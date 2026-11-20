import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Encodes text locally. Four white modules surround the symbol for scanners.
final class QrCodePane extends StatelessWidget {
  const QrCodePane({
    required this.data,
    this.size = 200,
    this.paintKey,
    super.key,
  });
  final String data;
  final double size;
  final Key? paintKey;
  static const quietZoneModules = 4;
  @override
  Widget build(BuildContext context) {
    try {
      if (data.isEmpty) throw const FormatException();
      final image = QrImage(
        QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
      );
      return CustomPaint(
        key: paintKey,
        size: Size.square(size),
        painter: _QrCodePainter(image),
      );
    } on Object {
      return SizedBox(
        key: paintKey,
        width: size,
        height: size,
        child: const Center(child: Text('二维码无法生成，请重新获取')),
      );
    }
  }
}

final class _QrCodePainter extends CustomPainter {
  _QrCodePainter(this.image);
  final QrImage image;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = false
      ..color = Colors.white;
    canvas.drawRect(Offset.zero & size, paint);
    final cell =
        size.shortestSide /
        (image.moduleCount + 2 * QrCodePane.quietZoneModules);
    final offset = QrCodePane.quietZoneModules * cell;
    paint.color = Colors.black;
    for (var row = 0; row < image.moduleCount; row++) {
      for (var col = 0; col < image.moduleCount; col++) {
        if (image.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(offset + col * cell, offset + row * cell, cell, cell),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCodePainter oldDelegate) =>
      oldDelegate.image != image;
}
