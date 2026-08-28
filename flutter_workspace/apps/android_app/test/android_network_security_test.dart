import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release manifest uses a narrow legacy and loopback allowlist', () {
    final prefix = File('android/app/src/main/AndroidManifest.xml').existsSync()
        ? ''
        : 'apps/android_app/';
    final manifest = File('${prefix}android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    final config = File(
      '${prefix}android/app/src/main/res/xml/network_security_config.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('android.permission.CAMERA'));
    expect(manifest, isNot(contains('android.permission.BLUETOOTH')));
    expect(manifest, isNot(contains('android.hardware.usb')));
    expect(
      manifest,
      contains('android:networkSecurityConfig="@xml/network_security_config"'),
    );
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    expect(manifest, isNot(contains('android:usesCleartextTraffic="true"')));
    expect(config, contains('<base-config cleartextTrafficPermitted="false">'));
    expect(
      config,
      isNot(contains('<base-config cleartextTrafficPermitted="true">')),
    );
    final domains = RegExp(
      r'<domain includeSubdomains="false">([^<]+)</domain>',
    ).allMatches(config).map((match) => match.group(1)).toSet();
    expect(domains, <String>{
      '127.0.0.1',
      'nls.server.com',
      'nls-dev.xmsjznwl.com',
    });
  });
}
