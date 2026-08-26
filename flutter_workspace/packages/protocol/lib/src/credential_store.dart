abstract interface class CredentialStore {
  Future<String?> readTk();

  Future<void> writeTk(String value);

  Future<void> clearTk();

  Future<String?> readStk();

  Future<void> writeStk(String value);

  Future<void> clearStk();
}
