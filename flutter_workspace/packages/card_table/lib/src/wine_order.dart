import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

final class WineSaveCsm {
  const WineSaveCsm({
    required this.id,
    required this.phone,
    required this.name,
    this.needSms = false,
  });

  final String id;
  final String phone;
  final String name;
  final bool needSms;
}

final class ProtocolWineOrderApi {
  const ProtocolWineOrderApi({required this.client});
  final ProtocolClient client;

  Future<Result<List<WineSaveCsm>>> listCsms(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/wine/get_csms_f_cj',
      body: <String, Object?>{'seat_id': _jsonId(seatId)},
      client: client,
    );
    return _readCsms(response);
  }

  Future<Result<void>> addCart(
    ClientKind client, {
    required String csmId,
    required String productId,
    required List<String> unitTypes,
    required List<int> counts,
    required List<int> grams,
  }) async {
    if (csmId.isEmpty ||
        productId.isEmpty ||
        unitTypes.isEmpty ||
        unitTypes.length != counts.length ||
        unitTypes.length != grams.length) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wine/add_sc_csm_cj_prd',
      body: <String, Object?>{
        'csm_id': _jsonId(csmId),
        'prd_id': _jsonId(productId),
        'unit_types': unitTypes,
        'prd_cnts': counts,
        'g_cnts': grams,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '添加存酒失败，请重试',
      disallowed: <String>[csmId, productId],
    );
  }

  Future<Result<void>> addAuthCart(
    ClientKind client, {
    required String csmId,
    required List<String> productIds,
    required List<String> unitTypes,
    required List<int> counts,
    required List<int> grams,
  }) async {
    if (csmId.isEmpty ||
        productIds.isEmpty ||
        productIds.length != unitTypes.length ||
        productIds.length != counts.length ||
        productIds.length != grams.length) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wine/add_sc_csm_auth_cj_prd',
      body: <String, Object?>{
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'pass_type': 1,
        'csm_id': _jsonId(csmId),
        'prd_ids': [for (final id in productIds) _jsonId(id)],
        'unit_types': unitTypes,
        'prd_cnts': counts,
        'g_cnts': grams,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '授权存酒失败，请重试',
      disallowed: <String>[csmId, ...productIds],
    );
  }

  Future<Result<void>> submitSave(
    ClientKind client, {
    required List<String> cartIds,
    required String phone,
    required String name,
    required String authCode,
    String remarkPhone = '',
    String remarkName = '-',
    String remark = '',
  }) async {
    if (cartIds.isEmpty || phone.isEmpty || name.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wine/new_cj_bef_in',
      body: <String, Object?>{
        'sc_ids': [for (final id in cartIds) _jsonId(id)],
        'phone_num_auth_code': authCode,
        'phone_num': phone,
        'cust_name': name,
        'remark_cust_phone': remarkPhone,
        'remark_cust_name': remarkName,
        'remark': remark,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '存酒失败，请重试',
      disallowed: <String>[phone, name, authCode, ...cartIds],
    );
  }

  Future<Result<void>> submitTake(
    ClientKind client, {
    required String seatId,
    required List<String> inventoryIds,
    required List<int> counts,
    required String phone,
    required String authCode,
  }) async {
    if (seatId.isEmpty ||
        inventoryIds.isEmpty ||
        inventoryIds.length != counts.length ||
        phone.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wine/new_qj_bef_out',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'invt_ids': [for (final id in inventoryIds) _jsonId(id)],
        'prd_cnts': counts,
        'phone_num_auth_code': authCode,
        'phone_num': phone,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '取酒失败，请重试',
      disallowed: <String>[seatId, phone, authCode, ...inventoryIds],
    );
  }

  Future<Result<void>> submitConfiscate(
    ClientKind client, {
    required String seatId,
    required String date,
    required String salesEmpId,
    required List<String> productIds,
    required List<String> unitTypes,
    required List<int> counts,
    required List<int> grams,
  }) async {
    if (seatId.isEmpty ||
        date.isEmpty ||
        salesEmpId.isEmpty ||
        productIds.isEmpty ||
        productIds.length != unitTypes.length ||
        productIds.length != counts.length ||
        productIds.length != grams.length) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wine/new_csm_cg_bef_in',
      body: <String, Object?>{
        'cg_day': date,
        'sales_emp_id': _jsonId(salesEmpId),
        'seat_id': _jsonId(seatId),
        'prd_ids': [for (final id in productIds) _jsonId(id)],
        'unit_types': unitTypes,
        'prd_cnts': counts,
        'g_cnts': grams,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '充公失败，请重试',
      disallowed: <String>[seatId, date, salesEmpId, ...productIds],
    );
  }

  Result<List<WineSaveCsm>> _readCsms(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const Success([]);
    final needSms = _wireCode(data['cust_in_need_sms']) == 1;
    final records = data['records'];
    if (records == null) return const Success([]);
    if (records is! List) return const FailureResult(_shapeFailure);
    final rows = <WineSaveCsm>[];
    for (final item in records) {
      if (item is! Map) return const FailureResult(_shapeFailure);
      final id = _asId(item['id']);
      if (id == null) return const FailureResult(_shapeFailure);
      rows.add(
        WineSaveCsm(
          id: id,
          phone: _money(item['p']),
          name: _money(item['n']),
          needSms: needSms,
        ),
      );
    }
    return Success(rows);
  }

  Result<void> _ack(
    Result<Map<String, Object?>> response, {
    required String fallback,
    required List<String> disallowed,
  }) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.wine_order_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: fallback,
            disallowed: disallowed,
          ),
        ),
      );
    }
    return const Success(null);
  }
}

String? _asId(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt().toString(),
  String() when value.isNotEmpty && value.length <= 64 => value,
  _ => null,
};

String _money(Object? value) => switch (value) {
  num() when value.isFinite => value.toString(),
  String() => value,
  _ => '',
};

Object _jsonId(String id) {
  final parsed = int.tryParse(id);
  return parsed ?? id;
}

int? _wireCode(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt(),
  String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(value),
  _ => null,
};

String _safeMessage(
  Object? value, {
  required String fallback,
  required List<String> disallowed,
}) {
  if (value is! String || value.isEmpty || value.length > 160) return fallback;
  for (final secret in disallowed) {
    if (secret.isNotEmpty && value.contains(secret)) return fallback;
  }
  if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(value)) return fallback;
  return value;
}

const AppFailure _shapeFailure = AppFailure(
  kind: FailureKind.protocol,
  code: 'protocol.wine_order_shape',
  safeMessage: '存酒接口返回了无法识别的数据',
);
const AppFailure _rejectedFailure = AppFailure(
  kind: FailureKind.business,
  code: 'business.wine_order_rejected',
  safeMessage: '服务端拒绝存酒操作，请重试',
);
