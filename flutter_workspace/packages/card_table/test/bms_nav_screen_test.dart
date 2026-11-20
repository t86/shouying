import 'management_permission_fixture.dart';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

final class FakeBmsLoader implements BmsLoader {
  @override
  Future<Result<Map<String,Object?>>> requestFcPrice(BmsFcPriceRequest request) async => const Success({});
  BmsGenRule rule = const BmsGenRule();
  List<BmsStationItem> stations = [
    const BmsStationItem(id: 'st_1', name: '店长', desc: '总管', status: 1),
    const BmsStationItem(
      id: 'st_2',
      name: '服务员',
      desc: '外场',
      status: 1,
      isWaiter: true,
    ),
  ];
  List<BmsEmployeeItem> employees = [
    const BmsEmployeeItem(
      id: 'emp_1',
      name: '李四',
      empNo: '1001',
      phone: '13911112222',
      stationName: '店长',
    ),
  ];
  List<BmsOneCateItem> oneCates = [
    const BmsOneCateItem(id: 'oc_1', name: '酒水类'),
  ];
  List<BmsTwoCateItem> twoCates = [
    const BmsTwoCateItem(id: 'tc_1', oneCateId: 'oc_1', name: '洋酒'),
  ];
  List<BmsProductItem> products = [
    const BmsProductItem(
      id: 'p_1',
      name: '威士忌',
      code: 'W01',
      price: 680,
      oneCateId: 'oc_1',
      twoCateId: 'tc_1',
    ),
  ];
  List<BmsRegionItem> regions = [const BmsRegionItem(id: 'reg_1', name: '卡座区')];
  List<BmsCardItem> seats = [
    const BmsCardItem(
      id: 's_1',
      name: 'V01',
      regionId: 'reg_1',
      minCharge: 1000,
      seatNum: 6,
    ),
  ];

  @override
  Future<Result<BmsGenRule>> loadGenRule() async => Success(rule);

  @override
  Future<Result<void>> saveGenRule(Map<String, Object?> fields) async {
    rule = BmsGenRule.fromWire(fields);
    return const Success(null);
  }

  @override
  Future<Result<List<BmsStationItem>>> loadStations({
    String keyword = '',
  }) async => Success(stations);

  @override
  Future<Result<void>> saveStation(Map<String, Object?> fields) async {
    stations.add(BmsStationItem.fromWire(fields));
    return const Success(null);
  }

  @override
  Future<Result<void>> setStationStatus(String id, bool enable) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteStation(String id) async {
    stations.removeWhere((s) => s.id == id);
    return const Success(null);
  }

  @override
  Future<Result<List<BmsEmployeeItem>>> loadEmployees({
    String keyword = '',
    String stationId = '',
  }) async => Success(employees);

  @override
  Future<Result<void>> saveEmployee(Map<String, Object?> fields) async {
    employees.add(BmsEmployeeItem.fromWire(fields));
    return const Success(null);
  }

  @override
  Future<Result<void>> batchResetEmpPwd(List<String> ids) async =>
      const Success(null);

  @override
  Future<Result<List<BmsOnboardingApprovalItem>>>
  loadOnboardingApprovals() async => const Success([]);

  @override
  Future<Result<void>> auditOnboarding(
    String id,
    bool pass, {
    String remark = '',
  }) async => const Success(null);

  @override
  Future<Result<List<BmsBusinessEmpItem>>> loadBusinessEmployees({
    String keyword = '',
    List<String> deptIds = const [],
  }) async => const Success([]);

  @override
  Future<Result<BmsOnboardingPage>> loadOnboardingPage({
    int status = 1,
    int page = 1,
    int pageSize = 20,
  }) async => const Success(BmsOnboardingPage());
  @override
  Future<Result<void>> auditOnboardingBatch(
    List<String> ids,
    bool pass,
  ) async => const Success(null);
  @override
  Future<Result<void>> saveOnboarding(Map<String, Object?> fields) async =>
      const Success(null);
  @override
  Future<Result<List<BmsDepartmentOption>>> loadDepartments() async =>
      const Success([]);
  @override
  Future<Result<List<BmsEmployeeItem>>> loadUpperEmployees(String name) async =>
      const Success([]);
  @override
  Future<Result<List<BmsEmployeeItem>>> loadBusinessCandidates({
    String keyword = '',
    List<String> deptIds = const [],
  }) async => const Success([]);
  @override
  Future<Result<void>> addBusinessEmployees(List<String> ids) async =>
      const Success(null);

  @override
  Future<Result<void>> setBusinessEmp(String id, bool isBusiness) async =>
      const Success(null);

  @override
  Future<Result<List<BmsOneCateItem>>> loadOneCates() async =>
      Success(oneCates);

  @override
  Future<Result<void>> saveOneCate(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteOneCate(String id) async => const Success(null);

  @override
  Future<Result<List<BmsTwoCateItem>>> loadTwoCates({
    String oneCateId = '',
  }) async => Success(twoCates);

  @override
  Future<Result<void>> saveTwoCate(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteTwoCate(String id) async => const Success(null);

  @override
  Future<Result<List<BmsProductItem>>> loadProducts({
    String oneCateId = '',
    String twoCateId = '',
    String keyword = '',
  }) async => Success(products);

  @override
  Future<Result<void>> saveProduct(Map<String, Object?> fields) async {
    products.add(BmsProductItem.fromWire(fields));
    return const Success(null);
  }

  @override
  Future<Result<void>> setProductStatus(String id, bool enable) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteProduct(String id) async {
    products.removeWhere((p) => p.id == id);
    return const Success(null);
  }

  @override
  Future<Result<List<BmsPackageGroupTemplate>>> loadTaocanTemplates() async =>
      const Success([]);

  @override
  Future<Result<List<BmsRegionItem>>> loadRegions() async => Success(regions);

  @override
  Future<Result<void>> saveRegion(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteRegion(String id) async => const Success(null);

  @override
  Future<Result<List<BmsCardItem>>> loadSeats({
    String regionId = '',
    String keyword = '',
  }) async => Success(seats);

  @override
  Future<Result<void>> saveSeat(Map<String, Object?> fields) async {
    seats.add(BmsCardItem.fromWire(fields));
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteSeat(String id) async {
    seats.removeWhere((s) => s.id == id);
    return const Success(null);
  }

  @override
  Future<Result<List<BmsCardMinGroupItem>>> loadCardMinGroups() async =>
      const Success([]);

  @override
  Future<Result<void>> saveCardMinGroup(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<BmsCardTipItem>>> loadCardTips() async =>
      const Success([]);

  @override
  Future<Result<void>> saveCardTips(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<BmsArriveRuleItem>>> loadArriveRules() async =>
      const Success([]);

  @override
  Future<Result<void>> saveArriveRules(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<BmsProductGroupItem>>> loadProductGroups() async =>
      const Success([]);

  @override
  Future<Result<void>> saveProductGroup(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<BmsLimitConfigItem>>> loadLimitConfigs() async =>
      const Success([]);

  @override
  Future<Result<void>> saveLimitConfig(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<BmsStoreInfo>> loadStoreInfo() async =>
      const Success(BmsStoreInfo(name: '测试门店'));

  @override
  Future<Result<void>> saveStoreInfo(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<void>> restoreWorkday() async => const Success(null);

  @override
  Future<Result<List<BmsPayChannelItem>>> loadPayChannels() async =>
      const Success([]);

  @override
  Future<Result<void>> setPayChannelUsed(String id, bool used) async =>
      const Success(null);

  @override
  Future<Result<List<BmsPrinterItem>>> loadPrinters() async =>
      const Success([]);

  @override
  Future<Result<void>> savePrinter(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<BmsMakeLibItem>>> loadMakeLibs() async =>
      const Success([]);

  @override
  Future<Result<void>> saveMakeLib(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<BmsBillConfig>> loadBillConfig() async =>
      const Success(BmsBillConfig());

  @override
  Future<Result<void>> saveBillConfig(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<BmsTerminalItem>>> loadTerminals() async =>
      const Success([]);

  @override
  Future<Result<void>> clearTerminal(String id) async => const Success(null);

  @override
  Future<Result<String>> genQuickCode(String id) async => const Success('9999');

  @override
  Future<Result<List<BmsRequireItem>>> loadRequires() async =>
      const Success([]);

  @override
  Future<Result<void>> saveRequireItem(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<BmsReasonItem>>> loadReasons(String reasonType) async =>
      const Success([]);

  @override
  Future<Result<void>> saveReason(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteReason(String id) async => const Success(null);

  @override
  Future<Result<BmsTerminalRuleConfig>> loadTerminalRules() async =>
      const Success(BmsTerminalRuleConfig());

  @override
  Future<Result<void>> saveTerminalRules(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<BmsVipRuleConfig>> loadVipRules() async =>
      const Success(BmsVipRuleConfig());

  @override
  Future<Result<void>> saveVipRules(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<BmsWineConfig>> loadWineConfig() async =>
      const Success(BmsWineConfig());

  @override
  Future<Result<void>> saveWineConfig(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<List<BmsWineItem>>> loadWinePrdItems() async =>
      const Success([]);

  @override
  Future<Result<void>> saveWinePrd(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteWinePrd(String id) async => const Success(null);

  @override
  Future<Result<List<BmsCutPrdItem>>> loadCutPrds() async => const Success([]);

  @override
  Future<Result<void>> saveCutPrd(Map<String, Object?> fields) async =>
      const Success(null);

  @override
  Future<Result<BmsSmsAccountInfo>> loadSmsAccount() async =>
      const Success(BmsSmsAccountInfo(balance: 500));
  @override
  Future<Result<void>> sendSmsSelfCheck(String mobile) async => const Success(null);

  @override
  Future<Result<BmsSmsBillPage>> loadSmsBills({
    required String startDay,
    required String endDay,
    int type = 0,
    int page = 1,
    int pageSize = 20,
  }) async => const Success(BmsSmsBillPage());
  @override
  Future<Result<BmsSmsDeliveryPage>> loadSmsRecordDetails({
    required String recordId,
    int status = 0,
    String mobile = '',
    int page = 1,
    int pageSize = 20,
    bool initialize = true,
    List<Map<String, Object?>> templates = const [],
  }) async => const Success(BmsSmsDeliveryPage());
  @override
  Future<Result<BmsSmsDeliveryPage>> loadSmsMobileResults({
    required String mobile,
  }) async => const Success(BmsSmsDeliveryPage());

  @override
  Future<Result<List<BmsSmsRecord>>> loadSmsRecords({
    String phone = '',
  }) async => const Success([]);
}

void main() {
  testWidgets(
    'BmsNavScreen renders navigation shell and responds to page switches',
    (tester) async {
      final loader = FakeBmsLoader();
      bool backClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: BmsNavScreen(
            permissions: managementTestPermissions(),
            safeModeEnabled: false,
            loader: loader,
            initialPage: 'stationConfig',
            userName: '超级管理员',
            onBack: () => backClicked = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证顶栏与侧边栏渲染
      expect(find.text('BMS 门店后台系统'), findsOneWidget);
      expect(find.text('超级管理员'), findsOneWidget);
      expect(find.text('门店管理后台'), findsOneWidget);

      // 初始页面为 stationConfig
      expect(find.text('岗位管理'), findsWidgets);
      expect(find.text('店长'), findsOneWidget);

      // 点击侧栏切换到商品管理 prdConfig
      final prdNavItem = find.byKey(const Key('bms-nav-item-prdConfig'));
      if (prdNavItem.evaluate().isNotEmpty) {
        await tester.tap(prdNavItem);
        await tester.pumpAndSettle();
        expect(find.text('商品管理'), findsWidgets);
        expect(find.text('威士忌 (W01)'), findsOneWidget);
      }

      // 点击返回按钮
      final backBtn = find.byKey(const Key('bms-back-to-cashier-btn'));
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      expect(backClicked, true);
    },
  );

  testWidgets('BmsCodeRulesView can load and save rules', (tester) async {
    final loader = FakeBmsLoader();

    await tester.pumpWidget(
      MaterialApp(home: BmsCodeRulesView(loader: loader)),
    );
    await tester.pumpAndSettle();

    expect(find.text('工号生成规则'), findsOneWidget);
    expect(find.text('与员工号相同'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);

    final saveBtn = find.byKey(const Key('bms-code-rules-save-btn'));
    expect(saveBtn, findsOneWidget);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(find.text('保存成功'), findsOneWidget);
  });
}
