import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

void main() {
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

  testWidgets('renders source-aligned region and card filters', (tester) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    var switchCalls = 0;
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
  });
}

List<Object?> _fullData() {
  final data = List<Object?>.filled(19, const <Object?>[]);
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
    <Object?>[9, '', '测试门店'],
  ];
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
