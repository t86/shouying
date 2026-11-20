import 'dart:convert';

import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class CashierVoucherQuery {
  const CashierVoucherQuery({this.typeId = 0, this.keyword = ''});
  final int typeId;
  final String keyword;
  bool get valid => const [0, 12, 22, 32].contains(typeId);
  Map<String, Object?> toWire() => {'type_id': typeId, 'key': keyword};
}

final class CashierVoucherRecord {
  const CashierVoucherRecord({
    required this.id,
    required this.cells,
    required this.canCancel,
  });
  final String id;
  final Map<String, String> cells;
  final bool canCancel;
  String get fingerprint => jsonEncode([id, canCancel, cells]);
  static const columns = [
    '操作员',
    '卡券类型',
    '卡券金额',
    '卡券ID',
    '卡券名称',
    '卡券券码',
    '兑换套餐',
    '收银订单状态',
    '卡券状态',
    '卡券领取时间',
    '当台二消金额',
    '卡台',
    '开台时间',
    '订位人',
    '每台可用张数',
    '使用模式',
    '核销时间',
    '退券时间',
    '退券人',
  ];
  static const _fields = [
    'o',
    't',
    'a',
    'k',
    'l',
    'c',
    'p',
    'os',
    's',
    'g',
    'a2',
    'sn',
    'ot',
    'se',
    'uc',
    'um',
    'vt',
    'ct',
    'ce',
  ];
  factory CashierVoucherRecord.fromWire(Map raw) {
    final id = _id('${raw['id']}');
    if (id == null) throw const FormatException();
    final cells = <String, String>{};
    for (var i = 0; i < columns.length; i++) {
      final value = raw[_fields[i]];
      if (value != null && value is! String && value is! num) {
        throw const FormatException();
      }
      if (_fields[i] == 'a' || _fields[i] == 'a2') {
        final amount = num.tryParse('$value');
        if (amount == null || !amount.isFinite) throw const FormatException();
        cells[columns[i]] = (amount / 100).toStringAsFixed(2);
      } else if (_fields[i] == 't') {
        cells[columns[i]] = switch (num.tryParse('$value')) {
          12 => '抖音券',
          22 => '美团券',
          32 => '推广券',
          _ => value?.toString() ?? '',
        };
      } else {
        cells[columns[i]] = value?.toString() ?? '';
      }
    }
    return CashierVoucherRecord(
      id: '$id',
      cells: Map.unmodifiable(cells),
      canCancel: raw['b'] is num && raw['b'] == 1,
    );
  }
  @override
  String toString() => 'CashierVoucherRecord(redacted)';
}

int? _id(String value) {
  final id = RegExp(r'^[1-9]\d*$').hasMatch(value) ? int.tryParse(value) : null;
  return id != null && id <= 9007199254740991 ? id : null;
}

const _shape = AppFailure(
  kind: FailureKind.protocol,
  code: 'voucher_records.invalid_data',
  safeMessage: '卡券记录返回格式不正确',
);
const _context = AppFailure(
  kind: FailureKind.authentication,
  code: 'voucher_records.context_changed',
  safeMessage: '登录、连接或记录已变化，请重新查询核实',
);
const _input = AppFailure(
  kind: FailureKind.business,
  code: 'voucher_records.invalid_input',
  safeMessage: '卡券查询条件或记录无效',
);
const _unknown = AppFailure(
  kind: FailureKind.unknown,
  code: 'voucher_records.unknown',
  safeMessage: '卡券请求失败，请查询核实后重试',
);
AppFailure? _ack(Result<Map<String, Object?>> result) {
  if (result.failureOrNull case final failure?) return failure;
  final raw = result.valueOrNull!['code'];
  final code = raw is num && raw.isFinite && raw % 1 == 0
      ? raw.toInt()
      : raw is String
      ? int.tryParse(raw)
      : null;
  return code == 1
      ? null
      : code == null
      ? _shape
      : const AppFailure(
          kind: FailureKind.business,
          code: 'voucher_records.rejected',
          safeMessage: '服务端拒绝操作，请核实卡券状态',
        );
}

final class ProtocolCashierVoucherApi {
  const ProtocolCashierVoucherApi({required this.client});
  final ProtocolClient client;
  Future<Result<List<CashierVoucherRecord>>> load(
    ClientKind kind,
    CashierVoucherQuery query,
  ) async {
    if (kind != ClientKind.cashier) return const FailureResult(_context);
    if (!query.valid) return const FailureResult(_input);
    try {
      final result = await client.post(
        '/sel/rpt/get_kq_csm_list_for_back',
        client: kind,
        body: query.toWire(),
      );
      if (_ack(result) case final failure?) return FailureResult(failure);
      final data = result.valueOrNull!['data'];
      if (data is! Map) throw const FormatException();
      final records = data['records'] ?? [];
      if (records is! List || records.length > 10000) {
        throw const FormatException();
      }
      final rows = <CashierVoucherRecord>[];
      final ids = <String>{};
      for (final raw in records) {
        if (raw is! Map) throw const FormatException();
        final row = CashierVoucherRecord.fromWire(raw);
        if (!ids.add(row.id)) throw const FormatException();
        rows.add(row);
      }
      return Success(List.unmodifiable(rows));
    } on FormatException {
      return const FailureResult(_shape);
    } on Object {
      return const FailureResult(_unknown);
    }
  }

  Future<Result<void>> cancel(
    ClientKind kind,
    String recordId, {
    required bool Function() canDispatch,
  }) async {
    if (kind != ClientKind.cashier) return const FailureResult(_context);
    final id = _id(recordId);
    if (id == null) return const FailureResult(_input);
    try {
      final result = await client.post(
        '/sel/cancel_kq_csm',
        client: kind,
        canDispatch: canDispatch,
        body: {'kq_order_id': id},
      );
      final failure = _ack(result);
      return failure == null ? const Success(null) : FailureResult(failure);
    } on Object {
      return const FailureResult(_unknown);
    }
  }

  Future<Result<ProtocolBinaryFile>> export(
    ClientKind kind,
    CashierVoucherQuery query,
  ) async {
    if (kind != ClientKind.cashier) return const FailureResult(_context);
    if (!query.valid) return const FailureResult(_input);
    try {
      return await client.postBinary(
        '/sel/rpt/exp_kq_csm_list_for_back',
        client: kind,
        body: query.toWire(),
        fallbackFileName: '当日卡券核销记录表.xlsx',
      );
    } on Object {
      return const FailureResult(_unknown);
    }
  }
}

final class SessionBoundCashierVoucherLoader {
  const SessionBoundCashierVoucherLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });
  final SessionRepository session;
  final ProtocolCashierVoucherApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  Future<Result<List<CashierVoucherRecord>>> load(CashierVoucherQuery query) =>
      _guard((kind, guard) => api.load(kind, query), () => true);
  Future<Result<void>> cancel(String recordId, bool Function() guard) => _guard(
    (kind, current) => api.cancel(kind, recordId, canDispatch: current),
    guard,
  );
  Future<Result<ProtocolBinaryFile>> export(
    CashierVoucherQuery query,
    bool Function() guard,
  ) => _guard((kind, current) => api.export(kind, query), guard);
  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind, bool Function()) invoke,
    bool Function() permitted,
  ) async {
    try {
      final user = session.currentUser, machine = session.currentMachine;
      final epoch = generation();
      bool current() =>
          !session.isClosed &&
          user != null &&
          machine?.client == ClientKind.cashier &&
          identical(user, session.currentUser) &&
          identical(machine, session.currentMachine) &&
          generation() == epoch &&
          phase() == ConnectionPhase.online &&
          permitted();
      if (!current()) return const FailureResult(_context);
      final result = await invoke(machine!.client, current);
      return current() ? result : const FailureResult(_context);
    } on Object {
      return const FailureResult(_unknown);
    }
  }
}
