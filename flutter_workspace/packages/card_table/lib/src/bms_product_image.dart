import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:foundation/foundation.dart';

enum BmsProductImageOperation {
  check('/prd/batch_upload_pic_chk'),
  missing('/prd/get_no_pic_prds'),
  signature('/oss/pt'),
  bindBatch('/prd/batch_upload_pic'),
  bindSingle('/prd/upload_pic'),
  getDefault('/prd/get_prd_def_pic'),
  saveDefault('/prd/save_prd_def_pic');

  const BmsProductImageOperation(this.path);
  final String path;
}

class BmsProductImageRequest {
  const BmsProductImageRequest(this.operation, {this.parameters = const {}});
  final BmsProductImageOperation operation;
  final Map<String, Object?> parameters;
  Map<String, Object?> get body {
    final expected = switch (operation) {
      BmsProductImageOperation.check => {'pic_names'},
      BmsProductImageOperation.bindBatch => {'ids', 'pic_names'},
      BmsProductImageOperation.bindSingle => {'prd_id', 'prd_name'},
      BmsProductImageOperation.saveDefault => {'mode', 'def_pic_name'},
      _ => <String>{},
    };
    if (parameters.length != expected.length ||
        !parameters.keys.every(expected.contains)) {
      throw const FormatException('图片请求参数不完整');
    }
    bool id(Object? v) => v is int && v > 0 && v <= 9007199254740991;
    bool stored(Object? v) =>
        v is String &&
        RegExp(
          r'^[a-zA-Z0-9_-]+\.(png|jpg|jpeg)$',
          caseSensitive: false,
        ).hasMatch(v);
    if (operation == BmsProductImageOperation.check) {
      final names = parameters['pic_names'];
      if (names is! List ||
          names.isEmpty ||
          names.length > 200 ||
          names.any((n) => n is! String || n.isEmpty || n.length > 200)) {
        throw const FormatException('图片名称无效');
      }
    }
    if (operation == BmsProductImageOperation.bindBatch) {
      final ids = parameters['ids'], names = parameters['pic_names'];
      if (ids is! List ||
          ids.isEmpty ||
          ids.length > 200 ||
          ids.any((v) => !id(v)) ||
          names is! List ||
          names.length != ids.length ||
          names.any((v) => !stored(v))) {
        throw const FormatException('商品与图片必须一一对应');
      }
    }
    if (operation == BmsProductImageOperation.bindSingle &&
        (!id(parameters['prd_id']) || !stored(parameters['prd_name']))) {
      throw const FormatException('商品或图片名称无效');
    }
    if (operation == BmsProductImageOperation.saveDefault &&
        (![1, 2].contains(parameters['mode']) ||
            (parameters['def_pic_name'] != '' &&
                !stored(parameters['def_pic_name'])))) {
      throw const FormatException('默认图片设置无效');
    }
    return Map.unmodifiable(
      parameters.map(
        (k, v) => MapEntry(k, v is List ? List.unmodifiable(v) : v),
      ),
    );
  }
}

class BmsProductImageFile {
  BmsProductImageFile(this.name, Uint8List bytes)
    : bytes = Uint8List.fromList(bytes);
  final String name;
  final Uint8List bytes;
  String get extension => name.split('.').last.toLowerCase();
  String get productName => name.split('.').first;
  static void validateNameAndSize(String name, int? size) {
    if (name.isEmpty ||
        name.length > 240 ||
        name.contains('/') ||
        name.contains('\\') ||
        name.split('.').first.isEmpty ||
        !RegExp(r'\.(png|jpg|jpeg)$', caseSensitive: false).hasMatch(name)) {
      throw const FormatException('仅支持按商品名称命名的 PNG/JPG/JPEG 图片');
    }
    if (size != null && (size <= 0 || size >= 500 * 1024)) {
      throw const FormatException('图片须小于500KiB');
    }
  }

  Future<Uint8List> validateAndThumbnail() async {
    validateNameAndSize(name, bytes.length);
    final png =
        bytes.length >= 8 &&
        [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ].asMap().entries.every((e) => bytes[e.key] == e.value);
    final jpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (extension == 'png' ? !png : !jpeg) {
      throw const FormatException('图片内容与扩展名不符');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? image;
    try {
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width <= 0 ||
          descriptor.height <= 0 ||
          descriptor.width * descriptor.height > 16000000) {
        throw const FormatException('图片尺寸过大或无效');
      }
      final scale = min(1.0, 128 / max(descriptor.width, descriptor.height));
      codec = await descriptor.instantiateCodec(
        targetWidth: max(1, (descriptor.width * scale).round()),
        targetHeight: max(1, (descriptor.height * scale).round()),
      );
      image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw const FormatException('无法读取图片');
      return data.buffer.asUint8List();
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('图片已损坏或无法解码');
    } finally {
      image?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer.dispose();
    }
  }
}

class BmsImageSignature {
  BmsImageSignature.fromWire(Map<String, Object?> data)
    : host = Uri.parse('${data['host'] ?? ''}'),
      directory = '${data['dir'] ?? ''}',
      policy = '${data['policy'] ?? ''}',
      accessId = '${data['accessid'] ?? ''}',
      signature = '${data['signature'] ?? ''}' {
    final hostName = host.host.toLowerCase();
    if (host.scheme != 'https' ||
        hostName.isEmpty ||
        host.userInfo.isNotEmpty ||
        host.hasQuery ||
        host.hasFragment ||
        hostName == 'localhost' ||
        hostName == '::1' ||
        RegExp(r'^(127\.|10\.|192\.168\.|169\.254\.|172\.(1[6-9]|2\d|3[01])\.)')
            .hasMatch(hostName)) {
      throw const FormatException('图片存储地址不安全');
    }
    if (directory.startsWith('/') ||
        directory.contains('..') ||
        directory.contains('\\') ||
        policy.isEmpty ||
        accessId.isEmpty ||
        signature.isEmpty) {
      throw const FormatException('图片上传凭据无效');
    }
  }
  final Uri host;
  final String directory, policy, accessId, signature;
  Map<String, String> fields(String filename) => {
    'key': '$directory$filename',
    'policy': policy,
    'OSSAccessKeyId': accessId,
    'success_action_status': '200',
    'signature': signature,
  };
}

class BmsUploadedImage {
  const BmsUploadedImage(this.fileName, this.thumbnail);
  final String fileName;
  final Uint8List thumbnail;
}

String newBmsImageFileName(String extension) {
  final random = Random.secure();
  final hex = List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}.$extension';
}

abstract interface class BmsProductImageLoader {
  Object? get productImageContext;
  Future<Result<Map<String, Object?>>> requestProductImage(
    BmsProductImageRequest request,
  );
  Future<Result<BmsUploadedImage>> uploadProductImage(
    BmsProductImageFile file, {
    required bool Function() isCurrent,
  });
}
