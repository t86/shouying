import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:session/src/flutter_secure_credential_store.dart';

void main() {
  group('FlutterSecureCredentialStore', () {
    test(
      'implements tk and stk read write and clear with fixed scopes',
      () async {
        final backend = _MemoryBackend();
        final store = FlutterSecureCredentialStore(backend: backend);

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
        final store = FlutterSecureCredentialStore(backend: backend);
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
      final store = FlutterSecureCredentialStore(backend: backend);
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
      final store = FlutterSecureCredentialStore(backend: backend);

      await Future.wait<void>(<Future<void>>[
        store.writeTk('one'),
        store.writeStk('two'),
        store.clearTk(),
        store.clearStk(),
      ]);

      expect(backend.maximumConcurrentCalls, 1);
    });

    test(
      'backend failures and string representations never expose tokens',
      () async {
        const secret = 'hostile-secret-token';
        final store = FlutterSecureCredentialStore(
          backend: _ThrowingBackend(StateError('write failed: $secret')),
        );

        Object? failure;
        try {
          await store.writeTk(secret);
        } on Object catch (error) {
          failure = error;
        }

        expect(failure, isA<CredentialStorageException>());
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
