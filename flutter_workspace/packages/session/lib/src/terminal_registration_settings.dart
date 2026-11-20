import 'dart:convert';

import 'package:foundation/foundation.dart';
import 'package:session/src/flutter_secure_credential_store.dart';

final class RegisteredTerminal {
  const RegisteredTerminal({required this.machineCode, required this.authMode});
  final String machineCode;
  final int authMode;

  @override
  String toString() => 'RegisteredTerminal(authMode: $authMode)';
}

/// A terminal binding is separate from employee tk and administrator stk.
final class TerminalRegistrationSettings {
  const TerminalRegistrationSettings({
    SecureCredentialBackend backend = const FlutterSecureStorageBackend(),
  }) : _backend = backend;
  final SecureCredentialBackend _backend;
  static const _key = 'shouyin_terminal_registration_v1';
  static const _failure = AppFailure(
    kind: FailureKind.device,
    code: 'terminal.settings_unavailable',
    safeMessage: '终端注册设置无法保存或读取，请重试',
  );

  bool _valid(String code, int mode) =>
      code.isNotEmpty &&
      code == code.trim() &&
      code.length <= 512 &&
      !RegExp(r'[\x00-\x1f\x7f]').hasMatch(code) &&
      mode >= 0 &&
      mode <= 9007199254740991;

  Future<Result<RegisteredTerminal?>> load() async {
    try {
      final raw = await _backend.read(_key, sessionScoped: false);
      if (raw == null) return const Success(null);
      final data = jsonDecode(raw);
      if (data is! Map ||
          data['machine_code'] is! String ||
          data['auth_mode'] is! int ||
          !_valid(data['machine_code'] as String, data['auth_mode'] as int)) {
        return const FailureResult(_failure);
      }
      return Success(
        RegisteredTerminal(
          machineCode: data['machine_code'] as String,
          authMode: data['auth_mode'] as int,
        ),
      );
    } on Object {
      return const FailureResult(_failure);
    }
  }

  Future<Result<void>> save(String machineCode, int authMode) async {
    if (!_valid(machineCode, authMode)) return const FailureResult(_failure);
    try {
      await _backend.write(
        _key,
        jsonEncode({'machine_code': machineCode, 'auth_mode': authMode}),
        sessionScoped: false,
      );
      return const Success(null);
    } on Object {
      return const FailureResult(_failure);
    }
  }
}
