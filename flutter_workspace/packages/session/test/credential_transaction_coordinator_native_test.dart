@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:session/src/credential_transaction_coordinator.dart';
import 'package:session/src/credential_transaction_coordinator_native.dart';
import 'package:test/test.dart';

void main() {
  late Directory lockDirectory;

  setUp(() async {
    lockDirectory = await Directory.systemTemp.createTemp(
      'shouyin-credential-lock-test-',
    );
  });

  tearDown(() async {
    await lockDirectory.delete(recursive: true);
  });

  test(
    'guard disappearing after exclusive-create conflict is retried',
    () async {
      final hash = sha256.convert(utf8.encode('race.namespace')).toString();
      final guardPath =
          '${lockDirectory.path}${Platform.pathSeparator}$hash.$pid.guard';
      final lockPath =
          '${lockDirectory.path}${Platform.pathSeparator}$hash.lock';
      final guard = _DisappearingGuard(File(guardPath));
      final lock = File(lockPath);
      var calls = 0;
      await IOOverrides.runZoned(() async {
        final coordinator = IoCredentialTransactionCoordinator(
          lockDirectoryProvider: FixedNativeLockDirectoryProvider(
            lockDirectory,
          ),
        );
        await coordinator.synchronized<void>('race.namespace', () async {
          calls++;
        });
      }, createFile: (path) => path == guardPath ? guard : lock);
      expect(guard.creates, 2);
      expect(calls, 1);
    },
  );

  test('permission error fails closed even if the guard exists', () async {
    final guard = _DisappearingGuard(
      File('${lockDirectory.path}/denied'),
      errorCode: Platform.isWindows ? 5 : 13,
      existsValue: true,
    );
    var calls = 0;
    await IOOverrides.runZoned(() async {
      final coordinator = IoCredentialTransactionCoordinator(
        lockDirectoryProvider: FixedNativeLockDirectoryProvider(lockDirectory),
      );
      await expectLater(
        coordinator.synchronized<void>('denied.namespace', () async {
          calls++;
        }),
        throwsA(isA<CredentialTransactionUnavailableException>()),
      );
    }, createFile: (_) => guard);
    expect(guard.creates, 1);
    expect(calls, 0);
  });

  test(
    'worker lock failures are reported instead of silently losing entered',
    () async {
      final invalidDirectory = await File(
        '${lockDirectory.path}/not-a-directory',
      ).create();
      final events = ReceivePort();
      final isolate = await Isolate.spawn(
        _attemptLock,
        _IsolateLockRequest(
          directoryPath: invalidDirectory.path,
          namespace: 'invalid',
          events: events.sendPort,
        ),
      );
      addTearDown(() {
        events.close();
        isolate.kill(priority: Isolate.immediate);
      });
      final messages = StreamIterator<Object?>(events);
      addTearDown(messages.cancel);
      expect(await messages.moveNext(), true);
      expect(messages.current, 'waiting');
      expect(await messages.moveNext(), true);
      expect(messages.current, isA<List>());
      expect((messages.current as List).first, 'error');
    },
  );

  test('OS lock serializes the same namespace across isolates', () async {
    final coordinator = IoCredentialTransactionCoordinator(
      lockDirectoryProvider: FixedNativeLockDirectoryProvider(lockDirectory),
    );
    final firstEntered = Completer<void>();
    final releaseFirst = Completer<void>();
    final first = coordinator.synchronized<void>('shared.namespace', () async {
      firstEntered.complete();
      await releaseFirst.future;
    });
    await firstEntered.future;

    final events = ReceivePort();
    final isolate = await Isolate.spawn(
      _attemptLock,
      _IsolateLockRequest(
        directoryPath: lockDirectory.path,
        namespace: 'shared.namespace',
        events: events.sendPort,
      ),
    );
    addTearDown(() {
      events.close();
      isolate.kill(priority: Isolate.immediate);
    });
    final waiting = Completer<void>();
    final entered = Completer<void>();
    final subscription = events.listen((message) {
      if (message == 'waiting' && !waiting.isCompleted) waiting.complete();
      if (message == 'entered' && !entered.isCompleted) entered.complete();
      if (message is List && message.first == 'error' && !entered.isCompleted) {
        entered.completeError(StateError('Lock isolate failed: ${message[1]}'));
      }
    });
    addTearDown(subscription.cancel);
    await waiting.future;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(entered.isCompleted, isFalse);

    releaseFirst.complete();
    await first;
    await entered.future;
  });

  test('different namespaces remain independent across isolates', () async {
    final coordinator = IoCredentialTransactionCoordinator(
      lockDirectoryProvider: FixedNativeLockDirectoryProvider(lockDirectory),
    );
    final firstEntered = Completer<void>();
    final releaseFirst = Completer<void>();
    final first = coordinator.synchronized<void>('namespace.a', () async {
      firstEntered.complete();
      await releaseFirst.future;
    });
    await firstEntered.future;

    final events = ReceivePort();
    final isolate = await Isolate.spawn(
      _attemptLock,
      _IsolateLockRequest(
        directoryPath: lockDirectory.path,
        namespace: 'namespace.b',
        events: events.sendPort,
      ),
    );
    addTearDown(() {
      events.close();
      isolate.kill(priority: Isolate.immediate);
    });
    final messages = StreamIterator<Object?>(events);
    expect(await messages.moveNext(), isTrue);
    expect(messages.current, 'waiting');
    expect(await messages.moveNext(), isTrue);
    expect(messages.current, 'entered');

    releaseFirst.complete();
    await first;
    await messages.cancel();
  });

  test('lock directory failures fail closed before the operation', () async {
    final coordinator = IoCredentialTransactionCoordinator(
      lockDirectoryProvider: const _ThrowingDirectoryProvider(),
    );
    var called = false;

    await expectLater(
      coordinator.synchronized<void>('unavailable', () async {
        called = true;
      }),
      throwsA(isA<CredentialTransactionUnavailableException>()),
    );
    expect(called, isFalse);
  });
}

Future<void> _attemptLock(_IsolateLockRequest request) async {
  final coordinator = IoCredentialTransactionCoordinator(
    lockDirectoryProvider: FixedNativeLockDirectoryProvider(
      Directory(request.directoryPath),
    ),
  );
  request.events.send('waiting');
  try {
    await coordinator.synchronized<void>(request.namespace, () async {
      request.events.send('entered');
    });
  } on Object catch (error) {
    request.events.send(['error', error.toString()]);
  }
}

final class _IsolateLockRequest {
  const _IsolateLockRequest({
    required this.directoryPath,
    required this.namespace,
    required this.events,
  });

  final String directoryPath;
  final String namespace;
  final SendPort events;
}

final class _ThrowingDirectoryProvider implements NativeLockDirectoryProvider {
  const _ThrowingDirectoryProvider();

  @override
  Future<Directory> getLockDirectory() => Future<Directory>.error(
    const FileSystemException('synthetic lock directory failure'),
  );
}

class _DisappearingGuard implements File {
  _DisappearingGuard(this.delegate, {int? errorCode, this.existsValue = false})
    : errorCode = errorCode ?? (Platform.isWindows ? 80 : 17);
  final File delegate;
  final int errorCode;
  final bool existsValue;
  int creates = 0;
  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    creates++;
    if (creates == 1) {
      throw FileSystemException(
        'synthetic create failure',
        delegate.path,
        OSError('synthetic', errorCode),
      );
    }
    return delegate.create(recursive: recursive, exclusive: exclusive);
  }

  @override
  Future<bool> exists() async => existsValue;
  @override
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      delegate.delete(recursive: recursive);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected file operation');
}
