import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/src/session_models.dart';

abstract interface class SessionRemoteApi {
  Future<Result<MachineSession>> authorizeMachine(String code);

  Future<Result<UserSession>> login({
    required MachineSession machine,
    required String account,
    required String password,
    required EmployeeLoginType type,
  });

  Future<Result<void>> logout(MachineSession machine);
}

final class SessionApi implements SessionRemoteApi {
  factory SessionApi({
    required ProtocolClient client,
    required CredentialStore credentialStore,
  }) => SessionApi._(client, credentialStore);

  const SessionApi._(this._client, this._credentialStore);

  static const int _maxMachineCodeLength = 128;
  static const int _maxAccountLength = 128;
  static const int _maxPasswordLength = 256;
  static const int _maxIdentifierLength = 128;
  static const int _maxNameLength = 256;
  static const int _maxCredentialLength = 4096;
  static const int _maxBusinessMessageLength = 160;

  final ProtocolClient _client;
  final CredentialStore _credentialStore;

  @override
  Future<Result<MachineSession>> authorizeMachine(String code) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty ||
        normalizedCode.length > _maxMachineCodeLength) {
      return const FailureResult(_invalidMachineCodeFailure);
    }

    final response = await _client.post(
      '/term/auth',
      body: <String, Object?>{'code': normalizedCode},
      client: ClientKind.superAdmin,
    );
    final protocolFailure = response.failureOrNull;
    if (protocolFailure != null) return FailureResult(protocolFailure);
    final payload = response.valueOrNull!;
    if (!_isSuccessCode(payload['code'])) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.term_auth_rejected',
          safeMessage: _safeBusinessMessage(
            payload['msg'] ?? payload['message'],
            fallback: '终端授权失败，请检查授权码',
          ),
        ),
      );
    }

    final data = _stringKeyedMap(payload['data']);
    final credential = _boundedString(
      data?['tk'],
      maxLength: _maxCredentialLength,
    );
    final mode = MachineAccessMode.fromWire(data?['am']);
    final machineId = _boundedIdentifier(data?['id']);
    final machineName = _boundedString(data?['n'], maxLength: _maxNameLength);
    if (credential == null ||
        mode == null ||
        machineId == null ||
        machineName == null) {
      return const FailureResult(_termAuthShapeFailure);
    }

    try {
      await _credentialStore.writeTk(credential);
    } on Object {
      return const FailureResult(_credentialsUnavailableFailure);
    }
    return Success(
      MachineSession(
        machineId: machineId,
        machineName: machineName,
        client: mode.client,
      ),
    );
  }

  @override
  Future<Result<UserSession>> login({
    required MachineSession machine,
    required String account,
    required String password,
    required EmployeeLoginType type,
  }) async {
    final normalizedAccount = account.trim();
    if (normalizedAccount.isEmpty ||
        normalizedAccount.length > _maxAccountLength ||
        password.trim().isEmpty ||
        password.length > _maxPasswordLength) {
      return const FailureResult(_invalidLoginInputFailure);
    }

    final passwordDigest = md5
        .convert(utf8.encode(password))
        .toString()
        .toUpperCase();
    final response = await _client.post(
      '/auth/login',
      body: <String, Object?>{
        'code': normalizedAccount,
        'passwd': passwordDigest,
        'client_name': machine.client.clientName,
        'pt': type.wireValue,
      },
      client: machine.client,
    );
    final protocolFailure = response.failureOrNull;
    if (protocolFailure != null) return FailureResult(protocolFailure);
    final payload = response.valueOrNull!;
    if (!_isSuccessCode(payload['code'])) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.login_rejected',
          safeMessage: _safeBusinessMessage(
            payload['msg'] ?? payload['message'],
            fallback: '员工登录失败，请检查账号或密码',
            disallowed: <String>[password, passwordDigest],
          ),
        ),
      );
    }

    final data = _stringKeyedMap(payload['data']);
    final employeeId = _boundedIdentifier(data?['emp_id']);
    final name = _boundedString(data?['name'], maxLength: _maxNameLength);
    final stationId = _boundedIdentifier(data?['station_id']);
    if (employeeId == null || name == null || stationId == null) {
      return const FailureResult(_loginShapeFailure);
    }
    return Success(
      UserSession(employeeId: employeeId, name: name, stationId: stationId),
    );
  }

  @override
  Future<Result<void>> logout(MachineSession machine) async {
    final response = await _client.post('/auth/logout', client: machine.client);
    final protocolFailure = response.failureOrNull;
    if (protocolFailure != null) return FailureResult(protocolFailure);
    final payload = response.valueOrNull!;
    if (!_isSuccessCode(payload['code'])) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.logout_rejected',
          safeMessage: _safeBusinessMessage(
            payload['msg'] ?? payload['message'],
            fallback: '远程退出失败，本地登录信息已清除',
          ),
        ),
      );
    }
    return const Success<void>(null);
  }

  static bool _isSuccessCode(Object? value) =>
      (value is int && value.runtimeType == int && value == 1) || value == '1';

  static Map<String, Object?>? _stringKeyedMap(Object? value) {
    if (value is! Map || value.keys.any((key) => key is! String)) return null;
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key as String: entry.value as Object?,
    };
  }

  static String? _boundedIdentifier(Object? value) {
    if (value is int && value.runtimeType == int) return value.toString();
    return _boundedString(value, maxLength: _maxIdentifierLength);
  }

  static String? _boundedString(Object? value, {required int maxLength}) {
    if (value is! String) return null;
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > maxLength) return null;
    return normalized;
  }

  static String _safeBusinessMessage(
    Object? value, {
    required String fallback,
    List<String> disallowed = const <String>[],
  }) {
    if (value is! String || value.isEmpty || value.length > 4096) {
      return fallback;
    }
    final unsafePattern = RegExp(
      r'[\x00-\x1f\x7f<>]|(?:^|\s)#\d+|\b(?:password|passwd|token|tk|stack)\b|\b[0-9a-fA-F]{32,}\b',
      caseSensitive: false,
    );
    if (unsafePattern.hasMatch(value) ||
        disallowed.any(
          (secret) => secret.isNotEmpty && value.contains(secret),
        )) {
      return fallback;
    }
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return fallback;
    if (normalized.length <= _maxBusinessMessageLength) return normalized;
    var end = _maxBusinessMessageLength;
    if (_isHighSurrogate(normalized.codeUnitAt(end - 1))) end -= 1;
    return normalized.substring(0, end);
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xd800 && codeUnit <= 0xdbff;

  @override
  String toString() => 'SessionApi()';

  static const AppFailure _invalidMachineCodeFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.machine_code_invalid',
    safeMessage: '请输入有效的终端授权码',
  );
  static const AppFailure _invalidLoginInputFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.login_input_invalid',
    safeMessage: '请输入有效的员工账号和密码',
  );
  static const AppFailure _termAuthShapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.term_auth_shape',
    safeMessage: '终端授权服务返回了无法识别的数据',
  );
  static const AppFailure _loginShapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.login_shape',
    safeMessage: '员工登录服务返回了无法识别的数据',
  );
  static const AppFailure _credentialsUnavailableFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.credentials_unavailable',
    safeMessage: '登录信息不可用，请重新登录',
  );
}
