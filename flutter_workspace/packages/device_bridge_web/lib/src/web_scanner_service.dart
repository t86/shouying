import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';

final class WebScannerService implements ScannerService {
  WebScannerService()
    : _scanner = HardwareKeyboardScannerService(
        capabilities: const ScannerCapabilities(degraded: true),
      );

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
