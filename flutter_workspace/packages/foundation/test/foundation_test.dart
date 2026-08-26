import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'dart:collection';

void main() {
  test('failure kinds have the fixed public order', () {
    expect(FailureKind.values, [
      FailureKind.network,
      FailureKind.authentication,
      FailureKind.business,
      FailureKind.protocol,
      FailureKind.realtime,
      FailureKind.device,
      FailureKind.unknown,
    ]);
  });
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
      expect(text, contains('[UNSUPPORTED]'));
    },
  );

  test('does not invoke user-defined methods on unsupported objects', () {
    final hostile = _Hostile();
    final input = HashMap<Object?, Object?>.identity()
      ..[hostile] = hostile
      ..['value'] = hostile;
    final text = Redactor.redact(input);
    expect(text, contains('[UNSUPPORTED]'));
    expect(text, isNot(contains('secret-from-tostring')));
    expect(hostile.calls, 0);
  });

  test('uses identity for cycles and serializes equal distinct iterables', () {
    final first = _EqualIterable([1]);
    final second = _EqualIterable([2]);
    final shared = [3];
    final cyclic = <dynamic>[];
    cyclic.add(cyclic);
    final text = Redactor.redact({
      'first': first,
      'second': second,
      'a': shared,
      'b': shared,
      'cycle': cyclic,
    });
    expect(text, contains('"first":[1]'));
    expect(text, contains('"second":[2]'));
    expect(text, contains('"a":[3]'));
    expect(text, contains('"b":[3]'));
    expect(text, contains('[CIRCULAR]'));
  });

  test('masks free text and produces stable output', () {
    final value = {
      'note': 'call 13800138000 and ref 1234567890123456',
      'route': '/v1/items',
      'amount': 1200,
    };
    final first = Redactor.redact(value);
    expect(first, contains('[PHONE]'));
    expect(first, contains('[SENSITIVE_DIGITS]'));
    expect(first, isNot(contains('13800138000')));
    expect(first, isNot(contains('1234567890123456')));
    expect(Redactor.redact(value), first);
  });
}

final class _Hostile {
  int calls = 0;

  @override
  String toString() {
    calls++;
    return 'secret-from-tostring';
  }

  @override
  bool operator ==(Object other) {
    calls++;
    return identical(this, other);
  }

  @override
  int get hashCode {
    calls++;
    return 1;
  }
}

final class _EqualIterable extends Iterable<Object?> {
  _EqualIterable(this.items);
  final List<Object?> items;

  @override
  Iterator<Object?> get iterator => items.iterator;

  @override
  bool operator ==(Object other) => other is _EqualIterable;

  @override
  int get hashCode => 1;
}
