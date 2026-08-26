final class CredentialSnapshot {
  const CredentialSnapshot({required this.tk, required this.stk});

  final String? tk;
  final String? stk;
}

abstract interface class CredentialStore {
  Future<String?> readTk();

  Future<void> writeTk(String value);

  Future<void> clearTk();

  Future<String?> readStk();

  Future<void> writeStk(String value);

  Future<void> clearStk();

  /// Reads both credentials as one consistent, atomic snapshot.
  Future<CredentialSnapshot> readSnapshot();

  /// Atomically clears tk only when its current value still matches [expected].
  Future<void> clearTkIfMatches(String? expected);

  /// Atomically clears stk only when its current value still matches [expected].
  Future<void> clearStkIfMatches(String? expected);
}
