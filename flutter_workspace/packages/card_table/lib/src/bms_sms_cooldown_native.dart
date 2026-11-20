import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> _file() async => File(
  '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}sms_self_check_at',
);
Future<DateTime?> read() async {
  final file = await _file();
  if (!await file.exists()) return null;
  final millis = int.tryParse(await file.readAsString());
  return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
}

Future<void> write(DateTime value) async {
  final file = await _file();
  await file.parent.create(recursive: true);
  await file.writeAsString('${value.millisecondsSinceEpoch}', flush: true);
}
