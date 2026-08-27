import 'dart:async';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

abstract interface class AndroidCameraControllerAdapter {
  Stream<String?> get barcodes;

  Stream<CameraControllerFailure> get failures;

  Future<void> start();

  Future<void> stop();

  Future<void> dispose();

  Widget buildPreview();
}

enum CameraControllerFailure { permissionDenied, unavailable }

final class CameraPermissionDenied implements Exception {
  const CameraPermissionDenied();
}

final class AndroidScannerService implements CameraScannerService {
  AndroidScannerService({
    ScannerService? hidScanner,
    AndroidCameraControllerAdapter? cameraController,
    MonotonicClock? clock,
  }) : _hidScanner = hidScanner ?? HardwareKeyboardScannerService(),
       _cameraController =
           cameraController ?? MobileScannerCameraControllerAdapter(),
       _clock = clock ?? _stopwatchClock() {
    _hidSubscription = _hidScanner.scans.listen(_emit);
    _cameraSubscription = _cameraController.barcodes.listen(_handleCameraValue);
    _controllerFailureSubscription = _cameraController.failures.listen(
      _handleControllerFailure,
    );
  }

  final ScannerService _hidScanner;
  final AndroidCameraControllerAdapter _cameraController;
  final MonotonicClock _clock;
  final StreamController<String> _scans = StreamController<String>.broadcast(
    sync: true,
  );
  final StreamController<AppFailure> _failures =
      StreamController<AppFailure>.broadcast(sync: true);
  late final StreamSubscription<String> _hidSubscription;
  late final StreamSubscription<String?> _cameraSubscription;
  late final StreamSubscription<CameraControllerFailure>
  _controllerFailureSubscription;
  bool _cameraOpen = false;
  bool _disposed = false;
  String? _lastCameraValue;
  Duration? _lastCameraValueAt;

  @override
  ScannerCapabilities get capabilities =>
      const ScannerCapabilities(hid: true, camera: true);

  @override
  bool get isCameraOpen => _cameraOpen;

  @override
  Stream<String> get scans => _scans.stream;

  @override
  Stream<AppFailure> get failures => _failures.stream;

  @override
  void start() {
    if (_disposed) return;
    _hidScanner.start();
  }

  @override
  void stop() {
    _hidScanner.stop();
    unawaited(closeCamera());
  }

  @override
  Future<Result<void>> openCamera() async {
    if (_disposed) {
      return const FailureResult<void>(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.camera_unavailable',
          safeMessage: '相机扫码不可用',
        ),
      );
    }
    if (_cameraOpen) return const Success<void>(null);
    try {
      await _cameraController.start();
      _cameraOpen = true;
      return const Success<void>(null);
    } on CameraPermissionDenied {
      _cameraOpen = false;
      return const FailureResult<void>(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.camera_permission',
          safeMessage: '未获得相机权限',
        ),
      );
    } on Object {
      _cameraOpen = false;
      return const FailureResult<void>(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.camera_unavailable',
          safeMessage: '相机扫码不可用',
        ),
      );
    }
  }

  @override
  Future<void> closeCamera() async {
    if (!_cameraOpen) return;
    _cameraOpen = false;
    _lastCameraValue = null;
    _lastCameraValueAt = null;
    try {
      await _cameraController.stop();
    } on Object {
      // Closing camera is best effort and must not crash diagnostics.
    }
  }

  @override
  Widget buildCameraPreview() => _cameraController.buildPreview();

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _cameraOpen = false;
    _hidScanner.stop();
    await _hidSubscription.cancel();
    await _cameraSubscription.cancel();
    await _controllerFailureSubscription.cancel();
    try {
      await _cameraController.stop();
    } on Object {
      // Continue disposal when the platform controller was never started.
    }
    await _cameraController.dispose();
    await _scans.close();
    await _failures.close();
    if (_hidScanner case final HardwareKeyboardScannerService hid) {
      hid.dispose();
    }
  }

  void _handleCameraValue(String? raw) {
    final value = raw?.trim();
    if (!_cameraOpen || value == null || value.isEmpty || value.length > 1024) {
      return;
    }
    final now = _clock();
    final previousAt = _lastCameraValueAt;
    if (value == _lastCameraValue &&
        previousAt != null &&
        now - previousAt <= const Duration(milliseconds: 500)) {
      return;
    }
    _lastCameraValue = value;
    _lastCameraValueAt = now;
    _emit(value);
  }

  void _emit(String value) {
    if (!_disposed && !_scans.isClosed) _scans.add(value);
  }

  void _handleControllerFailure(CameraControllerFailure failure) {
    _cameraOpen = false;
    if (_disposed || _failures.isClosed) return;
    _failures.add(switch (failure) {
      CameraControllerFailure.permissionDenied => const AppFailure(
        kind: FailureKind.device,
        code: 'device.camera_permission',
        safeMessage: '未获得相机权限',
      ),
      CameraControllerFailure.unavailable => const AppFailure(
        kind: FailureKind.device,
        code: 'device.camera_unavailable',
        safeMessage: '相机扫码不可用',
      ),
    });
  }

  static MonotonicClock _stopwatchClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }
}

final class MobileScannerCameraControllerAdapter
    implements AndroidCameraControllerAdapter {
  MobileScannerCameraControllerAdapter({MobileScannerController? controller})
    : _controller = controller ?? MobileScannerController(autoStart: true);

  final MobileScannerController _controller;
  final StreamController<CameraControllerFailure> _failures =
      StreamController<CameraControllerFailure>.broadcast(sync: true);

  @override
  Stream<String?> get barcodes => _controller.barcodes.map(
    (capture) => capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull,
  );

  @override
  Stream<CameraControllerFailure> get failures => _failures.stream;

  @override
  Future<void> start() async {
    // MobileScanner attaches and starts this controller when the preview mounts.
  }

  @override
  Future<void> stop() => _controller.stop();

  @override
  Future<void> dispose() async {
    await _controller.dispose();
    await _failures.close();
  }

  @override
  Widget buildPreview() => MobileScanner(
    controller: _controller,
    errorBuilder: (context, error) {
      final permissionDenied =
          error.errorCode == MobileScannerErrorCode.permissionDenied;
      if (!_failures.isClosed) {
        _failures.add(
          permissionDenied
              ? CameraControllerFailure.permissionDenied
              : CameraControllerFailure.unavailable,
        );
      }
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            permissionDenied
                ? 'device.camera_permission'
                : 'device.camera_unavailable',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    },
  );
}
