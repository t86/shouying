import 'package:device_bridge_platform_interface/src/test_receipt.dart';
import 'package:foundation/foundation.dart';

sealed class PrinterTarget {
  const PrinterTarget({required this.paperWidth});

  final ReceiptPaperWidth paperWidth;
}

final class SystemPrinterTarget extends PrinterTarget {
  const SystemPrinterTarget({required super.paperWidth});
}

final class LanEscPosTarget extends PrinterTarget {
  LanEscPosTarget({
    required String host,
    this.port = 9100,
    required super.paperWidth,
  }) : host = _validateHost(host) {
    if (port < 1 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'must be between 1 and 65535');
    }
  }

  final String host;
  final int port;

  static String _validateHost(String value) {
    final host = value.trim();
    if (host != value || host.isEmpty || host.length > 253) {
      throw ArgumentError.value(value, 'host', 'must be a bounded host name');
    }
    final isIpv6 =
        RegExp(r'^[0-9a-fA-F:]+$').hasMatch(host) && host.contains(':');
    final isDnsOrIpv4 = host
        .split('.')
        .every(
          (label) =>
              label.isNotEmpty &&
              label.length <= 63 &&
              RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?$')
                  .hasMatch(label),
        );
    if (!isIpv6 && !isDnsOrIpv4) {
      throw ArgumentError.value(value, 'host', 'must be an IP address or host');
    }
    return host;
  }
}

abstract interface class PrinterService {
  Future<Result<void>> printTestReceipt(
    TestReceipt receipt,
    PrinterTarget target,
  );
}

AppFailure? validatePrinterTargetForReceipt(
  TestReceipt receipt,
  PrinterTarget target,
) => receipt.paperWidth == target.paperWidth
    ? null
    : const AppFailure(
        kind: FailureKind.device,
        code: 'device.printer_target_invalid',
        safeMessage: '小票纸宽与打印目标不一致',
      );
