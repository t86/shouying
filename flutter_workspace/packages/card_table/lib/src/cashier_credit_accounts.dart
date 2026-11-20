import 'dart:convert';

import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

const creditRepaymentChannels = <int, String>{
  1: '现金还款',
  2: '微信还款',
  3: '支付宝还款',
  4: '刷卡还款',
  5: '工资抵扣',
  6: '会员卡扣款',
};

int _id(Object? raw) {
  final value = raw is num && raw.isFinite && raw % 1 == 0
      ? raw.toInt()
      : int.tryParse('$raw');
  if (value == null || value <= 0 || value > 9007199254740991) {
    throw const FormatException();
  }
  return value;
}

String _text(Object? raw) {
  if (raw == null) return '';
  if (raw is String && raw.length <= 2048) return raw;
  if (raw is num && raw.isFinite) return '$raw';
  throw const FormatException();
}

double _number(Object? raw) {
  final value = double.tryParse('$raw');
  if (value == null || !value.isFinite || value.abs() > 90071992547409) {
    throw const FormatException();
  }
  return value;
}

List<Map> _rows(Object? raw) {
  if (raw == null) return const [];
  if (raw is! List || raw.length > 10000) throw const FormatException();
  return [
    for (final row in raw)
      if (row is Map) row else throw const FormatException(),
  ];
}

final class CashierCreditAccount {
  const CashierCreditAccount({
    required this.id,
    required this.name,
    required this.amountYuan,
    this.contactName = '',
    this.contactPhone = '',
  });
  final String id, name, amountYuan, contactName, contactPhone;
  double get balance => _number(amountYuan);
  String get fingerprint =>
      jsonEncode([id, name, amountYuan, contactName, contactPhone]);
  factory CashierCreditAccount.fromWire(Map row) {
    _number(row['a']);
    return CashierCreditAccount(
      id: '${_id(row['id'])}',
      name: _text(row['n']),
      amountYuan: _text(row['a']),
      contactName: _text(row['cn']),
      contactPhone: _text(row['cp']),
    );
  }
}

final class CashierCreditAccountDraft {
  const CashierCreditAccountDraft({
    this.id,
    required this.name,
    this.contactName = '',
    this.contactPhone = '',
  });
  final String? id;
  final String name, contactName, contactPhone;
  Map<String, Object?> toWire() {
    if (name.isEmpty ||
        (contactPhone.isNotEmpty && contactPhone.length != 11)) {
      throw const FormatException();
    }
    return {
      'name': name,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      if (id != null) 'id': _id(id),
    };
  }
}

final class CashierCreditLog {
  const CashierCreditLog({
    required this.time,
    required this.type,
    required this.amountYuan,
    required this.channel,
    required this.operatorName,
  });
  final String time, type, amountYuan, channel, operatorName;
  factory CashierCreditLog.fromWire(Map row) => CashierCreditLog(
    time: _text(row['o']),
    type: _text(row['t']),
    amountYuan: _text(row['a']),
    channel: _text(row['c']),
    operatorName: _text(row['e']),
  );
}

final class CashierCreditOrder {
  const CashierCreditOrder({
    required this.id,
    required this.amountFen,
    required this.time,
    required this.seat,
    required this.salesName,
  });
  final String id, time, seat, salesName;
  final int amountFen;
  String get fingerprint => jsonEncode([id, amountFen, time, seat, salesName]);
  factory CashierCreditOrder.fromWire(Map row) {
    final amount = _number(row['a']);
    if (amount < 0 || amount % 1 != 0) throw const FormatException();
    return CashierCreditOrder(
      id: '${_id(row['id'])}',
      amountFen: amount.toInt(),
      time: _text(row['c']),
      seat: _text(row['s']),
      salesName: _text(row['sn']),
    );
  }
}

final class CashierCreditAllocation {
  const CashierCreditAllocation(this.orderId, this.channelId, this.rawFen);
  final String orderId;
  final int channelId;
  final double rawFen;
  int get amountFen => (rawFen + .5).floor();
}

final class CashierCreditRepayment {
  const CashierCreditRepayment({
    required this.accountId,
    required this.orders,
    required this.channelAmounts,
  });
  final String accountId;
  final List<CashierCreditOrder> orders;
  final Map<int, String> channelAmounts;
  double get totalYuan => channelAmounts.values.fold(
    0.0,
    (sum, raw) => sum + (raw.trim().isEmpty ? 0 : _number(raw)),
  );
  List<CashierCreditAllocation> allocate() {
    _id(accountId);
    if (orders.isEmpty ||
        channelAmounts.isEmpty ||
        orders.map((o) => o.id).toSet().length != orders.length) {
      throw const FormatException('请选择订单和还款方式');
    }
    final channels = channelAmounts.keys.toList()..sort();
    final amounts = <int, double>{};
    for (final id in channels) {
      if (!creditRepaymentChannels.containsKey(id)) {
        throw const FormatException('还款方式无效');
      }
      final raw = channelAmounts[id]!;
      final value = raw.trim().isEmpty ? 0.0 : _number(raw);
      if (value < 0) throw const FormatException('还款金额不能为负数');
      amounts[id] = value * 100;
    }
    final total = double.parse(totalYuan.toStringAsFixed(2));
    final owed = orders.fold<int>(0, (sum, order) {
      _id(order.id);
      if (order.amountFen < 0) throw const FormatException();
      return sum + order.amountFen;
    });
    if (total <= 0) throw const FormatException('请输入还款金额');
    if (total * 100 > owed) throw const FormatException('还款金额不能超过选中订单的挂账金额总和');
    final allocated = <String, Map<int, double>>{
      for (final order in orders) order.id: {},
    };
    for (final channel in channels) {
      var remaining = amounts[channel]!;
      for (final order in orders) {
        if (remaining <= 0) break;
        final row = allocated[order.id]!;
        final capacity =
            order.amountFen - row.values.fold<double>(0, (a, b) => a + b);
        if (capacity <= 0) continue;
        final amount = remaining < capacity ? remaining : capacity;
        row[channel] = amount;
        remaining -= amount;
      }
    }
    final result = <CashierCreditAllocation>[];
    for (final order in orders) {
      final row = allocated[order.id]!;
      for (final channel in channels) {
        if ((row[channel] ?? 0) > 0) {
          result.add(CashierCreditAllocation(order.id, channel, row[channel]!));
        }
      }
      // Do not let independently rounded fractional cents overpay an order.
      if (result
              .where((a) => a.orderId == order.id)
              .fold<int>(0, (sum, a) => sum + a.amountFen) >
          order.amountFen) {
        throw const FormatException('分配后的金额超过订单余额，请调整渠道金额');
      }
    }
    if (result.isEmpty) throw const FormatException('没有有效的还款数据');
    return List.unmodifiable(result);
  }

  Map<String, Object?> toWire() {
    final allocation = allocate();
    return {
      'ids': allocation.map((a) => _id(a.orderId)).toList(),
      'amts': allocation.map((a) => a.amountFen).toList(),
      'cnl_names': allocation
          .map((a) => creditRepaymentChannels[a.channelId]!)
          .toList(),
    };
  }
}

const _invalid = AppFailure(
  kind: FailureKind.business,
  code: 'credit.invalid_input',
  safeMessage: '请检查账户、订单、联系方式及还款金额',
);
const _shape = AppFailure(
  kind: FailureKind.protocol,
  code: 'credit.invalid_data',
  safeMessage: '挂账服务返回数据格式不正确',
);
const _stale = AppFailure(
  kind: FailureKind.authentication,
  code: 'credit.context_changed',
  safeMessage: '登录或连接已变化，请重新查询核实',
);
const _unknown = AppFailure(
  kind: FailureKind.unknown,
  code: 'credit.unknown',
  safeMessage: '操作结果尚未确认，请显式查询核实，勿重复提交',
);
const _busy = AppFailure(
  kind: FailureKind.business,
  code: 'credit.busy',
  safeMessage: '请等待当前操作完成并查询核实',
);

final class ProtocolCashierCreditAccountsApi {
  const ProtocolCashierCreditAccountsApi({required this.client});
  final ProtocolClient client;
  Future<Result<Map<String, Object?>>> _post(
    ClientKind kind,
    String path,
    Map<String, Object?> body, {
    bool Function()? canDispatch,
  }) async {
    if (kind != ClientKind.cashier) return const FailureResult(_stale);
    try {
      final result = await client.post(
        path,
        client: kind,
        body: body,
        canDispatch: canDispatch,
      );
      if (result.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      final raw = result.valueOrNull!['code'];
      final code = raw is num && raw.isFinite && raw % 1 == 0
          ? raw.toInt()
          : raw is String
          ? int.tryParse(raw)
          : null;
      if (code == null) return const FailureResult(_shape);
      if (code != 1) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.business,
            code: 'credit.rejected',
            safeMessage: '服务端拒绝操作，请核实账户和还款信息',
          ),
        );
      }
      return result;
    } on Object {
      return const FailureResult(_unknown);
    }
  }

  Future<Result<List<T>>> _read<T>(
    ClientKind kind,
    String path,
    Map<String, Object?> body,
    T Function(Map) decode,
  ) async {
    final result = await _post(kind, path, body);
    if (result.failureOrNull case final failure?) return FailureResult(failure);
    try {
      final data = result.valueOrNull!['data'];
      if (data is! Map) throw const FormatException();
      return Success(List.unmodifiable(_rows(data['records']).map(decode)));
    } on Object {
      return const FailureResult(_shape);
    }
  }

  Future<Result<List<CashierCreditAccount>>> list(
    ClientKind kind,
    String keyword,
  ) => _read(kind, '/cnlacct/list', {
    'key': keyword,
  }, CashierCreditAccount.fromWire);
  Future<Result<List<CashierCreditLog>>> logs(
    ClientKind kind,
    String accountId,
    int typeId,
  ) async {
    try {
      if (![0, 1, 2].contains(typeId)) throw const FormatException();
      return await _read(kind, '/cnlacct/get_op_logs', {
        'id': _id(accountId),
        'type_id': typeId,
      }, CashierCreditLog.fromWire);
    } on Object {
      return const FailureResult(_invalid);
    }
  }

  Future<Result<List<CashierCreditOrder>>> orders(
    ClientKind kind,
    String accountId,
  ) async {
    try {
      return await _read(kind, '/cnlacct/get_orders', {
        'id': _id(accountId),
      }, CashierCreditOrder.fromWire);
    } on Object {
      return const FailureResult(_invalid);
    }
  }

  Future<Result<void>> _write(
    ClientKind kind,
    String path,
    Map<String, Object?> body,
    bool Function() canDispatch,
  ) async {
    final result = await _post(kind, path, body, canDispatch: canDispatch);
    return result.failureOrNull == null
        ? const Success(null)
        : FailureResult(result.failureOrNull!);
  }

  Future<Result<void>> save(
    ClientKind kind,
    CashierCreditAccountDraft draft, {
    required bool Function() canDispatch,
  }) async {
    try {
      return await _write(
        kind,
        draft.id == null ? '/cnlacct/new' : '/cnlacct/save',
        draft.toWire(),
        canDispatch,
      );
    } on Object {
      return const FailureResult(_invalid);
    }
  }

  Future<Result<void>> delete(
    ClientKind kind,
    String id, {
    required bool Function() canDispatch,
  }) async {
    try {
      return await _write(kind, '/cnlacct/del', {'id': _id(id)}, canDispatch);
    } on Object {
      return const FailureResult(_invalid);
    }
  }

  Future<Result<void>> repay(
    ClientKind kind,
    CashierCreditRepayment repayment, {
    required bool Function() canDispatch,
  }) async {
    try {
      return await _write(
        kind,
        '/cnlacct/return',
        repayment.toWire(),
        canDispatch,
      );
    } on Object {
      return const FailureResult(_invalid);
    }
  }
}

abstract interface class CashierCreditAccountsLoader {
  bool get needsVerification;
  Future<Result<List<CashierCreditAccount>>> list(
    String keyword, {
    bool verify = false,
  });
  Future<Result<List<CashierCreditLog>>> logs(String accountId, int typeId);
  Future<Result<List<CashierCreditOrder>>> orders(String accountId);
  Future<Result<void>> save(
    CashierCreditAccountDraft draft,
    bool Function() current,
  );
  Future<Result<void>> delete(
    CashierCreditAccount account,
    bool Function() current,
  );
  Future<Result<void>> repay(
    CashierCreditRepayment repayment,
    bool Function() current,
  );
}

final class SessionBoundCashierCreditAccountsLoader
    implements CashierCreditAccountsLoader {
  SessionBoundCashierCreditAccountsLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });
  final SessionRepository session;
  final ProtocolCashierCreditAccountsApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  bool _writing = false, _unknownResult = false;
  @override
  bool get needsVerification => _unknownResult;
  bool Function() _capture(bool Function() permitted) {
    final user = session.currentUser, machine = session.currentMachine;
    final epoch = generation();
    return () =>
        !session.isClosed &&
        user != null &&
        machine?.client == ClientKind.cashier &&
        identical(user, session.currentUser) &&
        identical(machine, session.currentMachine) &&
        epoch == generation() &&
        phase() == ConnectionPhase.online &&
        permitted();
  }

  Future<Result<T>> _read<T>(Future<Result<T>> Function() run) async {
    final current = _capture(() => true);
    if (!current()) return const FailureResult(_stale);
    try {
      final result = await run();
      return current() ? result : const FailureResult(_stale);
    } on Object {
      return const FailureResult(_unknown);
    }
  }

  @override
  Future<Result<List<CashierCreditAccount>>> list(
    String keyword, {
    bool verify = false,
  }) async {
    if (verify && _writing) return const FailureResult(_busy);
    final current = _capture(() => true);
    final result = await _read(() => api.list(ClientKind.cashier, keyword));
    if (!current()) return const FailureResult(_stale);
    if (verify && result.failureOrNull == null && !_writing && current()) {
      _unknownResult = false;
    }
    return result;
  }

  @override
  Future<Result<List<CashierCreditLog>>> logs(String id, int type) =>
      _read(() => api.logs(ClientKind.cashier, id, type));
  @override
  Future<Result<List<CashierCreditOrder>>> orders(String id) =>
      _read(() => api.orders(ClientKind.cashier, id));
  Future<Result<void>> _mutate(
    bool Function() permitted,
    Future<Result<void>> Function(bool Function()) run, {
    Future<Result<void>> Function()? preflight,
  }) async {
    if (_writing || _unknownResult) return const FailureResult(_busy);
    final current = _capture(permitted);
    if (!current()) return const FailureResult(_stale);
    _writing = true;
    try {
      if (preflight != null) {
        final check = await preflight();
        if (!current()) return const FailureResult(_stale);
        if (check.failureOrNull != null) return check;
      }
      _unknownResult = true;
      final result = await run(current);
      if (!current()) return const FailureResult(_stale);
      if (result.failureOrNull == null ||
          result.failureOrNull?.kind == FailureKind.business) {
        _unknownResult = false;
      }
      return result;
    } on Object {
      return const FailureResult(_unknown);
    } finally {
      _writing = false;
    }
  }

  @override
  Future<Result<void>> save(
    CashierCreditAccountDraft draft,
    bool Function() current,
  ) => _mutate(
    current,
    (guard) => api.save(ClientKind.cashier, draft, canDispatch: guard),
  );
  @override
  Future<Result<void>> delete(
    CashierCreditAccount account,
    bool Function() current,
  ) => _mutate(
    current,
    (guard) => api.delete(ClientKind.cashier, account.id, canDispatch: guard),
    preflight: () async {
      final result = await api.list(ClientKind.cashier, '');
      if (result.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      final matches = result.valueOrNull!
          .where((a) => a.id == account.id)
          .toList();
      if (matches.length != 1 ||
          matches.single.balance > 0 ||
          matches.single.fingerprint != account.fingerprint) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.business,
            code: 'credit.account_changed',
            safeMessage: '账户余额或资料已变化，请刷新后核实；欠款账户不可删除',
          ),
        );
      }
      return const Success(null);
    },
  );
  @override
  Future<Result<void>> repay(
    CashierCreditRepayment repayment,
    bool Function() current,
  ) => _mutate(
    current,
    (guard) => api.repay(ClientKind.cashier, repayment, canDispatch: guard),
    preflight: () async {
      final result = await api.orders(ClientKind.cashier, repayment.accountId);
      if (result.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      final ids = repayment.orders.map((o) => o.id).toSet();
      final actual = result.valueOrNull!
          .where((o) => ids.contains(o.id))
          .map((o) => o.fingerprint)
          .toList();
      if (jsonEncode(actual) !=
          jsonEncode(repayment.orders.map((o) => o.fingerprint).toList())) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.business,
            code: 'credit.orders_changed',
            safeMessage: '待还订单已变化，请重新查询和分配金额',
          ),
        );
      }
      return const Success(null);
    },
  );
}
