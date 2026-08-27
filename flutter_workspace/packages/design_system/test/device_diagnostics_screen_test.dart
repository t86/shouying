import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  late _FakeCameraScanner scanner;
  late _FakePrinter printer;
  late _SessionSentinel sentinel;

  setUp(() {
    scanner = _FakeCameraScanner();
    sentinel = _SessionSentinel();
    printer = _FakePrinter(sentinel);
  });

  Widget subject() => ProviderScope(
    overrides: [
      scannerServiceProvider.overrideWithValue(scanner),
      printerServiceProvider.overrideWithValue(printer),
    ],
    child: MaterialApp(
      home: DeviceDiagnosticsScreen(
        appVersion: '1.0.0+1',
        platformLabel: 'Android',
        clock: () => DateTime.utc(2026, 8, 27),
        diagnosticIdFactory: () => 'diagnostic-ui-123',
      ),
    ),
  );

  testWidgets('starts scanner and displays only a masked last value', (
    tester,
  ) async {
    const rawScan = 'INVENTORY-998877';
    await tester.pumpWidget(subject());

    scanner.emit(rawScan);
    await tester.pump();

    expect(scanner.started, isTrue);
    expect(find.text(rawScan), findsNothing);
    expect(find.text('IN${'*' * 12}77'), findsOneWidget);
    expect(find.text('已就绪'), findsOneWidget);

    scanner.emit('ABC');
    await tester.pump();
    expect(find.text('ABC'), findsNothing);
    expect(find.text('***'), findsOneWidget);
  });

  testWidgets('camera controls follow capability and surface typed denial', (
    tester,
  ) async {
    scanner.permissionDenied = true;
    await tester.pumpWidget(subject());

    expect(find.byKey(DeviceDiagnosticsScreen.openCameraKey), findsOneWidget);
    await tester.tap(find.byKey(DeviceDiagnosticsScreen.openCameraKey));
    await tester.pump();
    await tester.pump();

    expect(scanner.openCalledAfterPreviewMount, isTrue);
    expect(find.text('device.camera_permission'), findsOneWidget);
    expect(find.text('未获得相机权限'), findsOneWidget);
    expect(find.text('相机已打开'), findsNothing);
    expect(find.byKey(_FakeCameraScanner.previewKey), findsNothing);

    scanner.permissionDenied = false;
    await tester.tap(find.byKey(DeviceDiagnosticsScreen.openCameraKey));
    await tester.pumpAndSettle();
    expect(scanner.openCalledAfterPreviewMount, isTrue);
    expect(find.byKey(_FakeCameraScanner.previewKey), findsOneWidget);
    expect(find.byKey(DeviceDiagnosticsScreen.closeCameraKey), findsOneWidget);
  });

  testWidgets('LAN inputs create validated target and print safe receipt', (
    tester,
  ) async {
    await tester.pumpWidget(subject());

    await tester.tap(find.byKey(DeviceDiagnosticsScreen.targetSelectorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('局域网 ESC/POS').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(DeviceDiagnosticsScreen.lanHostKey),
      '192.0.2.10',
    );
    await tester.enterText(
      find.byKey(DeviceDiagnosticsScreen.lanPortKey),
      '9100',
    );
    await tester.ensureVisible(
      find.byKey(DeviceDiagnosticsScreen.paperSelectorKey),
    );
    await tester.tap(find.byKey(DeviceDiagnosticsScreen.paperSelectorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('80 mm').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(DeviceDiagnosticsScreen.printButtonKey),
    );
    await tester.tap(find.byKey(DeviceDiagnosticsScreen.printButtonKey));
    await tester.pump();

    expect(printer.calls, 1);
    expect(printer.target, isA<LanEscPosTarget>());
    final target = printer.target! as LanEscPosTarget;
    expect(target.host, '192.0.2.10');
    expect(target.port, 9100);
    expect(target.paperWidth, ReceiptPaperWidth.mm80);
    expect(printer.receipt?.diagnosticId, 'diagnostic-ui-123');
    expect(printer.receipt?.paperWidth, ReceiptPaperWidth.mm80);
    expect(printer.receipt?.successText, '打印测试成功');
    expect(
      printer.receipt?.timestamp.toUtc().toIso8601String(),
      '2026-08-27T00:00:00.000Z',
    );
    expect(find.text('打印测试成功'), findsOneWidget);
    expect(sentinel.modelState, 'unchanged');
    expect(sentinel.sessionApiCalls, 0);
  });

  testWidgets(
    'typed print failure leaves unrelated session sentinel unchanged',
    (tester) async {
      printer.result = const FailureResult<void>(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.system_printer_unavailable',
          safeMessage: '系统打印不可用',
        ),
      );
      await tester.pumpWidget(subject());
      await tester.ensureVisible(
        find.byKey(DeviceDiagnosticsScreen.printButtonKey),
      );

      await tester.tap(find.byKey(DeviceDiagnosticsScreen.printButtonKey));
      await tester.pump();

      expect(find.text('device.system_printer_unavailable'), findsOneWidget);
      expect(find.text('系统打印不可用'), findsOneWidget);
      expect(find.text('打印失败'), findsOneWidget);
      expect(printer.calls, 1);
      expect(printer.receipt?.paperWidth, ReceiptPaperWidth.mm58);
      expect(sentinel.modelState, 'unchanged');
      expect(sentinel.sessionApiCalls, 0);
    },
  );

  testWidgets('invalid LAN input does not call printer', (tester) async {
    await tester.pumpWidget(subject());
    await tester.tap(find.byKey(DeviceDiagnosticsScreen.targetSelectorKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('局域网 ESC/POS').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(DeviceDiagnosticsScreen.lanHostKey),
      'bad host',
    );
    await tester.enterText(
      find.byKey(DeviceDiagnosticsScreen.lanPortKey),
      '70000',
    );

    await tester.ensureVisible(
      find.byKey(DeviceDiagnosticsScreen.printButtonKey),
    );
    await tester.tap(find.byKey(DeviceDiagnosticsScreen.printButtonKey));
    await tester.pump();

    expect(printer.calls, 0);
    expect(find.text('device.printer_target_invalid'), findsOneWidget);
  });

  testWidgets('layout responds at device diagnostics breakpoint', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 900));
    await tester.pumpWidget(subject());
    expect(find.byKey(DeviceDiagnosticsScreen.wideLayoutKey), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(500, 900));
    await tester.pumpWidget(subject());
    expect(find.byKey(DeviceDiagnosticsScreen.narrowLayoutKey), findsOneWidget);
  });
}

final class _SessionSentinel {
  String modelState = 'unchanged';
  int sessionApiCalls = 0;
}

final class _FakePrinter implements PrinterService {
  _FakePrinter(this.sentinel);

  final _SessionSentinel sentinel;
  int calls = 0;
  TestReceipt? receipt;
  PrinterTarget? target;
  Result<void> result = const Success<void>(null);

  @override
  Future<Result<void>> printTestReceipt(
    TestReceipt receipt,
    PrinterTarget target,
  ) async {
    if (sentinel.modelState != 'unchanged' || sentinel.sessionApiCalls != 0) {
      throw StateError('unrelated session sentinel changed before printing');
    }
    calls += 1;
    this.receipt = receipt;
    this.target = target;
    return result;
  }
}

final class _FakeCameraScanner implements CameraScannerService {
  static const previewKey = Key('fake-diagnostics-camera');

  final _scans = StreamController<String>.broadcast(sync: true);
  bool started = false;
  bool permissionDenied = false;
  bool _open = false;
  bool previewMounted = false;
  bool openCalledAfterPreviewMount = false;

  void emit(String value) => _scans.add(value);

  @override
  ScannerCapabilities get capabilities =>
      const ScannerCapabilities(camera: true);

  @override
  bool get isCameraOpen => _open;

  @override
  Stream<String> get scans => _scans.stream;

  @override
  Widget buildCameraPreview() => _PreviewMountProbe(
    key: previewKey,
    onMounted: () => previewMounted = true,
  );

  @override
  Future<void> closeCamera() async => _open = false;

  @override
  Future<Result<void>> openCamera() async {
    openCalledAfterPreviewMount = previewMounted;
    if (permissionDenied) {
      return const FailureResult<void>(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.camera_permission',
          safeMessage: '未获得相机权限',
        ),
      );
    }
    _open = true;
    return const Success<void>(null);
  }

  @override
  void start() => started = true;

  @override
  void stop() => started = false;
}

final class _PreviewMountProbe extends StatefulWidget {
  const _PreviewMountProbe({required this.onMounted, super.key});

  final VoidCallback onMounted;

  @override
  State<_PreviewMountProbe> createState() => _PreviewMountProbeState();
}

final class _PreviewMountProbeState extends State<_PreviewMountProbe> {
  @override
  void initState() {
    super.initState();
    widget.onMounted();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(height: 100);
}
