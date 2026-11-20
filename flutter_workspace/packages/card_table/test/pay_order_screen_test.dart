import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/pay_money_drawer.dart';
import 'package:card_table/src/pay_order_screen.dart';
import 'package:card_table/src/pay_order_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets(
    'selected settlement amount rounds each recorded row to cents consistently',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: _table(),
            loadOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        unpayItems: [
                          for (final id in ['1', '2'])
                            PayOrderItem(
                              id: id,
                              productId: '9',
                              name: '商品$id',
                              count: 1,
                              unitPrice: '0.335',
                              amount: '',
                            ),
                        ],
                      ),
                    ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('商品1'));
      await tester.tap(find.text('商品2'));
      await tester.pumpAndSettle();
      expect(find.text('结账 ￥0.68'), findsOneWidget);
    },
  );
  testWidgets(
    'paid historical time price is labelled without showing scheme unit price',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PayedOrderView(
              record: PayedOrderRecord(
                id: '1',
                items: [
                  PayOrderItem(
                    id: '9',
                    productId: '9',
                    name: '时价商品',
                    count: 2,
                    unitPrice: '0',
                    recordedUnitPrice: '80',
                    amount: '150',
                    status: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('时价'), findsOneWidget);
      expect(find.text('150.00'), findsOneWidget);
      expect(find.text('80.00'), findsNothing);
    },
  );
  testWidgets(
    'cashier summaries follow unpaid, paid and all consumption tabs',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: _table(),
            loadOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        summary: OrderSummary.fromWire({
                          'order_amt': 380000,
                          'discount_amt': 120000,
                          'payed_amt': 60000,
                          'payed_free_amt': 1000,
                          'yh_amt': 123,
                        }),
                        unpayItems: const [
                          PayOrderItem(
                            id: '9',
                            productId: '101',
                            name: '历史商品',
                            count: 2,
                            unitPrice: '100',
                            recordedUnitPrice: '80',
                            amount: '150',
                          ),
                        ],
                        payedOrders: const [
                          PayedOrderRecord(
                            id: '123',
                            originalAmt: '999',
                            paidAmt: '77',
                            mainReceivedAmt: '65',
                            items: [
                              PayOrderItem(
                                id: '22',
                                productId: '101',
                                name: '已结商品',
                                count: 1,
                                unitPrice: '100',
                                amount: '80',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('折前金额: ￥200.00'), findsOneWidget);
      expect(find.text('未结金额: ￥150.00'), findsOneWidget);
      expect(find.text('折扣金额: ￥50.00'), findsOneWidget);
      await tester.tap(find.text('已结支付单 123'));
      await tester.pumpAndSettle();
      expect(find.text('折前金额: ￥100.00'), findsOneWidget);
      expect(find.text('折后金额: ￥77.00'), findsOneWidget);
      expect(find.text('折扣金额: ￥23.00'), findsOneWidget);
      expect(find.text('主营实收: ￥65.00'), findsOneWidget);
      await tester.tap(find.text('全部消费'));
      await tester.pumpAndSettle();
      for (final text in [
        '折前金额: ￥5000.00',
        '优惠金额: ￥1.23',
        '折扣金额: ￥1210.00',
        '未结金额: ￥3200.00',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            key: const ValueKey('new'),
            table: _table(),
            loadOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        unpayItems: const [
                          PayOrderItem(
                            id: '9',
                            productId: '101',
                            name: '历史商品',
                            count: 2,
                            unitPrice: '100',
                            recordedUnitPrice: '80',
                            amount: '150',
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('未结金额: ￥150.00'), findsOneWidget);
      await tester.tap(find.text('全部消费'));
      await tester.pumpAndSettle();
      expect(find.text('未结金额: ￥--'), findsOneWidget);
    },
  );
  for (final timePrice in [false, true]) {
    testWidgets(
      '${timePrice ? 'time price' : 'gift'} refund uses recorded rules and cannot split time priced item',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? refundedAmount;
        await tester.pumpWidget(
          MaterialApp(
            home: PayOrderScreen(
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              table: _table(),
              loadOrders:
                  ({
                    required String seatId,
                    required int turnoverCount,
                  }) async => Success(
                    PayOrderData(
                      seatId: seatId,
                      unpayItems: [
                        PayOrderItem(
                          id: '9',
                          productId: '101',
                          name: '历史商品',
                          count: 2,
                          unitPrice: timePrice ? '0' : '100',
                          recordedUnitPrice: '80',
                          amount: '150',
                          authorizationType: timePrice ? 0 : 2,
                        ),
                      ],
                    ),
                  ),
              refundItem:
                  ({
                    required String seatId,
                    required String orderId,
                    required int count,
                    required String amount,
                    required String remark,
                    required bool online,
                  }) async {
                    refundedAmount = amount;
                    return const Success(null);
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (timePrice) expect(find.text('时价'), findsOneWidget);
        await tester.tap(find.text('退单'));
        await tester.pumpAndSettle();
        final field = find.widgetWithText(TextField, '退单数量');
        if (timePrice) {
          expect(tester.widget<TextField>(field).enabled, isFalse);
        } else {
          await tester.enterText(field, '1');
        }
        await tester.tap(find.text('确认退单'));
        await tester.pumpAndSettle();
        expect(refundedAmount, timePrice ? '150.00' : '80.00');
      },
    );
  }
  for (final action in ['加渠道', '转单']) {
    for (final turnoverChanged in [false, true]) {
      testWidgets(
        '$action refuses dialog after ${turnoverChanged ? 'turnover' : 'seat'} changes',
        (tester) async {
          tester.view.physicalSize = const Size(1400, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final table = ValueNotifier(_table());
          addTearDown(table.dispose);
          var mutations = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(splashFactory: NoSplash.splashFactory),
              home: ValueListenableBuilder<CardTable>(
                valueListenable: table,
                builder: (_, current, _) => PayOrderScreen(
                  operationContext: const AlwaysStoppedAnimation<Object?>(true),
                  table: current,
                  loadOrders:
                      ({
                        required String seatId,
                        required int turnoverCount,
                      }) async => Success(
                        PayOrderData(
                          seatId: seatId,
                          unpayItems: const [
                            PayOrderItem(
                              id: '9',
                              productId: '101',
                              name: '测试商品',
                              count: 1,
                              unitPrice: '10',
                              amount: '10',
                            ),
                          ],
                        ),
                      ),
                  addChannel:
                      ({
                        required String seatId,
                        required String channelId,
                        required String amount,
                      }) async {
                        mutations++;
                        return const Success(null);
                      },
                  moveOrder:
                      ({
                        required String seatId,
                        required String destSeatId,
                        required List<String> orderIds,
                        List<int> counts = const [],
                        int? totalAmtFen,
                        bool Function()? canDispatch,
                      }) async {
                        mutations++;
                        return const Success(null);
                      },
                  tables: () => [_table(id: '102')],
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(action));
          await tester.pumpAndSettle();
          if (action == '加渠道') {
            await tester.enterText(find.byKey(PayOrderScreen.amountKey), '10');
          } else {
            await tester.tap(find.byType(RadioListTile<String>));
          }
          table.value = _table(
            id: turnoverChanged ? '100' : '101',
            turnover: turnoverChanged ? 2 : 1,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(action == '加渠道' ? '确认' : '确认转单'));
          await tester.pumpAndSettle();
          expect(mutations, 0);
          expect(find.text('卡台已变化，请重新打开操作'), findsOneWidget);
        },
      );
    }
  }
  for (final scenario in ['empty', 'failed refresh', 'covered', 'zero']) {
    testWidgets('final payment guard: $scenario', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var requests = 0;
      var cartReads = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: PayOrderScreen(
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: _table(),
            loadOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        unpayItems: [
                          PayOrderItem(
                            id: '9',
                            productId: '101',
                            name: '测试商品',
                            count: 1,
                            unitPrice: '10',
                            amount: scenario == 'zero' ? '0' : '10',
                          ),
                        ],
                      ),
                    ),
            loadCart: (_) async {
              cartReads++;
              if (scenario == 'failed refresh' && cartReads > 1) {
                return const FailureResult(
                  AppFailure(
                    kind: FailureKind.network,
                    code: 'test.failed',
                    safeMessage: '读取失败',
                  ),
                );
              }
              return Success(
                scenario == 'covered' || scenario == 'failed refresh'
                    ? const [
                        PayCartItem(
                          id: '1',
                          channelId: '1',
                          channelName: '现金',
                          amount: '10',
                        ),
                      ]
                    : const <PayCartItem>[],
              );
            },
            payOrder:
                ({
                  required String seatId,
                  required List<String> orderIds,
                  required List<int> counts,
                  required String totalAmount,
                }) async {
                  requests++;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('测试商品'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(PayOrderScreen.payKey));
      await tester.pumpAndSettle();
      expect(requests, 0, reason: 'opening payment must never submit');
      final drawer = tester.widget<PayMoneyDrawer>(find.byType(PayMoneyDrawer));
      if (scenario == 'zero') {
        final finish = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text('完成收款'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(finish.onPressed, isNotNull);
      }
      // Exercise the submit seam directly as well as the disabled-button UI.
      await drawer.onSubmitPay();
      await tester.pumpAndSettle();
      expect(requests, scenario == 'covered' || scenario == 'zero' ? 1 : 0);
      expect(cartReads, greaterThanOrEqualTo(2));
    });
  }
  testWidgets('pay order lists unpaid lines and posts selected ids', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final paid = <Map<String, Object?>>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: PayOrderScreen(
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          table: _table(),
          loadCart: (_) async => const Success([
            PayCartItem(
              id: '1',
              channelId: '1',
              channelName: '现金',
              amount: '76',
            ),
          ]),
          loadOrders:
              ({required String seatId, required int turnoverCount}) async =>
                  const Success(
                    PayOrderData(
                      seatId: '100',
                      unpayItems: [
                        PayOrderItem(
                          id: '10',
                          productId: '102',
                          name: '花生',
                          count: 1,
                          unitPrice: '20',
                          amount: '20',
                        ),
                        PayOrderItem(
                          id: '9',
                          productId: '101',
                          name: '莫吉托',
                          count: 2,
                          unitPrice: '38',
                          amount: '76',
                        ),
                      ],
                    ),
                  ),
          payOrder:
              ({
                required String seatId,
                required List<String> orderIds,
                required List<int> counts,
                required String totalAmount,
              }) async {
                paid.add({
                  'seatId': seatId,
                  'orderIds': orderIds,
                  'counts': counts,
                  'totalAmount': totalAmount,
                });
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('莫吉托'), findsOneWidget);
    expect(find.textContaining('未支付订单'), findsOneWidget);
    await tester.tap(find.text('莫吉托'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('收款抽屉'));
    await tester.pumpAndSettle();
    final drawer = tester.widget<PayMoneyDrawer>(find.byType(PayMoneyDrawer));
    expect(drawer.totalUnpayAmt, 76);
    drawer.onClose!();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PayOrderScreen.payKey));
    await tester.pumpAndSettle();
    expect(paid, isEmpty);
    await tester
        .widget<PayMoneyDrawer>(find.byType(PayMoneyDrawer))
        .onSubmitPay();
    await tester.pumpAndSettle();
    expect(paid, isNotEmpty);
    expect(paid.single['orderIds'], ['9']);
    expect(paid.single['counts'], [2]);
    expect(find.text('支付成功'), findsOneWidget);
  });

  testWidgets('pay without a selection shows vue warning', (tester) async {
    var posted = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: PayOrderScreen(
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          table: _table(),
          loadOrders:
              ({required String seatId, required int turnoverCount}) async =>
                  const Success(
                    PayOrderData(
                      seatId: '100',
                      unpayItems: [
                        PayOrderItem(
                          id: '9',
                          productId: '101',
                          name: '莫吉托',
                          count: 1,
                          unitPrice: '38',
                          amount: '38',
                        ),
                      ],
                    ),
                  ),
          payOrder:
              ({
                required String seatId,
                required List<String> orderIds,
                required List<int> counts,
                required String totalAmount,
              }) async {
                posted += 1;
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PayOrderScreen.payKey));
    await tester.pumpAndSettle();
    expect(find.text('请选择需要结账的商品'), findsOneWidget);
    expect(posted, 0);
  });
}

CardTable _table({String id = '100', int turnover = 1}) => CardTable(
  id: id,
  name: 'A01',
  regionId: '1',
  seatType: 1,
  businessType: 1,
  capacity: 4,
  displayOrder: 1,
  businessStatus: 4,
  orderAmount: 0,
  paidAmount: 0,
  customerName: '',
  customerCount: 0,
  reservationTime: '',
  openTime: '20260909120000',
  remark: '',
  mark: '',
  paidValAmount: 0,
  turnoverCount: turnover,
);
