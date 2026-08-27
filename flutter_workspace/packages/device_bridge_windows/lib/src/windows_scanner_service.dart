import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';

final class WindowsScannerService implements ScannerService {
  WindowsScannerService() : _scanner = HardwareKeyboardScannerService();

  final HardwareKeyboardScannerService _scanner;

  @override
  ScannerCapabilities get capabilities => _scanner.capabilities;

  @override
  Stream<String> get scans => _scanner.scans;

  @override
  void start() => _scanner.start();

  @override
  void stop() => _scanner.stop();

  void dispose() => _scanner.dispose();
}
