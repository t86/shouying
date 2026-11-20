import 'dart:async';

import 'package:card_table/src/vip_pages.dart';
import 'package:card_table/src/vip_nav_screen.dart';
import 'package:card_table/src/vip_manager.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

VipNavScreen screen(VipPages pages) => VipNavScreen(
  onBack: () {},
  pages: pages,
  listCards: ({
    required int pageNum,
    required int pageSize,
    String keyword = '',
    bool init = false,
  }) async => const Success(VipCardPage(total: 0)),
);

void main() {
  testWidgets('relationship report exposes source employee selector', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: screen(
          VipPages(
            employees: () => const [
              CardEmployee(
                id: '42',
                name: '员工九',
                deptId: '1',
                code: '009',
                namePy: 'ygj',
              ),
            ],
            exportReport:
                ({
                  required kind,
                  pageNum = 1,
                  pageSize = 20,
                  beginDay = '',
                  endDay = '',
                  keyword = '',
                  typeId = 0,
                  salesEmpId = '',
                  canDispatch,
                }) async {
                  selected.add(salesEmpId);
                  return const Success(null);
                },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('报表管理'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('客户关系维护表'));
    await tester.tap(find.text('客户关系维护表'));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == '开卡推荐人（工号/姓名/拼音）',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == '开卡推荐人（工号/姓名/拼音）',
      ),
      '009',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('员工九 (009)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导出'));
    await tester.pumpAndSettle();
    expect(selected, ['42']);
  });
  testWidgets(
    'level export sends visible filter and current page, not hardcoded first page',
    (tester) async {
      final calls = <(VipReportKind, int, String)>[];
      await tester.pumpWidget(
        MaterialApp(
          home: screen(
            VipPages(
              queryReport: ({
                required kind,
                pageNum = 1,
                pageSize = 20,
                beginDay = '',
                endDay = '',
                keyword = '',
                typeId = 0,
                salesEmpId = '0',
              }) async => const Success(VipReportPage(total: 41)),
              exportReport:
                  ({
                    required kind,
                    pageNum = 1,
                    pageSize = 20,
                    beginDay = '',
                    endDay = '',
                    keyword = '',
                    typeId = 0,
                    salesEmpId = '0',
                    canDispatch,
                  }) async {
                    expect(canDispatch?.call(), true);
                    calls.add((kind, pageNum, keyword));
                    return const Success(null);
                  },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('报表管理'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('更改等级记录表'));
      await tester.tap(find.text('更改等级记录表'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == '姓名/手机号/会员卡号',
        ),
        '张三',
      );
      await tester.tap(find.text('下一页'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('导出'));
      await tester.pumpAndSettle();
      expect(calls.single, (VipReportKind.changeLevel, 2, '张三'));
      expect(find.text('导出成功'), findsOneWidget);
    },
  );

  testWidgets('back transition immediately invalidates export before dispose', (
    tester,
  ) async {
    bool Function()? dispatch;
    final done = Completer<Result<void>>();
    final nav = GlobalKey<NavigatorState>();
    final pages = VipPages(
      exportReport:
          ({
            required kind,
            pageNum = 1,
            pageSize = 20,
            beginDay = '',
            endDay = '',
            keyword = '',
            typeId = 0,
            salesEmpId = '0',
            canDispatch,
          }) {
            dispatch = canDispatch;
            return done.future;
          },
    );
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: Text('home')),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => screen(pages)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('报表管理'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导出'));
    await tester.pump();
    expect(dispatch?.call(), true);
    nav.currentState!.pop();
    await tester.pump();
    expect(dispatch?.call(), false);
    done.complete(const Success(null));
    await tester.pumpAndSettle();
    expect(find.text('导出成功'), findsNothing);
  });
}
