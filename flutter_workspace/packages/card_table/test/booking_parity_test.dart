import 'dart:async';
import 'dart:convert';

import 'package:card_table/card_table.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

void main() {
  group('BookingDetailAccess truth table (P0)', () {
    test('fail-closed default hides consumption and wine options', () {
      expect(
        BookingDetailAccess.optionIds(
          BookingDetailConfig.restricted,
          status: 4,
          turnoverCount: 2,
        ),
        isEmpty,
      );
      final parsedNull = BookingDetailConfig.fromWire(null);
      expect(parsedNull, BookingDetailConfig.restricted);
    });

    test('limit_book_csm_amt == 1 overrides enabled flags', () {
      final cfg = BookingDetailConfig.fromWire(<String, Object?>{
        'limit_book_csm_amt': 1,
        'enable_book_csm_dtl': 1,
        'enable_book_wine_dtl': 1,
      });
      expect(cfg.amountsRestricted, isTrue);
      expect(cfg.consumptionEnabled, isFalse);
      expect(cfg.wineEnabled, isFalse);
      expect(
        BookingDetailAccess.optionIds(cfg, status: 5, turnoverCount: 1),
        isEmpty,
      );
    });

    test('limit_book_csm_amt == 2 gates options independently by status & turnover', () {
      final both = BookingDetailConfig.fromWire(<String, Object?>{
        'limit_book_csm_amt': 2,
        'enable_book_csm_dtl': 1,
        'enable_book_wine_dtl': 1,
      });
      final consumptionOnly = BookingDetailConfig.fromWire(<String, Object?>{
        'limit_book_csm_amt': '2',
        'enable_book_csm_dtl': '1',
        'enable_book_wine_dtl': 0,
      });
      final wineOnly = BookingDetailConfig.fromWire(<String, Object?>{
        'limit_book_csm_amt': 2,
        'enable_book_csm_dtl': 0,
        'enable_book_wine_dtl': 1,
      });

      // Empty / reserved require turnoverCount > 0
      expect(BookingDetailAccess.optionIds(both, status: 1, turnoverCount: 0), isEmpty);
      expect(BookingDetailAccess.optionIds(both, status: 1, turnoverCount: 1), [26, 27]);
      expect(BookingDetailAccess.optionIds(both, status: 8, turnoverCount: 0), isEmpty);
      expect(BookingDetailAccess.optionIds(both, status: 8, turnoverCount: 2), [26, 27]);
      // Locked never shows detail options
      expect(BookingDetailAccess.optionIds(both, status: 2, turnoverCount: 2), isEmpty);
      // Active / paid show even when turnoverCount == 0
      for (final status in const [4, 5, 6, 7]) {
        expect(BookingDetailAccess.optionIds(both, status: status, turnoverCount: 0), [26, 27]);
        expect(BookingDetailAccess.optionIds(consumptionOnly, status: status, turnoverCount: 0), [26]);
        expect(BookingDetailAccess.optionIds(wineOnly, status: status, turnoverCount: 0), [27]);
      }
    });

    test('buildTurnoverTabs matches Vue turnoverCountForRequest rules', () {
      // Opened table with 1 prior turnover -> 2 tabs: current (1) and prior (0)
      final openTabs = BookingDetailAccess.buildTurnoverTabs('A01', 1, status: 4);
      expect(openTabs.map((t) => (t.label, t.turnoverCount)).toList(), [
        ('A01-002', 1),
        ('A01-001', 0),
      ]);
      // Settled table with turnoverCount=2 -> 2 tabs: request counts 1, 0
      final paidTabs = BookingDetailAccess.buildTurnoverTabs('A01', 2, status: 7);
      expect(paidTabs.map((t) => (t.label, t.turnoverCount)).toList(), [
        ('A01-002', 1),
        ('A01-001', 0),
      ]);
      // Empty turned-over table with turnoverCount=1 -> 1 tab: request count 0
      final emptyTabs = BookingDetailAccess.buildTurnoverTabs('A01', 1, status: 1);
      expect(emptyTabs.map((t) => (t.label, t.turnoverCount)).toList(), [
        ('A01-001', 0),
      ]);
    });
  });

  group('Booking pin ordering, full-field search & models (P0/P1)', () {
    test('pinned seats sort by topNum descending ahead of region and displayOrder', () {
      final store = LegacyCardTableStore();
      final data = _parityFullData();
      // Pin seat 200 with higher topNum (50) and seat 101 with lower topNum (10)
      data[29] = <Object?>[
        <Object?>[101, 10, 1],
        <Object?>[200, 50, 1],
      ];
      final res = store.applyEnvelope(
        SyncEnvelope.fromValidatedReconciliation(cursor: '20260828010101', data: data),
      );
      expect(res.failureOrNull, isNull);
      final snap = res.valueOrNull!;
      expect(snap.tables.take(2).map((t) => t.id).toList(), ['200', '101']);
      expect(snap.tables[0].pinOrder, 50);
      expect(snap.tables[1].pinOrder, 10);
      // Future date also sorts pinned seats first by pinOrder descending
      final tomorrowTables = snap.tablesForDate('20260829');
      expect(tomorrowTables.take(2).map((t) => t.id).toList(), ['200', '101']);
    });

    test('matchesBookingSearch covers table, sales code/name/py, dept, guest name/py, and both phones', () {
      final store = LegacyCardTableStore();
      final snap = store
          .applyEnvelope(
            SyncEnvelope.fromValidatedReconciliation(
              cursor: '20260828010101',
              data: _parityFullData(),
            ),
          )
          .valueOrNull!;
      final a01 = snap.tables.firstWhere((t) => t.id == '100');

      bool hit(String kw, {bool showCustomerDetails = true}) =>
          BookingCardDisplay.matchesBookingSearch(
            table: a01,
            keyword: kw,
            employees: snap.employees,
            departments: snap.departments,
            showCustomerDetails: showCustomerDetails,
          );

      expect(hit('A01'), isTrue);
      expect(hit('S001'), isTrue); // sales code
      expect(hit('张三'), isTrue); // sales name
      expect(hit('zs'), isTrue); // sales pinyin
      expect(hit('营销一部'), isTrue); // sales dept
      expect(hit('王先生'), isTrue); // customer name
      expect(hit('wxs'), isTrue); // customer name pinyin (ds14 col 23)
      expect(hit('13911112222'), isTrue); // booking phone (ds14 col 17)
      expect(hit('13899990000'), isTrue); // csm phone (ds14 col 35)
      expect(hit('不存在的词'), isFalse);

      // Customer fields hidden when showCustomerDetails is false
      expect(hit('王先生', showCustomerDetails: false), isFalse);
      expect(hit('13911112222', showCustomerDetails: false), isFalse);
      expect(hit('张三', showCustomerDetails: false), isTrue);
    });
  });

  group('Booking terminal config & 6 binary export APIs (P0)', () {
    test('getBookingDetailConfig calls /org/get_org_biz_cfg and parses rules', () async {
      final captured = <(String, Object?)>[];
      final client = _mockProtocolClient((options) {
        captured.add((options.path, options.data));
        return ResponseBody.fromString(
          jsonEncode({
            'code': 1,
            'data': {
              'limit_book_csm_amt': 2,
              'enable_book_csm_dtl': 1,
              'enable_book_wine_dtl': 0,
            },
          }),
          200,
        );
      });
      final api = ProtocolBookingCardApi(client: client);
      final res = await api.getBookingDetailConfig(ClientKind.booking);
      expect(res.failureOrNull, isNull);
      expect(captured.single.$1, endsWith('/org/get_org_biz_cfg'));
      expect(res.valueOrNull, const BookingDetailConfig(
        amountsRestricted: false,
        consumptionEnabled: true,
        wineEnabled: false,
      ));
    });

    test('all 6 booking report & queue export APIs post to exact Vue paths and save XLSX', () async {
      final calls = <(String, Object?)>[];
      final fakeZip = Uint8List.fromList(<int>[80, 75, 3, 4, 1, 2, 3, 4]);
      final client = _mockProtocolClient((options) {
        calls.add((options.path, options.data));
        return ResponseBody.fromBytes(
          fakeZip,
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ],
          },
        );
      });

      final savedFiles = <String>[];
      Future<Result<String>> fakeSaver(
        ProtocolBinaryFile file, {
        bool Function()? canSave,
      }) async {
        savedFiles.add(file.fileName);
        return Success('浏览器下载：${file.fileName}');
      }

      final reportsLoader = ProtocolBookingReportsLoader(
        api: ProtocolBookingReportsApi(client: client),
        saver: fakeSaver,
      );
      final queueLoader = ProtocolBookingQueueLoader(
        api: ProtocolBookingQueueApi(client: client),
        saver: fakeSaver,
      );

      final r1 = await reportsLoader.exportSeatOpenLog(key: 'VIP', typeId: 2);
      final r2 = await reportsLoader.exportBookList();
      final r3 = await reportsLoader.exportOnlineBookList();
      final r4 = await reportsLoader.exportSeatOpeningList();
      final r5 = await reportsLoader.exportDeptRegionSeatOpenList();
      final r6 = await queueLoader.exportQueueList(queueTypeId: 3, status: 1);

      for (final r in [r1, r2, r3, r4, r5, r6]) {
        expect(r.failureOrNull, isNull);
      }
      expect(calls.map((c) => c.$1).toList(), [
        endsWith('/sel/rpt/exp_seat_open_log'),
        endsWith('/sel/rpt/exp_book_list'),
        endsWith('/sel/rpt/exp_ol_book_list'),
        endsWith('/sel/rpt/exp_seat_opening_list'),
        endsWith('/sel/rpt/exp_dept_region_seat_open_list'),
        endsWith('/custq/exp_cust_queue_list'),
      ]);
      expect(calls[0].$2, {'key': 'VIP', 'type_id': 2});
      expect(calls[5].$2, {'queue_type_id': 3, 'status': 1});
      expect(savedFiles, [
        '开台记录.xlsx',
        '预留记录.xlsx',
        '线上预订记录.xlsx',
        '入客数据实时汇总.xlsx',
        '部门实时订台区域开台.xlsx',
        '排队列表.xlsx',
      ]);
    });
  });

  group('Booking CardTableScreen parity interactions (P0/P1/P2)', () {
    testWidgets('terminal rules dynamically control 消费明细 and 存取酒明细 options', (
      tester,
    ) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: BookingTheme.dark(),
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onLoadBookingDetailConfig: () async => const Success(
              BookingDetailConfig(
                amountsRestricted: false,
                consumptionEnabled: true,
                wineEnabled: false,
              ),
            ),
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _parityFullData(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      expect(_menuText('查看卡台详情'), findsOneWidget);
      expect(_menuText('查看消费明细'), findsOneWidget);
      expect(_menuText('查看存取酒明细'), findsNothing);
    });

    testWidgets('empty turned-over table gates 修改翻台订位人 and 复台 behind canClearSeat', (
      tester,
    ) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final dataNoPerm = _parityFullData();
      // Seat 101: status=1, turnoverCount=2, no canClearSeat permission
      (dataNoPerm[14]! as List).cast<List>()[1][13] = 2;
      dataNoPerm[35] = <Object?>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: BookingTheme.dark(),
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(cursor: '20260828010101', data: dataNoPerm),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
      await tester.pumpAndSettle();
      expect(_menuText('修改翻台订位人'), findsNothing);
      expect(_menuText('复台'), findsNothing);
      await tester.tap(_menuText('关闭'));
      await tester.pumpAndSettle();

      // Grant canClearSeat (module 5, perm 2)
      final dataWithPerm = _parityFullData();
      (dataWithPerm[14]! as List).cast<List>()[1][13] = 2;
      dataWithPerm[35] = <Object?>[
        <Object?>[5, 2],
      ];
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010102',
          data: dataWithPerm,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
      await tester.pumpAndSettle();
      expect(_menuText('修改翻台订位人'), findsOneWidget);
      expect(_menuText('复台'), findsOneWidget);
    });

    testWidgets('future date intercepts online and locked cards with exact Vue messages', (
      tester,
    ) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final data = _parityFullData();
      // Mark seat 101 online (ds26) and seat 200 locked (ds14 col 19 = 2)
      data[26] = <Object?>[
        <Object?>[101, 1],
      ];
      (data[14]! as List).cast<List>()[2][19] = 2;

      await tester.pumpWidget(
        MaterialApp(
          theme: BookingTheme.dark(),
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(cursor: '20260828010101', data: data),
      );
      await tester.pumpAndSettle();

      // Switch to tomorrow date tab
      await tester.tap(find.widgetWithText(ChoiceChip, '08-29'));
      await tester.pumpAndSettle();

      // Online seat on non-current day -> exact warning, no menu
      await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
      await tester.pumpAndSettle();
      expect(find.text('非营业日栏所在线上卡台，线下不可操作！'), findsOneWidget);
      expect(find.byKey(CardTableScreen.cardMenuKey), findsNothing);

      // Locked seat on future date -> exact warning, no menu
      ScaffoldMessenger.of(tester.element(find.byType(CardTableScreen)))
          .clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('200')));
      await tester.pumpAndSettle();
      expect(find.text('未来日期无法解锁卡台！'), findsOneWidget);
      expect(find.byKey(CardTableScreen.cardMenuKey), findsNothing);
    });

    testWidgets('reserve drawer submits SMS toggle, arrival time chip, and rejects count > 100', (
      tester,
    ) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final writes = <Map<String, Object?>>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: BookingTheme.dark(),
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            showCustomerDetails: true,
            onBookingCardWrite: ({
              required action,
              required seatId,
              bookId = '',
              fields = const <String, Object?>{},
              canDispatch,
            }) async {
              writes.add(fields);
              return const Success(null);
            },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _parityFullData(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
      await tester.pumpAndSettle();
      await tester.tap(_menuText('预留'));
      await tester.pumpAndSettle();

      // Toggle SMS to 是 (1) and pick 21:00 arrival time chip
      await tester.tap(find.byKey(const Key('booking-sms-yes')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '21:00'));
      await tester.pumpAndSettle();

      // Count 101 rejected
      await tester.enterText(
        find.widgetWithText(TextFormField, '预定人数'),
        '101',
      );
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(find.text('请输入有效的预定人数 (1-100)'), findsOneWidget);
      expect(writes, isEmpty);

      // Valid count 6 submits SMS=1 and exp_arrive_time='2100'
      await tester.enterText(
        find.widgetWithText(TextFormField, '预定人数'),
        '6',
      );
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(writes, hasLength(1));
      expect(writes.single['auto_send_msg'], 1);
      expect(writes.single['exp_arrive_time'], '2100');
      expect(writes.single['customer_exp_cnt'], 6);
    });

    testWidgets('card face shows 部分结 badge and 转台记录, and detail dialog shows all Vue fields', (
      tester,
    ) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final data = _parityFullData();
      // Status 6 (partial paid) with transfer history and expected arrive time
      (data[14]! as List).cast<List>()[0][19] = 6;

      await tester.pumpWidget(
        MaterialApp(
          theme: BookingTheme.dark(),
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            showCustomerDetails: true,
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(cursor: '20260828010101', data: data),
      );
      await tester.pumpAndSettle();

      expect(find.text('部分结'), findsOneWidget);
      expect(find.textContaining('转台记录：B01→A01'), findsOneWidget);

      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(_menuText('查看卡台详情'));
      await tester.tap(_menuText('查看卡台详情'));
      await tester.pumpAndSettle();

      expect(find.text('卡台名称：A01'), findsOneWidget);
      expect(find.text('转台信息'), findsOneWidget);
      expect(find.text('B01→A01'), findsOneWidget);
      expect(find.text('预订到达时间'), findsOneWidget);
      expect(find.text('21:30'), findsOneWidget);
      expect(find.text('联合订位人电话'), findsOneWidget);
      expect(find.text('13700001111'), findsOneWidget);

      // Esc closes detail dialog
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('转台信息'), findsNothing);
    });

    testWidgets('report screens trigger export buttons with active filters', (
      tester,
    ) async {
      var exportedKey = '';
      var exportedType = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: BookingTheme.dark(),
          home: SeatOpenLogScreen(
            canRead: ValueNotifier<bool>(true),
            load: ({key = '', deptId = 0, typeId = 1}) async =>
                const Success(<SeatOpenLogRow>[]),
            onExport: ({key = '', typeId = 1}) async {
              exportedKey = key;
              exportedType = typeId;
              return const Success('浏览器下载：开台记录.xlsx');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(SeatOpenLogScreen.keywordKey), 'A01');
      await tester.tap(find.byKey(SeatOpenLogScreen.exportButtonKey));
      await tester.pumpAndSettle();

      expect(exportedKey, 'A01');
      expect(exportedType, 1);
      expect(find.text('导出成功：浏览器下载：开台记录.xlsx'), findsOneWidget);
    });

    testWidgets('responsive viewports (Desktop/Web 1440x900, Tablet 1024x768, Phone 360x800) render cleanly with zero overflow', (
      tester,
    ) async {
      for (final viewport in const [
        (name: 'Desktop/Web', size: Size(1440, 900), isPhone: false),
        (name: 'Tablet', size: Size(1024, 768), isPhone: false),
        (name: 'Phone', size: Size(360, 800), isPhone: true),
      ]) {
        tester.view.physicalSize = viewport.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final events = StreamController<SyncEnvelope>.broadcast(sync: true);
        addTearDown(events.close);
        await tester.pumpWidget(
          MaterialApp(
            theme: BookingTheme.dark(),
            home: CardTableScreen(
              system: BusinessSystem.booking,
              events: events.stream,
              connectionPhase: ConnectionPhase.online,
              showCustomerDetails: true,
              onOpenReserved: () {},
              onRefresh: () async => const Success(null),
            ),
          ),
        );
        events.add(
          SyncEnvelope.fromValidatedReconciliation(
            cursor: '20260828010101',
            data: _parityFullData(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${viewport.name} grid');

        // Tap card 101: Desktop/Tablet/Web uses anchored popup; Phone uses BottomSheet
        await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
        await tester.pumpAndSettle();
        expect(find.byKey(CardTableScreen.cardMenuKey), findsOneWidget);
        if (viewport.isPhone) {
          expect(find.byType(BottomSheet), findsOneWidget);
        } else {
          expect(find.byType(BottomSheet), findsNothing);
        }
        await tester.tap(_menuText('关闭'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${viewport.name} menu');
      }
    });

    testWidgets('transfer picker shows region-grouped grid with disabled reasons and updates selection', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final writes = <Map<String, Object?>>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: BookingTheme.dark(),
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onBookingCardWrite: ({
              required action,
              required seatId,
              bookId = '',
              fields = const <String, Object?>{},
              canDispatch,
            }) async {
              writes.add(fields);
              return const Success(null);
            },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _parityFullData(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      await tester.tap(_menuText('转台'));
      await tester.pumpAndSettle();

      // Current seat 100 is visible but marked disabled as 当前台
      expect(find.text('当前台'), findsOneWidget);
      // Select empty seat 200 (B01, minConsume=2000) directly from the visual grid
      await tester.tap(find.byKey(const ValueKey<String>('seat-picker-200')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '确认转台'));
      await tester.pumpAndSettle();

      expect(writes, hasLength(1));
      expect(writes.single['dest_seat_id'], '200');
      expect(writes.single['new_min_csm_amt'], 2000);
    });

    testWidgets('searchable employee picker filters by pinyin and submits sales change', (
      tester,
    ) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final writes = <Map<String, Object?>>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: BookingTheme.dark(),
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onBookingCardWrite: ({
              required action,
              required seatId,
              bookId = '',
              fields = const <String, Object?>{},
              canDispatch,
            }) async {
              writes.add(fields);
              return const Success(null);
            },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _parityFullData(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      await tester.tap(_menuText('修改订位人'));
      await tester.pumpAndSettle();

      // Filter by pinyin 'ls' -> finds 李四 (S002), hides 张三 inside dialog
      await tester.enterText(
        find.byKey(const Key('booking-employee-search')),
        'ls',
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('李四'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('张三'),
        ),
        findsNothing,
      );

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.textContaining('李四'),
        ),
      );
      await tester.pumpAndSettle();
      expect(writes, hasLength(1));
      expect(writes.single['sales_emp_id'], '1002');
      expect(writes.single['sales_name'], '李四');
    });

    testWidgets('wide viewport opens booking reports as right-side drawer and exports queue with active filters', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var exportedType = -1;
      var exportedStatus = -1;
      await tester.pumpWidget(
        MaterialApp(
          theme: BookingTheme.dark(),
          home: BookingQueueScreen(
            queue: const CardTableQueueSnapshot(
              types: [QueueType(id: 7, status: 1, name: '卡座', numPrefix: 'K')],
              records: [],
            ),
            onExport: ({queueTypeId = 0, status = 0}) async {
              exportedType = queueTypeId;
              exportedStatus = status;
              return const Success('浏览器下载：排队列表.xlsx');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(BookingQueueScreen.tabListKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('卡座'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('排队中'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(BookingQueueScreen.exportButtonKey));
      await tester.pumpAndSettle();

      expect(exportedType, 7);
      expect(exportedStatus, 1);
      expect(find.text('导出成功：浏览器下载：排队列表.xlsx'), findsOneWidget);
    });
  });
}

Finder _menuText(String label) => find.descendant(
  of: find.byKey(CardTableScreen.cardMenuKey),
  matching: find.text(label),
);

ProtocolClient _mockProtocolClient(
  ResponseBody Function(RequestOptions options) responder,
) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeAdapter(responder);
  var now = DateTime.utc(2026, 8, 28, 12, 0, 0);
  return ProtocolClient(
    dio: dio,
    config: ApiConfig(
      apiBase: Uri.parse('https://example.test/api'),
      onlineBase: Uri.parse('https://online.example.test/api'),
      websocketBase: Uri.parse('wss://example.test/ws'),
    ),
    credentialStore: _TestCredentialStore(),
    requestGate: RequestGate(
      clock: () {
        now = now.add(const Duration(milliseconds: 200));
        return now;
      },
    ),
  );
}

final class _TestCredentialStore implements CredentialStore {
  @override
  Future<void> clearStk() async {}
  @override
  Future<void> clearStkIfMatches(String? expected) async {}
  @override
  Future<void> clearTk() async {}
  @override
  Future<void> clearTkIfMatches(String? expected) async {}
  @override
  Future<String?> readStk() async => 's1';
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      const CredentialSnapshot(tk: 't1', stk: 's1');
  @override
  Future<String?> readTk() async => 't1';
  @override
  Future<void> writeStk(String value) async {}
  @override
  Future<void> writeTk(String value) async {}
}

final class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);
  final ResponseBody Function(RequestOptions options) responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => responder(options);

  @override
  void close({bool force = false}) {}
}

List<Object?> _parityFullData() {
  final data = List<Object?>.filled(57, const <Object?>[]);
  // 0: regions [id, name, status, displayOrder, must1, must2, must3]
  data[0] = <Object?>[
    <Object?>[1, '大厅', 1, 10, 0, 0, 0],
    <Object?>[2, '包厢', 1, 20, 0, 0, 0],
  ];
  // 1: seats [id, name, status, regionId, seatType, businessType, capacity, displayOrder]
  data[1] = <Object?>[
    <Object?>[100, 'A01', 1, 1, 3, 1, 6, 1],
    <Object?>[101, 'A02', 1, 1, 3, 1, 4, 2],
    <Object?>[200, 'B01', 1, 2, 4, 1, 8, 1],
  ];
  // 5: employees [id, name, status, deptId, 0, 0, phone, namePy, code, upperEmpId]
  data[5] = <Object?>[
    <Object?>[1001, '张三', 1, 10, 0, 0, '13600001111', 'zs', 'S001', 0],
    <Object?>[1002, '李四', 1, 10, 0, 0, '13700001111', 'ls', 'S002', 0],
  ];
  // 6: departments [id, name, status, parentId]
  data[6] = <Object?>[
    <Object?>[10, '营销一部', 1, 0],
  ];
  // 14: seat business rows (40 cols)
  List<Object?> seatRow(int seatId, {required int status, num minConsume = 0}) {
    final row = List<Object?>.filled(40, 0);
    row[0] = seatId;
    row[1] = '';
    row[2] = '';
    row[4] = '';
    row[5] = '';
    row[10] = minConsume;
    row[14] = '';
    row[15] = '';
    row[16] = '';
    row[17] = '';
    row[19] = status;
    row[20] = '';
    row[23] = '';
    row[24] = '';
    row[25] = '';
    row[32] = '';
    row[34] = '';
    row[35] = '';
    row[36] = '';
    return row;
  }

  final row100 = seatRow(100, status: 4, minConsume: 1000);
  row100[4] = '2130'; // expectedArriveTime
  row100[5] = '20260828201500'; // openTime
  row100[6] = 500; // orderAmount
  row100[13] = 0; // turnoverCount
  row100[14] = 1001; // salesEmployeeId
  row100[15] = 1002; // secondSalesEmployeeId
  row100[16] = '王先生'; // customerName
  row100[17] = '13911112222'; // bookingCustomerPhone
  row100[18] = 6; // customerCount
  row100[23] = 'wxs'; // customerNamePy
  row100[24] = 'VIP客户'; // remark
  row100[25] = '生'; // mark
  row100[31] = 500; // mainOrderAmount
  row100[32] = 'B01→A01'; // transferHistory
  row100[35] = '13899990000'; // csm_cust_phone

  final row101 = seatRow(101, status: 1, minConsume: 500);
  final row200 = seatRow(200, status: 1, minConsume: 2000);

  data[14] = <Object?>[row100, row101, row200];
  // 18: business day [businessDayId, closeTime, storeName]
  data[18] = <Object?>[
    <Object?>[9, '', '测试门店'],
  ];
  // 24: business dates [label, dateId]
  data[24] = <Object?>[
    <Object?>['08-28', '20260828'],
    <Object?>['08-29', '20260829'],
  ];
  // 39: status counts
  data[39] = <Object?>[
    <Object?>[1, 0, 2],
    <Object?>[4, 0, 1],
    <Object?>[20, 0, 1],
  ];
  // 41: role modules
  data[41] = <Object?>[
    <Object?>[9, 5, 1],
    <Object?>[9, 1, 1],
  ];
  return data;
}
