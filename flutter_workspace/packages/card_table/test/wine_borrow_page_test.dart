import 'package:card_table/src/wine_borrow_return_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:card_table/src/wine_loader.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:foundation/foundation.dart';

import 'wine_borrow_form_test.dart' show FormLoader;

class PageLoader extends FormLoader implements WineBorrowPageLoader {
  final queries = <Map<String, Object?>>[];
  final pending = <String, Completer<Result<WineBorrowReturnPage>>>{};
  bool failPage = false;
  @override
  Future<Result<WineBorrowReturnPage>> loadWineBorrowReturnPage({
    required int type,
    required int page,
    int pageSize = 20,
    required String beginDay,
    required String endDay,
    String keyword = '',
  }) async {
    queries.add({
      'type': type,
      'page': page,
      'size': pageSize,
      'begin': beginDay,
      'end': endDay,
      'key': keyword,
    });
    if (pending[keyword] case final gate?) return gate.future;
    if (failPage) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.network,
          code: 'test',
          safeMessage: '查询失败',
        ),
      );
    }
    return Success(pageData('第$page页记录'));
  }
}

WineBorrowReturnPage pageData(String name) => WineBorrowReturnPage(
  total: 41,
  items: [
    WineBorrowReturnItem(
      id: '1',
      type: 1,
      wineName: name,
      unit: '瓶',
      count: 1,
      personName: '甲',
      opTime: '2026-09-20',
    ),
  ],
);

void main() {
  testWidgets('page response after identity change is rejected', (
    tester,
  ) async {
    final loader = PageLoader();
    loader.pending[''] = Completer<Result<WineBorrowReturnPage>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WineBorrowView(loader: loader)),
      ),
    );
    await tester.pump();
    loader.borrowFormContext = Object();
    loader.pending['']!.complete(Success(pageData('旧身份数据')));
    await tester.pumpAndSettle();
    expect(find.text('旧身份数据'), findsNothing);
    expect(find.textContaining('登录或连接状态已改变'), findsOneWidget);
  });
  for (final returning in [false, true]) {
    testWidgets('date and paging contract returning=$returning', (
      tester,
    ) async {
      final loader = PageLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: returning
                ? WineReturnView(
                    loader: loader,
                    now: () => DateTime(2026, 9, 20),
                  )
                : WineBorrowView(
                    loader: loader,
                    now: () => DateTime(2026, 9, 20),
                  ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(loader.queries.last, {
        'type': returning ? 2 : 1,
        'page': 1,
        'size': 20,
        'begin': '2026-09-13',
        'end': '2026-09-20',
        'key': '',
      });
      await tester.tap(find.text('下一页'));
      await tester.pumpAndSettle();
      expect(loader.queries.last['page'], 2);
      expect(find.text('21'), findsOneWidget);
      for (final days in [30, 90]) {
        await tester.tap(find.text(days == 90 ? '近3个月' : '近30天'));
        await tester.pumpAndSettle();
        expect(loader.queries.last['page'], 1);
        expect(
          loader.queries.last['begin'],
          days == 30 ? '2026-08-21' : '2026-06-22',
        );
      }
      await tester.enterText(
        find.byKey(const Key('wine-list-begin')),
        '2026-08-01',
      );
      await tester.enterText(
        find.byKey(const Key('wine-list-end')),
        '2026-08-31',
      );
      await tester.enterText(find.byKey(const Key('wine-list-search')), '备注');
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(loader.queries.last['begin'], '2026-08-01');
      expect(loader.queries.last['end'], '2026-08-31');
      expect(loader.queries.last['key'], '备注');
      await tester.enterText(find.byKey(const Key('wine-list-search')), '未提交');
      await tester.tap(find.text('下一页'));
      await tester.pumpAndSettle();
      expect(loader.queries.last['key'], '备注');
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(loader.queries.last['page'], 1);
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(loader.queries.last['begin'], '2026-09-13');
      expect(loader.queries.last['key'], '');
      final count = loader.queries.length;
      await tester.enterText(
        find.byKey(const Key('wine-list-begin')),
        '2026-09-31',
      );
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(loader.queries.length, count);
      expect(find.textContaining('有效起止日期'), findsOneWidget);
    });
  }
  testWidgets(
    'older response cannot replace latest filter and failed reads are visible',
    (tester) async {
      final loader = PageLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WineBorrowView(loader: loader)),
        ),
      );
      await tester.pumpAndSettle();
      loader.pending['旧'] = Completer<Result<WineBorrowReturnPage>>();
      loader.pending['新'] = Completer<Result<WineBorrowReturnPage>>();
      await tester.enterText(find.byKey(const Key('wine-list-search')), '旧');
      await tester.tap(find.text('查询'));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('wine-list-search')), '新');
      await tester.tap(find.text('查询'));
      await tester.pump();
      loader.pending['新']!.complete(Success(pageData('新结果')));
      await tester.pumpAndSettle();
      loader.pending['旧']!.complete(Success(pageData('旧结果')));
      await tester.pumpAndSettle();
      expect(find.text('新结果'), findsOneWidget);
      expect(find.text('旧结果'), findsNothing);
      loader.failPage = true;
      await tester.enterText(find.byKey(const Key('wine-list-search')), '失败');
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(find.textContaining('加载错误: 查询失败'), findsOneWidget);
      expect(find.text('新结果'), findsNothing);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '下一页'))
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'borrow records expose original quick date filters and paging on phone',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: WineBorrowView(loader: FormLoader())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('近7天'), findsOneWidget);
      expect(find.text('近30天'), findsOneWidget);
      expect(find.text('近3个月'), findsOneWidget);
      expect(find.byKey(const Key('wine-list-begin')), findsOneWidget);
      expect(find.byKey(const Key('wine-list-end')), findsOneWidget);
      expect(find.text('上一页'), findsOneWidget);
      expect(find.text('下一页'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
