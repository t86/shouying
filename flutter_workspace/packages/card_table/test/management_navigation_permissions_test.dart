import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:permissions/permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

import 'management_permission_fixture.dart';

void main() {
  for (final wine in [false, true]) {
    testWidgets(
      '${wine ? 'Wine' : 'ERP'} revocation closes owned dialogs and unloads current body',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final observer = ManagementRouteObserver();
        final erp = CountingErp(), wineLoader = CountingWine();
        PermissionSnapshot? permissions = managementTestPermissions();
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [observer],
            home: StatefulBuilder(
              builder: (context, setter) {
                update = setter;
                return wine
                    ? WineNavScreen(
                        loader: wineLoader,
                        routeObserver: observer,
                        permissions: permissions,
                      )
                    : ErpNavScreen(
                        loader: erp,
                        routeObserver: observer,
                        permissions: permissions,
                        initialPage: 'erpLib',
                      );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(Scaffold).first);
        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => const AlertDialog(title: Text('业务页弹窗')),
          ),
        );
        await tester.pumpAndSettle();
        update(() => permissions = null);
        await tester.pumpAndSettle();
        expect(find.text('业务页弹窗'), findsNothing);
        expect(
          find.text(wine ? '权限数据尚未就绪，请等待同步或检查连接' : '当前页面不可用或暂无权限'),
          findsWidgets,
        );
        expect(erp.loads + wineLoader.loads, 1);
      },
    );
  }
  Future<void> wide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'missing permissions fail closed and initial URLs cannot load data',
    (tester) async {
      await wide(tester);
      final bms = CountingBms(), erp = CountingErp(), wine = CountingWine();
      for (final screen in <Widget>[
        BmsNavScreen(loader: bms, initialPage: 'stationConfig'),
        ErpNavScreen(loader: erp, initialPage: 'erpLib'),
        WineNavScreen(loader: wine, initialPath: '/wine/saveNeedToLib'),
      ]) {
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();
        expect(
          find.text(
            screen is WineNavScreen ? '权限数据尚未就绪，请等待同步或检查连接' : '当前页面不可用或暂无权限',
          ),
          findsWidgets,
        );
      }
      expect(bms.loads + erp.loads + wine.loads, 0);
    },
  );
  testWidgets('safe mode hides personnel and blocks its direct initial page', (
    tester,
  ) async {
    await wide(tester);
    final loader = CountingBms();
    await tester.pumpWidget(
      MaterialApp(
        home: BmsNavScreen(
          loader: loader,
          permissions: managementTestPermissions(),
          initialPage: 'stationConfig',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('人员管理'), findsNothing);
    expect(loader.loads, 0);
    expect(find.text('当前页面不可用或暂无权限'), findsOneWidget);
  });
  testWidgets(
    'ERP warehouse sees operational groups, empty bottles require module25, admin sees all',
    (tester) async {
      await wide(tester);
      final loader = CountingErp();
      Future<void> show(ClientKind client, List<int> modules) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ErpNavScreen(
              loader: loader,
              client: client,
              permissions: managementTestPermissions(modules: modules),
              initialPage: 'erpLib',
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(ClientKind.erp, []);
      expect(find.text('仓库管理'), findsNothing);
      expect(find.text('物料管理'), findsNothing);
      expect(find.text('供应商管理'), findsNothing);
      expect(find.text('空瓶管理'), findsNothing);
      expect(find.text('入库管理'), findsOneWidget);
      expect(loader.loads, 0);
      await show(ClientKind.erp, [25]);
      expect(find.text('空瓶管理'), findsOneWidget);
      expect(loader.loads, 0);
      await show(ClientKind.erpAdmin, []);
      expect(find.text('仓库管理'), findsWidgets);
      expect(find.text('供应商管理'), findsOneWidget);
      expect(find.text('空瓶管理'), findsOneWidget);
      expect(loader.loads, 1);
    },
  );
  testWidgets('ordinary Wine needs no role10 for its own groups', (
    tester,
  ) async {
    await wide(tester);
    final loader = CountingWine();
    await tester.pumpWidget(
      MaterialApp(
        home: WineNavScreen(
          loader: loader,
          permissions: managementTestPermissions(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loader.loads, 1);
    for (final name in ['存酒管理', '充公管理', '用户管理', '客户中心存酒', '报表管理', '存酒借还']) {
      expect(find.text(name), findsWidgets);
    }
  });
  testWidgets('revoking BMS personnel access removes body and its open form', (
    tester,
  ) async {
    await wide(tester);
    final loader = CountingBms();
    var safe = false;
    late StateSetter update;
    final observer = ManagementRouteObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: StatefulBuilder(
          builder: (context, setter) {
            update = setter;
            return BmsNavScreen(
              loader: loader,
              routeObserver: observer,
              permissions: managementTestPermissions(),
              safeModeEnabled: safe,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('bms-station-add-btn')));
    await tester.pumpAndSettle();
    expect(find.text('新建岗位'), findsOneWidget);
    update(() => safe = true);
    await tester.pumpAndSettle();
    expect(find.text('新建岗位'), findsNothing);
    expect(find.text('当前页面不可用或暂无权限'), findsOneWidget);
    expect(loader.loads, 1);
  });
  testWidgets('revocation never pops an unrelated login page pushed later', (
    tester,
  ) async {
    await wide(tester);
    final nav = GlobalKey<NavigatorState>();
    var safe = false;
    late StateSetter update;
    final observer = ManagementRouteObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        navigatorObservers: [observer],
        home: StatefulBuilder(
          builder: (context, setter) {
            update = setter;
            return BmsNavScreen(
              loader: CountingBms(),
              routeObserver: observer,
              permissions: managementTestPermissions(),
              safeModeEnabled: safe,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('新登录页')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      showDialog<void>(
        context: tester.element(find.text('新登录页')),
        builder: (_) => const AlertDialog(title: Text('登录页弹窗')),
      ),
    );
    await tester.pumpAndSettle();
    update(() => safe = true);
    await tester.pumpAndSettle();
    expect(find.text('新登录页'), findsOneWidget);
    expect(find.text('登录页弹窗'), findsOneWidget);
  });
  testWidgets(
    'SMS detail and its nested dialog close precisely on permission revocation',
    (tester) async {
      await wide(tester);
      final observer = ManagementRouteObserver();
      final loader = CountingBms();
      PermissionSnapshot? permissions = managementTestPermissions();
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: StatefulBuilder(
            builder: (context, setter) {
              update = setter;
              return BmsNavScreen(
                loader: loader,
                routeObserver: observer,
                permissions: permissions,
                safeModeEnabled: false,
                initialPage: 'messageDetail',
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bms-sms-bill-7')));
      await tester.pumpAndSettle();
      expect(loader.detailLoads, 1);
      final context = tester.element(find.byType(Scaffold).last);
      expect(
        ModalRoute.of(context)?.settings.name,
        ManagementRouteObserver.childRouteName,
      );
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('短信详情弹窗')),
        ),
      );
      await tester.pumpAndSettle();
      update(() => permissions = null);
      await tester.pumpAndSettle();
      expect(find.text('短信详情弹窗'), findsNothing);
      expect(find.text('当前页面不可用或暂无权限'), findsOneWidget);
      expect(find.byKey(const Key('bms-sms-bill-7')), findsNothing);
      expect(loader.detailLoads, 1);
    },
  );
}

class CountingBms implements BmsLoader {
  int loads = 0;
  int detailLoads = 0;
  @override
  Future<Result<BmsSmsBillPage>> loadSmsBills({
    required String startDay,
    required String endDay,
    int type = 0,
    int page = 1,
    int pageSize = 20,
  }) async =>
      const Success(BmsSmsBillPage(records: [BmsSmsBill(id: '7')], total: 1));
  @override
  Future<Result<BmsSmsDeliveryPage>> loadSmsRecordDetails({
    required String recordId,
    int status = 0,
    String mobile = '',
    int page = 1,
    int pageSize = 20,
    bool initialize = true,
    List<Map<String, Object?>> templates = const [],
  }) async {
    detailLoads++;
    return const Success(BmsSmsDeliveryPage());
  }

  @override
  Future<Result<List<BmsStationItem>>> loadStations({
    String keyword = '',
  }) async {
    loads++;
    return const Success([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CountingErp implements ErpLoader {
  int loads = 0;
  @override
  Future<Result<List<ErpStoreItem>>> loadStores() async {
    loads++;
    return const Success([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CountingWine implements WineLoader {
  int loads = 0;
  @override
  Future<Result<List<WineSaveRecord>>> loadSaveNeedToLib({
    String keyword = '',
  }) async {
    loads++;
    return const Success([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
