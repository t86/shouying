import 'package:design_system/design_system.dart';
import 'package:device_bridge_android/device_bridge_android.dart';
import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  Widget subject(AndroidScannerService scanner) => ProviderScope(
    overrides: [
      scannerServiceProvider.overrideWithValue(scanner),
      printerServiceProvider.overrideWithValue(_NoopPrinter()),
    ],
    child: const MaterialApp(
      home: DeviceDiagnosticsScreen(
        appVersion: '1.0.0',
        platformLabel: 'Android',
      ),
    ),
  );

  testWidgets('mounted preview maps start permission denial without success', (
    tester,
  ) async {
    var sawMountedPreview = false;
    final camera = MobileScannerCameraControllerAdapter(
      startController: (_) {
        sawMountedPreview = find.byType(MobileScanner).evaluate().isNotEmpty;
        throw const MobileScannerException(
          errorCode: MobileScannerErrorCode.permissionDenied,
        );
      },
    );
    final scanner = AndroidScannerService(
      hidScanner: _NoopScanner(),
      cameraController: camera,
    );
    await tester.pumpWidget(subject(scanner));

    await tester.tap(find.byKey(DeviceDiagnosticsScreen.openCameraKey));
    await tester.pump();
    await tester.pump();

    expect(sawMountedPreview, isTrue);
    expect(find.text('device.camera_permission'), findsOneWidget);
    expect(find.text('相机已打开'), findsNothing);
    expect(find.byType(MobileScanner), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mounted preview awaits successful controller start', (
    tester,
  ) async {
    var sawMountedPreview = false;
    final camera = MobileScannerCameraControllerAdapter(
      startController: (_) async {
        sawMountedPreview = find.byType(MobileScanner).evaluate().isNotEmpty;
      },
    );
    final scanner = AndroidScannerService(
      hidScanner: _NoopScanner(),
      cameraController: camera,
    );
    await tester.pumpWidget(subject(scanner));

    await tester.tap(find.byKey(DeviceDiagnosticsScreen.openCameraKey));
    await tester.pump();
    await tester.pump();

    expect(sawMountedPreview, isTrue);
    expect(scanner.isCameraOpen, isTrue);
    expect(find.text('相机已打开'), findsOneWidget);
    expect(find.byType(MobileScanner), findsOneWidget);
    expect(find.byKey(DeviceDiagnosticsScreen.closeCameraKey), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

final class _NoopScanner implements ScannerService {
  @override
  ScannerCapabilities get capabilities => const ScannerCapabilities();

  @override
  Stream<String> get scans => const Stream<String>.empty();

  @override
  void start() {}

  @override
  void stop() {}
}

final class _NoopPrinter implements PrinterService {
  @override
  Future<Result<void>> printTestReceipt(
    TestReceipt receipt,
    PrinterTarget target,
  ) async => const Success<void>(null);
}
