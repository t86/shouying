import 'dart:async';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StreamController<HidKeyStroke> keys;
  late _FakeMonotonicClock clock;
  late HidScannerService service;

  setUp(() {
    keys = StreamController<HidKeyStroke>.broadcast(sync: true);
    clock = _FakeMonotonicClock();
    service = HidScannerService(keyStrokes: keys.stream, clock: clock.call);
  });

  tearDown(() async {
    service.dispose();
    await keys.close();
  });

  test('rapid characters followed by Enter emit once and clear', () async {
    final values = <String>[];
    service.scans.listen(values.add);
    service.start();

    for (final character in 'ABC123'.split('')) {
      keys.add(HidKeyStroke.character(character));
      clock.advance(const Duration(milliseconds: 40));
    }
    keys.add(const HidKeyStroke.enter());
    keys.add(const HidKeyStroke.enter());

    expect(values, <String>['ABC123']);
  });

  test('gap over 100ms resets input and rejects manual typing', () {
    final values = <String>[];
    service.scans.listen(values.add);
    service.start();

    keys.add(const HidKeyStroke.character('A'));
    clock.advance(const Duration(milliseconds: 120));
    for (final character in 'BC'.split('')) {
      keys.add(HidKeyStroke.character(character));
      clock.advance(const Duration(milliseconds: 20));
    }
    keys.add(const HidKeyStroke.enter());

    expect(values, isEmpty);
  });

  test('short scans and lower control characters are rejected', () {
    final values = <String>[];
    service.scans.listen(values.add);
    service.start();

    keys
      ..add(const HidKeyStroke.character('A'))
      ..add(const HidKeyStroke.character('\u0001'))
      ..add(const HidKeyStroke.character('B'))
      ..add(const HidKeyStroke.enter());

    expect(values, isEmpty);
  });

  test('max length and total time budget prevent unbounded buffering', () {
    final values = <String>[];
    service = HidScannerService(
      keyStrokes: keys.stream,
      clock: clock.call,
      maxLength: 4,
      maxScanDuration: const Duration(milliseconds: 150),
    );
    service.scans.listen(values.add);
    service.start();

    for (final character in 'ABCDE'.split('')) {
      keys.add(HidKeyStroke.character(character));
      clock.advance(const Duration(milliseconds: 40));
    }
    keys.add(const HidKeyStroke.enter());

    expect(values, isEmpty);
  });

  test('stop/start lifecycle does not close the scan stream', () {
    final values = <String>[];
    service.scans.listen(values.add);
    service
      ..start()
      ..stop()
      ..start();

    for (final character in 'XYZ'.split('')) {
      keys.add(HidKeyStroke.character(character));
      clock.advance(const Duration(milliseconds: 20));
    }
    keys.add(const HidKeyStroke.enter());

    expect(values, <String>['XYZ']);
  });

  test('constructor prevents weakening safety controls', () {
    expect(
      () => HidScannerService(
        keyStrokes: keys.stream,
        clock: clock.call,
        minimumLength: 2,
      ),
      throwsArgumentError,
    );
    expect(
      () => HidScannerService(
        keyStrokes: keys.stream,
        clock: clock.call,
        maxLength: 2048,
      ),
      throwsArgumentError,
    );
  });
}

final class _FakeMonotonicClock {
  Duration _elapsed = Duration.zero;

  Duration call() => _elapsed;

  void advance(Duration duration) => _elapsed += duration;
}
