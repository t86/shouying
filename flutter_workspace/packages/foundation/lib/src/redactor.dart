import 'dart:collection';
import 'dart:convert';

abstract final class Redactor {
  static const _redacted = '[REDACTED]';
  static const _circular = '[CIRCULAR]';
  static const _sensitiveDigits = '[SENSITIVE_DIGITS]';
  static const _phone = '[PHONE]';
  static const _unsupported = '[UNSUPPORTED]';

  static final _phonePattern = RegExp(r'(?<!\d)1[3-9]\d{9}(?!\d)');
  static final _digitsPattern = RegExp(r'(?<!\d)\d{16,}(?!\d)');
  static const _sensitiveKeys = {
    'tk',
    'stk',
    'passwd',
    'password',
    'authpassword',
    'loginpassword',
    'phone',
    'mobile',
    'paymentcode',
    'paycode',
    'cardnumber',
  };

  static String redact(Object? value) {
    final active = HashSet<Object>.identity();
    try {
      return jsonEncode(_sanitize(value, active));
    } catch (_) {
      return '"$_redacted"';
    }
  }

  static Object? _sanitize(Object? value, Set<Object> active) {
    if (value == null || value is bool || value is String) {
      return value is String ? _mask(value) : value;
    }
    if (value is num) return value.isFinite ? value : null;
    if (value is Map) {
      if (!active.add(value)) return _circular;
      try {
        final entries = <String, Object?>{};
        var nonStringKey = 0;
        for (final entry in value.entries) {
          final key = entry.key is String
              ? entry.key as String
              : '[NON_STRING_KEY_${nonStringKey++}]';
          entries[key] = _isSensitive(key)
              ? _redacted
              : _sanitize(entry.value, active);
        }
        final sorted = entries.keys.toList()..sort();
        return <String, Object?>{for (final key in sorted) key: entries[key]};
      } finally {
        active.remove(value);
      }
    }
    if (value is Iterable) {
      if (!active.add(value)) return _circular;
      try {
        return value
            .map((item) => _sanitize(item, active))
            .toList(growable: false);
      } finally {
        active.remove(value);
      }
    }
    return _unsupported;
  }

  static bool _isSensitive(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
    return _sensitiveKeys.contains(normalized);
  }

  static String _mask(String value) => value
      .replaceAllMapped(_phonePattern, (_) => _phone)
      .replaceAllMapped(_digitsPattern, (_) => _sensitiveDigits);
}
