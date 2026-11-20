import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:card_table/src/pay_order_models.dart'
    show RecordedOrderPrice, OrderSummary;

const orderRefundAuthorizationRequiredCode =
    'order_refund.authorization_required';
const orderSetAuthorizationRequiredCode = 'order_set.authorization_required';

final class OrderSetItem {
  const OrderSetItem({
    this.id = '',
    required this.groupId,
    required this.detailProductId,
    required this.detailCount,
    required this.selectCount,
    this.requirement = '',
  });
  final String id, groupId, detailProductId, requirement;
  final int detailCount, selectCount;
  bool get valid =>
      _setId(groupId) != null &&
      _setId(detailProductId) != null &&
      detailCount > 0 &&
      selectCount > 0 &&
      requirement.length <= 200;
}

final class OrderCartItem {
  const OrderCartItem({
    required this.id,
    required this.productId,
    required this.count,
    required this.unitPrice,
    required this.amount,
    this.isSet = false,
    this.setItems = const [],
  });

  final String id;
  final String productId;
  final int count;
  final String unitPrice;
  final String amount;
  final bool isSet;
  final List<OrderSetItem> setItems;
  bool get setEditable =>
      isSet && setItems.isNotEmpty && setItems.every((item) => item.valid);

  @override
  String toString() => 'OrderCartItem(id: $id, count: $count)';
}

final class OrderGuestHit {
  const OrderGuestHit({required this.phone, required this.name});

  final String phone;
  final String name;

  @override
  String toString() => 'OrderGuestHit(<redacted>)';
}

final class OrderSetDetail {
  const OrderSetDetail({
    required this.productId,
    required this.groupId,
    required this.detailProductId,
    required this.detailCount,
    required this.groupSelectCount,
    required this.name,
    this.typeId = '1',
    this.seqId = 0,
    this.templateResolved = false,
  });

  final String productId;
  final String groupId;
  final String detailProductId;
  final int detailCount;
  final int groupSelectCount;
  final String name;
  final String typeId;
  final int seqId;
  final bool templateResolved;

  bool get fixed => groupId == '1';
}

final class OrderPlacedItem {
  const OrderPlacedItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.count,
    required String unitPrice,
    required String amount,
    this.recordedUnitPrice,
    this.authorizationType = 0,
    required this.orderedAt,
    required this.waiterName,
    this.status = 0,
    this.refunded = false,
    this.online = false,
    this.isSet = false,
    this.setItems = const [],
  }) : originalUnitPrice = unitPrice,
       recordedAmount = amount;

  final String id;
  final String productId;
  final String name;
  final int count;
  final String originalUnitPrice, recordedAmount;
  final String? recordedUnitPrice;
  final int authorizationType;
  RecordedOrderPrice get recordedPrice => RecordedOrderPrice(
    originalPrice: RecordedOrderPrice.number(originalUnitPrice),
    recordedPrice: RecordedOrderPrice.number(recordedUnitPrice),
    recordedAmount: RecordedOrderPrice.number(recordedAmount),
    count: count,
    authorizationType: authorizationType,
  );
  String get unitPrice => isTimePrice
      ? '时价'
      : RecordedOrderPrice.number(recordedUnitPrice) != null
      ? recordedUnitPrice!
      : originalUnitPrice;
  String get amount =>
      (authorizationType == 2 ||
          authorizationType == 3 ||
          (count == 0 && !isTimePrice))
      ? '0.0'
      : RecordedOrderPrice.number(recordedAmount) != null
      ? recordedAmount
      : recordedPrice.amountFor().toString();
  bool get isTimePrice => recordedPrice.isTimePrice;
  bool get canSplit => !isTimePrice;
  String get displayUnitPrice => recordedPrice.displayUnitPrice;
  double amountForCount(num selectedCount) =>
      recordedPrice.amountFor(changeCount: selectedCount);
  double refundAmount({num? count}) =>
      recordedPrice.amountFor(changeCount: count, refund: true);
  final String orderedAt;
  final String waiterName;
  final int status;
  final bool refunded;
  final bool online;
  final bool isSet;
  final List<OrderSetItem> setItems;
  bool get setEditable =>
      isSet &&
      !refunded &&
      !paid &&
      count > 0 &&
      setItems.isNotEmpty &&
      setItems.every((item) => item.valid && _setId(item.id) != null);

  bool get paid => status == 5;

  @override
  String toString() => 'OrderPlacedItem(id: $id, count: $count)';
}

final class OrderPlacedData {
  const OrderPlacedData({this.items = const [], this.summary});
  final List<OrderPlacedItem> items;
  final OrderSummary? summary;
}

final class WaiterPayQr {
  const WaiterPayQr({
    required this.payId,
    required this.amountFen,
    required this.payUrl,
  });

  final String payId;
  final int amountFen;
  final String payUrl;
}

final class ProtocolOrderMealApi {
  const ProtocolOrderMealApi({required this.client});
  final ProtocolClient client;

  Future<Result<void>> addProduct(
    ClientKind client, {
    required String seatId,
    required String productId,
    required int count,
    required String price,
    String amount = '',
    int authType = 0,
  }) async {
    if (seatId.isEmpty ||
        productId.isEmpty ||
        count < 1 ||
        count > 9999 ||
        price.isEmpty ||
        price.length > 32 ||
        amount.length > 32) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/add_prd',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'prd_id': _jsonId(productId),
        'prd_cnt': count,
        'prd_price': price,
        'auth_type': authType,
        'prd_amt': amount,
        'requirement': '',
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '加入购物车失败，请重试',
      disallowed: <String>[seatId, productId, price, amount],
    );
  }

  Future<Result<int>> cartCount(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/wsc/get_item_cnt',
      body: <String, Object?>{'id': _jsonId(seatId)},
      client: client,
    );
    return _readCount(response);
  }

  Future<Result<List<OrderCartItem>>> listItems(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/wsc/get_items',
      body: <String, Object?>{'id': _jsonId(seatId)},
      client: client,
    );
    return _readItems(response);
  }

  Future<Result<void>> setCount(
    ClientKind client, {
    required String seatId,
    required String itemId,
    required int count,
  }) async {
    if (seatId.isEmpty || itemId.isEmpty || count < 0 || count > 999999) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/set_cnt',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'id': _jsonId(itemId),
        'cnt': count,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '修改购物车失败，请重试',
      disallowed: <String>[seatId, itemId],
    );
  }

  Future<Result<void>> bindWaiter(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/wo/set_csm_waiter',
      body: <String, Object?>{'seat_id': _jsonId(seatId)},
      client: client,
    );
    return _ack(
      response,
      fallback: '绑定服务员失败，请重试',
      disallowed: <String>[seatId],
    );
  }

  Future<Result<List<OrderGuestHit>>> searchGuests(
    ClientKind client, {
    required String phone,
  }) async {
    if (phone.isEmpty || phone.length > 11) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wo/get_cust_items_for_csm',
      body: <String, Object?>{'cust_phone': phone},
      client: client,
    );
    return _readGuests(response);
  }

  Future<Result<void>> bindGuest(
    ClientKind client, {
    required String seatId,
    required String phone,
    Duration pollInterval = const Duration(seconds: 1),
    int maxAttempts = 30,
  }) async {
    if (seatId.isEmpty || phone.isEmpty || phone.length > 11) {
      return const FailureResult(_shapeFailure);
    }
    final setResponse = await this.client.post(
      '/wo/set_csm_cust',
      body: <String, Object?>{'cust_phone': phone, 'seat_id': _jsonId(seatId)},
      client: client,
    );
    if (setResponse.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = setResponse.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.order_meal_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: '绑定客人失败，请重试',
            disallowed: <String>[seatId, phone],
          ),
        ),
      );
    }
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    final orderId = _asId(data['order_id']);
    if (orderId == null) return const FailureResult(_shapeFailure);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (pollInterval > Duration.zero) {
        await Future<void>.delayed(pollInterval);
      }
      final poll = await this.client.post(
        '/wo/get_set_csm_cust_rst',
        body: <String, Object?>{'order_id': _jsonId(orderId)},
        client: client,
      );
      if (poll.failureOrNull != null) continue;
      final pollEnvelope = poll.valueOrNull!;
      if (_wireCode(pollEnvelope['code']) != 1) continue;
      final pollData = pollEnvelope['data'];
      if (pollData is! Map) continue;
      final status = _wireCode(pollData['s']);
      if (status == 1) continue;
      if (status == 5) return const Success(null);
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.order_meal_rejected',
          safeMessage: _safeMessage(
            pollData['m'],
            fallback: '绑定客人失败，请重试',
            disallowed: <String>[seatId, phone],
          ),
        ),
      );
    }
    return const FailureResult(
      AppFailure(
        kind: FailureKind.business,
        code: 'business.order_bind_guest_timeout',
        safeMessage: '操作超时，请重试',
      ),
    );
  }

  Future<Result<List<OrderPlacedItem>>> listOrders(
    ClientKind client, {
    required String seatId,
    required int turnoverCount,
  }) async {
    final result = await listOrdersWithSummary(
      client,
      seatId: seatId,
      turnoverCount: turnoverCount,
    );
    if (result.failureOrNull case final failure?) return FailureResult(failure);
    return Success(result.valueOrNull!.items);
  }

  Future<Result<OrderPlacedData>> listOrdersWithSummary(
    ClientKind client, {
    required String seatId,
    required int turnoverCount,
  }) async {
    if (seatId.isEmpty || turnoverCount < 0) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wo/list',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'turnover_cnt': turnoverCount,
      },
      client: client,
    );
    final rows = _readOrders(response);
    if (rows.failureOrNull case final failure?) return FailureResult(failure);
    final data = response.valueOrNull?['data'];
    final info = data is Map ? data['pay_info'] : null;
    return Success(
      OrderPlacedData(
        items: rows.valueOrNull!,
        summary: info is Map<String, Object?>
            ? OrderSummary.fromWire(info)
            : null,
      ),
    );
  }

  Future<Result<void>> placeOrder(
    ClientKind client, {
    required String seatId,
    required List<String> cartItemIds,
  }) async {
    if (seatId.isEmpty || cartItemIds.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final ids = <Object>[];
    for (final id in cartItemIds) {
      if (id.isEmpty || id.length > 64) {
        return const FailureResult(_shapeFailure);
      }
      ids.add(_jsonId(id));
    }
    final response = await this.client.post(
      '/wsc/order',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'shopping_cart_ids': ids,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '下单失败，请重试',
      disallowed: <String>[seatId, ...cartItemIds],
      successCodes: const {1, 5},
    );
  }

  Future<Result<void>> addTimed(
    ClientKind client, {
    required String seatId,
    required String productId,
    required int count,
    required String amount,
    String requirement = '',
  }) async {
    if (seatId.isEmpty ||
        productId.isEmpty ||
        count < 1 ||
        count > 9999 ||
        amount.length > 32 ||
        requirement.length > 200) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/add_hl',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'prd_id': _jsonId(productId),
        'prd_cnt': count,
        'prd_amt': amount,
        'requirement': requirement,
        'relate_csm_id': 0,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '加入购物车失败，请重试',
      disallowed: <String>[seatId, productId, amount],
    );
  }

  Future<Result<void>> addSet(
    ClientKind client, {
    required String seatId,
    required String productId,
    required int count,
    required int priceFen,
    required List<String> groupIds,
    required List<String> detailProductIds,
    required List<int> detailCounts,
    required List<int> selectCounts,
    List<String> requirements = const [],
    int authType = 0,
  }) async {
    if (_setId(seatId) == null ||
        _setId(productId) == null ||
        count < 1 ||
        count > 9999 ||
        priceFen < 0 ||
        groupIds.isEmpty ||
        groupIds.length != detailProductIds.length ||
        groupIds.length != detailCounts.length ||
        groupIds.length != selectCounts.length ||
        groupIds.any((id) => _setId(id) == null) ||
        detailProductIds.any((id) => _setId(id) == null) ||
        detailCounts.any((n) => n <= 0 || n > 9007199254740991) ||
        selectCounts.any((n) => n <= 0 || n > 9007199254740991) ||
        (requirements.isNotEmpty && requirements.length != groupIds.length) ||
        requirements.any((text) => text.length > 200)) {
      return const FailureResult(_shapeFailure);
    }
    final reqs = [
      for (var i = 0; i < groupIds.length; i++)
        i < requirements.length ? requirements[i] : '',
    ];
    final response = await this.client.post(
      '/wsc/add_set',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'prd_id': _jsonId(productId),
        'prd_cnt': count,
        'prd_price': priceFen,
        'grp_ids': [for (final id in groupIds) _jsonId(id)],
        'dtl_prd_ids': [for (final id in detailProductIds) _jsonId(id)],
        'dtl_prd_cnts': detailCounts,
        'sel_cnts': selectCounts,
        'requirements': reqs,
        'auth_type': authType,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '加入购物车失败，请重试',
      disallowed: <String>[seatId, productId],
    );
  }

  Future<Result<void>> refundOrder(
    ClientKind client, {
    required String seatId,
    required String orderId,
    required int count,
    required String amount,
    required String remark,
    required bool online,
    String authEmpCode = '',
    String authEmpPasswd = '',
    int passType = 1,
  }) async {
    if (seatId.isEmpty ||
        orderId.isEmpty ||
        count < 1 ||
        count > 9007199254740991 ||
        remark.isEmpty ||
        remark.length > 80 ||
        amount.length > 32 ||
        (amount.isNotEmpty &&
            (double.tryParse(amount)?.isFinite != true ||
                double.parse(amount) < 0)) ||
        (passType != 1 && passType != 2) ||
        authEmpCode.length > 128 ||
        authEmpPasswd.length > 256 ||
        (authEmpCode.isEmpty != authEmpPasswd.isEmpty) ||
        (passType == 2 && authEmpCode.isEmpty)) {
      return const FailureResult(_shapeFailure);
    }
    // Account and decoded card passwords both arrive as transient plaintext.
    // The Vue getCodeAndPwd path hashes either mode once before transmission.
    final digest = authEmpPasswd.isEmpty
        ? ''
        : md5.convert(utf8.encode(authEmpPasswd)).toString().toUpperCase();
    final response = await this.client.post(
      online ? '/wo/ol_unpay_back' : '/wo/back',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'order_id': _jsonId(orderId),
        'back_cnt': count,
        'back_amt': amount,
        'back_remark': remark,
        'auth_emp_code': authEmpCode,
        'auth_emp_passwd': digest,
        'pass_type': passType,
      },
      client: client,
    );
    if (_wireCode(response.valueOrNull?['code']) == 2) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: orderRefundAuthorizationRequiredCode,
          safeMessage: '退单需要额外授权，请使用授权账号或员工卡',
        ),
      );
    }
    return _ack(
      response,
      fallback: '退单失败，请重试',
      disallowed: <String>[
        seatId,
        orderId,
        remark,
        authEmpCode,
        authEmpPasswd,
        digest,
      ],
    );
  }

  Future<Result<bool>> checkOrderAmounts(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/wo/chk_order_can_see',
      body: {'seat_id': _jsonId(seatId)},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final code = _wireCode(response.valueOrNull?['code']);
    if (code == 1) return const Success(true);
    if (code == 2) return const Success(false);
    return const FailureResult(
      AppFailure(
        kind: FailureKind.business,
        code: 'order_meal.amount_access_failed',
        safeMessage: '金额查看权限验证失败，请重试',
      ),
    );
  }

  Future<Result<void>> convertCartToYh(
    ClientKind client, {
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String reason,
  }) async {
    if (seatId.isEmpty ||
        cartItemIds.isEmpty ||
        cartItemIds.length != counts.length ||
        reason.isEmpty ||
        reason.length > 80) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/to_yh',
      body: <String, Object?>{
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'auth_reason': reason,
        'seat_id': _jsonId(seatId),
        'shopping_cart_ids': [for (final id in cartItemIds) _jsonId(id)],
        'auth_cnts': counts,
        'pass_type': 1,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '优惠失败，请重试',
      disallowed: <String>[seatId, reason, ...cartItemIds],
    );
  }

  Future<Result<void>> addYh(
    ClientKind client, {
    required String seatId,
    required String productId,
    required int count,
    required String amount,
    required String price,
    required String reason,
    String requirement = '',
  }) async {
    if (seatId.isEmpty ||
        productId.isEmpty ||
        count < 1 ||
        count > 9999 ||
        reason.isEmpty ||
        reason.length > 80 ||
        amount.length > 32 ||
        price.isEmpty ||
        price.length > 32 ||
        requirement.length > 200) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/add_prd',
      body: <String, Object?>{
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'auth_reason': reason,
        'seat_id': _jsonId(seatId),
        'prd_id': _jsonId(productId),
        'prd_cnt': count,
        'prd_amt': amount,
        'requirement': requirement,
        'pass_type': 1,
        'prd_price': price,
        'auth_type': 2,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '加入购物车失败，请重试',
      disallowed: <String>[seatId, productId, reason],
    );
  }

  Future<Result<void>> addYh2(
    ClientKind client, {
    required String seatId,
    required String productId,
    required int count,
    required String salesEmpId,
    required String yh2SeatId,
    String requirement = '',
  }) async {
    if (seatId.isEmpty ||
        productId.isEmpty ||
        count < 1 ||
        count > 9999 ||
        salesEmpId.isEmpty ||
        yh2SeatId.isEmpty ||
        requirement.length > 200) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/add_yh2',
      body: <String, Object?>{
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'auth_reason': '',
        'seat_id': _jsonId(seatId),
        'prd_id': _jsonId(productId),
        'prd_cnt': count,
        'requirement': requirement,
        'pass_type': 1,
        'yh2_sales_emp_id': _jsonId(salesEmpId),
        'yh2_seat_id': _jsonId(yh2SeatId),
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '加入购物车失败，请重试',
      disallowed: <String>[seatId, productId, salesEmpId, yh2SeatId],
    );
  }

  Future<Result<void>> addRequirement(
    ClientKind client, {
    required String seatId,
    required String itemId,
    required String requirement,
  }) async {
    if (seatId.isEmpty ||
        itemId.isEmpty ||
        requirement.isEmpty ||
        requirement.length > 200) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/add_requirement',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'id': _jsonId(itemId),
        'requirement': requirement,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '修改要求失败，请重试',
      disallowed: <String>[seatId, itemId, requirement],
    );
  }

  Future<Result<void>> addSetRequirement(
    ClientKind client, {
    required String seatId,
    required String itemId,
    required String groupId,
    required String detailProductId,
    required int detailCount,
    required int selectCount,
    required String sourceRequirement,
    required String requirement,
  }) async {
    if (seatId.isEmpty ||
        itemId.isEmpty ||
        groupId.isEmpty ||
        detailProductId.isEmpty ||
        detailCount < 1 ||
        selectCount < 1 ||
        sourceRequirement.length > 200 ||
        requirement.length > 200) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/add_set_requirement',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'id': _jsonId(itemId),
        'grp_id': _jsonId(groupId),
        'dtl_prd_id': _jsonId(detailProductId),
        'dtl_prd_cnts': detailCount,
        'sel_cnts': selectCount,
        'src_requirement': sourceRequirement,
        'requirement': requirement,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '修改要求失败，请重试',
      disallowed: <String>[seatId, itemId, requirement],
    );
  }

  Future<Result<void>> changeSetDetail(
    ClientKind client, {
    required String seatId,
    required String itemId,
    required String groupId,
    required String detailProductId,
    required List<String> destDetailProductIds,
    required List<int> destSelectCounts,
    required String requirement,
    required List<String> destRequirements,
  }) async {
    if (_setId(seatId) == null ||
        _setId(itemId) == null ||
        _setId(groupId) == null ||
        groupId == '1' ||
        _setId(detailProductId) == null ||
        !_validSetTargets(
          destDetailProductIds,
          destSelectCounts,
          destRequirements,
        ) ||
        requirement.length > 200) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/chg_set_dtl',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'id': _jsonId(itemId),
        'grp_ids': _jsonId(groupId),
        'dtl_prd_ids': _jsonId(detailProductId),
        'dest_dtl_prd_ids': [
          for (final id in destDetailProductIds) _jsonId(id),
        ],
        'dest_sel_cnts': destSelectCounts,
        'requirement': requirement,
        'dest_requirements': destRequirements,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '修改明细失败，请重试',
      disallowed: <String>[seatId, itemId],
    );
  }

  Future<Result<void>> convertCartToYh2(
    ClientKind client, {
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
    String reason = '',
  }) async {
    if (seatId.isEmpty ||
        cartItemIds.isEmpty ||
        cartItemIds.length != counts.length ||
        salesEmpId.isEmpty ||
        yh2SeatId.isEmpty ||
        reason.length > 80) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wsc/to_yh2',
      body: <String, Object?>{
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'auth_reason': reason,
        'seat_id': _jsonId(seatId),
        'shopping_cart_ids': [for (final id in cartItemIds) _jsonId(id)],
        'auth_cnts': counts,
        'pass_type': 1,
        'yh2_sales_emp_id': _jsonId(salesEmpId),
        'yh2_seat_id': _jsonId(yh2SeatId),
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '优惠2失败，请重试',
      disallowed: <String>[seatId, salesEmpId, yh2SeatId, ...cartItemIds],
    );
  }

  Future<Result<void>> giftOrdered(
    ClientKind client, {
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String reason,
  }) async {
    if (seatId.isEmpty ||
        orderIds.isEmpty ||
        orderIds.length != counts.length ||
        reason.isEmpty ||
        reason.length > 80) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wo/yh_prd',
      body: <String, Object?>{
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'auth_reason': reason,
        'seat_id': _jsonId(seatId),
        'order_ids': [for (final id in orderIds) _jsonId(id)],
        'auth_cnts': counts,
        'pass_type': 1,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '优惠失败，请重试',
      disallowed: <String>[seatId, reason, ...orderIds],
    );
  }

  Future<Result<void>> changeOrderedSet(
    ClientKind client, {
    required String seatId,
    required String orderId,
    required String orderDetailId,
    required List<String> destDetailProductIds,
    required List<int> destSelectCounts,
    required List<String> destRequirements,
    String authEmpCode = '',
    String authEmpPasswd = '',
    int passType = 1,
  }) async {
    final cashier = client == ClientKind.cashier;
    if (_setId(seatId) == null ||
        _setId(orderId) == null ||
        _setId(orderDetailId) == null ||
        !_validSetTargets(
          destDetailProductIds,
          destSelectCounts,
          destRequirements,
        ) ||
        (!cashier &&
            ((passType != 1 && passType != 2) ||
                authEmpCode.length > 128 ||
                authEmpPasswd.length > 256 ||
                (authEmpCode.isEmpty != authEmpPasswd.isEmpty) ||
                (passType == 2 && authEmpCode.isEmpty)))) {
      return const FailureResult(_shapeFailure);
    }
    final digest = authEmpPasswd.isEmpty
        ? ''
        : md5.convert(utf8.encode(authEmpPasswd)).toString().toUpperCase();
    final response = await this.client.post(
      cashier ? '/sel/chg_prd_set_dtl' : '/wo/set_chg',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        if (!cashier) 'auth_emp_code': authEmpCode,
        if (!cashier) 'auth_emp_passwd': digest,
        'order_id': _jsonId(orderId),
        'order_dtl_id': _jsonId(orderDetailId),
        'dest_dtl_prd_ids': [
          for (final id in destDetailProductIds) _jsonId(id),
        ],
        'dest_dtl_prd_sel_cnts': destSelectCounts,
        'dest_requirements': destRequirements,
        if (!cashier) 'pass_type': passType,
      },
      client: client,
    );
    if (!cashier && _wireCode(response.valueOrNull?['code']) == 2) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: orderSetAuthorizationRequiredCode,
          safeMessage: '更换套餐需要额外授权，请使用授权账号或员工卡',
        ),
      );
    }
    return _ack(
      response,
      fallback: '修改明细失败，请重试',
      disallowed: <String>[
        seatId,
        orderId,
        orderDetailId,
        authEmpCode,
        authEmpPasswd,
        digest,
      ],
    );
  }

  Future<Result<void>> convertOrderToYh2(
    ClientKind client, {
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
    String reason = '',
  }) async {
    if (seatId.isEmpty ||
        orderIds.isEmpty ||
        orderIds.length != counts.length ||
        salesEmpId.isEmpty ||
        yh2SeatId.isEmpty ||
        reason.length > 80) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wo/yh2_prd',
      body: <String, Object?>{
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'auth_reason': reason,
        'seat_id': _jsonId(seatId),
        'order_ids': [for (final id in orderIds) _jsonId(id)],
        'auth_cnts': counts,
        'pass_type': 1,
        'yh2_sales_emp_id': _jsonId(salesEmpId),
        'yh2_seat_id': _jsonId(yh2SeatId),
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '优惠2失败，请重试',
      disallowed: <String>[seatId, salesEmpId, yh2SeatId, ...orderIds],
    );
  }

  Future<Result<void>> reprintKitchen(
    ClientKind client, {
    required String orderId,
  }) async {
    if (orderId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/wo/reprt_cp',
      body: <String, Object?>{'order_id': _jsonId(orderId)},
      client: client,
    );
    return _ack(
      response,
      fallback: '补打出品失败，请重试',
      disallowed: <String>[orderId],
    );
  }

  Future<Result<void>> printBill(
    ClientKind client, {
    required String seatId,
    required bool unpaid,
    required bool includeHl,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/wo/prt_csm_bill',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'total_type': unpaid ? 2 : 1,
        'include_hl': includeHl ? 1 : 2,
      },
      client: client,
    );
    return _ack(response, fallback: '打印失败，请重试', disallowed: <String>[seatId]);
  }

  Future<Result<void>> reprintBill(
    ClientKind client, {
    required String seatId,
    required int turnoverCount,
    required bool unpaid,
    required bool includeHl,
    String payId = '',
  }) async {
    if (seatId.isEmpty || turnoverCount < 0) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/sy_prt_csm_bill',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'turnover_cnt': turnoverCount,
        'pay_id': payId.isEmpty ? 0 : _jsonId(payId),
        'range_type': unpaid
            ? 2
            : payId.isEmpty
            ? 1
            : 3,
        'include_hl': includeHl ? 1 : 2,
      },
      client: client,
    );
    return _ack(response, fallback: '打印失败，请重试', disallowed: <String>[seatId]);
  }

  Future<Result<void>> cleanSeat(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/sel/seat_clean',
      body: <String, Object?>{'seat_id': _jsonId(seatId)},
      client: client,
    );
    return _ack(response, fallback: '清台失败，请重试', disallowed: <String>[seatId]);
  }

  Future<Result<void>> mergeYh2(
    ClientKind client, {
    required String seatId,
    required List<String> orderIds,
    required String destSeatId,
  }) async {
    if (seatId.isEmpty || orderIds.isEmpty || destSeatId.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/move_order',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'order_ids': [for (final id in orderIds) _jsonId(id)],
        'dest_seat_id': _jsonId(destSeatId),
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '并台失败，请重试',
      disallowed: <String>[seatId, destSeatId, ...orderIds],
    );
  }

  Future<Result<List<OrderPlacedItem>>> waiterTodoOrders(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/wo/get_waiter_olpay_todo_orders',
      body: <String, Object?>{'seat_id': _jsonId(seatId)},
      client: client,
    );
    return _readWaiterTodos(response);
  }

  Future<Result<WaiterPayQr>> createWaiterPay(
    ClientKind client, {
    required String seatId,
    required int payType,
    required List<String> orderIds,
    String authCode = '',
  }) async {
    if (seatId.isEmpty || payType < 1 || orderIds.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/wo/do_waiter_olpay_with_orders',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'pay_type': payType,
        'auth_code': authCode,
        'order_ids': [for (final id in orderIds) _jsonId(id)],
      },
      client: client,
    );
    return _readWaiterPay(response);
  }

  Future<Result<void>> redeemCoupon(
    ClientKind client, {
    required String authCode,
  }) async {
    if (authCode.isEmpty || authCode.length > 64) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/kq_csm_by_code',
      body: <String, Object?>{'auth_code': authCode, 'relate_csm_id': 0},
      client: client,
    );
    return _ack(response, fallback: '核销失败，请重试', disallowed: <String>[authCode]);
  }

  Result<List<OrderPlacedItem>> _readWaiterTodos(
    Result<Map<String, Object?>> response,
  ) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const Success([]);
    final groups = data['oos'];
    if (groups == null) return const Success([]);
    if (groups is! List) return const FailureResult(_shapeFailure);
    final rows = <OrderPlacedItem>[];
    for (final group in groups) {
      if (group is! Map) return const FailureResult(_shapeFailure);
      final orders = group['os'];
      if (orders == null) continue;
      if (orders is! List) return const FailureResult(_shapeFailure);
      for (final item in orders) {
        if (item is! Map) return const FailureResult(_shapeFailure);
        final id = _asId(item['id']);
        final productId = _asId(item['pid']);
        final count = _wireCode(item['pc']) ?? 1;
        if (id == null || productId == null || count < 1) {
          return const FailureResult(_shapeFailure);
        }
        rows.add(
          OrderPlacedItem(
            id: id,
            productId: productId,
            name: _money(item['n']),
            count: count,
            unitPrice: _money(item['pp']),
            amount: _money(item['pa']),
            orderedAt: _money(item['ot']),
            waiterName: '',
            recordedUnitPrice: _money(item['p2']),
            authorizationType: _wireCode(item['at']) ?? 0,
          ),
        );
      }
    }
    return Success(rows);
  }

  Result<WaiterPayQr> _readWaiterPay(Result<Map<String, Object?>> response) {
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
          code: 'business.order_meal_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: '生成买单二维码失败，请重试',
            disallowed: const <String>[],
          ),
        ),
      );
    }
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    final payId = _asId(data['ol_pay_id']);
    final amount = _wireCode(data['pay_amt']);
    final payUrl = _money(data['pay_url']);
    if (payId == null || amount == null || amount < 0 || payUrl.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    return Success(
      WaiterPayQr(payId: payId, amountFen: amount, payUrl: payUrl),
    );
  }

  Result<void> _ack(
    Result<Map<String, Object?>> response, {
    required String fallback,
    required List<String> disallowed,
    Set<int> successCodes = const {1},
  }) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (!successCodes.contains(code)) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.order_meal_rejected',
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

  Result<int> _readCount(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final count = _wireCode(envelope['data']);
    if (count == null || count < 0) return const FailureResult(_shapeFailure);
    return Success(count);
  }

  Result<List<OrderCartItem>> _readItems(
    Result<Map<String, Object?>> response,
  ) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final raw = envelope['data'];
    final data = raw is Map ? raw['records'] : raw;
    if (data == null) return const Success([]);
    if (data is! List) return const FailureResult(_shapeFailure);
    final rows = <OrderCartItem>[];
    for (final item in data) {
      if (item is! Map) return const FailureResult(_shapeFailure);
      final map = <String, Object?>{
        for (final entry in item.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
      final id = _asId(map['id']);
      final productId = _asId(map['pid']);
      final count = _wireCode(map['pc']);
      if (id == null || productId == null || count == null || count < 1) {
        return const FailureResult(_shapeFailure);
      }
      rows.add(
        OrderCartItem(
          id: id,
          productId: productId,
          count: count,
          unitPrice: _money(map['pp']),
          amount: _money(map['pa']),
          isSet: _wireCode(map['is']) == 1,
          setItems: _readSetItems(map['si']),
        ),
      );
    }
    return Success(rows);
  }

  Result<List<OrderGuestHit>> _readGuests(
    Result<Map<String, Object?>> response,
  ) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data == null) return const Success([]);
    final records = switch (data) {
      Map() => data['records'],
      List() => data,
      _ => null,
    };
    if (records == null) return const Success([]);
    if (records is! List) return const FailureResult(_shapeFailure);
    final rows = <OrderGuestHit>[];
    for (final item in records) {
      if (item is! Map) return const FailureResult(_shapeFailure);
      final phone = _money(item['p']);
      if (phone.isEmpty) return const FailureResult(_shapeFailure);
      rows.add(OrderGuestHit(phone: phone, name: _money(item['n'])));
    }
    return Success(rows);
  }

  Result<List<OrderPlacedItem>> _readOrders(
    Result<Map<String, Object?>> response,
  ) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code == 2) return const Success([]);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data == null) return const Success([]);
    final records = switch (data) {
      Map() => data['records'],
      List() => data,
      _ => null,
    };
    if (records == null) return const Success([]);
    if (records is! List) return const FailureResult(_shapeFailure);
    final rows = <OrderPlacedItem>[];
    final expanded = <Map>[];
    for (final record in records) {
      if (record is! Map) return const FailureResult(_shapeFailure);
      final returns = record['bs'];
      if (returns != null && returns is! List) {
        return const FailureResult(_shapeFailure);
      }
      if (returns is! List || returns.isEmpty) {
        expanded.add(record);
      } else {
        if (_wireCode(record['pc']) != 0) expanded.add(record);
        for (final returned in returns) {
          if (returned is! Map) return const FailureResult(_shapeFailure);
          expanded.add({
            ...record,
            ...returned,
            'si': returned['si'] ?? record['si'],
            'back': true,
          });
        }
      }
    }
    for (final item in expanded) {
      final map = <String, Object?>{
        for (final entry in item.entries)
          if (entry.key is String) entry.key as String: entry.value,
      };
      final id = _asId(map['id']);
      final productId = _asId(map['pid']);
      final count = _wireCode(map['pc']);
      if (id == null || productId == null || count == null || count < 0) {
        return const FailureResult(_shapeFailure);
      }
      rows.add(
        OrderPlacedItem(
          id: id,
          productId: productId,
          name: _money(map['n']),
          count: count,
          unitPrice: _money(map['pp']),
          recordedUnitPrice: _money(map['p2']),
          authorizationType: _wireCode(map['at']) ?? 0,
          amount: _money(map['pa']),
          orderedAt: _money(map['ot']),
          waiterName: _money(map['wn']),
          status: _wireCode(map['s']) ?? 0,
          refunded: map['back'] == true || _wireCode(map['back']) == 1,
          online: _wireCode(map['io']) == 1,
          isSet: _wireCode(map['is']) == 1,
          setItems: _readSetItems(map['si']),
        ),
      );
    }
    return Success(rows);
  }
}

String? _asId(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt().toString(),
  String() when value.isNotEmpty && value.length <= 64 => value,
  _ => null,
};

int? _setId(String value) {
  final parsed = int.tryParse(value);
  return parsed != null && parsed > 0 && parsed <= 9007199254740991
      ? parsed
      : null;
}

List<OrderSetItem> _readSetItems(Object? value) {
  if (value == null) return const [];
  if (value is! List) {
    return const [
      OrderSetItem(
        groupId: '',
        detailProductId: '',
        detailCount: 0,
        selectCount: 0,
      ),
    ];
  }
  return List.unmodifiable(
    value.map((raw) {
      final item = raw is Map ? raw : const <String, Object?>{};
      return OrderSetItem(
        id: _asId(item['id']) ?? '',
        groupId: _asId(item['gid']) ?? '',
        detailProductId:
            _asId(item.containsKey('dpi') ? item['dpi'] : item['i']) ?? '',
        detailCount:
            _wireCode(item.containsKey('dpc') ? item['dpc'] : item['c']) ?? 0,
        selectCount:
            _wireCode(item.containsKey('sc') ? item['sc'] : item['s']) ?? 0,
        requirement: _money(item['r']),
      );
    }),
  );
}

bool _validSetTargets(
  List<String> ids,
  List<int> counts,
  List<String> requirements,
) =>
    ids.isNotEmpty &&
    ids.length == counts.length &&
    ids.length == requirements.length &&
    ids.every((id) => _setId(id) != null) &&
    counts.every((count) => count > 0 && count <= 9007199254740991) &&
    requirements.every((requirement) => requirement.length <= 200);

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
  code: 'protocol.order_meal_shape',
  safeMessage: '点单接口返回了无法识别的数据',
);
const AppFailure _rejectedFailure = AppFailure(
  kind: FailureKind.business,
  code: 'business.order_meal_rejected',
  safeMessage: '服务端拒绝点单操作，请重试',
);
