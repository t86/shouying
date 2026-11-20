import 'package:card_table/src/pay_order_api.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class SessionBoundPayOrderLoader {
  SessionBoundPayOrderLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });

  final SessionRepository session;
  final ProtocolPayOrderApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  final _paidTransferPending = <(String, String)>{};
  final _paidTransferUnknown = <(String, String)>{};
  final _paidTransferTurnovers = <(String, String), int>{};
  Set<String> paidTransfersNeedingVerification(String seatId) => {
    for (final key in {..._paidTransferPending, ..._paidTransferUnknown})
      if (key.$1 == seatId) key.$2,
  };

  Future<Result<PayOrderData>> loadOrders({
    required String seatId,
    required int turnoverCount,
  }) => _guard(
    (client) =>
        api.getCsmOrders(client, seatId: seatId, turnoverCount: turnoverCount),
  );

  Future<Result<List<PayCartItem>>> listCart(String seatId) =>
      _guard((client) => api.listCart(client, seatId: seatId));

  Future<Result<void>> addChannel({
    required String seatId,
    required String channelId,
    required String amount,
  }) => _guard(
    (client) => api.addChannel(
      client,
      seatId: seatId,
      channelId: channelId,
      amount: amount,
    ),
  );

  Future<Result<void>> deleteChannel({
    required String seatId,
    required String itemId,
  }) => _guard(
    (client) => api.deleteChannel(client, seatId: seatId, itemId: itemId),
  );

  Future<Result<void>> addAuthChannel({
    required String seatId,
    required String amount,
  }) => _guard(
    (client) => api.addAuthChannel(client, seatId: seatId, amount: amount),
  );

  Future<Result<void>> payOrder({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String totalAmount,
  }) => _guard(
    (client) => api.payOrder(
      client,
      seatId: seatId,
      orderIds: orderIds,
      counts: counts,
      totalAmount: totalAmount,
    ),
  );

  Future<Result<void>> cleanSeat(String seatId) =>
      _guard((client) => api.cleanSeat(client, seatId: seatId));

  Future<Result<void>> setSettleMode({
    required String seatId,
    required int settleMode,
  }) => _guard(
    (client) =>
        api.setSettleMode(client, seatId: seatId, settleMode: settleMode),
  );

  Future<Result<void>> printBill(String seatId) =>
      _guard((client) => api.printBill(client, seatId: seatId));

  Future<Result<void>> moveOrder({
    required String seatId,
    required String destSeatId,
    required List<String> orderIds,
    List<int> counts = const [],
    int? totalAmtFen,
    bool Function()? canDispatch,
  }) => _guardDispatch(
    (client, current) => api.moveWkOrder(
      client,
      seatId: seatId,
      destSeatId: destSeatId,
      orderIds: orderIds,
      counts: counts,
      totalAmtFen: totalAmtFen,
      canDispatch: current,
    ),
    canDispatch,
  );

  Future<Result<void>> reopenPaidPayment({
    required String seatId,
    required String payId,
  }) => _guard(
    (client) => api.reopenPaidPayment(client, seatId: seatId, payId: payId),
  );

  Future<Result<void>> beginPaymentProcess({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String totalAmount,
  }) => _guard(
    (client) => api.beginPaymentProcess(
      client,
      seatId: seatId,
      orderIds: orderIds,
      counts: counts,
      totalAmount: totalAmount,
    ),
  );

  Future<Result<void>> refundPayed({
    required String seatId,
    required String payId,
    required List<String> orderIds,
    required List<int> counts,
    required List<String> amounts,
    required String remark,
  }) => _guard(
    (client) => api.refundPayed(
      client,
      seatId: seatId,
      payId: payId,
      orderIds: orderIds,
      counts: counts,
      amounts: amounts,
      remark: remark,
    ),
  );

  Future<Result<void>> changePackageDetail({
    required String seatId,
    required String orderId,
    required String orderDetailId,
    required List<String> destProductIds,
    required List<int> destCounts,
  }) => _guard(
    (client) => api.changePackageDetail(
      client,
      seatId: seatId,
      orderId: orderId,
      orderDetailId: orderDetailId,
      destProductIds: destProductIds,
      destCounts: destCounts,
    ),
  );

  Future<Result<void>> movePayedOrder({
    required String seatId,
    required String destSeatId,
    required String payId,
    required int totalAmtFen,
    required int turnoverCount,
    required String receiptFingerprint,
    List<String> selectedUnpaidIds = const [],
    bool Function()? canDispatch,
  }) async {
    final key = (seatId, payId);
    if (_paidTransferPending.contains(key) ||
        _paidTransferUnknown.contains(key)) {
      return const FailureResult(_paidTransferUncertain);
    }
    _paidTransferPending.add(key);
    try {
      return await _guardDispatch((client, current) async {
        if (client != ClientKind.cashier) return const FailureResult(_changed);
        final fresh = await api.getCsmOrders(
          client,
          seatId: seatId,
          turnoverCount: turnoverCount,
          canDispatch: current,
        );
        if (fresh.failureOrNull case final failure?)
          return FailureResult(failure);
        if (!current()) return const FailureResult(_changed);
        final data = fresh.valueOrNull!;
        final receipt = data.payedOrders
            .where((p) => p.id == payId)
            .firstOrNull;
        if (receipt == null ||
            receipt.transferFingerprint != receiptFingerprint ||
            receipt.transferAmountFen != totalAmtFen ||
            data.unpayItems.any(
              (row) =>
                  selectedUnpaidIds.contains(row.id) &&
                  !row.online &&
                  row.isLocked,
            )) {
          return const FailureResult(_paidTransferChanged);
        }
        // Set BEFORE the awaited protocol/credential boundary. An interrupted
        // response must remain blocked even when this screen is reopened.
        _paidTransferUnknown.add(key);
        _paidTransferTurnovers[key] = turnoverCount;
        final result = await api.movePayedOrder(
          client,
          seatId: seatId,
          destSeatId: destSeatId,
          payId: payId,
          totalAmtFen: totalAmtFen,
          canDispatch: current,
        );
        if (current() &&
            (result.failureOrNull == null ||
                result.failureOrNull!.kind == FailureKind.business)) {
          _paidTransferUnknown.remove(key);
          _paidTransferTurnovers.remove(key);
        }
        return result;
      }, canDispatch);
    } finally {
      _paidTransferPending.remove(key);
    }
  }

  Future<Result<void>> verifyPaidTransfer({
    required String seatId,
    required String payId,
    required int turnoverCount,
    bool Function()? canDispatch,
  }) async {
    final key = (seatId, payId);
    final originalTurnover = _paidTransferTurnovers[key];
    if (originalTurnover != null && originalTurnover != turnoverCount) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'pay_order.paid_transfer_wrong_turnover',
          safeMessage: '请切换到翻台轮次 $originalTurnover 后核实该支付单',
        ),
      );
    }
    if (_paidTransferPending.contains(key))
      return const FailureResult(_paidTransferUncertain);
    return _guardDispatch((client, current) async {
      final fresh = await api.getCsmOrders(
        client,
        seatId: seatId,
        turnoverCount: turnoverCount,
        canDispatch: current,
      );
      if (fresh.failureOrNull case final failure?)
        return FailureResult(failure);
      if (!current()) return const FailureResult(_changed);
      _paidTransferUnknown.remove(key);
      _paidTransferTurnovers.remove(key);
      return const Success(null);
    }, canDispatch);
  }

  static const _paidTransferUncertain = AppFailure(
    kind: FailureKind.business,
    code: 'pay_order.paid_transfer_unverified',
    safeMessage: '该支付单转单仍在处理或结果未知，请先显式核实',
  );
  static const _paidTransferChanged = AppFailure(
    kind: FailureKind.business,
    code: 'pay_order.paid_transfer_changed',
    safeMessage: '支付单或锁单状态已变化，请刷新后重新选择',
  );

  Future<Result<List<PayedChannelItem>>> getChangePayChannels({
    required String seatId,
    required String payId,
  }) => _guard(
    (client) => api.getChangePayChannels(client, seatId: seatId, payId: payId),
  );

  Future<Result<void>> addLateChannel({
    required String seatId,
    required String lateId,
  }) => _guard(
    (client) => api.addLateChannel(client, seatId: seatId, lateId: lateId),
  );

  Future<Result<List<Map<String, Object?>>>> getSeatLateChannels(
    String seatId,
  ) => _guard((client) => api.getSeatLateChannels(client, seatId: seatId));

  Future<Result<void>> newLateChannel({
    required String seatId,
    required int amountFen,
    required String note,
  }) => _guard(
    (client) => api.newLateChannel(
      client,
      seatId: seatId,
      amountFen: amountFen,
      note: note,
    ),
  );

  Future<Result<void>> refundLateChannel({
    required String seatId,
    required String lateId,
  }) => _guard(
    (client) => api.refundLateChannel(client, seatId: seatId, lateId: lateId),
  );

  Future<Result<void>> changeLateChannelSeat({
    required String lateId,
    required String destSeatId,
  }) => _guard(
    (client) => api.changeLateChannelSeat(
      client,
      lateId: lateId,
      destSeatId: destSeatId,
    ),
  );

  Future<Result<List<Map<String, Object?>>>> getPhoneMemberCards(
    String phone,
  ) => _guard((client) => api.getPhoneMemberCards(client, phone: phone));

  Future<Result<void>> addMemberCardChannel({
    required String seatId,
    required String cardId,
    required int amountFen,
    required String phone,
    required String authCode,
    int authType = 2,
  }) => _guard(
    (client) => api.addMemberCardChannel(
      client,
      seatId: seatId,
      cardId: cardId,
      amountFen: amountFen,
      phone: phone,
      authCode: authCode,
      authType: authType,
    ),
  );

  Future<Result<List<Map<String, Object?>>>> getPhonePrepays({
    required String seatId,
    required String phone,
  }) => _guard(
    (client) => api.getPhonePrepays(client, seatId: seatId, phone: phone),
  );

  Future<Result<void>> addPrepayChannel({
    required String seatId,
    required String prepayId,
    required String amount,
    required String authCode,
  }) => _guard(
    (client) => api.addPrepayChannel(
      client,
      seatId: seatId,
      prepayId: prepayId,
      amount: amount,
      authCode: authCode,
    ),
  );

  Future<Result<void>> customerPaymentCodePay({
    required String seatId,
    required String paymentCode,
    required String amount,
  }) => _guard(
    (client) => api.customerPaymentCodePay(
      client,
      seatId: seatId,
      paymentCode: paymentCode,
      amount: amount,
    ),
  );

  Future<Result<void>> convertOnlineOrderLocal({
    required String seatId,
    required List<String> onlineOrderIds,
  }) => _guard(
    (client) => api.convertOnlineOrderLocal(
      client,
      seatId: seatId,
      onlineOrderIds: onlineOrderIds,
    ),
  );

  Future<Result<void>> convertOnlinePayLocalLate({
    required String seatId,
    required List<String> onlinePayIds,
  }) => _guard(
    (client) => api.convertOnlinePayLocalLate(
      client,
      seatId: seatId,
      onlinePayIds: onlinePayIds,
    ),
  );

  Future<Result<void>> forceCancelWaiterOnlinePay(String seatId) => _guard(
    (client) => api.forceCancelWaiterOnlinePay(client, seatId: seatId),
  );

  Future<Result<void>> onlineOrderImmediateProduce({
    required String seatId,
    required List<String> orderIds,
  }) => _guard(
    (client) => api.onlineOrderImmediateProduce(
      client,
      seatId: seatId,
      orderIds: orderIds,
    ),
  );

  Future<Result<void>> batchUpdateOrderWaiter({
    required String seatId,
    required List<String> orderIds,
    required String waiterEmpId,
    bool Function()? canDispatch,
  }) => _guardDispatch(
    (client, current) => api.batchUpdateOrderWaiter(
      client,
      seatId: seatId,
      orderIds: orderIds,
      waiterEmpId: waiterEmpId,
      canDispatch: current,
    ),
    canDispatch,
  );

  Future<Result<void>> batchUpdateOrderAuther({
    required String seatId,
    required List<String> orderIds,
    required String authEmpId,
    bool Function()? canDispatch,
  }) => _guardDispatch(
    (client, current) => api.batchUpdateOrderAuther(
      client,
      seatId: seatId,
      orderIds: orderIds,
      authEmpId: authEmpId,
      canDispatch: current,
    ),
    canDispatch,
  );

  Future<Result<void>> _guardDispatch(
    Future<Result<void>> Function(ClientKind, bool Function()) run,
    bool Function()? canDispatch,
  ) {
    final user = session.currentUser;
    final machine = session.currentMachine;
    final epoch = generation();
    bool current() =>
        user != null &&
        machine != null &&
        identical(user, session.currentUser) &&
        identical(machine, session.currentMachine) &&
        epoch == generation() &&
        phase() == ConnectionPhase.online &&
        (canDispatch?.call() ?? true);
    return _guard((client) async {
      final result = await run(client, current);
      return current() ? result : const FailureResult(_changed);
    });
  }

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind client) run,
  ) async {
    try {
      final user = session.currentUser;
      final machine = session.currentMachine;
      if (user == null || machine == null) {
        return const FailureResult(_sessionRequired);
      }
      final epoch = generation();
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_unavailable);
      }
      final result = await run(machine.client);
      if (!identical(user, session.currentUser) ||
          !identical(machine, session.currentMachine) ||
          generation() != epoch) {
        return const FailureResult(_changed);
      }
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_unavailable);
      }
      return result;
    } on Object {
      return const FailureResult(_failed);
    }
  }

  static const AppFailure _sessionRequired = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.pay_order_session_required',
    safeMessage: '请登录后再结账',
  );
  static const AppFailure _unavailable = AppFailure(
    kind: FailureKind.network,
    code: 'network.pay_order_unavailable',
    safeMessage: '连接未就绪，暂时无法结账',
  );
  static const AppFailure _changed = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.pay_order_context_changed',
    safeMessage: '登录或连接状态已变化，请重新打开',
  );
  static const AppFailure _failed = AppFailure(
    kind: FailureKind.unknown,
    code: 'pay_order.load_failed',
    safeMessage: '结账失败，请重试',
  );
}
