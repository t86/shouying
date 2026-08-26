import 'package:dio/dio.dart';
import 'package:protocol/src/api_config.dart';
import 'package:protocol/src/client_kind.dart';
import 'package:protocol/src/credential_store.dart';

final class HeaderPolicy {
  const HeaderPolicy({required this.config, required this.credentialStore});

  final ApiConfig config;
  final CredentialStore credentialStore;

  Future<Map<String, String>> headersFor({
    required Uri target,
    required ClientKind client,
  }) async {
    final tk = await credentialStore.readTk();
    final stk = await credentialStore.readStk();
    final headers = <String, String>{
      Headers.acceptHeader: Headers.jsonContentType,
      Headers.contentTypeHeader: Headers.jsonContentType,
    };

    if (tk != null && tk.trim().isNotEmpty) headers['tk'] = tk;
    if (stk != null && stk.trim().isNotEmpty) headers['stk'] = stk;
    final termType = client.termType;
    if (!_isOnlineTarget(target) && termType != null) {
      headers['tt'] = termType.toString();
    }
    return headers;
  }

  bool _isOnlineTarget(Uri target) {
    final online = config.onlineBase.normalizePath();
    final normalizedTarget = target.normalizePath();
    if (normalizedTarget.scheme != online.scheme ||
        normalizedTarget.host != online.host ||
        normalizedTarget.port != online.port) {
      return false;
    }

    final basePath = online.path;
    final targetPath = normalizedTarget.path;
    return basePath.isEmpty ||
        targetPath == basePath ||
        targetPath.startsWith('$basePath/');
  }
}
