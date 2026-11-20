import 'dart:async';

import 'management_permission_fixture.dart';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:permissions/permissions.dart';

final class _MockWineLoader implements WineLoader {
  @override
  Future<Result<List<Map<String,Object?>>>> loadWineBorrowEmployees(String query) async => const Success([]);
  @override
  Future<Result<List<Map<String,Object?>>>> loadWineReturnOptions({String keyword = ''}) async => const Success([]);
  _MockWineLoader({this.populated = false});
  final bool populated;
  int saveLoads = 0;
  @override
  Future<Result<List<WineSaveRecord>>> loadSaveNeedToLib({
    String keyword = '',
  }) async {
    saveLoads++;
    return const Success([]);
  }

  @override
  Future<Result<void>> confirmSaveNeedToLib(List<String> ids) async =>
      const Success(null);

  @override
  Future<Result<void>> backSaveNeedToLib(
    List<String> ids, {
    String reason = '',
  }) async => const Success(null);

  @override
  Future<Result<void>> chgSaveNeedToLib(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<Map<String, Object?>>>> loadChgSalesEmpList() async =>
      const Success([]);

  @override
  Future<Result<List<WineGetRecord>>> loadNeedToLib({
    String keyword = '',
  }) async => const Success([]);

  @override
  Future<Result<void>> confirmGetNeedToLib(List<String> ids) async =>
      const Success(null);

  @override
  Future<Result<void>> backGetNeedToLib(
    List<String> ids, {
    String reason = '',
  }) async => const Success(null);

  @override
  Future<Result<void>> confirmAuthGetNeedToLib(
    Map<String, Object?> fields,
  ) async => const Success(null);

  @override
  Future<Result<List<WineInventoryItem>>> loadSaveLibList({
    String startDate = '',
    String endDate = '',
    int daysLeft = 0,
    String keyword = '',
  }) async => const Success([]);

  @override
  Future<Result<void>> delayWineInvt({
    required String id,
    required int days,
    String reason = '',
  }) async => const Success(null);

  @override
  Future<Result<void>> cgWineInvt(List<String> ids) async =>
      const Success(null);

  @override
  Future<Result<List<WineInventoryItem>>> loadSaveLibChildList({
    String startDate = '',
    String endDate = '',
    String keyword = '',
  }) async => const Success([]);

  @override
  Future<Result<List<WineInventoryItem>>> loadPassTimeNeedToLib({
    String keyword = '',
  }) async => Success(
    populated
        ? const [
            WineInventoryItem(
              id: '1',
              customerName: '窄屏测试客户姓名',
              customerPhone: '13800000000',
              seatName: '测试卡台A01',
              salesName: '测试订台员工',
              saveTime: '2026-09-20 12:00:00',
            ),
          ]
        : [],
  );

  @override
  Future<Result<void>> cgExpiredWineInvt(List<String> ids) async =>
      const Success(null);

  @override
  Future<Result<void>> delayExpiredWineInvt({
    required String id,
    required int days,
    String reason = '',
  }) async => const Success(null);

  @override
  Future<Result<List<WineGridItem>>> loadSaveLibGrid({
    String keyword = '',
  }) async => const Success([]);

  @override
  Future<Result<List<WineInventoryItem>>> loadSaveLibGridDetail(
    String prdId,
  ) async => const Success([]);

  @override
  Future<Result<void>> exportWineInvtExpired({
    String keyword = '',
    int ordType = 1,
  }) async => const Success(null);

  @override
  Future<Result<void>> exportExcelOfGridReport({String keyword = ''}) async =>
      const Success(null);

  @override
  Future<Result<void>> exportUnreturnedWineList({String keyword = ''}) async =>
      const Success(null);

  @override
  Future<Result<void>> exportWineDetailList({
    String startTime = '',
    String endTime = '',
    String keyword = '',
    int daysLeft = 0,
  }) async => const Success(null);

  @override
  Future<Result<List<WineConfiscateItem>>> loadNeedToStoreList({
    String keyword = '',
  }) async => Success(
    populated
        ? const [
            WineConfiscateItem(
              id: '1',
              seatName: '测试卡台A01',
              customerName: '窄屏测试客户姓名',
              customerPhone: '13800000000',
              salesName: '测试充公员工',
              wineName: '测试酒水',
              unit: '瓶',
              count: 1,
              expireTime: '2026-09-20 12:00:00',
            ),
          ]
        : [],
  );

  @override
  Future<Result<void>> backToStoreList(List<String> ids) async =>
      const Success(null);

  @override
  Future<Result<void>> confirmToStoreList(List<String> ids) async =>
      const Success(null);

  @override
  Future<Result<void>> confirmAuthToStoreList(
    Map<String, Object?> fields,
  ) async => const Success(null);

  @override
  Future<Result<void>> chgCsmCgBefIn(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<WineConfiscateItem>>> loadStoreLibList({
    String keyword = '',
  }) async => const Success([]);

  @override
  Future<Result<void>> newCgOut(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<WineConfiscateItem>>> loadToStoreDetailList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
    String startDate = '',
    String endDate = '',
  }) async => const Success([]);

  @override
  Future<Result<Map<String, Object?>>> loadToStoreOrderDetail(
    String orderId,
  ) async => const Success({});

  @override
  Future<Result<void>> toStoreToHc(String orderId) async => const Success(null);

  @override
  Future<Result<List<WineCustomerItem>>> loadCustomList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
  }) async => const Success([]);

  @override
  Future<Result<void>> openOrCloseMsg({
    required List<String> custIds,
    required bool enable,
  }) async => const Success(null);

  @override
  Future<Result<void>> updateCustomName({
    required String custId,
    required String name,
  }) async => const Success(null);

  @override
  Future<Result<bool>> validatePhoneNum(String phone) async =>
      const Success(true);

  @override
  Future<Result<void>> updateCustomPhoneNum({
    required String custId,
    required String phone,
  }) async => const Success(null);

  @override
  Future<Result<List<WineBlacklistItem>>> loadBlackList({
    String keyword = '',
  }) async => const Success([]);

  @override
  Future<Result<void>> addBlackList({
    required List<String> phones,
    String remark = '',
  }) async => const Success(null);

  @override
  Future<Result<void>> deleteBlackList(List<String> ids) async =>
      const Success(null);

  @override
  Future<Result<List<WineSaveRecord>>> loadCustomCenterSaveWineList({
    String keyword = '',
  }) async => const Success([]);

  @override
  Future<Result<List<WineInventoryItem>>> loadCustomCenterGetWineList({
    String phone = '',
    String seatId = '',
  }) async => const Success([]);

  @override
  Future<Result<List<Map<String, Object?>>>> loadCustomCenterSeatList() async =>
      const Success([]);

  @override
  Future<Result<void>> submitCustomCenterGetWine(
    Map<String, Object?> fields,
  ) async => const Success(null);

  @override
  Future<Result<List<WineReportRow>>> loadReportData({
    required String path,
    Map<String, Object?> params = const {},
  }) async => const Success([]);

  @override
  Future<Result<void>> printSaveAndGetWineList(String id) async =>
      const Success(null);

  @override
  Future<Result<List<WineBorrowReturnItem>>> loadWineBorrowReturnList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
    int type = 0,
  }) async => const Success([]);

  @override
  Future<Result<List<Map<String, Object?>>>> loadWineCanBorrowList({
    String keyword = '',
  }) async => const Success([]);

  @override
  Future<Result<void>> submitWineBorrow(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<void>> submitWineReturn(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<WineBorrowReturnItem>>> loadWineBorrowInvtList({
    String keyword = '',
  }) async => const Success([]);
}

void main() {
  for (final path in [
    'saveNeedToLib',
    'getNeedToLib',
    'saveLib',
    'saveLibChild',
    'passTime',
    'saveLibAllData',
    'toStore',
    'storeLib',
    'toStoreDetail',
    'userConfig',
    'customSaveLib',
    'customGetLib',
    'saveAndGetReport',
    'passTimeLongReport',
    'toStoreOutReport',
    'saveAllDataReport',
    'getAllDataReport',
    'toStoreAllDataReport',
    'saveWineSearch',
    'nowInvtReport',
    'borrowWine',
    'returnWine',
    'unreturnedWine',
  ]) {
    testWidgets('phone wine route $path has no overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: WineNavScreen(
            loader: _MockWineLoader(populated: true),
            permissions: managementTestPermissions(),
            safeModeEnabled: false,
            phase: ConnectionPhase.online,
            initialPath: '/wine/$path',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('打开存酒菜单'), findsOneWidget);
      final actions = find.byWidgetPredicate(
        (widget) => widget is ButtonStyleButton,
      );
      for (var i = 0; i < actions.evaluate().length; i++) {
        await tester.ensureVisible(actions.at(i));
        await tester.pumpAndSettle();
        expect(
          actions.at(i).hitTestable(),
          findsOneWidget,
          reason: '$path action $i must be reachable without submitting',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'online direct wine works without metadata and disconnect closes owned dialog',
    (tester) async {
      final loader = _MockWineLoader();
      final observer = ManagementRouteObserver();
      var phase = ConnectionPhase.online;
      late StateSetter update;
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return WineNavScreen(
                loader: loader,
                phase: phase,
                routeObserver: observer,
                safeModeEnabled: false,
                permissions: PermissionSnapshot(
                  available: false,
                  roleIds: const [],
                  moduleIds: const [],
                  subPermissions: const [],
                  stationId: 1,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('存酒待入库'), findsWidgets);
      expect(loader.saveLoads, 1);
      final context = tester.element(find.byType(Scaffold).first);
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('待处理操作')),
        ),
      );
      await tester.pumpAndSettle();
      update(() => phase = ConnectionPhase.blocked);
      await tester.pumpAndSettle();
      expect(find.text('待处理操作'), findsNothing);
      expect(find.text('连接尚未就绪，请等待恢复后重试'), findsOneWidget);
      expect(loader.saveLoads, 1);
      expect(find.text('存酒待入库'), findsNothing);
    },
  );
  testWidgets('phone drawer reaches authorized wine pages without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: WineNavScreen(
          loader: _MockWineLoader(),
          permissions: managementTestPermissions(),
          safeModeEnabled: false,
          initialPath: '/wine/unknown',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('打开存酒菜单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('存酒管理').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('存酒待入库').first);
    await tester.pumpAndSettle();
    expect(find.text('存酒管理 · 存酒待入库'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('打开存酒菜单'));
    await tester.pumpAndSettle();
    expect(find.text('报表管理'), findsOneWidget);
    expect(find.text('存酒借还'), findsOneWidget);
    await tester.tap(find.text('取酒待出库').first);
    await tester.pumpAndSettle();
    expect(find.text('存酒管理 · 取酒待出库'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unknown permissions are explicit and do not claim online', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: WineNavScreen(loader: _MockWineLoader())),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('权限数据尚未就绪'), findsOneWidget);
    expect(find.text('在线'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('WineNavScreen renders navigation items and responds to onBack', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var backCalled = 0;
    final loader = _MockWineLoader();

    await tester.pumpWidget(
      MaterialApp(
        home: WineNavScreen(
          permissions: managementTestPermissions(),
          safeModeEnabled: false,
          loader: loader,
          initialPath: '/wine/saveNeedToLib',
          onBack: () => backCalled += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Logout button
    expect(find.text('存酒管理系统'), findsOneWidget);
    expect(find.byTooltip('退出存酒系统'), findsOneWidget);

    // Verify Left Nav Groups
    expect(find.text('存酒管理'), findsWidgets);
    expect(find.text('充公管理'), findsWidgets);
    expect(find.text('用户管理'), findsWidgets);
    expect(find.text('客户中心存酒'), findsWidgets);
    expect(find.text('报表管理'), findsWidgets);
    expect(find.text('存酒借还'), findsWidgets);

    // Initial selected is 存酒待入库
    expect(find.text('存酒待入库'), findsWidgets);

    // Click onBack
    await tester.tap(find.byTooltip('退出存酒系统'));
    await tester.pumpAndSettle();
    expect(backCalled, 1);
  });

  testWidgets('WineNavScreen can switch to other pages via navigation items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final loader = _MockWineLoader();

    await tester.pumpWidget(
      MaterialApp(
        home: WineNavScreen(
          permissions: managementTestPermissions(),
          safeModeEnabled: false,
          loader: loader,
          initialPath: '/wine/toStore',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // In 待充公
    expect(find.text('待充公'), findsWidgets);

    // Switch to 充公库
    await tester.tap(find.text('充公库').first);
    await tester.pumpAndSettle();
    expect(find.text('充公出库'), findsOneWidget);

    // Switch to 存酒借还 -> 借酒
    await tester.tap(find.text('存酒借还').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('借酒').first);
    await tester.pumpAndSettle();
    expect(find.text('新增借酒'), findsOneWidget);
  });
}
