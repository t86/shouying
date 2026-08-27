import 'dart:async';

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
  const LoginState({
    required this.phase,
    required this.stablePhase,
    this.failure,
  });

  const LoginState.idle()
    : this(phase: LoginPhase.idle, stablePhase: LoginPhase.idle);

  final LoginPhase phase;
  final LoginPhase stablePhase;
  final AppFailure? failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoginState &&
          phase == other.phase &&
          stablePhase == other.stablePhase &&
          failure == other.failure;

  @override
  int get hashCode => Object.hash(phase, stablePhase, failure);

  @override
  String toString() =>
      'LoginState(phase: ${phase.name}, stablePhase: ${stablePhase.name}, '
      'failureCode: ${failure?.code})';
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
  bool _syncScheduled = false;
  StreamSubscription<MachineSession?>? _machineSubscription;
  StreamSubscription<UserSession?>? _userSubscription;

  @override
  LoginState build() {
    final repository = ref.watch(sessionRepositoryProvider);
    final oldMachineSubscription = _machineSubscription;
    final oldUserSubscription = _userSubscription;
    if (oldMachineSubscription != null) {
      unawaited(oldMachineSubscription.cancel());
    }
    if (oldUserSubscription != null) {
      unawaited(oldUserSubscription.cancel());
    }
    final machineSubscription = repository.machineSessions.listen(
      (_) => _scheduleRepositorySync(repository),
    );
    final userSubscription = repository.userSessions.listen(
      (_) => _scheduleRepositorySync(repository),
    );
    _machineSubscription = machineSubscription;
    _userSubscription = userSubscription;
    ref.onDispose(() {
      unawaited(machineSubscription.cancel());
      unawaited(userSubscription.cancel());
    });
    final stablePhase = _stablePhase(repository);
    return LoginState(phase: stablePhase, stablePhase: stablePhase);
  }

  Future<Result<MachineSession>> authorizeMachine(String code) async {
    if (_operationInProgress) {
      return const FailureResult(_operationInProgressFailure);
    }
    _operationInProgress = true;
    final repository = ref.read(sessionRepositoryProvider);
    state = LoginState(
      phase: LoginPhase.authorizingMachine,
      stablePhase: _stablePhase(repository),
    );
    try {
      final result = await repository.authorizeMachine(code);
      if (ref.mounted) _applyResult(result.failureOrNull, repository);
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
    final repository = ref.read(sessionRepositoryProvider);
    state = LoginState(
      phase: LoginPhase.loggingIn,
      stablePhase: _stablePhase(repository),
    );
    try {
      final result = await repository.login(
        account: account,
        password: password,
        type: type,
      );
      if (ref.mounted) _applyResult(result.failureOrNull, repository);
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
    final repository = ref.read(sessionRepositoryProvider);
    try {
      final result = await repository.logout();
      if (ref.mounted) _applyResult(result.failureOrNull, repository);
      return result;
    } finally {
      _operationInProgress = false;
    }
  }

  void _applyResult(AppFailure? failure, SessionRepository repository) {
    final stablePhase = _stablePhase(repository);
    state = failure == null
        ? LoginState(phase: stablePhase, stablePhase: stablePhase)
        : LoginState(
            phase: LoginPhase.failure,
            stablePhase: stablePhase,
            failure: failure,
          );
  }

  void _scheduleRepositorySync(SessionRepository repository) {
    if (_syncScheduled) return;
    _syncScheduled = true;
    unawaited(
      Future<void>.microtask(() {
        _syncScheduled = false;
        if (!ref.mounted || _operationInProgress) return;
        final stablePhase = _stablePhase(repository);
        state = LoginState(phase: stablePhase, stablePhase: stablePhase);
      }),
    );
  }

  LoginPhase _stablePhase(SessionRepository repository) {
    if (repository.currentUser != null) return LoginPhase.authenticated;
    if (repository.currentMachine != null) return LoginPhase.readyForLogin;
    return LoginPhase.idle;
  }

  static const AppFailure _operationInProgressFailure = AppFailure(
    kind: FailureKind.business,
    code: 'session.operation_in_progress',
    safeMessage: '操作正在进行，请勿重复提交',
  );
}
