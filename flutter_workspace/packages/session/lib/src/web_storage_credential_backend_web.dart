import 'package:session/src/flutter_secure_credential_store.dart';
import 'package:web/web.dart' as web;

SecureCredentialBackend createWebStorageCredentialBackend() =>
    const WebStorageCredentialBackend();

final class WebStorageCredentialBackend implements SecureCredentialBackend {
  const WebStorageCredentialBackend();

  static const String _prefix = 'shouyin.legacy.';

  web.Storage _storage(bool sessionScoped) =>
      sessionScoped ? web.window.sessionStorage : web.window.localStorage;

  @override
  Future<String?> read(String key, {required bool sessionScoped}) async =>
      _storage(sessionScoped).getItem('$_prefix$key');

  @override
  Future<void> write(
    String key,
    String? value, {
    required bool sessionScoped,
  }) async {
    final storage = _storage(sessionScoped);
    final storageKey = '$_prefix$key';
    if (value == null) {
      storage.removeItem(storageKey);
    } else {
      storage.setItem(storageKey, value);
    }
  }
}
