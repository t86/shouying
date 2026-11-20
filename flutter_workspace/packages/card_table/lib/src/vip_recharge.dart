import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

final class VipCardHit {
  factory VipCardHit.fromWire(Map<String, Object?> source) {
    if (source.length > _maxFields) throw _invalid;
    return VipCardHit._(id: _id(source['id']), label: _text(source['n']));
  }

  const VipCardHit._({required this.id, required this.label});

  final String id;
  final String label;

  @override
  String toString() => 'VipCardHit(<redacted>)';
}

final class VipMemberCard {
  factory VipMemberCard.fromWire(Map<String, Object?> source) {
    if (source.length > _maxFields) throw _invalid;
    return VipMemberCard._(
      id: _id(source['id']),
      cardNo: _text(source['card_no']),
      name: _optional(source['name']),
      bindPhone: _optional(source['bind_phone']),
      storedBalance: _money(source['val_bal']),
      giftBalance: _money(source['free_bal']),
      totalBalance: _money(source['bal']),
      salesEmployeeId: _optionalId(source['sales_emp_id']),
    );
  }

  const VipMemberCard._({
    required this.id,
    required this.cardNo,
    required this.name,
    required this.bindPhone,
    required this.storedBalance,
    required this.giftBalance,
    required this.totalBalance,
    required this.salesEmployeeId,
  });

  final String id;
  final String cardNo;
  final String name;
  final String bindPhone;
  final String storedBalance;
  final String giftBalance;
  final String totalBalance;
  final String salesEmployeeId;

  @override
  String toString() => 'VipMemberCard(<redacted>)';
}

final class VipDepositRule {
  factory VipDepositRule.fromWire(Map<String, Object?> source) {
    if (source.length > _maxFields) throw _invalid;
    final depositFen = _fen(source['d']);
    final giftFen = _fen(source['f']);
    return VipDepositRule._(
      depositFen: depositFen,
      giftFen: giftFen,
      displayPrice: (depositFen / 100).toStringAsFixed(2),
      giftAmount: giftFen / 100,
      giftPoints: _int(source['fp']),
      giftCoupon: _optional(source['fkn']),
      couponId: _int(source['fk']),
    );
  }

  const VipDepositRule._({
    required this.depositFen,
    required this.giftFen,
    required this.displayPrice,
    required this.giftAmount,
    required this.giftPoints,
    required this.giftCoupon,
    required this.couponId,
  });

  final int depositFen;
  final int giftFen;
  final String displayPrice;
  final double giftAmount;
  final int giftPoints;
  final String giftCoupon;
  final int couponId;

  @override
  String toString() => 'VipDepositRule(<redacted>)';
}

final class VipRechargeOrder {
  const VipRechargeOrder({required this.orderId, required this.payId});
  final String orderId;
  final String payId;
}

final class VipRechargePay {
  const VipRechargePay({required this.scanUrl, required this.payResult});
  final String scanUrl;
  final int payResult;
}

final class VipLastSales {
  const VipLastSales({required this.id, required this.name});
  final String id;
  final String name;
}

final class VipOrderStatus {
  const VipOrderStatus({required this.payResult});
  final int payResult;
}

final class VipRechargeEmployee {
  const VipRechargeEmployee({
    required this.id,
    required this.name,
    this.code = '',
  });

  final String id;
  final String name;
  final String code;
}

final class ProtocolVipRechargeApi {
  const ProtocolVipRechargeApi({required this.client, this.canDispatch});
  final ProtocolClient client;
  final bool Function()? canDispatch;
  Future<Result<Map<String, Object?>>> _post(
    String path, {
    required Map<String, Object?> body,
    required ClientKind client,
  }) => this.client.post(
    path,
    body: body,
    client: client,
    canDispatch: canDispatch,
  );

  Future<Result<List<VipCardHit>>> search(
    ClientKind client, {
    required String keyword,
  }) async {
    if (keyword.length > _maxKeyword) return const FailureResult(_shapeFailure);
    final response = await _post(
      '/sel/get_cust_card_list_for_dept',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code != 1) return const Success([]);
    final data = envelope['data'];
    if (data == null) return const Success([]);
    if (data is! Map<String, Object?>) {
      return const FailureResult(_shapeFailure);
    }
    return _readRecords(data, VipCardHit.fromWire);
  }

  Future<Result<VipMemberCard>> detail(
    ClientKind client, {
    required String cardId,
  }) async {
    final response = await _post(
      '/mb/card/get_mb_card_f_deposit',
      body: <String, Object?>{'id': _jsonId(cardId)},
      client: client,
    );
    return _readMap(response, (data) {
      final card = data['mb_card'];
      if (card is! Map<String, Object?>) throw _invalid;
      return VipMemberCard.fromWire(card);
    });
  }

  Future<Result<List<VipDepositRule>>> rules(
    ClientKind client, {
    required String cardId,
  }) async {
    final response = await _post(
      '/sel/get_deposit_rules_for_dept',
      body: <String, Object?>{'id': _jsonId(cardId)},
      client: client,
    );
    return _readList(response, (map) => VipDepositRule.fromWire(map));
  }

  Future<Result<VipRechargeOrder>> createOrder(
    ClientKind client, {
    required Map<String, Object?> body,
  }) async {
    bool integer(Object? v, {int min = 0}) =>
        v is int && v >= min && v <= 9007199254740991;
    if (!const [1, 2].contains(body['mode']) ||
        !integer(body['id'], min: 1) ||
        !integer(body['deposit_amt'], min: 1) ||
        [
          'free_amt',
          'free_pt_amt',
          'free_kq_id',
          'sales_emp_id',
        ].any((key) => !integer(body[key])) ||
        (body.containsKey('csm_id') && !integer(body['csm_id'], min: 1)) ||
        body['remark'] is! String ||
        (body['remark'] as String).length > 2048)
      return const FailureResult(_invalidRequest);
    final response = await _post(
      '/wo/new_cust_dept_order',
      body: body,
      client: client,
    );
    return _readMap(response, (data) {
      return VipRechargeOrder(
        orderId: _id(data['order_id']),
        payId: _id(data['pay_id']),
      );
    });
  }

  Future<Result<VipRechargePay>> createPay(
    ClientKind client, {
    required String payId,
    required int payAmtFen,
    required int payType,
    String authCode = '',
  }) async {
    if (payId.isEmpty ||
        payAmtFen <= 0 ||
        payAmtFen > 9007199254740991 ||
        !const [1, 2, 5, 6].contains(payType) ||
        (const [5, 6].contains(payType) && authCode.trim().isEmpty) ||
        authCode.length > 2048)
      return const FailureResult(_invalidRequest);
    final response = await _post(
      '/wo/new_cust_dept_order_pay',
      body: <String, Object?>{
        'pay_id': payId,
        'pay_amt': payAmtFen,
        'pay_type': payType,
        'auth_code': authCode,
      },
      client: client,
    );
    return _readMap(response, (data) {
      return VipRechargePay(
        scanUrl: _optional(data['scan_url']),
        payResult: _payStatus(data['pay_rst']),
      );
    });
  }

  Future<Result<VipLastSales?>> lastSales(
    ClientKind client, {
    required String cardId,
  }) async {
    final response = await _post(
      '/wo/get_cust_card_last_sales',
      body: <String, Object?>{'card_id': _jsonId(cardId)},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code != 1) return const Success(null);
    final data = envelope['data'];
    if (data == null) return const Success(null);
    if (data is! Map<String, Object?>) {
      return const FailureResult(_shapeFailure);
    }
    final id = data['id'];
    if (id == null || id == '') return const Success(null);
    try {
      return Success(VipLastSales(id: _id(id), name: _optional(data['name'])));
    } on FormatException {
      return const FailureResult(_shapeFailure);
    }
  }

  Future<Result<VipOrderStatus>> orderStatus(
    ClientKind client, {
    required String orderId,
  }) async {
    final response = await _post(
      '/wo/get_cust_dept_order_status',
      body: <String, Object?>{'order_id': orderId},
      client: client,
    );
    return _readMap(
      response,
      (data) => VipOrderStatus(payResult: _payStatus(data['pay_rst'])),
    );
  }

  Result<List<T>> _readList<T>(
    Result<Map<String, Object?>> response,
    T Function(Map<String, Object?>) parse,
  ) {
    final data = _data(response);
    if (data is FailureResult<Map<String, Object?>>) {
      return FailureResult(data.failureOrNull!);
    }
    return _readRecords(data.valueOrNull!, parse);
  }

  Result<List<T>> _readRecords<T>(
    Map<String, Object?> data,
    T Function(Map<String, Object?>) parse,
  ) {
    final records = data['records'];
    if (records == null) return const Success([]);
    if (records is! List || records.length > _maxRows) {
      return const FailureResult(_shapeFailure);
    }
    try {
      return Success(
        List<T>.unmodifiable([
          for (final record in records)
            if (record is Map<String, Object?>)
              parse(record)
            else
              throw _invalid,
        ]),
      );
    } on FormatException {
      return const FailureResult(_shapeFailure);
    }
  }

  Result<T> _readMap<T>(
    Result<Map<String, Object?>> response,
    T Function(Map<String, Object?>) parse,
  ) {
    final data = _data(response);
    if (data is FailureResult<Map<String, Object?>>) {
      return FailureResult(data.failureOrNull!);
    }
    try {
      return Success(parse(data.valueOrNull!));
    } on FormatException {
      return const FailureResult(_shapeFailure);
    }
  }

  Result<Map<String, Object?>> _data(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map<String, Object?>) {
      return const FailureResult(_shapeFailure);
    }
    return Success(data);
  }
}

int _payStatus(Object? value) {
  final status = _wireCode(value);
  if (status == null || !const [0, 1, 2].contains(status)) throw _invalid;
  return status;
}

const _invalidRequest = AppFailure(
  kind: FailureKind.business,
  code: 'vip_recharge.invalid_request',
  safeMessage: '充值金额或支付信息无效，请检查后重试',
);

Object _jsonId(String id) {
  final parsed = int.tryParse(id);
  return parsed ?? id;
}

String _id(Object? value) => switch (value) {
  String() when value.isNotEmpty && value.length <= 64 => value,
  num() when value.isFinite && value % 1 == 0 => value.toInt().toString(),
  _ => throw _invalid,
};

String _optionalId(Object? value) =>
    value == null || value == '' ? '' : _id(value);

String _text(Object? value) {
  final text = _optional(value);
  if (text.isEmpty) throw _invalid;
  return text;
}

String _optional(Object? value) => switch (value) {
  null => '',
  String() when value.length <= 2048 => value,
  num() when value.isFinite => value.toString(),
  _ => throw _invalid,
};

String _money(Object? value) {
  if (value == null) return '0.00';
  return _optional(value);
}

int _fen(Object? value) {
  final number = switch (value) {
    num() when value.isFinite => value,
    String() => num.tryParse(value),
    _ => null,
  };
  if (number == null || !number.isFinite || number % 1 != 0 || number < 0) {
    throw _invalid;
  }
  return number.toInt();
}

int _int(Object? value) {
  if (value == null || value == '') return 0;
  return _fen(value);
}

int? _wireCode(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt(),
  String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(value),
  _ => null,
};

const int _maxRows = 10000;
const int _maxFields = 64;
const int _maxKeyword = 2048;
const FormatException _invalid = FormatException(
  'Invalid vip recharge payload',
);
const AppFailure _shapeFailure = AppFailure(
  kind: FailureKind.protocol,
  code: 'protocol.vip_recharge_shape',
  safeMessage: '会员充值返回了无法识别的数据',
);
const AppFailure _rejectedFailure = AppFailure(
  kind: FailureKind.business,
  code: 'business.vip_recharge_rejected',
  safeMessage: '服务端拒绝会员充值操作，请重试',
);
