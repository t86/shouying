import 'dart:async';

import 'package:card_table/src/cashier_profit_loss.dart';
import 'package:card_table/src/cashier_profit_loss_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

CashierProfitLossCatalog catalog() => CashierProfitLossCatalog(
  libraries: {'1': '酒库', '2': '餐库'},
  productsByLibrary: {
    '1': [
      const CashierProfitLossProduct(
        id: '7',
        name: '啤酒',
        firstCategory: '酒水',
        secondCategory: '啤酒类',
      ),
    ],
    '2': [
      const CashierProfitLossProduct(
        id: '8',
        name: '小吃',
        firstCategory: '餐点',
        secondCategory: '小食',
      ),
    ],
  },
);
void main() {
  Future<void> open(
    WidgetTester tester, {
    required Future<Result<void>> Function(
      CashierProfitLossDraft,
      bool Function(),
    )
    submit,
    ValueNotifier<CashierProfitLossCatalog>? metadata,
    ValueNotifier<bool>? access,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CashierProfitLossScreen(
          catalog: metadata ?? ValueNotifier(catalog()),
          canOperate: access ?? ValueNotifier(true),
          load: () async => const Success(<CashierProfitLossRecord>[]),
          submit: submit,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加盘盈盘亏单'));
    await tester.pumpAndSettle();
  }

  void choose(WidgetTester tester, String key, String value) => tester
      .widget<DropdownButtonFormField<String>>(find.byKey(ValueKey(key)))
      .onChanged!(value);
  testWidgets(
    'mobile product search filters candidates while retaining selected row',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, submit: (draft, guard) async => const Success(null));
      choose(tester, 'profit-library', '1');
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('profit-product-search')),
        '不存在',
      );
      await tester.pump();
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.descendant(
                of: find.byKey(const ValueKey('profit-product-0')),
                matching: find.byType(DropdownButton<String>),
              ),
            )
            .items,
        isEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('profit-product-search')),
        '啤',
      );
      await tester.pump();
      choose(tester, 'profit-product-0', '7');
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('profit-product-search')),
        '不存在',
      );
      await tester.pump();
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.descendant(
                of: find.byKey(const ValueKey('profit-product-0')),
                matching: find.byType(DropdownButton<String>),
              ),
            )
            .items!
            .single
            .value,
        '7',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'business rejection preserves draft; successful retry closes editor and refreshes records',
    (tester) async {
      var calls = 0, loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CashierProfitLossScreen(
            catalog: ValueNotifier(catalog()),
            canOperate: ValueNotifier(true),
            load: () async {
              loads++;
              return const Success(<CashierProfitLossRecord>[]);
            },
            submit: (draft, guard) async {
              calls++;
              expect(draft.entries.single.profit, 3);
              return calls == 1
                  ? const FailureResult(
                      AppFailure(
                        kind: FailureKind.business,
                        code: 'reject',
                        safeMessage: '拒绝',
                      ),
                    )
                  : const Success(null);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('添加盘盈盘亏单'));
      await tester.pumpAndSettle();
      choose(tester, 'profit-library', '1');
      await tester.pump();
      choose(tester, 'profit-product-0', '7');
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('profit-count-0')), '3');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('profit-count-0')))
            .controller!
            .text,
        '3',
      );
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(loads, 2);
      expect(find.text('确定'), findsNothing);
    },
  );
  testWidgets(
    'three rows, at least one retained, library change clears choices',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await open(tester, submit: (draft, guard) async => const Success(null));
      expect(find.byType(TextField), findsNWidgets(7));
      choose(tester, 'profit-library', '1');
      await tester.pump();
      choose(tester, 'profit-product-0', '7');
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('profit-count-0')), '3');
      choose(tester, 'profit-library', '2');
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('profit-count-0')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.ensureVisible(find.byKey(const ValueKey('profit-remove-2')));
      await tester.tap(find.byKey(const ValueKey('profit-remove-2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('profit-remove-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('profit-remove-0')));
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(3));
    },
  );
  testWidgets(
    'only selected rows submit and uncertain response locks duplicate writes',
    (tester) async {
      var calls = 0;
      await open(
        tester,
        submit: (draft, guard) async {
          calls++;
          expect(guard(), true);
          expect(draft.entries.length, 1);
          expect(draft.entries.single.profit, -2);
          expect(draft.entries.single.loss, 0);
          return const FailureResult(
            AppFailure(
              kind: FailureKind.network,
              code: 'timeout',
              safeMessage: '超时',
            ),
          );
        },
      );
      choose(tester, 'profit-library', '1');
      await tester.pump();
      choose(tester, 'profit-product-0', '7');
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('profit-count-0')),
        '-2',
      );
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.textContaining('结果尚未确认'), findsOneWidget);
    },
  );
  testWidgets('metadata or access changes invalidate editor permanently', (
    tester,
  ) async {
    final metadata = ValueNotifier(catalog());
    final access = ValueNotifier(true);
    var calls = 0;
    await open(
      tester,
      metadata: metadata,
      access: access,
      submit: (draft, guard) async {
        calls++;
        return const Success(null);
      },
    );
    choose(tester, 'profit-library', '1');
    await tester.pump();
    choose(tester, 'profit-product-0', '7');
    await tester.pump();
    metadata.value = catalog();
    access.value = false;
    access.value = true;
    await tester.pump();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(calls, 0);
  });
  testWidgets(
    'back invalidates callback before reverse transition and late success does not refresh',
    (tester) async {
      final pending = Completer<Result<void>>();
      bool Function()? captured;
      await open(
        tester,
        submit: (draft, guard) {
          captured = guard;
          return pending.future;
        },
      );
      choose(tester, 'profit-library', '1');
      await tester.pump();
      choose(tester, 'profit-product-0', '7');
      await tester.pump();
      await tester.tap(find.text('确定'));
      await tester.pump();
      Navigator.of(tester.element(find.text('取消'))).pop();
      await tester.pump();
      expect(captured!(), false);
      pending.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('添加盘盈盘亏单'), findsOneWidget);
    },
  );
}
