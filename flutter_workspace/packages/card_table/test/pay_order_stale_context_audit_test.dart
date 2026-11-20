import 'dart:async';

import 'package:card_table/src/card_table_models.dart';

import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/pay_order_screen.dart';
import 'package:card_table/src/pay_money_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

CardTable table() => CardTable(
  id: '100',
  name: 'A01',
  regionId: '1',
  seatType: 1,
  businessType: 1,
  capacity: 4,
  displayOrder: 1,
  businessStatus: 5,
  orderAmount: 10,
  paidAmount: 0,
  customerName: '',
  customerCount: 1,
  reservationTime: '',
  openTime: '12:00',
  remark: '',
  mark: '',
  turnoverCount: 2,
);

// A live business context can expire while widget.table remains unchanged.
void main() {
  testWidgets(
    'pending write remains exclusive across context loss and renewal',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      final pending = Completer<Result<void>>();
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: table(),
            operationContext: token,
            loadOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        turnoverCount: turnoverCount,
                      ),
                    ),
            setSettleMode:
                ({required String seatId, required int settleMode}) async {
                  writes++;
                  return writes == 1 ? pending.future : const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('先后买单'));
      await tester.pump();
      token.value = null;
      token.value = Object();
      await tester.pump();
      await tester.tap(find.text('先后买单'));
      await tester.pump();
      expect(writes, 1);
      pending.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('已设为后买单'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('先后买单'));
      await tester.pumpAndSettle();
      expect(writes, 2);
    },
  );
  testWidgets(
    'missing operation context fails closed even with known refund context',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: table(),
            refundContext: const AlwaysStoppedAnimation<Object?>(true),
            loadOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        turnoverCount: turnoverCount,
                      ),
                    ),
            setSettleMode:
                ({required String seatId, required int settleMode}) async {
                  writes++;
                  return const Success(null);
                },
            cleanSeat: (_) async {
              writes++;
              return const Success(null);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('先后买单'));
      await tester.pump();
      await tester.tap(find.byKey(PayOrderScreen.cleanKey));
      await tester.pump();
      expect(writes, 0);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
  for (final action in ['mode', 'add', 'clean', 'pay']) {
    testWidgets('invalidated live context blocks $action callback', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      final calls = <String>[];
      final pendingCart = Completer<Result<List<PayCartItem>>>();
      var cartLoads = 0;
      const cart = <PayCartItem>[
        PayCartItem(id: '3', channelId: '1', channelName: '现金', amount: '10'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: table(),
            refundContext: token,
            operationContext: token,
            loadOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        turnoverCount: turnoverCount,
                        unpayItems: const [
                          PayOrderItem(
                            id: '9',
                            productId: '101',
                            name: '商品',
                            count: 1,
                            unitPrice: '10',
                            amount: '10',
                          ),
                        ],
                      ),
                    ),
            loadCart: (_) async =>
                ++cartLoads == 1 ? const Success(cart) : pendingCart.future,
            setSettleMode:
                ({required String seatId, required int settleMode}) async {
                  calls.add('mode:$seatId');
                  return const Success(null);
                },
            addChannel:
                ({
                  required String seatId,
                  required String channelId,
                  required String amount,
                }) async {
                  calls.add('add:$seatId');
                  return const Success(null);
                },
            cleanSeat: (seatId) async {
              calls.add('clean:$seatId');
              return const Success(null);
            },
            payOrder:
                ({
                  required String seatId,
                  required List<String> orderIds,
                  required List<int> counts,
                  required String totalAmount,
                }) async {
                  calls.add('pay:$seatId');
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (action == 'mode') {
        token.value = null;
        await tester.pump();
        await tester.tap(find.text('先后买单'));
      } else if (action == 'clean') {
        await tester.tap(find.byKey(PayOrderScreen.cleanKey));
        await tester.pumpAndSettle();
        token.value = null;
        await tester.pump();
        await tester.tap(find.text('确定'));
      } else if (action == 'add') {
        await tester.tap(find.text('加渠道'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(PayOrderScreen.channelIdKey), '1');
        await tester.enterText(find.byKey(PayOrderScreen.amountKey), '10');
        token.value = null;
        await tester.pump();
        await tester.tap(find.text('确认'));
      } else {
        await tester.tap(find.text('商品'));
        await tester.pump();
        await tester.tap(find.byKey(PayOrderScreen.payKey));
        await tester.pumpAndSettle();
        final drawer = tester.widget<PayMoneyDrawer>(
          find.byType(PayMoneyDrawer),
        );
        final completion = drawer.onSubmitPay();
        await tester.pump();
        token.value = null;
        pendingCart.complete(const Success(cart));
        await completion;
      }
      await tester.pump();
      expect(calls, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
