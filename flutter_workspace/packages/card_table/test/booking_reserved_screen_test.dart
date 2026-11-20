import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('BookingReservedScreen loads and displays reserved items', (
    tester,
  ) async {
    final items = [
      const BookingReservedItem(
        id: '101',
        bookId: '101',
        departmentName: '营销一部',
        orderPersonName: '李四',
        orderPersonCode: '8001',
        expArriveTime: '2026-09-15 20:00',
        minConsumeYuan: '500',
        customerCount: '4',
        customerName: '王总',
        customerPhone: '13812345678',
        seatName: 'V01',
        remark: '需要冰块',
      ),
    ];

    bool backCalled = false;
    bool logoutCalled = false;
    List<String>? cancelledIds;

    await tester.pumpWidget(
      MaterialApp(
        home: BookingReservedScreen(
          onLoadReservedList: ({required isToday, futureType = 1}) async {
            return Success(items);
          },
          onCancelReservedInfo: (ids) async {
            cancelledIds = ids;
            return const Success(null);
          },
          onBackToCardMachine: () {
            backCalled = true;
          },
          onLogout: () {
            logoutCalled = true;
          },
          userName: '测试员工',
          employeeId: '9999',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and items
    expect(find.text('当日预留'), findsOneWidget);
    expect(find.text('其它预留'), findsOneWidget);
    expect(find.text('王总'), findsOneWidget);
    expect(find.text('营销一部'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);
    expect(find.text('V01'), findsOneWidget);

    // Verify back to cardMachine button (S1.P2.T02)
    expect(find.byKey(BookingReservedScreen.backCardMachineKey), findsOneWidget);
    await tester.tap(find.byKey(BookingReservedScreen.backCardMachineKey));
    await tester.pump();
    expect(backCalled, isTrue);
    expect(cancelledIds, isNull);

    // Verify account menu (S1.P2.T03)
    expect(find.text('工号：9999'), findsOneWidget);
    await tester.tap(find.byKey(BookingReservedScreen.accountMenuKey));
    await tester.pumpAndSettle();
    expect(find.text('修改密码'), findsOneWidget);
    expect(find.text('退出登录'), findsOneWidget);
    await tester.tap(find.byKey(BookingReservedScreen.logoutKey));
    await tester.pump();
    expect(logoutCalled, isTrue);
  });

  testWidgets('BookingReservedScreen search and tab switching work', (
    tester,
  ) async {
    final todayItems = [
      const BookingReservedItem(
        id: '1',
        bookId: '1',
        departmentName: '二部',
        orderPersonName: '张三',
        orderPersonCode: '101',
        expArriveTime: '2026-09-14 21:00',
        minConsumeYuan: '800',
        customerCount: '6',
        customerName: '陈总',
        customerPhone: '13900001111',
        seatName: 'K01',
        remark: '',
      ),
      const BookingReservedItem(
        id: '2',
        bookId: '2',
        departmentName: '三部',
        orderPersonName: '赵六',
        orderPersonCode: '102',
        expArriveTime: '2026-09-14 22:00',
        minConsumeYuan: '1000',
        customerCount: '8',
        customerName: '刘总',
        customerPhone: '13900002222',
        seatName: 'K02',
        remark: '',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: BookingReservedScreen(
          onLoadReservedList: ({required isToday, futureType = 1}) async {
            return Success(todayItems);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('陈总'), findsOneWidget);
    expect(find.text('刘总'), findsOneWidget);

    // Search for 陈总
    await tester.enterText(find.byKey(BookingReservedScreen.searchKey), '陈总');
    await tester.tap(find.byKey(BookingReservedScreen.searchBtnKey));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == '陈总'),
      findsOneWidget,
    );
    expect(find.text('刘总'), findsNothing);

    // Reset search
    await tester.tap(find.byKey(BookingReservedScreen.resetBtnKey));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == '陈总'),
      findsOneWidget,
    );
    expect(find.text('刘总'), findsOneWidget);

    // Switch to 其它预留 tab
    await tester.tap(find.byKey(BookingReservedScreen.tabFutureKey));
    await tester.pumpAndSettle();

    // Verify sub-date buttons appear
    expect(find.text('明天'), findsOneWidget);
    expect(find.text('未来7天'), findsOneWidget);
    expect(find.text('全部'), findsOneWidget);
  });

  testWidgets('BookingReservedScreen triggers date filters and edit reservation', (
    tester,
  ) async {
    final calls = <({bool isToday, int futureType})>[];
    BookingCardWriteAction? writeAction;
    Map<String, Object?>? writeFields;
    String? writeSeatId;
    String? writeBookId;

    final tomorrowItem = const BookingReservedItem(
      id: '888',
      bookId: '888',
      departmentName: '一部',
      orderPersonName: '张经理',
      orderPersonCode: '100',
      expArriveTime: '2026-09-29 19:00',
      minConsumeYuan: '600',
      customerCount: '4',
      customerName: '孙总',
      customerPhone: '13700003333',
      seatName: 'V08',
      seatId: '58',
      remark: '无',
      isToday: false,
    );

    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BookingReservedScreen(
          onLoadReservedList: ({required isToday, futureType = 1}) async {
            calls.add((isToday: isToday, futureType: futureType));
            if (!isToday && futureType == 1) {
              return Success([tomorrowItem]);
            }
            return const Success([]);
          },
          onLoadBookDetail: (bookId) async {
            expect(bookId, '888');
            return Success(BookingBookDetail.fromWire(_completeDetail));
          },
          onBookingCardWrite: ({
            required action,
            required seatId,
            bookId = '',
            fields = const {},
            canDispatch,
          }) async {
            writeAction = action;
            writeSeatId = seatId;
            writeBookId = bookId;
            writeFields = fields;
            return const Success(null);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(calls.length, 1);
    expect(calls.first.isToday, isTrue);

    // Switch to 其它预留 -> loads futureType = 1 (明天)
    await tester.tap(find.byKey(BookingReservedScreen.tabFutureKey));
    await tester.pumpAndSettle();

    expect(calls.length, 2);
    expect(calls[1].isToday, isFalse);
    expect(calls[1].futureType, 1);
    expect(find.text('孙总'), findsOneWidget);

    // Tap "未来7天"
    await tester.tap(find.text('未来7天'));
    await tester.pumpAndSettle();

    expect(calls.length, 3);
    expect(calls[2].isToday, isFalse);
    expect(calls[2].futureType, 2);

    // Tap "全部"
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();

    expect(calls.length, 4);
    expect(calls[3].isToday, isFalse);
    expect(calls[3].futureType, 3);

    // Switch back to "明天" to test edit
    await tester.tap(find.text('明天'));
    await tester.pumpAndSettle();

    expect(find.text('编辑'), findsOneWidget);
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();

    // Verify edit dialog opened
    expect(find.text('编辑预留 - V08'), findsOneWidget);
    expect(find.text('保存修改'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '备注'), '只改备注');
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();

    expect(writeAction, BookingCardWriteAction.updateReserve);
    expect(writeSeatId, '108');
    expect(writeBookId, '888');
    expect(writeFields, {..._completeDetail, 'remark': '只改备注'});
    expect(writeFields?['customer_name'], '孙总详情');
    expect(writeFields?['customer_phone'], '13700003333');
  });

  testWidgets('latest date request wins while older reads are pending', (tester) async {
    final requests = <({bool today, int type, Completer<Result<List<BookingReservedItem>>> result})>[];
    await tester.pumpWidget(MaterialApp(home: BookingReservedScreen(
      onLoadReservedList: ({required isToday, futureType = 1}) {
        final result = Completer<Result<List<BookingReservedItem>>>();
        requests.add((today: isToday, type: futureType, result: result));
        return result.future;
      },
    )));
    await tester.pump();
    await tester.tap(find.byKey(BookingReservedScreen.tabFutureKey));
    await tester.pump();
    await tester.tap(find.text('未来7天'));
    await tester.pump();
    expect(requests.map((r) => (r.today, r.type)), [(true, 1), (false, 1), (false, 2)]);
    requests[0].result.complete(const FailureResult(AppFailure(
      kind: FailureKind.unknown, code: 'old', safeMessage: '过期错误',
    )));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('过期错误'), findsNothing);
    requests.last.result.complete(const Success([]));
    await tester.pumpAndSettle();
    expect(find.text('暂无预留数据'), findsOneWidget);
    requests[1].result.completeError(StateError('stale request'));
    await tester.pumpAndSettle();
    expect(find.text('过期错误'), findsNothing);
    expect(find.text('获取预留数据失败'), findsNothing);
    expect(find.text('暂无预留数据'), findsOneWidget);
  });


  testWidgets('unchanged server values survive a save without list defaults', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    final original = {..._completeDetail, 'customer_name': '  详情客户  ',
      'customer_exp_cnt': 0, 'exp_min_csm_amt': 0, 'is_this_wkday': 1};
    Map<String, Object?>? saved;
    await tester.pumpWidget(MaterialApp(home: BookingReservedScreen(
      onLoadReservedList: ({required isToday, futureType = 1}) async =>
          const Success([_testItem]),
      onLoadBookDetail: (_) async => Success(BookingBookDetail.fromWire(original)),
      onBookingCardWrite: ({required action, required seatId, bookId = '',
          fields = const {}, canDispatch}) async {
        saved = fields;
        return const Success(null);
      },
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();
    expect(saved, original);
  });

  testWidgets('changing date invalidates a pending reservation edit', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    final detail = Completer<Result<BookingBookDetail>>();
    var writes = 0;
    await tester.pumpWidget(MaterialApp(home: BookingReservedScreen(
      onLoadReservedList: ({required isToday, futureType = 1}) async =>
          isToday ? const Success([_testItem]) : const Success([]),
      onLoadBookDetail: (_) => detail.future,
      onBookingCardWrite: ({required action, required seatId, bookId = '',
          fields = const {}, canDispatch}) async {
        writes++;
        return const Success(null);
      },
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑'));
    await tester.pump();
    await tester.tap(find.byKey(BookingReservedScreen.tabFutureKey));
    await tester.pumpAndSettle();
    detail.complete(Success(BookingBookDetail.fromWire(_completeDetail)));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('保存修改'), findsNothing);
    expect(writes, 0);
  });

  testWidgets('only the latest requested reservation edit opens a dialog', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    final details = <String, Completer<Result<BookingBookDetail>>>{
      '1': Completer<Result<BookingBookDetail>>(),
      '2': Completer<Result<BookingBookDetail>>(),
    };
    final savedIds = <String>[];
    await tester.pumpWidget(MaterialApp(home: BookingReservedScreen(
      onLoadReservedList: ({required isToday, futureType = 1}) async =>
          const Success([_testItem, _testItemB]),
      onLoadBookDetail: (id) => details[id]!.future,
      onBookingCardWrite: ({required action, required seatId, bookId = '',
          fields = const {}, canDispatch}) async {
        savedIds.add(bookId);
        return const Success(null);
      },
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑').at(0));
    await tester.pump();
    await tester.tap(find.text('编辑').at(1));
    await tester.pump();
    details['2']!.complete(Success(BookingBookDetail.fromWire(_completeDetail)));
    await tester.pumpAndSettle();
    expect(find.text('编辑预留 - B01'), findsOneWidget);
    details['1']!.complete(Success(BookingBookDetail.fromWire(_completeDetail)));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog, skipOffstage: false), findsOneWidget);
    expect(find.text('编辑预留 - A01'), findsNothing);
    expect(find.text('编辑预留 - B01'), findsOneWidget);
    await tester.tap(find.text('保存修改'));
    await tester.pumpAndSettle();
    expect(savedIds, ['2']);
  });

  for (final failureMode in ['missing', 'failure', 'incomplete', 'throws']) {
    testWidgets('editing is blocked for $failureMode detail', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      var writes = 0;
      await tester.pumpWidget(MaterialApp(home: BookingReservedScreen(
        onLoadReservedList: ({required isToday, futureType = 1}) async =>
            const Success([_testItem]),
        onLoadBookDetail: failureMode == 'missing' ? null : (_) async {
          if (failureMode == 'throws') {
            throw StateError('offline');
          }
          if (failureMode == 'failure') {
            return const FailureResult(AppFailure(
              kind: FailureKind.unknown, code: 'detail.failed', safeMessage: '详情暂不可用',
            ));
          }
          return Success(BookingBookDetail.fromWire({'customer_name': '不完整'}));
        },
        onBookingCardWrite: ({required action, required seatId, bookId = '',
            fields = const {}, canDispatch}) async {
          writes++;
          return const Success(null);
        },
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();
      expect(find.text('保存修改'), findsNothing);
      expect(writes, 0);
      expect(find.text(failureMode == 'failure' ? '详情暂不可用' :
          '预留详情不完整，无法安全修改，请重试'), findsOneWidget);
    });
  }

  testWidgets('changing date clears selected bookings before the next read completes', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
    final pending = Completer<Result<List<BookingReservedItem>>>();
    var deletes = 0;
    await tester.pumpWidget(MaterialApp(home: BookingReservedScreen(
      onLoadReservedList: ({required isToday, futureType = 1}) =>
          isToday ? Future.value(const Success([_testItem])) : pending.future,
      onCancelReservedInfo: (_) async { deletes++; return const Success(null); },
    )));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    await tester.tap(find.byKey(BookingReservedScreen.tabFutureKey));
    await tester.pump();
    expect(find.text('旧客户'), findsNothing);
    await tester.tap(find.byKey(BookingReservedScreen.deleteBtnKey));
    await tester.pump();
    expect(find.text('请选择需要删除的列表！'), findsOneWidget);
    expect(deletes, 0);
    pending.complete(const Success([]));
    await tester.pumpAndSettle();
  });

  testWidgets('a stale success cannot replace the latest date data', (tester) async {
    final reads = <Completer<Result<List<BookingReservedItem>>>>[];
    await tester.pumpWidget(MaterialApp(home: BookingReservedScreen(
      onLoadReservedList: ({required isToday, futureType = 1}) {
        final read = Completer<Result<List<BookingReservedItem>>>();
        reads.add(read);
        return read.future;
      },
    )));
    await tester.pump();
    await tester.tap(find.byKey(BookingReservedScreen.tabFutureKey));
    await tester.pump();
    reads.last.complete(const Success([]));
    await tester.pumpAndSettle();
    reads.first.complete(const Success([_testItem]));
    await tester.pumpAndSettle();
    expect(find.text('旧客户'), findsNothing);
    expect(find.text('暂无预留数据'), findsOneWidget);
  });

}


const _completeDetail = <String, Object?>{
  'customer_name': '孙总详情', 'customer_phone': '13700003333',
  'is_this_wkday': 2, 'book_day': '2026-11-28',
  'auto_send_msg': 1, 'exp_arrive_time': '202611281930',
  'sales_emp_id': 23, 'second_sales_emp_id': 24,
  'customer_exp_cnt': 6, 'exp_min_csm_amt': 880.5,
  'exp_region_id': 7, 'exp_seat_id': 108, 'exp_seat_ids': [108, 109],
  'remark': '详情备注', 'mark': 'VIP',
};

const _testItem = BookingReservedItem(
  id: '1', bookId: '1', departmentName: '', orderPersonName: '',
  orderPersonCode: '', expArriveTime: '', minConsumeYuan: '0',
  customerCount: '1', customerName: '旧客户', customerPhone: '',
  seatName: 'A01', remark: '',
);

const _testItemB = BookingReservedItem(
  id: '2', bookId: '2', departmentName: '', orderPersonName: '',
  orderPersonCode: '', expArriveTime: '', minConsumeYuan: '0',
  customerCount: '1', customerName: '客户B', customerPhone: '',
  seatName: 'B01', remark: '',
);
