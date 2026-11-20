import 'dart:typed_data';

class BmsPickedImage {
  const BmsPickedImage({
    required this.name,
    required this.size,
    required this.readBytes,
    required this.release,
  });
  final String name;
  final int? size;
  final Future<Uint8List> Function() readBytes;
  final Future<void> Function() release;
}

typedef BmsProductImagePicker = Future<List<BmsPickedImage>?> Function({
  required bool multiple,
});
