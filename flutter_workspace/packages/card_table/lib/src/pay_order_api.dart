import 'package:card_table/src/pay_order_models.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

final class ProtocolPayOrderApi {
  const ProtocolPayOrderApi({required this.client});
  final ProtocolClient client;

  Future<Result<PayOrderData>> getCsmOrders(
    ClientKind client, {
    required String seatId,
    required int turnoverCount,
    bool Function()? canDispatch,
  }) async {
    if (seatId.isEmpty || turnoverCount < 0) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/csm_orders',
      canDispatch: canDispatch,
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'turnover_cnt': turnoverCount,
      },
      client: client,
    );
    if (response.failureOrNull != null ||
        _wireCode(response.valueOrNull?['code']) != 1) {
      return _readOrders(
        response,
        seatId: seatId,
        turnoverCount: turnoverCount,
      );
    }
    // Only the all-consumption tab uses wo/list's whole-table summary.
    // Unpaid and individual paid tabs summarize their own historical rows.
    OrderSummary? summary;
    try {
      final summaryResponse = await this.client.post(
        '/wo/list',
        canDispatch: canDispatch,
        body: {'seat_id': _jsonId(seatId), 'turnover_cnt': turnoverCount},
        client: client,
      );
      final envelope = summaryResponse.valueOrNull;
      final data = envelope?['data'];
      final info = data is Map ? data['pay_info'] : null;
      if (_wireCode(envelope?['code']) == 1 && info is Map<String, Object?>) {
        summary = OrderSummary.fromWire(info);
      }
    } on Object {
      /* Summary unavailability does not change the recorded orders. */
    }
    return _readOrders(
      response,
      seatId: seatId,
      turnoverCount: turnoverCount,
      summary: summary,
    );
  }

  Future<Result<List<PayCartItem>>> listCart(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/sel/cart_items',
      body: <String, Object?>{'id': _jsonId(seatId)},
      client: client,
    );
    return _readCart(response);
  }

  Future<Result<void>> addChannel(
    ClientKind client, {
    required String seatId,
    required String channelId,
    required String amount,
    String bizId = '0',
  }) async {
    final parsedChannelId = int.tryParse(channelId);
    if (seatId.isEmpty ||
        !RegExp(r'^[0-9]+$').hasMatch(channelId) ||
        parsedChannelId == null ||
        parsedChannelId <= 0 ||
        const [5, 6, 10, 202, 500, 1000, 9999].contains(parsedChannelId) ||
        (double.tryParse(amount) ?? 0) <= 0 ||
        !(double.tryParse(amount) ?? 0).isFinite) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/cart_add_cnl',
      body: <String, Object?>{
        'id': _jsonId(seatId),
        'pay_cnl_id': parsedChannelId,
        'pay_amt': amount,
        'biz_id': _jsonId(bizId),
      },
      client: client,
    );
    return _ack(response, fallback: '加入失败，请重试', disallowed: <String>[seatId]);
  }

  Future<Result<void>> deleteChannel(
    ClientKind client, {
    required String seatId,
    required String itemId,
  }) async {
    if (seatId.isEmpty || itemId.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/cart_del_cnl',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'id': _jsonId(itemId),
      },
      client: client,
    );
    return _ack(response, fallback: '删除失败，请重试', disallowed: <String>[seatId]);
  }

  Future<Result<void>> addAuthChannel(
    ClientKind client, {
    required String seatId,
    required String amount,
  }) async {
    if (seatId.isEmpty || amount.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/cart_add_auth_cnl',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'pay_cnl_id': 10,
        'pay_amt': amount,
        'auth_emp_code': '',
        'auth_emp_passwd': '',
        'pass_type': 1,
      },
      client: client,
    );
    return _ack(response, fallback: '抹零失败，请重试', disallowed: <String>[seatId]);
  }

  Future<Result<void>> payOrder(
    ClientKind client, {
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String totalAmount,
  }) async {
    if (seatId.isEmpty ||
        orderIds.isEmpty ||
        orderIds.length != counts.length ||
        totalAmount.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/pay_order',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'wk_order_ids': [for (final id in orderIds) _jsonId(id)],
        'prd_cnts': counts,
        'total_amt': totalAmount,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '支付失败，请重试',
      disallowed: <String>[seatId, ...orderIds],
    );
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

  Future<Result<void>> setSettleMode(
    ClientKind client, {
    required String seatId,
    required int settleMode,
  }) async {
    if (seatId.isEmpty || (settleMode != 1 && settleMode != 2)) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/chg_settle_mode',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'settle_mode': settleMode,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '切换买单模式失败，请重试',
      disallowed: <String>[seatId],
    );
  }

  Future<Result<void>> printBill(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/sel/prt_sel_bill',
      body: <String, Object?>{'seat_id': _jsonId(seatId)},
      client: client,
    );
    return _ack(response, fallback: '打印失败，请重试', disallowed: <String>[seatId]);
  }

  Future<Result<void>> moveWkOrder(
    ClientKind client, {
    required String seatId,
    required String destSeatId,
    required List<String> orderIds,
    List<int> counts = const [],
    int? totalAmtFen,
    bool Function()? canDispatch,
  }) async {
    if (seatId.isEmpty ||
        destSeatId.isEmpty ||
        orderIds.isEmpty ||
        counts.length != orderIds.length ||
        counts.any((count) => count <= 0) ||
        totalAmtFen == null ||
        totalAmtFen < 0) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/move_wk_order',
      canDispatch: canDispatch,
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'dest_seat_id': _jsonId(destSeatId),
        'wk_order_ids': [for (final id in orderIds) _jsonId(id)],
        'prd_cnts': counts,
        'total_amt': totalAmtFen,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '转单失败，请重试',
      disallowed: <String>[seatId, destSeatId, ...orderIds],
    );
  }

  /// Reopen an entire receipt; unlike a goods refund, all three arrays are empty.
  Future<Result<void>> reopenPaidPayment(
    ClientKind client, {
    required String seatId,
    required String payId,
  }) async {
    if (client != ClientKind.cashier ||
        _paymentId(seatId) == null ||
        _paymentId(payId) == null) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/pay_order_back',
      body: <String, Object?>{
        'seat_id': _paymentId(seatId),
        'pay_id': _paymentId(payId),
        'remark': '',
        'wk_order_ids': <int>[],
        'prd_back_cnts': <int>[],
        'prd_back_amts': <String>[],
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '重新结算失败，请刷新后重试',
      disallowed: <String>[seatId, payId],
    );
  }

  Future<Result<void>> beginPaymentProcess(
    ClientKind client, {
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String totalAmount,
  }) async {
    final ids = orderIds.map(_paymentId).toList();
    final amount = double.tryParse(totalAmount);
    if (client != ClientKind.cashier ||
        _paymentId(seatId) == null ||
        ids.isEmpty ||
        ids.length != counts.length ||
        ids.any((id) => id == null) ||
        ids.toSet().length != ids.length ||
        counts.any((count) => count < 0 || count > 9007199254740991) ||
        totalAmount.length > 64 ||
        amount == null ||
        !amount.isFinite ||
        amount < 0) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/cart_begin_process',
      body: <String, Object?>{
        'seat_id': _paymentId(seatId),
        'wk_order_ids': ids,
        'prd_cnts': counts,
        'total_amt': totalAmount,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '确认待结订单失败，请刷新后重试',
      disallowed: <String>[seatId, ...orderIds],
    );
  }

  Future<Result<void>> refundPayed(
    ClientKind client, {
    required String seatId,
    required String payId,
    required List<String> orderIds,
    required List<int> counts,
    required List<String> amounts,
    required String remark,
  }) async {
    int? id(String value) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed > 0 && parsed <= 9007199254740991
          ? parsed
          : null;
    }

    final parsedIds = orderIds.map(id).toList();
    if (client != ClientKind.cashier ||
        id(seatId) == null ||
        id(payId) == null ||
        orderIds.isEmpty ||
        orderIds.length != counts.length ||
        orderIds.length != amounts.length ||
        parsedIds.any((value) => value == null) ||
        parsedIds.toSet().length != parsedIds.length ||
        counts.any((count) => count <= 0 || count > 9007199254740991) ||
        amounts.any(
          (amount) =>
              amount.length > 64 ||
              double.tryParse(amount)?.isFinite != true ||
              double.parse(amount) < 0,
        ) ||
        remark.trim().isEmpty ||
        remark.length > 160) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/pay_order_back',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'pay_id': _jsonId(payId),
        'remark': remark,
        'wk_order_ids': parsedIds,
        'prd_back_cnts': counts,
        'prd_back_amts': amounts,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '退单失败，请重试',
      disallowed: <String>[seatId, payId, remark, ...orderIds],
    );
  }

  Future<Result<void>> changePackageDetail(
    ClientKind client, {
    required String seatId,
    required String orderId,
    required String orderDetailId,
    required List<String> destProductIds,
    required List<int> destCounts,
  }) async {
    if (seatId.isEmpty ||
        orderId.isEmpty ||
        orderDetailId.isEmpty ||
        destProductIds.isEmpty ||
        destProductIds.length != destCounts.length ||
        destCounts.any((count) => count <= 0)) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/chg_prd_set_dtl',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'order_id': _jsonId(orderId),
        'order_dtl_id': _jsonId(orderDetailId),
        'dest_dtl_prd_ids': [for (final id in destProductIds) _jsonId(id)],
        'dest_dtl_prd_sel_cnts': destCounts,
        'dest_requirements': [for (final _ in destProductIds) ''],
      },
      client: client,
    );
    return _ack(response, fallback: '更改套餐明细失败', disallowed: const <String>[]);
  }

  Future<Result<void>> movePayedOrder(
    ClientKind client, {
    required String seatId,
    required String destSeatId,
    required String payId,
    required int totalAmtFen,
    bool Function()? canDispatch,
  }) async {
    if (seatId.isEmpty || destSeatId.isEmpty || payId.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/move_payed_wk_order',
      canDispatch: canDispatch,
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'dest_seat_id': _jsonId(destSeatId),
        'pay_id': _jsonId(payId),
        'total_amt': totalAmtFen,
      },
      client: client,
    );
    return _ack(response, fallback: '已结转单失败', disallowed: const <String>[]);
  }

  Future<Result<List<PayedChannelItem>>> getChangePayChannels(
    ClientKind client, {
    required String seatId,
    required String payId,
  }) async {
    if (seatId.isEmpty || payId.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/get_chg_pay_cnls',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'pay_id': _jsonId(payId),
      },
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code != 1) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.pay_order_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: '获取支付渠道失败',
            disallowed: const <String>[],
          ),
        ),
      );
    }
    final rawList = envelope['data'];
    if (rawList is! List) return const Success([]);
    final channels = <PayedChannelItem>[];
    for (final it in rawList) {
      if (it is Map) {
        channels.add(
          PayedChannelItem(
            channelName: _wireText(it['name'] ?? it['channel_name']),
            amount:
                double.tryParse(_wireText(it['amt'] ?? it['amount'])) ?? 0.0,
            cardNo: _wireText(it['card_no']),
            payTime: _wireText(it['pay_time']),
            cashierName: _wireText(it['cashier_name']),
          ),
        );
      }
    }
    return Success(channels);
  }

  Future<Result<void>> addLateChannel(
    ClientKind client, {
    required String seatId,
    required String lateId,
  }) async {
    if (seatId.isEmpty || lateId.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/cart_add_late_cnl',
      body: <String, Object?>{
        'id': _jsonId(seatId),
        'late_id': _jsonId(lateId),
      },
      client: client,
    );
    return _ack(response, fallback: '添加滞留金渠道失败', disallowed: const <String>[]);
  }

  Future<Result<List<Map<String, Object?>>>> getSeatLateChannels(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/sel/get_seat_late_cnls',
      body: <String, Object?>{'seat_id': _jsonId(seatId)},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final rawList = envelope['data'];
    if (rawList is! List) return const Success([]);
    return Success([
      for (final it in rawList)
        if (it is Map) Map<String, Object?>.from(it),
    ]);
  }

  Future<Result<void>> newLateChannel(
    ClientKind client, {
    required String seatId,
    required int amountFen,
    required String note,
  }) async {
    if (seatId.isEmpty || amountFen <= 0) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/new_late_cnl',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'amt': amountFen,
        'note': note,
      },
      client: client,
    );
    return _ack(response, fallback: '创建滞留金失败', disallowed: const <String>[]);
  }

  Future<Result<void>> refundLateChannel(
    ClientKind client, {
    required String seatId,
    required String lateId,
  }) async {
    if (seatId.isEmpty || lateId.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/refund_late_cnl',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'late_id': _jsonId(lateId),
      },
      client: client,
    );
    return _ack(response, fallback: '退还滞留金失败', disallowed: const <String>[]);
  }

  Future<Result<void>> changeLateChannelSeat(
    ClientKind client, {
    required String lateId,
    required String destSeatId,
  }) async {
    if (lateId.isEmpty || destSeatId.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/chg_late_cnl_seat',
      body: <String, Object?>{
        'late_id': _jsonId(lateId),
        'dest_seat_id': _jsonId(destSeatId),
      },
      client: client,
    );
    return _ack(response, fallback: '转移滞留金卡台失败', disallowed: const <String>[]);
  }

  Future<Result<List<Map<String, Object?>>>> getPhoneMemberCards(
    ClientKind client, {
    required String phone,
  }) async {
    if (phone.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/sel/get_phone_mb_cards',
      body: <String, Object?>{'phone': phone},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final rawList = envelope['data'];
    if (rawList is! List) return const Success([]);
    return Success([
      for (final it in rawList)
        if (it is Map) Map<String, Object?>.from(it),
    ]);
  }

  Future<Result<void>> addMemberCardChannel(
    ClientKind client, {
    required String seatId,
    required String cardId,
    required int amountFen,
    required String phone,
    required String authCode,
    int authType = 2,
  }) async {
    if (seatId.isEmpty || cardId.isEmpty || amountFen <= 0 || phone.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/cart_add_mb_card_cnl',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'auth_type': authType,
        'auth_code': authCode,
        'mb_card_id': _jsonId(cardId),
        'amt': amountFen,
        'phone_num': phone,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '会员卡支付渠道添加失败',
      disallowed: const <String>[],
    );
  }

  Future<Result<List<Map<String, Object?>>>> getPhonePrepays(
    ClientKind client, {
    required String seatId,
    required String phone,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/sel/get_phone_prepays_f_csm',
      body: <String, Object?>{'seat_id': _jsonId(seatId), 'phone': phone},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final rawList = envelope['data'];
    if (rawList is! List) return const Success([]);
    return Success([
      for (final it in rawList)
        if (it is Map) Map<String, Object?>.from(it),
    ]);
  }

  Future<Result<void>> addPrepayChannel(
    ClientKind client, {
    required String seatId,
    required String prepayId,
    required String amount,
    required String authCode,
  }) async {
    if (seatId.isEmpty || prepayId.isEmpty || amount.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/cart_add_prepay_cnl',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'auth_code': authCode,
        'prepay_id': _jsonId(prepayId),
        'amt': amount,
      },
      client: client,
    );
    return _ack(response, fallback: '预订金渠道添加失败', disallowed: const <String>[]);
  }

  Future<Result<void>> customerPaymentCodePay(
    ClientKind client, {
    required String seatId,
    required String paymentCode,
    required String amount,
  }) async {
    if (seatId.isEmpty || paymentCode.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/customer_payment_code_pay',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'pay_code': paymentCode,
        'amount': amount,
      },
      client: client,
    );
    return _ack(response, fallback: '付款码支付失败', disallowed: const <String>[]);
  }

  Future<Result<void>> convertOnlineOrderLocal(
    ClientKind client, {
    required String seatId,
    required List<String> onlineOrderIds,
  }) async {
    if (seatId.isEmpty || onlineOrderIds.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/conv_ol_order_local',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'ol_order_ids': [for (final id in onlineOrderIds) _jsonId(id)],
      },
      client: client,
    );
    return _ack(response, fallback: '线上订单转线下失败', disallowed: const <String>[]);
  }

  Future<Result<void>> convertOnlinePayLocalLate(
    ClientKind client, {
    required String seatId,
    required List<String> onlinePayIds,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/sel/conv_ol_pay_local_late',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'ol_pay_ids': [for (final id in onlinePayIds) _jsonId(id)],
      },
      client: client,
    );
    return _ack(response, fallback: '强制转滞留金失败', disallowed: const <String>[]);
  }

  Future<Result<void>> forceCancelWaiterOnlinePay(
    ClientKind client, {
    required String seatId,
  }) async {
    if (seatId.isEmpty) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/sel/force_cancel_waiter_olpay',
      body: <String, Object?>{'seat_id': _jsonId(seatId)},
      client: client,
    );
    return _ack(
      response,
      fallback: '强制取消服务员买单失败',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> onlineOrderImmediateProduce(
    ClientKind client, {
    required String seatId,
    required List<String> orderIds,
  }) async {
    if (seatId.isEmpty || orderIds.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/ol_order_do_cp',
      body: <String, Object?>{
        'seat_id': _jsonId(seatId),
        'order_ids': [for (final id in orderIds) _jsonId(id)],
      },
      client: client,
    );
    return _ack(response, fallback: '立即出品操作失败', disallowed: const <String>[]);
  }

  Future<Result<void>> batchUpdateOrderWaiter(
    ClientKind client, {
    required String seatId,
    required List<String> orderIds,
    required String waiterEmpId,
    bool Function()? canDispatch,
  }) => _batchChangePerson(
    client,
    seatId: seatId,
    orderIds: orderIds,
    employeeId: waiterEmpId,
    author: false,
    canDispatch: canDispatch,
  );

  Future<Result<void>> batchUpdateOrderAuther(
    ClientKind client, {
    required String seatId,
    required List<String> orderIds,
    required String authEmpId,
    bool Function()? canDispatch,
  }) => _batchChangePerson(
    client,
    seatId: seatId,
    orderIds: orderIds,
    employeeId: authEmpId,
    author: true,
    canDispatch: canDispatch,
  );

  Future<Result<void>> _batchChangePerson(
    ClientKind client, {
    required String seatId,
    required List<String> orderIds,
    required String employeeId,
    required bool author,
    bool Function()? canDispatch,
  }) async {
    if (seatId.isEmpty ||
        orderIds.isEmpty ||
        employeeId.isEmpty ||
        orderIds.any((id) => id.isEmpty)) {
      return const FailureResult(_shapeFailure);
    }
    var succeeded = 0, rejected = 0;
    for (final orderId in orderIds) {
      final response = await this.client.post(
        author ? '/sel/chg_wkorder_auther' : '/sel/chg_wkorder_waiter',
        body: <String, Object?>{
          'seat_id': _jsonId(seatId),
          'order_id': _jsonId(orderId),
          author ? 'auth_emp_id' : 'waiter_emp_id': _jsonId(employeeId),
        },
        client: client,
        canDispatch: canDispatch,
      );
      final result = _ack(response, fallback: '修改失败', disallowed: const []);
      if (result.failureOrNull case final failure?) {
        // A transport/identity error is not a business rejection. Stop rather
        // than sending the remaining orders under an uncertain session.
        if (failure.kind != FailureKind.business) return FailureResult(failure);
        rejected++;
      } else {
        succeeded++;
      }
    }
    if (rejected > 0)
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.pay_order_batch_partial',
          safeMessage: '批量修改完成：成功$succeeded个，失败$rejected个，请刷新核实',
        ),
      );
    return const Success(null);
  }

  Result<PayOrderData> _readOrders(
    Result<Map<String, Object?>> response, {
    required String seatId,
    required int turnoverCount,
    OrderSummary? summary,
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
          code: 'business.pay_order_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: '获取订单失败，请重试',
            disallowed: <String>[seatId],
          ),
        ),
      );
    }
    final data = envelope['data'];
    if (data is! Map) {
      return Success(
        PayOrderData(seatId: seatId, turnoverCount: turnoverCount),
      );
    }
    final unpay = data['unpay_order'];
    final unpaid = <PayOrderItem>[];
    if (unpay is Map) {
      unpaid.addAll(_items(unpay['os'], online: false));
      final oos = unpay['oos'];
      if (oos is List) {
        for (final group in oos) {
          if (group is Map) {
            unpaid.addAll(
              _items(
                group['resultNotPayData'] ?? group['os'],
                online: true,
                groupRefunded:
                    group['back'] == true || _wireCode(group['back']) == 1,
              ),
            );
          }
        }
      }
    }
    final payed = <PayedOrderRecord>[];
    final rawPayed = data['payed_order'];
    if (rawPayed is List) {
      for (final item in rawPayed) {
        if (item is! Map) continue;
        final id = _asId(item['id']);
        if (id == null) continue;
        final amts = item['amts'];
        final channels = <PayedChannelItem>[];
        final rawChannels = item['ps'];
        if (rawChannels != null && rawChannels is! List) {
          return const FailureResult(_shapeFailure);
        }
        for (final channel in (rawChannels as List? ?? const [])) {
          if (channel is! Map) return const FailureResult(_shapeFailure);
          final amount = double.tryParse(_money(channel['pa']));
          final stored = _money(channel['pv']).isEmpty
              ? 0.0
              : double.tryParse(_money(channel['pv']));
          final discount = _money(channel['pf']).isEmpty
              ? 0.0
              : double.tryParse(_money(channel['pf']));
          if (amount == null ||
              !amount.isFinite ||
              stored == null ||
              !stored.isFinite ||
              discount == null ||
              !discount.isFinite) {
            return const FailureResult(_shapeFailure);
          }
          final cardNo = _money(channel['c']);
          channels.add(
            PayedChannelItem(
              channelName: _money(channel['cn']),
              channelId: _asId(channel['pc']) ?? '',
              amount: amount,
              cardNo: cardNo.isEmpty ? null : cardNo,
              cardStoredAmt: stored,
              cardDiscountAmt: discount,
              payTime: _money(item['pt']),
            ),
          );
        }
        payed.add(
          PayedOrderRecord(
            id: id,
            items: [
              ..._items(item['os'], online: false, paidOrderId: id),
              if (item['oos'] is List)
                for (final group in item['oos'] as List)
                  if (group is Map)
                    ..._items(
                      group['os'],
                      online: true,
                      paidOrderId: id,
                      groupRefunded:
                          group['back'] == true ||
                          _wireCode(group['back']) == 1,
                    ),
            ],
            originalAmt: amts is Map ? _money(amts['o']) : '',
            paidAmt: amts is Map ? _money(amts['pv']) : '',
            mainReceivedAmt: amts is Map ? _money(amts['pzv']) : '',
            transferAmount: amts is Map ? _money(amts['p']) : '',
            channels: List.unmodifiable(channels),
          ),
        );
      }
    }
    return Success(
      PayOrderData(
        seatId: seatId,
        turnoverCount: turnoverCount,
        settleMode: _wireCode(data['settle_mode']) ?? 1,
        customerName: _money(data['csm_cust_name']),
        customerPhone: _money(data['csm_cust_phone']),
        waiterEmpId: _asId(data['waiter_emp_id']) ?? '',
        unpayItems: unpaid,
        payedOrders: payed,
        summary: summary,
      ),
    );
  }

  List<PayOrderItem> _items(
    Object? raw, {
    required bool online,
    bool groupRefunded = false,
    String paidOrderId = '',
  }) {
    if (raw is! List) return const [];
    final rows = <PayOrderItem>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final id = _asId(item['id']);
      final productId = _asId(item['pid']);
      final count = _wireCode(item['pc']);
      if (id == null || productId == null || count == null || count < 0) {
        continue;
      }
      rows.add(
        PayOrderItem(
          id: id,
          productId: productId,
          name: _money(item['n']),
          count: count,
          unitPrice: _money(item['pp']),
          recordedUnitPrice: _money(item['p2']),
          authorizationType: _wireCode(item['at']) ?? 0,
          amount: _money(item['pa']),
          orderedAt: _money(item['ot']),
          status: _wireCode(item['s']) ?? 0,
          paidOrderId: paidOrderId,
          locked: (num.tryParse('${item['l']}') ?? 0) > 0,
          waiterEmployeeId: _asId(item['wei']) ?? '',
          authorEmployeeId: _asId(item['ae']) ?? '',
          packageDetails: [
            if (_wireCode(item['is']) == 1 && item['si'] is List)
              for (final detail in (item['si'] as List).whereType<Map>())
                if (_asId(detail['dpi']) case final detailId?)
                  PayOrderPackageDetail(
                    id: detailId,
                    name: '',
                    count: _packageQuantity(detail['sc'], detail['dpc'], count),
                  ),
          ],
          online: online,
          refunded:
              groupRefunded ||
              item['back'] == true ||
              _wireCode(item['back']) == 1,
        ),
      );
    }
    return rows;
  }

  Result<List<PayCartItem>> _readCart(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data == null) return const Success([]);
    if (data is! List) return const FailureResult(_shapeFailure);
    final rows = <PayCartItem>[];
    for (final item in data) {
      if (item is! Map) return const FailureResult(_shapeFailure);
      final id = _asId(item['id']);
      final channelId = _asId(item['pid']);
      if (id == null || channelId == null) {
        return const FailureResult(_shapeFailure);
      }
      rows.add(
        PayCartItem(
          id: id,
          channelId: channelId,
          amount: _money(item['pa']),
          channelName: _money(item['cn']),
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
          code: 'business.pay_order_rejected',
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

String _wireText(Object? value) => value?.toString() ?? '';

num _packageQuantity(Object? selected, Object? perUnit, int parentCount) {
  final count =
      (RecordedOrderPrice.number(selected) ?? 0) *
      (RecordedOrderPrice.number(perUnit) ?? 0) *
      parentCount;
  return count == count.truncateToDouble() ? count.toInt() : count;
}

Object _jsonId(String id) {
  final parsed = int.tryParse(id);
  return parsed ?? id;
}

int? _paymentId(String value) {
  final id = int.tryParse(value);
  return id != null && id > 0 && id <= 9007199254740991 ? id : null;
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
  code: 'protocol.pay_order_shape',
  safeMessage: '结账接口返回了无法识别的数据',
);
const AppFailure _rejectedFailure = AppFailure(
  kind: FailureKind.business,
  code: 'business.pay_order_rejected',
  safeMessage: '服务端拒绝结账操作，请重试',
);
