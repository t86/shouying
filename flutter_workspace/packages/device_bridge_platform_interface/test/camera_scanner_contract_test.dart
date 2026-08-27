import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test(
    'camera scanner capability exposes controls without platform imports',
    () async {
      final scanner = _FakeCameraScanner();

      expect(scanner.capabilities.camera, isTrue);
      expect(await scanner.openCamera(), isA<Success<void>>());
      expect(scanner.isCameraOpen, isTrue);
      expect(scanner.buildCameraPreview(), isA<SizedBox>());
      await scanner.closeCamera();
      expect(scanner.isCameraOpen, isFalse);
    },
  );
}

final class _FakeCameraScanner implements CameraScannerService {
  bool _open = false;

  @override
  ScannerCapabilities get capabilities =>
      const ScannerCapabilities(camera: true);

  @override
  bool get isCameraOpen => _open;

  @override
  Stream<String> get scans => const Stream<String>.empty();

  @override
  Widget buildCameraPreview() => const SizedBox();

  @override
  Future<void> closeCamera() async => _open = false;

  @override
  Future<Result<void>> openCamera() async {
    _open = true;
    return const Success<void>(null);
  }

  @override
  void start() {}

  @override
  void stop() {}
}
