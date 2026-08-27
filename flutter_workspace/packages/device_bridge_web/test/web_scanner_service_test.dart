import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:device_bridge_web/device_bridge_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Web scanner reports focused-keyboard degraded capability', () {
    final ScannerService scanner = WebScannerService();

    expect(scanner.capabilities.hid, isTrue);
    expect(scanner.capabilities.camera, isFalse);
    expect(scanner.capabilities.degraded, isTrue);
    scanner.start();
    scanner.stop();
    (scanner as WebScannerService).dispose();
  });
}
