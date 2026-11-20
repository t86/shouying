import 'package:card_table/src/account_passwords.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class SessionBoundAccountPasswordLoader {
  const SessionBoundAccountPasswordLoader({
    required this.session,
    required this.api,
    required this.phase,
    required this.generation,
  });

  final SessionRepository session;
  final ProtocolAccountPasswordApi api;
  final ConnectionPhase Function() phase;
  final int Function() generation;

  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) => _guard(
    (client) => api.changePassword(
      client,
      oldPassword: oldPassword,
      newPassword: newPassword,
    ),
  );

  Future<Result<bool>> authPasswordEnabled() =>
      _guard(api.authPasswordEnabled);

  Future<Result<void>> changeAuthPassword({
    required bool enabled,
    required String loginPassword,
    required String authPassword,
  }) => _guard(
    (client) => api.changeAuthPassword(
      client,
      enabled: enabled,
      loginPassword: loginPassword,
      authPassword: authPassword,
    ),
  );

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
    code: 'authentication.account_password_session_required',
    safeMessage: '请登录后再修改密码',
  );
  static const AppFailure _unavailable = AppFailure(
    kind: FailureKind.network,
    code: 'network.account_password_unavailable',
    safeMessage: '连接未就绪，暂时无法修改密码',
  );
  static const AppFailure _changed = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.account_password_context_changed',
    safeMessage: '登录或连接状态已变化，请重新打开',
  );
  static const AppFailure _failed = AppFailure(
    kind: FailureKind.unknown,
    code: 'account_password.load_failed',
    safeMessage: '密码操作失败，请重试',
  );
}
