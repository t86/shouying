import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  test('result exposes either value or typed failure', () {
    const ok = Success<int>(3);
    const failed = FailureResult<int>(
      AppFailure(
        kind: FailureKind.network,
        code: 'network.unavailable',
        safeMessage: '网络不可用',
      ),
    );
    expect(ok.valueOrNull, 3);
    expect(ok.failureOrNull, isNull);
    expect(failed.valueOrNull, isNull);
    expect(failed.failureOrNull?.kind, FailureKind.network);
  });

  test('only online allows writes', () {
    expect(ConnectionPhase.online.allowsWrites, isTrue);
    expect(ConnectionPhase.blocked.allowsWrites, isFalse);
    expect(ConnectionPhase.reconciling.allowsWrites, isFalse);
  });

  test('all failure kinds construct safely and fields are immutable', () {
    for (final kind in FailureKind.values) {
      const failure = AppFailure(
        kind: FailureKind.unknown,
        code: 'safe.code',
        safeMessage: 'safe message',
      );
      expect(
        AppFailure(
          kind: kind,
          code: 'safe.code',
          safeMessage: 'safe message',
        ).kind,
        kind,
      );
      expect(failure.code, 'safe.code');
      expect(failure.safeMessage, 'safe message');
    }
  });

  test('nullable success remains distinguishable from failure', () {
    const success = Success<String?>(null);
    const failure = FailureResult<String?>(
      AppFailure(
        kind: FailureKind.unknown,
        code: 'unknown',
        safeMessage: 'unknown',
      ),
    );
    expect(success, isA<Success<String?>>());
    expect(success.valueOrNull, isNull);
    expect(failure, isA<FailureResult<String?>>());
    expect(failure.failureOrNull, isNotNull);
  });

  test('redacts sensitive values and free text secrets', () {
    final text = Redactor.redact({
      'tk': 'token-value',
      'passwd': 'HASH',
      'phone': '13800138000',
      'payment_code': '123456789012345678',
      'route': '/auth/login',
    });
    expect(text, contains('/auth/login'));
    expect(text, isNot(contains('token-value')));
    expect(text, isNot(contains('13800138000')));
    expect(text, isNot(contains('123456789012345678')));
  });

  test('redacts nested collections without mutating original', () {
    final original = {
      'profile': {'PHONE': '13800138000', 'note': 'call 13900139000'},
      'items': ['payment_code', 'amount 1200 at 2026-08-26', 1],
    };
    final text = Redactor.redact(original);
    expect(text, contains('[REDACTED]'));
    expect(text, contains('[PHONE]'));
    expect(text, isNot(contains('13800138000')));
    expect(text, isNot(contains('13900139000')));
    expect(text, contains('2026-08-26'));
    expect(original['profile'], {
      'PHONE': '13800138000',
      'note': 'call 13900139000',
    });
  });

  test('recognizes sensitive key separators and replaces values', () {
    final text = Redactor.redact({
      'stk': 'a',
      'password': 'b',
      'auth_password': 'c',
      'login-password': 'd',
      'mobile': 'e',
      'payCode': 'f',
      'card_number': 'g',
    });
    for (final secret in ['"a"', '"b"', '"c"', '"d"', '"e"', '"f"', '"g"']) {
      expect(text, isNot(contains(secret)));
    }
    expect(RegExp(r'\[REDACTED\]').allMatches(text).length, 7);
  });

  test(
    'handles primitive, unknown, non-string keys, and circular values safely',
    () {
      expect(() => Redactor.redact(null), returnsNormally);
      expect(Redactor.redact(double.infinity), contains('null'));
      final circular = <dynamic, dynamic>{};
      circular['self'] = circular;
      final list = <dynamic>[];
      list.add(list);
      final text = Redactor.redact({
        1: circular,
        'list': list,
        'value': Object(),
      });
      expect(text, contains('[CIRCULAR]'));
      expect(text, contains('Instance of'));
    },
  );
}
