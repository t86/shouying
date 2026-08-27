import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:session/src/flutter_secure_credential_store.dart';
import 'package:session/src/credential_transaction_coordinator.dart';

void main() {
  group('FlutterSecureCredentialStore', () {
    test(
      'implements tk and stk read write and clear with fixed scopes',
      () async {
        final backend = _MemoryBackend();
        final store = FlutterSecureCredentialStore(
          backend: backend,
          coordinator: const _TestCoordinator(),
        );

        await store.writeTk('tk-value');
        await store.writeStk('stk-value');

        expect(await store.readTk(), 'tk-value');
        expect(await store.readStk(), 'stk-value');
        expect(
          backend.calls,
          containsAll(<String>[
            'write:shouyin.tk:persistent',
            'write:shouyin.stk:session',
            'read:shouyin.tk:persistent',
            'read:shouyin.stk:session',
          ]),
        );

        await store.clearTk();
        await store.clearStk();

        expect(await store.readTk(), isNull);
        expect(await store.readStk(), isNull);
      },
    );

    test(
      'readSnapshot cannot interleave with operations on the same store',
      () async {
        final backend = _MemoryBackend()
          ..persistent['shouyin.tk'] = 'old-tk'
          ..session['shouyin.stk'] = 'old-stk';
        final store = FlutterSecureCredentialStore(
          backend: backend,
          coordinator: const _TestCoordinator(),
        );
        final readStarted = Completer<void>();
        final releaseRead = Completer<void>();
        backend.onRead = (key) async {
          if (key == 'shouyin.tk' && !readStarted.isCompleted) {
            readStarted.complete();
            await releaseRead.future;
          }
        };

        final snapshotFuture = store.readSnapshot();
        await readStarted.future;
        final writeFuture = store.writeTk('new-tk');
        releaseRead.complete();

        final snapshot = await snapshotFuture;
        await writeFuture;
        expect(snapshot.tk, 'old-tk');
        expect(snapshot.stk, 'old-stk');
        expect(await store.readTk(), 'new-tk');
      },
    );

    test('conditional clear preserves a newer token', () async {
      final backend = _MemoryBackend();
      final store = FlutterSecureCredentialStore(
        backend: backend,
        coordinator: const _TestCoordinator(),
      );
      await store.writeTk('old-tk');
      await store.writeStk('old-stk');
      final snapshot = await store.readSnapshot();
      await store.writeTk('new-tk');
      await store.writeStk('new-stk');

      await store.clearTkIfMatches(snapshot.tk);
      await store.clearStkIfMatches(snapshot.stk);

      expect(await store.readTk(), 'new-tk');
      expect(await store.readStk(), 'new-stk');
    });

    test('all operations are serialized per store instance', () async {
      final backend = _MemoryBackend(delay: const Duration(milliseconds: 2));
      final store = FlutterSecureCredentialStore(
        backend: backend,
        coordinator: const _TestCoordinator(),
      );

      await Future.wait<void>(<Future<void>>[
        store.writeTk('one'),
        store.writeStk('two'),
        store.clearTk(),
        store.clearStk(),
      ]);

      expect(backend.maximumConcurrentCalls, 1);
    });

    test(
      'all instances sharing a namespace use one transaction queue',
      () async {
        final backend = _MemoryBackend(delay: const Duration(milliseconds: 2));
        final first = FlutterSecureCredentialStore(
          backend: backend,
          coordinator: const _TestCoordinator(),
          namespace: 'test.shared.queue',
        );
        final second = FlutterSecureCredentialStore(
          backend: backend,
          coordinator: const _TestCoordinator(),
          namespace: 'test.shared.queue',
        );

        await Future.wait<void>(<Future<void>>[
          first.writeTk('one'),
          second.writeStk('two'),
          first.clearTk(),
          second.clearStk(),
        ]);

        expect(backend.maximumConcurrentCalls, 1);
      },
    );

    test(
      'cross-instance conditional clear cannot delete a newer token',
      () async {
        final backend = _CasGateBackend()..value = 'old-tk';
        final first = FlutterSecureCredentialStore(
          backend: backend,
          coordinator: const _TestCoordinator(),
          namespace: 'test.shared.cas',
        );
        final second = FlutterSecureCredentialStore(
          backend: backend,
          coordinator: const _TestCoordinator(),
          namespace: 'test.shared.cas',
        );

        final clear = first.clearTkIfMatches('old-tk');
        await backend.readStarted.future;
        var writeCompleted = false;
        final write = second.writeTk('new-tk').then((_) {
          writeCompleted = true;
        });
        await Future<void>.delayed(Duration.zero);

        expect(writeCompleted, isFalse);
        backend.releaseRead.complete();
        await Future.wait<void>(<Future<void>>[clear, write]);
        expect(await first.readTk(), 'new-tk');
      },
    );

    test('cross-instance snapshot cannot mix credential generations', () async {
      final backend = _SnapshotGateBackend()
        ..persistent['shouyin.tk'] = 'old-tk'
        ..session['shouyin.stk'] = 'old-stk';
      final first = FlutterSecureCredentialStore(
        backend: backend,
        coordinator: const _TestCoordinator(),
        namespace: 'test.shared.snapshot',
      );
      final second = FlutterSecureCredentialStore(
        backend: backend,
        coordinator: const _TestCoordinator(),
        namespace: 'test.shared.snapshot',
      );

      final snapshotFuture = first.readSnapshot();
      await backend.tkReadStarted.future;
      var writesCompleted = false;
      final writes =
          Future.wait<void>(<Future<void>>[
            second.writeTk('new-tk'),
            second.writeStk('new-stk'),
          ]).then((_) {
            writesCompleted = true;
          });
      await Future<void>.delayed(Duration.zero);

      expect(writesCompleted, isFalse);
      backend.releaseTkRead.complete();
      final snapshot = await snapshotFuture;
      await writes;
      expect(snapshot.tk, 'old-tk');
      expect(snapshot.stk, 'old-stk');
      expect(
        await first.readSnapshot(),
        isA<CredentialSnapshot>()
            .having((value) => value.tk, 'tk', 'new-tk')
            .having((value) => value.stk, 'stk', 'new-stk'),
      );
    });

    test(
      'transaction coordinator failure fails closed with stable error',
      () async {
        final store = FlutterSecureCredentialStore(
          backend: _MemoryBackend(),
          coordinator: const _UnavailableCoordinator(),
          namespace: 'test.unavailable',
        );

        await expectLater(
          store.writeTk('synthetic-tk'),
          throwsA(
            isA<CredentialStorageException>().having(
              (failure) => failure.code,
              'code',
              'credential.transaction_unavailable',
            ),
          ),
        );
      },
    );

    test(
      'backend failures and string representations never expose tokens',
      () async {
        const secret = 'hostile-secret-token';
        final store = FlutterSecureCredentialStore(
          backend: _ThrowingBackend(StateError('write failed: $secret')),
          coordinator: const _TestCoordinator(),
        );

        Object? failure;
        try {
          await store.writeTk(secret);
        } on Object catch (error) {
          failure = error;
        }

        expect(failure, isA<CredentialStorageException>());
        expect(
          (failure! as CredentialStorageException).code,
          'credential.storage_unavailable',
        );
        expect(failure.toString(), isNot(contains(secret)));
        expect(store.toString(), isNot(contains(secret)));
      },
    );
  });
}

final class _MemoryBackend implements SecureCredentialBackend {
  _MemoryBackend({this.delay = Duration.zero});

  final Duration delay;
  final Map<String, String> persistent = <String, String>{};
  final Map<String, String> session = <String, String>{};
  final List<String> calls = <String>[];
  Future<void> Function(String key)? onRead;
  int concurrentCalls = 0;
  int maximumConcurrentCalls = 0;

  @override
  Future<String?> read(String key, {required bool sessionScoped}) async {
    _enter();
    try {
      calls.add('read:$key:${sessionScoped ? 'session' : 'persistent'}');
      await onRead?.call(key);
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      return (sessionScoped ? session : persistent)[key];
    } finally {
      concurrentCalls -= 1;
    }
  }

  @override
  Future<void> write(
    String key,
    String? value, {
    required bool sessionScoped,
  }) async {
    _enter();
    try {
      calls.add('write:$key:${sessionScoped ? 'session' : 'persistent'}');
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      final target = sessionScoped ? session : persistent;
      if (value == null) {
        target.remove(key);
      } else {
        target[key] = value;
      }
    } finally {
      concurrentCalls -= 1;
    }
  }

  void _enter() {
    concurrentCalls += 1;
    if (concurrentCalls > maximumConcurrentCalls) {
      maximumConcurrentCalls = concurrentCalls;
    }
  }
}

final class _ThrowingBackend implements SecureCredentialBackend {
  const _ThrowingBackend(this.error);

  final Object error;

  @override
  Future<String?> read(String key, {required bool sessionScoped}) =>
      Future<String?>.error(error);

  @override
  Future<void> write(
    String key,
    String? value, {
    required bool sessionScoped,
  }) => Future<void>.error(error);
}

final class _CasGateBackend implements SecureCredentialBackend {
  String? value;
  final Completer<void> readStarted = Completer<void>();
  final Completer<void> releaseRead = Completer<void>();

  @override
  Future<String?> read(String key, {required bool sessionScoped}) async {
    final captured = value;
    if (!readStarted.isCompleted) readStarted.complete();
    await releaseRead.future;
    return captured;
  }

  @override
  Future<void> write(
    String key,
    String? value, {
    required bool sessionScoped,
  }) async {
    this.value = value;
  }
}

final class _SnapshotGateBackend implements SecureCredentialBackend {
  final Map<String, String> persistent = <String, String>{};
  final Map<String, String> session = <String, String>{};
  final Completer<void> tkReadStarted = Completer<void>();
  final Completer<void> releaseTkRead = Completer<void>();

  @override
  Future<String?> read(String key, {required bool sessionScoped}) async {
    final captured = (sessionScoped ? session : persistent)[key];
    if (key == 'shouyin.tk' && !tkReadStarted.isCompleted) {
      tkReadStarted.complete();
      await releaseTkRead.future;
    }
    return captured;
  }

  @override
  Future<void> write(
    String key,
    String? value, {
    required bool sessionScoped,
  }) async {
    final target = sessionScoped ? session : persistent;
    if (value == null) {
      target.remove(key);
    } else {
      target[key] = value;
    }
  }
}

final class _UnavailableCoordinator
    implements CredentialTransactionCoordinator {
  const _UnavailableCoordinator();

  @override
  Future<T> synchronized<T>(String namespace, Future<T> Function() operation) =>
      Future<T>.error(const CredentialTransactionUnavailableException());
}

final class _TestCoordinator implements CredentialTransactionCoordinator {
  const _TestCoordinator();

  static final Map<String, Future<void>> _tails = <String, Future<void>>{};

  @override
  Future<T> synchronized<T>(
    String namespace,
    Future<T> Function() operation,
  ) async {
    final previous = _tails[namespace] ?? Future<void>.value();
    final release = Completer<void>();
    final tail = release.future;
    _tails[namespace] = tail;
    await previous;
    try {
      return await operation();
    } finally {
      release.complete();
      if (identical(_tails[namespace], tail)) {
        unawaited(_tails.remove(namespace));
      }
    }
  }
}
