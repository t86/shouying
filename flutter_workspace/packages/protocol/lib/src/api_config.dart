import 'package:protocol/src/canonical_uri.dart';

final class ApiConfig {
  factory ApiConfig({
    required Uri apiBase,
    required Uri onlineBase,
    required Uri websocketBase,
  }) => ApiConfig._(
    apiBase: _normalizeEndpoint(
      apiBase,
      name: 'apiBase',
      allowedSchemes: const <String>{'http', 'https'},
    ),
    onlineBase: _normalizeEndpoint(
      onlineBase,
      name: 'onlineBase',
      allowedSchemes: const <String>{'http', 'https'},
    ),
    websocketBase: _normalizeEndpoint(
      websocketBase,
      name: 'websocketBase',
      allowedSchemes: const <String>{'ws', 'wss'},
    ),
  );

  const ApiConfig._({
    required this.apiBase,
    required this.onlineBase,
    required this.websocketBase,
  });

  final Uri apiBase;
  final Uri onlineBase;
  final Uri websocketBase;

  static Uri _normalizeEndpoint(
    Uri endpoint, {
    required String name,
    required Set<String> allowedSchemes,
  }) {
    if (!endpoint.isAbsolute ||
        !endpoint.hasAuthority ||
        endpoint.host.isEmpty ||
        !allowedSchemes.contains(endpoint.scheme.toLowerCase())) {
      throw ArgumentError.value(
        endpoint,
        name,
        '$name must be an absolute ${allowedSchemes.join('/')} endpoint',
      );
    }
    if (endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment) {
      throw ArgumentError.value(
        endpoint,
        name,
        '$name must not contain userinfo, a query, or a fragment',
      );
    }

    final normalized = endpoint.normalizePath();
    var path = normalized.path;
    while (path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    final trimmed = normalized.replace(path: path);
    final segments = CanonicalUri.safePathSegments(trimmed);
    if (segments == null) {
      throw ArgumentError.value(
        endpoint,
        name,
        '$name contains an ambiguous or unsafe path',
      );
    }
    return trimmed.replace(pathSegments: segments);
  }
}
