import 'package:flutter/widgets.dart';
import 'package:foundation/foundation.dart';

abstract interface class ScannerService {
  Stream<String> get scans;

  ScannerCapabilities get capabilities;

  void start();

  void stop();
}

abstract interface class CameraScannerService implements ScannerService {
  bool get isCameraOpen;

  Stream<AppFailure> get failures;

  Future<Result<void>> openCamera();

  Future<void> closeCamera();

  Widget buildCameraPreview();
}

final class ScannerCapabilities {
  const ScannerCapabilities({
    this.hid = true,
    this.camera = false,
    this.degraded = false,
  });

  final bool hid;
  final bool camera;
  final bool degraded;
}
