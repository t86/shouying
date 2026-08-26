import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

typedef RequestClock = DateTime Function();

final class RequestGate {
  factory RequestGate({
    required RequestClock clock,
    int maxEntries = 512,
    Duration retention = const Duration(minutes: 10),
  }) {
    if (maxEntries <= 0) {
      throw ArgumentError.value(maxEntries, 'maxEntries', 'must be positive');
    }
    if (retention <= Duration.zero) {
      throw ArgumentError.value(retention, 'retention', 'must be positive');
    }
    return RequestGate._(clock, maxEntries, retention);
  }

  RequestGate._(this._clock, this._maxEntries, this._retention);

  final RequestClock _clock;
  final int _maxEntries;
  final Duration _retention;
  final LinkedHashMap<String, DateTime> _lastAllowedAt =
      LinkedHashMap<String, DateTime>();

  int get trackedRequestCount => _lastAllowedAt.length;

  bool allow(Uri target) {
    final normalized = target.normalizePath();
    final now = _clock();
    _evictExpired(now);

    final key = _hashRoute(normalized);
    final lastAllowedAt = _lastAllowedAt[key];
    if (lastAllowedAt == null) {
      _evictOldestAtCapacity();
      _lastAllowedAt[key] = now;
      return true;
    }

    final threshold = _isCustomerOrderSelection(normalized) ? 100 : 0;
    if (now.difference(lastAllowedAt).inMilliseconds <= threshold) {
      return false;
    }
    _lastAllowedAt.remove(key);
    _lastAllowedAt[key] = now;
    return true;
  }

  String _hashRoute(Uri target) {
    final canonicalRoute = Uri(
      scheme: target.scheme,
      userInfo: target.userInfo,
      host: target.host,
      port: target.port,
      pathSegments: target.pathSegments,
    );
    return sha256.convert(utf8.encode(canonicalRoute.toString())).toString();
  }

  void _evictExpired(DateTime now) {
    _lastAllowedAt.removeWhere((_, lastAllowedAt) {
      final age = now.difference(lastAllowedAt);
      return !age.isNegative && age >= _retention;
    });
  }

  void _evictOldestAtCapacity() {
    while (_lastAllowedAt.length >= _maxEntries) {
      _lastAllowedAt.remove(_lastAllowedAt.keys.first);
    }
  }

  bool _isCustomerOrderSelection(Uri target) {
    final segments = target.pathSegments;
    return segments.length >= 2 &&
        segments[segments.length - 2] == 'sel' &&
        segments.last == 'csm_orders';
  }

  @override
  String toString() => 'RequestGate(trackedRequestCount: $trackedRequestCount)';
}
