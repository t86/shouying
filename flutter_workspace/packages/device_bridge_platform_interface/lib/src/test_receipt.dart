final class TestReceipt {
  TestReceipt({
    required String appVersion,
    required String platform,
    required this.timestamp,
    required String diagnosticId,
  }) : appVersion = _safeText(appVersion, 'appVersion', 64),
       platform = _safeText(platform, 'platform', 32),
       diagnosticId = _diagnosticId(diagnosticId);

  final String appVersion;
  final String platform;
  final DateTime timestamp;
  final String diagnosticId;

  String get qrPayload => diagnosticId;

  static String _safeText(String value, String name, int maxLength) {
    final text = value.trim();
    if (text != value ||
        text.isEmpty ||
        text.length > maxLength ||
        _controlCharacters.hasMatch(text) ||
        _sensitiveMarkers.hasMatch(text)) {
      throw ArgumentError.value(
        value,
        name,
        'must contain safe diagnostic text',
      );
    }
    return text;
  }

  static String _diagnosticId(String value) {
    if (!RegExp(r'^[A-Za-z0-9_-]{3,64}$').hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'diagnosticId',
        'must be an opaque diagnostic identifier',
      );
    }
    return value;
  }

  static final RegExp _controlCharacters = RegExp(r'[\x00-\x1F\x7F]');
  static final RegExp _sensitiveMarkers = RegExp(
    r'(?:token|password|passwd|secret|authorization|request\s*body|请求体|密码|凭据|令牌)\s*[:=]',
    caseSensitive: false,
  );
}
