Future<DateTime?> read() async => null;
Future<void> write(DateTime value) async =>
    throw UnsupportedError('Persistent cooldown unavailable');
