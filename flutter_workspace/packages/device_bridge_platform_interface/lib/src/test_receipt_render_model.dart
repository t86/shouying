import 'package:device_bridge_platform_interface/src/test_receipt.dart';

final class TestReceiptRenderModel {
  TestReceiptRenderModel._({
    required this.successText,
    required this.paperWidth,
    required this.paperLabel,
    required this.appVersion,
    required this.platform,
    required this.timestampText,
    required this.qrPayload,
    required this.lines,
  });

  factory TestReceiptRenderModel.fromReceipt(TestReceipt receipt) {
    final paperLabel = switch (receipt.paperWidth) {
      ReceiptPaperWidth.mm58 => '58mm',
      ReceiptPaperWidth.mm80 => '80mm',
    };
    final timestampText = receipt.timestamp.toUtc().toIso8601String();
    return TestReceiptRenderModel._(
      successText: receipt.successText,
      paperWidth: receipt.paperWidth,
      paperLabel: paperLabel,
      appVersion: receipt.appVersion,
      platform: receipt.platform,
      timestampText: timestampText,
      qrPayload: receipt.qrPayload,
      lines: List<String>.unmodifiable(<String>[
        receipt.successText,
        'Paper: $paperLabel',
        'App: ${receipt.appVersion}',
        'Platform: ${receipt.platform}',
        'Time: $timestampText',
      ]),
    );
  }

  final String successText;
  final ReceiptPaperWidth paperWidth;
  final String paperLabel;
  final String appVersion;
  final String platform;
  final String timestampText;
  final String qrPayload;
  final List<String> lines;
}
