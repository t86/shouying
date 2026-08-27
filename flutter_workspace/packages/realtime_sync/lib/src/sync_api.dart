import 'dart:collection';

import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/src/sync_envelope.dart';

final class SyncBatch {
  const SyncBatch({
    required this.cursor,
    required this.data,
    required this.hasChanges,
  });

  final String cursor;
  final Object? data;
  final bool hasChanges;

  @override
  String toString() => 'SyncBatch(cursor: $cursor, hasChanges: $hasChanges)';
}

abstract interface class SyncApi {
  Future<Result<SyncBatch>> fetchAll(ClientKind client);

  Future<Result<SyncBatch>> fetchIncrement(
    ClientKind client,
    String lastSyncTime,
  );
}

final class ProtocolSyncApi implements SyncApi {
  factory ProtocolSyncApi({required ProtocolClient client}) =>
      ProtocolSyncApi._(client);

  const ProtocolSyncApi._(this._client);

  final ProtocolClient _client;

  @override
  Future<Result<SyncBatch>> fetchAll(ClientKind client) async {
    final response = await _client.post('/sync_base/all', client: client);
    return _mapResponse(response);
  }

  @override
  Future<Result<SyncBatch>> fetchIncrement(
    ClientKind client,
    String lastSyncTime,
  ) async {
    if (!SyncEnvelope.isCanonicalCursor(lastSyncTime)) {
      return const FailureResult(_invalidCursorFailure);
    }
    final response = await _client.post(
      '/sync_base/increment',
      body: <String, Object?>{'last_sync_time': lastSyncTime},
      client: client,
    );
    return _mapResponse(response);
  }

  Result<SyncBatch> _mapResponse(Result<Map<String, Object?>> response) {
    final failure = response.failureOrNull;
    if (failure != null) return FailureResult(failure);
    final payload = response.valueOrNull!;
    final code = _wireCode(payload['code']);
    if (code == null) return const FailureResult(_responseShapeFailure);
    if (code != 1 && code != 2) {
      return const FailureResult(_businessFailure);
    }

    final data = _stringKeyedMap(payload['data']);
    final cursor = data?['ts'];
    if (data == null || !SyncEnvelope.isCanonicalCursor(cursor)) {
      return const FailureResult(_responseShapeFailure);
    }
    if (!data.containsKey('ds')) {
      return const FailureResult(_responseShapeFailure);
    }

    final Object? frozenData;
    try {
      frozenData = _freezeJson(data['ds'], HashSet<Object>.identity());
    } on Object {
      return const FailureResult(_responseShapeFailure);
    }
    return Success(
      SyncBatch(
        cursor: cursor! as String,
        data: frozenData,
        hasChanges: code == 1,
      ),
    );
  }

  static int? _wireCode(Object? value) => switch (value) {
    num()
        when value.isFinite &&
            value % 1 == 0 &&
            value.abs() <= 9007199254740991 =>
      value.toInt(),
    String() when value == '1' || value == '2' => int.parse(value),
    String() when value.length <= 16 && RegExp(r'^[1-9]\d*$').hasMatch(value) =>
      int.tryParse(value),
    _ => null,
  };

  static Map<String, Object?>? _stringKeyedMap(Object? value) {
    if (value is! Map || value.keys.any((key) => key is! String)) return null;
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key as String: entry.value as Object?,
    };
  }

  static Object? _freezeJson(Object? value, Set<Object> active) {
    if (value == null || value is bool || value is String) return value;
    if (value is num && value.isFinite) return value;
    if (value is Map) {
      if (!active.add(value) || value.keys.any((key) => key is! String)) {
        throw const FormatException();
      }
      try {
        return Map<String, Object?>.unmodifiable(<String, Object?>{
          for (final entry in value.entries)
            entry.key as String: _freezeJson(entry.value, active),
        });
      } finally {
        active.remove(value);
      }
    }
    if (value is List) {
      if (!active.add(value)) throw const FormatException();
      try {
        return List<Object?>.unmodifiable(
          value.map((item) => _freezeJson(item, active)),
        );
      } finally {
        active.remove(value);
      }
    }
    throw const FormatException();
  }

  @override
  String toString() => 'ProtocolSyncApi()';

  static const AppFailure _invalidCursorFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.sync_cursor',
    safeMessage: '同步游标格式无效',
  );
  static const AppFailure _responseShapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.sync_response_shape',
    safeMessage: '同步服务返回了无法识别的数据',
  );
  static const AppFailure _businessFailure = AppFailure(
    kind: FailureKind.business,
    code: 'business.sync_rejected',
    safeMessage: '同步服务暂时无法完成请求',
  );
}
