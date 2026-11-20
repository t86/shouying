import 'package:card_table/src/business_day_api.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

/// UI additionally binds each operation to the displayed business day.
final class SessionBoundBusinessDayLoader {
  const SessionBoundBusinessDayLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
    this.dispatchScope,
  });
  final SessionRepository session;
  final BusinessDayApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  final Object? Function()? dispatchScope;

  Future<Result<void>> close() =>
      _guard((client, guard) => api.close(client, canDispatch: guard));
  Future<Result<void>> printShift() =>
      _guard((client, guard) => api.printShift(client, canDispatch: guard));
  Future<Result<AutoCloseConfig>> loadAutoClose() =>
      _guard((client, guard) => api.loadAutoClose(client, canDispatch: guard));
  Future<Result<void>> saveAutoClose({
    required bool enabled,
    required int hour,
    required int minute,
  }) => _guard(
    (client, guard) => api.saveAutoClose(
      client,
      enabled: enabled,
      hour: hour,
      minute: minute,
      canDispatch: guard,
    ),
  );

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind, bool Function()) invoke,
  ) async {
    try {
      final user = session.currentUser, machine = session.currentMachine;
      final epoch = generation();
      final scope = dispatchScope?.call();
      bool current() =>
          !session.isClosed &&
          identical(user, session.currentUser) &&
          identical(machine, session.currentMachine) &&
          generation() == epoch &&
          phase() == ConnectionPhase.online;
      if (session.isClosed ||
          user == null ||
          machine?.client != ClientKind.cashier ||
          phase() != ConnectionPhase.online) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.authentication,
            code: 'business_day.unavailable',
            safeMessage: '请在在线的收银会话中操作营业日',
          ),
        );
      }
      final result = await invoke(
        machine!.client,
        () => current() && dispatchScope?.call() == scope,
      );
      if (session.isClosed ||
          !identical(user, session.currentUser) ||
          !identical(machine, session.currentMachine) ||
          generation() != epoch ||
          phase() != ConnectionPhase.online) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.authentication,
            code: 'business_day.context_changed',
            safeMessage: '登录或连接已改变，请核实操作结果后重新打开',
          ),
        );
      }
      return result;
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'business_day.failed',
          safeMessage: '营业日操作失败，请核实当前状态',
        ),
      );
    }
  }
}
