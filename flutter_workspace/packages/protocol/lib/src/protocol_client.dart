import 'dart:collection';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/src/api_config.dart';
import 'package:protocol/src/canonical_uri.dart';
import 'package:protocol/src/client_kind.dart';
import 'package:protocol/src/credential_store.dart';
import 'package:protocol/src/header_policy.dart';
import 'package:protocol/src/limited_response_adapter.dart';
import 'package:protocol/src/protocol_adapter.dart';
import 'package:protocol/src/request_gate.dart';

/// Application-level response budgets.
///
/// Dio may allocate transport bytes before these checks run. The raw-byte
/// budget caps JSON decoding and subsequent application traversal, while a
/// trustworthy Content-Length header can reject a response before parsing.
interface class ProtocolResponseLimits {
  const ProtocolResponseLimits({
    this.maxRawResponseBytes = defaultMaxRawResponseBytes,
    this.maxDepth = defaultMaxDepth,
    this.maxNodes = defaultMaxNodes,
  }) : assert(maxRawResponseBytes > 0),
       assert(maxDepth > 0),
       assert(maxNodes > 0);

  static const int defaultMaxRawResponseBytes = 2 * 1024 * 1024;
  static const int defaultMaxDepth = 32;
  static const int defaultMaxNodes = 10000;

  final int maxRawResponseBytes;
  final int maxDepth;
  final int maxNodes;
}

/// A protocol-scoped owner of the injected [Dio] instance.
///
/// Construction configures Dio's base timeouts and wraps its transport
/// adapter, so the instance must not be shared with unrelated consumers.
/// Multiple ProtocolClients may share it; the strictest response byte limit
/// wins without nesting transport wrappers.
class ProtocolClient {
  factory ProtocolClient({
    required Dio dio,
    required ApiConfig config,
    required CredentialStore credentialStore,
    required RequestGate requestGate,
    ProtocolResponseLimits responseLimits = const ProtocolResponseLimits(),
  }) {
    _validateResponseLimits(responseLimits);
    dio.options
      ..connectTimeout = _requestTimeout
      ..sendTimeout = _requestTimeout
      ..receiveTimeout = _requestTimeout;
    installProtocolAdapter(dio, responseLimits.maxRawResponseBytes);
    return ProtocolClient._(
      dio,
      config,
      credentialStore,
      requestGate,
      HeaderPolicy(config: config, credentialStore: credentialStore),
      responseLimits,
    );
  }

  ProtocolClient._(
    this._dio,
    this._config,
    this._credentialStore,
    this._requestGate,
    this._headerPolicy,
    this._responseLimits,
  );

  static const Duration _requestTimeout = Duration(seconds: 12);

  static void _validateResponseLimits(ProtocolResponseLimits limits) {
    if (limits.maxRawResponseBytes <= 0) {
      throw ArgumentError.value(
        limits.maxRawResponseBytes,
        'responseLimits.maxRawResponseBytes',
        'must be positive',
      );
    }
    if (limits.maxDepth <= 0) {
      throw ArgumentError.value(
        limits.maxDepth,
        'responseLimits.maxDepth',
        'must be positive',
      );
    }
    if (limits.maxNodes <= 0) {
      throw ArgumentError.value(
        limits.maxNodes,
        'responseLimits.maxNodes',
        'must be positive',
      );
    }
  }

  final Dio _dio;
  final ApiConfig _config;
  final CredentialStore _credentialStore;
  final RequestGate _requestGate;
  final HeaderPolicy _headerPolicy;
  final ProtocolResponseLimits _responseLimits;

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

    final HeaderSelection headerSelection;
    try {
      headerSelection = await _headerPolicy.selectionFor(
        target: target,
        client: client,
      );
    } on Object {
      return const FailureResult(_credentialsUnavailableFailure);
    }

    final options = Options(
      method: method,
      connectTimeout: _requestTimeout,
      sendTimeout: body == null ? Duration.zero : _requestTimeout,
      receiveTimeout: _requestTimeout,
      responseType: ResponseType.plain,
      headers: headerSelection.headers,
    );

    try {
      final response = await _dio.requestUri<dynamic>(
        target,
        data: body,
        options: options,
      );
      return await _handleResponse(
        response.data,
        response.headers,
        headerSelection.snapshot,
      );
    } on ResponseTooLargeException {
      return const FailureResult(_responseTooLargeFailure);
    } on DioException catch (error) {
      if (error.error is ResponseTooLargeException) {
        return const FailureResult(_responseTooLargeFailure);
      }
      return FailureResult(_mapDioFailure(error.type));
    } on Object {
      return const FailureResult(_unknownFailure);
    }
  }

  Uri? _targetFor(String path, Map<String, Object?> query) {
    final requestSegments = CanonicalUri.decodeRequestPath(path);
    final baseSegments = CanonicalUri.safePathSegments(_config.apiBase);
    if (requestSegments == null || baseSegments == null) return null;
    return _config.apiBase.replace(
      pathSegments: <String>[...baseSegments, ...requestSegments],
      queryParameters: query.isEmpty ? null : query,
    );
  }

  Future<Result<Map<String, Object?>>> _handleResponse(
    Object? data,
    Headers responseHeaders,
    CredentialSnapshot? credentialSnapshot,
  ) async {
    if (_contentLengthExceedsLimit(responseHeaders)) {
      return const FailureResult(_responseTooLargeFailure);
    }

    Object? decoded = data;
    String? rawCodeToken;
    if (decoded is String) {
      if (decoded.length > _responseLimits.maxRawResponseBytes ||
          utf8.encode(decoded).length > _responseLimits.maxRawResponseBytes) {
        return const FailureResult(_responseTooLargeFailure);
      }
      try {
        rawCodeToken = _topLevelCodeToken(decoded);
        decoded = jsonDecode(decoded);
      } on FormatException {
        return const FailureResult(_invalidTopLevelFailure);
      }
    }
    if (decoded is! Map || decoded.keys.any((key) => key is! String)) {
      return const FailureResult(_invalidTopLevelFailure);
    }

    switch (_validateJsonShape(decoded)) {
      case _JsonShapeResult.valid:
        break;
      case _JsonShapeResult.tooLarge:
        return const FailureResult(_responseTooLargeFailure);
      case _JsonShapeResult.tooDeep:
        return const FailureResult(_responseTooDeepFailure);
      case _JsonShapeResult.invalid:
        return const FailureResult(_invalidTopLevelFailure);
    }

    final result = <String, Object?>{
      for (final entry in decoded.entries)
        entry.key as String: entry.value as Object?,
    };
    final code = _authCode(result['code'], rawCodeToken);
    if (code == 11 || code == 12) {
      if (credentialSnapshot case final snapshot?) {
        await _ignoreClearFailure(
          () => _credentialStore.clearTkIfMatches(snapshot.tk),
        );
      }
      return const FailureResult(_tkExpiredFailure);
    }
    if (code == 14 || code == 15) {
      if (credentialSnapshot case final snapshot?) {
        await _ignoreClearFailure(
          () => _credentialStore.clearStkIfMatches(snapshot.stk),
        );
      }
      return const FailureResult(_stkExpiredFailure);
    }
    return Success(result);
  }

  int? _authCode(Object? decodedCode, String? rawCodeToken) {
    if (rawCodeToken != null) {
      final token = rawCodeToken.trim();
      if (token == '11' || token == '12' || token == '14' || token == '15') {
        return int.parse(token);
      }
      if (token.startsWith('"')) {
        try {
          final value = jsonDecode(token);
          if (value is String &&
              (value == '11' ||
                  value == '12' ||
                  value == '14' ||
                  value == '15')) {
            return int.parse(value);
          }
        } on FormatException {
          return null;
        }
      }
      return null;
    }

    if (decodedCode is int &&
        (decodedCode == 11 ||
            decodedCode == 12 ||
            decodedCode == 14 ||
            decodedCode == 15)) {
      return decodedCode;
    }
    if (decodedCode is String &&
        (decodedCode == '11' ||
            decodedCode == '12' ||
            decodedCode == '14' ||
            decodedCode == '15')) {
      return int.parse(decodedCode);
    }
    return null;
  }

  String? _topLevelCodeToken(String source) {
    var index = _skipWhitespace(source, 0);
    if (index >= source.length || source.codeUnitAt(index) != 0x7b) return null;
    index += 1;
    String? found;

    while (true) {
      index = _skipWhitespace(source, index);
      if (index >= source.length || source.codeUnitAt(index) == 0x7d) {
        return found;
      }
      if (source.codeUnitAt(index) != 0x22) return null;
      final keyEnd = _skipJsonString(source, index);
      if (keyEnd == null) return null;
      final Object? key;
      try {
        key = jsonDecode(source.substring(index, keyEnd));
      } on FormatException {
        return null;
      }
      index = _skipWhitespace(source, keyEnd);
      if (index >= source.length || source.codeUnitAt(index) != 0x3a) {
        return null;
      }
      index = _skipWhitespace(source, index + 1);
      final valueStart = index;
      final valueEnd = _skipJsonValue(source, valueStart);
      if (valueEnd == null) return null;
      if (key == 'code') found = source.substring(valueStart, valueEnd);

      index = _skipWhitespace(source, valueEnd);
      if (index >= source.length) return null;
      final delimiter = source.codeUnitAt(index);
      if (delimiter == 0x7d) return found;
      if (delimiter != 0x2c) return null;
      index += 1;
    }
  }

  int _skipWhitespace(String source, int index) {
    while (index < source.length) {
      final codeUnit = source.codeUnitAt(index);
      if (codeUnit != 0x20 &&
          codeUnit != 0x09 &&
          codeUnit != 0x0a &&
          codeUnit != 0x0d) {
        break;
      }
      index += 1;
    }
    return index;
  }

  int? _skipJsonString(String source, int start) {
    var escaped = false;
    for (var index = start + 1; index < source.length; index += 1) {
      final codeUnit = source.codeUnitAt(index);
      if (escaped) {
        escaped = false;
      } else if (codeUnit == 0x5c) {
        escaped = true;
      } else if (codeUnit == 0x22) {
        return index + 1;
      }
    }
    return null;
  }

  int? _skipJsonValue(String source, int start) {
    if (start >= source.length) return null;
    if (source.codeUnitAt(start) == 0x22) return _skipJsonString(source, start);

    final opening = source.codeUnitAt(start);
    if (opening == 0x7b || opening == 0x5b) {
      final expectedClosings = <int>[opening == 0x7b ? 0x7d : 0x5d];
      var inString = false;
      var escaped = false;
      for (var index = start + 1; index < source.length; index += 1) {
        final codeUnit = source.codeUnitAt(index);
        if (inString) {
          if (escaped) {
            escaped = false;
          } else if (codeUnit == 0x5c) {
            escaped = true;
          } else if (codeUnit == 0x22) {
            inString = false;
          }
          continue;
        }
        if (codeUnit == 0x22) {
          inString = true;
        } else if (codeUnit == 0x7b) {
          expectedClosings.add(0x7d);
        } else if (codeUnit == 0x5b) {
          expectedClosings.add(0x5d);
        } else if (codeUnit == 0x7d || codeUnit == 0x5d) {
          if (expectedClosings.isEmpty ||
              expectedClosings.removeLast() != codeUnit) {
            return null;
          }
          if (expectedClosings.isEmpty) return index + 1;
        }
      }
      return null;
    }

    var index = start;
    while (index < source.length) {
      final codeUnit = source.codeUnitAt(index);
      if (codeUnit == 0x2c || codeUnit == 0x7d) break;
      index += 1;
    }
    return index > start ? index : null;
  }

  bool _contentLengthExceedsLimit(Headers headers) {
    final values = headers[Headers.contentLengthHeader];
    if (values == null || values.length != 1) return false;
    final contentLength = int.tryParse(values.single);
    return contentLength != null &&
        contentLength > _responseLimits.maxRawResponseBytes;
  }

  _JsonShapeResult _validateJsonShape(Map<Object?, Object?> root) {
    final pending = <(Object?, int)>[(root, 1)];
    final visitedContainers = HashSet<Object>.identity();
    var nodeCount = 0;

    while (pending.isNotEmpty) {
      final (value, depth) = pending.removeLast();
      nodeCount += 1;
      if (nodeCount > _responseLimits.maxNodes) {
        return _JsonShapeResult.tooLarge;
      }
      if (depth > _responseLimits.maxDepth) {
        return _JsonShapeResult.tooDeep;
      }

      switch (value) {
        case null || String() || bool():
          break;
        case num():
          if (!value.isFinite) return _JsonShapeResult.invalid;
        case Map():
          if (!visitedContainers.add(value)) return _JsonShapeResult.invalid;
          if (nodeCount + pending.length + value.length >
              _responseLimits.maxNodes) {
            return _JsonShapeResult.tooLarge;
          }
          for (final entry in value.entries) {
            if (entry.key is! String) return _JsonShapeResult.invalid;
            pending.add((entry.value, depth + 1));
          }
        case List():
          if (!visitedContainers.add(value)) return _JsonShapeResult.invalid;
          if (nodeCount + pending.length + value.length >
              _responseLimits.maxNodes) {
            return _JsonShapeResult.tooLarge;
          }
          for (final item in value) {
            pending.add((item, depth + 1));
          }
        default:
          return _JsonShapeResult.invalid;
      }
    }
    return _JsonShapeResult.valid;
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
  static const AppFailure _responseTooLargeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.response_too_large',
    safeMessage: '服务返回的数据过大',
  );
  static const AppFailure _responseTooDeepFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.response_too_deep',
    safeMessage: '服务返回的数据层级过深',
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

enum _JsonShapeResult { valid, tooLarge, tooDeep, invalid }
