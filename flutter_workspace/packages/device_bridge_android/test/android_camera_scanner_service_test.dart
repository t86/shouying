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

  testWidgets('real adapter is manual-start and error builder is pure', (
    tester,
  ) async {
    final adapter = MobileScannerCameraControllerAdapter();
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
    );
    final preview = adapter.buildPreview() as MobileScanner;
    expect(preview.controller?.autoStart, isFalse);

    final placeholder = preview.errorBuilder!(
      tester.element(find.byType(SizedBox)),
      const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      ),
    );
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: placeholder),
    );

    expect(find.text('device.camera_permission'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await adapter.dispose();
  });

  test('real adapter translates start permission denial', () async {
    final adapter = MobileScannerCameraControllerAdapter(
      startController: (_) => throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      ),
    );

    expect(adapter.start(), throwsA(isA<CameraPermissionDenied>()));
    await adapter.dispose();
  });

  test('real adapter translates other start errors as unavailable', () async {
    final adapter = MobileScannerCameraControllerAdapter(
      startController: (_) => throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.genericError,
      ),
    );

    expect(adapter.start(), throwsA(isA<CameraUnavailable>()));
    await adapter.dispose();
  });

  test('camera becomes open only after controller start completes', () async {
    camera.startGate = Completer<void>();

    final opening = scanner.openCamera();
    expect(scanner.isCameraOpen, isFalse);
    camera.startGate!.complete();

    expect((await opening).failureOrNull, isNull);
    expect(scanner.isCameraOpen, isTrue);
  });

  test('closing during pending start prevents stale open state', () async {
    camera.startGate = Completer<void>();
    final opening = scanner.openCamera();

    await scanner.closeCamera();
    camera.startGate!.complete();
    final result = await opening;

    expect(result.failureOrNull?.code, 'device.camera_unavailable');
    expect(scanner.isCameraOpen, isFalse);
    expect(camera.stopped, isTrue);
  });

  test('duplicate open while pending starts controller only once', () async {
    camera.startGate = Completer<void>();

    final first = scanner.openCamera();
    final second = scanner.openCamera();
    camera.startGate!.complete();

    expect((await first).failureOrNull, isNull);
    expect((await second).failureOrNull, isNull);
    expect(camera.startCalls, 1);
  });

  test('dispose during pending start prevents stale open state', () async {
    camera.startGate = Completer<void>();
    final opening = scanner.openCamera();

    await scanner.dispose();
    camera.startGate!.complete();
    final result = await opening;

    expect(result.failureOrNull?.code, 'device.camera_unavailable');
    expect(scanner.isCameraOpen, isFalse);
    expect(camera.disposed, isTrue);
  });

  test('reopen waits for controller close to finish', () async {
    expect((await scanner.openCamera()).failureOrNull, isNull);
    camera.stopGate = Completer<void>();

    final closing = scanner.closeCamera();
    final reopening = scanner.openCamera();
    await Future<void>.delayed(Duration.zero);
    final startsBeforeStopCompleted = camera.startCalls;

    camera.stopGate!.complete();
    await closing;
    expect((await reopening).failureOrNull, isNull);
    expect(startsBeforeStopCompleted, 1);
    expect(camera.startCalls, 2);
    expect(scanner.isCameraOpen, isTrue);
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
  Completer<void>? startGate;
  Completer<void>? stopGate;
  bool permissionDenied = false;
  bool stopped = false;
  bool disposed = false;
  int startCalls = 0;

  @override
  Stream<String?> get barcodes => _barcodes.stream;

  void emit(String? value) => _barcodes.add(value);

  @override
  Widget buildPreview() => const SizedBox(key: previewKey);

  @override
  Future<void> start() async {
    startCalls += 1;
    if (permissionDenied) throw const CameraPermissionDenied();
    await startGate?.future;
  }

  @override
  Future<void> stop() async {
    stopped = true;
    await stopGate?.future;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _barcodes.close();
  }
}
