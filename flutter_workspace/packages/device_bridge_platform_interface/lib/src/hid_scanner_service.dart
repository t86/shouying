import 'dart:async';

import 'package:device_bridge_platform_interface/src/scanner_service.dart';

typedef MonotonicClock = Duration Function();

enum HidKeyKind { character, enter }

final class HidKeyStroke {
  const HidKeyStroke.character(this.character) : kind = HidKeyKind.character;

  const HidKeyStroke.enter() : kind = HidKeyKind.enter, character = null;

  final HidKeyKind kind;
  final String? character;
}

final class HidScannerService implements ScannerService {
  HidScannerService({
    required this.keyStrokes,
    required this.clock,
    this.minimumLength = 3,
    this.maxLength = 128,
    this.maximumCharacterGap = const Duration(milliseconds: 50),
    this.manualInputResetGap = const Duration(milliseconds: 100),
    this.maxScanDuration = const Duration(seconds: 2),
  }) {
    if (minimumLength < 3) {
      throw ArgumentError.value(minimumLength, 'minimumLength', 'must be >= 3');
    }
    if (maxLength < minimumLength || maxLength > 1024) {
      throw ArgumentError.value(maxLength, 'maxLength', 'must be <= 1024');
    }
    if (maximumCharacterGap <= Duration.zero ||
        maximumCharacterGap > const Duration(milliseconds: 50)) {
      throw ArgumentError.value(
        maximumCharacterGap,
        'maximumCharacterGap',
        'must be between 1ms and 50ms',
      );
    }
    if (manualInputResetGap < const Duration(milliseconds: 100)) {
      throw ArgumentError.value(
        manualInputResetGap,
        'manualInputResetGap',
        'must be at least 100ms',
      );
    }
    if (maxScanDuration <= Duration.zero ||
        maxScanDuration > const Duration(seconds: 5)) {
      throw ArgumentError.value(
        maxScanDuration,
        'maxScanDuration',
        'must be between 1ms and 5s',
      );
    }
  }

  final Stream<HidKeyStroke> keyStrokes;
  final MonotonicClock clock;
  final int minimumLength;
  final int maxLength;
  final Duration maximumCharacterGap;
  final Duration manualInputResetGap;
  final Duration maxScanDuration;
  final StreamController<String> _scanController =
      StreamController<String>.broadcast(sync: true);
  final StringBuffer _buffer = StringBuffer();
  // Stored and cancelled by stop/dispose.
  // ignore: cancel_subscriptions
  StreamSubscription<HidKeyStroke>? _keySubscription;
  Duration? _startedAt;
  Duration? _lastCharacterAt;
  bool _invalidSequence = false;
  bool _disposed = false;

  @override
  ScannerCapabilities get capabilities => const ScannerCapabilities();

  @override
  Stream<String> get scans => _scanController.stream;

  @override
  void start() {
    if (_disposed || _keySubscription != null) return;
    _keySubscription = keyStrokes.listen(_handleKeyStroke);
  }

  @override
  void stop() {
    final subscription = _keySubscription;
    _keySubscription = null;
    unawaited(subscription?.cancel());
    _clear();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stop();
    unawaited(_scanController.close());
  }

  void _handleKeyStroke(HidKeyStroke stroke) {
    if (stroke.kind == HidKeyKind.enter) {
      _finish();
      return;
    }
    final character = stroke.character;
    if (character == null ||
        character.runes.length != 1 ||
        _isControlCharacter(character)) {
      _invalidSequence = true;
      return;
    }

    final now = clock();
    final last = _lastCharacterAt;
    if (last != null) {
      final gap = now - last;
      if (gap > manualInputResetGap) {
        _clear();
      } else if (gap > maximumCharacterGap) {
        _invalidSequence = true;
      }
    }
    _startedAt ??= now;
    _lastCharacterAt = now;
    if (now - _startedAt! > maxScanDuration || _buffer.length >= maxLength) {
      _invalidSequence = true;
      return;
    }
    _buffer.write(character);
  }

  void _finish() {
    final value = _buffer.toString();
    final startedAt = _startedAt;
    final durationOkay =
        startedAt == null || clock() - startedAt <= maxScanDuration;
    if (!_invalidSequence &&
        durationOkay &&
        value.length >= minimumLength &&
        value.length <= maxLength &&
        !_scanController.isClosed) {
      _scanController.add(value);
    }
    _clear();
  }

  void _clear() {
    _buffer.clear();
    _startedAt = null;
    _lastCharacterAt = null;
    _invalidSequence = false;
  }

  static bool _isControlCharacter(String value) {
    final codePoint = value.runes.single;
    return codePoint < 0x20 || codePoint == 0x7f;
  }
}
