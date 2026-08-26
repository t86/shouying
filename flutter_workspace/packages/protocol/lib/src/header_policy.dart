import 'package:dio/dio.dart';
import 'package:protocol/src/api_config.dart';
import 'package:protocol/src/canonical_uri.dart';
import 'package:protocol/src/client_kind.dart';
import 'package:protocol/src/credential_store.dart';

final class HeaderSelection {
  HeaderSelection({required Map<String, String> headers, this.snapshot})
    : headers = Map<String, String>.unmodifiable(headers);

  final Map<String, String> headers;
  final CredentialSnapshot? snapshot;
}

final class HeaderPolicy {
  const HeaderPolicy({required this.config, required this.credentialStore});

  final ApiConfig config;
  final CredentialStore credentialStore;

  Future<Map<String, String>> headersFor({
    required Uri target,
    required ClientKind client,
  }) async => (await selectionFor(target: target, client: client)).headers;

  Future<HeaderSelection> selectionFor({
    required Uri target,
    required ClientKind client,
  }) async {
    final headers = <String, String>{
      Headers.acceptHeader: Headers.jsonContentType,
      Headers.contentTypeHeader: Headers.jsonContentType,
    };
    final isApiTarget = CanonicalUri.isSameOriginSubtree(
      target: target,
      base: config.apiBase,
    );
    final isOnlineTarget = CanonicalUri.isSameOriginSubtree(
      target: target,
      base: config.onlineBase,
    );
    if (!isApiTarget && !isOnlineTarget) {
      return HeaderSelection(headers: headers);
    }

    final snapshot = await credentialStore.readSnapshot();
    final tk = snapshot.tk;
    final stk = snapshot.stk;
    if (tk != null && tk.trim().isNotEmpty) headers['tk'] = tk;
    if (stk != null && stk.trim().isNotEmpty) headers['stk'] = stk;
    final termType = client.termType;
    if (isApiTarget && !isOnlineTarget && termType != null) {
      headers['tt'] = termType.toString();
    }
    return HeaderSelection(headers: headers, snapshot: snapshot);
  }
}
