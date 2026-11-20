import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:card_table/src/super_admin_models.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

/// S9 超级账号协议端点调用
final class ProtocolSuperAdminApi {
  const ProtocolSuperAdminApi({
    required this.client,
    this.clientKind = ClientKind.superAdmin,
    this.canDispatch,
  });

  final ProtocolClient client;
  final ClientKind clientKind;
  final bool Function()? canDispatch;

  bool _allowed() {
    try {
      return canDispatch?.call() ?? true;
    } on Object {
      return false;
    }
  }

  Future<Result<Map<String, Object?>>> _post(
    String path, [
    Map<String, Object?> body = const <String, Object?>{},
  ]) async {
    try {
      if (!_allowed()) return const FailureResult(_changedFailure);
      final response = await client.post(
        path,
        body: body,
        client: clientKind,
        canDispatch: _allowed,
      );
      if (response.failureOrNull case final failure?) {
        return FailureResult(failure);
      }
      if (!_allowed()) return const FailureResult(_changedFailure);
      final value = response.valueOrNull!;
      final raw = value['code'];
      final int? code = switch (raw) {
        num()
            when raw.isFinite &&
                raw % 1 == 0 &&
                raw.abs() <= 9007199254740991 =>
          raw.toInt(),
        String() when RegExp(r'^\d+$').hasMatch(raw) => int.tryParse(raw),
        _ => null,
      };
      if (code == null) return const FailureResult(_shapeFailure);
      if (code != 1) return const FailureResult(_rejectedFailure);
      return Success(value);
    } on Object {
      return const FailureResult(_requestFailure);
    }
  }

  static const _shapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'super_admin.invalid_data',
    safeMessage: '超级账号服务数据格式不正确',
  );
  static const _changedFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'super_admin.context_changed',
    safeMessage: '页面或管理员会话已变化，请重试',
  );
  static const _inputFailure = AppFailure(
    kind: FailureKind.business,
    code: 'super_admin.invalid_input',
    safeMessage: '请检查输入内容',
  );
  static const _rejectedFailure = AppFailure(
    kind: FailureKind.business,
    code: 'super_admin.rejected',
    safeMessage: '服务端拒绝操作，请核实权限及输入',
  );
  static const _requestFailure = AppFailure(
    kind: FailureKind.network,
    code: 'super_admin.request_failed',
    safeMessage: '超级账号服务请求失败',
  );
  static bool _validId(int id) => id > 0 && id <= 9007199254740991;
  static Map<String, Object?> _data(Map<String, Object?> envelope) {
    final data = envelope['data'];
    if (data is! Map) throw const FormatException();
    return Map<String, Object?>.from(data);
  }

  Result<T> _decode<T>(
    Result<Map<String, Object?>> result,
    T Function(Map<String, Object?>) parse,
  ) {
    if (result.failureOrNull case final failure?) return FailureResult(failure);
    try {
      return Success(parse(result.valueOrNull!));
    } on Object {
      return const FailureResult(_shapeFailure);
    }
  }

  Result<bool> _parseSuccess(Result<Map<String, Object?>> response) {
    if (response case Success()) {
      return const Success(true);
    }
    return FailureResult(
      response.failureOrNull ??
          const AppFailure(
            kind: FailureKind.business,
            code: 'super_admin.error',
            safeMessage: '操作失败',
          ),
    );
  }

  // ---------------------------------------------------------------------------
  // S9.P2 超管登录与会话 API
  // ---------------------------------------------------------------------------

  /// 超级账号登录 (POST /sauth/login)
  Future<Result<SuperAdminLoginResult>> login({
    required String md5Password,
  }) async {
    if (!RegExp(r'^[0-9A-F]{32}$').hasMatch(md5Password)) {
      return const FailureResult(_inputFailure);
    }
    final res = await _post('/sauth/login', <String, Object?>{
      'password': md5Password,
    });
    return _decode(res, SuperAdminLoginResult.fromWire);
  }

  /// 超级账号登出 (POST /sauth/logout)
  Future<Result<bool>> logout() async {
    final res = await _post('/sauth/logout', const <String, Object?>{});
    return _parseSuccess(res);
  }

  /// 修改超管密码 (POST /smgr/chgpwd)
  Future<Result<bool>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (oldPassword.isEmpty && newPassword.isEmpty) {
      return const FailureResult(_inputFailure);
    }
    final res = await _post('/smgr/chgpwd', <String, Object?>{
      'old_password': md5
          .convert(utf8.encode(oldPassword))
          .toString()
          .toUpperCase(),
      'new_password': md5
          .convert(utf8.encode(newPassword))
          .toString()
          .toUpperCase(),
    });
    return _parseSuccess(res);
  }

  // ---------------------------------------------------------------------------
  // S9.P1 用户与岗位管理 API
  // ---------------------------------------------------------------------------

  /// 读取部门/岗位及员工列表 (POST /smgr/emps)
  Future<Result<SmgrInitData>> loadEmps({
    int isInit = 2,
    int deptId = 0,
    String stationId = '',
    String name = '',
  }) async {
    final parsedStation = stationId.isEmpty ? null : int.tryParse(stationId);
    if ((isInit != 1 && isInit != 2) ||
        deptId < 0 ||
        deptId > 9007199254740991 ||
        (stationId.isNotEmpty &&
            (!RegExp(r'^[1-9]\d*$').hasMatch(stationId) ||
                parsedStation == null ||
                !_validId(parsedStation)))) {
      return const FailureResult(_inputFailure);
    }
    final res = await _post('/smgr/emps', <String, Object?>{
      'is_init': isInit,
      'dept_id': deptId,
      'station_id': parsedStation ?? '',
      'name': name,
    });
    return _decode(res, (value) => SmgrInitData.fromWire(_data(value)));
  }

  /// 设置岗位有效 (POST /smgr/station_enable)
  Future<Result<bool>> setStationEnable(int stationId) async {
    if (!_validId(stationId)) return const FailureResult(_inputFailure);
    final res = await _post('/smgr/station_enable', <String, Object?>{
      'station_id': stationId,
    });
    return _parseSuccess(res);
  }

  /// 赋予门店管理员权限 (POST /smgr/grant)
  Future<Result<bool>> grantStationAdmin(int stationId) async {
    if (!_validId(stationId)) return const FailureResult(_inputFailure);
    final res = await _post('/smgr/grant', <String, Object?>{
      'station_id': stationId,
    });
    return _parseSuccess(res);
  }

  /// 收回门店管理员权限 (POST /smgr/revoke)
  Future<Result<bool>> revokeStationAdmin(int stationId) async {
    if (!_validId(stationId)) return const FailureResult(_inputFailure);
    final res = await _post('/smgr/revoke', <String, Object?>{
      'station_id': stationId,
    });
    return _parseSuccess(res);
  }

  /// 重置员工密码 (POST /smgr/resetpwd)
  Future<Result<bool>> resetEmpPassword(int empId) async {
    if (!_validId(empId)) return const FailureResult(_inputFailure);
    final res = await _post('/smgr/resetpwd', <String, Object?>{
      'emp_id': empId,
    });
    return _parseSuccess(res);
  }

  /// 启用员工状态 (POST /smgr/emp_enable)
  Future<Result<bool>> setEmpEnable(int empId) async {
    if (!_validId(empId)) return const FailureResult(_inputFailure);
    final res = await _post('/smgr/emp_enable', <String, Object?>{
      'emp_id': empId,
    });
    return _parseSuccess(res);
  }

  /// 禁用员工状态 (POST /smgr/emp_disable)
  Future<Result<bool>> setEmpDisable(int empId) async {
    if (!_validId(empId)) return const FailureResult(_inputFailure);
    final res = await _post('/smgr/emp_disable', <String, Object?>{
      'emp_id': empId,
    });
    return _parseSuccess(res);
  }

  // ---------------------------------------------------------------------------
  // S9.P3 终端注册 API
  // ---------------------------------------------------------------------------

  /// 终端设备授权注册 (POST /register/machine)
  Future<Result<TerminalRegisterResult>> registerTerminal({
    required String authCode,
    required String machineCode,
    String remark = '',
  }) async {
    if (authCode.trim().isEmpty || machineCode.trim().isEmpty) {
      return const FailureResult(_inputFailure);
    }
    final res = await _post('/register/machine', <String, Object?>{
      'auth_code': authCode,
      'machine_code': machineCode,
      'remark': remark,
    });
    return _decode(
      res,
      (value) => TerminalRegisterResult.fromWire(_data(value)),
    );
  }
}
