import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One-request authorization; never persist or export this value.
final class CashierQuotaAuthorization {
  CashierQuotaAuthorization({
    required this.code,
    required String password,
    this.passType = 1,
  }) : passwordDigest = md5
           .convert(utf8.encode(password))
           .toString()
           .toUpperCase(),
       valid =
           code.trim().isNotEmpty &&
           password.isNotEmpty &&
           (passType == 1 || passType == 2);
  final String code, passwordDigest;
  final int passType;
  final bool valid;
  Map<String, Object?> toWire() => {
    'auth_emp_code': code,
    'auth_emp_passwd': passwordDigest,
    'pass_type': passType,
  };
  @override
  String toString() => 'CashierQuotaAuthorization(redacted)';
}

final class CashierQuotaResult {
  const CashierQuotaResult({required this.name, required this.code});
  final String name, code;
}
