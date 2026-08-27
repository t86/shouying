import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:device_bridge_windows/device_bridge_windows.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final receipt = TestReceipt(
    appVersion: '1.0.0+1',
    platform: 'Windows',
    timestamp: DateTime.utc(2026, 8, 27, 10, 20),
    diagnosticId: 'diagnostic_A1b2c3',
  );

  test(
    'system printing builds selected 58/80mm PDF and calls layoutPdf',
    () async {
      final widths = <ReceiptPaperWidth>[];
      final documents = <Uint8List>[];
      final printer = WindowsPrinterService(
        systemPrint: ({required bytes, required paperWidth}) async {
          widths.add(paperWidth);
          documents.add(bytes);
          return true;
        },
      );

      for (final width in ReceiptPaperWidth.values) {
        final result = await printer.printTestReceipt(
          receipt,
          SystemPrinterTarget(paperWidth: width),
        );
        expect(result, isA<Success<void>>());
      }

      expect(widths, ReceiptPaperWidth.values);
      expect(documents, hasLength(2));
      expect(
        documents.every(
          (bytes) => ascii.decode(bytes.take(4).toList()) == '%PDF',
        ),
        isTrue,
      );
      expect(documents[0], isNot(equals(documents[1])));
    },
  );

  test('LAN printing sends init, content, QR, cut and closes socket', () async {
    final ticket = await buildWindowsEscPosTestReceipt(
      receipt,
      ReceiptPaperWidth.mm58,
    );
    expect(ticket, isNotEmpty);
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
    final printer = WindowsPrinterService(
      connectTimeout: const Duration(seconds: 1),
    );

    final result = await printer.printTestReceipt(
      receipt,
      LanEscPosTarget(
        host: InternetAddress.loopbackIPv4.address,
        port: server.port,
        paperWidth: ReceiptPaperWidth.mm58,
      ),
    );
    expect(result, isA<Success<void>>());
    final bytes = await received.future.timeout(const Duration(seconds: 2));
    await peerClosed.future.timeout(const Duration(seconds: 2));
    await server.close();

    expect(bytes.take(2), <int>[0x1b, 0x40]);
    expect(_contains(bytes, <int>[0x1c, 0x26]), isTrue);
    expect(_contains(bytes, gbk_bytes.encode('打印测试成功')), isTrue);
    expect(_contains(bytes, <int>[0x1d, 0x28, 0x6b]), isTrue);
    expect(_contains(bytes, <int>[0x1d, 0x56]), isTrue);
  });

  test('connection refusal maps to typed unavailable failure', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    await server.close();
    final printer = WindowsPrinterService(
      connectTimeout: const Duration(milliseconds: 100),
    );

    final result = await printer.printTestReceipt(
      receipt,
      LanEscPosTarget(
        host: InternetAddress.loopbackIPv4.address,
        port: port,
        paperWidth: ReceiptPaperWidth.mm80,
      ),
    );

    expect(result, isA<FailureResult<void>>());
    expect(result.failureOrNull?.code, 'device.lan_printer_unavailable');
  });

  test('connection timeout maps to typed unavailable failure', () async {
    final printer = WindowsPrinterService(
      socketConnector: (_, _, _) => throw TimeoutException('not exposed'),
    );

    final result = await printer.printTestReceipt(
      receipt,
      LanEscPosTarget(
        host: 'printer.local',
        paperWidth: ReceiptPaperWidth.mm80,
      ),
    );

    expect(result.failureOrNull?.code, 'device.lan_printer_unavailable');
    expect(result.failureOrNull?.safeMessage, '无法连接局域网打印机');
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
