enum FailureKind {
  network,
  authentication,
  business,
  protocol,
  realtime,
  device,
  unknown,
}

final class AppFailure {
  const AppFailure({
    required this.kind,
    required this.code,
    required this.safeMessage,
  });

  final FailureKind kind;
  final String code;
  final String safeMessage;
}
