import 'package:card_table/src/bms_product_image_picker_native.dart'
    if (dart.library.js_interop) 'package:card_table/src/bms_product_image_picker_web.dart'
    as platform;
import 'package:card_table/src/bms_product_image_picker_types.dart';
export 'package:card_table/src/bms_product_image_picker_types.dart';

Future<List<BmsPickedImage>?> pickBmsProductImages({required bool multiple}) =>
    platform.pick(multiple: multiple);
