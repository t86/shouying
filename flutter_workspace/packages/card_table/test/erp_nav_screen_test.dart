import 'management_permission_fixture.dart';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

final class FakeErpLoader implements ErpLoader {
  @override
  Future<Result<ErpStockOptions>> loadSinOptions() async => const FailureResult(
    AppFailure(
      kind: FailureKind.network,
      code: 'test.unavailable',
      safeMessage: '仓库数据未就绪',
    ),
  );
  @override
  Future<Result<List<ErpStoreItem>>> loadSoutStores() async =>
      const FailureResult(
        AppFailure(
          kind: FailureKind.network,
          code: 'test.unavailable',
          safeMessage: '仓库数据未就绪',
        ),
      );
  @override
  Future<Result<List<ErpStockMaterial>>> searchStockMaterials({
    required bool outgoing,
    required String keyword,
    String storeId = '',
  }) async => const Success([]);
  List<ErpStoreItem> stores = [
    const ErpStoreItem(id: 's1', code: 'WH01', name: '总仓', status: 1),
    const ErpStoreItem(id: 's2', code: 'WH02', name: '分仓', status: 0),
  ];

  @override
  Future<Result<List<ErpNegStoreAlert>>> loadNegStoreAlerts() async =>
      const Success(<ErpNegStoreAlert>[]);

  @override
  Future<Result<List<ErpUnboundPrdAlert>>> loadUnboundPrdAlerts() async =>
      const Success(<ErpUnboundPrdAlert>[]);

  @override
  Future<Result<List<ErpStoreItem>>> loadStores() async => Success(stores);

  @override
  Future<Result<void>> saveStore(ErpStoreItem store) async {
    stores.add(store);
    return const Success(null);
  }

  @override
  Future<Result<void>> toggleStoreStatus(String storeId, bool enable) async {
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteStore(String storeId) async {
    stores.removeWhere((s) => s.id == storeId);
    return const Success(null);
  }

  @override
  Future<Result<List<ErpMatCate>>> loadMatCateTree() async =>
      const Success(<ErpMatCate>[]);

  @override
  Future<Result<List<ErpMatItem>>> loadMats({
    String? oneCateId,
    String? twoCateId,
    String? keyword,
  }) async => const Success(<ErpMatItem>[]);

  @override
  Future<Result<void>> saveMat(ErpMatItem mat) async => const Success(null);

  @override
  Future<Result<void>> toggleMatStatus(String matId, bool enable) async =>
      const Success(null);

  @override
  Future<Result<void>> deleteMat(String matId) async => const Success(null);

  @override
  Future<Result<List<ErpComparePrdItem>>> loadComparePrds(int type) async =>
      const Success(<ErpComparePrdItem>[]);

  @override
  Future<Result<void>> bindMatPrd({
    required String prdId,
    required String matId,
  }) async => const Success(null);

  @override
  Future<Result<void>> closeBindPrds(List<String> prdIds) async =>
      const Success(null);

  @override
  Future<Result<List<ErpSupplierItem>>> loadSuppliers() async =>
      const Success(<ErpSupplierItem>[]);

  @override
  Future<Result<void>> saveSupplier(ErpSupplierItem supplier) async =>
      const Success(null);

  @override
  Future<Result<void>> toggleSupplierStatus(
    String supplierId,
    bool enable,
  ) async => const Success(null);

  @override
  Future<Result<void>> deleteSupplier(String supplierId) async =>
      const Success(null);

  @override
  Future<Result<List<ErpSinItem>>> loadSinList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async => const Success(<ErpSinItem>[]);

  @override
  Future<Result<List<ErpMatItem>>> searchSinMats(String keyword) async =>
      const Success(<ErpMatItem>[]);

  @override
  Future<Result<void>> createSinOrder(Map<String, Object?> payload) async =>
      const Success(null);

  @override
  Future<Result<void>> reverseSinOrder(String billId) async =>
      const Success(null);

  @override
  Future<Result<void>> redPunchSinOrder(String billId) async =>
      const Success(null);

  @override
  Future<Result<List<ErpSindItem>>> loadSindList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async => const Success(<ErpSindItem>[]);

  @override
  Future<Result<void>> batchSindIn(List<String> billIds) async =>
      const Success(null);

  @override
  Future<Result<void>> partSindIn(Map<String, Object?> payload) async =>
      const Success(null);

  @override
  Future<Result<void>> applySindSh(Map<String, Object?> payload) async =>
      const Success(null);

  @override
  Future<Result<List<ErpDisputeItem>>> loadDisputeInList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async => const Success(<ErpDisputeItem>[]);

  @override
  Future<Result<void>> confirmDisputeIn(String disputeId) async =>
      const Success(null);

  @override
  Future<Result<void>> cancelDisputeIn(String disputeId) async =>
      const Success(null);

  @override
  Future<Result<void>> rejectDisputeIn(String disputeId) async =>
      const Success(null);

  @override
  Future<Result<List<ErpSoutItem>>> loadSoutList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async => const Success(<ErpSoutItem>[]);

  @override
  Future<Result<void>> createSoutOrder(Map<String, Object?> payload) async =>
      const Success(null);

  @override
  Future<Result<void>> reverseSoutOrder(String billId) async =>
      const Success(null);

  @override
  Future<Result<void>> redPunchSoutOrder(String billId) async =>
      const Success(null);

  @override
  Future<Result<List<ErpSoutdItem>>> loadSoutdList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async => const Success(<ErpSoutdItem>[]);

  @override
  Future<Result<void>> createSoutdOrder(Map<String, Object?> payload) async =>
      const Success(null);

  @override
  Future<Result<void>> reverseSoutdOrder(String billId) async =>
      const Success(null);

  @override
  Future<Result<void>> redPunchSoutdOrder(String billId) async =>
      const Success(null);

  @override
  Future<Result<List<ErpDisputeItem>>> loadDisputeOutList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async => const Success(<ErpDisputeItem>[]);

  @override
  Future<Result<void>> rejectDisputeOut(String disputeId) async =>
      const Success(null);

  @override
  Future<Result<void>> redPunchDisputeOut(String disputeId) async =>
      const Success(null);

  @override
  Future<Result<void>> breakLossDisputeOut(String disputeId) async =>
      const Success(null);

  @override
  Future<Result<List<ErpEmptyInItem>>> loadEmptyInList({
    String? beginDay,
    String? endDay,
  }) async => const Success(<ErpEmptyInItem>[]);

  @override
  Future<Result<void>> confirmEmptyIn(String billId) async =>
      const Success(null);

  @override
  Future<Result<void>> redPunchEmptyIn(String billId) async =>
      const Success(null);

  @override
  Future<Result<List<ErpEmptyInvtItem>>> loadEmptyInvtList({
    String? keyword,
  }) async => const Success(<ErpEmptyInvtItem>[]);

  @override
  Future<Result<void>> submitEmptyOut(Map<String, Object?> payload) async =>
      const Success(null);

  @override
  Future<Result<List<ErpEmptyOutItem>>> loadEmptyOutList({
    String? beginDay,
    String? endDay,
  }) async => const Success(<ErpEmptyOutItem>[]);

  @override
  Future<Result<void>> redPunchEmptyOut(String billId) async =>
      const Success(null);

  @override
  Future<Result<ErpReportParams>> loadReportParams() async =>
      const Success(ErpReportParams());

  @override
  Future<Result<List<ErpMatNowInvtItem>>> loadMatNowInvt({
    String? storeId,
    String? keyword,
  }) async => const Success(<ErpMatNowInvtItem>[]);

  @override
  Future<Result<List<ErpMatMonthInvtItem>>> loadMatMonthInvt({
    String? storeId,
    String? month,
  }) async => const Success(<ErpMatMonthInvtItem>[]);

  @override
  Future<Result<List<ErpInOutRecItem>>> loadInRecs({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) async => const Success(<ErpInOutRecItem>[]);

  @override
  Future<Result<List<ErpInOutRecItem>>> loadOutRecs({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) async => const Success(<ErpInOutRecItem>[]);

  @override
  Future<Result<List<ErpInOutSumItem>>> loadInSum({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) async => const Success(<ErpInOutSumItem>[]);

  @override
  Future<Result<List<ErpInOutSumItem>>> loadOutSum({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) async => const Success(<ErpInOutSumItem>[]);

  @override
  Future<Result<List<ErpPsiItem>>> loadStorePsi({
    String? storeId,
    String? date,
  }) async => const Success(<ErpPsiItem>[]);

  @override
  Future<Result<List<ErpEmptyOperItem>>> loadEmptyInOperList({
    String? beginDay,
    String? endDay,
  }) async => const Success(<ErpEmptyOperItem>[]);

  @override
  Future<Result<List<ErpEmptyOperItem>>> loadEmptyOutOperList({
    String? beginDay,
    String? endDay,
  }) async => const Success(<ErpEmptyOperItem>[]);
}

void main() {
  testWidgets('ErpNavScreen renders navigation shell and switches pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final loader = FakeErpLoader();
    var backTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ErpNavScreen(
          permissions: managementTestPermissions(),
          safeModeEnabled: false,
          loader: loader,
          initialPage: 'home',
          userName: '仓管员张三',
          onBack: () => backTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header
    expect(find.text('ERP 仓库管理系统'), findsOneWidget);
    expect(find.text('仓管员张三'), findsOneWidget);
    expect(find.text('ERP 仓库运行正常'), findsOneWidget);

    // Click back button
    await tester.tap(find.text('返回收银'));
    await tester.pump();
    expect(backTapped, true);

    // Switch to warehouse management
    await tester.tap(find.text('仓库管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('仓库设置'));
    await tester.pumpAndSettle();

    expect(find.text('仓库管理'), findsNWidgets(2));
    expect(find.text('总仓'), findsOneWidget);
    expect(find.text('分仓'), findsOneWidget);
  });

  testWidgets('ErpStoreManagementView can load and show store list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final loader = FakeErpLoader();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ErpStoreManagementView(loader: loader)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('仓库管理'), findsOneWidget);
    expect(find.text('WH01'), findsOneWidget);
    expect(find.text('WH02'), findsOneWidget);
  });
}
