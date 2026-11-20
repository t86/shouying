import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

final class ProtocolAccountPasswordApi {
  const ProtocolAccountPasswordApi({required this.client});
  final ProtocolClient client;

  Future<Result<void>> changePassword(
    ClientKind client, {
    required String oldPassword,
    required String newPassword,
  }) async {
    if (oldPassword.isEmpty ||
        newPassword.isEmpty ||
        oldPassword.length > _maxPassword ||
        newPassword.length > _maxPassword) {
      return const FailureResult(_shapeFailure);
    }
    final oldDigest = _digest(oldPassword);
    final newDigest = _digest(newPassword);
    final response = await this.client.post(
      '/emp/chg_pwd',
      body: <String, Object?>{
        'old_password': oldDigest,
        'new_password': newDigest,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '修改密码失败，请检查原密码',
      disallowed: <String>[oldPassword, newPassword, oldDigest, newDigest],
    );
  }

  Future<Result<bool>> authPasswordEnabled(ClientKind client) async {
    final response = await this.client.postWithoutBody(
      '/emp/get_auth_pwd_enabled',
      client: client,
    );
    return _readEnabled(response);
  }

  Future<Result<void>> changeAuthPassword(
    ClientKind client, {
    required bool enabled,
    required String loginPassword,
    required String authPassword,
  }) async {
    if (enabled &&
        (loginPassword.isEmpty ||
            authPassword.isEmpty ||
            loginPassword.length > _maxPassword ||
            authPassword.length > _maxPassword)) {
      return const FailureResult(_shapeFailure);
    }
    final loginDigest = enabled ? _digest(loginPassword) : '';
    final authDigest = enabled ? _digest(authPassword) : '';
    final response = await this.client.post(
      '/emp/chg_auth_pwd',
      body: <String, Object?>{
        'login_password': loginDigest,
        'auth_password': authDigest,
      },
      client: client,
    );
    return _ack(
      response,
      fallback: '保存授权密码失败，请重试',
      disallowed: <String>[
        loginPassword,
        authPassword,
        loginDigest,
        authDigest,
      ],
    );
  }

  Result<void> _ack(
    Result<Map<String, Object?>> response, {
    required String fallback,
    required List<String> disallowed,
  }) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.account_password_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: fallback,
            disallowed: disallowed,
          ),
        ),
      );
    }
    return const Success(null);
  }

  Result<bool> _readEnabled(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map<String, Object?>) {
      return const FailureResult(_shapeFailure);
    }
    final enabled = data['enabled'];
    return switch (enabled) {
      1 || '1' || true => const Success(true),
      0 || '0' || false => const Success(false),
      _ => const FailureResult(_shapeFailure),
    };
  }
}

String _digest(String value) =>
    md5.convert(utf8.encode(value)).toString().toUpperCase();

int? _wireCode(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt(),
  String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(value),
  _ => null,
};

String _safeMessage(
  Object? value, {
  required String fallback,
  required List<String> disallowed,
}) {
  if (value is! String || value.isEmpty || value.length > 160) return fallback;
  for (final secret in disallowed) {
    if (secret.isNotEmpty && value.contains(secret)) return fallback;
  }
  if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(value)) return fallback;
  return value;
}

const int _maxPassword = 256;
const AppFailure _shapeFailure = AppFailure(
  kind: FailureKind.protocol,
  code: 'protocol.account_password_shape',
  safeMessage: '密码接口返回了无法识别的数据',
);
const AppFailure _rejectedFailure = AppFailure(
  kind: FailureKind.business,
  code: 'business.account_password_rejected',
  safeMessage: '服务端拒绝密码操作，请重试',
);
