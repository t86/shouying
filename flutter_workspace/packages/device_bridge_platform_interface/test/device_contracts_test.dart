import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('printer targets validate host, port, and paper width', () {
    const system = SystemPrinterTarget(paperWidth: ReceiptPaperWidth.mm58);
    expect(system.paperWidth, ReceiptPaperWidth.mm58);

    final lan = LanEscPosTarget(
      host: '192.0.2.10',
      paperWidth: ReceiptPaperWidth.mm80,
    );
    expect(lan.port, 9100);
    expect(
      () =>
          LanEscPosTarget(host: 'bad host', paperWidth: ReceiptPaperWidth.mm58),
      throwsArgumentError,
    );
    expect(
      () => LanEscPosTarget(
        host: 'printer.local',
        port: 0,
        paperWidth: ReceiptPaperWidth.mm58,
      ),
      throwsArgumentError,
    );
  });

  test('test receipt accepts only bounded diagnostic data', () {
    final timestamp = DateTime.utc(2026, 8, 27, 9, 30);
    final receipt = TestReceipt(
      appVersion: '1.0.0+1',
      platform: 'Windows',
      timestamp: timestamp,
      diagnosticId: 'diag_A1b2c3',
    );

    expect(receipt.timestamp, timestamp);
    expect(receipt.qrPayload, 'diag_A1b2c3');
    expect(
      () => TestReceipt(
        appVersion: 'token=secret',
        platform: 'Windows',
        timestamp: timestamp,
        diagnosticId: 'diag_A1b2c3',
      ),
      throwsArgumentError,
    );
    expect(
      () => TestReceipt(
        appVersion: '1.0.0',
        platform: 'Windows',
        timestamp: timestamp,
        diagnosticId: 'https://payment.example/abc',
      ),
      throwsArgumentError,
    );
  });

  test('scanner and printer fakes satisfy the public contracts', () async {
    final scanner = _FakeScanner();
    final printer = _FakePrinter();

    scanner.start();
    expect(scanner.isStarted, isTrue);
    scanner.stop();
    expect(scanner.isStarted, isFalse);

    final receipt = TestReceipt(
      appVersion: '1.0.0',
      platform: 'test',
      timestamp: DateTime.utc(2026),
      diagnosticId: 'diagnostic-123',
    );
    final result = await printer.printTestReceipt(
      receipt,
      const SystemPrinterTarget(paperWidth: ReceiptPaperWidth.mm80),
    );
    expect(result, isA<Success<void>>());
  });
}

final class _FakeScanner implements ScannerService {
  bool isStarted = false;

  @override
  ScannerCapabilities get capabilities => const ScannerCapabilities();

  @override
  Stream<String> get scans => const Stream<String>.empty();

  @override
  void start() => isStarted = true;

  @override
  void stop() => isStarted = false;
}

final class _FakePrinter implements PrinterService {
  @override
  Future<Result<void>> printTestReceipt(
    TestReceipt receipt,
    PrinterTarget target,
  ) async => const Success<void>(null);
}
