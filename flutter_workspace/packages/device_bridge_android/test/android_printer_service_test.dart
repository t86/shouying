import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_bridge_android/device_bridge_android.dart';
import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  TestReceipt receipt(ReceiptPaperWidth paperWidth) => TestReceipt(
    appVersion: '1.0.0+1',
    platform: 'Android',
    timestamp: DateTime.utc(2026, 8, 27),
    diagnosticId: 'diagnostic-android-123',
    paperWidth: paperWidth,
  );

  test('builds PDF and delegates system printing', () async {
    var called = false;
    final printer = AndroidPrinterService(
      systemPrint:
          ({required bytes, required paperWidth, required model}) async {
            called = true;
            expect(ascii.decode(bytes.take(4).toList()), '%PDF');
            expect(paperWidth, ReceiptPaperWidth.mm58);
            expect(model.paperWidth, ReceiptPaperWidth.mm58);
            expect(model.successText, '打印测试成功');
            expect(model.qrPayload, 'diagnostic-android-123');
            expect(model.timestampText, '2026-08-27T00:00:00.000Z');
            return true;
          },
    );

    final result = await printer.printTestReceipt(
      receipt(ReceiptPaperWidth.mm58),
      const SystemPrinterTarget(paperWidth: ReceiptPaperWidth.mm58),
    );

    expect(called, isTrue);
    expect(result, isA<Success<void>>());
  });

  test('LAN adapter sends ESC/POS bytes to loopback and closes', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final received = Completer<List<int>>();
    final peerClosed = Completer<void>();
    server.listen((socket) {
      final bytes = <int>[];
      socket.listen((chunk) {
        bytes.addAll(chunk);
        if (!received.isCompleted && _contains(bytes, <int>[0x1d, 0x56])) {
          received.complete(List<int>.unmodifiable(bytes));
        }
      }, onDone: peerClosed.complete);
    });
    final printer = AndroidPrinterService();

    final result = await printer.printTestReceipt(
      receipt(ReceiptPaperWidth.mm80),
      LanEscPosTarget(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        paperWidth: ReceiptPaperWidth.mm80,
      ),
    );
    final bytes = await received.future.timeout(const Duration(seconds: 2));
    await peerClosed.future.timeout(const Duration(seconds: 2));
    await server.close();

    expect(result, isA<Success<void>>());
    expect(bytes.take(2), <int>[0x1b, 0x40]);
    expect(_contains(bytes, <int>[0x1c, 0x26]), isTrue);
    expect(_contains(bytes, gbk_bytes.encode('打印测试成功')), isTrue);
    expect(_contains(bytes, <int>[0x1d, 0x28, 0x6b]), isTrue);
    expect(_contains(bytes, <int>[0x1d, 0x56]), isTrue);
  });

  test('timeout is a typed LAN failure', () async {
    final printer = AndroidPrinterService(
      socketConnector: (_, _, _) => throw TimeoutException('hidden'),
    );

    final result = await printer.printTestReceipt(
      receipt(ReceiptPaperWidth.mm58),
      LanEscPosTarget(
        host: 'printer.local',
        paperWidth: ReceiptPaperWidth.mm58,
      ),
    );

    expect(result.failureOrNull?.code, 'device.lan_printer_unavailable');
  });

  test('paper mismatch is a typed failure before system printing', () async {
    var called = false;
    final printer = AndroidPrinterService(
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

bool _contains(List<int> bytes, List<int> needle) {
  for (var offset = 0; offset <= bytes.length - needle.length; offset += 1) {
    var matches = true;
    for (var index = 0; index < needle.length; index += 1) {
      if (bytes[offset + index] != needle[index]) {
        matches = false;
        break;
      }
    }
    if (matches) return true;
  }
  return false;
}
