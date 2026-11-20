import 'package:card_table/src/super_admin_api.dart';
import 'package:card_table/src/super_admin_models.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

abstract interface class SuperAdminLoader implements Listenable {
  bool get isAuthenticated;
  bool get isBusy;
  int get sessionRevision;
  Future<Result<void>> restore();
  Future<Result<SuperAdminLoginResult>> login({
    required String md5Password,
    bool Function()? canDispatch,
  });
  Future<Result<void>> logout({bool Function()? canDispatch});
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
    bool Function()? canDispatch,
  });
  Future<Result<SmgrInitData>> loadEmps({
    int isInit = 2,
    int deptId = 0,
    String stationId = '',
    String name = '',
    bool Function()? canDispatch,
  });
  Future<Result<void>> setStationEnable(
    int stationId, {
    bool Function()? canDispatch,
  });
  Future<Result<void>> toggleStationAdmin(
    int stationId,
    bool grant, {
    bool Function()? canDispatch,
  });
  Future<Result<void>> resetEmpPassword(
    int empId, {
    bool Function()? canDispatch,
  });
  Future<Result<void>> toggleEmpStatus(
    int empId,
    bool enable, {
    bool Function()? canDispatch,
  });
  Future<Result<TerminalRegisterResult>> registerTerminal({
    required String authCode,
    required String machineCode,
    bool Function()? canDispatch,
  });
}

/// Authority belongs exclusively to a verified stk, never the ordinary session.
final class ProtocolSuperAdminLoader extends ChangeNotifier
    implements SuperAdminLoader {
  ProtocolSuperAdminLoader({
    required this.api,
    required this.credentials,
    this.session,
  });
  final ProtocolSuperAdminApi api;
  final CredentialStore credentials;
  // Constructor compatibility only; never consulted for administrator authority.
  final SessionRepository? session;
  String? _token;
  bool _closed = false;
  int _generation = 0;
  int _revision = 0;
  int _pending = 0;
  Future<void> _credentialTail = Future<void>.value();

  @override
  bool get isAuthenticated => !_closed && _token != null;
  @override
  bool get isBusy => !_closed && _pending > 0;
  @override
  int get sessionRevision => _revision;

  static const _changed = AppFailure(
    kind: FailureKind.authentication,
    code: 'super_admin.context_changed',
    safeMessage: '页面或管理员会话已变化，请重新登录',
  );
  static const _required = AppFailure(
    kind: FailureKind.authentication,
    code: 'super_admin.login_required',
    safeMessage: '请先登录超级管理员',
  );
  static const _storeFailed = AppFailure(
    kind: FailureKind.unknown,
    code: 'super_admin.credentials_unavailable',
    safeMessage: '管理员凭据存储不可用，请重试',
  );

  bool _allowed(bool Function()? guard) {
    try {
      return !_closed &&
          (guard?.call() ?? true) &&
          (api.canDispatch?.call() ?? true);
    } on Object {
      return false;
    }
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  void _start() {
    _pending++;
    _notify();
  }

  void _finish() {
    _pending--;
    _notify();
  }

  ProtocolSuperAdminApi _scoped(bool Function() guard) => ProtocolSuperAdminApi(
    client: api.client,
    clientKind: api.clientKind,
    canDispatch: guard,
  );
  Future<T> _credentials<T>(Future<T> Function() action) {
    final next = _credentialTail.then((_) => action());
    _credentialTail = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  void _invalidate() {
    _generation++;
    _revision++;
    _token = null;
    _notify();
  }

  @override
  Future<Result<void>> restore() async {
    if (_closed) return const FailureResult(_changed);
    _invalidate();
    final generation = _generation;
    bool current() => _generation == generation && _allowed(null);
    _start();
    try {
      final token = await _credentials(credentials.readStk);
      if (!current()) return const FailureResult(_changed);
      if (token == null || token.trim().isEmpty) {
        return const FailureResult(_required);
      }
      final result = await _scoped(current).loadEmps();
      if (!current()) return const FailureResult(_changed);
      if (result.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      if (await credentials.readStk() != token || !current()) {
        return const FailureResult(_changed);
      }
      _token = token;
      _revision++;
      _notify();
      return const Success(null);
    } on Object {
      return const FailureResult(_storeFailed);
    } finally {
      _finish();
    }
  }

  @override
  Future<Result<SuperAdminLoginResult>> login({
    required String md5Password,
    bool Function()? canDispatch,
  }) async {
    if (!_allowed(canDispatch)) return const FailureResult(_changed);
    _invalidate();
    final generation = _generation;
    bool current() => _generation == generation && _allowed(canDispatch);
    _start();
    try {
      final result = await _scoped(current).login(md5Password: md5Password);
      if (!current()) return const FailureResult(_changed);
      if (result.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      final login = result.valueOrNull!;
      final saved = await _credentials(() async {
        if (!current()) return false;
        await credentials.writeStk(login.token);
        if (!current()) {
          await credentials.clearStkIfMatches(login.token);
          return false;
        }
        return true;
      });
      if (!saved || !current()) return const FailureResult(_changed);
      _token = login.token;
      _revision++;
      _notify();
      return Success(login);
    } on Object {
      return const FailureResult(_storeFailed);
    } finally {
      _finish();
    }
  }

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ProtocolSuperAdminApi scoped) action,
    bool Function()? canDispatch,
  ) async {
    if (!_allowed(canDispatch)) return const FailureResult(_changed);
    final token = _token;
    if (token == null) return const FailureResult(_required);
    final generation = _generation;
    bool current() =>
        _generation == generation && _token == token && _allowed(canDispatch);
    _start();
    try {
      final stored = await credentials.readStk();
      if (!current()) return const FailureResult(_changed);
      if (stored != token) {
        _invalidate();
        return const FailureResult(_changed);
      }
      final result = await action(_scoped(current));
      if (result.failureOrNull?.code == 'authentication.stk_expired' &&
          _generation == generation &&
          _token == token) {
        _invalidate();
        await _credentials(() => credentials.clearStkIfMatches(token));
        return result;
      }
      if (!current()) return const FailureResult(_changed);
      return result;
    } on Object {
      return const FailureResult(_storeFailed);
    } finally {
      _finish();
    }
  }

  @override
  Future<Result<void>> logout({bool Function()? canDispatch}) async {
    if (!_allowed(canDispatch)) return const FailureResult(_changed);
    final token = _token;
    final generation = ++_generation;
    _token = null;
    // Revoke authority now; advance the public revision after the remote call so
    // the caller's captured revision can still guard logout's page lifetime.
    _start();
    bool current() => _generation == generation && _allowed(canDispatch);
    Result<void> result = const Success(null);
    String? candidate = token;
    try {
      candidate ??= await _credentials(() async {
        if (_generation != generation) return null;
        return credentials.readStk();
      });
      if (token != null) result = _void(await _scoped(current).logout());
    } on Object {
      result = const FailureResult(_storeFailed);
    } finally {
      try {
        final expected = candidate;
        if (expected != null) {
          await _credentials(() async {
            // Do not erase a newer login even if the server reused its token.
            if (_generation == generation || _token != expected) {
              await credentials.clearStkIfMatches(expected);
            }
          });
        }
      } on Object {
        result = const FailureResult(_storeFailed);
      }
      if (_generation == generation) _revision++;
      _finish();
    }
    return result;
  }

  static Result<void> _void(Result<bool> result) {
    if (result.failureOrNull case final failure?) return FailureResult(failure);
    return const Success(null);
  }

  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
    bool Function()? canDispatch,
  }) async => _void(
    await _guard(
      (scoped) => scoped.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      ),
      canDispatch,
    ),
  );
  @override
  Future<Result<SmgrInitData>> loadEmps({
    int isInit = 2,
    int deptId = 0,
    String stationId = '',
    String name = '',
    bool Function()? canDispatch,
  }) => _guard(
    (scoped) => scoped.loadEmps(
      isInit: isInit,
      deptId: deptId,
      stationId: stationId,
      name: name,
    ),
    canDispatch,
  );
  @override
  Future<Result<void>> setStationEnable(
    int stationId, {
    bool Function()? canDispatch,
  }) async => _void(
    await _guard((scoped) => scoped.setStationEnable(stationId), canDispatch),
  );
  @override
  Future<Result<void>> toggleStationAdmin(
    int stationId,
    bool grant, {
    bool Function()? canDispatch,
  }) async => _void(
    await _guard(
      (scoped) => grant
          ? scoped.grantStationAdmin(stationId)
          : scoped.revokeStationAdmin(stationId),
      canDispatch,
    ),
  );
  @override
  Future<Result<void>> resetEmpPassword(
    int empId, {
    bool Function()? canDispatch,
  }) async => _void(
    await _guard((scoped) => scoped.resetEmpPassword(empId), canDispatch),
  );
  @override
  Future<Result<void>> toggleEmpStatus(
    int empId,
    bool enable, {
    bool Function()? canDispatch,
  }) async => _void(
    await _guard(
      (scoped) =>
          enable ? scoped.setEmpEnable(empId) : scoped.setEmpDisable(empId),
      canDispatch,
    ),
  );
  @override
  Future<Result<TerminalRegisterResult>> registerTerminal({
    required String authCode,
    required String machineCode,
    bool Function()? canDispatch,
  }) async {
    bool current() => _allowed(canDispatch);
    if (!current()) return const FailureResult(_changed);
    // Public pre-auth endpoint: independent from administrator authentication.
    return _scoped(current)
        .registerTerminal(authCode: authCode, machineCode: machineCode);
  }

  @override
  void dispose() {
    _closed = true;
    _generation++;
    _revision++;
    _token = null;
    super.dispose();
  }
}
