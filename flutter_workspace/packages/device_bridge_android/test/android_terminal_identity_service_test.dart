import 'package:device_bridge_android/device_bridge_android.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('shouyin/terminal_identity');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('reads Android identity through native channel without arguments',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getMachineCode');
      expect(call.arguments, isNull);
      return 'android:fixture-id';
    });
    final service = AndroidTerminalIdentityService();
    expect(service.supported, isTrue);
    expect((await service.getMachineCode()).valueOrNull, 'android:fixture-id');
  });

  test('rejects an empty native identity', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => '   ');
    expect(
      (await AndroidTerminalIdentityService().getMachineCode())
          .failureOrNull
          ?.code,
      'device.terminal_identity_unavailable',
    );
  });

  test('maps native errors without exposing native details', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(
          code: 'read_failed', message: 'private-native-detail');
    });
    final failure =
        (await AndroidTerminalIdentityService().getMachineCode()).failureOrNull;
    expect(failure?.kind, FailureKind.device);
    expect(failure?.safeMessage, '无法获取终端机器码，请检查设备后重试');
  });

  test('missing native handler is a device failure, never a fake ID', () async {
    final result = await AndroidTerminalIdentityService().getMachineCode();
    expect(result.valueOrNull, isNull);
    expect(result.failureOrNull?.code, 'device.terminal_identity_unavailable');
  });
}
