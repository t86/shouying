import 'dart:async';
import 'package:design_system/design_system.dart';
import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('HID subscribes before start and only returns first trimmed code', (tester) async {
    final scanner = FakeScanner()..initial = '  synthetic-first  ';
    addTearDown(scanner.controller.close);
    final harness = await open(tester, scanner);
    await tester.pumpAndSettle();
    scanner.controller.add('synthetic-second');
    await tester.pumpAndSettle();
    expect(harness.results, ['synthetic-first']);
    expect(scanner.starts, 1); expect(scanner.stops, 1);
    expect(scanner.cancels, 1);
    expect(find.textContaining('synthetic-first'), findsNothing);
  });
  testWidgets('invalid codes are not echoed or returned and next valid scan works', (tester) async {
    final scanner = FakeScanner(); addTearDown(scanner.controller.close);
    final harness = await open(tester, scanner);
    await tester.pumpAndSettle();
    for(final value in ['', 'inside\ncontrol', 'x' * 1025]) scanner.controller.add(value);
    await tester.pumpAndSettle();
    expect(harness.results, isEmpty);
    expect(find.textContaining('inside'), findsNothing);
    scanner.controller.add('vendor-neutral:value/123');
    await tester.pumpAndSettle();
    expect(harness.results, ['vendor-neutral:value/123']);
  });
  testWidgets('revoked canScan aborts accepting codes and shuts scanner down', (tester) async {
    var allowed = true;
    final scanner = FakeScanner(); addTearDown(scanner.controller.close);
    final harness = await open(tester, scanner, canScan: () => allowed);
    await tester.pumpAndSettle();
    allowed = false; scanner.controller.add('private-synthetic');
    await tester.pumpAndSettle();
    expect(harness.results.whereType<String>(), isEmpty);
    expect(scanner.stops, 1);
    expect(find.textContaining('private-synthetic'), findsNothing);
  });
  testWidgets('camera mounts preview before open and permission failure is safe', (tester) async {
    final scanner = FakeCamera()..answer = const FailureResult(AppFailure(
      kind: FailureKind.device, code: 'device.camera_permission', safeMessage: 'PRIVATE-ERROR'));
    addTearDown(scanner.controller.close);
    await open(tester, scanner);
    await tester.pumpAndSettle();
    expect(scanner.opens, 1); expect(scanner.previewWasMounted, isTrue);
    expect(find.textContaining('相机权限'), findsOneWidget);
    expect(find.textContaining('PRIVATE-ERROR'), findsNothing);
    expect(scanner.starts, 1); // HID remains a usable fallback.
  });
  testWidgets('pop invalidates immediately and late camera open is closed', (tester) async {
    final scanner = FakeCamera()..pending = Completer<Result<void>>();
    addTearDown(scanner.controller.close);
    final harness = await open(tester, scanner);
    await tester.pump(); await tester.pump();
    expect(scanner.opens, 1);
    harness.navigator.currentState!.pop();
    scanner.controller.add('during-return-animation');
    await tester.pump();
    expect(scanner.stops, 1);
    scanner.pending!.complete(const Success(null));
    await tester.pumpAndSettle();
    expect(harness.results, [null]);
    expect(scanner.cameraOpen, isFalse); expect(scanner.closes, greaterThanOrEqualTo(2));
    expect(scanner.cancels, 1);
  });
  testWidgets('covered scan route cannot consume codes and stream errors reveal nothing', (tester) async {
    final scanner = FakeScanner(); addTearDown(scanner.controller.close);
    final harness = await open(tester, scanner); await tester.pumpAndSettle();
    unawaited(harness.navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('other')))));
    await tester.pump();
    scanner.controller.add('covered-private');
    await tester.pumpAndSettle();
    expect(harness.results, isEmpty); expect(scanner.stops, 1);
    harness.navigator.currentState!.pop(); await tester.pumpAndSettle();
    expect(find.textContaining('covered-private'), findsNothing);
  });
}

Future<({GlobalKey<NavigatorState> navigator, List<String?> results})> open(
  WidgetTester tester, ScannerService scanner, {bool Function()? canScan}) async {
  final navigator = GlobalKey<NavigatorState>(), results = <String?>[];
  await tester.pumpWidget(MaterialApp(navigatorKey: navigator, home: const Scaffold()));
  unawaited(navigator.currentState!.push<String>(MaterialPageRoute<String>(
    builder: (_) => PaymentCodeScanScreen(scanner: scanner, canScan: canScan ?? () => true),
  )).then(results.add));
  return (navigator: navigator, results: results);
}

class FakeScanner implements ScannerService {
  FakeScanner() { controller = StreamController<String>.broadcast(sync: true, onCancel: () => cancels++); }
  late final StreamController<String> controller;
  int starts = 0, stops = 0, cancels = 0;
  String? initial;
  @override Stream<String> get scans => controller.stream;
  @override ScannerCapabilities get capabilities => const ScannerCapabilities(hid: true);
  @override void start() { starts++; if(initial != null) controller.add(initial!); }
  @override void stop() { stops++; }
}
class FakeCamera extends FakeScanner implements CameraScannerService {
  final preview = GlobalKey();
  int opens = 0, closes = 0;
  bool cameraOpen = false, previewWasMounted = false;
  Completer<Result<void>>? pending;
  Result<void> answer = const Success(null);
  @override ScannerCapabilities get capabilities => const ScannerCapabilities(hid: true, camera: true);
  @override bool get isCameraOpen => cameraOpen;
  @override Widget buildCameraPreview() => SizedBox(key: preview);
  @override Future<Result<void>> openCamera() async {
    opens++; previewWasMounted = preview.currentContext != null;
    final result = pending == null ? answer : await pending!.future;
    cameraOpen = result.failureOrNull == null; return result;
  }
  @override Future<void> closeCamera() async { closes++; cameraOpen = false; }
}
