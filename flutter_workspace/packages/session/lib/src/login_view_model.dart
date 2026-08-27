import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';
import 'package:session/src/session_models.dart';
import 'package:session/src/session_repository.dart';

enum LoginPhase {
  idle,
  authorizingMachine,
  readyForLogin,
  loggingIn,
  authenticated,
  failure,
}

final class LoginState {
  const LoginState({required this.phase, this.failure});

  const LoginState.idle() : this(phase: LoginPhase.idle);

  final LoginPhase phase;
  final AppFailure? failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginState && phase == other.phase && failure == other.failure;

  @override
  int get hashCode => Object.hash(phase, failure);

  @override
  String toString() =>
      'LoginState(phase: ${phase.name}, failureCode: ${failure?.code})';
}

Duration? _disableRetry(int retryCount, Object error) => null;

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => throw StateError(
    'sessionRepositoryProvider must be overridden by the application',
  ),
  retry: _disableRetry,
);

final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(
  LoginViewModel.new,
  retry: _disableRetry,
);

final class LoginViewModel extends Notifier<LoginState> {
  bool _operationInProgress = false;

  @override
  LoginState build() {
    final repository = ref.watch(sessionRepositoryProvider);
    if (repository.currentUser != null) {
      return const LoginState(phase: LoginPhase.authenticated);
    }
    if (repository.currentMachine != null) {
      return const LoginState(phase: LoginPhase.readyForLogin);
    }
    return const LoginState.idle();
  }

  Future<Result<MachineSession>> authorizeMachine(String code) async {
    if (_operationInProgress) {
      return const FailureResult(_operationInProgressFailure);
    }
    _operationInProgress = true;
    state = const LoginState(phase: LoginPhase.authorizingMachine);
    try {
      final result = await ref
          .read(sessionRepositoryProvider)
          .authorizeMachine(code);
      if (ref.mounted) {
        final failure = result.failureOrNull;
        state = failure == null
            ? const LoginState(phase: LoginPhase.readyForLogin)
            : LoginState(phase: LoginPhase.failure, failure: failure);
      }
      return result;
    } finally {
      _operationInProgress = false;
    }
  }

  Future<Result<UserSession>> login({
    required String account,
    required String password,
    required EmployeeLoginType type,
  }) async {
    if (_operationInProgress) {
      return const FailureResult(_operationInProgressFailure);
    }
    _operationInProgress = true;
    state = const LoginState(phase: LoginPhase.loggingIn);
    try {
      final result = await ref
          .read(sessionRepositoryProvider)
          .login(account: account, password: password, type: type);
      if (ref.mounted) {
        final failure = result.failureOrNull;
        state = failure == null
            ? const LoginState(phase: LoginPhase.authenticated)
            : LoginState(phase: LoginPhase.failure, failure: failure);
      }
      return result;
    } finally {
      _operationInProgress = false;
    }
  }

  Future<Result<void>> logout() async {
    if (_operationInProgress) {
      return const FailureResult(_operationInProgressFailure);
    }
    _operationInProgress = true;
    try {
      final result = await ref.read(sessionRepositoryProvider).logout();
      if (ref.mounted) state = const LoginState.idle();
      return result;
    } finally {
      _operationInProgress = false;
    }
  }

  static const AppFailure _operationInProgressFailure = AppFailure(
    kind: FailureKind.business,
    code: 'session.operation_in_progress',
    safeMessage: '操作正在进行，请勿重复提交',
  );
}
