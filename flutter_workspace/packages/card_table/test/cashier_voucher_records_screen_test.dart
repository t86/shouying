import 'dart:async';

import 'package:card_table/src/cashier_voucher_records.dart';
import 'package:card_table/src/cashier_voucher_records_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

CashierVoucherRecord record({bool refundable = true}) => CashierVoucherRecord(
  id: '7',
  canCancel: refundable,
  cells: const {'卡券券码': 'code7', '卡券名称': '测试券'},
);
void main() {
  Future<void> show(
    WidgetTester tester, {
    required Future<Result<List<CashierVoucherRecord>>> Function(
      CashierVoucherQuery,
    )
    load,
    required Future<Result<void>> Function(String, bool Function()) cancel,
    ValueNotifier<bool>? access,
  }) async {
    tester.view.physicalSize = const Size(2600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CashierVoucherRecordsScreen(
          canOperate: access ?? ValueNotifier(true),
          load: load,
          cancel: cancel,
          export: (q, g) async => const Success('file.xlsx'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> refund(WidgetTester tester) async {
    await tester.ensureVisible(find.text('退券'));
    await tester.tap(find.text('退券'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'dispatched refund remains locked after permission pulse and late context failure',
    (tester) async {
      final access = ValueNotifier(true), pending = Completer<Result<void>>();
      var writes = 0;
      await show(
        tester,
        access: access,
        load: (q) async => Success([record()]),
        cancel: (id, g) {
          writes++;
          return pending.future;
        },
      );
      await refund(tester);
      expect(writes, 1);
      access.value = false;
      access.value = true;
      await tester.pumpAndSettle();
      pending.complete(
        const FailureResult(
          AppFailure(
            kind: FailureKind.authentication,
            code: 'context_changed',
            safeMessage: '上下文变化',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '退券'))
            .onPressed,
        isNull,
      );
      expect(writes, 1);
      await tester.ensureVisible(find.text('查询'));
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '退券'))
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'back invalidates pending cancellation guard before reverse animation ends',
    (tester) async {
      tester.view.physicalSize = const Size(2600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final nav = GlobalKey<NavigatorState>();
      final pending = Completer<Result<void>>();
      bool Function()? captured;
      var loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: const Scaffold(body: Text('首页')),
        ),
      );
      unawaited(
        nav.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => CashierVoucherRecordsScreen(
              canOperate: ValueNotifier(true),
              load: (q) async {
                loads++;
                return Success([record()]);
              },
              cancel: (id, g) {
                captured = g;
                return pending.future;
              },
              export: (q, g) async => const Success('file.xlsx'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await refund(tester);
      expect(captured!(), true);
      nav.currentState!.pop();
      await tester.pump();
      expect(captured!(), false);
      pending.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(find.text('首页'), findsOneWidget);
    },
  );
  testWidgets(
    'build-phase access pulse invalidates confirmation without setState errors',
    (tester) async {
      tester.view.physicalSize = const Size(2600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final access = ValueNotifier(true), trigger = ValueNotifier(false);
      var pulsed = false, writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: trigger,
            builder: (context, value, child) {
              if (value && !pulsed) {
                pulsed = true;
                access.value = false;
                access.value = true;
              }
              return CashierVoucherRecordsScreen(
                canOperate: access,
                load: (q) async => Success([record()]),
                cancel: (id, g) async {
                  writes++;
                  return const Success(null);
                },
                export: (q, g) async => const Success('file.xlsx'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('退券'));
      await tester.tap(find.text('退券'));
      await tester.pumpAndSettle();
      trigger.value = true;
      await tester.pump();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('refund rechecks fresh row eligibility after confirmation', (
    tester,
  ) async {
    var loads = 0, writes = 0;
    await show(
      tester,
      load: (q) async {
        loads++;
        return Success([record(refundable: loads == 1)]);
      },
      cancel: (id, g) async {
        writes++;
        return const Success(null);
      },
    );
    await refund(tester);
    expect(loads, 2);
    expect(writes, 0);
    expect(find.textContaining('记录已变化'), findsOneWidget);
  });
  testWidgets(
    'uncertain cancellation cannot repeat until explicit successful query',
    (tester) async {
      var writes = 0;
      final access = ValueNotifier(true);
      await show(
        tester,
        access: access,
        load: (q) async => Success([record()]),
        cancel: (id, g) async {
          writes++;
          expect(g(), true);
          return const FailureResult(
            AppFailure(
              kind: FailureKind.network,
              code: 'timeout',
              safeMessage: '超时',
            ),
          );
        },
      );
      await refund(tester);
      expect(writes, 1);
      expect(find.textContaining('结果尚未确认'), findsOneWidget);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '退券'),
      );
      expect(button.onPressed, isNull);
      access.value = false;
      access.value = true;
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '退券'))
            .onPressed,
        isNull,
      );
      expect(writes, 1);
      await tester.ensureVisible(find.text('查询'));
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      await refund(tester);
      expect(writes, 2);
    },
  );
  testWidgets('permission pulse during confirmation sends no refund', (
    tester,
  ) async {
    final access = ValueNotifier(true);
    var writes = 0;
    await show(
      tester,
      access: access,
      load: (q) async => Success([record()]),
      cancel: (id, g) async {
        writes++;
        return const Success(null);
      },
    );
    await tester.ensureVisible(find.text('退券'));
    await tester.tap(find.text('退券'));
    await tester.pumpAndSettle();
    access.value = false;
    access.value = true;
    await tester.pump();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(writes, 0);
  });
}
