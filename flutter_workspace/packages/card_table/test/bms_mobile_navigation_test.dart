import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:permissions/permissions.dart';
import 'bms_nav_screen_test.dart' show FakeBmsLoader;

void main() {
  testWidgets('default landing selects visible page and disconnect unloads it', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var phase = ConnectionPhase.online;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      update = setState;
      return BmsNavScreen(loader: FakeBmsLoader(), phase: phase,
        permissions: PermissionSnapshot(available: false, roleIds: const [],
          moduleIds: const [], subPermissions: const [], stationId: null),
        initialPage: null);
    })));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bms-prd-item-p_1')), findsOneWidget);
    expect(find.text('当前页面不可用或暂无权限'), findsNothing);
    expect(tester.takeException(), isNull);
    update(() => phase = ConnectionPhase.blocked);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bms-prd-item-p_1')), findsNothing);
    expect(find.text('连接尚未就绪，请等待恢复后重试'), findsOneWidget);
  });
  testWidgets('online BMS direct menus survive missing role metadata on phone', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: BmsNavScreen(
      loader: FakeBmsLoader(),
      phase: ConnectionPhase.online,
      permissions: PermissionSnapshot(available: false, roleIds: const [],
        moduleIds: const [], subPermissions: const [], stationId: null),
      initialPage: 'unknown',
      userName: '一个很长的管理员名称用于验证手机布局',
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('打开门店后台菜单'));
    await tester.pumpAndSettle();
    expect(find.text('商品管理'), findsWidgets);
    expect(find.text('人员管理'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
