import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class CashierProfitLossProduct {
  const CashierProfitLossProduct({
    required this.id,
    required this.name,
    required this.firstCategory,
    required this.secondCategory,
  });
  final String id, name, firstCategory, secondCategory;
}

final class CashierProfitLossCatalog {
  const CashierProfitLossCatalog({
    this.libraries = const {},
    this.productsByLibrary = const {},
  });
  final Map<String, String> libraries;
  final Map<String, List<CashierProfitLossProduct>> productsByLibrary;
}

final class CashierProfitLossEntry {
  const CashierProfitLossEntry({
    required this.productId,
    required this.profit,
    required this.loss,
  });
  final String productId;
  final int profit, loss;
}

final class CashierProfitLossDraft {
  const CashierProfitLossDraft({
    required this.libraryId,
    required this.entries,
  });
  final String libraryId;
  final List<CashierProfitLossEntry> entries;
}

final class CashierProfitLossRecordEntry {
  const CashierProfitLossRecordEntry({
    required this.name,
    required this.firstCategory,
    required this.secondCategory,
    required this.profit,
    required this.loss,
  });
  final String name, firstCategory, secondCategory, profit, loss;
}

final class CashierProfitLossRecord {
  const CashierProfitLossRecord({
    required this.library,
    required this.operatorName,
    required this.time,
    required this.entries,
  });
  final String library, operatorName, time;
  final List<CashierProfitLossRecordEntry> entries;
}

const _shape = AppFailure(
  kind: FailureKind.protocol,
  code: 'profit_loss.invalid_data',
  safeMessage: '盘盈盘亏数据格式不正确',
);
const _context = AppFailure(
  kind: FailureKind.authentication,
  code: 'profit_loss.context_changed',
  safeMessage: '请在有效的在线收银会话中重新打开盘盈盘亏',
);
const _rejected = AppFailure(
  kind: FailureKind.business,
  code: 'profit_loss.rejected',
  safeMessage: '服务端拒绝盘盈盘亏操作，请核实数据',
);
const _failed = AppFailure(
  kind: FailureKind.unknown,
  code: 'profit_loss.failed',
  safeMessage: '盘盈盘亏请求结果尚未确认，请核实服务端记录',
);

final class ProtocolCashierProfitLossApi {
  const ProtocolCashierProfitLossApi({required this.client});
  final ProtocolClient client;
  static int? _id(String value) {
    final id = RegExp(r'^[1-9]\d*$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    return id != null && id <= 9007199254740991 ? id : null;
  }

  static AppFailure? _ack(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) return failure;
    final raw = response.valueOrNull!['code'];
    final code = raw is num && raw.isFinite && raw % 1 == 0
        ? raw.toInt()
        : raw is String
        ? int.tryParse(raw)
        : null;
    return code == null
        ? _shape
        : code == 1
        ? null
        : _rejected;
  }

  Future<Result<List<CashierProfitLossRecord>>> load(ClientKind kind) async {
    if (kind != ClientKind.cashier) return const FailureResult(_context);
    try {
      final response = await client.postWithoutBody(
        '/sel/get_prd_profit_loss',
        client: kind,
      );
      if (_ack(response) case final failure?) return FailureResult(failure);
      final data = response.valueOrNull!['data'];
      if (data is! Map) return const FailureResult(_shape);
      final records = data['records'] ?? [];
      if (records is! List || records.length > 10000) {
        return const FailureResult(_shape);
      }
      String text(Object? value) {
        if (value == null) return '';
        if (value is! String && value is! num) throw const FormatException();
        return '$value';
      }

      final result = <CashierProfitLossRecord>[];
      for (final row in records) {
        if (row is! Map) throw const FormatException();
        final details = row['rs'] ?? [];
        if (details is! List || details.length > 10000) {
          throw const FormatException();
        }
        result.add(
          CashierProfitLossRecord(
            library: text(row['m']),
            operatorName: text(row['o']),
            time: text(row['t']),
            entries: [
              for (final detail in details)
                if (detail is Map)
                  CashierProfitLossRecordEntry(
                    name: text(detail['n']),
                    firstCategory: text(detail['on']),
                    secondCategory: text(detail['tn']),
                    profit: text(detail['pc']),
                    loss: text(detail['lc']),
                  )
                else
                  throw const FormatException(),
            ],
          ),
        );
      }
      return Success(result);
    } on FormatException {
      return const FailureResult(_shape);
    } on Object {
      return const FailureResult(_failed);
    }
  }

  Future<Result<void>> submit(
    ClientKind kind,
    CashierProfitLossDraft draft, {
    bool Function()? canDispatch,
  }) async {
    if (kind != ClientKind.cashier) return const FailureResult(_context);
    if (_id(draft.libraryId) == null ||
        draft.entries.isEmpty ||
        draft.entries.any(
          (e) =>
              _id(e.productId) == null ||
              e.profit.abs() > 9007199254740991 ||
              e.loss.abs() > 9007199254740991,
        )) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'profit_loss.invalid_input',
          safeMessage: '请选择出品库和商品，数量须为整数',
        ),
      );
    }
    try {
      final response = await client.post(
        '/sel/do_prd_profit_loss',
        client: kind,
        canDispatch: canDispatch,
        body: {
          'mklib_id': _id(draft.libraryId),
          'prd_ids': draft.entries.map((e) => _id(e.productId)).toList(),
          'prd_profit_cnts': draft.entries.map((e) => e.profit).toList(),
          'prd_loss_cnts': draft.entries.map((e) => e.loss).toList(),
        },
      );
      final failure = _ack(response);
      return failure == null ? const Success(null) : FailureResult(failure);
    } on Object {
      return const FailureResult(_failed);
    }
  }
}

final class SessionBoundCashierProfitLossLoader {
  const SessionBoundCashierProfitLossLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });
  final SessionRepository session;
  final ProtocolCashierProfitLossApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  Future<Result<List<CashierProfitLossRecord>>> load() =>
      _guard((kind, guard) => api.load(kind), () => true);
  Future<Result<void>> submit(
    CashierProfitLossDraft draft,
    bool Function() canDispatch,
  ) => _guard(
    (kind, guard) => api.submit(kind, draft, canDispatch: guard),
    canDispatch,
  );
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
          epoch == generation() &&
          phase() == ConnectionPhase.online &&
          permitted();
      if (!current()) return const FailureResult(_context);
      final result = await invoke(machine!.client, current);
      return current() ? result : const FailureResult(_context);
    } on Object {
      return const FailureResult(_failed);
    }
  }
}
