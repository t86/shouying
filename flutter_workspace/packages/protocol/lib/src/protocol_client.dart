import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/src/api_config.dart';
import 'package:protocol/src/client_kind.dart';
import 'package:protocol/src/credential_store.dart';
import 'package:protocol/src/header_policy.dart';
import 'package:protocol/src/request_gate.dart';

class ProtocolClient {
  factory ProtocolClient({
    required Dio dio,
    required ApiConfig config,
    required CredentialStore credentialStore,
    required RequestGate requestGate,
  }) => ProtocolClient._(
    dio,
    config,
    credentialStore,
    requestGate,
    HeaderPolicy(config: config, credentialStore: credentialStore),
  );

  ProtocolClient._(
    this._dio,
    this._config,
    this._credentialStore,
    this._requestGate,
    this._headerPolicy,
  );

  static const Duration _requestTimeout = Duration(seconds: 12);

  final Dio _dio;
  final ApiConfig _config;
  final CredentialStore _credentialStore;
  final RequestGate _requestGate;
  final HeaderPolicy _headerPolicy;

  Future<Result<Map<String, Object?>>> get(
    String path, {
    Map<String, Object?> query = const <String, Object?>{},
    required ClientKind client,
  }) => _request(method: 'GET', path: path, query: query, client: client);

  Future<Result<Map<String, Object?>>> post(
    String path, {
    Map<String, Object?> body = const <String, Object?>{},
    required ClientKind client,
  }) => _request(method: 'POST', path: path, body: body, client: client);

  Future<Result<Map<String, Object?>>> _request({
    required String method,
    required String path,
    required ClientKind client,
    Map<String, Object?> query = const <String, Object?>{},
    Map<String, Object?>? body,
  }) async {
    final target = _targetFor(path, query);
    if (target == null) return const FailureResult(_invalidPathFailure);
    if (!_requestGate.allow(target)) {
      return const FailureResult(_requestThrottledFailure);
    }

    final Map<String, String> headers;
    try {
      headers = await _headerPolicy.headersFor(target: target, client: client);
    } on Object {
      return const FailureResult(_credentialsUnavailableFailure);
    }

    final options = Options(
      method: method,
      connectTimeout: _requestTimeout,
      sendTimeout: _requestTimeout,
      receiveTimeout: _requestTimeout,
      headers: headers,
    );

    try {
      final response = await _dio.requestUri<Object?>(
        target,
        data: body,
        options: options,
      );
      return await _handleResponse(response.data);
    } on DioException catch (error) {
      return FailureResult(_mapDioFailure(error.type));
    } on Object {
      return const FailureResult(_unknownFailure);
    }
  }

  Uri? _targetFor(String path, Map<String, Object?> query) {
    if (!_isSafeRequestPath(path)) return null;

    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    final basePath = _config.apiBase.path;
    final joinedPath = basePath.isEmpty
        ? '/$relativePath'
        : '$basePath/$relativePath';
    return _config.apiBase.replace(
      path: joinedPath,
      queryParameters: query.isEmpty ? null : query,
    );
  }

  bool _isSafeRequestPath(String path) {
    if (path.isEmpty ||
        path.trim() != path ||
        path.startsWith('//') ||
        path.contains(r'\') ||
        path.contains('?') ||
        path.contains('#')) {
      return false;
    }

    final parsed = Uri.tryParse(path);
    if (parsed == null ||
        parsed.isAbsolute ||
        parsed.hasAuthority ||
        parsed.hasQuery ||
        parsed.hasFragment) {
      return false;
    }
    final rawPath = path.startsWith('/') ? path.substring(1) : path;
    final rawSegments = rawPath.split('/');
    if (rawSegments.isEmpty) return false;
    try {
      return rawSegments.every((rawSegment) {
        final segment = Uri.decodeComponent(rawSegment);
        return segment.isNotEmpty && segment != '.' && segment != '..';
      });
    } on FormatException {
      return false;
    }
  }

  Future<Result<Map<String, Object?>>> _handleResponse(Object? data) async {
    Object? decoded = data;
    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } on FormatException {
        return const FailureResult(_invalidTopLevelFailure);
      }
    }
    if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
      return const FailureResult(_invalidTopLevelFailure);
    }

    final result = <String, Object?>{
      for (final entry in decoded.entries)
        entry.key as String: entry.value as Object?,
    };
    final code = result['code'];
    if ((code is int && (code == 11 || code == 12)) ||
        (code is String && (code == '11' || code == '12'))) {
      await _ignoreClearFailure(_credentialStore.clearTk);
      return const FailureResult(_tkExpiredFailure);
    }
    if ((code is int && (code == 14 || code == 15)) ||
        (code is String && (code == '14' || code == '15'))) {
      await _ignoreClearFailure(_credentialStore.clearStk);
      return const FailureResult(_stkExpiredFailure);
    }
    return Success(result);
  }

  Future<void> _ignoreClearFailure(Future<void> Function() clear) async {
    try {
      await clear();
    } on Object {
      // Credential invalidation is best-effort; the safe auth failure wins.
    }
  }

  AppFailure _mapDioFailure(DioExceptionType type) => switch (type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => _timeoutFailure,
    DioExceptionType.connectionError ||
    DioExceptionType.badCertificate => _networkUnavailableFailure,
    DioExceptionType.cancel => _cancelledFailure,
    DioExceptionType.badResponse => _serverFailure,
    DioExceptionType.unknown => _unknownFailure,
  };

  static const AppFailure _invalidPathFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.invalid_path',
    safeMessage: '请求路径无效',
  );
  static const AppFailure _requestThrottledFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.request_throttled',
    safeMessage: '请求过于频繁，请稍后重试',
  );
  static const AppFailure _invalidTopLevelFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.invalid_top_level',
    safeMessage: '服务返回了无法识别的数据',
  );
  static const AppFailure _credentialsUnavailableFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.credentials_unavailable',
    safeMessage: '登录信息不可用，请重新登录',
  );
  static const AppFailure _tkExpiredFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.tk_expired',
    safeMessage: '登录已失效，请重新登录',
  );
  static const AppFailure _stkExpiredFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.stk_expired',
    safeMessage: '授权已失效，请重新登录',
  );
  static const AppFailure _timeoutFailure = AppFailure(
    kind: FailureKind.network,
    code: 'network.timeout',
    safeMessage: '请求超时，请稍后重试',
  );
  static const AppFailure _networkUnavailableFailure = AppFailure(
    kind: FailureKind.network,
    code: 'network.unavailable',
    safeMessage: '网络不可用，请检查连接',
  );
  static const AppFailure _cancelledFailure = AppFailure(
    kind: FailureKind.network,
    code: 'network.cancelled',
    safeMessage: '请求已取消',
  );
  static const AppFailure _serverFailure = AppFailure(
    kind: FailureKind.network,
    code: 'network.server_error',
    safeMessage: '服务暂时不可用，请稍后重试',
  );
  static const AppFailure _unknownFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'unknown.request_failed',
    safeMessage: '请求失败，请稍后重试',
  );
}
