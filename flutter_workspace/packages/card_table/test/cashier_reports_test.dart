import 'package:card_table/src/cashier_reports.dart';
import 'package:card_table/src/cashier_reports_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets(
    'cashier cocktail amounts remain complete in a 390-wide viewport',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '鸡尾酒汇总表',
            onLoadData: (_, _, _, _) async => const Success([
              CashierReportRow(
                id: '1',
                cells: {'点单金额': '原价：10000000.00\n方案价：9000000.00'},
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final amount = tester.widget<Text>(
        find.text('原价：10000000.00\n方案价：9000000.00'),
      );
      expect(amount.overflow, isNull);
      expect(amount.maxLines, isNull);
      final horizontal = tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .where((w) => w.scrollDirection == Axis.horizontal)
          .first;
      expect(horizontal.controller!.position.maxScrollExtent, greaterThan(0));
      horizontal.controller!.jumpTo(
        horizontal.controller!.position.maxScrollExtent,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  test('CashierReportCatalog covers all 37 cashier reports', () {
    expect(CashierReportCatalog.reports.length, greaterThanOrEqualTo(37));
    expect(CashierReportCatalog.reports.containsKey('班结表'), isTrue);
    expect(CashierReportCatalog.reports.containsKey('售出日报表'), isTrue);
    expect(CashierReportCatalog.reports.containsKey('商品出库表'), isTrue);
    expect(CashierReportCatalog.reports.containsKey('支付记录'), isTrue);
    expect(CashierReportCatalog.reports.containsKey('区域实时营收'), isTrue);
    expect(CashierReportCatalog.reports.containsKey('业绩日报表'), isTrue);
    expect(CashierReportCatalog.reports.containsKey('低消进度统计表'), isTrue);
    expect(CashierReportCatalog.reports.containsKey('鸡尾酒明细表'), isTrue);
    expect(CashierReportCatalog.reports.containsKey('估清商品'), isTrue);
  });

  testWidgets('CashierReportScreen renders columns and loaded data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '鸡尾酒汇总表',
          onLoadData: (title, start, end, keyword) async => const Success([
            CashierReportRow(
              id: '1',
              cells: {
                '序号': '1',
                '点单人部门': '早班',
                '点单人': '张收银',
                '点单金额': '12500.00',
              },
            ),
          ]),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('鸡尾酒汇总表'), findsOneWidget);
    expect(find.text('早班'), findsOneWidget);
    expect(find.text('张收银'), findsOneWidget);
    expect(find.text('12500.00'), findsOneWidget);
    expect(find.text('共计 1 条记录'), findsOneWidget);
  });
}
