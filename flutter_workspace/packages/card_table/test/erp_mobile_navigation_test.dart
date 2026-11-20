import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:permissions/permissions.dart';
import 'package:protocol/protocol.dart';

import 'erp_nav_screen_test.dart' show FakeErpLoader;

class FailedHomeLoader implements ErpLoader {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Result<List<ErpUnboundPrdAlert>>> loadUnboundPrdAlerts() async => const Success([]);
  @override
  Future<Result<List<ErpNegStoreAlert>>> loadNegStoreAlerts() async =>
      const FailureResult(AppFailure(kind: FailureKind.network,
        code: 'test.offline', safeMessage: '连接未就绪'));
}

void main() {
  testWidgets('failed warehouse reads never claim healthy empty inventory', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: ErpHomeView(loader: FailedHomeLoader()),
    )));
    await tester.pumpAndSettle();
    expect(find.text('ERP 仓库运行正常'), findsNothing);
    expect(find.text('连接未就绪'), findsOneWidget);
  });
  testWidgets(
    'online warehouse shows direct menus but not ungranted extensions on phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var phase = ConnectionPhase.online;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return ErpNavScreen(
                loader: FakeErpLoader(),
                client: ClientKind.erp,
                phase: phase,
            initialPage: 'home',
                permissions: PermissionSnapshot(
                  available: false,
                  roleIds: const [],
                  moduleIds: const [],
                  subPermissions: const [],
                  stationId: null,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('打开仓库菜单'));
      await tester.pumpAndSettle();
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('空瓶管理'), findsNothing);
      expect(find.text('物料管理'), findsNothing);
      update(() => phase = ConnectionPhase.blocked);
      await tester.pumpAndSettle();
      expect(find.text('首页'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
