typedef RequestClock = DateTime Function();

final class RequestGate {
  factory RequestGate({required RequestClock clock}) => RequestGate._(clock);

  RequestGate._(this._clock);

  final RequestClock _clock;
  final Map<String, DateTime> _lastAllowedAt = <String, DateTime>{};

  bool allow(Uri target) {
    final normalized = target.normalizePath();
    final key = normalized.toString();
    final now = _clock();
    final lastAllowedAt = _lastAllowedAt[key];
    if (lastAllowedAt == null) {
      _lastAllowedAt[key] = now;
      return true;
    }

    final threshold = _isCustomerOrderSelection(normalized) ? 100 : 0;
    if (now.difference(lastAllowedAt).inMilliseconds <= threshold) {
      return false;
    }
    _lastAllowedAt[key] = now;
    return true;
  }

  bool _isCustomerOrderSelection(Uri target) {
    final segments = target.pathSegments;
    return segments.length >= 2 &&
        segments[segments.length - 2] == 'sel' &&
        segments.last == 'csm_orders';
  }
}
