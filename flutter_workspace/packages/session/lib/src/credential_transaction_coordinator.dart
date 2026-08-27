abstract interface class CredentialTransactionCoordinator {
  Future<T> synchronized<T>(String namespace, Future<T> Function() operation);
}

final class CredentialTransactionUnavailableException implements Exception {
  const CredentialTransactionUnavailableException();

  @override
  String toString() =>
      'CredentialTransactionUnavailableException(exclusive lock unavailable)';
}
