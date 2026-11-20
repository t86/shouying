import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:protocol/protocol.dart';

Future<String> save(ProtocolBinaryFile file, {bool Function()? canSave}) async {
  void check() {
    if (!(canSave?.call() ?? true)) throw StateError('Export context changed');
  }

  check();
  final downloads = await getDownloadsDirectory();
  check();
  if (downloads == null) throw FileSystemException('Downloads unavailable');
  await downloads.create(recursive: true);
  check();
  // A unique directory prevents replacing an earlier export with the same name.
  final directory = await downloads.createTemp('wine-export-');
  File? target;
  try {
    check();
    final safeName = file.fileName.split(RegExp(r'[/\\]')).last;
    target = File('${directory.path}${Platform.pathSeparator}$safeName');
    check();
    await target.writeAsBytes(file.bytes, flush: true);
    check();
    return target.path;
  } on Object {
    // Only remove this invocation's new artifact; never an earlier export.
    try {
      if (target != null && await target.exists()) await target.delete();
    } on Object {
      /* Best-effort cleanup. */
    }
    try {
      await directory.delete();
    } on Object {
      /* Leave nonempty directories untouched. */
    }
    rethrow;
  }
}
