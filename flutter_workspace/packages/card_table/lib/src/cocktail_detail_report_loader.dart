import 'package:card_table/src/cocktail_detail_report.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

/// Binds one read to the order session and connection epoch that started it.
final class SessionBoundCocktailDetailReportLoader {
  const SessionBoundCocktailDetailReportLoader({
    required this.session,
    required this.loadRemote,
    required this.phase,
    required this.generation,
  });

  final SessionRepository session;
  final CocktailDetailLoader loadRemote;
  final ConnectionPhase Function() phase;
  final int Function() generation;

  Future<Result<List<CocktailDetailReportRow>>> load(String keyword) async {
    try {
      final user = session.currentUser;
      final machine = session.currentMachine;
      if (user == null ||
          machine == null ||
          machine.client != ClientKind.order) {
        return const FailureResult(_sessionRequiredFailure);
      }
      final epoch = generation();
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_connectionUnavailableFailure);
      }

      final result = await loadRemote(keyword);

      if (!identical(user, session.currentUser) ||
          !identical(machine, session.currentMachine) ||
          generation() != epoch) {
        return const FailureResult(_contextChangedFailure);
      }
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_connectionUnavailableFailure);
      }
      return result;
    } on Object {
      return const FailureResult(_loadFailure);
    }
  }

  static const AppFailure _sessionRequiredFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.cocktail_detail_report_session_required',
    safeMessage: '请登录点单系统后查询鸡尾酒明细表',
  );
  static const AppFailure _connectionUnavailableFailure = AppFailure(
    kind: FailureKind.network,
    code: 'network.cocktail_detail_report_unavailable',
    safeMessage: '连接未就绪，暂时无法查询鸡尾酒明细表',
  );
  static const AppFailure _contextChangedFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.cocktail_detail_report_context_changed',
    safeMessage: '登录或连接状态已变化，请重新查询鸡尾酒明细表',
  );
  static const AppFailure _loadFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'cocktail_detail_report.load_failed',
    safeMessage: '鸡尾酒明细表查询失败，请重试',
  );
}
