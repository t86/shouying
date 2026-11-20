import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_report_configuration.dart';
import 'package:card_table/src/bms_report_selection_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class SelectionLoader implements BmsLoader, BmsReportConfigurationLoader {
  Object? token = Object();
  bool failAdd = false;
  bool badTree = false;
  final requests = <BmsReportConfigurationRequest>[];
  final configured = <Map<String, Object?>>[
    {'id': 1, 'n': '已配置'},
  ];
  @override
  Object? get configurationContext => token;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  Future<Result<Map<String, Object?>>> requestReportConfiguration(
    BmsReportConfigurationRequest r,
  ) async {
    final body = r.body;
    requests.add(r);
    switch (r.operation) {
      case BmsReportConfigurationOperation.departmentTabs:
      case BmsReportConfigurationOperation.waiterProducts:
        return Success({'records': List.of(configured)});
      case BmsReportConfigurationOperation.deptTree:
        if (badTree) {
          return const Success({
            'depts': [
              {'id': 1, 'n': '坏数据', 'subs': 'invalid'},
            ],
          });
        }
        return const Success({
          'depts': [
            {
              'id': 1,
              'n': '已配置',
              'subs': [
                {'id': 2, 'n': '子部门'},
              ],
            },
          ],
        });
      case BmsReportConfigurationOperation.waiterProductItems:
        final page = body['page_num'] as int;
        return Success({
          'cates': [
            {
              'id': 10,
              'n': '酒水',
              'ss': [
                {'id': 11, 'n': '啤酒'},
              ],
            },
          ],
          'prds': [
            for (
              var id = (page - 1) * 20 + 1;
              id <= (page == 1 ? 20 : 21);
              id++
            )
              {'id': id, 'n': '商品$id', 'on': '酒水', 'tn': '啤酒', 'price': '10'},
          ],
        });
      case BmsReportConfigurationOperation.addDepartmentTabs:
      case BmsReportConfigurationOperation.addWaiterProducts:
        if (failAdd) {
          return const FailureResult(
            AppFailure(
              kind: FailureKind.business,
              code: 'test.fail',
              safeMessage: '保存失败',
            ),
          );
        }
        configured.add({'id': 2, 'n': '子部门'});
        return const Success({});
      default:
        return const Success({});
    }
  }
}

void main() {
  testWidgets(
    'department batch keeps source tree order rather than click order',
    (tester) async {
      final loader = SelectionLoader()..configured.clear();
      await tester.pumpWidget(
        MaterialApp(home: BmsReportTYConfigView(loader: loader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('report-option-2')));
      await tester.tap(find.byKey(const Key('report-option-1')));
      await tester.tap(find.byKey(const Key('report-add')));
      await tester.pumpAndSettle();
      expect(
        loader.requests
            .where(
              (r) =>
                  r.operation ==
                  BmsReportConfigurationOperation.addDepartmentTabs,
            )
            .single
            .parameters,
        {
          'dept_ids': [1, 2],
        },
      );
    },
  );
  testWidgets('malformed department children fail safely without writes', (
    tester,
  ) async {
    final loader = SelectionLoader()..badTree = true;
    await tester.pumpWidget(
      MaterialApp(home: BmsReportTYConfigView(loader: loader)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('配置数据无法读取，请重试'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('report-add')))
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'department tree preserves child choices, configured disabled and failed selection',
    (tester) async {
      final loader = SelectionLoader()..failAdd = true;
      await tester.pumpWidget(
        MaterialApp(home: BmsReportTYConfigView(loader: loader)),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('report-option-1')))
            .onChanged,
        isNull,
      );
      await tester.tap(find.byKey(const Key('report-option-2')));
      await tester.tap(find.byKey(const Key('report-add')));
      await tester.pumpAndSettle();
      expect(loader.requests.last.parameters, {
        'dept_ids': [2],
      });
      expect(find.text('保存失败'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('report-option-2')))
            .value,
        true,
      );
      loader.failAdd = false;
      await tester.tap(find.byKey(const Key('report-add')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('report-option-2')))
            .onChanged,
        isNull,
      );
    },
  );

  testWidgets('sales candidates filter and page with applied query on phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loader = SelectionLoader();
    await tester.pumpWidget(
      MaterialApp(home: BmsSealPrdConfigView(loader: loader)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const Key('report-search')), '啤酒');
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('report-search')), '未提交');
    await tester.ensureVisible(find.byKey(const Key('report-more')));
    await tester.tap(find.byKey(const Key('report-more')));
    await tester.pumpAndSettle();
    expect(loader.requests.last.parameters, {
      'name': '啤酒',
      'page_num': 2,
      'page_size': 20,
      'init': 2,
      'one_cate_id': 0,
      'two_cate_id': 0,
    });
    expect(find.byKey(const Key('report-option-21')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changed session or cancelled deletion never writes', (
    tester,
  ) async {
    final loader = SelectionLoader();
    await tester.pumpWidget(
      MaterialApp(home: BmsReportTYConfigView(loader: loader)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('report-delete-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(
      loader.requests.any(
        (r) =>
            r.operation == BmsReportConfigurationOperation.deleteDepartmentTab,
      ),
      false,
    );
    await tester.tap(find.byKey(const Key('report-delete-1')));
    await tester.pumpAndSettle();
    loader.token = Object();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(
      loader.requests.any(
        (r) =>
            r.operation == BmsReportConfigurationOperation.deleteDepartmentTab,
      ),
      false,
    );
  });
}
