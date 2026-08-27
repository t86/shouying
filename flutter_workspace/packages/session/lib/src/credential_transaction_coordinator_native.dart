import 'dart:async';

import 'package:session/src/credential_transaction_coordinator.dart';

CredentialTransactionCoordinator createCredentialTransactionCoordinator() =>
    const ProcessCredentialTransactionCoordinator();

final class ProcessCredentialTransactionCoordinator
    implements CredentialTransactionCoordinator {
  const ProcessCredentialTransactionCoordinator();

  static final Map<String, Future<void>> _transactionTails =
      <String, Future<void>>{};

  @override
  Future<T> synchronized<T>(
    String namespace,
    Future<T> Function() operation,
  ) async {
    final preceding = _transactionTails[namespace] ?? Future<void>.value();
    final release = Completer<void>();
    final tail = release.future;
    _transactionTails[namespace] = tail;
    await preceding;
    try {
      return await operation();
    } finally {
      release.complete();
      if (identical(_transactionTails[namespace], tail)) {
        unawaited(_transactionTails.remove(namespace));
      }
    }
  }
}
