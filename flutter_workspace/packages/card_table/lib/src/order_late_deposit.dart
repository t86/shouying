import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class OrderLateDepositPayment {
  const OrderLateDepositPayment({
    required this.payDetailId,
    required this.payUrl,
    required this.result,
  });
  final String payDetailId, payUrl;

  /// Source r: 0 awaiting result, 1 paid, 2 explicitly failed.
  final int result;
}

abstract interface class OrderLateDepositLoader {
  bool get needsVerification;
  Future<Result<OrderLateDepositPayment>> create({
    required String seatId,
    required int payType,
    required String amountYuan,
    String? authCode,
    required bool Function() canDispatch,
  });
  Future<Result<int>> status(
    String payDetailId, {
    required bool Function() canDispatch,
  });
}

bool isValidOrderLateDepositAmount(String value) =>
    RegExp(r'^(?:\d{1,12}(?:\.\d{1,2})?|\.\d{1,2})$').hasMatch(value) &&
    (num.tryParse(value) ?? 0) > 0;

const _invalid = AppFailure(
  kind: FailureKind.business,
  code: 'order_late.invalid_input',
  safeMessage: '请选择渠道并输入有效金额（元，最多两位小数）',
);
const _shape = AppFailure(
  kind: FailureKind.protocol,
  code: 'order_late.invalid_response',
  safeMessage: '付款结果未能确认，请核实系统记录',
);
const _changed = AppFailure(
  kind: FailureKind.authentication,
  code: 'order_late.context_changed',
  safeMessage: '登录、连接或页面已变化，操作已停止',
);
const _unknown = AppFailure(
  kind: FailureKind.unknown,
  code: 'order_late.result_unknown',
  safeMessage: '付款结果不确定，请核实系统记录，请勿重复创建',
);
const _busy = AppFailure(
  kind: FailureKind.business,
  code: 'order_late.busy',
  safeMessage: '付款创建正在处理中，请勿重复提交',
);

int? _integer(Object? raw) {
  final value = raw is int ? raw : int.tryParse('$raw');
  return value != null && value >= 0 && value <= 9007199254740991
      ? value
      : null;
}

int? _positiveId(Object? raw) {
  final value = _integer(raw);
  return value != null && value > 0 ? value : null;
}

/// Service-staff collection, deliberately separate from /sel/cart_add_late_cnl
/// (which consumes an existing late-deposit balance during cashier checkout).
final class ProtocolOrderLateDepositApi {
  const ProtocolOrderLateDepositApi({required this.client});
  final ProtocolClient client;
  Future<Result<OrderLateDepositPayment>> create(
    ClientKind clientKind, {
    required String seatId,
    required int payType,
    required String amountYuan,
    String? authCode,
    required bool Function() canDispatch,
  }) async {
    final id = _positiveId(seatId);
    final scanning = payType == 5 || payType == 6;
    if (id == null ||
        ![1, 2, 5, 6].contains(payType) ||
        !isValidOrderLateDepositAmount(amountYuan) ||
        (scanning &&
            (authCode == null ||
                authCode.trim().isEmpty ||
                authCode.length > 128 ||
                RegExp(r'[\x00-\x1f]').hasMatch(authCode)))) {
      return const FailureResult(_invalid);
    }
    try {
      final result = await client.post(
        '/wo/do_waiter_late_olpay',
        client: clientKind,
        canDispatch: canDispatch,
        body: {
          'seat_id': id,
          'pay_type': payType,
          'pay_amt': amountYuan,
          'auth_code': scanning ? authCode : null,
        },
      );
      if (result.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      final envelope = result.valueOrNull!;
      if (_integer(envelope['code']) != 1) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.business,
            code: 'order_late.rejected',
            safeMessage: '服务端拒绝创建滞留金付款，请核实后重试',
          ),
        );
      }
      final data = envelope['data'];
      if (data is! Map) return const FailureResult(_shape);
      final status = data['r'] == null ? 0 : _integer(data['r']);
      final detail = _positiveId(data['pay_dtl_id']);
      final url = data['pay_url'] ?? '';
      if (status == null ||
          ![0, 1, 2].contains(status) ||
          url is! String ||
          url.length > 8192 ||
          (status == 0 && detail == null)) {
        return const FailureResult(_shape);
      }
      return Success(
        OrderLateDepositPayment(
          payDetailId: detail?.toString() ?? '',
          payUrl: url,
          result: status,
        ),
      );
    } on Object {
      return const FailureResult(_unknown);
    }
  }

  Future<Result<int>> status(
    ClientKind clientKind,
    String payDetailId, {
    required bool Function() canDispatch,
  }) async {
    final id = _positiveId(payDetailId);
    if (id == null) return const FailureResult(_invalid);
    try {
      final result = await client.post(
        '/wo/get_waiter_late_olpay_status',
        client: clientKind,
        canDispatch: canDispatch,
        body: {'id': id},
      );
      if (result.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      final envelope = result.valueOrNull!;
      if (_integer(envelope['code']) != 1) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.business,
            code: 'order_late.status_rejected',
            safeMessage: '付款查询未确认，请继续查询原付款记录',
          ),
        );
      }
      final data = envelope['data'];
      final status = data is Map ? _integer(data['status']) : null;
      return status == null ? const FailureResult(_shape) : Success(status);
    } on Object {
      return const FailureResult(_shape);
    }
  }
}

/// Share one instance in shell dependencies so reopening a page cannot retry an
/// unknown creation. There is no safe automated reset without a known detail id.
final class SessionBoundOrderLateDepositLoader
    implements OrderLateDepositLoader {
  SessionBoundOrderLateDepositLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });
  final SessionRepository session;
  final ProtocolOrderLateDepositApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  bool _creating = false, _needsVerification = false;
  @override
  bool get needsVerification => _needsVerification;

  bool Function() _capture(bool Function() canDispatch) {
    final user = session.currentUser,
        machine = session.currentMachine,
        epoch = generation();
    return () {
      try {
        return !session.isClosed &&
            user != null &&
            machine?.client == ClientKind.order &&
            identical(user, session.currentUser) &&
            identical(machine, session.currentMachine) &&
            generation() == epoch &&
            phase() == ConnectionPhase.online &&
            canDispatch();
      } on Object {
        return false;
      }
    };
  }

  @override
  Future<Result<OrderLateDepositPayment>> create({
    required String seatId,
    required int payType,
    required String amountYuan,
    String? authCode,
    required bool Function() canDispatch,
  }) async {
    if (_needsVerification) return const FailureResult(_unknown);
    if (_creating) return const FailureResult(_busy);
    final current = _capture(canDispatch);
    if (!current()) return const FailureResult(_changed);
    _creating = true;
    try {
      final result = await api.create(
        ClientKind.order,
        seatId: seatId,
        payType: payType,
        amountYuan: amountYuan,
        authCode: authCode,
        canDispatch: current,
      );
      final failure = result.failureOrNull;
      // These protocol failures happen before transport. Do not turn a failed
      // credential read or a rate gate into an irreversible unknown payment.
      if (const {
            'protocol.dispatch_invalidated',
            'protocol.request_throttled',
            'protocol.invalid_path',
            'authentication.credentials_unavailable',
          }.contains(failure?.code) ||
          failure?.kind == FailureKind.business) {
        return current() ? result : const FailureResult(_changed);
      }
      if (!current() || failure != null) {
        _needsVerification = true;
        return const FailureResult(_unknown);
      }
      return result;
    } on Object {
      _needsVerification = true;
      return const FailureResult(_unknown);
    } finally {
      _creating = false;
    }
  }

  @override
  Future<Result<int>> status(
    String payDetailId, {
    required bool Function() canDispatch,
  }) async {
    final current = _capture(canDispatch);
    if (!current()) return const FailureResult(_changed);
    final result = await api.status(
      ClientKind.order,
      payDetailId,
      canDispatch: current,
    );
    return current() ? result : const FailureResult(_changed);
  }
}
