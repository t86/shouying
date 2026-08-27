import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:protocol/protocol.dart';

/// Narrow plugin seam used to keep secure-storage platform channels out of
/// unit tests.
abstract interface class SecureCredentialBackend {
  Future<String?> read(String key, {required bool sessionScoped});

  Future<void> write(String key, String? value, {required bool sessionScoped});
}

final class FlutterSecureStorageBackend implements SecureCredentialBackend {
  const FlutterSecureStorageBackend({
    this._storage = const FlutterSecureStorage(),
  });

  static const WebOptions _persistentWebOptions = WebOptions();
  static const WebOptions _sessionWebOptions = WebOptions(
    useSessionStorage: true,
  );

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key, {required bool sessionScoped}) =>
      _storage.read(
        key: key,
        webOptions: sessionScoped ? _sessionWebOptions : _persistentWebOptions,
      );

  @override
  Future<void> write(
    String key,
    String? value, {
    required bool sessionScoped,
  }) => _storage.write(
    key: key,
    value: value,
    webOptions: sessionScoped ? _sessionWebOptions : _persistentWebOptions,
  );
}

/// A deliberately detail-free failure for credential persistence operations.
final class CredentialStorageException implements Exception {
  const CredentialStorageException._();

  @override
  String toString() => 'CredentialStorageException(storage operation failed)';
}

/// Secure credential storage with process-instance atomicity.
///
/// Every read, write, snapshot, and compare-and-clear operation is serialized
/// through this instance's queue. This provides a consistent snapshot and
/// conditional-clear guarantee for callers sharing the same store instance.
/// Browser tabs and separately constructed store instances cannot share this
/// mutex; compare-and-clear still re-reads the current value immediately before
/// deletion, but cross-instance atomicity is not claimed.
///
/// On Web, `tk` uses the plugin's persistent encrypted storage while `stk`
/// explicitly uses `sessionStorage`. Web confidentiality remains bounded by
/// the application's same-origin and script security.
final class FlutterSecureCredentialStore implements CredentialStore {
  factory FlutterSecureCredentialStore({SecureCredentialBackend? backend}) =>
      FlutterSecureCredentialStore._(
        backend ?? const FlutterSecureStorageBackend(),
      );

  FlutterSecureCredentialStore._(this._backend);

  static const String _tkKey = 'shouyin.tk';
  static const String _stkKey = 'shouyin.stk';

  final SecureCredentialBackend _backend;
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<String?> readTk() =>
      _enqueue(() => _backend.read(_tkKey, sessionScoped: false));

  @override
  Future<void> writeTk(String value) =>
      _enqueue(() => _backend.write(_tkKey, value, sessionScoped: false));

  @override
  Future<void> clearTk() =>
      _enqueue(() => _backend.write(_tkKey, null, sessionScoped: false));

  @override
  Future<String?> readStk() =>
      _enqueue(() => _backend.read(_stkKey, sessionScoped: true));

  @override
  Future<void> writeStk(String value) =>
      _enqueue(() => _backend.write(_stkKey, value, sessionScoped: true));

  @override
  Future<void> clearStk() =>
      _enqueue(() => _backend.write(_stkKey, null, sessionScoped: true));

  @override
  Future<CredentialSnapshot> readSnapshot() => _enqueue(() async {
    final tk = await _backend.read(_tkKey, sessionScoped: false);
    final stk = await _backend.read(_stkKey, sessionScoped: true);
    return CredentialSnapshot(tk: tk, stk: stk);
  });

  @override
  Future<void> clearTkIfMatches(String? expected) => _enqueue(() async {
    final current = await _backend.read(_tkKey, sessionScoped: false);
    if (current == expected) {
      await _backend.write(_tkKey, null, sessionScoped: false);
    }
  });

  @override
  Future<void> clearStkIfMatches(String? expected) => _enqueue(() async {
    final current = await _backend.read(_stkKey, sessionScoped: true);
    if (current == expected) {
      await _backend.write(_stkKey, null, sessionScoped: true);
    }
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final preceding = _operationTail;
    final release = Completer<void>();
    _operationTail = release.future;
    return preceding.then((_) async {
      try {
        return await operation();
      } on Object {
        throw const CredentialStorageException._();
      } finally {
        release.complete();
      }
    });
  }

  @override
  String toString() => 'FlutterSecureCredentialStore()';
}
