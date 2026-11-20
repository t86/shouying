import 'package:card_table/src/bms_high_margin_configuration_view.dart';
import 'package:card_table/src/bms_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:card_table/src/bms_report_configuration.dart';
import 'package:foundation/foundation.dart';

typedef Op = BmsReportConfigurationOperation;
Map<String, Object?> product(int id) => {
  'id': id,
  'n': '商品$id',
  'on': '酒水',
  'tn': '啤酒',
  'p': '123.45',
  'pt': '存货',
  's': id == 1 ? '无效' : '有效',
};

class Loader extends UnsupportedLoader implements BmsReportConfigurationLoader {
  @override
  Object? configurationContext = Object();
  final calls = <BmsReportConfigurationRequest>[];
  final writes = <BmsReportConfigurationRequest>[];
  final configured = <int>{1};
  bool failWrite = false, failCandidates = false;
  Completer<void>? configGate;
  @override
  Future<Result<Map<String, Object?>>> requestReportConfiguration(
    BmsReportConfigurationRequest request,
  ) async {
    calls.add(request);
    if (request.operation == Op.highMarginProducts) {
      await configGate?.future;
      return Success({
        'records': request.parameters['key'] == '无匹配'
            ? []
            : [for (final id in configured) product(id)],
      });
    }
    if (request.operation == Op.highMarginProductItems) {
      if (failCandidates) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'test',
            safeMessage: '候选读取失败',
          ),
        );
      }
      return Success({
        'cates': [
          {
            'id': 10,
            'n': '酒水',
            'ss': [
              {'id': 20, 'n': '啤酒'},
            ],
          },
        ],
        'prds': [
          for (
            var i = request.parameters['page_num'] == 1 ? 1 : 21;
            i <= (request.parameters['page_num'] == 1 ? 20 : 21);
            i++
          )
            product(i),
        ],
      });
    }
    writes.add(request);
    if (failWrite) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'test',
          safeMessage: '服务器拒绝',
        ),
      );
    }
    if (request.operation == Op.addHighMarginProducts) {
      configured.addAll((request.parameters['ids'] as List).cast<int>());
    }
    if (request.operation == Op.deleteHighMarginProducts) {
      configured.removeAll(request.parameters['ids'] as List);
    }
    return const Success({});
  }
}

Future<void> open(
  WidgetTester tester,
  Loader loader, {
  bool phone = false,
}) async {
  if (phone) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: BmsMiniProgressConfigView(loader: loader)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> add(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('high-margin-add')));
  await tester.pumpAndSettle();
}

void select(WidgetTester tester, int id) {
  final table = tester.widget<DataTable>(find.byType(DataTable).last);
  table.rows
      .firstWhere((r) => r.key == ValueKey('high-margin-row-$id'))
      .onSelectChanged!(true);
}

class UnsupportedLoader implements BmsLoader {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('delete confirmation from old session cannot write', (
    tester,
  ) async {
    final loader = Loader();
    await open(tester, loader);
    select(tester, 1);
    await tester.pump();
    await tester.tap(find.byKey(const Key('high-margin-delete')));
    await tester.pumpAndSettle();
    loader.configurationContext = Object();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(loader.writes, isEmpty);
  });
  testWidgets(
    'phone candidates keep source fields, categories, pages and disable all configured ids',
    (tester) async {
      final loader = Loader();
      await open(tester, loader, phone: true);
      expect(find.text('123.45'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('high-margin-search')),
        '无匹配',
      );
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      await add(tester);
      var table = tester.widget<DataTable>(find.byType(DataTable).last);
      expect(table.rows.first.onSelectChanged, isNull);
      final one = find.byType(DropdownButtonFormField<int>).first;
      tester.widget<DropdownButtonFormField<int>>(one).onChanged!(10);
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>).last,
          )
          .onChanged!(20);
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('high-margin-candidate-search')),
        'pj',
      );
      await tester.tap(find.text('查询候选'));
      await tester.pumpAndSettle();
      expect(loader.calls.last.parameters, {
        'name': 'pj',
        'page_num': 1,
        'page_size': 20,
        'init': 1,
        'one_cate_id': 10,
        'two_cate_id': 20,
      });
      select(tester, 2);
      await tester.pump();
      await tester.tap(find.text('加载更多'));
      await tester.pumpAndSettle();
      expect(loader.calls.last.parameters['page_num'], 2);
      expect(loader.calls.last.parameters['init'], 2);
      select(tester, 21);
      await tester.pump();
      expect(find.text('没有更多了'), findsOneWidget);
      await tester.tap(find.byKey(const Key('high-margin-confirm-add')));
      await tester.pumpAndSettle();
      expect(loader.writes.single.operation, Op.addHighMarginProducts);
      expect(loader.writes.single.parameters, {
        'ids': [2, 21],
      });
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('add failure visibly preserves selection and retry refreshes', (
    tester,
  ) async {
    final loader = Loader()..failWrite = true;
    await open(tester, loader, phone: true);
    await add(tester);
    select(tester, 2);
    await tester.pump();
    await tester.tap(find.byKey(const Key('high-margin-confirm-add')));
    await tester.pumpAndSettle();
    expect(find.text('服务器拒绝').hitTestable(), findsOneWidget);
    expect(
      tester.widget<DataTable>(find.byType(DataTable).last).rows[1].selected,
      true,
    );
    loader.failWrite = false;
    await tester.tap(find.byKey(const Key('high-margin-confirm-add')));
    await tester.pumpAndSettle();
    expect(find.text('添加高毛利商品'), findsNothing);
    expect(find.text('商品2'), findsOneWidget);
  });
  for (final cancel in [true, false]) {
    testWidgets(
      'pending add preflight ${cancel ? 'cancel' : 'session switch'} never writes',
      (tester) async {
        final loader = Loader();
        await open(tester, loader);
        await add(tester);
        select(tester, 2);
        await tester.pump();
        loader.configGate = Completer<void>();
        await tester.tap(find.byKey(const Key('high-margin-confirm-add')));
        await tester.pump();
        if (cancel) {
          await tester.tap(find.text('关闭'));
          await tester.pump();
        } else {
          loader.configurationContext = Object();
        }
        loader.configGate!.complete();
        await tester.pumpAndSettle();
        expect(loader.writes, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'delete cancellation and failure keep configuration, success refreshes',
    (tester) async {
      final loader = Loader();
      await open(tester, loader);
      select(tester, 1);
      await tester.pump();
      await tester.tap(find.byKey(const Key('high-margin-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(loader.writes, isEmpty);
      loader.failWrite = true;
      await tester.tap(find.byKey(const Key('high-margin-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();
      expect(find.text('服务器拒绝'), findsOneWidget);
      expect(find.text('商品1'), findsOneWidget);
      loader.failWrite = false;
      await tester.tap(find.byKey(const Key('high-margin-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认删除'));
      await tester.pumpAndSettle();
      expect(loader.writes.last.operation, Op.deleteHighMarginProducts);
      expect(loader.writes.last.parameters, {
        'ids': [1],
      });
      expect(find.text('暂无数据'), findsOneWidget);
    },
  );
  testWidgets(
    'candidate read failure is visible and reset retries without fake data',
    (tester) async {
      final loader = Loader()..failCandidates = true;
      await open(tester, loader);
      await add(tester);
      expect(find.text('候选读取失败'), findsOneWidget);
      expect(loader.writes, isEmpty);
      loader.failCandidates = false;
      await tester.tap(find.text('重置候选'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<DataTable>(find.byType(DataTable).last).rows.length,
        20,
      );
    },
  );
  testWidgets(
    'high margin is configuration, not a recommendation placeholder',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BmsMiniProgressConfigView(loader: UnsupportedLoader()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('配置高毛利商品'), findsOneWidget);
      expect(find.textContaining('重点推荐'), findsNothing);
      expect(find.textContaining('未接入'), findsOneWidget);
    },
  );
}
