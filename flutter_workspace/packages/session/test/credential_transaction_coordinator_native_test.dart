@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

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
  await coordinator.synchronized<void>(request.namespace, () async {
    request.events.send('entered');
  });
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
