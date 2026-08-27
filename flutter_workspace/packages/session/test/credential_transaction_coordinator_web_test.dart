@TestOn('browser')
library;

import 'dart:async';

import 'package:session/src/credential_transaction_coordinator.dart';
import 'package:session/src/credential_transaction_coordinator_web.dart';
import 'package:test/test.dart';

void main() {
  test('real Web Locks serialize coordinator instances by namespace', () async {
    const requester = NavigatorWebLockRequester();
    expect(requester.isAvailable, isTrue);
    const first = BrowserCredentialTransactionCoordinator(requester: requester);
    const second = BrowserCredentialTransactionCoordinator(
      requester: requester,
    );
    final firstEntered = Completer<void>();
    final releaseFirst = Completer<void>();
    var secondEntered = false;

    final firstOperation = first.synchronized<void>(
      'test.browser.shared',
      () async {
        firstEntered.complete();
        await releaseFirst.future;
      },
    );
    await firstEntered.future;
    final secondOperation = second.synchronized<void>(
      'test.browser.shared',
      () async {
        secondEntered = true;
      },
    );
    await Future<void>.delayed(Duration.zero);

    expect(secondEntered, isFalse);
    releaseFirst.complete();
    await Future.wait<void>(<Future<void>>[firstOperation, secondOperation]);
    expect(secondEntered, isTrue);
  });

  test('missing Web Locks fail closed without running the operation', () async {
    const coordinator = BrowserCredentialTransactionCoordinator(
      requester: _UnavailableWebLockRequester(),
    );
    var called = false;

    await expectLater(
      coordinator.synchronized<void>('test.browser.unavailable', () async {
        called = true;
      }),
      throwsA(isA<CredentialTransactionUnavailableException>()),
    );
    expect(called, isFalse);
  });
}

final class _UnavailableWebLockRequester implements WebLockRequester {
  const _UnavailableWebLockRequester();

  @override
  bool get isAvailable => false;

  @override
  Future<void> requestExclusive(
    String name,
    Future<void> Function() operation,
  ) => throw StateError('request must not be called');
}
