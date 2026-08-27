import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:foundation/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

typedef AndroidSystemPrint = Future<bool> Function({
  required Uint8List bytes,
  required ReceiptPaperWidth paperWidth,
});

typedef AndroidSocketConnector = Future<Socket> Function(
  String host,
  int port,
  Duration timeout,
);

final class AndroidPrinterService implements PrinterService {
  AndroidPrinterService({
    AndroidSystemPrint? systemPrint,
    AndroidSocketConnector? socketConnector,
    this.connectTimeout = const Duration(seconds: 3),
  }) : _systemPrint = systemPrint ?? _layoutPdf,
       _socketConnector = socketConnector ?? _connectSocket;

  final AndroidSystemPrint _systemPrint;
  final AndroidSocketConnector _socketConnector;
  final Duration connectTimeout;

  @override
  Future<Result<void>> printTestReceipt(
    TestReceipt receipt,
    PrinterTarget target,
  ) async {
    if (connectTimeout <= Duration.zero ||
        connectTimeout > const Duration(seconds: 10)) {
      return const FailureResult<void>(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.lan_printer_unavailable',
          safeMessage: '无法连接局域网打印机',
        ),
      );
    }
    switch (target) {
      case SystemPrinterTarget():
        return _printSystem(receipt, target.paperWidth);
      case LanEscPosTarget():
        return _printLan(receipt, target);
    }
  }

  Future<Result<void>> _printSystem(
    TestReceipt receipt,
    ReceiptPaperWidth paperWidth,
  ) async {
    try {
      final bytes = await buildAndroidTestReceiptPdf(receipt, paperWidth);
      if (await _systemPrint(bytes: bytes, paperWidth: paperWidth)) {
        return const Success<void>(null);
      }
    } on Object {
      // Platform exceptions are mapped to a fixed safe failure.
    }
    return const FailureResult<void>(
      AppFailure(
        kind: FailureKind.device,
        code: 'device.system_printer_unavailable',
        safeMessage: '系统打印不可用',
      ),
    );
  }

  Future<Result<void>> _printLan(
    TestReceipt receipt,
    LanEscPosTarget target,
  ) async {
    Socket? socket;
    try {
      final bytes = buildAndroidEscPosTestReceipt(receipt, target.paperWidth);
      socket = await _socketConnector(
        target.host,
        target.port,
        connectTimeout,
      ).timeout(connectTimeout);
      socket.add(bytes);
      await socket.flush().timeout(connectTimeout);
      unawaited(socket.close());
      socket = null;
      return const Success<void>(null);
    } on Object {
      socket?.destroy();
      return const FailureResult<void>(
        AppFailure(
          kind: FailureKind.device,
          code: 'device.lan_printer_unavailable',
          safeMessage: '无法连接局域网打印机',
        ),
      );
    }
  }

  static Future<bool> _layoutPdf({
    required Uint8List bytes,
    required ReceiptPaperWidth paperWidth,
  }) => Printing.layoutPdf(
    name: 'shouyin-device-test.pdf',
    format: _pageFormat(paperWidth),
    dynamicLayout: false,
    onLayout: (_) async => bytes,
  );

  static Future<Socket> _connectSocket(
    String host,
    int port,
    Duration timeout,
  ) => Socket.connect(host, port, timeout: timeout);
}

Future<Uint8List> buildAndroidTestReceiptPdf(
  TestReceipt receipt,
  ReceiptPaperWidth paperWidth,
) async {
  final document = pw.Document();
  document.addPage(
    pw.Page(
      pageFormat: _pageFormat(paperWidth),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: <pw.Widget>[
          pw.Center(
            child: pw.CustomPaint(
              size: const PdfPoint(108, 22),
              painter: _paintChineseSuccess,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Paper: ${_paperLabel(paperWidth)}'),
          pw.Text('App: ${receipt.appVersion}'),
          pw.Text('Platform: ${receipt.platform}'),
          pw.Text('Time: ${receipt.timestamp.toUtc().toIso8601String()}'),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: receipt.qrPayload,
              width: 72,
              height: 72,
            ),
          ),
        ],
      ),
    ),
  );
  return document.save();
}

List<int> buildAndroidEscPosTestReceipt(
  TestReceipt receipt,
  ReceiptPaperWidth paperWidth,
) {
  final qr = QRCode(receipt.qrPayload, QRSize.size4, QRCorrection.L);
  return <int>[
    0x1b,
    0x40,
    0x1c,
    0x26,
    ...gbk_bytes.encode('打印测试成功\n'),
    0x1c,
    0x2e,
    ...ascii.encode('Paper: ${_paperLabel(paperWidth)}\n'),
    ...ascii.encode('App: ${receipt.appVersion}\n'),
    ...ascii.encode('Platform: ${receipt.platform}\n'),
    ...ascii.encode('Time: ${receipt.timestamp.toUtc().toIso8601String()}\n'),
    ...qr.bytes,
    0x1b,
    0x64,
    0x02,
    0x1d,
    0x56,
    0x00,
  ];
}

PdfPageFormat _pageFormat(ReceiptPaperWidth width) => PdfPageFormat(
  (width == ReceiptPaperWidth.mm58 ? 58 : 80) * PdfPageFormat.mm,
  120 * PdfPageFormat.mm,
  marginAll: 4 * PdfPageFormat.mm,
);

String _paperLabel(ReceiptPaperWidth width) => switch (width) {
  ReceiptPaperWidth.mm58 => '58mm',
  ReceiptPaperWidth.mm80 => '80mm',
};

void _paintChineseSuccess(PdfGraphics canvas, PdfPoint size) {
  canvas.setLineWidth(1.35);
  for (var glyph = 0; glyph < _successGlyphs.length; glyph += 1) {
    final offset = glyph * 18.0;
    for (final line in _successGlyphs[glyph]) {
      canvas.drawLine(
        offset + line.$1 * 14,
        2 + line.$2 * 18,
        offset + line.$3 * 14,
        2 + line.$4 * 18,
      );
    }
  }
  canvas.strokePath();
}

const _successGlyphs = <List<(double, double, double, double)>>[
  [
    (0.05, .28, .43, .28),
    (.25, .08, .25, .9),
    (.05, .7, .42, .55),
    (.5, .2, .95, .2),
    (.74, .2, .74, .88),
    (.48, .52, .92, .52),
  ],
  [
    (.08, .2, .48, .08),
    (.08, .2, .08, .64),
    (.08, .64, .48, .64),
    (.48, .08, .48, .8),
    (.58, .2, .94, .2),
    (.58, .2, .58, .9),
    (.58, .58, .9, .58),
    (.9, .2, .9, .68),
  ],
  [
    (.05, .18, .18, .28),
    (.03, .48, .17, .55),
    (.04, .84, .2, .65),
    (.3, .18, .7, .18),
    (.3, .18, .3, .68),
    (.7, .18, .7, .68),
    (.3, .68, .7, .68),
    (.5, .28, .5, .58),
    (.77, .12, .77, .78),
    (.77, .78, .94, .9),
  ],
  [
    (.05, .18, .18, .28),
    (.05, .42, .2, .42),
    (.13, .42, .13, .82),
    (.13, .82, .3, .66),
    (.3, .3, .92, .3),
    (.6, .1, .6, .76),
    (.35, .58, .82, .58),
    (.4, .82, .62, .58),
    (.62, .58, .9, .88),
    (.8, .1, .9, .18),
  ],
  [
    (.08, .25, .9, .25),
    (.35, .08, .27, .78),
    (.27, .78, .08, .9),
    (.5, .08, .88, .84),
    (.72, .08, .16, .72),
    (.78, .72, .94, .9),
  ],
  [
    (.05, .2, .48, .2),
    (.26, .2, .26, .65),
    (.05, .65, .48, .65),
    (.58, .24, .95, .24),
    (.76, .08, .7, .72),
    (.7, .72, .52, .9),
    (.7, .52, .93, .68),
  ],
];
