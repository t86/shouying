import 'dart:async';

import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/src/session_api.dart';
import 'package:session/src/session_models.dart';

final class SessionRepository {
  factory SessionRepository({
    required SessionRemoteApi api,
    required CredentialStore credentialStore,
  }) => SessionRepository._(api, credentialStore);

  SessionRepository._(this._api, this._credentialStore) {
    machineSessions = _CurrentValueStream<MachineSession?>(
      _machineController.stream,
      () => _machine,
    );
    userSessions = _CurrentValueStream<UserSession?>(
      _userController.stream,
      () => _user,
    );
  }

  final SessionRemoteApi _api;
  final CredentialStore _credentialStore;
  final StreamController<MachineSession?> _machineController =
      StreamController<MachineSession?>.broadcast(sync: true);
  final StreamController<UserSession?> _userController =
      StreamController<UserSession?>.broadcast(sync: true);

  late final Stream<MachineSession?> machineSessions;
  late final Stream<UserSession?> userSessions;

  MachineSession? _machine;
  UserSession? _user;
  bool _operationInProgress = false;
  bool _closed = false;

  MachineSession? get currentMachine => _machine;
  UserSession? get currentUser => _user;
  bool get isClosed => _closed;

  Future<Result<MachineSession>> authorizeMachine(String code) async {
    final guard = _guardOperation<MachineSession>();
    if (guard != null) return guard;
    try {
      final result = await _api.authorizeMachine(code);
      if (_closed) return const FailureResult(_repositoryClosedFailure);
      final machine = result.valueOrNull;
      if (machine != null && machine != _machine) {
        _setUser(null);
        _setMachine(machine);
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
    final guard = _guardOperation<UserSession>();
    if (guard != null) return guard;
    try {
      final machine = _machine;
      if (machine == null) return const FailureResult(_machineRequiredFailure);
      final result = await _api.login(
        machine: machine,
        account: account,
        password: password,
        type: type,
      );
      if (_closed) return const FailureResult(_repositoryClosedFailure);
      final user = result.valueOrNull;
      if (user != null) _setUser(user);
      return result;
    } finally {
      _operationInProgress = false;
    }
  }

  Future<Result<void>> logout() async {
    final guard = _guardOperation<void>();
    if (guard != null) return guard;
    try {
      final machine = _machine;
      _setUser(null);
      _setMachine(null);

      CredentialSnapshot? snapshot;
      var snapshotUnavailable = false;
      AppFailure? credentialFailure;
      try {
        snapshot = await _credentialStore.readSnapshot();
      } on Object {
        snapshotUnavailable = true;
        credentialFailure = _credentialsUnavailableFailure;
      }

      final remoteResult = machine == null
          ? const Success<void>(null)
          : await _api.logout(machine);

      if (snapshot != null) {
        try {
          await _credentialStore.clearTkIfMatches(snapshot.tk);
        } on Object {
          credentialFailure = _credentialsUnavailableFailure;
        }
        try {
          await _credentialStore.clearStkIfMatches(snapshot.stk);
        } on Object {
          credentialFailure = _credentialsUnavailableFailure;
        }
      } else if (snapshotUnavailable) {
        try {
          await _credentialStore.clearTk();
        } on Object {
          credentialFailure = _credentialsUnavailableFailure;
        }
        try {
          await _credentialStore.clearStk();
        } on Object {
          credentialFailure = _credentialsUnavailableFailure;
        }
      }

      final remoteFailure = remoteResult.failureOrNull;
      if (remoteFailure != null) return FailureResult(remoteFailure);
      if (credentialFailure != null) return FailureResult(credentialFailure);
      if (_closed) return const FailureResult(_repositoryClosedFailure);
      return const Success<void>(null);
    } finally {
      _operationInProgress = false;
    }
  }

  Result<T>? _guardOperation<T>() {
    if (_closed) return const FailureResult(_repositoryClosedFailure);
    if (_operationInProgress) {
      return const FailureResult(_operationInProgressFailure);
    }
    _operationInProgress = true;
    return null;
  }

  void _setMachine(MachineSession? value) {
    if (_machine == value) return;
    _machine = value;
    if (!_machineController.isClosed) _machineController.add(value);
  }

  void _setUser(UserSession? value) {
    if (_user == value) return;
    _user = value;
    if (!_userController.isClosed) _userController.add(value);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _setUser(null);
    _setMachine(null);
    await Future.wait<void>(<Future<void>>[
      _userController.close(),
      _machineController.close(),
    ]);
  }

  static const AppFailure _operationInProgressFailure = AppFailure(
    kind: FailureKind.business,
    code: 'session.operation_in_progress',
    safeMessage: '操作正在进行，请勿重复提交',
  );
  static const AppFailure _repositoryClosedFailure = AppFailure(
    kind: FailureKind.unknown,
    code: 'session.repository_closed',
    safeMessage: '登录服务已关闭',
  );
  static const AppFailure _machineRequiredFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.machine_required',
    safeMessage: '请先完成终端授权',
  );
  static const AppFailure _credentialsUnavailableFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.credentials_unavailable',
    safeMessage: '登录信息不可用，请重新登录',
  );
}

final class _CurrentValueStream<T> extends Stream<T> {
  const _CurrentValueStream(this._source, this._current);

  final Stream<T> _source;
  final T Function() _current;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    late final StreamController<T> controller;
    StreamSubscription<T>? sourceSubscription;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        sourceSubscription = _source.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.add(_current());
      },
      onPause: () => sourceSubscription?.pause(),
      onResume: () => sourceSubscription?.resume(),
      onCancel: () => sourceSubscription?.cancel(),
    );
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
