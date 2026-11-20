import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'card_amount_metadata_test.dart' as fixture;

List<Object?> frame({int turnover = 1, int day = 1, int status = 4}) {
  final data = [
    ...fixture.full(fixture.business(turnover: turnover)),
    [],
    [],
    [],
  ];
  data[2] = [
    [1, '酒水', 1, 1],
  ];
  data[3] = [
    [11, '啤酒', 1, 1, 1],
  ];
  data[4] = [
    [101, '审计商品', 1, 1, '', '', '1', '11', '38', 1, 1, 0, 1, '', '2', '2'],
  ];
  data[16] = [
    [1, 1, 101],
  ];
  data[13] = [
    [9, 2, 1],
  ];
  data[41] = [
    [9, 1, 1],
  ];
  data[54] = [
    [1, 0],
  ];
  data[18] = [
    [day, '', '门店'],
  ];
  return data;
}

void main() {
  for (final change in ['turnover', 'business-day', 'same-business']) {
    testWidgets('order operation context after $change', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final writes = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            stationId: '9',
            employeeId: '42',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onAddOrderProduct:
                ({
                  required String seatId,
                  required String productId,
                  required int count,
                  required String price,
                  String amount = '',
                }) async {
                  writes.add('add:$seatId:$productId');
                  return const Success(null);
                },
            onOrderCartItems: (seatId) async => const Success([
              OrderCartItem(
                id: 'old-cart',
                productId: '101',
                count: 2,
                unitPrice: '38',
                amount: '76',
              ),
            ]),
            onSetOrderCartCount:
                ({
                  required String seatId,
                  required String itemId,
                  required int count,
                }) async {
                  writes.add('quantity:$seatId:$itemId');
                  return const Success(null);
                },
            onPlaceOrder:
                ({
                  required String seatId,
                  required List<String> cartItemIds,
                }) async {
                  writes.add('place:$seatId:${cartItemIds.join(',')}');
                  return const Success(null);
                },
          ),
        ),
      );
      events.add(fixture.event(frame()));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      final meal = tester.widget<OrderMealScreen>(find.byType(OrderMealScreen));
      expect(meal.table.turnoverCount, 1);
      expect(meal.refundContext!.value, isNotNull);
      final operationToken = meal.operationContext!.value;
      expect(
        operationToken,
        isNotNull,
        reason: 'page must seed full card store before any later broadcast',
      );
      await tester.tap(find.text('审计商品'));
      await tester.pumpAndSettle();
      final next = frame(
        turnover: change == 'turnover' ? 2 : 1,
        day: change == 'business-day' ? 2 : 1,
      );
      if (change == 'same-business') ((next[14] as List).first as List)[19] = 5;
      events.add(fixture.event(next));
      await tester.pumpAndSettle();
      expect(meal.refundContext!.value, null);
      expect(
        meal.liveTableAmounts!.value,
        change == 'same-business' ? isNotNull : isNull,
      );
      expect(
        meal.operationContext!.value,
        change == 'same-business' ? same(operationToken) : isNull,
      );
      expect(meal.fcPrices!.value.known, true);
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.placeOrderKey));
      await tester.pumpAndSettle();
      expect(
        writes,
        change == 'same-business'
            ? ['add:100:101', 'quantity:100:old-cart', 'place:100:old-cart']
            : isEmpty,
      );
    });
  }
}
