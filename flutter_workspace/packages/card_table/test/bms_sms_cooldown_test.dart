import 'dart:io';

import 'package:card_table/src/bms_sms_cooldown_native.dart' as native;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('native cooldown persists success timestamp across reads', () async {
    final directory = await Directory.systemTemp.createTemp(
      'sms-cooldown-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    expect(await native.read(), isNull);
    final time = DateTime(2026, 9, 20, 10, 1, 2);
    await native.write(time);
    expect(await native.read(), time);
  });
}
