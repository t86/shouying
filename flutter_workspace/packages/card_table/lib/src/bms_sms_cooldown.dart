import 'package:card_table/src/bms_sms_cooldown_stub.dart'
    if (dart.library.io) 'package:card_table/src/bms_sms_cooldown_native.dart'
    if (dart.library.js_interop) 'package:card_table/src/bms_sms_cooldown_web.dart'
    as platform;

DateTime? _lastSent;
Future<DateTime?> readSmsSelfCheckTime() async {
  final stored = await platform.read();
  if (stored != null && (_lastSent == null || stored.isAfter(_lastSent!))) {
    _lastSent = stored;
  }
  return _lastSent;
}

Future<void> writeSmsSelfCheckTime(DateTime value) async {
  _lastSent = value;
  await platform.write(value);
}
