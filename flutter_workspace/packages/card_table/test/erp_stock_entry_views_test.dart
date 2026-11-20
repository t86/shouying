import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_models.dart';
import 'package:card_table/src/erp_in_views.dart';
import 'package:card_table/src/erp_out_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

Future<void> choose(WidgetTester tester, String key, String label) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'purchase requires source supplier and outbound warehouse change clears stock-bound lines',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loader = StockLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ErpAnotherInLibView(loader: loader)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('新建其他入库单'));
      await tester.pumpAndSettle();
      await choose(tester, 'erp-stock-store', '一仓');
      await choose(tester, 'erp-stock-type', '采购入库');
      await choose(tester, 'erp-stock-invoice', '普票');
      await tester.enterText(find.byKey(const Key('erp-stock-search')), '啤');
      await tester.tap(find.text('搜索物料'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('erp-stock-candidate-31')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('提交入库'));
      await tester.pumpAndSettle();
      expect(loader.saved, isNull);
      expect(find.text('必选框不能为空'), findsOneWidget);
      await choose(tester, 'erp-stock-supplier', '供货商');
      await tester.tap(find.text('提交入库'));
      await tester.pumpAndSettle();
      expect(loader.saved!['supplier_id'], 9);
      expect(loader.saved!['record_type'], 1);
      expect(loader.saved!['amts'], ['20.00']);
      expect(loader.saved!['src_amts'], ['20.00']);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ErpAnotherOutLibView(loader: loader)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('新建其他出库单'));
      await tester.pumpAndSettle();
      await choose(tester, 'erp-stock-store', '一仓');
      await tester.enterText(find.byKey(const Key('erp-stock-search')), '啤');
      await tester.tap(find.text('搜索物料'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('erp-stock-candidate-31')));
      await tester.pumpAndSettle();
      await choose(tester, 'erp-stock-store', '二仓');
      expect(find.text('切换出库仓库'), findsOneWidget);
      await tester.tap(find.text('继续'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('erp-stock-quantity-31')), findsNothing);
      await tester.tap(find.text('搜索物料'));
      await tester.pumpAndSettle();
      expect(loader.lastSearch, (true, '啤', '3'));
    },
  );
  for (final outgoing in [false, true]) {
    testWidgets(
      '${outgoing ? 'out' : 'in'} selects real stock, validates and preserves server failure before successful refresh',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final loader = StockLoader();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: outgoing
                  ? ErpAnotherOutLibView(loader: loader)
                  : ErpAnotherInLibView(loader: loader),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(outgoing ? '新建其他出库单' : '新建其他入库单'));
        await tester.pumpAndSettle();
        await choose(tester, 'erp-stock-store', '一仓');
        await choose(tester, 'erp-stock-type', outgoing ? '其他出库' : '其他入库');
        if (!outgoing) await choose(tester, 'erp-stock-invoice', '专票');
        await tester.enterText(find.byKey(const Key('erp-stock-search')), '啤');
        await tester.tap(find.text('搜索物料'));
        await tester.pumpAndSettle();
        expect(loader.lastSearch, (outgoing, '啤', '2'));
        await tester.tap(find.byKey(const Key('erp-stock-candidate-31')));
        await tester.pumpAndSettle();
        expect(find.textContaining('瓶'), findsWidgets);
        await tester.enterText(
          find.byKey(const Key('erp-stock-quantity-31')),
          outgoing ? '6' : '-1',
        );
        await tester.tap(find.text(outgoing ? '提交出库' : '提交入库'));
        await tester.pumpAndSettle();
        expect(loader.saved, isNull);
        await tester.enterText(
          find.byKey(const Key('erp-stock-quantity-31')),
          '2',
        );
        await tester.enterText(
          find.byKey(const Key('erp-stock-value-31')),
          outgoing ? '12.50' : '113',
        );
        await tester.tap(find.text(outgoing ? '提交出库' : '提交入库'));
        await tester.pumpAndSettle();
        expect(loader.saved, {
          'store_id': 2,
          'record_type': outgoing ? 17 : 7,
          'remark': '',
          'mat_ids': [31],
          'cnts': [2.0],
          'amts': [outgoing ? '25.00' : '100.00'],
          if (!outgoing) 'supplier_id': '',
          if (!outgoing) 'fapiao_type': 2,
          if (!outgoing) 'src_amts': ['113.00'],
        });
        expect(find.text('保存失败'), findsOneWidget);
        expect(find.byKey(const Key('erp-stock-quantity-31')), findsOneWidget);
        loader.fail = false;
        await tester.tap(find.text(outgoing ? '提交出库' : '提交入库'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('erp-stock-quantity-31')), findsNothing);
        expect(loader.listLoads, 2);
      },
    );
  }
}

class StockLoader implements ErpLoader {
  bool fail = true;
  int listLoads = 0;
  Map<String, Object?>? saved;
  (bool, String, String)? lastSearch;
  @override
  Future<Result<List<ErpSinItem>>> loadSinList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async {
    listLoads++;
    return const Success([]);
  }

  @override
  Future<Result<List<ErpSoutItem>>> loadSoutList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async {
    listLoads++;
    return const Success([]);
  }

  @override
  Future<Result<ErpStockOptions>> loadSinOptions() async => const Success(
    ErpStockOptions(
      stores: [
        ErpStoreItem(id: '2', name: '一仓'),
        ErpStoreItem(id: '3', name: '二仓'),
      ],
      suppliers: [ErpSupplierItem(id: '9', name: '供货商')],
    ),
  );
  @override
  Future<Result<List<ErpStoreItem>>> loadSoutStores() async => const Success([
    ErpStoreItem(id: '2', name: '一仓'),
    ErpStoreItem(id: '3', name: '二仓'),
  ]);
  @override
  Future<Result<List<ErpStockMaterial>>> searchStockMaterials({
    required bool outgoing,
    required String keyword,
    String storeId = '',
  }) async {
    lastSearch = (outgoing, keyword, storeId);
    return const Success([
      ErpStockMaterial(
        id: '31',
        name: '真实物料',
        unitName: '瓶',
        stockCount: 5,
        stockAmount: 100,
      ),
    ]);
  }

  Future<Result<void>> save(Map<String, Object?> fields) async {
    saved = fields;
    return fail
        ? const FailureResult(
            AppFailure(
              kind: FailureKind.business,
              code: 'test',
              safeMessage: '保存失败',
            ),
          )
        : const Success(null);
  }

  @override
  Future<Result<void>> createSinOrder(Map<String, Object?> fields) =>
      save(fields);
  @override
  Future<Result<void>> createSoutOrder(Map<String, Object?> fields) =>
      save(fields);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
