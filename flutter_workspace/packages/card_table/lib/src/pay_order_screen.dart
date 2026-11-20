import 'dart:async';

import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/not_pay_order_view.dart';
import 'package:card_table/src/pay_money_drawer.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/pay_order_view.dart';
import 'package:card_table/src/paid_order_refund.dart';
import 'package:card_table/src/paid_order_refund_dialog.dart';
import 'package:card_table/src/live_order_operation_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show ValueListenable, mapEquals, listEquals;
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';

typedef PayOrderLoad = Future<Result<PayOrderData>> Function({
  required String seatId,
  required int turnoverCount,
});
typedef PayOrderCart = Future<Result<List<PayCartItem>>> Function(
  String seatId,
);
typedef PayOrderAddChannel = Future<Result<void>> Function({
  required String seatId,
  required String channelId,
  required String amount,
});
typedef PayOrderDeleteChannel = Future<Result<void>> Function({
  required String seatId,
  required String itemId,
});
typedef PayOrderPay = Future<Result<void>> Function({
  required String seatId,
  required List<String> orderIds,
  required List<int> counts,
  required String totalAmount,
});
typedef PayOrderClean = Future<Result<void>> Function(String seatId);
typedef PayOrderSettle = Future<Result<void>> Function({
  required String seatId,
  required int settleMode,
});
typedef PayOrderPrint = Future<Result<void>> Function(String seatId);
typedef PayOrderAuthZero = Future<Result<void>> Function({
  required String seatId,
  required String amount,
});
typedef PayOrderLateChannel = Future<Result<void>> Function({
  required String seatId,
  required String lateId,
});
typedef PayOrderMemberChannel = Future<Result<void>> Function({
  required String seatId,
  required String cardId,
  required int amountFen,
  required String phone,
  required String authCode,
});
typedef PayOrderPrepayChannel = Future<Result<void>> Function({
  required String seatId,
  required String prepayId,
  required String amount,
  required String authCode,
});
typedef PayOrderMove = Future<Result<void>> Function({
  required String seatId,
  required String destSeatId,
  required List<String> orderIds,
  List<int> counts,
  int? totalAmtFen,
  bool Function()? canDispatch,
});

/// Historical refund quote seam, not a generic /wo/back wire adapter.
/// Production binding must supply the endpoint-specific payment identity and
/// special-product amount rules before enabling this operation (S3.P2.T03).
typedef PayOrderRefundItem = Future<Result<void>> Function({
  required String seatId,
  required String orderId,
  required int count,
  required String amount,
  required String remark,
  required bool online,
});
typedef PayOrderRefundPayed = Future<Result<void>> Function({
  required String seatId,
  required String payId,
  required List<String> orderIds,
  required List<int> counts,
  required List<String> amounts,
  required String remark,
});
typedef PayOrderEditPackage = Future<Result<void>> Function({
  required String seatId,
  required String orderId,
  required String orderDetailId,
  required List<String> destProductIds,
  required List<int> destCounts,
});
typedef PayOrderMovePayed = Future<Result<void>> Function({
  required String seatId,
  required String destSeatId,
  required String payId,
  required int totalAmtFen,
  required int turnoverCount,
  required String receiptFingerprint,
  List<String> selectedUnpaidIds,
  bool Function()? canDispatch,
});
typedef PayOrderVerifyPaidTransfer = Future<Result<void>> Function({
  required String seatId,
  required String payId,
  required int turnoverCount,
  bool Function()? canDispatch,
});
typedef PayOrderChangePayChannel = Future<Result<void>> Function({
  required String seatId,
  required String payId,
});
typedef PayOrderCustomerCodePay = Future<Result<void>> Function({
  required String seatId,
  required String paymentCode,
  required String amount,
});
typedef PayOrderConvertOnline = Future<Result<void>> Function({
  required String seatId,
  required List<String> onlineOrderIds,
});
typedef PayOrderConvertLate = Future<Result<void>> Function({
  required String seatId,
  required List<String> onlinePayIds,
});
typedef PayOrderForceCancelWaiter = Future<Result<void>> Function(
  String seatId,
);
typedef PayOrderImmediateProduce = Future<Result<void>> Function({
  required String seatId,
  required List<String> orderIds,
});
typedef PayOrderBatchWaiter = Future<Result<void>> Function({
  required String seatId,
  required List<String> orderIds,
  required String waiterEmpId,
  bool Function()? canDispatch,
});
typedef PayOrderBatchAuther = Future<Result<void>> Function({
  required String seatId,
  required List<String> orderIds,
  required String authEmpId,
  bool Function()? canDispatch,
});

final class PayOrderScreen extends StatefulWidget {
  const PayOrderScreen({
    required this.table,
    required this.loadOrders,
    this.loadCart,
    this.addChannel,
    this.deleteChannel,
    this.payOrder,
    this.cleanSeat,
    this.setSettleMode,
    this.printBill,
    this.addAuthChannel,
    this.addLateChannel,
    this.addMemberCardChannel,
    this.addPrepayChannel,
    this.onOpenOrderMeal,
    this.moveOrder,
    this.refundItem,
    this.refundPayed,
    this.productTypeFor,
    this.productNameFor,
    this.refundContext,
    this.operationContext,
    this.currentTableRevision,
    this.refundReasons = const [],
    this.isOldOrder = false,
    this.events,
    this.connectionPhases,
    this.connectionPhase = ConnectionPhase.blocked,
    this.editPackage,
    this.movePayedOrder,
    this.paidTransfersNeedingVerification,
    this.verifyPaidTransfer,
    this.changePayChannel,
    this.customerPaymentCodePay,
    this.convertOnlineOrderLocal,
    this.convertOnlinePayLocalLate,
    this.forceCancelWaiterOnlinePay,
    this.onlineOrderImmediateProduce,
    this.batchUpdateOrderWaiter,
    this.batchUpdateOrderAuther,
    this.employees,
    this.tables,
    this.onOpenLateManagement,
    super.key,
  });

  static const Key unpaidTabKey = Key('pay-order-unpaid-tab');
  static const Key cartTabKey = Key('pay-order-cart-tab');
  static const Key payKey = Key('pay-order-pay');
  static const Key cleanKey = Key('pay-order-clean');
  static const Key channelIdKey = Key('pay-order-channel-id');
  static const Key amountKey = Key('pay-order-amount');

  final CardTable table;
  final PayOrderLoad loadOrders;
  final PayOrderCart? loadCart;
  final PayOrderAddChannel? addChannel;
  final PayOrderDeleteChannel? deleteChannel;
  final PayOrderPay? payOrder;
  final PayOrderClean? cleanSeat;
  final PayOrderSettle? setSettleMode;
  final PayOrderPrint? printBill;
  final PayOrderAuthZero? addAuthChannel;
  final PayOrderLateChannel? addLateChannel;
  final PayOrderMemberChannel? addMemberCardChannel;
  final PayOrderPrepayChannel? addPrepayChannel;
  final VoidCallback? onOpenOrderMeal;
  final PayOrderMove? moveOrder;
  final PayOrderRefundItem? refundItem;
  final PayOrderRefundPayed? refundPayed;
  final int? Function(String productId)? productTypeFor;
  final String? Function(String productId)? productNameFor;
  final ValueListenable<Object?>? refundContext;
  final ValueListenable<Object?>? operationContext;
  final ValueListenable<int>? currentTableRevision;
  final List<String> refundReasons;
  final bool isOldOrder;
  final Stream<SyncEnvelope>? events;
  final Stream<ConnectionPhase>? connectionPhases;
  final ConnectionPhase connectionPhase;
  final PayOrderEditPackage? editPackage;
  final PayOrderMovePayed? movePayedOrder;
  final Set<String> Function(String seatId)? paidTransfersNeedingVerification;
  final PayOrderVerifyPaidTransfer? verifyPaidTransfer;
  final PayOrderChangePayChannel? changePayChannel;
  final PayOrderCustomerCodePay? customerPaymentCodePay;
  final PayOrderConvertOnline? convertOnlineOrderLocal;
  final PayOrderConvertLate? convertOnlinePayLocalLate;
  final PayOrderForceCancelWaiter? forceCancelWaiterOnlinePay;
  final PayOrderImmediateProduce? onlineOrderImmediateProduce;
  final PayOrderBatchWaiter? batchUpdateOrderWaiter;
  final PayOrderBatchAuther? batchUpdateOrderAuther;
  final List<CardEmployee> Function()? employees;
  final List<CardTable> Function()? tables;
  final VoidCallback? onOpenLateManagement;

  @override
  State<PayOrderScreen> createState() => _PayOrderScreenState();
}

final class _PayOrderScreenState extends State<PayOrderScreen> {
  PayOrderData? _data;
  List<PayCartItem> _cart = const [];
  final Set<String> _selected = <String>{};
  bool _localBusy = false;
  bool _reading = false;
  bool _refreshPending = false;
  Timer? _refreshTimer;
  Completer<void>? _refreshCompletion;
  ValueListenable<int>? _observedRevision;
  int? _lastRevision;
  bool get _busy => _localBusy || _sending || _reading || _refreshPending;
  set _busy(bool value) {
    _localBusy = value;
    if (!value) _scheduleRefresh();
  }

  bool _sending = false;
  bool _transferNeedsVerification = false;
  final _localPaidTransferUnknown = <String>{};
  Set<String> get _paidTransfersToVerify => {
    ..._localPaidTransferUnknown,
    ...?widget.paidTransfersNeedingVerification?.call(widget.table.id),
  };
  int _successfulReads = 0;
  int _tab = 0;
  int? _selectedTurnover;
  int get _lastTurnover => widget.table.businessStatus == 1
      ? widget.table.turnoverCount - 1
      : widget.table.turnoverCount;
  int get _turnover => _selectedTurnover ?? _lastTurnover;
  bool get _isOldOrder =>
      widget.isOldOrder || _turnover != widget.table.turnoverCount;
  int _loadEpoch = 0;
  LiveOrderOperationScope? _refundScope;
  ValueListenable<Object?>? _observedRefundContext;
  ValueListenable<Object?>? _observedOperationContext;
  int _operationEpoch = 0;
  bool _sawAvailableScope = false;
  ValueListenable<Object?>? get _operationContext =>
      widget.operationContext ?? _refundScope?.context;
  void _operationChanged() {
    final firstReady = !_sawAvailableScope && _operationContext?.value != null;
    if (_operationContext?.value != null) _sawAvailableScope = true;
    _operationEpoch++;
    _loadEpoch++;
    if (mounted) {
      setState(() {
        _selected.clear();
        if (!_isOldOrder && !firstReady) {
          _data = null;
          _cart = const [];
          _tab = 0;
        }
      });
      if (!_isOldOrder && _operationContext?.value != null) {
        _requestLiveRefresh();
      } else if (!_isOldOrder) {
        _refreshPending = false;
        _refreshTimer?.cancel();
        _refreshTimer = null;
        _completeRefresh();
      }
    }
  }

  bool Function() _captureOperation({bool allowOldPaidTransfer = false}) {
    final route = ModalRoute.of(context);
    final source = _operationContext;
    final token = source?.value;
    final seat = _seatContext;
    final epoch = _operationEpoch;
    var warned = false;
    return () {
      final valid =
          mounted &&
          (route == null ||
              (route.isActive &&
                  route.animation?.status != AnimationStatus.reverse)) &&
          (allowOldPaidTransfer || !_isOldOrder) &&
          token != null &&
          identical(source, _operationContext) &&
          identical(token, source?.value) &&
          epoch == _operationEpoch &&
          seat == _seatContext;
      if (!valid && mounted && !warned) {
        warned = true;
        _show(seat != _seatContext ? '卡台已变化，请重新打开操作' : '操作上下文已失效，请重新打开页面');
      }
      return valid;
    };
  }

  Future<Result<void>> _sendOperation(
    Future<Result<void>> Function() send,
  ) async {
    if (_sending) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'pay_order.operation_pending',
          safeMessage: '上一操作仍在处理中，请稍候',
        ),
      );
    }
    _sending = true;
    // Do not let a previously started read publish across a business write.
    if (_reading) {
      _loadEpoch++;
      _refreshPending = true;
    }
    setState(() => _busy = true);
    try {
      return await send();
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.network,
          code: 'pay_order.operation_failed',
          safeMessage: '无法确认操作结果，请刷新后核实',
        ),
      );
    } finally {
      _sending = false;
      if (mounted) setState(() => _busy = false);
    }
  }

  ValueListenable<Object?>? get _refundContext =>
      widget.refundContext ?? _refundScope?.refundContext;
  int? _refundProductType(String id) {
    try {
      return widget.productTypeFor != null
          ? widget.productTypeFor!(id)
          : _refundScope?.productTypeFor(id);
    } on Object {
      return null;
    }
  }

  List<String> get _refundReasons => widget.refundReasons.isNotEmpty
      ? widget.refundReasons
      : _refundScope?.refundReasons ?? const [];
  void _refundAccessChanged() {
    if (mounted) setState(() {});
  }

  void _bindRefundScope() {
    _loadEpoch++;
    _observedRevision?.removeListener(_revisionChanged);
    _observedOperationContext?.removeListener(_operationChanged);
    _operationEpoch++;
    _observedRefundContext?.removeListener(_refundAccessChanged);
    final previous = _refundScope;
    _refundScope = null;
    if (previous != null) unawaited(previous.dispose());
    if ((widget.refundContext == null || widget.operationContext == null) &&
        widget.events != null &&
        widget.connectionPhases != null) {
      _refundScope = LiveOrderOperationScope(
        table: widget.table,
        events: widget.events!,
        phases: widget.connectionPhases!,
        initialPhase: widget.connectionPhase,
        invalidateOnStatusChange: false,
        canOperateInStatus: (status) => const {1, 4, 5, 6, 7}.contains(status),
      );
    }
    _observedRefundContext = _refundContext;
    _observedRefundContext?.addListener(_refundAccessChanged);
    _observedOperationContext = _operationContext;
    if (_observedOperationContext?.value != null) _sawAvailableScope = true;
    _observedOperationContext?.addListener(_operationChanged);
    _observedRevision =
        widget.currentTableRevision ?? _refundScope?.currentTableRevision;
    _lastRevision = _observedRevision?.value;
    _observedRevision?.addListener(_revisionChanged);
  }

  void _revisionChanged() {
    final revision = _observedRevision?.value;
    if (revision == _lastRevision || _isOldOrder) return;
    _lastRevision = revision;
    _loadEpoch++;
    _requestLiveRefresh();
  }

  // Initial direct-route reads are authorized by the backend. Losing an
  // established live scope, however, must hide the previously displayed data.
  bool get _canReadCurrent =>
      _isOldOrder ||
      !_sawAvailableScope ||
      _operationContext == null ||
      _operationContext?.value != null;

  void _requestLiveRefresh() {
    if (!mounted) return;
    _refreshPending = true;
    _scheduleRefresh();
    setState(() {});
  }

  void _scheduleRefresh() {
    if (!mounted ||
        !_refreshPending ||
        _refreshTimer != null ||
        _reading ||
        _sending ||
        _localBusy ||
        !_canReadCurrent) {
      return;
    }
    // Defer one event turn so initial replay and write-finally/manual reload
    // notifications join the same read rather than racing each other.
    _refreshTimer = Timer(Duration.zero, () {
      _refreshTimer = null;
      if (mounted) unawaited(_readOnce());
    });
  }

  void _completeRefresh() {
    final completion = _refreshCompletion;
    _refreshCompletion = null;
    if (completion != null && !completion.isCompleted) completion.complete();
  }

  @override
  void initState() {
    super.initState();
    _bindRefundScope();
    _requestLiveRefresh();
  }

  Future<void> _reload() {
    if (!mounted) return Future.value();
    _refreshCompletion ??= Completer<void>();
    final future = _refreshCompletion!.future;
    _requestLiveRefresh();
    if (!_reading && !_sending && !_localBusy && _canReadCurrent) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
      unawaited(_readOnce());
    }
    return future;
  }

  Future<void> _readOnce() async {
    if (!mounted ||
        !_refreshPending ||
        _reading ||
        _sending ||
        _localBusy ||
        !_canReadCurrent) {
      return;
    }
    _refreshPending = false;
    _reading = true;
    final epoch = ++_loadEpoch;
    final seat = _seatContext;
    final source = _operationContext;
    final token = source?.value;
    final historical = _isOldOrder;
    final loadOrders = widget.loadOrders;
    final loadCart = widget.loadCart;
    bool current() =>
        mounted &&
        epoch == _loadEpoch &&
        seat == _seatContext &&
        historical == _isOldOrder &&
        identical(source, _operationContext) &&
        (historical || identical(token, source?.value));
    setState(() {});
    try {
      final result = await loadOrders(seatId: seat.$1, turnoverCount: seat.$2);
      if (!current()) return;
      List<PayCartItem> cart = const [];
      AppFailure? failure = result.failureOrNull;
      if (failure == null && loadCart != null) {
        final cartResult = await loadCart(seat.$1);
        if (!current()) return;
        cart = cartResult.valueOrNull ?? const [];
        failure = cartResult.failureOrNull;
      }
      if (!current()) return;
      final paidId = _activePaidId;
      if (failure == null) _successfulReads++;
      final wasCart = _data != null && _tab == 2 + _data!.payedOrders.length;
      setState(() {
        _data = result.valueOrNull;
        _cart = cart;
        if (paidId != null) {
          final index =
              _data?.payedOrders.indexWhere((item) => item.id == paidId) ?? -1;
          _tab = index < 0 ? 0 : index + 2;
        } else if (wasCart) {
          _tab = 2 + (_data?.payedOrders.length ?? 0);
        } else if (_tab > 1) {
          _tab = 0;
        }
        final validIds = _unpaid
            .where((item) => !item.paid && !item.refunded && item.count > 0)
            .map((item) => item.id)
            .toSet();
        _selected.removeWhere((id) => !validIds.contains(id));
      });
      if (failure != null) _show(failure.safeMessage);
    } on Object {
      if (current()) {
        setState(() {
          _data = null;
          _cart = const [];
          _selected.clear();
        });
        _show('读取收款数据失败，请刷新重试');
      }
    } finally {
      _reading = false;
      if (mounted) {
        setState(() {});
        if (_refreshPending) {
          if (_refreshCompletion != null &&
              !_sending &&
              !_localBusy &&
              _canReadCurrent) {
            unawaited(_readOnce());
          } else {
            _scheduleRefresh();
          }
        } else {
          _completeRefresh();
        }
      }
    }
  }

  @override
  void didUpdateWidget(PayOrderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.refundContext, widget.refundContext) ||
        !identical(oldWidget.operationContext, widget.operationContext) ||
        !identical(
          oldWidget.currentTableRevision,
          widget.currentTableRevision,
        ) ||
        !identical(oldWidget.events, widget.events) ||
        !identical(oldWidget.connectionPhases, widget.connectionPhases) ||
        oldWidget.table.id != widget.table.id ||
        oldWidget.table.businessStatus != widget.table.businessStatus ||
        oldWidget.table.turnoverCount != widget.table.turnoverCount) {
      _bindRefundScope();
      _data = null;
      _cart = const [];
      _selected.clear();
      if (oldWidget.table.id != widget.table.id ||
          oldWidget.table.businessStatus != widget.table.businessStatus ||
          oldWidget.table.turnoverCount != widget.table.turnoverCount) {
        _tab = 0;
        _selectedTurnover = null;
      }
      unawaited(_reload());
    }
  }

  @override
  void dispose() {
    _loadEpoch++;
    _refreshTimer?.cancel();
    _refreshPending = false;
    _completeRefresh();
    _observedRevision?.removeListener(_revisionChanged);
    _observedRefundContext?.removeListener(_refundAccessChanged);
    _observedOperationContext?.removeListener(_operationChanged);
    final scope = _refundScope;
    if (scope != null) unawaited(scope.dispose());
    super.dispose();
  }

  Map<Object, int> _channelSnapshot(PayedOrderRecord record) {
    final counts = <Object, int>{};
    for (final channel in record.channels) {
      final fields = (
        channel.channelId,
        channel.channelName,
        channel.amount,
        channel.cardNo,
        channel.cardStoredAmt,
        channel.cardDiscountAmt,
        channel.payTime,
        channel.cashierName,
      );
      counts.update(fields, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  String? get _activePaidId {
    final records = _data?.payedOrders ?? const <PayedOrderRecord>[];
    return _tab >= 2 && _tab - 2 < records.length ? records[_tab - 2].id : null;
  }

  Future<void> _refundPayed(PayedOrderRecord record) async {
    final operationCurrent = _captureOperation();
    if (!operationCurrent()) return;
    final contextToken = _refundContext;
    final token = contextToken?.value;
    final seat = _seatContext;
    final originalChannels = _channelSnapshot(record);
    if (_busy ||
        widget.table.businessStatus == 1 ||
        _isOldOrder ||
        widget.refundPayed == null ||
        contextToken == null ||
        token == null ||
        record.id.isEmpty ||
        _activePaidId != record.id) {
      return;
    }
    final original = PaidOrderRefundDraft.fromRecord(
      record: record,
      seatId: seat.$1,
      turnoverCount: seat.$2,
      isOldOrder: _isOldOrder,
      productTypeFor: _refundProductType,
    );
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => PaidOrderRefundDialog(
        draft: original,
        productNameFor: _productNameFor,
        reasons: _refundReasons,
        contextToken: contextToken,
        submit: (draft, isCurrentAttempt) async {
          bool current() =>
              operationCurrent() &&
              isCurrentAttempt() &&
              identical(contextToken, _refundContext) &&
              identical(token, contextToken.value) &&
              _seatContext == seat &&
              _activePaidId == record.id &&
              widget.table.businessStatus != 1 &&
              !_isOldOrder;
          const cancelled = FailureResult<void>(
            AppFailure(
              kind: FailureKind.authentication,
              code: 'paid_refund.context_changed',
              safeMessage: '退款已取消或登录、卡台状态已改变',
            ),
          );
          if (!current()) return cancelled;
          final latest = await widget.loadOrders(
            seatId: seat.$1,
            turnoverCount: seat.$2,
          );
          if (!current()) return cancelled;
          if (latest.failureOrNull case final failure?) {
            return FailureResult(failure);
          }
          final data = latest.valueOrNull;
          if (data == null ||
              data.seatId != seat.$1 ||
              data.turnoverCount != seat.$2) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'paid_refund.order_changed',
                safeMessage: '支付单上下文已变化，请刷新后重试',
              ),
            );
          }
          final refreshed = data.payedOrders
              .where((item) => item.id == record.id)
              .firstOrNull;
          if (refreshed == null) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'paid_refund.order_changed',
                safeMessage: '支付单已不存在，请刷新后重试',
              ),
            );
          }
          if (refreshed.originalAmt != record.originalAmt ||
              refreshed.paidAmt != record.paidAmt ||
              !mapEquals(_channelSnapshot(refreshed), originalChannels)) {
            return const FailureResult(
              AppFailure(
                kind: FailureKind.business,
                code: 'paid_refund.payment_changed',
                safeMessage: '支付金额或渠道已变化，请刷新后重新确认退款',
              ),
            );
          }
          for (final line in draft.lines.where((line) => line.selected)) {
            final item = refreshed.items
                .where(
                  (item) =>
                      item.id == line.item.id &&
                      item.online == line.item.online,
                )
                .firstOrNull;
            final old = line.item;
            if (item == null ||
                item.isRefunded ||
                item.isRefunding ||
                item.productId != old.productId ||
                item.count != old.count ||
                item.status != old.status ||
                item.refunded != old.refunded ||
                item.authorizationType != old.authorizationType ||
                (item.paidOrderId.isNotEmpty &&
                    item.paidOrderId != record.id) ||
                item.originalUnitPrice != old.originalUnitPrice ||
                item.recordedUnitPrice != old.recordedUnitPrice ||
                item.recordedAmount != old.recordedAmount ||
                _refundProductType(item.productId) != line.productType) {
              return const FailureResult(
                AppFailure(
                  kind: FailureKind.business,
                  code: 'paid_refund.order_changed',
                  safeMessage: '所选商品已变化，请刷新后重新退款',
                ),
              );
            }
          }
          if (draft.validate() case final failure?) {
            return FailureResult(failure);
          }
          if (!current()) return cancelled;
          final result = await _sendOperation(
            () => widget.refundPayed!(
              seatId: seat.$1,
              payId: record.id,
              orderIds: draft.orderIds,
              counts: draft.counts,
              amounts: draft.amounts,
              remark: draft.reason,
            ),
          );
          return current() ? result : cancelled;
        },
      ),
    );
    if (!operationCurrent() ||
        success != true ||
        !identical(token, contextToken.value) ||
        _seatContext != seat) {
      return;
    }
    _show('退单成功');
    await _reload();
    if (!mounted) return;
    final index =
        _data?.payedOrders.indexWhere((item) => item.id == record.id) ?? -1;
    setState(() => _tab = index < 0 ? 0 : index + 2);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  (String, int) get _seatContext => (widget.table.id, _turnover);

  List<PayOrderItem> get _unpaid => _data?.unpayItems ?? const [];

  num get _selectedTotal {
    var totalFen = 0;
    for (final item in _unpaid) {
      if (_selected.contains(item.id)) {
        totalFen += (item.subtotal * 100).round();
      }
    }
    return totalFen / 100;
  }

  Future<void> _pay() async {
    final current = _captureOperation();
    if (!current()) return;
    if (_busy) return;
    if (_selected.isEmpty) {
      _show('请选择需要结账的商品');
      return;
    }
    final pay = widget.payOrder;
    if (pay == null) {
      _show('结账尚未接入');
      return;
    }
    final chosen = [
      for (final item in _unpaid)
        if (_selected.contains(item.id)) item,
    ];
    if (chosen.isEmpty ||
        chosen.length != _selected.length ||
        chosen.any(
          (item) =>
              item.count <= 0 ||
              item.isRefunded ||
              item.isRefunding ||
              item.paid ||
              !item.hasValidPaymentAmount ||
              double.tryParse(item.amount) == null ||
              !double.parse(item.amount).isFinite ||
              double.parse(item.amount) < 0,
        )) {
      _show('选中商品或金额无效，请刷新后重试');
      return;
    }
    final totalFen = chosen.fold<int>(
      0,
      (sum, item) => sum + (double.parse(item.amount) * 100).round(),
    );
    final seatId = widget.table.id;
    final loadCart = widget.loadCart;
    if (loadCart == null) {
      _show('收款清单尚未接入');
      return;
    }
    setState(() => _busy = true);
    try {
      final cartResult = await loadCart(seatId);
      if (!current()) {
        _show('卡台已变化，请重新打开收款');
        return;
      }
      final cart = cartResult.valueOrNull;
      if (cartResult.failureOrNull != null || cart == null) {
        _show(cartResult.failureOrNull?.safeMessage ?? '无法确认收款清单，请重试');
        return;
      }
      var receivedFen = 0;
      for (final item in cart) {
        final amount = double.tryParse(item.amount);
        if (amount == null || !amount.isFinite || amount < 0) {
          _show('收款清单金额无效，请刷新后重试');
          return;
        }
        receivedFen += (amount * 100).round();
      }
      if (receivedFen < totalFen) {
        _show('收款金额不足，请补足支付渠道');
        return;
      }
      final result = await _sendOperation(
        () => pay(
          seatId: seatId,
          orderIds: [for (final item in chosen) item.id],
          counts: [for (final item in chosen) item.count],
          totalAmount: (totalFen / 100).toStringAsFixed(2),
        ),
      );
      if (!current()) return;
      setState(() => _busy = false);
      if (result.failureOrNull != null) {
        _show(result.failureOrNull!.safeMessage);
        return;
      }
      _show('支付成功');
      _selected.clear();
      await _reload();
    } on Object {
      if (current()) _show('无法确认收款结果，请刷新后核实');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clean() async {
    final current = _captureOperation();
    if (!current()) return;
    final ownerRoute = ModalRoute.of(context);
    final clean = widget.cleanSeat;
    if (clean == null) {
      _show('清台尚未接入');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清台'),
        content: Text('确定要对卡台 ${widget.table.name} 清台吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !current()) return;
    setState(() => _busy = true);
    final result = await _sendOperation(() => clean(widget.table.id));
    if (!current()) return;
    setState(() => _busy = false);
    if (result.failureOrNull != null) {
      _show(result.failureOrNull!.safeMessage);
      return;
    }
    _show('清台成功');
    if (mounted && ownerRoute?.isCurrent == true) {
      unawaited(Navigator.of(context).maybePop());
    }
  }

  Future<void> _addChannel() async {
    final current = _captureOperation();
    if (!current()) return;
    if (widget.addChannel == null) {
      _show('支付渠道尚未接入');
      return;
    }
    final values = await showDialog<(String, String)>(
      context: context,
      builder: (context) => const _ChannelDialog(),
    );
    if (values == null || !current()) return;
    setState(() => _busy = true);
    final result = await _sendOperation(
      () => widget.addChannel!(
        seatId: widget.table.id,
        channelId: values.$1,
        amount: values.$2,
      ),
    );
    if (!current()) return;
    setState(() => _busy = false);
    if (result.failureOrNull != null) {
      _show(result.failureOrNull!.safeMessage);
      return;
    }
    _show('加入成功');
    await _reload();
  }

  void _openPayDrawer() {
    final current = _captureOperation();
    if (!current()) return;
    if (_selected.isEmpty) {
      _show('请选择需要结账的商品');
      return;
    }
    final unpayAmt = _selectedTotal.toDouble();
    final seatId = widget.table.id;
    final turnover = widget.table.turnoverCount;
    void checkContext() {
      if (!current() ||
          widget.table.id != seatId ||
          widget.table.turnoverCount != turnover) {
        throw StateError('卡台已变化，请重新打开收款');
      }
    }

    unawaited(
      showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '收款抽屉',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (ctx, anim1, anim2) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: PayMoneyDrawer(
              seatId: int.tryParse(widget.table.id) ?? 0,
              totalUnpayAmt: unpayAmt,
              cartItems: _cart,
              refreshCart: () async {
                checkContext();
                final load = widget.loadCart;
                if (load == null) throw StateError('收款清单尚未接入');
                final result = await load(widget.table.id);
                if (result.failureOrNull != null) {
                  throw StateError(result.failureOrNull!.safeMessage);
                }
                checkContext();
                setState(() => _cart = result.valueOrNull!);
                return _cart;
              },
              onAddChannel: (channelId, amtFen, note) async {
                checkContext();
                if (widget.addChannel == null) throw StateError('支付渠道尚未接入');
                final amtStr = (amtFen / 100.0).toStringAsFixed(2);
                final result = await _sendOperation(
                  () => widget.addChannel!(
                    seatId: widget.table.id,
                    channelId: channelId.toString(),
                    amount: amtStr,
                  ),
                );
                checkContext();
                if (result.failureOrNull != null) {
                  throw StateError(result.failureOrNull!.safeMessage);
                }
              },
              onDeleteChannel: (cartItemId) async {
                checkContext();
                if (widget.deleteChannel == null) throw StateError('删除渠道尚未接入');
                final result = await _sendOperation(
                  () => widget.deleteChannel!(
                    seatId: widget.table.id,
                    itemId: cartItemId.toString(),
                  ),
                );
                checkContext();
                if (result.failureOrNull != null) {
                  throw StateError(result.failureOrNull!.safeMessage);
                }
              },
              onAddLate: (lateId) async {
                checkContext();
                final add = widget.addLateChannel;
                if (add == null) throw StateError('滞留金尚未接入');
                final result = await _sendOperation(
                  () => add(seatId: widget.table.id, lateId: lateId),
                );
                checkContext();
                if (result.failureOrNull != null) {
                  throw StateError(result.failureOrNull!.safeMessage);
                }
              },
              onAddMemberCard:
                  ({
                    required String cardId,
                    required int amountFen,
                    required String phone,
                    required String authCode,
                  }) async {
                    checkContext();
                    final add = widget.addMemberCardChannel;
                    if (add == null) throw StateError('会员卡渠道尚未接入');
                    final result = await _sendOperation(
                      () => add(
                        seatId: widget.table.id,
                        cardId: cardId,
                        amountFen: amountFen,
                        phone: phone,
                        authCode: authCode,
                      ),
                    );
                    checkContext();
                    if (result.failureOrNull != null) {
                      throw StateError(result.failureOrNull!.safeMessage);
                    }
                  },
              onAddPrepay:
                  ({
                    required String prepayId,
                    required String amount,
                    required String authCode,
                  }) async {
                    checkContext();
                    final add = widget.addPrepayChannel;
                    if (add == null) throw StateError('预订金渠道尚未接入');
                    final result = await _sendOperation(
                      () => add(
                        seatId: widget.table.id,
                        prepayId: prepayId,
                        amount: amount,
                        authCode: authCode,
                      ),
                    );
                    checkContext();
                    if (result.failureOrNull != null) {
                      throw StateError(result.failureOrNull!.safeMessage);
                    }
                  },
              onAddZeroAuth: (amtFen, authCode) async {
                checkContext();
                if (widget.addAuthChannel != null) {
                  final amtStr = (amtFen / 100.0).toStringAsFixed(2);
                  final result = await _sendOperation(
                    () => widget.addAuthChannel!(
                      seatId: widget.table.id,
                      amount: amtStr,
                    ),
                  );
                  checkContext();
                  if (result.failureOrNull != null) {
                    throw StateError(result.failureOrNull!.safeMessage);
                  }
                }
              },
              onSubmitPay: () async {
                checkContext();
                final route = ModalRoute.of(ctx);
                if (route?.isCurrent != true) return;
                Navigator.pop(ctx);
                await _pay();
              },
              onClose: () {
                final route = ModalRoute.of(ctx);
                if (route?.isCurrent == true) {
                  Navigator.pop(ctx);
                } else if (route?.isActive == true) {
                  route!.navigator?.removeRoute(route);
                }
              },
            ),
          ),
        ),
        transitionBuilder: (ctx, anim1, anim2, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        ),
      ),
    );
  }

  String? Function(String)? get _productNameFor =>
      widget.productNameFor ?? _refundScope?.productNameFor;

  String _productName(PayOrderItem item) =>
      payOrderProductName(item.name, item.productId, _productNameFor);

  Future<void> _moveItem(PayOrderItem item) async {
    final current = _captureOperation();
    if (_transferNeedsVerification) {
      _show('上次转单结果未知，请先核实转单结果');
      return;
    }
    if (!current() ||
        _busy ||
        item.isRefunded ||
        item.isLocked ||
        item.online ||
        item.paid ||
        widget.moveOrder == null)
      return;
    String search = '';
    String? selected;
    var count = item.count;
    final destSeatId = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text('转单 - ${_productName(item)}'),
          content: SizedBox(
            width: 550,
            height: 350,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: '搜索目标卡台'),
                  onChanged: (value) => update(() => search = value.trim()),
                ),
                if (item.canSplit)
                  Row(
                    children: [
                      const Text('转单数量'),
                      IconButton(
                        onPressed: count > 1
                            ? () => update(() => count--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$count'),
                      IconButton(
                        onPressed: count < item.count
                            ? () => update(() => count++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final table in _tables)
                        if (table.name.contains(search) || table.id == search)
                          RadioListTile<String>(
                            title: Text(table.name),
                            value: table.id,
                            groupValue: selected,
                            onChanged: (value) =>
                                update(() => selected = value),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(ctx, selected),
              child: const Text('确认转单'),
            ),
          ],
        ),
      ),
    );
    if (destSeatId == null || destSeatId.isEmpty || !current()) {
      return;
    }
    bool valid() =>
        current() &&
        _tables.any((t) => t.id == destSeatId) &&
        _unpaid.any(
          (r) =>
              r.id == item.id &&
              r.count == item.count &&
              r.recordedAmount == item.recordedAmount &&
              !r.isLocked &&
              !r.online &&
              !r.isRefunded,
        );
    if (!valid()) return;
    setState(() {
      _busy = true;
      _transferNeedsVerification = true;
    });
    final res = await _sendOperation(
      () => widget.moveOrder!(
        seatId: widget.table.id,
        destSeatId: destSeatId,
        orderIds: [item.id],
        counts: [count],
        totalAmtFen: (item.amountForCount(count) * 100).round(),
        canDispatch: valid,
      ),
    );
    if (!current()) return;
    setState(() => _busy = false);
    if (res.failureOrNull != null) {
      if (res.failureOrNull!.kind == FailureKind.business) {
        setState(() => _transferNeedsVerification = false);
      }
      _show(res.failureOrNull!.safeMessage);
      await _reload();
      return;
    }
    setState(() => _transferNeedsVerification = false);
    _show('转单成功');
    await _reload();
  }

  Future<void> _verifyTransfer() async {
    final current = _captureOperation();
    if (!current() || _busy) return;
    final before = _successfulReads;
    await _reload();
    if (current() && _successfulReads > before) {
      setState(() => _transferNeedsVerification = false);
      _show('已重新读取消费明细，请核对后再操作');
    }
  }

  bool get _hasSelectedSourceLock => _unpaid.any(
    (row) => _selected.contains(row.id) && !row.online && row.isLocked,
  );

  Future<void> _movePaidReceipt() async {
    final current = _captureOperation(allowOldPaidTransfer: true);
    if (!current() || _busy || widget.movePayedOrder == null) return;
    final payId = _activePaidId;
    if (payId == null) {
      _show('请选择具体已结支付单后再整笔转单');
      return;
    }
    if (_paidTransfersToVerify.contains(payId)) {
      _show('该支付单转单结果待核实');
      return;
    }
    if (_hasSelectedSourceLock) {
      _show('所选订单存在锁定订单，不可操作');
      return;
    }
    final receipt = _data!.payedOrders.firstWhere((p) => p.id == payId);
    final amount = receipt.transferAmountFen;
    if (amount == null) {
      _show('支付单缺少有效 amts.p 金额，请重新读取');
      return;
    }
    final fingerprint = receipt.transferFingerprint;
    final selectedUnpaid = _selected.toList(growable: false);
    String search = '';
    String? chosen;
    final destination = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text('整笔转单 · 支付单 $payId'),
          content: SizedBox(
            width: 550,
            height: 350,
            child: Column(
              children: [
                Text('整笔金额 ￥${(amount / 100).toStringAsFixed(2)}'),
                TextField(
                  decoration: const InputDecoration(labelText: '搜索目标卡台'),
                  onChanged: (value) => update(() => search = value.trim()),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      for (final table in _tables)
                        if (table.name.contains(search) || table.id == search)
                          RadioListTile<String>(
                            title: Text(table.name),
                            value: table.id,
                            groupValue: chosen,
                            onChanged: (value) => update(() => chosen = value),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: chosen == null
                  ? null
                  : () => Navigator.pop(ctx, chosen),
              child: const Text('确认整笔转单'),
            ),
          ],
        ),
      ),
    );
    if (destination == null || !current()) return;
    bool valid() =>
        current() &&
        _activePaidId == payId &&
        !_hasSelectedSourceLock &&
        _tables.any((t) => t.id == destination) &&
        _data?.payedOrders.any(
              (p) => p.id == payId && p.transferFingerprint == fingerprint,
            ) ==
            true;
    if (!valid()) {
      _show('支付单或锁单状态已变化，请重新选择');
      return;
    }
    setState(() => _localPaidTransferUnknown.add(payId));
    final result = await _sendOperation(
      () => widget.movePayedOrder!(
        seatId: widget.table.id,
        destSeatId: destination,
        payId: payId,
        totalAmtFen: amount,
        turnoverCount: _turnover,
        receiptFingerprint: fingerprint,
        selectedUnpaidIds: selectedUnpaid,
        canDispatch: valid,
      ),
    );
    if (!current()) return;
    if (result.failureOrNull == null ||
        result.failureOrNull!.kind == FailureKind.business) {
      setState(() => _localPaidTransferUnknown.remove(payId));
    }
    _show(result.failureOrNull?.safeMessage ?? '整笔转单成功');
    if (result.failureOrNull == null) setState(() => _tab = 0);
    await _reload();
  }

  Future<void> _verifyPaidReceipt(String payId) async {
    final current = _captureOperation(allowOldPaidTransfer: true);
    if (!current() || _busy) return;
    final verify = widget.verifyPaidTransfer;
    if (verify == null) {
      _show('核实服务不可用，请联系管理员');
      return;
    }
    final result = await _sendOperation(
      () => verify(
        seatId: widget.table.id,
        payId: payId,
        turnoverCount: _turnover,
        canDispatch: current,
      ),
    );
    if (!current()) return;
    if (result.failureOrNull case final failure?) {
      _show(failure.safeMessage);
      return;
    }
    setState(() => _localPaidTransferUnknown.remove(payId));
    _show('已重新读取支付单，请核对结果后再操作');
    await _reload();
  }

  Future<void> _refundItem(PayOrderItem item) async {
    final current = _captureOperation();
    if (!current()) return;
    if (item.paid) {
      _show('已结退款请打开对应支付单操作');
      return;
    }
    final remarkCtrl = TextEditingController(text: '客人退单');
    final countCtrl = TextEditingController(text: '${item.count}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('退单 - ${_productName(item)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countCtrl,
              enabled: item.canSplit,
              decoration: const InputDecoration(labelText: '退单数量'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: remarkCtrl,
              decoration: const InputDecoration(labelText: '退单原因'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认退单'),
          ),
        ],
      ),
    );
    if (confirmed != true || !current()) return;
    if (widget.refundItem == null) {
      _show('退单功能尚未接入');
      return;
    }
    final count = int.tryParse(countCtrl.text.trim());
    if (count == null ||
        count <= 0 ||
        count > item.count ||
        (!item.canSplit && count != item.count)) {
      _show('退单数量无效，时价商品不可拆分');
      return;
    }
    final refundAmount = item.refundAmount(count: count);
    if (!refundAmount.isFinite || refundAmount < 0) {
      _show('退款金额无效，请刷新后重试');
      return;
    }
    setState(() => _busy = true);
    final res = await _sendOperation(
      () => widget.refundItem!(
        seatId: widget.table.id,
        orderId: item.id,
        count: count,
        amount: refundAmount.toStringAsFixed(2),
        remark: remarkCtrl.text.trim(),
        online: item.online,
      ),
    );
    if (!current()) return;
    setState(() => _busy = false);
    if (res.failureOrNull != null) {
      _show(res.failureOrNull!.safeMessage);
      return;
    }
    _show('退单成功');
    await _reload();
  }

  Future<void> _editPackageItem(PayOrderItem item) async {
    _show('改套餐明细：${_productName(item)}');
  }

  Future<void> _changePayChannel(String payId) async {
    final current = _captureOperation();
    if (!current()) return;
    if (widget.changePayChannel != null) {
      final result = await _sendOperation(
        () => widget.changePayChannel!(seatId: widget.table.id, payId: payId),
      );
      if (!current()) return;
      if (result.failureOrNull case final failure?) {
        _show(failure.safeMessage);
        return;
      }
      await _reload();
    } else {
      _show('更改支付渠道功能');
    }
  }

  Future<void> _customerPaymentCodePay() async {
    final current = _captureOperation();
    if (!current()) return;
    final codeCtrl = TextEditingController();
    final amtCtrl = TextEditingController(text: _selectedTotal.toString());
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('客人付款码支付'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: '付款码 (扫码/输入)'),
            ),
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: '扣款金额'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, (codeCtrl.text.trim(), amtCtrl.text.trim())),
            child: const Text('立即扣款'),
          ),
        ],
      ),
    );
    if (result == null || !current()) return;
    if (widget.customerPaymentCodePay == null) {
      _show('付款码支付尚未接入');
      return;
    }
    setState(() => _busy = true);
    final res = await _sendOperation(
      () => widget.customerPaymentCodePay!(
        seatId: widget.table.id,
        paymentCode: result.$1,
        amount: result.$2,
      ),
    );
    if (!current()) return;
    setState(() => _busy = false);
    if (res.failureOrNull != null) {
      _show(res.failureOrNull!.safeMessage);
      return;
    }
    _show('付款码扣款成功');
    await _reload();
  }

  Future<void> _batchUpdateWaiter() async {
    await _batchChangePerson(false);
  }

  Future<void> _batchUpdateAuther() async {
    await _batchChangePerson(true);
  }

  List<CardEmployee> get _employees =>
      widget.employees?.call() ?? _refundScope?.snapshot?.employees ?? const [];
  List<CardTable> get _tables =>
      widget.tables?.call() ?? _refundScope?.snapshot?.tables ?? const [];
  List<PayOrderItem> get _batchRows {
    if (_tab == 1)
      return [
        ..._unpaid,
        for (final paid in _data?.payedOrders ?? <PayedOrderRecord>[])
          ...paid.items,
      ];
    final paidId = _activePaidId;
    return paidId == null
        ? const []
        : _data!.payedOrders.firstWhere((p) => p.id == paidId).items;
  }

  Future<void> _batchChangePerson(bool author) async {
    final current = _captureOperation();
    if (!current() ||
        _busy ||
        _tab == 0 ||
        (author
            ? widget.batchUpdateOrderAuther == null
            : widget.batchUpdateOrderWaiter == null))
      return;
    final tab = _tab;
    final rows = _batchRows
        .where((row) => !author || row.authorizationType == 8)
        .toList();
    final chosen =
        await showDialog<({List<String> ids, CardEmployee employee})>(
          context: context,
          builder: (_) => _BatchPersonDialog(
            rows: rows,
            employees: _employees,
            author: author,
            productNameFor: _productNameFor,
          ),
        );
    if (chosen == null || !current()) return;
    final originalRows = rows
        .map(
          (r) => (
            r.id,
            r.count,
            r.recordedAmount,
            r.authorizationType,
            r.refunded,
            r.online,
          ),
        )
        .toList();
    bool valid() =>
        current() &&
        _tab == tab &&
        listEquals(
          originalRows,
          _batchRows
              .where((r) => !author || r.authorizationType == 8)
              .map(
                (r) => (
                  r.id,
                  r.count,
                  r.recordedAmount,
                  r.authorizationType,
                  r.refunded,
                  r.online,
                ),
              )
              .toList(),
        ) &&
        _employees.any(
          (e) => e.id == chosen.employee.id && (author || e.status == 1),
        );
    if (!valid()) {
      _show('订单或员工信息已变化，请重新选择');
      return;
    }
    final res = await _sendOperation(
      () => author
          ? widget.batchUpdateOrderAuther!(
              seatId: widget.table.id,
              orderIds: chosen.ids,
              authEmpId: chosen.employee.id,
              canDispatch: valid,
            )
          : widget.batchUpdateOrderWaiter!(
              seatId: widget.table.id,
              orderIds: chosen.ids,
              waiterEmpId: chosen.employee.id,
              canDispatch: valid,
            ),
    );
    if (!current()) return;
    _show(res.failureOrNull?.safeMessage ?? '批量修改完成！成功${chosen.ids.length}个');
    // A partial batch has already changed rows; always reload, even on failure.
    await _reload();
  }

  Future<void> _convertOnlineOrderLocal() async {
    final current = _captureOperation();
    if (!current()) return;
    final targets = _selected.isNotEmpty
        ? _selected.toList()
        : _unpaid.where((e) => e.online).map((e) => e.id).toList();
    if (targets.isEmpty) {
      _show('请选择要转线下的线上订单');
      return;
    }
    if (widget.convertOnlineOrderLocal == null) {
      _show('线上转线下功能尚未接入');
      return;
    }
    setState(() => _busy = true);
    final res = await _sendOperation(
      () => widget.convertOnlineOrderLocal!(
        seatId: widget.table.id,
        onlineOrderIds: targets,
      ),
    );
    if (!current()) return;
    setState(() => _busy = false);
    if (res.failureOrNull != null) {
      _show(res.failureOrNull!.safeMessage);
      return;
    }
    _show('线上转线下成功');
    await _reload();
  }

  Future<void> _convertOnlinePayLocalLate() async {
    final current = _captureOperation();
    if (!current()) return;
    if (widget.convertOnlinePayLocalLate == null) {
      _show('强制转滞留金尚未接入');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('强制转滞留金确认'),
        content: const Text('是否将未完成最终支付的线上渠道转到滞留金？操作后原支付单作废。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (confirmed != true || !current()) return;
    setState(() => _busy = true);
    final res = await _sendOperation(
      () => widget.convertOnlinePayLocalLate!(
        seatId: widget.table.id,
        onlinePayIds: const [],
      ),
    );
    if (!current()) return;
    setState(() => _busy = false);
    if (res.failureOrNull != null) {
      _show(res.failureOrNull!.safeMessage);
      return;
    }
    _show('强制转滞留金成功');
    await _reload();
  }

  Future<void> _forceCancelWaiterPay() async {
    final current = _captureOperation();
    if (!current()) return;
    if (widget.forceCancelWaiterOnlinePay == null) {
      _show('取消服务员买单功能尚未接入');
      return;
    }
    setState(() => _busy = true);
    final res = await _sendOperation(
      () => widget.forceCancelWaiterOnlinePay!(widget.table.id),
    );
    if (!current()) return;
    setState(() => _busy = false);
    if (res.failureOrNull != null) {
      _show(res.failureOrNull!.safeMessage);
      return;
    }
    _show('已强制取消服务员买单并解锁');
    await _reload();
  }

  Future<void> _immediateProduce() async {
    final current = _captureOperation();
    if (!current()) return;
    final targets = _selected.isNotEmpty
        ? _selected.toList()
        : _unpaid.map((e) => e.id).toList();
    if (targets.isEmpty) {
      _show('请选择要立即出品的订单');
      return;
    }
    if (widget.onlineOrderImmediateProduce == null) {
      _show('立即出品功能尚未接入');
      return;
    }
    setState(() => _busy = true);
    final res = await _sendOperation(
      () => widget.onlineOrderImmediateProduce!(
        seatId: widget.table.id,
        orderIds: targets,
      ),
    );
    if (!current()) return;
    setState(() => _busy = false);
    if (res.failureOrNull != null) {
      _show(res.failureOrNull!.safeMessage);
      return;
    }
    _show('已提交立即出品');
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final paidOrders = data?.payedOrders ?? const <PayedOrderRecord>[];
    final paid = _activePaidId == null ? null : paidOrders[_tab - 2];
    final tabSummary = data == null
        ? null
        : paid != null
        ? OrderSummary.fromRows(paid.items)
        : _tab == 0
        ? OrderSummary.fromRows(data.unpayItems)
        : _tab == 1
        ? data.summary
        : null;
    final paidAmount = RecordedOrderPrice.number(paid?.paidAmt) ?? 0;
    final paidOriginal = RecordedOrderPrice.number(tabSummary?.allAmt) ?? 0;
    final paidDiscount =
        (((paidOriginal * 100 + .5).floor() - (paidAmount * 100 + .5).floor())
                    .clamp(0, double.maxFinite) /
                100)
            .toStringAsFixed(2);
    return Theme(
      data: ThemeData.dark().copyWith(
        splashFactory: Theme.of(context).splashFactory,
        scaffoldBackgroundColor: const Color(0xff090F1D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2362D5),
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff121A2C),
          title: Text('${widget.table.name} 结账与结算'),
          actions: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff009370),
              ),
              onPressed: _busy ? null : _openPayDrawer,
              icon: const Icon(Icons.point_of_sale, size: 18),
              label: const Text('收款抽屉'),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: widget.customerPaymentCodePay == null
                  ? '付款码支付暂不可用'
                  : '付款码支付',
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xff4B89FF),
                ),
                onPressed: _busy || widget.customerPaymentCodePay == null
                    ? null
                    : _customerPaymentCodePay,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('付款码'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '刷新',
              onPressed: _busy ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_lastTurnover >= 0)
              Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<int>(
                  value: _turnover,
                  items: [
                    for (var i = _lastTurnover; i >= 0; i--)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${widget.table.name}-${(i + 1).toString().padLeft(3, '0')}',
                        ),
                      ),
                  ],
                  onChanged: _sending || _localBusy
                      ? null
                      : (value) {
                          if (value == null || value == _turnover) return;
                          setState(() {
                            _selectedTurnover = value;
                            _operationEpoch++;
                            _loadEpoch++;
                            _data = null;
                            _cart = const [];
                            _selected.clear();
                            _tab = 0;
                          });
                          _requestLiveRefresh();
                        },
                ),
              ),
            for (final id in _paidTransfersToVerify)
              ListTile(
                title: Text('支付单 $id 整笔转单结果待核实'),
                trailing: TextButton(
                  onPressed: _busy ? null : () => _verifyPaidReceipt(id),
                  child: const Text('核实整笔转单结果'),
                ),
              ),
            if (_transferNeedsVerification)
              ListTile(
                title: const Text('转单结果待核实，禁止重复提交'),
                trailing: TextButton(
                  onPressed: _busy ? null : _verifyTransfer,
                  child: const Text('核实转单结果'),
                ),
              ),
            if (data != null)
              Container(
                color: const Color(0xff152035),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Flex(
                  direction: MediaQuery.sizeOf(context).width < 1100
                      ? Axis.vertical
                      : Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '翻台轮次: $_turnover',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '客人: ${data.customerName.isNotEmpty ? data.customerName : "散客"}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '买单模式: ${data.settleMode == 1 ? "先买单" : "后买单"}',
                      style: TextStyle(
                        color: data.settleMode == 1
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (MediaQuery.sizeOf(context).width >= 1100)
                      const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '折前金额: ￥${tabSummary?.allAmt ?? '--'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          paid == null
                              ? '优惠金额: ￥${tabSummary?.giveAmt ?? '--'}'
                              : '折后金额: ￥${paidAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '折扣金额: ￥${paid == null ? tabSummary?.discountAmt ?? '--' : paidDiscount}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          paid == null
                              ? '未结金额: ￥${tabSummary?.notPayAmt ?? '--'}'
                              : '主营实收: ￥${(RecordedOrderPrice.number(paid.mainReceivedAmt) ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xffFFA726),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Container(
              color: const Color(0xff101728),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tabButton(
                      0,
                      '未支付订单 (${_unpaid.length})',
                      key: PayOrderScreen.unpaidTabKey,
                    ),
                    _tabButton(1, '全部消费'),
                    if (_tab >= 1 &&
                        _tab < 2 + paidOrders.length &&
                        widget.movePayedOrder != null)
                      TextButton(
                        onPressed: _busy ? null : _movePaidReceipt,
                        child: const Text('整笔转单'),
                      ),
                    for (var i = 0; i < paidOrders.length; i++)
                      _tabButton(2 + i, '已结支付单 ${paidOrders[i].id}'),
                    _tabButton(
                      2 + paidOrders.length,
                      '待结算购物车 (${_cart.length})',
                      key: PayOrderScreen.cartTabKey,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _body(data, paidOrders)),
            Container(
              color: const Color(0xff121A2C),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Wrap(
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton(
                        key: PayOrderScreen.payKey,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff2362D5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: _busy ? null : _openPayDrawer,
                        child: Text(
                          '结账 ￥${_selectedTotal.toString()}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _busy ? null : _addChannel,
                        child: const Text('加渠道'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        key: PayOrderScreen.cleanKey,
                        onPressed: _busy ? null : _clean,
                        child: const Text('清台'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _busy || widget.setSettleMode == null
                            ? null
                            : () async {
                                final current = _captureOperation();
                                if (!current()) return;
                                final next = (_data?.settleMode ?? 1) == 1
                                    ? 2
                                    : 1;
                                final result = await _sendOperation(
                                  () => widget.setSettleMode!(
                                    seatId: widget.table.id,
                                    settleMode: next,
                                  ),
                                );
                                if (!current()) return;
                                if (result.failureOrNull != null) {
                                  _show(result.failureOrNull!.safeMessage);
                                  return;
                                }
                                _show(next == 1 ? '已设为先买单' : '已设为后买单');
                                await _reload();
                              },
                        child: const Text('先后买单'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _busy || widget.printBill == null
                            ? null
                            : () async {
                                final current = _captureOperation();
                                if (!current()) return;
                                final result = await _sendOperation(
                                  () => widget.printBill!(widget.table.id),
                                );
                                if (!current()) return;
                                if (result.failureOrNull != null) {
                                  _show(result.failureOrNull!.safeMessage);
                                  return;
                                }
                                _show('打印成功');
                              },
                        child: const Text('打印结算单'),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: '更多收银操作',
                        color: const Color(0xff1A243B),
                        onSelected: (val) {
                          switch (val) {
                            case 'waiter':
                              unawaited(_batchUpdateWaiter());
                            case 'auther':
                              unawaited(_batchUpdateAuther());
                            case 'toLocal':
                              unawaited(_convertOnlineOrderLocal());
                            case 'toLate':
                              unawaited(_convertOnlinePayLocalLate());
                            case 'cancelWaiter':
                              unawaited(_forceCancelWaiterPay());
                            case 'produce':
                              unawaited(_immediateProduce());
                            case 'late':
                              widget.onOpenLateManagement?.call();
                          }
                        },
                        itemBuilder: (_) => [
                          if (_tab > 0 &&
                              _tab < 2 + (_data?.payedOrders.length ?? 0) &&
                              widget.batchUpdateOrderWaiter != null)
                            const PopupMenuItem(
                              value: 'waiter',
                              child: Text('改服务员'),
                            ),
                          if (_tab > 0 &&
                              _tab < 2 + (_data?.payedOrders.length ?? 0) &&
                              widget.batchUpdateOrderAuther != null)
                            const PopupMenuItem(
                              value: 'auther',
                              child: Text('改授权人'),
                            ),
                          const PopupMenuItem(
                            value: 'toLocal',
                            child: Text('线上转线下'),
                          ),
                          const PopupMenuItem(
                            value: 'toLate',
                            child: Text('强制转滞留金'),
                          ),
                          const PopupMenuItem(
                            value: 'cancelWaiter',
                            child: Text('取消服务员买单'),
                          ),
                          const PopupMenuItem(
                            value: 'produce',
                            child: Text('立即出品'),
                          ),
                          const PopupMenuItem(
                            value: 'late',
                            child: Text('滞留金管理'),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '更多操作',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.onOpenOrderMeal != null) ...[
                        TextButton(
                          onPressed: widget.onOpenOrderMeal,
                          child: const Text('点单'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton(
                        onPressed: () =>
                            unawaited(Navigator.of(context).maybePop()),
                        child: const Text('返回'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(int index, String label, {Key? key}) {
    final active = _tab == index;
    return TextButton(
      key: key,
      style: TextButton.styleFrom(
        foregroundColor: active ? Colors.white : Colors.white60,
        backgroundColor: active ? const Color(0xff2362D5) : Colors.transparent,
        shape: const RoundedRectangleBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () => setState(() => _tab = index),
      child: Text(label),
    );
  }

  Widget _body(PayOrderData? data, List<PayedOrderRecord> paidOrders) {
    if (!_canReadCurrent) {
      return const Center(child: Text('当前流水不可用，请等待同步或重新打开'));
    }
    if (_busy && data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final cartTabIndex = 2 + paidOrders.length;
    if (_tab == cartTabIndex) {
      if (_cart.isEmpty) {
        return const Center(
          child: Text(
            '待结算购物车是空的',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        );
      }
      return ListView(
        children: [
          for (final item in _cart)
            ListTile(
              title: Text(
                item.channelName.isEmpty
                    ? '渠道${item.channelId}'
                    : item.channelName,
              ),
              subtitle: Text('￥${item.amount}'),
              trailing: TextButton(
                onPressed: _busy || widget.deleteChannel == null
                    ? null
                    : () async {
                        final current = _captureOperation();
                        if (!current()) return;
                        final result = await _sendOperation(
                          () => widget.deleteChannel!(
                            seatId: widget.table.id,
                            itemId: item.id,
                          ),
                        );
                        if (!current()) return;
                        if (result.failureOrNull != null) {
                          _show(result.failureOrNull!.safeMessage);
                          return;
                        }
                        _show('删除成功');
                        await _reload();
                      },
                child: const Text(
                  '删除',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
        ],
      );
    }

    if (_tab >= 2 && _tab < cartTabIndex) {
      final idx = _tab - 2;
      return PayedOrderView(
        record: paidOrders[idx],
        productNameFor: _productNameFor,
        onChangeChannel: () => unawaited(_changePayChannel(paidOrders[idx].id)),
        onRefundPayed:
            !_busy &&
                widget.table.businessStatus != 1 &&
                !_isOldOrder &&
                widget.refundPayed != null &&
                _refundContext?.value != null
            ? () => unawaited(_refundPayed(paidOrders[idx]))
            : null,
      );
    }

    if (_tab == 1) {
      final allItems = [..._unpaid, for (final p in paidOrders) ...p.items];
      return NotPayOrderView(
        items: allItems,
        productNameFor: _productNameFor,
        selectedIds: _selected,
        onSelectionChanged: (s) => setState(() {
          _selected
            ..clear()
            ..addAll(s);
        }),
        onRefundItem: widget.refundItem == null
            ? null
            : (it) => unawaited(_refundItem(it)),
        onMoveItem: (it) => unawaited(_moveItem(it)),
        onEditPackageItem: (it) => unawaited(_editPackageItem(it)),
      );
    }

    return NotPayOrderView(
      items: _unpaid,
      productNameFor: _productNameFor,
      selectedIds: _selected,
      onSelectionChanged: (s) => setState(() {
        _selected
          ..clear()
          ..addAll(s);
      }),
      onRefundItem: widget.refundItem == null
          ? null
          : (it) => unawaited(_refundItem(it)),
      onMoveItem: (it) => unawaited(_moveItem(it)),
      onEditPackageItem: (it) => unawaited(_editPackageItem(it)),
    );
  }
}

final class _BatchPersonDialog extends StatefulWidget {
  const _BatchPersonDialog({
    required this.rows,
    required this.employees,
    required this.author,
    this.productNameFor,
  });
  final List<PayOrderItem> rows;
  final List<CardEmployee> employees;
  final bool author;
  final String? Function(String)? productNameFor;
  @override
  State<_BatchPersonDialog> createState() => _BatchPersonDialogState();
}

final class _BatchPersonDialogState extends State<_BatchPersonDialog> {
  String person(PayOrderItem row, {bool author = false}) {
    final id = author ? row.authorEmployeeId : row.waiterEmployeeId;
    if (id == '0') return author ? '——' : '自助';
    final name = widget.employees.where((e) => e.id == id).firstOrNull?.name;
    if (name != null && name.isNotEmpty) return name;
    final recorded = author ? row.autherName : row.waiterName;
    if (recorded.isNotEmpty) return recorded;
    return id.isEmpty ? '员工信息缺失' : '未知员工（$id）';
  }

  String packageName(PayOrderPackageDetail detail) =>
      payOrderProductName(detail.name, detail.id, widget.productNameFor);
  late final selected = {
    for (final row in widget.rows)
      if (widget.author || (!row.isRefunded && !row.online)) row.id,
  };
  String search = '';
  CardEmployee? employee;
  String? error;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.author ? '批量修改授权人' : '批量修改下单人'),
    content: SizedBox(
      width: 700,
      height: MediaQuery.sizeOf(context).height * .62,
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text('全选订单'),
            value:
                widget.rows.isNotEmpty &&
                widget.rows
                    .where((r) => widget.author || (!r.isRefunded && !r.online))
                    .every((r) => selected.contains(r.id)),
            onChanged: (value) => setState(() {
              selected.clear();
              if (value == true)
                selected.addAll(
                  widget.rows
                      .where(
                        (r) => widget.author || (!r.isRefunded && !r.online),
                      )
                      .map((r) => r.id),
                );
            }),
          ),
          Expanded(
            child: ListView(
              children: [
                if (widget.rows.isEmpty)
                  Text(widget.author ? '暂无含授权人的订单' : '暂无订单'),
                for (final row in widget.rows)
                  CheckboxListTile(
                    value: selected.contains(row.id),
                    // Source only defaults/excludes these during select-all; an
                    // individual row remains manually selectable in the original.
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        selected.add(row.id);
                      } else {
                        selected.remove(row.id);
                      }
                    }),
                    title: Text(
                      payOrderProductName(
                        row.name,
                        row.productId,
                        widget.productNameFor,
                      ),
                    ),
                    subtitle: Text(
                      '数量 ${row.count}  单价 ${double.tryParse(row.originalUnitPrice) == 0 ? '时价' : row.originalUnitPrice}\n小计 ${((double.tryParse(row.originalUnitPrice) ?? 0) == 0 ? double.tryParse(row.recordedAmount) ?? 0 : (double.tryParse(row.originalUnitPrice) ?? 0) * row.count).toStringAsFixed(2)}  服务员 ${person(row)}  授权人 ${person(row, author: true)}\n${row.orderedAt}${row.packageDetails.map((d) => '\n${packageName(d)} × ${d.count}').join()}',
                    ),
                  ),
              ],
            ),
          ),
          TextField(
            decoration: const InputDecoration(labelText: '输入姓名、工号或拼音'),
            onChanged: (value) => setState(() {
              search = value.trim().toLowerCase();
              employee = null;
            }),
          ),
          SizedBox(
            height: 100,
            child: ListView(
              children: [
                if (search.isNotEmpty)
                  for (final e in widget.employees)
                    if ((widget.author || e.status == 1) &&
                        [
                          e.name,
                          e.code,
                          e.namePy,
                        ].any((s) => s.toLowerCase().contains(search)))
                      ListTile(
                        title: Text('${e.name}（${e.code}）'),
                        selected: employee?.id == e.id,
                        trailing: employee?.id == e.id
                            ? const Icon(Icons.check)
                            : null,
                        onTap: () => setState(() => employee = e),
                      ),
              ],
            ),
          ),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          if (selected.isEmpty || employee == null) {
            setState(() => error = selected.isEmpty ? '请至少选择一个订单' : '请选择员工');
            return;
          }
          Navigator.pop(context, (
            ids: widget.rows
                .where((r) => selected.contains(r.id))
                .map((r) => r.id)
                .toList(),
            employee: employee!,
          ));
        },
        child: const Text('确认修改'),
      ),
    ],
  );
}

final class _ChannelDialog extends StatefulWidget {
  const _ChannelDialog();

  @override
  State<_ChannelDialog> createState() => _ChannelDialogState();
}

final class _ChannelDialogState extends State<_ChannelDialog> {
  final TextEditingController _channel = TextEditingController(text: '1');
  final TextEditingController _amount = TextEditingController();

  @override
  void dispose() {
    _channel.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('加入支付渠道'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: PayOrderScreen.channelIdKey,
            controller: _channel,
            decoration: const InputDecoration(labelText: '渠道Id'),
          ),
          TextField(
            key: PayOrderScreen.amountKey,
            controller: _amount,
            decoration: const InputDecoration(labelText: '金额'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final channelId = _channel.text.trim();
            final amount = _amount.text.trim();
            if (channelId.isEmpty || amount.isEmpty) return;
            Navigator.pop(context, (channelId, amount));
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}
