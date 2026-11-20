import 'package:card_table/src/cashier_reports.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';
import 'package:protocol/protocol.dart';

final class SessionBoundCashierReportPrinter {
  const SessionBoundCashierReportPrinter({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });
  final SessionRepository session;
  final ProtocolCashierReportsApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  Future<Result<void>> print(CashierReportQuery query) async {
    const changed = AppFailure(
      kind: FailureKind.authentication,
      code: 'report.print_context_changed',
      safeMessage: '登录、连接或页面状态已变化，请重新查询后打印',
    );
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
          (query.canDispatch?.call() ?? true);
      if (!current()) return const FailureResult(changed);
      final result = await api.printReportQuery(
        machine!.client,
        query: query,
        canDispatch: current,
      );
      return current() ? result : const FailureResult(changed);
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'report.print_unconfirmed',
          safeMessage: '打印结果尚未确认，请检查打印记录，勿重复提交',
        ),
      );
    }
  }
}
