import 'dart:async';

import 'package:device_bridge_platform_interface/src/hid_scanner_service.dart';
import 'package:device_bridge_platform_interface/src/scanner_service.dart';
import 'package:flutter/services.dart';

final class HardwareKeyboardScannerService implements ScannerService {
  HardwareKeyboardScannerService({
    this.capabilities = const ScannerCapabilities(),
  }) {
    _hid = HidScannerService(keyStrokes: _keys.stream, clock: _clock);
  }

  final StreamController<HidKeyStroke> _keys =
      StreamController<HidKeyStroke>.broadcast(sync: true);
  final Stopwatch _stopwatch = Stopwatch()..start();
  late final HidScannerService _hid;
  bool _listening = false;

  @override
  final ScannerCapabilities capabilities;

  Duration _clock() => _stopwatch.elapsed;

  @override
  Stream<String> get scans => _hid.scans;

  @override
  void start() {
    if (_listening) return;
    _listening = true;
    HardwareKeyboard.instance.addHandler(_handleKey);
    _hid.start();
  }

  @override
  void stop() {
    if (!_listening) return;
    _listening = false;
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _hid.stop();
  }

  void dispose() {
    stop();
    _hid.dispose();
    unawaited(_keys.close());
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _keys.add(const HidKeyStroke.enter());
      return false;
    }
    final character = event.character;
    if (character != null) _keys.add(HidKeyStroke.character(character));
    return false;
  }
}
