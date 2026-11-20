import 'dart:async';

import 'package:card_table/src/cocktail_detail_report.dart';
import 'package:card_table/src/cocktail_detail_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets(
    '390 width preserves both historical amount lines with horizontal scroll',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final access = ValueNotifier(true);
      addTearDown(access.dispose);
      await _pump(
        tester,
        access,
        (_) async => Success([
          CocktailDetailReportRow.fromWire({
            'rn': 'A',
            'a': '9000000.00',
            'sa': '10000000.00',
          }),
          CocktailDetailReportRow.fromWire({
            'rn': '合计',
            'a': '9000000.00',
            'sa': '10000000.00',
          }),
        ]),
      );
      await tester.pumpAndSettle();
      final amount = find.text('原价：10000000.00\n方案价：9000000.00');
      expect(amount, findsNWidgets(2));
      expect(tester.widget<Text>(amount.first).maxLines, isNull);
      expect(tester.widget<Text>(amount.first).overflow, isNull);
      final horizontal = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .where((w) => w.scrollDirection == Axis.horizontal)
          .first;
      expect(horizontal.controller!.position.maxScrollExtent, greaterThan(0));
      horizontal.controller!.jumpTo(2000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('shows source columns, search, and no export', (tester) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    var calls = 0;
    String? keyword;
    await _pump(tester, canRead, (value) async {
      calls++;
      keyword = value;
      return Success([_row(), _total()]);
    });
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(keyword, '');
    expect(find.text('鸡尾酒明细表'), findsOneWidget);
    expect(find.text('订台人/点单人/商品名称'), findsOneWidget);
    expect(find.text('查询'), findsOneWidget);
    expect(find.text('重置'), findsOneWidget);
    for (final label in CocktailDetailReportRow.columnLabels) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('>>'), findsWidgets);
    expect(find.text('莫吉托'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('合计'), findsOneWidget);
    expect(find.text('30.50'), findsOneWidget);
    expect(find.textContaining('导出'), findsNothing);
    expect(find.textContaining('待接入'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('query sends the typed keyword and reset clears it', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final keywords = <String>[];
    await _pump(tester, canRead, (value) async {
      keywords.add(value);
      return Success([_row()]);
    });
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CocktailDetailReportScreen.keywordKey),
      '莫吉托',
    );
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重置'));
    await tester.pumpAndSettle();
    expect(keywords, ['', '莫吉托', '']);
    expect(
      tester
          .widget<TextField>(find.byKey(CocktailDetailReportScreen.keywordKey))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('total row leaves the sequence number blank', (tester) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    await _pump(tester, canRead, (_) async => Success([_total()]));
    await tester.pumpAndSettle();
    expect(find.text('合计'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('displays safe failures and queries again', (tester) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    var calls = 0;
    await _pump(tester, canRead, (_) async {
      calls++;
      return calls == 1 ? const FailureResult(_safeFailure) : Success([_row()]);
    });
    await tester.pumpAndSettle();
    expect(find.text(_safeFailure.safeMessage), findsOneWidget);
    expect(find.text('莫吉托'), findsNothing);
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('莫吉托'), findsOneWidget);
  });

  testWidgets('losing read access removes loaded rows', (tester) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    await _pump(tester, canRead, (_) async => Success([_row()]));
    await tester.pumpAndSettle();
    canRead.value = false;
    await tester.pump();
    expect(find.text('莫吉托'), findsNothing);
    expect(find.text('当前不可查询鸡尾酒明细表'), findsOneWidget);
    canRead.value = true;
    await tester.pumpAndSettle();
    expect(find.text('莫吉托'), findsNothing);
  });

  testWidgets('false then true invalidates in-flight responses until query', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final old = Completer<Result<List<CocktailDetailReportRow>>>();
    var calls = 0;
    await _pump(tester, canRead, (_) {
      calls++;
      return calls == 1 ? old.future : Future.value(Success([_row()]));
    });
    canRead.value = false;
    canRead.value = true;
    old.complete(Success([_row(name: '旧行')]));
    await tester.pumpAndSettle();
    expect(find.text('旧行'), findsNothing);
    expect(find.text('莫吉托'), findsNothing);
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    expect(find.text('莫吉托'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  ValueNotifier<bool> canRead,
  CocktailDetailLoader load,
) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData.dark(),
    home: CocktailDetailReportScreen(load: load, canRead: canRead),
  ),
);

CocktailDetailReportRow _row({String name = '莫吉托'}) =>
    CocktailDetailReportRow.fromWire({
      'rn': 'A 区',
      's': 'A01',
      'n': name,
      'a': '10.5',
    });

CocktailDetailReportRow _total() =>
    CocktailDetailReportRow.fromWire({'rn': '合计', 'a': '30.50'});

const AppFailure _safeFailure = AppFailure(
  kind: FailureKind.business,
  code: 'business.cocktail_detail_report_rejected',
  safeMessage: '服务端拒绝查询鸡尾酒明细表，请重试',
);
