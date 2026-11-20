import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

List<Object?> _data() {
  final data = List<Object?>.filled(60, const <Object?>[]);
  data[0] = [
    [1, '大厅', 1, 1],
  ];
  data[1] = [
    [100, 'A01', 1, 1, 3, 1, 6, 1],
  ];
  final row = List<Object?>.filled(38, null);
  row[0] = 100;
  row[2] = '20260920120000';
  row[5] = '20260920123000';
  for (final i in [6, 7, 8, 9, 10, 11, 12]) {
    row[i] = 0;
  }
  row[13] = 1;
  row[16] = '';
  row[17] = '';
  row[18] = 1;
  row[19] = 4;
  row[20] = '';
  row[24] = '';
  row[25] = '';
  data[14] = [row];
  data[18] = [
    [9, '', 'test'],
  ];
  data[41] = [
    [9, 5, 1],
    [9, 1, 1],
  ];
  data[4] = [
    [101, '历史商品', 2, 0, '', '', 1, 1, 0, 5],
  ];
  return data;
}

void main() {
  for (final change in ['same', 'turnover', 'status']) {
    final changed = change == 'turnover';
    testWidgets('cashier opens order menu without stale turnover $change', (
      tester,
    ) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            stationId: '9',
            employeeId: '42',
            onLoadPayOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        turnoverCount: turnoverCount,
                      ),
                    ),
            onAddOrderProduct:
                ({
                  required String seatId,
                  required String productId,
                  required int count,
                  required String price,
                  String amount = '',
                }) async {
                  writes++;
                  return const Success(null);
                },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920120000',
          data: _data(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      expect(find.byType(PayOrderScreen), findsOneWidget);
      if (change != 'same') {
        final changedData = _data();
        if (changed) {
          (changedData[14] as List).first[13] = 2;
        } else {
          (changedData[14] as List).first[19] = 5;
        }
        events.add(
          SyncEnvelope.fromValidatedReconciliation(
            cursor: '20260920120001',
            data: changedData,
          ),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(TextButton, '点单'));
      await tester.pumpAndSettle();
      expect(
        find.byType(OrderMealScreen),
        changed ? findsNothing : findsOneWidget,
      );
      expect(
        find.byType(PayOrderScreen),
        changed ? findsOneWidget : findsNothing,
      );
      if (changed) expect(find.text('卡台状态已变化，请返回卡台列表重新打开'), findsOneWidget);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'cashier payment page receives paid-refund identity and live scope',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      final phases = StreamController<ConnectionPhase>.broadcast(sync: true);
      addTearDown(events.close);
      addTearDown(phases.close);
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            connectionPhases: phases.stream,
            stationId: '9',
            employeeId: '42',
            onLoadPayOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        turnoverCount: turnoverCount,
                      ),
                    ),
            onRefundPaidOrder:
                ({
                  required String seatId,
                  required String payId,
                  required List<String> orderIds,
                  required List<int> counts,
                  required List<String> amounts,
                  required String remark,
                }) async {
                  writes++;
                  return const Success(null);
                },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920120000',
          data: _data(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      final page = tester.widget<PayOrderScreen>(find.byType(PayOrderScreen));
      expect(page.refundPayed, isNotNull);
      expect(page.refundContext?.value, isNotNull);
      expect(page.productTypeFor?.call('101'), 5);
      phases.add(ConnectionPhase.blocked);
      await tester.pumpAndSettle();
      expect(page.refundContext!.value, isNull);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'refund route scope changes on reconnect or turnover, not price updates',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      final phases = StreamController<ConnectionPhase>.broadcast(sync: true);
      addTearDown(events.close);
      addTearDown(phases.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            connectionPhases: phases.stream,
            stationId: '9',
            employeeId: '42',
            onAddOrderProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920120000',
          data: _data(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      final meal = tester.widget<OrderMealScreen>(find.byType(OrderMealScreen));
      expect(meal.productTypeFor?.call('101'), 5);
      expect(meal.isCashier, false);
      expect(meal.refundContext?.value, isNotNull);
      final first = meal.refundContext!.value;
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920120001',
          data: {
            '58': [
              [101, 1, 100, 1],
            ],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(identical(first, meal.refundContext!.value), true);
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920120001',
          data: {
            '14': [
              [100],
            ],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(meal.refundContext!.value, isNull);
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920120001',
          data: {'58': []},
        ),
      );
      await tester.pumpAndSettle();
      expect(meal.refundContext!.value, isNull);
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920120001',
          data: _data(),
        ),
      );
      await tester.pumpAndSettle();
      expect(meal.refundContext!.value, isNotNull);
      phases.add(ConnectionPhase.blocked);
      await tester.pumpAndSettle();
      expect(meal.refundContext!.value, isNull);
      phases.add(ConnectionPhase.online);
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920120002',
          data: _data(),
        ),
      );
      await tester.pumpAndSettle();
      expect(meal.refundContext!.value, isNotNull);
      expect(identical(first, meal.refundContext!.value), false);
      final second = meal.refundContext!.value;
      final changed = _data();
      (changed[14] as List).first[13] = 2;
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920120003',
          data: changed,
        ),
      );
      await tester.pumpAndSettle();
      expect(identical(second, meal.refundContext!.value), false);
      expect(tester.takeException(), isNull);
    },
  );
}
