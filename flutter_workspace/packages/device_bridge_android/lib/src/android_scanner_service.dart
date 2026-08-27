import 'dart:async';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

abstract interface class AndroidCameraControllerAdapter {
  Stream<String?> get barcodes;

  Future<void> start();

  Future<void> stop();

  Future<void> dispose();

  Widget buildPreview();
}

final class CameraPermissionDenied implements Exception {
  const CameraPermissionDenied();
}

final class CameraUnavailable implements Exception {
  const CameraUnavailable();
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
  }

  final ScannerService _hidScanner;
  final AndroidCameraControllerAdapter _cameraController;
  final MonotonicClock _clock;
  final StreamController<String> _scans = StreamController<String>.broadcast(
    sync: true,
  );
  late final StreamSubscription<String> _hidSubscription;
  late final StreamSubscription<String?> _cameraSubscription;
  bool _cameraOpen = false;
  bool _disposed = false;
  int _cameraGeneration = 0;
  int? _pendingGeneration;
  Future<Result<void>>? _pendingStart;
  Future<void>? _pendingStop;
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
      return _cameraUnavailable();
    }
    final stopping = _pendingStop;
    if (stopping != null) {
      await stopping;
      if (_disposed) return _cameraUnavailable();
    }
    if (_cameraOpen) return const Success<void>(null);
    final pending = _pendingStart;
    if (pending != null) {
      if (_pendingGeneration == _cameraGeneration) return pending;
      await pending;
      if (_disposed) return _cameraUnavailable();
      if (_cameraOpen) return const Success<void>(null);
    }
    final generation = ++_cameraGeneration;
    _pendingGeneration = generation;
    late final Future<Result<void>> operation;
    operation = _startCamera(generation).whenComplete(() {
      if (identical(_pendingStart, operation)) {
        _pendingStart = null;
        _pendingGeneration = null;
      }
    });
    _pendingStart = operation;
    return operation;
  }

  Future<Result<void>> _startCamera(int generation) async {
    try {
      await _cameraController.start();
      if (_disposed || generation != _cameraGeneration) {
        await _stopCameraController();
        return _cameraUnavailable();
      }
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
      return _cameraUnavailable();
    }
  }

  @override
  Future<void> closeCamera() async {
    _cameraGeneration += 1;
    _cameraOpen = false;
    _lastCameraValue = null;
    _lastCameraValueAt = null;
    await _stopCameraController();
  }

  Future<void> _stopCameraController() {
    final pending = _pendingStop;
    if (pending != null) return pending;
    late final Future<void> operation;
    operation = _stopControllerSafely().whenComplete(() {
      if (identical(_pendingStop, operation)) _pendingStop = null;
    });
    _pendingStop = operation;
    return operation;
  }

  Future<void> _stopControllerSafely() async {
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
    _cameraGeneration += 1;
    _cameraOpen = false;
    _hidScanner.stop();
    await _hidSubscription.cancel();
    await _cameraSubscription.cancel();
    await _stopCameraController();
    await _cameraController.dispose();
    await _scans.close();
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

  static MonotonicClock _stopwatchClock() {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  }

  static FailureResult<void> _cameraUnavailable() => const FailureResult<void>(
    AppFailure(
      kind: FailureKind.device,
      code: 'device.camera_unavailable',
      safeMessage: '相机扫码不可用',
    ),
  );
}

typedef MobileScannerStartController = Future<void> Function(
  MobileScannerController controller,
);

final class MobileScannerCameraControllerAdapter
    implements AndroidCameraControllerAdapter {
  MobileScannerCameraControllerAdapter({
    MobileScannerController? controller,
    MobileScannerStartController? startController,
  }) : _controller = controller ?? MobileScannerController(autoStart: false),
       _startController = startController ?? _startMobileScanner {
    if (_controller.autoStart) {
      throw ArgumentError('MobileScanner controller must use autoStart:false');
    }
  }

  final MobileScannerController _controller;
  final MobileScannerStartController _startController;

  @override
  Stream<String?> get barcodes => _controller.barcodes.map(
    (capture) => capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull,
  );

  @override
  Future<void> start() async {
    try {
      await _startController(_controller);
    } on MobileScannerException catch (error) {
      if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
        throw const CameraPermissionDenied();
      }
      throw const CameraUnavailable();
    }
  }

  @override
  Future<void> stop() => _controller.stop();

  @override
  Future<void> dispose() async {
    await _controller.dispose();
  }

  @override
  Widget buildPreview() => MobileScanner(
    controller: _controller,
    errorBuilder: _buildSafeCameraError,
  );

  static Future<void> _startMobileScanner(MobileScannerController controller) =>
      controller.start();

  static Widget _buildSafeCameraError(
    BuildContext context,
    MobileScannerException error,
  ) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: Text(
        error.errorCode == MobileScannerErrorCode.permissionDenied
            ? 'device.camera_permission'
            : 'device.camera_unavailable',
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}
