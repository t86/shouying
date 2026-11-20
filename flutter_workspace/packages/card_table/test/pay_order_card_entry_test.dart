import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'card_amount_metadata_test.dart' as fixture;

void main() {
  testWidgets(
    'cashier card entry binds real transfer and batch actions with live metadata',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      var moves = 0, paidMoves = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            stationId: '9',
            employeeId: '7',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onLoadPayOrders:
                ({required seatId, required turnoverCount}) async => Success(
                  PayOrderData(
                    seatId: seatId,
                    payedOrders: const [
                      PayedOrderRecord(id: '80', transferAmount: '12.345'),
                    ],
                    unpayItems: const [
                      PayOrderItem(
                        id: '9',
                        productId: '4',
                        name: '酒水',
                        count: 2,
                        unitPrice: '10',
                        amount: '20',
                      ),
                    ],
                  ),
                ),
            onMovePayOrder:
                ({
                  required seatId,
                  required destSeatId,
                  required orderIds,
                  counts = const [],
                  totalAmtFen,
                  canDispatch,
                }) async {
                  expect(canDispatch!(), isTrue);
                  expect(destSeatId, '101');
                  expect(counts, [2]);
                  expect(totalAmtFen, 2000);
                  moves++;
                  return const Success(null);
                },
            onMovePaidPayOrder:
                ({
                  required seatId,
                  required destSeatId,
                  required payId,
                  required totalAmtFen,
                  required turnoverCount,
                  required receiptFingerprint,
                  selectedUnpaidIds = const [],
                  canDispatch,
                }) async {
                  expect(canDispatch!(), isTrue);
                  expect(payId, '80');
                  expect(totalAmtFen, 1235);
                  expect(destSeatId, '101');
                  expect(receiptFingerprint, isNotEmpty);
                  paidMoves++;
                  return const Success(null);
                },
            paidTransfersNeedingVerification: (_) => {},
            onVerifyPaidTransfer: ({
              required seatId,
              required payId,
              required turnoverCount,
              canDispatch,
            }) async => const Success(null),
            onBatchUpdateOrderWaiter: ({
              required seatId,
              required orderIds,
              required waiterEmpId,
              canDispatch,
            }) async => const Success(null),
            onBatchUpdateOrderAuther: ({
              required seatId,
              required orderIds,
              required authEmpId,
              canDispatch,
            }) async => const Success(null),
          ),
        ),
      );
      final data = fixture.full(fixture.business());
      data[1] = [
        [100, 'A01', 1, 1, 1, 1, 4, 1],
        [101, 'B01', 1, 1, 1, 1, 4, 2],
      ];
      data[5] = [
        [7, '张三', 1, 1, 9, 1, '', 'zs', '9001'],
      ];
      events.add(fixture.event(data));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A01'));
      await tester.pumpAndSettle();
      final page = tester.widget<PayOrderScreen>(find.byType(PayOrderScreen));
      expect(page.moveOrder, isNotNull);
      expect(page.batchUpdateOrderWaiter, isNotNull);
      expect(page.batchUpdateOrderAuther, isNotNull);
      expect(page.employees!().single.namePy, 'zs');
      await tester.tap(find.text('转单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B01'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认转单'));
      await tester.pumpAndSettle();
      expect(moves, 1);
      await tester.tap(find.text('已结支付单 80'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('整笔转单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B01'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认整笔转单'));
      await tester.pumpAndSettle();
      expect(paidMoves, 1);
    },
  );
}
