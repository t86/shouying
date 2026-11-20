import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('unsupported platforms fail explicitly without a machine code',
      () async {
    const service = UnsupportedTerminalIdentityService();
    expect(service.supported, isFalse);
    final result = await service.getMachineCode();
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull?.kind, FailureKind.device);
    expect(result.failureOrNull?.code, 'device.terminal_identity_unsupported');
  });
}
