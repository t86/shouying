import 'package:foundation/foundation.dart';

/// Native terminal identity for registration. Never supplies a shared fallback ID.
abstract interface class TerminalIdentityService {
  bool get supported;

  Future<Result<String>> getMachineCode();
}

final class UnsupportedTerminalIdentityService
    implements TerminalIdentityService {
  const UnsupportedTerminalIdentityService();

  @override
  bool get supported => false;

  @override
  Future<Result<String>> getMachineCode() async => const FailureResult<String>(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.terminal_identity_unsupported',
          safeMessage: '当前平台不支持终端注册',
        ),
      );
}
