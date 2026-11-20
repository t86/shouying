import 'dart:ui' as ui;

import 'package:card_table/src/qr_code_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr/qr.dart';

void main() {
  testWidgets(
    'QR paints encoded modules inside a four-module white quiet zone',
    (tester) async {
      const key = Key('qr-paint');
      const data = 'synthetic-qr-content';
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: QrCodePane(data: data, paintKey: key),
          ),
        ),
      );
      final painter = tester.widget<CustomPaint>(find.byKey(key)).painter!;
      final recorder = ui.PictureRecorder();
      painter.paint(Canvas(recorder), const Size(200, 200));
      final picture = recorder.endRecording();
      final image = await tester.runAsync(() => picture.toImage(200, 200));
      final bytes = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
      );
      final matrix = QrImage(
        QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
      );
      final margin = (200 * 4 / (matrix.moduleCount + 8)).floor();
      var dark = 0;
      for (var y = 0; y < 200; y++) {
        for (var x = 0; x < 200; x++) {
          final index = (y * 200 + x) * 4;
          final red = bytes!.getUint8(index);
          if (x < margin ||
              y < margin ||
              x >= 200 - margin ||
              y >= 200 - margin) {
            expect(red, 255);
            expect(bytes.getUint8(index + 3), 255);
          } else if (red == 0) {
            dark++;
          }
        }
      }
      expect(dark, greaterThan(100));
      image!.dispose();
      picture.dispose();
    },
  );
  testWidgets('empty QR data produces an error instead of a fake text QR', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: QrCodePane(data: '')));
    expect(find.text('二维码无法生成，请重新获取'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(QrCodePane),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
  });
}
