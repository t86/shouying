import 'package:flutter_test/flutter_test.dart';
import 'package:session/session.dart';

void main() {
  test(
    'terminal settings persist separately from authentication credentials',
    () async {
      final backend = Backend();
      final settings = TerminalRegistrationSettings(backend: backend);
      expect((await settings.load()).valueOrNull, isNull);
      expect((await settings.save('native-machine', 8)).failureOrNull, isNull);
      final restored = (await settings.load()).valueOrNull!;
      expect(restored.machineCode, 'native-machine');
      expect(restored.authMode, 8);
      expect(backend.values.keys, isNot(contains('tk')));
      expect(backend.values.keys, isNot(contains('stk')));
      expect((await settings.save('', 8)).failureOrNull, isNotNull);
    },
  );
}

class Backend implements SecureCredentialBackend {
  final values = <String, String?>{};
  @override
  Future<String?> read(String key, {required bool sessionScoped}) async =>
      values[key];
  @override
  Future<void> write(
    String key,
    String? value, {
    required bool sessionScoped,
  }) async {
    expect(sessionScoped, isFalse);
    values[key] = value;
  }
}
