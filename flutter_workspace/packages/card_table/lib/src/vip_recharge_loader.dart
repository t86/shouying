import 'package:card_table/src/vip_recharge.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class SessionBoundVipRechargeLoader {
  SessionBoundVipRechargeLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });

  final SessionRepository session;
  final ProtocolVipRechargeApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  bool _writing = false, _unknown = false, _paymentStarted = false;
  VipRechargeOrder? _pendingOrder;
  VipRechargeOrder? get pendingOrder => _pendingOrder;
  bool get needsVerification => _writing || _unknown || _pendingOrder != null;

  Future<Result<List<VipCardHit>>> search(String keyword) =>
      _guard((client, api) => api.search(client, keyword: keyword));

  Future<Result<VipMemberCard>> detail(String cardId) =>
      _guard((client, api) => api.detail(client, cardId: cardId));

  Future<Result<List<VipDepositRule>>> rules(String cardId) =>
      _guard((client, api) => api.rules(client, cardId: cardId));

  Future<Result<VipRechargeOrder>> createOrder(
    Map<String, Object?> body, {
    bool Function()? canDispatch,
  }) async {
    if (needsVerification) return const FailureResult(_pendingFailure);
    if (!_available(canDispatch)) return const FailureResult(_changed);
    _writing = true;
    _unknown = true;
    try {
      final result = await _guard(
        (client, api) => api.createOrder(client, body: body),
        canDispatch: canDispatch,
      );
      if (result.valueOrNull case final order?) {
        _pendingOrder = order;
        _unknown = false;
      } else if (result.failureOrNull?.kind == FailureKind.business) {
        _unknown = false;
      }
      return result;
    } finally {
      _writing = false;
    }
  }

  Future<Result<VipRechargePay>> createPay({
    required String payId,
    required int payAmtFen,
    required int payType,
    String authCode = '',
    bool Function()? canDispatch,
  }) async {
    if (_writing ||
        _unknown ||
        _paymentStarted ||
        _pendingOrder?.payId != payId)
      return const FailureResult(_pendingFailure);
    if (!_available(canDispatch)) return const FailureResult(_changed);
    _writing = true;
    _unknown = true;
    try {
      final result = await _guard(
        (client, api) => api.createPay(
          client,
          payId: payId,
          payAmtFen: payAmtFen,
          payType: payType,
          authCode: authCode,
        ),
        canDispatch: canDispatch,
      );
      if (result.valueOrNull case final pay?) {
        _unknown = false;
        _paymentStarted = true;
        if (pay.payResult == 1 || pay.payResult == 2) _clearPending();
      } else if (result.failureOrNull?.kind == FailureKind.business) {
        _clearPending();
      }
      return result;
    } finally {
      _writing = false;
    }
  }

  Future<Result<VipLastSales?>> lastSales(String cardId) =>
      _guard((client, api) => api.lastSales(client, cardId: cardId));

  Future<Result<VipOrderStatus>> orderStatus(String orderId) async {
    final pending = _pendingOrder;
    final result = await _guard(
      (client, api) => api.orderStatus(client, orderId: orderId),
    );
    if (!_writing &&
        identical(pending, _pendingOrder) &&
        pending?.orderId == orderId &&
        const [1, 2].contains(result.valueOrNull?.payResult))
      _clearPending();
    return result;
  }

  void _clearPending() {
    _pendingOrder = null;
    _unknown = false;
    _paymentStarted = false;
  }

  bool _available(bool Function()? check) {
    try {
      return session.currentUser != null &&
          const [
            ClientKind.order,
            ClientKind.cashier,
          ].contains(session.currentMachine?.client) &&
          phase() == ConnectionPhase.online &&
          (check?.call() ?? true);
    } on Object {
      return false;
    }
  }

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind, ProtocolVipRechargeApi) run, {
    bool Function()? canDispatch,
  }) async {
    try {
      final user = session.currentUser;
      final machine = session.currentMachine;
      if (user == null ||
          machine == null ||
          !const [
            ClientKind.order,
            ClientKind.cashier,
          ].contains(machine.client)) {
        return const FailureResult(_sessionRequired);
      }
      final epoch = generation();
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_unavailable);
      }
      bool current() =>
          identical(user, session.currentUser) &&
          identical(machine, session.currentMachine) &&
          generation() == epoch &&
          phase() == ConnectionPhase.online &&
          (canDispatch?.call() ?? true);
      if (!current()) return const FailureResult(_changed);
      final result = await run(
        machine.client,
        ProtocolVipRechargeApi(
          client: api.client,
          canDispatch: () => current() && (api.canDispatch?.call() ?? true),
        ),
      );
      if (!current()) return const FailureResult(_changed);
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
    code: 'authentication.vip_recharge_session_required',
    safeMessage: '请登录点单或收银系统后进行会员充值',
  );
  static const AppFailure _unavailable = AppFailure(
    kind: FailureKind.network,
    code: 'network.vip_recharge_unavailable',
    safeMessage: '连接未就绪，暂时无法会员充值',
  );
  static const AppFailure _changed = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.vip_recharge_context_changed',
    safeMessage: '登录或连接状态已变化，请重新打开会员充值',
  );
  static const AppFailure _failed = AppFailure(
    kind: FailureKind.unknown,
    code: 'vip_recharge.load_failed',
    safeMessage: '会员充值操作失败，请重试',
  );
  static const _pendingFailure = AppFailure(
    kind: FailureKind.business,
    code: 'vip_recharge.pending_verification',
    safeMessage: '存在待核实充值订单，禁止重复创建或支付；请先核实支付状态',
  );
}
