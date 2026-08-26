import 'dart:collection';
import 'dart:convert';

abstract final class Redactor {
  static const _redacted = '[REDACTED]';
  static const _circular = '[CIRCULAR]';
  static const _sensitiveDigits = '[SENSITIVE_DIGITS]';
  static const _phone = '[PHONE]';
  static const _unsupported = '[UNSUPPORTED]';
  static const _maxDepth = 16;
  static const _maxNodes = 1000;
  static const _maxItems = 200;
  static const _maxStringLength = 4096;
  static const _maxOutputLength = 32768;
  static const _digitsPattern = r'(?<!\d)\d{16,}(?!\d)';
  static const _sensitiveKeys = {
    'tk',
    'stk',
    'token',
    'verifytoken',
    'verificationtoken',
    'accesstoken',
    'refreshtoken',
    'passwd',
    'password',
    'authpassword',
    'loginpassword',
    'phone',
    'phonenum',
    'mobile',
    'mobilephone',
    'custphone',
    'custphonenum',
    'customerphone',
    'cardnumber',
    'cardno',
    'bankcard',
    'paymentcode',
    'paycode',
  };

  /// Redacts a decoded JSON tree. Complex inputs must be `Map`/materialized
  /// `List`; custom collections and general `Iterable`s are unsupported.
  static String redact(Object? value) {
    final budget = _Budget(HashSet<Object>.identity());
    try {
      final output = jsonEncode(_sanitize(value, budget, 0));
      return output.length > _maxOutputLength
          ? jsonEncode('[OUTPUT_TRUNCATED]')
          : output;
    } catch (_) {
      return '"$_redacted"';
    }
  }

  static Object? _sanitize(Object? value, _Budget budget, int depth) {
    if (++budget.nodes > _maxNodes) return '[NODE_LIMIT]';
    if (depth > _maxDepth) return '[MAX_DEPTH]';
    if (value == null || value is bool) return value;
    if (value is String) return _mask(value);
    if (value is num) {
      if (!value.isFinite) {
        return null;
      }
      final digits = value.toString();
      if (value is int && RegExp(r'^1[3-9]\d{9}$').hasMatch(digits)) {
        return _phone;
      }
      if (value is int && RegExp(r'^\d{16,}$').hasMatch(digits)) {
        return _sensitiveDigits;
      }
      return value;
    }
    if (value is Map) {
      if (!budget.active.add(value)) return _circular;
      try {
        final entries = <String, Object?>{};
        var nonStringKey = 0;
        var itemCount = 0;
        for (final entry in value.entries) {
          if (++itemCount > _maxItems) {
            entries['[COLLECTION_TRUNCATED]'] = '[COLLECTION_TRUNCATED]';
            break;
          }
          final originalKey = entry.key;
          final key = originalKey is String
              ? _mask(originalKey)
              : '[NON_STRING_KEY_${nonStringKey++}]';
          var uniqueKey = key;
          var suffix = 1;
          while (entries.containsKey(uniqueKey)) {
            uniqueKey = '$key#${suffix++}';
          }
          entries[uniqueKey] =
              _isSensitive(originalKey is String ? originalKey : key)
              ? _redacted
              : _sanitize(entry.value, budget, depth + 1);
        }
        final sorted = entries.keys.toList()..sort();
        return <String, Object?>{for (final key in sorted) key: entries[key]};
      } finally {
        budget.active.remove(value);
      }
    }
    if (value is List) {
      if (!budget.active.add(value)) return _circular;
      try {
        final result = <Object?>[];
        for (var i = 0; i < value.length && i < _maxItems; i++) {
          result.add(_sanitize(value[i], budget, depth + 1));
        }
        if (value.length > _maxItems) result.add('[COLLECTION_TRUNCATED]');
        return result;
      } finally {
        budget.active.remove(value);
      }
    }
    return _unsupported;
  }

  static bool _isSensitive(String key) => _sensitiveKeys.contains(
    key.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), ''),
  );

  static String _mask(String value) {
    var result = value
        .replaceAllMapped(
          RegExp(r'(?<!\d)(?:\+?86[ -]?)?1[3-9](?:[ -]?\d){9}(?!\d)'),
          (_) => _phone,
        )
        .replaceAllMapped(RegExp(_digitsPattern), (_) => _sensitiveDigits);
    if (result.length > _maxStringLength) {
      result = '${result.substring(0, _maxStringLength)}[STRING_TRUNCATED]';
    }
    return result;
  }
}

final class _Budget {
  _Budget(this.active);
  final HashSet<Object> active;
  int nodes = 0;
}
