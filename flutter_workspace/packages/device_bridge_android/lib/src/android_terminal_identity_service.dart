import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:foundation/foundation.dart';

final class AndroidTerminalIdentityService implements TerminalIdentityService {
  const AndroidTerminalIdentityService({
    MethodChannel channel = const MethodChannel('shouyin/terminal_identity'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  bool get supported => true;

  @override
  Future<Result<String>> getMachineCode() async {
    try {
      final code =
          (await _channel.invokeMethod<String>('getMachineCode'))?.trim();
      if (code != null && code.isNotEmpty) return Success<String>(code);
    } on Object {
      // Native exception messages can contain device details; do not surface them.
    }
    return const FailureResult<String>(
      AppFailure(
        kind: FailureKind.device,
        code: 'device.terminal_identity_unavailable',
        safeMessage: '无法获取终端机器码，请检查设备后重试',
      ),
    );
  }
}
