import 'management_permission_fixture.dart';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bms_nav_screen_test.dart' show FakeBmsLoader;
import 'erp_nav_screen_test.dart' show FakeErpLoader;

void main() {
  for (final entry in ['其他入库', '其他出库']) {
    testWidgets('$entry cannot submit synthetic materials', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: entry == '其他入库'
                ? ErpAnotherInLibView(loader: FakeErpLoader())
                : ErpAnotherOutLibView(loader: FakeErpLoader()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('新建$entry单'));
      await tester.pumpAndSettle();
      expect(find.text('仓库数据未就绪'), findsOneWidget);
      expect(find.text('添加物料'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                entry == '其他入库' ? '提交入库' : '提交出库',
              ),
            )
            .onPressed,
        isNull,
      );
    });
  }

  testWidgets('BMS does not pretend to change a password', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: BmsNavScreen(
          permissions: managementTestPermissions(),
          safeModeEnabled: false,
          loader: FakeBmsLoader(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改密码'));
    await tester.pumpAndSettle();
    expect(find.textContaining('尚未接入'), findsOneWidget);
    expect(find.text('确认修改'), findsNothing);
    expect(find.text('密码修改成功'), findsNothing);
  });
}
