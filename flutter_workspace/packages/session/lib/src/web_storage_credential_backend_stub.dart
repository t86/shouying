import 'package:session/src/flutter_secure_credential_store.dart';

SecureCredentialBackend createWebStorageCredentialBackend() =>
    const _UnavailableWebStorageCredentialBackend();

final class _UnavailableWebStorageCredentialBackend
    implements SecureCredentialBackend {
  const _UnavailableWebStorageCredentialBackend();

  @override
  Future<String?> read(String key, {required bool sessionScoped}) =>
      Future<String?>.error(UnsupportedError('Web storage is unavailable'));

  @override
  Future<void> write(
    String key,
    String? value, {
    required bool sessionScoped,
  }) => Future<void>.error(UnsupportedError('Web storage is unavailable'));
}
