import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:card_table/src/bms_product_image_picker_types.dart';

Future<List<BmsPickedImage>?> pick({required bool multiple}) async {
  final result = Completer<List<BmsPickedImage>?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.png,.jpg,.jpeg'
    ..multiple = multiple;
  input.style.display = 'none';
  void finish(List<BmsPickedImage>? files) {
    if (!result.isCompleted) result.complete(files);
    input.remove();
  }

  input.addEventListener('cancel', ((web.Event event) => finish(null)).toJS);
  input.addEventListener(
    'change',
    ((web.Event event) {
      final files = input.files;
      if (files == null || files.length == 0) {
        finish(null);
        return;
      }
      finish([for (var i = 0; i < files.length; i++) _image(files.item(i)!)]);
    }).toJS,
  );
  web.document.body!.append(input);
  input.click();
  return result.future;
}

BmsPickedImage _image(web.File file) => BmsPickedImage(
  name: file.name,
  size: file.size,
  readBytes: () async => (await file.arrayBuffer().toDart).toDart.asUint8List(),
  release: () async {},
);
