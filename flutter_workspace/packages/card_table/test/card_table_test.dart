import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

void main() {
  testWidgets('late malformed full snapshot shows protocol failure and retry', (
    tester,
  ) async {
    final feed = (await tester.runAsync(() async => CardTableEventFeed()))!;
    addTearDown(() => tester.runAsync(feed.close));
    final data = _fullData();
    data[1] = <Object?>[
      <Object?>['invalid'],
    ];
    feed.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: data,
      ),
    );
    var refreshCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.booking,
          events: feed.events,
          connectionPhase: ConnectionPhase.online,
          onRefresh: () async {
            refreshCalls += 1;
            return const Success<void>(null);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('卡台数据格式无法识别'), findsOneWidget);
    await tester.tap(find.byKey(CardTableScreen.refreshKey));
    await tester.pumpAndSettle();
    expect(refreshCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test(
    'card feed reset drops the previous session and closes cleanly',
    () async {
      final feed = CardTableEventFeed();
      feed.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(),
        ),
      );
      feed.reset();
      final replay = <SyncEnvelope>[];
      final subscription = feed.events.listen(replay.add);
      await Future<void>.delayed(Duration.zero);
      expect(replay, isEmpty);
      await subscription.cancel();
      await feed.close().timeout(const Duration(seconds: 1));
    },
  );
  testWidgets(
    'late card listener receives full state after buffered increments',
    (tester) async {
      final feed = (await tester.runAsync(() async => CardTableEventFeed()))!;
      addTearDown(() => tester.runAsync(feed.close));
      feed.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(),
        ),
      );
      feed.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010102',
          data: <String, Object?>{
            '1': <Object?>[
              <Object?>[101, 'A02更新', 1, 1, 3, 1, 4, 2],
            ],
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: feed.events,
            connectionPhase: ConnectionPhase.online,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A01'), findsOneWidget);
      expect(find.text('A02更新'), findsOneWidget);
      expect(find.text('正在等待完整卡台数据'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test('normalizes legacy full datasets 0, 1, 14, and 18', () {
    final store = LegacyCardTableStore();
    final result = store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );

    expect(result.failureOrNull, isNull);
    final snapshot = result.valueOrNull!;
    expect(snapshot.businessDayId, '9');
    expect(snapshot.businessOpen, isTrue);
    expect(snapshot.regions.map((region) => region.id), <String>['1', '2']);
    expect(snapshot.tables.map((table) => table.id), <String>[
      '100',
      '101',
      '200',
    ]);
    expect(snapshot.tables.last.businessStatus, 1);
    expect(snapshot.tables.first.name, 'A01');
    expect(snapshot.tables.first.businessStatus, 4);
    expect(snapshot.tables.first.customerName, '顾客');
    expect(snapshot.tables.first.orderAmount, 120);
    expect(snapshot.businessDates.map((date) => date.id), <String>[
      '20260828',
      '20260829',
    ]);
    expect(
      snapshot
          .tablesForDate('20260829')
          .firstWhere((table) => table.id == '101')
          .businessStatus,
      8,
    );
    expect(snapshot.statusCounts[20], 1);
    expect(snapshot.statusCountsForRegion('1')[1], 1);
    expect(snapshot.toString(), isNot(contains('顾客')));
  });

  test('applies incremental seat and business updates atomically', () {
    final store = LegacyCardTableStore();
    store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );

    final updated = store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010102',
        data: <String, Object?>{
          '1': <Object?>[
            <Object?>[101, 'A02', 3, 1, 3, 1, 4, 2],
          ],
          '14': <Object?>[_businessRow(100, status: 5, orderAmount: 200)],
        },
      ),
    );

    expect(updated.failureOrNull, isNull);
    expect(updated.valueOrNull!.tables.map((table) => table.id), <String>[
      '100',
      '200',
    ]);
    expect(updated.valueOrNull!.tables.first.businessStatus, 5);
    expect(updated.valueOrNull!.tables.first.orderAmount, 200);

    final beforeMalformed = store.currentSnapshot;
    final malformed = store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010103',
        data: <String, Object?>{
          '1': <Object?>[
            <Object?>['broken'],
          ],
        },
      ),
    );
    expect(malformed.failureOrNull?.code, 'protocol.card_table_shape');
    expect(identical(store.currentSnapshot, beforeMalformed), isTrue);
  });

  test('fails closed until a complete full snapshot arrives', () {
    final store = LegacyCardTableStore();
    final result = store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: <String, Object?>{
          '14': <Object?>[_businessRow(100, status: 4, orderAmount: 10)],
        },
      ),
    );
    expect(result.failureOrNull?.code, 'protocol.card_table_snapshot_required');
    expect(store.currentSnapshot, isNull);
  });

  test('applies source-aligned terminal region and card restrictions', () {
    final regionRestricted = LegacyCardTableStore(machineId: '77')
        .applyEnvelope(
          SyncEnvelope.fromValidatedReconciliation(
            cursor: '20260828010101',
            data: _fullData(
              machineAccess: <Object?>[
                <Object?>[77, 1, 1, 1],
              ],
            ),
          ),
        );
    expect(
      regionRestricted.valueOrNull!.tables.map((table) => table.id),
      <String>['100', '101'],
    );

    final cardRestricted = LegacyCardTableStore(machineId: '77').applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(
          machineAccess: <Object?>[
            <Object?>[77, 2, 1, 200],
          ],
        ),
      ),
    );
    expect(
      cardRestricted.valueOrNull!.tables.map((table) => table.id),
      <String>['200'],
    );

    final unrestricted = LegacyCardTableStore(machineId: '77').applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(
          machineAccess: <Object?>[
            <Object?>[77, 3, 1, 0],
          ],
        ),
      ),
    );
    expect(unrestricted.valueOrNull!.tables.length, 3);
  });

  test('limits supervisor card visibility to configured regions', () {
    final restricted = LegacyCardTableStore(stationId: '9').applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(
          roleRows: <Object?>[
            <Object?>[9, 11, 1],
          ],
          supervisorRegions: <Object?>[
            <Object?>[9, 2, 1],
          ],
        ),
      ),
    );
    expect(restricted.valueOrNull!.tables.map((table) => table.id), <String>[
      '200',
    ]);

    final fullAccess = LegacyCardTableStore(stationId: '9').applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(
          roleRows: <Object?>[
            <Object?>[9, 11, 1],
          ],
          supervisorRegions: <Object?>[
            <Object?>[9, 0, 1],
          ],
        ),
      ),
    );
    expect(fullAccess.valueOrNull!.tables.length, 3);
  });

  testWidgets('renders source-aligned region and card filters', (tester) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    var switchCalls = 0;
    var refreshCalls = 0;
    var diagnosticsCalls = 0;
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.cashier,
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
          onSwitchSystem: () async {
            switchCalls += 1;
            return const Success<void>(null);
          },
          onRefresh: () async {
            refreshCalls += 1;
            return const Success<void>(null);
          },
          onOpenDiagnostics: () => diagnosticsCalls += 1,
          userName: '系统管理员',
        ),
      ),
    );
    expect(find.text('正在等待完整卡台数据'), findsOneWidget);

    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('收银 · 卡台列表'), findsOneWidget);
    expect(find.text('大厅'), findsWidgets);
    expect(find.text('包厢'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(CardTableScreen.gridKey),
        matching: find.text('A01'),
      ),
      findsOneWidget,
    );
    expect(find.text('A02'), findsOneWidget);
    expect(find.text('B01'), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('明天'), findsOneWidget);
    expect(find.text('空台 2'), findsOneWidget);
    expect(find.text('预订 0'), findsOneWidget);
    expect(find.text('开台 0'), findsOneWidget);
    expect(find.text('抵达数 1'), findsOneWidget);
    expect(find.text('顾客'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '大厅'));
    await tester.pump();
    expect(find.text('空台 1'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '全部区域'));
    await tester.pump();

    await tester.enterText(find.byKey(CardTableScreen.searchKey), 'A01');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(CardTableScreen.gridKey),
        matching: find.text('A01'),
      ),
      findsOneWidget,
    );
    expect(find.text('A02'), findsNothing);
    expect(find.text('B01'), findsNothing);

    await tester.tap(find.byKey(CardTableScreen.switchSystemKey));
    await tester.pumpAndSettle();
    expect(switchCalls, 1);
    await tester.tap(find.byKey(CardTableScreen.refreshKey));
    await tester.pumpAndSettle();
    expect(refreshCalls, 1);
    await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
    await tester.pumpAndSettle();
    expect(find.text('开台记录'), findsOneWidget);
    expect(diagnosticsCalls, 0);
    await tester.ensureVisible(find.byKey(CardTableScreen.openDiagnosticsKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.openDiagnosticsKey));
    await tester.pumpAndSettle();
    expect(diagnosticsCalls, 1);
  });

  testWidgets('booking empty card opens the source-aligned action menu', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.booking,
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
    await tester.pumpAndSettle();
    final menu = find.byType(BottomSheet);
    Finder menuText(String text) =>
        find.descendant(of: menu, matching: find.text(text));
    expect(menuText('A02 · 空台'), findsOneWidget);
    expect(menuText('预留'), findsOneWidget);
    expect(menuText('开台'), findsOneWidget);
    expect(menuText('锁定'), findsOneWidget);
    expect(menuText('置顶'), findsOneWidget);
    expect(menuText('取消锁定'), findsNothing);
    await tester.tap(menuText('关闭'));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'closed business day keeps cards visible and booking can open it',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      var openCalls = 0;
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onOpenBusinessDay: () async {
              openCalls += 1;
              return const Success<void>(null);
            },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(businessDayId: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('营业日未开启'), findsOneWidget);
      expect(find.byKey(CardTableScreen.openBusinessDayKey), findsOneWidget);
      expect(find.text('A01'), findsOneWidget);
      expect(find.text('A02'), findsOneWidget);

      await tester.tap(find.byKey(CardTableScreen.openBusinessDayKey));
      await tester.pumpAndSettle();
      expect(find.text('是否确认开启营业日？'), findsOneWidget);
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(openCalls, 1);
      expect(find.text('开启请求已提交，等待服务端同步'), findsOneWidget);
    },
  );

  testWidgets('only online booking can start a business day', (tester) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.booking,
          events: events.stream,
          connectionPhase: ConnectionPhase.blocked,
          onOpenBusinessDay: () async => const Success<void>(null),
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(businessDayId: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(CardTableScreen.openBusinessDayKey))
          .onPressed,
      isNull,
    );
  });
}

List<Object?> _fullData({
  int businessDayId = 9,
  List<Object?> machineAccess = const <Object?>[],
  List<Object?> roleRows = const <Object?>[],
  List<Object?> supervisorRegions = const <Object?>[],
}) {
  final data = List<Object?>.filled(57, const <Object?>[]);
  data[0] = <Object?>[
    <Object?>[2, '包厢', 1, 20, 0, 0, 0],
    <Object?>[1, '大厅', 1, 10, 0, 0, 0],
    <Object?>[3, '停用', 2, 30, 0, 0, 0],
  ];
  data[1] = <Object?>[
    <Object?>[101, 'A02', 1, 1, 3, 1, 4, 2],
    <Object?>[100, 'A01', 1, 1, 3, 1, 6, 1],
    <Object?>[200, 'B01', 1, 2, 4, 1, 8, 1],
    <Object?>[300, '删除台', 3, 1, 3, 1, 2, 3],
  ];
  data[14] = <Object?>[
    _businessRow(100, status: 4, orderAmount: 120),
    _businessRow(200, status: 22, orderAmount: 50),
  ];
  data[18] = <Object?>[
    <Object?>[businessDayId, '', '测试门店'],
  ];
  data[24] = <Object?>[
    <Object?>['今天', '20260828'],
    <Object?>['明天', '20260829'],
  ];
  data[25] = <Object?>[
    <Object?>[
      '20260829',
      101,
      'future-book-1',
      '20260829120000',
      '20260829123000',
      1,
      '未来顾客',
      '',
      6,
      1,
      0,
      0,
      '',
      'WLGK',
    ],
  ];
  data[39] = <Object?>[
    <Object?>[1, 0, 2],
    <Object?>[3, 0, 2],
    <Object?>[4, 0, 1],
    <Object?>[20, 0, 1],
    <Object?>[1, 1, 1],
    <Object?>[4, 1, 1],
    <Object?>[20, 1, 1],
    <Object?>[1, 2, 1],
  ];
  data[40] = machineAccess;
  data[13] = roleRows;
  data[56] = supervisorRegions;
  return data;
}

List<Object?> _businessRow(
  int seatId, {
  required int status,
  required num orderAmount,
}) {
  final row = List<Object?>.filled(38, null);
  row[0] = seatId;
  row[2] = '20260828120000';
  row[5] = '20260828123000';
  row[6] = orderAmount;
  row[7] = 0;
  row[8] = 20;
  row[9] = 0;
  row[10] = 0;
  row[11] = 0;
  row[12] = 0;
  row[13] = 1;
  row[16] = '顾客';
  row[17] = '';
  row[18] = 4;
  row[19] = status;
  row[20] = '';
  row[24] = '';
  row[25] = '';
  return row;
}
