import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

abstract interface class BusinessDayApi {
  Future<Result<void>> open(ClientKind client);
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

  static int? _wireCode(Object? value) => switch (value) {
    num() when value.isFinite && value % 1 == 0 => value.toInt(),
    '1' => 1,
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
