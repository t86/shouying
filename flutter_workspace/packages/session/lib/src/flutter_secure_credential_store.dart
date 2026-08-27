import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:protocol/protocol.dart';
import 'package:session/src/credential_transaction_coordinator.dart';
import 'package:session/src/credential_transaction_coordinator_factory.dart';

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
  const CredentialStorageException._(this.code);

  final String code;

  @override
  String toString() => 'CredentialStorageException(storage operation failed)';
}

/// Secure credential storage with one transaction per storage namespace.
///
/// Every read, write, snapshot, and compare-and-clear operation is serialized
/// across all store instances sharing [namespace]. Native runtimes use a
/// process-wide named mutex. Web uses an exclusive, origin-scoped Web Lock, so
/// tabs and workers on the same origin participate in the same transaction.
/// If Web Locks are unavailable or rejected, operations fail closed with
/// [CredentialStorageException]; no compare-and-clear atomicity is claimed
/// without the browser lock.
///
/// On Web, `tk` uses the plugin's persistent encrypted storage while `stk`
/// explicitly uses `sessionStorage`. Web confidentiality remains bounded by
/// the application's same-origin and script security.
final class FlutterSecureCredentialStore implements CredentialStore {
  factory FlutterSecureCredentialStore({
    SecureCredentialBackend? backend,
    CredentialTransactionCoordinator? coordinator,
    String namespace = defaultNamespace,
  }) => FlutterSecureCredentialStore._(
    backend ?? const FlutterSecureStorageBackend(),
    coordinator ?? createCredentialTransactionCoordinator(),
    namespace,
  );

  FlutterSecureCredentialStore._(
    this._backend,
    this._coordinator,
    this.namespace,
  );

  static const String defaultNamespace = 'shouyin.credentials.v1';
  static const String _tkKey = 'shouyin.tk';
  static const String _stkKey = 'shouyin.stk';

  final SecureCredentialBackend _backend;
  final CredentialTransactionCoordinator _coordinator;
  final String namespace;

  @override
  Future<String?> readTk() =>
      _transaction(() => _backend.read(_tkKey, sessionScoped: false));

  @override
  Future<void> writeTk(String value) =>
      _transaction(() => _backend.write(_tkKey, value, sessionScoped: false));

  @override
  Future<void> clearTk() =>
      _transaction(() => _backend.write(_tkKey, null, sessionScoped: false));

  @override
  Future<String?> readStk() =>
      _transaction(() => _backend.read(_stkKey, sessionScoped: true));

  @override
  Future<void> writeStk(String value) =>
      _transaction(() => _backend.write(_stkKey, value, sessionScoped: true));

  @override
  Future<void> clearStk() =>
      _transaction(() => _backend.write(_stkKey, null, sessionScoped: true));

  @override
  Future<CredentialSnapshot> readSnapshot() => _transaction(() async {
    final tk = await _backend.read(_tkKey, sessionScoped: false);
    final stk = await _backend.read(_stkKey, sessionScoped: true);
    return CredentialSnapshot(tk: tk, stk: stk);
  });

  @override
  Future<void> clearTkIfMatches(String? expected) => _transaction(() async {
    final current = await _backend.read(_tkKey, sessionScoped: false);
    if (current == expected) {
      await _backend.write(_tkKey, null, sessionScoped: false);
    }
  });

  @override
  Future<void> clearStkIfMatches(String? expected) => _transaction(() async {
    final current = await _backend.read(_stkKey, sessionScoped: true);
    if (current == expected) {
      await _backend.write(_stkKey, null, sessionScoped: true);
    }
  });

  Future<T> _transaction<T>(Future<T> Function() operation) async {
    try {
      return await _coordinator.synchronized(namespace, operation);
    } on CredentialTransactionUnavailableException {
      throw const CredentialStorageException._(
        'credential.transaction_unavailable',
      );
    } on Object {
      throw const CredentialStorageException._(
        'credential.storage_unavailable',
      );
    }
  }

  @override
  String toString() => 'FlutterSecureCredentialStore()';
}
