import 'dart:typed_data';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:device_bridge_web/device_bridge_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  final receipt = TestReceipt(
    appVersion: '1.0.0+1',
    platform: 'Web',
    timestamp: DateTime.utc(2026, 8, 27),
    diagnosticId: 'diagnostic-web-123',
  );

  test('system target uses browser/system layout printing', () async {
    Uint8List? document;
    final printer = WebPrinterService(
      systemPrint: ({required bytes, required paperWidth}) async {
        document = bytes;
        return true;
      },
    );

    final result = await printer.printTestReceipt(
      receipt,
      const SystemPrinterTarget(paperWidth: ReceiptPaperWidth.mm80),
    );

    expect(result, isA<Success<void>>());
    expect(document, isNotNull);
  });

  test('LAN target is unsupported without importing dart:io', () async {
    final printer = WebPrinterService();

    final result = await printer.printTestReceipt(
      receipt,
      LanEscPosTarget(
        host: 'printer.local',
        paperWidth: ReceiptPaperWidth.mm58,
      ),
    );

    expect(result.failureOrNull?.code, 'device.target_unsupported');
  });
}
