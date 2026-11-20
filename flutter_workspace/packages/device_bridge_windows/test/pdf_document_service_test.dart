import 'dart:typed_data';

import 'package:device_bridge_windows/device_bridge_windows.dart';
import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test(
    'Windows business document uses system PDF dispatch and live scope',
    () async {
      var calls = 0;
      var current = true;
      bool Function()? savedGuard;
      final bytes = Uint8List.fromList('%PDF-1.7\n'.codeUnits);
      final PdfDocumentPrinter printer = WindowsPrinterService(
        documentPrint: (document, name, guard) async {
          calls++;
          expect(document, orderedEquals(bytes));
          expect(identical(document, bytes), isFalse);
          expect(name, '其他出库单.pdf');
          expect(guard(), isTrue);
          savedGuard = guard;
          return true;
        },
      );
      final result = await printer.printPdfDocument(
        bytes,
        name: '其他出库单.pdf',
        canDispatch: () => current,
      );
      expect(result, isA<Success<void>>());
      expect(calls, 1);
      current = false;
      expect(savedGuard!(), isFalse);
      final stale = await printer.printPdfDocument(
        bytes,
        name: '其他出库单.pdf',
        canDispatch: () => current,
      );
      expect(stale.failureOrNull?.code, 'device.pdf_context_changed');
      expect(calls, 1);
    },
  );
}
