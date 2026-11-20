import 'package:device_bridge_windows/device_bridge_windows.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('shouyin/terminal_identity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('reads Windows identity through native channel without arguments',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getMachineCode');
      expect(call.arguments, isNull);
      return 'windows:fixture-id';
    });
    final service = WindowsTerminalIdentityService();
    expect(service.supported, isTrue);
    expect((await service.getMachineCode()).valueOrNull, 'windows:fixture-id');
  });

  test('rejects an empty native identity', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => '   ');
    expect(
      (await WindowsTerminalIdentityService().getMachineCode())
          .failureOrNull
          ?.code,
      'device.terminal_identity_unavailable',
    );
  });

  test('maps registry errors without exposing native details', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
          code: 'read_failed', message: 'private-native-detail');
    });
    final failure =
        (await WindowsTerminalIdentityService().getMachineCode()).failureOrNull;
    expect(failure?.kind, FailureKind.device);
    expect(failure?.safeMessage, '无法获取终端机器码，请检查设备后重试');
  });

  test('missing native handler is a device failure, never a fake ID', () async {
    final result = await WindowsTerminalIdentityService().getMachineCode();
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull?.code, 'device.terminal_identity_unavailable');
  });
}
