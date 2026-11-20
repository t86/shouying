import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:protocol/protocol.dart';

Future<String> save(ProtocolBinaryFile file, {bool Function()? canSave}) async {
  if (!(canSave?.call() ?? true)) throw StateError('Export context changed');
  final blob = web.Blob(
    [file.bytes.toJS].toJS,
    web.BlobPropertyBag(type: file.mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = file.fileName;
  web.document.body!.append(anchor);
  try {
    if (!(canSave?.call() ?? true)) throw StateError('Export context changed');
    anchor.click();
  } finally {
    anchor.remove();
    Future<void>.delayed(
      const Duration(seconds: 1),
      () => web.URL.revokeObjectURL(url),
    );
  }
  return '浏览器下载：${file.fileName}';
}
