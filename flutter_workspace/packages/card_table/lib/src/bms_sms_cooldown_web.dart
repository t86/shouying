import 'package:web/web.dart' as web;

// Preserve the original Vue timestamp key for browser migrations.
Future<DateTime?> read() async {
  final millis = int.tryParse(
    web.window.localStorage.getItem('currentTime') ?? '',
  );
  return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
}

Future<void> write(DateTime value) async => web.window.localStorage.setItem(
  'currentTime',
  '${value.millisecondsSinceEpoch}',
);
