import 'dart:async';

import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:card_table/src/erp_out_views.dart';
import 'package:card_table/src/erp_in_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'erp_stock_entry_views_test.dart' show StockLoader;

class Loader extends StockLoader implements ErpSoutWorkflowLoader {
  @override
  Object? soutContext = Object();
  final queries = <Map<String, Object?>>[];
  final whole = <String>[], partial = <Map<int, double>>[];
  Completer<void>? pending;
  bool network = false;
  bool listFails = false;
  int hc = 1;
  @override
  Future<Result<ErpSoutPage>> loadOtherOutPage({
    required String beginDay,
    required String endDay,
    int recordType = 0,
    String remark = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    queries.add({
      'begin_day': beginDay,
      'end_day': endDay,
      'record_type': recordType,
      'remark': remark,
      'page_num': page,
      'page_size': pageSize,
    });
    if (listFails) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.network,
          code: 'read',
          safeMessage: '读取失败',
        ),
      );
    }
    return Success(
      ErpSoutPage([
        {
          'id': 1,
          'hc': hc,
          'cd': 'OUT1',
          'rt': '其他出库',
          'sn': '仓库',
          'ta': '5',
          'sa': '10',
          'r': '备注',
          'st': '时间',
          'en': '员工',
        },
      ], 41),
    );
  }

  @override
  Future<Result<ErpSoutDocument>> loadOtherOutDocument(
    String id,
    ErpSoutDocumentMode mode,
  ) async {
    if (pending != null) await pending!.future;
    return Success(
      ErpSoutDocument({
        'store_id': 2,
        'stores': [
          {'id': 2, 'n': '一仓'},
        ],
        'record_type': 17,
        'remark': '复制备注',
        'dtls': [
          {
            'id': 31,
            'n': '真实物料',
            'moc': '一类',
            'mtc': '二类',
            'un': '瓶',
            'c': 2,
            'sa': 12.5,
            'a': 10,
          },
        ],
      }, mode),
    );
  }

  @override
  Future<Result<void>> reverseOtherOutWhole(String id) async {
    whole.add(id);
    return const Success(null);
  }

  @override
  Future<Result<void>> reverseOtherOutLines(Map<int, double> counts) async {
    partial.add(counts);
    return network
        ? const FailureResult(
            AppFailure(
              kind: FailureKind.network,
              code: 'timeout',
              safeMessage: '网络失败',
            ),
          )
        : const Success(null);
  }
}

class LateLoader extends Loader {
  final completion = Completer<Result<void>>();
  int writes = 0;
  @override
  Future<Result<void>> createSoutOrder(Map<String, Object?> payload) {
    writes++;
    return completion.future;
  }
}

Future<void> open(WidgetTester tester, Loader loader) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: ErpAnotherOutLibView(loader: loader)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'already reversed bills cannot select and fresh reversal blocks old selection',
    (tester) async {
      final loader = Loader()..hc = 2;
      await open(tester, loader);
      expect(
        tester
            .widget<CheckboxListTile>(find.byType(CheckboxListTile))
            .onChanged,
        isNull,
      );
      loader.hc = 1;
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OUT1'));
      await tester.pump();
      await tester.tap(find.text('红冲整单'));
      await tester.pumpAndSettle();
      loader.hc = 2;
      await tester.tap(find.text('确定红冲'));
      await tester.pumpAndSettle();
      expect(loader.whole, isEmpty);
      await tester.tap(find.text('类似创建'));
      await tester.pumpAndSettle();
      expect(find.byType(ErpStockEntryDialog), findsNothing);
    },
  );
  testWidgets('failed replacement query clears old selected bill and total', (
    tester,
  ) async {
    final loader = Loader();
    await open(tester, loader);
    await tester.tap(find.text('OUT1'));
    await tester.pump();
    loader.listFails = true;
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    expect(find.text('OUT1'), findsNothing);
    expect(find.text('第 1 页 · 共 0 条'), findsOneWidget);
    await tester.tap(find.text('红冲整单'));
    await tester.pumpAndSettle();
    expect(find.text('确定红冲'), findsNothing);
    expect(loader.whole, isEmpty);
    await tester.tap(find.text('类似创建'));
    await tester.pumpAndSettle();
    expect(find.byType(ErpStockEntryDialog), findsNothing);
  });
  testWidgets(
    'successful covered copy route disappears without popping covering page',
    (tester) async {
      final loader = LateLoader();
      await open(tester, loader);
      await tester.tap(find.text('OUT1'));
      await tester.pump();
      await tester.tap(find.text('类似创建'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('提交出库'));
      await tester.pump();
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        nav.push<void>(
          MaterialPageRoute(builder: (_) => const Scaffold(body: Text('新页面'))),
        ),
      );
      await tester.pumpAndSettle();
      loader.completion.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('新页面'), findsOneWidget);
      expect(
        find.byType(ErpStockEntryDialog, skipOffstage: false),
        findsNothing,
      );
      expect(loader.writes, 1);
    },
  );
  testWidgets('390 list date type remark and pagination follow source', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loader = Loader();
    await open(tester, loader);
    expect(find.text('第 1 页 · 共 41 条'), findsOneWidget);
    await tester.tap(find.text('近30天'));
    await tester.pumpAndSettle();
    expect(
      DateTime.parse(loader.queries.last['end_day'] as String)
          .difference(
            DateTime.parse(loader.queries.last['begin_day'] as String),
          )
          .inDays,
      30,
    );
    tester
        .widget<DropdownButtonFormField<int>>(
          find.byType(DropdownButtonFormField<int>),
        )
        .onChanged!(62);
    await tester.pump();
    await tester.enterText(find.byKey(const Key('sout-remark')), '报损');
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    expect(loader.queries.last['record_type'], 62);
    expect(loader.queries.last['remark'], '报损');
    await tester.tap(find.byTooltip('下一页'));
    await tester.pumpAndSettle();
    expect(loader.queries.last['page_num'], 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'similar creation preserves source material ids count and sale unit price',
    (tester) async {
      final loader = Loader();
      await open(tester, loader);
      await tester.tap(find.text('OUT1'));
      await tester.pump();
      await tester.tap(find.text('类似创建'));
      await tester.pumpAndSettle();
      expect(find.text('类似创建其他出库'), findsOneWidget);
      expect(loader.lastSearch, (true, '真实物料', '2'));
      await tester.tap(find.text('提交出库'));
      await tester.pumpAndSettle();
      expect(loader.saved, {
        'store_id': 2,
        'record_type': 17,
        'remark': '复制备注',
        'mat_ids': [31],
        'cnts': [2.0],
        'amts': ['25.00'],
      });
      expect(find.text('保存失败'), findsOneWidget);
      loader.soutContext = Object();
      final saved = loader.saved;
      await tester.tap(find.text('提交出库'));
      await tester.pumpAndSettle();
      expect(identical(loader.saved, saved), true);
    },
  );
  for (final cancel in [true, false]) {
    testWidgets(
      '${cancel ? 'cancel' : 'session change'} during partial preflight prevents reversal',
      (tester) async {
        final loader = Loader();
        await open(tester, loader);
        await tester.tap(find.text('OUT1'));
        await tester.pump();
        await tester.tap(find.text('红冲'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('sout-hc-31')), '1.5');
        await tester.pump();
        expect(find.text('红冲后数量：0.5 · 成本小计：7.50 · 红冲小计：9.38'), findsOneWidget);
        loader.pending = Completer<void>();
        await tester.tap(find.text('确认分项红冲'));
        await tester.pump();
        if (cancel) {
          await tester.tap(find.text('关闭'));
          await tester.pump();
        } else {
          loader.soutContext = Object();
        }
        loader.pending!.complete();
        await tester.pumpAndSettle();
        expect(loader.partial, isEmpty);
      },
    );
  }
  testWidgets('whole needs confirmation; uncertain partial cannot resubmit', (
    tester,
  ) async {
    final loader = Loader()..network = true;
    await open(tester, loader);
    await tester.tap(find.text('OUT1'));
    await tester.pump();
    await tester.tap(find.text('红冲整单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(loader.whole, isEmpty);
    await tester.tap(find.text('红冲整单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定红冲'));
    await tester.pumpAndSettle();
    expect(loader.whole, ['1']);
    await tester.tap(find.text('OUT1'));
    await tester.pump();
    await tester.tap(find.text('红冲'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sout-hc-31')), '1');
    await tester.tap(find.text('确认分项红冲'));
    await tester.pumpAndSettle();
    expect(loader.partial, [
      {31: 1.0},
    ]);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认分项红冲'))
          .onPressed,
      isNull,
    );
  });
}
