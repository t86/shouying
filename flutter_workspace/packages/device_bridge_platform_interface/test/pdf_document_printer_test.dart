import 'dart:typed_data';

import 'package:device_bridge_platform_interface/device_bridge_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'system document bridge dispatches stable PDF bytes and scoped callback',
    () async {
      final pdf = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55, 10]);
      var calls = 0;
      final result = await dispatchPdfDocument(pdf, '出库单.pdf', () => true, (
        bytes,
        name,
        guard,
      ) async {
        calls++;
        expect(bytes, pdf);
        expect(name, '出库单.pdf');
        expect(guard(), true);
        return true;
      });
      expect(result.failureOrNull, isNull);
      expect(calls, 1);
    },
  );
  test('invalid PDF or expired scope never opens the system dialog', () async {
    var calls = 0;
    final pdf = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55, 10]);
    for (final input in [(Uint8List(0), true), (pdf, false)]) {
      final result = await dispatchPdfDocument(
        input.$1,
        '出库单.pdf',
        () => input.$2,
        (bytes, name, guard) async {
          calls++;
          return true;
        },
      );
      expect(result.failureOrNull, isNotNull);
    }
    expect(calls, 0);
  });
  test('cancellation and late invalidation are not reported as successful printing', () async {
    final pdf = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55, 10]);
    expect(
      (await dispatchPdfDocument(
        pdf,
        '出库单.pdf',
        () => true,
        (bytes, name, guard) async => false,
      )).failureOrNull?.code,
      'device.pdf_not_accepted',
    );
    var current = true;
    expect(
      (await dispatchPdfDocument(pdf, '出库单.pdf', () => current, (
        bytes,
        name,
        guard,
      ) async {
        current = false;
        expect(guard(), false);
        return true;
      })).failureOrNull?.code,
      'device.pdf_result_unknown',
    );
  });
  test(
    'dispatch exception after scope loss stays unknown, not safe to retry',
    () async {
      final pdf = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55, 10]);
      var current = true;
      var dispatched = 0;
      final result = await dispatchPdfDocument(pdf, '出库单.pdf', () => current, (
        bytes,
        name,
        guard,
      ) async {
        dispatched++;
        current = false;
        throw StateError('platform result unavailable after handoff');
      });
      current =
          true; // Returning from the covering page must not make retry safe.
      expect(dispatched, 1);
      expect(result.failureOrNull?.code, 'device.pdf_result_unknown');
    },
  );
  test('confirmed cancellation remains retryable after scope loss', () async {
    final pdf = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55, 10]);
    var current = true;
    final result = await dispatchPdfDocument(pdf, '出库单.pdf', () => current, (
      bytes,
      name,
      guard,
    ) async {
      current = false;
      return false;
    });
    expect(result.failureOrNull?.code, 'device.pdf_not_accepted');
  });
  test(
    'scope already lost before dispatch is context changed with no side effect',
    () async {
      final pdf = Uint8List.fromList([37, 80, 68, 70, 45, 49, 46, 55, 10]);
      var dispatched = 0;
      final result = await dispatchPdfDocument(pdf, '出库单.pdf', () => false, (
        bytes,
        name,
        guard,
      ) async {
        dispatched++;
        return true;
      });
      expect(dispatched, 0);
      expect(result.failureOrNull?.code, 'device.pdf_context_changed');
    },
  );
}
