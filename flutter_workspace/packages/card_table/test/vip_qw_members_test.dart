import 'dart:async';

import 'package:card_table/src/vip_manager.dart';
import 'package:card_table/src/vip_nav_screen.dart';
import 'package:card_table/src/vip_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

Future<void> open(WidgetTester tester, VipPages pages) async {
  await tester.pumpWidget(
    MaterialApp(
      home: VipNavScreen(
        onBack: () {},
        pages: pages,
        listCards: ({
          required int pageNum,
          required int pageSize,
          String keyword = '',
          bool init = false,
        }) async => const Success(VipCardPage(total: 0)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('企微会员'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  testWidgets(
    'query button sends entered keyword and pagination resets on query and reset',
    (tester) async {
      final calls = <(int, int, String)>[];
      await open(
        tester,
        VipPages(
          listQwMembers:
              ({
                int pageNum = 1,
                int pageSize = 10,
                String keyword = '',
              }) async {
                calls.add((pageNum, pageSize, keyword));
                return Success(
                  VipReportPage(
                    total: 21,
                    records: [
                      {'n': '会员$pageNum', 'p': '138', 't': '今天'},
                    ],
                  ),
                );
              },
        ),
      );
      await tester.enterText(find.byType(TextField), '昵称A');
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(calls.last, (1, 10, '昵称A'));
      expect(find.text('共 21 条 · 第 1 / 3 页'), findsOneWidget);
      await tester.tap(find.text('下一页'));
      await tester.pumpAndSettle();
      expect(calls.last, (2, 10, '昵称A'));
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(calls.last, (1, 10, '昵称A'));
      await tester.tap(find.text('下一页'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(calls.last, (1, 10, ''));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '',
      );
    },
  );

  testWidgets(
    'late query cannot replace newer result and failure has explicit retry',
    (tester) async {
      final pending = Completer<Result<VipReportPage>>();
      var count = 0;
      await open(
        tester,
        VipPages(
          listQwMembers:
              ({
                int pageNum = 1,
                int pageSize = 10,
                String keyword = '',
              }) async {
                count++;
                if (count == 1) return pending.future;
                if (count == 3)
                  return const FailureResult(
                    AppFailure(
                      kind: FailureKind.network,
                      code: 'offline',
                      safeMessage: '查询失败',
                    ),
                  );
                return const Success(
                  VipReportPage(
                    total: 1,
                    records: [
                      {'n': '新结果'},
                    ],
                  ),
                );
              },
        ),
      );
      await tester.enterText(find.byType(TextField), '新');
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      pending.complete(
        const Success(
          VipReportPage(
            total: 50,
            records: [
              {'n': '旧结果'},
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('新结果'), findsOneWidget);
      expect(find.text('旧结果'), findsNothing);
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(find.text('查询失败'), findsOneWidget);
      expect(find.text('新结果'), findsNothing);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('新结果'), findsOneWidget);
    },
  );

  testWidgets('standalone VIP hides search but preserves read pagination', (
    tester,
  ) async {
    final calls = <int>[];
    await open(
      tester,
      VipPages(
        configurationAccess: () => false,
        listQwMembers:
            ({int pageNum = 1, int pageSize = 10, String keyword = ''}) async {
              calls.add(pageNum);
              return const Success(VipReportPage(total: 11));
            },
      ),
    );
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('下一页'));
    await tester.pumpAndSettle();
    expect(calls, [1, 2]);
    final next = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '下一页'),
    );
    expect(next.onPressed, isNull);
    await tester.tap(find.text('上一页'));
    await tester.pumpAndSettle();
    expect(calls.last, 1);
  });
}
