
import 'package:flutter/services.dart';
import 'package:card_table/src/bms_product_image_picker_types.dart';

const _channel = MethodChannel('shouyin/product_images');
Future<List<BmsPickedImage>?> pick({required bool multiple}) async {
  final rows = await _channel.invokeMethod<List<Object?>>('pickImages', {
    'multiple': multiple,
  });
  if (rows == null) return null;
  return [for (final row in rows) _image(row)];
}

BmsPickedImage _image(Object? raw) {
  if (raw is! Map ||
      raw['id'] is! String ||
      raw['name'] is! String ||
      (raw['size'] != null && raw['size'] is! int)) {
    throw const FormatException('文件选择器返回无效数据');
  }
  final id = raw['id'] as String;
  return BmsPickedImage(
    name: raw['name'] as String,
    size: raw['size'] as int?,
    readBytes: () async {
      final bytes = await _channel.invokeMethod<Uint8List>('readImage', {
        'id': id,
      });
      if (bytes == null) throw const FormatException('无法读取所选图片');
      return bytes;
    },
    release: () async {
      await _channel.invokeMethod<void>('releaseImages', {
        'ids': [id],
      });
    },
  );
}
