import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:device_bridge_windows/device_bridge_windows.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Windows scanner is an HID platform implementation', () {
    final ScannerService scanner = WindowsScannerService();

    expect(scanner.capabilities.hid, isTrue);
    expect(scanner.capabilities.camera, isFalse);
    expect(scanner.capabilities.degraded, isFalse);
    scanner.start();
    scanner.stop();
    (scanner as WindowsScannerService).dispose();
  });
}
