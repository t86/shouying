final class CanonicalUri {
  const CanonicalUri._();

  static final RegExp _dangerousResidualEscape = RegExp(
    r'%(?:0[0-9a-f]|1[0-9a-f]|2[3eEfF5]|3[fF]|5[cC]|7[fF])',
    caseSensitive: false,
  );

  static List<String>? decodeRequestPath(String path) {
    if (path.isEmpty ||
        path.trim() != path ||
        path.startsWith('//') ||
        path.contains(r'\') ||
        path.contains('?') ||
        path.contains('#')) {
      return null;
    }

    final parsed = Uri.tryParse(path);
    if (parsed == null ||
        parsed.isAbsolute ||
        parsed.hasAuthority ||
        parsed.hasQuery ||
        parsed.hasFragment) {
      return null;
    }

    final rawPath = path.startsWith('/') ? path.substring(1) : path;
    final rawSegments = rawPath.split('/');
    if (rawSegments.isEmpty) return null;

    final decodedSegments = <String>[];
    try {
      for (final rawSegment in rawSegments) {
        final decoded = Uri.decodeComponent(rawSegment);
        if (!_isSafeDecodedSegment(decoded)) return null;
        decodedSegments.add(decoded);
      }
    } on FormatException {
      return null;
    }
    return decodedSegments;
  }

  static List<String>? safePathSegments(Uri uri) {
    final segments = uri.pathSegments;
    for (final segment in segments) {
      if (!_isSafeDecodedSegment(segment)) return null;
    }
    return List<String>.unmodifiable(segments);
  }

  static bool isSameOriginSubtree({required Uri target, required Uri base}) {
    if (!target.isAbsolute ||
        !target.hasAuthority ||
        target.userInfo.isNotEmpty ||
        target.hasFragment ||
        target.scheme != base.scheme ||
        target.host != base.host ||
        target.port != base.port) {
      return false;
    }

    final targetSegments = safePathSegments(target);
    final baseSegments = safePathSegments(base);
    if (targetSegments == null ||
        baseSegments == null ||
        targetSegments.length < baseSegments.length) {
      return false;
    }
    for (var index = 0; index < baseSegments.length; index += 1) {
      if (targetSegments[index] != baseSegments[index]) return false;
    }
    return true;
  }

  static bool _isSafeDecodedSegment(String segment) {
    if (segment.isEmpty ||
        segment == '.' ||
        segment == '..' ||
        segment.contains('/') ||
        segment.contains(r'\') ||
        segment.contains('?') ||
        segment.contains('#') ||
        _dangerousResidualEscape.hasMatch(segment)) {
      return false;
    }
    return !segment.runes.any((rune) => rune < 0x20 || rune == 0x7f);
  }
}
