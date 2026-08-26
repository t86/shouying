enum ConnectionPhase { online, blocked, reconciling }

extension ConnectionPhaseWriteAccess on ConnectionPhase {
  bool get allowsWrites => this == ConnectionPhase.online;
}
