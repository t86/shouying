import 'dart:typed_data';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:device_bridge_web/device_bridge_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  TestReceipt receipt(ReceiptPaperWidth paperWidth) => TestReceipt(
    appVersion: '1.0.0+1',
    platform: 'Web',
    timestamp: DateTime.utc(2026, 8, 27),
    diagnosticId: 'diagnostic-web-123',
    paperWidth: paperWidth,
  );

  test('system target uses browser/system layout printing', () async {
    Uint8List? document;
    final printer = WebPrinterService(
      systemPrint:
          ({required bytes, required paperWidth, required model}) async {
            document = bytes;
            expect(model.paperWidth, ReceiptPaperWidth.mm80);
            expect(model.successText, '打印测试成功');
            expect(model.qrPayload, 'diagnostic-web-123');
            expect(model.timestampText, '2026-08-27T00:00:00.000Z');
            return true;
          },
    );

    final result = await printer.printTestReceipt(
      receipt(ReceiptPaperWidth.mm80),
      const SystemPrinterTarget(paperWidth: ReceiptPaperWidth.mm80),
    );

    expect(result, isA<Success<void>>());
    expect(document, isNotNull);
  });

  test('LAN target is unsupported without importing dart:io', () async {
    final printer = WebPrinterService();

    final result = await printer.printTestReceipt(
      receipt(ReceiptPaperWidth.mm58),
      LanEscPosTarget(
        host: 'printer.local',
        paperWidth: ReceiptPaperWidth.mm58,
      ),
    );

    expect(result.failureOrNull?.code, 'device.target_unsupported');
  });

  test('paper mismatch is rejected before browser printing', () async {
    var called = false;
    final printer = WebPrinterService(
      systemPrint:
          ({required bytes, required paperWidth, required model}) async {
            called = true;
            return true;
          },
    );

    final result = await printer.printTestReceipt(
      receipt(ReceiptPaperWidth.mm58),
      const SystemPrinterTarget(paperWidth: ReceiptPaperWidth.mm80),
    );

    expect(result.failureOrNull?.code, 'device.printer_target_invalid');
    expect(called, isFalse);
  });
}
