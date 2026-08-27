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
      paperWidth: ReceiptPaperWidth.mm58,
    );

    expect(receipt.timestamp, timestamp);
    expect(receipt.paperWidth, ReceiptPaperWidth.mm58);
    expect(receipt.successText, '打印测试成功');
    expect(receipt.qrPayload, 'diag_A1b2c3');
    expect(
      () => TestReceipt(
        appVersion: 'token=secret',
        platform: 'Windows',
        timestamp: timestamp,
        diagnosticId: 'diag_A1b2c3',
        paperWidth: ReceiptPaperWidth.mm58,
      ),
      throwsArgumentError,
    );
    expect(
      () => TestReceipt(
        appVersion: '1.0.0',
        platform: 'Windows',
        timestamp: timestamp,
        diagnosticId: 'https://payment.example/abc',
        paperWidth: ReceiptPaperWidth.mm58,
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
      paperWidth: ReceiptPaperWidth.mm80,
    );
    final result = await printer.printTestReceipt(
      receipt,
      const SystemPrinterTarget(paperWidth: ReceiptPaperWidth.mm80),
    );
    expect(result, isA<Success<void>>());
  });

  test('shared render model owns canonical receipt semantics', () {
    final receipt = TestReceipt(
      appVersion: '1.2.3+4',
      platform: 'Android',
      timestamp: DateTime.utc(2026, 8, 27, 10, 20),
      diagnosticId: 'diagnostic-model-123',
      paperWidth: ReceiptPaperWidth.mm80,
    );

    final model = TestReceiptRenderModel.fromReceipt(receipt);

    expect(model.successText, '打印测试成功');
    expect(model.paperWidth, ReceiptPaperWidth.mm80);
    expect(model.paperLabel, '80mm');
    expect(model.timestampText, '2026-08-27T10:20:00.000Z');
    expect(model.qrPayload, 'diagnostic-model-123');
    expect(model.lines, contains('打印测试成功'));
    expect(model.lines, contains('Paper: 80mm'));
    expect(model.lines, contains('Time: 2026-08-27T10:20:00.000Z'));
  });

  test('target width mismatch maps to typed invalid target failure', () {
    final receipt = TestReceipt(
      appVersion: '1.0.0',
      platform: 'test',
      timestamp: DateTime.utc(2026),
      diagnosticId: 'diagnostic-123',
      paperWidth: ReceiptPaperWidth.mm58,
    );

    expect(
      validatePrinterTargetForReceipt(
        receipt,
        const SystemPrinterTarget(paperWidth: ReceiptPaperWidth.mm58),
      ),
      isNull,
    );
    expect(
      validatePrinterTargetForReceipt(
        receipt,
        LanEscPosTarget(
          host: 'printer.local',
          paperWidth: ReceiptPaperWidth.mm80,
        ),
      )?.code,
      'device.printer_target_invalid',
    );
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
