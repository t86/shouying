import 'package:card_table/src/bms_fc_price.dart';
import 'package:card_table/src/bms_fc_price_screen.dart';
import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets(
    'new plan accepts empty employee set and batch delete calls confirmed ids',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loader = FcLoader();
      await tester.pumpWidget(
        MaterialApp(home: BmsFcPriceScreen(loader: loader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('价格方案管理'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增方案'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('移除草稿'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('fc-plan-name')), '新方案');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      final added = loader.calls.firstWhere(
        (r) => r.operation == BmsFcPriceOperation.addPlan,
      );
      expect(added.name, '新方案');
      expect(added.ids, isEmpty);
      await tester.tap(find.byType(Checkbox).last);
      await tester.pump();
      await tester.tap(find.text('批量删除'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(
        loader.calls
            .firstWhere((r) => r.operation == BmsFcPriceOperation.deletePlans)
            .ids,
        [7],
      );
    },
  );
  Future<void> open(WidgetTester tester, FcLoader loader) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: BmsFcPriceScreen(loader: loader)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> editPlan(WidgetTester tester) async {
    await tester.tap(find.text('价格方案管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑方案'));
    await tester.pumpAndSettle();
  }

  for (final outcome in ['save', 'cancel', 'reject']) {
    testWidgets('remove and add employee preserves source $outcome semantics', (
      tester,
    ) async {
      final loader = FcLoader();
      await open(tester, loader);
      await editPlan(tester);
      if (outcome == 'reject') loader.fail = BmsFcPriceOperation.removeEmployee;
      expect(find.byKey(const Key('fc-remove-add-1')), findsNothing);
      await tester.tap(find.byKey(const Key('fc-remove-add-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('加入当前方案需点击确定保存'), findsOneWidget);
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      if (outcome == 'reject') {
        expect(find.byKey(const Key('fc-selected-2')), findsNothing);
        expect(find.text('服务拒绝'), findsOneWidget);
        return;
      }
      expect(find.byKey(const Key('fc-selected-2')), findsOneWidget);
      expect(loader.removed, contains(2));
      expect(
        loader.calls.where((r) => r.operation == BmsFcPriceOperation.savePlan),
        isEmpty,
      );
      await tester.tap(find.text(outcome == 'cancel' ? '取消' : '确定'));
      await tester.pumpAndSettle();
      final saves = loader.calls.where(
        (r) => r.operation == BmsFcPriceOperation.savePlan,
      );
      if (outcome == 'save') {
        expect(saves.single.ids, [1, 2]);
        expect(saves.single.planId, 7);
      } else {
        expect(saves, isEmpty);
      }
    });
  }
  testWidgets('employee move actions remain usable on a narrow display', (
    tester,
  ) async {
    final loader = FcLoader();
    await open(tester, loader);
    await editPlan(tester);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final move = find.byKey(const Key('fc-remove-add-2'));
    await tester.scrollUntilVisible(
      move,
      100,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(move.hitTestable(), findsOneWidget);
    await tester.tap(move);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('加入当前方案需点击确定保存'), findsOneWidget);
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(loader.removed, contains(2));
    final selected = find.byKey(const Key('fc-selected-2'));
    await tester.scrollUntilVisible(
      selected,
      80,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(selected, findsOneWidget);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(
      loader.calls
          .where((r) => r.operation == BmsFcPriceOperation.savePlan)
          .single
          .ids,
      [1, 2],
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'price zero is editable and saved as zero cents, failure preserves draft',
    (tester) async {
      final loader = FcLoader();
      await open(tester, loader);
      final field = find.byKey(const Key('fc-price-3-7'));
      expect(tester.widget<TextField>(field).controller!.text, '0.00');
      await tester.enterText(field, '0.001');
      await tester.tap(find.byKey(const Key('fc-save-3-7')));
      await tester.pumpAndSettle();
      expect(
        loader.calls.where((r) => r.operation == BmsFcPriceOperation.savePrice),
        isEmpty,
      );
      await tester.enterText(field, '0');
      loader.fail = BmsFcPriceOperation.savePrice;
      await tester.tap(find.byKey(const Key('fc-save-3-7')));
      await tester.pumpAndSettle();
      expect(find.text('服务拒绝'), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, '0');
      loader.fail = null;
      await tester.tap(find.byKey(const Key('fc-save-3-7')));
      await tester.pumpAndSettle();
      expect(loader.calls.last.amount, 0);
      expect(find.text('价格已保存'), findsOneWidget);
    },
  );
  testWidgets(
    'configured products cannot be added twice; selections use actual ids',
    (tester) async {
      final loader = FcLoader();
      await open(tester, loader);
      await tester.tap(find.text('添加商品'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('fc-candidate-3')))
            .onChanged,
        isNull,
      );
      await tester.tap(find.byKey(const Key('fc-candidate-4')));
      await tester.pump();
      await tester.tap(find.text('添加 >'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(
        loader.calls
            .firstWhere((r) => r.operation == BmsFcPriceOperation.addProducts)
            .ids,
        [4],
      );
    },
  );
  testWidgets(
    'current staff preselect, occupied staff disabled, saving sends full selected list',
    (tester) async {
      final loader = FcLoader();
      await open(tester, loader);
      await editPlan(tester);
      expect(find.byKey(const Key('fc-selected-1')), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('fc-candidate-2')))
            .onChanged,
        isNull,
      );
      await tester.tap(find.byKey(const Key('fc-candidate-3')));
      await tester.pump();
      await tester.tap(find.text('添加 >'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('fc-plan-name')), '改名方案');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      final request = loader.calls.firstWhere(
        (r) => r.operation == BmsFcPriceOperation.savePlan,
      );
      expect(request.planId, 7);
      expect(request.ids, [1, 3]);
      expect(request.name, '改名方案');
    },
  );
  testWidgets(
    'immediate removal survives cancel but local selected removal does not write',
    (tester) async {
      final loader = FcLoader();
      await open(tester, loader);
      await editPlan(tester);
      await tester.tap(find.byKey(const Key('fc-remove-assigned-2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('取消当前编辑也不会恢复'), findsOneWidget);
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      final request = loader.calls.firstWhere(
        (r) => r.operation == BmsFcPriceOperation.removeEmployee,
      );
      expect(request.planId, 9);
      expect(request.employeeId, 2);
      expect(loader.removed, contains(2));
      await tester.tap(find.text('移除草稿'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(
        loader.calls.where((r) => r.operation == BmsFcPriceOperation.savePlan),
        isEmpty,
      );
      expect(
        loader.calls
            .where((r) => r.operation == BmsFcPriceOperation.removeEmployee)
            .length,
        1,
      );
      await tester.tap(find.byType(Checkbox).last);
      await tester.pump();
      await tester.tap(find.text('编辑方案'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fc-selected-1')), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('fc-candidate-2')))
            .onChanged,
        isNotNull,
      );
    },
  );
  testWidgets(
    'multi-department search merges candidates by id without losing draft selections',
    (tester) async {
      final loader = FcLoader();
      await open(tester, loader);
      await editPlan(tester);
      await tester.tap(find.text('营销部'));
      await tester.tap(find.text('服务部'));
      await tester.tap(find.text('查询候选'));
      await tester.pumpAndSettle();
      expect(
        loader.calls
            .where((r) => r.operation == BmsFcPriceOperation.employeeItems)
            .map((r) => r.deptId)
            .toList(),
        [0, 8, 9],
      );
      expect(find.byKey(const Key('fc-candidate-1')), findsOneWidget);
      expect(find.byKey(const Key('fc-selected-1')), findsOneWidget);
    },
  );
}

class FcLoader implements BmsLoader {
  final calls = <BmsFcPriceRequest>[];
  final removed = <int>{};
  BmsFcPriceOperation? fail;
  @override
  Future<Result<Map<String, Object?>>> requestFcPrice(
    BmsFcPriceRequest request,
  ) async {
    calls.add(request);
    if (request.operation == fail) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'test',
          safeMessage: '服务拒绝',
        ),
      );
    }
    switch (request.operation) {
      case BmsFcPriceOperation.products:
        return const Success({
          'prds': [
            {'id': 3, 'n': '酒', 'on': '酒水', 'tn': '洋酒', 'p': 1200},
          ],
          'plans': [
            {'id': 7, 'n': '方案A'},
          ],
          'prices': [
            {'id': 3, 'p': 7, 'a': 0},
          ],
        });
      case BmsFcPriceOperation.plans:
        return const Success({
          'records': [
            {'id': 7, 'n': '方案A', 'e': 1, 'c': '2026-09-20', 'u': '2026-09-20'},
          ],
        });
      case BmsFcPriceOperation.productItems:
        return const Success({
          'cates': [
            {
              'id': 1,
              'n': '酒水',
              'cs': [
                {'id': 2, 'n': '洋酒'},
              ],
            },
          ],
          'records': [
            {'id': 3, 'n': '已配置酒', 'p': 1200, 'c': 1},
            {'id': 4, 'n': '未配置酒', 'p': 100, 'c': 0},
          ],
        });
      case BmsFcPriceOperation.employeeItems:
        return Success({
          'records': [
            {
              'id': 1,
              'n': '当前员工',
              'c': '001',
              's': 1,
              'p': 7,
              'r': '方案A',
              'd': '营销部',
            },
            {
              'id': 2,
              'n': '其它员工',
              'c': '002',
              's': removed.contains(2) ? 0 : 2,
              'p': removed.contains(2) ? 0 : 9,
              'r': removed.contains(2) ? '' : '方案B',
            },
            {'id': 3, 'n': '新员工', 'c': '003', 's': 0, 'p': 0},
          ],
        });
      case BmsFcPriceOperation.removeEmployee:
        removed.add(request.employeeId);
        return const Success({});
      default:
        return const Success({});
    }
  }

  @override
  Future<Result<List<BmsDepartmentOption>>> loadDepartments() async =>
      const Success([
        BmsDepartmentOption('8', '营销部'),
        BmsDepartmentOption('9', '服务部'),
      ]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
