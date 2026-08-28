import 'dart:collection';
import 'dart:convert';

import 'package:foundation/foundation.dart';

enum SyncEventType {
  data(1),
  heartbeat(2),
  serverError(3);

  const SyncEventType(this.code);

  final int code;

  static SyncEventType? fromCode(int code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

final class SyncEnvelope {
  const SyncEnvelope._({
    required this.type,
    required this.cursor,
    required this.data,
  });

  static const int maxRawMessageBytes = 2 * 1024 * 1024;
  static const int maxJsonDepth = 32;
  static const int maxJsonNodes = 10000;
  static final RegExp _cursorPattern = RegExp(r'^\d{14}$');

  final SyncEventType type;
  final String? cursor;
  final Object? data;

  static bool isCanonicalCursor(Object? value) =>
      value is String && _cursorPattern.hasMatch(value);

  static Result<SyncEnvelope> parse(Object? input) {
    Object? decoded = input;
    if (input is String) {
      if (input.length > maxRawMessageBytes) {
        return const FailureResult(_messageTooLargeFailure);
      }
      try {
        if (utf8.encode(input).length > maxRawMessageBytes) {
          return const FailureResult(_messageTooLargeFailure);
        }
        decoded = jsonDecode(input);
      } on FormatException {
        return const FailureResult(_invalidEnvelopeFailure);
      } on Object {
        return const FailureResult(_invalidEnvelopeFailure);
      }
    }

    final guard = _JsonGuard();
    final Object? frozen;
    try {
      frozen = guard.freeze(decoded, depth: 0);
    } on _JsonLimitException catch (error) {
      return FailureResult(error.failure);
    } on Object {
      return const FailureResult(_invalidEnvelopeFailure);
    }
    if (frozen is! Map<String, Object?>) {
      return const FailureResult(_invalidEnvelopeFailure);
    }

    final code = _exactCode(frozen['p']);
    final type = code == null ? null : SyncEventType.fromCode(code);
    if (type == null || !frozen.containsKey('d')) {
      return const FailureResult(_invalidEnvelopeFailure);
    }

    final cursorValue = frozen['t'];
    final cursor = isCanonicalCursor(cursorValue)
        ? cursorValue! as String
        : null;
    if (type != SyncEventType.serverError && cursor == null) {
      return const FailureResult(_invalidEnvelopeFailure);
    }
    if (type == SyncEventType.serverError &&
        cursorValue != null &&
        cursor == null) {
      return const FailureResult(_invalidEnvelopeFailure);
    }

    return Success(
      SyncEnvelope._(type: type, cursor: cursor, data: frozen['d']),
    );
  }

  /// Builds an event from a [ProtocolSyncApi] batch that has already passed
  /// the HTTP response byte, depth, node, JSON-shape, and immutability checks.
  /// Live WebSocket input must continue to use [parse].
  static SyncEnvelope fromValidatedReconciliation({
    required String cursor,
    required Object? data,
  }) {
    if (!isCanonicalCursor(cursor)) {
      throw ArgumentError.value(cursor, 'cursor', 'must be yyyyMMddHHmmss');
    }
    return SyncEnvelope._(type: SyncEventType.data, cursor: cursor, data: data);
  }

  static SyncEnvelope safeServerError({String? cursor}) => SyncEnvelope._(
    type: SyncEventType.serverError,
    cursor: cursor,
    data: '实时同步服务返回错误',
  );

  static int? _exactCode(Object? value) {
    if (value is String) {
      return switch (value) {
        '1' => 1,
        '2' => 2,
        '3' => 3,
        _ => null,
      };
    }
    if (value is! num || !value.isFinite || value % 1 != 0) return null;
    final code = value.toInt();
    return code >= 1 && code <= 3 ? code : null;
  }

  @override
  String toString() =>
      'SyncEnvelope(type: ${type.name}, cursor: ${cursor ?? 'none'})';

  static const AppFailure _invalidEnvelopeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.websocket_envelope',
    safeMessage: '实时同步服务返回了无法识别的数据',
  );
  static const AppFailure _messageTooLargeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.websocket_message_too_large',
    safeMessage: '实时同步消息超出安全大小限制',
  );
  static const AppFailure _messageTooDeepFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.websocket_message_too_deep',
    safeMessage: '实时同步消息结构过深',
  );
  static const AppFailure _messageTooComplexFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.websocket_message_too_complex',
    safeMessage: '实时同步消息结构过于复杂',
  );
}

final class _JsonGuard {
  final Set<Object> _active = HashSet<Object>.identity();
  int _nodes = 0;
  int _characters = 0;
  int _utf8Bytes = 0;

  Object? freeze(Object? value, {required int depth}) {
    _nodes += 1;
    if (_nodes > SyncEnvelope.maxJsonNodes) {
      throw const _JsonLimitException(SyncEnvelope._messageTooComplexFailure);
    }
    if (depth > SyncEnvelope.maxJsonDepth) {
      throw const _JsonLimitException(SyncEnvelope._messageTooDeepFailure);
    }
    if (value == null || value is bool) return value;
    if (value is String) {
      _consumeString(value);
      return value;
    }
    if (value is num) {
      if (!value.isFinite) {
        throw const _JsonLimitException(SyncEnvelope._invalidEnvelopeFailure);
      }
      return value;
    }
    if (value is Map) {
      if (!_active.add(value)) {
        throw const _JsonLimitException(SyncEnvelope._invalidEnvelopeFailure);
      }
      try {
        final result = <String, Object?>{};
        for (final entry in value.entries) {
          final key = entry.key;
          if (key is! String) {
            throw const _JsonLimitException(
              SyncEnvelope._invalidEnvelopeFailure,
            );
          }
          _consumeString(key);
          result[key] = freeze(entry.value, depth: depth + 1);
        }
        return Map<String, Object?>.unmodifiable(result);
      } finally {
        _active.remove(value);
      }
    }
    if (value is List) {
      if (!_active.add(value)) {
        throw const _JsonLimitException(SyncEnvelope._invalidEnvelopeFailure);
      }
      try {
        return List<Object?>.unmodifiable(
          value.map((item) => freeze(item, depth: depth + 1)),
        );
      } finally {
        _active.remove(value);
      }
    }
    throw const _JsonLimitException(SyncEnvelope._invalidEnvelopeFailure);
  }

  void _consumeString(String value) {
    _characters += value.length;
    if (_characters > SyncEnvelope.maxRawMessageBytes) {
      throw const _JsonLimitException(SyncEnvelope._messageTooLargeFailure);
    }
    _utf8Bytes += utf8.encode(value).length;
    if (_utf8Bytes > SyncEnvelope.maxRawMessageBytes) {
      throw const _JsonLimitException(SyncEnvelope._messageTooLargeFailure);
    }
  }
}

final class _JsonLimitException implements Exception {
  const _JsonLimitException(this.failure);

  final AppFailure failure;
}
