import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

final class AutoCloseConfig {
  const AutoCloseConfig({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;
}

abstract interface class BusinessDayApi {
  Future<Result<void>> open(ClientKind client);

  Future<Result<void>> close(ClientKind client, {bool Function()? canDispatch});

  Future<Result<void>> printShift(
    ClientKind client, {
    bool Function()? canDispatch,
  });

  Future<Result<AutoCloseConfig>> loadAutoClose(
    ClientKind client, {
    bool Function()? canDispatch,
  });

  Future<Result<void>> saveAutoClose(
    ClientKind client, {
    required bool enabled,
    required int hour,
    required int minute,
    bool Function()? canDispatch,
  });
}

final class ProtocolBusinessDayApi implements BusinessDayApi {
  const ProtocolBusinessDayApi({required this.client});

  final ProtocolClient client;

  @override
  Future<Result<void>> open(ClientKind client) async {
    final response = await this.client.post('/wkd/start', client: client);
    final failure = response.failureOrNull;
    if (failure != null) return FailureResult(failure);
    final code = _wireCode(response.valueOrNull!['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> close(
    ClientKind client, {
    bool Function()? canDispatch,
  }) async {
    final response = await this.client.post(
      '/wkd/close',
      canDispatch: canDispatch,
      body: const <String, Object?>{},
      client: client,
    );
    return _ack(response, rejected: '服务端拒绝结束营业日');
  }

  @override
  Future<Result<void>> printShift(
    ClientKind client, {
    bool Function()? canDispatch,
  }) async {
    final response = await this.client.post(
      '/wkd/prt_bj',
      canDispatch: canDispatch,
      body: const <String, Object?>{
        'region_ids': [-1],
        'cashier_ids': [-1],
      },
      client: client,
    );
    return _ack(response, rejected: '服务端拒绝打印班结表');
  }

  @override
  Future<Result<AutoCloseConfig>> loadAutoClose(
    ClientKind client, {
    bool Function()? canDispatch,
  }) async {
    final response = await this.client.post(
      '/wkd/auto_close_cfg',
      canDispatch: canDispatch,
      body: const <String, Object?>{},
      client: client,
    );
    final failure = response.failureOrNull;
    if (failure != null) return FailureResult(failure);
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.business_day_rejected',
          safeMessage: '服务端拒绝读取自动结束营业日',
        ),
      );
    }
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    final hour = _wireCode(data['hour']);
    final minute = _wireCode(data['minute']);
    final onOff = _wireCode(data['on_off']);
    if (hour == null ||
        minute == null ||
        onOff == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        (onOff != 1 && onOff != 2)) {
      return const FailureResult(_shapeFailure);
    }
    return Success(
      AutoCloseConfig(enabled: onOff == 1, hour: hour, minute: minute),
    );
  }

  @override
  Future<Result<void>> saveAutoClose(
    ClientKind client, {
    required bool enabled,
    required int hour,
    required int minute,
    bool Function()? canDispatch,
  }) async {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wkd/save_auto_close',
      canDispatch: canDispatch,
      body: <String, Object?>{
        'on_off': enabled ? 1 : 2,
        'hour': enabled ? hour : 0,
        'minute': enabled ? minute : 0,
      },
      client: client,
    );
    return _ack(response, rejected: '服务端拒绝保存自动结束营业日');
  }

  Future<Result<void>> _ack(
    Result<Map<String, Object?>> response, {
    required String rejected,
  }) async {
    final failure = response.failureOrNull;
    if (failure != null) return FailureResult(failure);
    final code = _wireCode(response.valueOrNull!['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.business_day_rejected',
          safeMessage: rejected,
        ),
      );
    }
    return const Success<void>(null);
  }

  static int? _wireCode(Object? value) => switch (value) {
    num() when value.isFinite && value % 1 == 0 => value.toInt(),
    String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(
      value,
    ),
    _ => null,
  };

  static const AppFailure _shapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.business_day_shape',
    safeMessage: '营业日服务返回了无法识别的数据',
  );
  static const AppFailure _rejectedFailure = AppFailure(
    kind: FailureKind.business,
    code: 'business.business_day_rejected',
    safeMessage: '服务端拒绝开启营业日',
  );
}
