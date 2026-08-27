import 'package:session/src/flutter_secure_credential_store.dart';
import 'package:session/src/web_storage_credential_backend_stub.dart'
    if (dart.library.js_interop) 'package:session/src/web_storage_credential_backend_web.dart'
    as platform;

SecureCredentialBackend createWebStorageCredentialBackend() =>
    platform.createWebStorageCredentialBackend();
