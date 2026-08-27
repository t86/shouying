import 'dart:async';

import 'package:device_bridge_android/device_bridge_android.dart';
import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  late _FakeCameraController camera;
  late _FakeClock clock;
  late AndroidScannerService scanner;

  setUp(() {
    camera = _FakeCameraController();
    clock = _FakeClock();
    scanner = AndroidScannerService(
      hidScanner: _FakeHidScanner(),
      cameraController: camera,
      clock: clock.call,
    );
  });

  tearDown(() async => scanner.dispose());

  test('ignores empty values and suppresses a duplicate for 500ms', () async {
    final values = <String>[];
    scanner.scans.listen(values.add);

    expect((await scanner.openCamera()).failureOrNull, isNull);
    camera.emit(null);
    camera.emit('');
    camera.emit('INVENTORY_123');
    clock.advance(const Duration(milliseconds: 400));
    camera.emit('INVENTORY_123');
    clock.advance(const Duration(milliseconds: 101));
    camera.emit('INVENTORY_123');

    expect(values, <String>['INVENTORY_123', 'INVENTORY_123']);
  });

  test('permission denial maps to device.camera_permission', () async {
    camera.permissionDenied = true;

    final result = await scanner.openCamera();

    expect(result.failureOrNull?.code, 'device.camera_permission');
    expect(scanner.isCameraOpen, isFalse);
  });

  test('asynchronous controller denial maps to typed failure stream', () async {
    await scanner.openCamera();
    final failure = scanner.failures.first;

    camera.fail(CameraControllerFailure.permissionDenied);

    expect((await failure).code, 'device.camera_permission');
    expect(scanner.isCameraOpen, isFalse);
  });

  testWidgets('real adapter forwards MobileScanner permission errors', (
    tester,
  ) async {
    final adapter = MobileScannerCameraControllerAdapter();
    final permissionFailure = adapter.failures.first;
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
    );
    final preview = adapter.buildPreview() as MobileScanner;

    preview.errorBuilder!(
      tester.element(find.byType(SizedBox)),
      const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      ),
    );

    expect(await permissionFailure, CameraControllerFailure.permissionDenied);
    await adapter.dispose();
  });

  testWidgets('preview widget is isolated behind injected controller seam', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: scanner.buildCameraPreview(),
      ),
    );

    expect(find.byKey(_FakeCameraController.previewKey), findsOneWidget);
  });

  test('dispose stops controller and closes scan stream', () async {
    final done = Completer<void>();
    scanner.scans.listen(null, onDone: done.complete);
    await scanner.openCamera();

    await scanner.dispose();

    await done.future;
    expect(camera.stopped, isTrue);
    expect(camera.disposed, isTrue);
  });
}

final class _FakeClock {
  Duration value = Duration.zero;

  Duration call() => value;

  void advance(Duration duration) => value += duration;
}

final class _FakeHidScanner implements ScannerService {
  @override
  ScannerCapabilities get capabilities => const ScannerCapabilities();

  @override
  Stream<String> get scans => const Stream<String>.empty();

  @override
  void start() {}

  @override
  void stop() {}
}

final class _FakeCameraController implements AndroidCameraControllerAdapter {
  static const previewKey = Key('fake-camera-preview');

  final _barcodes = StreamController<String?>.broadcast(sync: true);
  final _failures = StreamController<CameraControllerFailure>.broadcast(
    sync: true,
  );
  bool permissionDenied = false;
  bool stopped = false;
  bool disposed = false;

  @override
  Stream<String?> get barcodes => _barcodes.stream;

  @override
  Stream<CameraControllerFailure> get failures => _failures.stream;

  void emit(String? value) => _barcodes.add(value);

  void fail(CameraControllerFailure failure) => _failures.add(failure);

  @override
  Widget buildPreview() => const SizedBox(key: previewKey);

  @override
  Future<void> start() async {
    if (permissionDenied) throw const CameraPermissionDenied();
  }

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _barcodes.close();
    await _failures.close();
  }
}
