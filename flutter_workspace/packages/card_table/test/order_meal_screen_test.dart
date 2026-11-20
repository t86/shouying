import 'package:card_table/src/product_pricing.dart';

import 'dart:async';

import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/fc_price.dart';
import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/order_meal_screen.dart';
import 'package:card_table/src/sold_out_products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('guest binding uses edited phone after selecting a search hit', (
    tester,
  ) async {
    final boundPhones = <String>[];
    await _openGuestDialog(
      tester,
      search: (_) async =>
          const Success([OrderGuestHit(phone: '13800000001', name: '合成客人A')]),
      bind: ({required seatId, required phone}) async {
        boundPhones.add(phone);
        return const Success(null);
      },
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '0001',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '13800000002',
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(boundPhones, ['13800000002']);
  });

  testWidgets(
    'guest search keeps newest results when requests finish backwards',
    (tester) async {
      final first = Completer<Result<List<OrderGuestHit>>>();
      final latest = Completer<Result<List<OrderGuestHit>>>();
      await _openGuestDialog(
        tester,
        search: (phone) => phone == '0001' ? first.future : latest.future,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '0001',
      );
      await tester.pump();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '0002',
      );
      await tester.pump();
      latest.complete(
        const Success([OrderGuestHit(phone: '13800000002', name: '当前搜索')]),
      );
      await tester.pumpAndSettle();
      first.complete(
        const Success([OrderGuestHit(phone: '13800000001', name: '过期搜索')]),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('当前搜索'), findsOneWidget);
      expect(find.textContaining('过期搜索'), findsNothing);
    },
  );

  testWidgets('short guest input invalidates a pending search', (tester) async {
    final pending = Completer<Result<List<OrderGuestHit>>>();
    await _openGuestDialog(tester, search: (_) => pending.future);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '0001',
    );
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '00',
    );
    await tester.pump();
    pending.complete(
      const Success([OrderGuestHit(phone: '13800000001', name: '过期搜索')]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets(
    'guest search clears old hits while loading and reports failure',
    (tester) async {
      final pending = Completer<Result<List<OrderGuestHit>>>();
      await _openGuestDialog(
        tester,
        search: (phone) => phone == '0001'
            ? Future.value(
                const Success([
                  OrderGuestHit(phone: '13800000001', name: '旧结果'),
                ]),
              )
            : pending.future,
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '0001',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        '0002',
      );
      await tester.pump();
      expect(find.byType(CheckboxListTile), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      pending.complete(
        const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'synthetic.offline',
            safeMessage: '合成搜索失败，请重试',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('合成搜索失败，请重试'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    },
  );

  testWidgets('guest search list scrolls to its last hit above the keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);
    final boundPhones = <String>[];
    await _openGuestDialog(
      tester,
      search: (_) async => Success([
        for (var i = 0; i < 12; i++)
          OrderGuestHit(
            phone: '138000000${i.toString().padLeft(2, '0')}',
            name: '合成客人$i',
          ),
      ]),
      bind: ({required seatId, required phone}) async {
        boundPhones.add(phone);
        return const Success(null);
      },
    );
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '0001',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final lastHit = find.text('合成客人11  13800000011');
    await tester.ensureVisible(lastHit);
    await tester.pumpAndSettle();
    expect(lastHit.hitTestable(), findsOneWidget);
    await tester.tap(lastHit);
    await tester.pump();
    final confirm = find.widgetWithText(FilledButton, '确定');
    expect(confirm.hitTestable(), findsOneWidget);
    expect(tester.getBottomRight(confirm).dy, lessThanOrEqualTo(500));
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(boundPhones, ['13800000011']);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(360, 800), const Size(393, 873)]) {
    testWidgets('my-order actions fit and remain reachable on $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: _mobileOrderScreen(
            loadOrders: ({required seatId, required turnoverCount}) async =>
                const Success([
                  OrderPlacedItem(
                    id: 'synthetic-order',
                    productId: '101',
                    name: '合成手机布局商品',
                    count: 2,
                    unitPrice: '38',
                    amount: '76',
                    orderedAt: '12:00',
                    waiterName: '',
                  ),
                ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final title = find.text('合成手机布局商品');
      expect(tester.getSize(title).width, greaterThan(200));
      for (final label in ['退单', '赠送', '优惠2', '改明细', '补打出品']) {
        final action = find.widgetWithText(TextButton, label);
        expect(action.hitTestable(), findsOneWidget);
        expect(
          tester.getTopLeft(action).dy,
          greaterThan(tester.getBottomRight(title).dy),
        );
      }
    });
  }

  testWidgets('late clean-seat success removes only its original order route', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final pending = Completer<Result<void>>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: Scaffold(
          body: TextButton(
            onPressed: () => navigator.currentState!.push(
              MaterialPageRoute<void>(
                builder: (_) => OrderMealScreen(
                  pricingContext: const ProductPricingContext(
                    isBusiness: false,
                    isBox: false,
                    isMember: false,
                  ),
                  table: _table(),
                  catalog: _catalog(),
                  operationContext: const AlwaysStoppedAnimation<Object?>(true),
                  addProduct: ({
                    required String seatId,
                    required String productId,
                    required int count,
                    required String price,
                    String amount = '',
                  }) async => const Success(null),
                  cleanSeat: (_) => pending.future,
                ),
              ),
            ),
            child: const Text('打开点单'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开点单'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.moreKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清台'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pump();
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('新的页面')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    pending.complete(const Success(null));
    await tester.pumpAndSettle();
    expect(find.text('新的页面'), findsOneWidget);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('打开点单'), findsOneWidget);
    expect(find.byType(OrderMealScreen), findsNothing);
  });
  testWidgets(
    'coupon rechecks live module permission after dialog without rebuilding page',
    (tester) async {
      var modules = <int>{86};
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            table: _table(),
            catalog: _catalog(),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            moduleIds: const {86},
            currentModuleIds: () => modules,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
            redeemCoupon: (_) async {
              writes++;
              return const Success(null);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('核销卡券'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(OrderMealScreen.redeemFieldKey),
        'synthetic-coupon',
      );
      modules = {};
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.textContaining('无核销权限'), findsOneWidget);
    },
  );
  testWidgets(
    'waiter payment renders QR and yuan amount then removes expired code',
    (tester) async {
      final operation = ValueNotifier<Object?>(Object());
      addTearDown(operation.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            table: _table(),
            catalog: _catalog(),
            operationContext: operation,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
            waiterTodoOrders: (_) async => const Success([
              OrderPlacedItem(
                id: '9',
                productId: '101',
                name: '测试',
                count: 1,
                unitPrice: '1',
                amount: '1',
                orderedAt: '',
                waiterName: '',
              ),
            ]),
            createWaiterPay:
                ({
                  required String seatId,
                  required int payType,
                  required List<String> orderIds,
                }) async => const Success(
                  WaiterPayQr(
                    payId: '1',
                    amountFen: 1234,
                    payUrl: 'synthetic-qr-content',
                  ),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('买单二维码'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-meal-waiter-qr')), findsOneWidget);
      expect(find.text('金额：￥12.34'), findsOneWidget);
      await tester.pump(const Duration(minutes: 15));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-meal-waiter-qr')), findsNothing);
    },
  );
  testWidgets(
    'operation expiry removes only its old payment QR, not a newer page',
    (tester) async {
      final operation = ValueNotifier<Object?>(Object());
      addTearDown(operation.dispose);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            table: _table(),
            catalog: _catalog(),
            operationContext: operation,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
            waiterTodoOrders: (_) async => const Success([
              OrderPlacedItem(
                id: '9',
                productId: '101',
                name: '旧流水',
                count: 1,
                unitPrice: '1',
                amount: '1',
                orderedAt: '',
                waiterName: '',
              ),
            ]),
            createWaiterPay:
                ({
                  required String seatId,
                  required int payType,
                  required List<String> orderIds,
                }) async => const Success(
                  WaiterPayQr(
                    payId: '1',
                    amountFen: 100,
                    payUrl: 'qr-for-old-table',
                  ),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('买单二维码'));
      await tester.pumpAndSettle();
      expect(find.byKey(OrderMealScreen.waiterQrKey), findsOneWidget);
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('新的登录页')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      operation.value = null;
      await tester.pumpAndSettle();
      expect(find.text('新的登录页'), findsOneWidget);
      expect(
        find.byKey(OrderMealScreen.waiterQrKey, skipOffstage: false),
        findsNothing,
      );
    },
  );
  for (final action in ['add', 'place']) {
    testWidgets(
      'pending $action keeps write mutex across disconnect and reconnect',
      (tester) async {
        final operation = ValueNotifier<Object?>(Object());
        addTearDown(operation.dispose);
        final pending = Completer<Result<void>>();
        var writes = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              table: _table(),
              catalog: _catalog(),
              fcPriceCatalog: _prices(null),
              operationContext: operation,
              addProduct:
                  ({
                    required String seatId,
                    required String productId,
                    required int count,
                    required String price,
                    String amount = '',
                  }) async {
                    writes++;
                    return pending.future;
                  },
              loadCartItems: (_) async => const Success([
                OrderCartItem(
                  id: '9',
                  productId: '101',
                  count: 2,
                  unitPrice: '38',
                  amount: '76',
                ),
              ]),
              placeOrder:
                  ({
                    required String seatId,
                    required List<String> cartItemIds,
                  }) async {
                    writes++;
                    return pending.future;
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (action == 'add') {
          await tester.tap(find.text('莫吉托'));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, '确认'));
          await tester.pumpAndSettle();
        } else {
          await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(OrderMealScreen.placeOrderKey));
          await tester.pump();
        }
        expect(writes, 1);
        operation.value = null;
        operation.value = Object();
        await tester.pump();
        if (action == 'add') {
          await tester.tap(find.text('莫吉托'));
          await tester.pumpAndSettle();
          expect(find.byKey(OrderMealScreen.countKey), findsNothing);
        } else {
          expect(
            tester
                .widget<FilledButton>(find.byKey(OrderMealScreen.placeOrderKey))
                .onPressed,
            isNull,
          );
        }
        expect(writes, 1);
        pending.complete(const Success(null));
        await tester.pumpAndSettle();
        if (action == 'place') {
          expect(
            tester
                .widget<FilledButton>(find.byKey(OrderMealScreen.placeOrderKey))
                .onPressed,
            isNotNull,
          );
        }
      },
    );
  }
  testWidgets(
    'missing operation context denies new product cart edits and placing orders',
    (tester) async {
      final writes = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            table: _table(),
            catalog: _catalog(),
            fcPriceCatalog: _prices(null),
            addProduct:
                ({
                  required String seatId,
                  required String productId,
                  required int count,
                  required String price,
                  String amount = '',
                }) async {
                  writes.add('add');
                  return const Success(null);
                },
            loadCartItems: (_) async => const Success([
              OrderCartItem(
                id: '9',
                productId: '101',
                count: 2,
                unitPrice: '38',
                amount: '76',
              ),
            ]),
            setCartCount:
                ({
                  required String seatId,
                  required String itemId,
                  required int count,
                }) async {
                  writes.add('quantity');
                  return const Success(null);
                },
            placeOrder:
                ({
                  required String seatId,
                  required List<String> cartItemIds,
                }) async {
                  writes.add('place');
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('莫吉托'));
      await tester.pumpAndSettle();
      expect(find.byKey(OrderMealScreen.countKey), findsNothing);
      await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.placeOrderKey));
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
    },
  );
  testWidgets('reconnect never revives an old quantity dialog attempt', (
    tester,
  ) async {
    final original = Object();
    final operation = ValueNotifier<Object?>(original);
    addTearDown(operation.dispose);
    var writes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          table: _table(),
          catalog: _catalog(),
          fcPriceCatalog: _prices(null),
          operationContext: operation,
          addProduct:
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('莫吉托'));
    await tester.pumpAndSettle();
    operation.value = null;
    operation.value = original;
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    await tester.tap(find.text('莫吉托'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(writes, 1);
  });
  testWidgets(
    'waiter payment read completion cannot create payment in a changed operation',
    (tester) async {
      final operation = ValueNotifier<Object?>(Object());
      addTearDown(operation.dispose);
      final pending = Completer<Result<List<OrderPlacedItem>>>();
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            table: _table(),
            catalog: _catalog(),
            operationContext: operation,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
            waiterTodoOrders: (_) => pending.future,
            createWaiterPay:
                ({
                  required String seatId,
                  required int payType,
                  required List<String> orderIds,
                }) async {
                  writes++;
                  return const Success(
                    WaiterPayQr(
                      payId: '1',
                      amountFen: 100,
                      payUrl: 'synthetic',
                    ),
                  );
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('买单二维码'));
      await tester.pump();
      operation.value = null;
      operation.value = Object();
      pending.complete(
        const Success([
          OrderPlacedItem(
            id: '9',
            productId: '101',
            name: '旧流水',
            count: 1,
            unitPrice: '1',
            amount: '1',
            orderedAt: '',
            waiterName: '',
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(writes, 0);
    },
  );
  testWidgets(
    'scheme product shows struck original and labeled price on mobile',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prices = ValueNotifier(_prices(77700));
      addTearDown(prices.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: _table(),
            catalog: _catalog(name: 'GOGO小费', price: '800'),
            employeeId: '11',
            fcPrices: prices,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('原价：￥800.00'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('原价：￥800.00')).style?.decoration,
        TextDecoration.lineThrough,
      );
      expect(find.text('方案价：￥777.00'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('方案价：￥777.00')).style?.color,
        const Color(0xffE63122),
      );
      expect(tester.takeException(), isNull);
      prices.value = _prices(0);
      await tester.pumpAndSettle();
      expect(find.text('原价：￥800.00'), findsOneWidget);
      expect(find.text('方案价：￥0.00'), findsOneWidget);
      prices.value = _prices(80000);
      await tester.pumpAndSettle();
      expect(find.textContaining('原价：'), findsNothing);
      expect(find.textContaining('方案价：'), findsNothing);
      expect(find.text('￥800.00'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('￥800.00')).style?.color,
        const Color(0xff009370),
      );
      prices.value = _prices(null);
      await tester.pumpAndSettle();
      expect(find.textContaining('原价：'), findsNothing);
      expect(find.textContaining('方案价：'), findsNothing);
    },
  );
  testWidgets(
    'footer independently rounds recorded amount and discount without mixing new turnover',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final initial = _table(orderAmount: 12.345, discountAmount: 0.005);
      final live = ValueNotifier<CardTable?>(initial);
      addTearDown(live.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: initial,
            catalog: _catalog(),
            showFooterAmounts: true,
            liveTableAmounts: live,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('折前金额:￥12.36'), findsOneWidget);
      live.value = _table(orderAmount: 20, discountAmount: 5);
      await tester.pumpAndSettle();
      expect(find.text('折前金额:￥25.00'), findsOneWidget);
      live.value = _table(
        orderAmount: 200,
        discountAmount: 99,
        turnoverCount: 2,
      );
      await tester.pumpAndSettle();
      expect(find.text('折前金额:￥12.36'), findsOneWidget);
      expect(find.text('折前金额:￥299.00'), findsNothing);
    },
  );
  testWidgets('open order page follows same-table live footer amounts only', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final initial = _table(orderAmount: 100, paidValAmount: 90, paidAmount: 30);
    final live = ValueNotifier<CardTable?>(initial);
    addTearDown(live.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          table: initial,
          catalog: _catalog(),
          showFooterAmounts: true,
          liveTableAmounts: live,
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('折前金额:￥100.00'), findsOneWidget);
    live.value = _table(
      orderAmount: 120,
      paidValAmount: 110,
      paidAmount: 50,
      mainOrderAmount: 80,
    );
    await tester.pumpAndSettle();
    expect(find.text('折前金额:￥120.00'), findsOneWidget);
    expect(find.text('折后金额:￥110.00'), findsOneWidget);
    expect(find.text('主营点单金额:￥80.00'), findsOneWidget);
    expect(find.text('已收金额:￥50.00'), findsOneWidget);
    live.value = _table(orderAmount: 999, turnoverCount: 1);
    await tester.pumpAndSettle();
    expect(find.text('折前金额:￥999.00'), findsNothing);
    expect(find.text('折前金额:￥100.00'), findsOneWidget);
    live.value = null;
    await tester.pumpAndSettle();
    expect(find.text('折前金额:￥100.00'), findsOneWidget);
  });
  testWidgets('cancel during refund preflight prevents the later write', (
    tester,
  ) async {
    final token = ValueNotifier<Object?>(Object());
    addTearDown(token.dispose);
    final pending = Completer<Result<List<OrderPlacedItem>>>();
    var reads = 0, writes = 0;
    const item = OrderPlacedItem(
      id: '9',
      productId: '101',
      name: '测试退单',
      count: 2,
      unitPrice: '38',
      amount: '76',
      orderedAt: '12:00',
      waiterName: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          table: _table(),
          catalog: _catalog(),
          productTypeFor: (_) => 1,
          refundContext: token,
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          loadOrders: ({
            required String seatId,
            required int turnoverCount,
          }) async => ++reads == 1 ? const Success([item]) : pending.future,
          refundReasons: const ['点错'],
          refundOrder:
              ({
                required String seatId,
                required String orderId,
                required int count,
                required String amount,
                required String remark,
                required bool online,
                String authEmpCode = '',
                String authEmpPasswd = '',
                int passType = 1,
              }) async {
                writes++;
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('点错'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pump();
    expect(reads, 2);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    pending.complete(const Success([item]));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.byKey(const Key('order-refund-count')), findsNothing);
  });
  for (final changed in ['paid', 'count', 'type']) {
    testWidgets('refund rechecks live order $changed before posting', (
      tester,
    ) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      var reads = 0, writes = 0, type = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: _table(),
            catalog: _catalog(),
            productTypeFor: (_) => type,
            refundContext: token,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
            loadOrders:
                ({required String seatId, required int turnoverCount}) async {
                  reads++;
                  return Success([
                    OrderPlacedItem(
                      id: '9',
                      productId: '101',
                      name: '测试退单',
                      count: reads > 1 && changed == 'count' ? 1 : 2,
                      unitPrice: '38',
                      amount: '76',
                      orderedAt: '12:00',
                      waiterName: '',
                      status: reads > 1 && changed == 'paid' ? 5 : 0,
                    ),
                  ]);
                },
            refundReasons: const ['点错'],
            refundOrder:
                ({
                  required String seatId,
                  required String orderId,
                  required int count,
                  required String amount,
                  required String remark,
                  required bool online,
                  String authEmpCode = '',
                  String authEmpPasswd = '',
                  int passType = 1,
                }) async {
                  writes++;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('退单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('点错'));
      await tester.pump();
      if (changed == 'type') type = 4;
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.byKey(const Key('order-refund-count')), findsOneWidget);
    });
  }
  for (final scheme in <int?>[null, 2500]) {
    testWidgets('compensation retains entered total with scheme $scheme', (
      tester,
    ) async {
      final sent = <({String amount, String price})>[];
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: _table(),
            catalog: _catalog(prdType: 5),
            employeeId: '11',
            fcPriceCatalog: _prices(scheme),
            addProduct:
                ({
                  required String seatId,
                  required String productId,
                  required int count,
                  required String price,
                  String amount = '',
                }) async {
                  sent.add((amount: amount, price: price));
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('莫吉托'));
      await tester.pumpAndSettle();
      expect(find.byKey(OrderMealScreen.amountKey), findsOneWidget);
      await tester.enterText(find.byKey(OrderMealScreen.amountKey), '17.50');
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(sent, [(amount: '17.50', price: scheme == null ? '38' : '25.00')]);
    });
  }
  testWidgets(
    'scheme updates and unknown state never reprice saved cart or history',
    (tester) async {
      final prices = ValueNotifier(_prices(1000));
      addTearDown(prices.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: _table(),
            catalog: _catalog(),
            employeeId: '11',
            fcPrices: prices,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
            loadCartItems: (seatId) async => const Success([
              OrderCartItem(
                id: '1',
                productId: '101',
                count: 2,
                unitPrice: '38',
                amount: '76',
              ),
            ]),
            loadOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    const Success([
                      OrderPlacedItem(
                        id: '2',
                        productId: '101',
                        name: '历史订单',
                        count: 2,
                        unitPrice: '38',
                        amount: '76',
                        orderedAt: '昨天',
                        waiterName: '员工',
                      ),
                    ]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
      await tester.pumpAndSettle();
      expect(find.text('￥38  小计￥76'), findsOneWidget);
      prices.value = FcPriceCatalog.unknown;
      await tester.pumpAndSettle();
      expect(find.text('￥38  小计￥76'), findsOneWidget);
      await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
      await tester.pumpAndSettle();
      prices.value = _prices(0);
      await tester.pumpAndSettle();
      expect(find.text('数量 2  ￥38  昨天  ￥76'), findsOneWidget);
    },
  );
  for (final scenario in ['zero', 'update', 'unknown', 'fallback']) {
    testWidgets('live scheme new product $scenario', (tester) async {
      final prices = ValueNotifier(_prices(1000));
      addTearDown(prices.dispose);
      final added = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: _table(),
            catalog: _catalog(),
            employeeId: '11',
            fcPrices: prices,
            addProduct:
                ({
                  required String seatId,
                  required String productId,
                  required int count,
                  required String price,
                  String amount = '',
                }) async {
                  added.add(price);
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('方案价：￥10.00'), findsOneWidget);
      await tester.tap(find.text('莫吉托'));
      await tester.pumpAndSettle();
      prices.value = switch (scenario) {
        'zero' => _prices(0),
        'update' => _prices(2500),
        'unknown' => FcPriceCatalog.unknown,
        _ => _prices(null),
      };
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(
        added,
        scenario == 'unknown'
            ? isEmpty
            : [
                switch (scenario) {
                  'zero' => '0.00',
                  'update' => '25.00',
                  _ => '38',
                },
              ],
      );
      if (scenario == 'unknown') {
        expect(find.textContaining('价格方案尚未同步'), findsOneWidget);
      }
    });
  }
  testWidgets(
    'timed scheme rechecks amount after dialog and keeps zero valid',
    (tester) async {
      final prices = ValueNotifier(_prices(1000));
      addTearDown(prices.dispose);
      final amounts = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            table: _table(),
            catalog: _catalog(prdType: 3),
            employeeId: '11',
            fcPrices: prices,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
            addTimed:
                ({
                  required String seatId,
                  required String productId,
                  required int count,
                  required String amount,
                }) async {
                  amounts.add(amount);
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('莫吉托'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(OrderMealScreen.countKey), '2');
      prices.value = _prices(0);
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(amounts, ['0.00']);
    },
  );
  testWidgets('order meal lists a regular product and can add it', (
    tester,
  ) async {
    final added =
        <({String seatId, String productId, int count, String price})>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          remaining: const {'101': 4},
          cartCount: 0,
          addProduct:
              ({
                required String seatId,
                required String productId,
                required int count,
                required String price,
                String amount = '',
              }) async {
                added.add((
                  seatId: seatId,
                  productId: productId,
                  count: count,
                  price: price,
                ));
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('商品菜单'), findsOneWidget);
    expect(find.text('A01'), findsOneWidget);
    expect(find.text('酒水'), findsOneWidget);
    expect(find.text('鸡尾酒'), findsOneWidget);
    expect(find.text('莫吉托'), findsOneWidget);
    expect(find.text('当前商品已售罄'), findsNothing);
    await tester.tap(find.text('莫吉托'));
    await tester.pumpAndSettle();
    expect(find.text('默认商品数量1'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(added, isNotEmpty);
    expect(added.single.seatId, '100');
    expect(added.single.productId, '101');
    expect(added.single.count, 1);
    expect(added.single.price, '38');
    expect(find.text('加入购物车成功'), findsOneWidget);
    expect(find.text('购物车'), findsOneWidget);
    expect(find.text('加入'), findsOneWidget);
  });

  testWidgets('cart tab shows added items and can delete them', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var cartCount = 0;
    var items = <OrderCartItem>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          remaining: const {'101': 4},
          cartCount: 0,
          addProduct:
              ({
                required String seatId,
                required String productId,
                required int count,
                required String price,
                String amount = '',
              }) async {
                cartCount += count;
                items = [
                  OrderCartItem(
                    id: '9',
                    productId: productId,
                    count: cartCount,
                    unitPrice: price,
                    amount: '38',
                  ),
                ];
                return const Success(null);
              },
          loadCartCount: (seatId) async => Success(cartCount),
          loadCartItems: (seatId) async => Success(items),
          setCartCount:
              ({
                required String seatId,
                required String itemId,
                required int count,
              }) async {
                if (count == 0) {
                  items = [];
                  cartCount = 0;
                }
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('莫吉托'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(find.text('已点：1'), findsWidgets);
    await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
    await tester.pumpAndSettle();
    expect(find.text('莫吉托'), findsWidgets);
    expect(find.text('删除'), findsOneWidget);
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('购物车是空的'), findsOneWidget);
  });

  testWidgets('order meal shows vue header footer bind and order actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(orderAmount: 800, paidAmount: 800, paidValAmount: 800),
          showOrderSummary: true,
          showFooterAmounts: true,
          catalog: _catalog(),
          remaining: const {'101': 4},
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          bindGuestEnabled: true,
          salesLabel: '总经办/大师兄',
          userName: '测试员',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('开台时间'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.textContaining('A01'), findsWidgets);
    expect(find.textContaining('总经办/大师兄'), findsOneWidget);
    expect(find.text('绑定客人'), findsOneWidget);
    expect(find.text('绑定当台服务员'), findsOneWidget);
    expect(find.text('返回首页'), findsOneWidget);
    expect(find.text('商品菜单'), findsOneWidget);
    expect(find.text('购物车'), findsOneWidget);
    expect(find.text('我的点单'), findsOneWidget);
    expect(find.text('核销卡券'), findsOneWidget);
    expect(find.text('更多功能'), findsOneWidget);
    expect(find.textContaining('折前金额'), findsOneWidget);
    expect(find.textContaining('折后金额'), findsOneWidget);
    expect(find.textContaining('主营点单金额'), findsOneWidget);
    expect(find.textContaining('已收金额'), findsOneWidget);
  });

  testWidgets('order meal binds the current waiter after confirm', (
    tester,
  ) async {
    final seats = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          bindWaiter: (seatId) async {
            seats.add(seatId);
            return const Success(null);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.bindWaiterKey));
    await tester.pumpAndSettle();
    expect(find.text('绑定当台服务员？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(seats, ['100']);
    expect(find.text('绑定成功'), findsOneWidget);
    expect(find.byKey(OrderMealScreen.bindWaiterKey), findsNothing);
  });

  testWidgets('order meal my-order tab lists placed items', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          loadOrders:
              ({required String seatId, required int turnoverCount}) async =>
                  Success([
                    const OrderPlacedItem(
                      id: '9',
                      productId: '101',
                      name: '莫吉托',
                      count: 2,
                      unitPrice: '38',
                      amount: '76',
                      orderedAt: '12:00',
                      waiterName: '大师兄',
                    ),
                  ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
    await tester.pumpAndSettle();
    expect(find.text('莫吉托'), findsWidgets);
    expect(find.textContaining('数量 2'), findsOneWidget);
  });

  testWidgets('sold-out regular products cannot be added', (tester) async {
    var adds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          remaining: const {'101': 0},
          cartCount: 0,
          addProduct:
              ({
                required String seatId,
                required String productId,
                required int count,
                required String price,
                String amount = '',
              }) async {
                adds += 1;
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('莫吉托'));
    await tester.pumpAndSettle();
    expect(find.text('当前商品已售罄'), findsOneWidget);
    expect(find.text('默认商品数量1'), findsNothing);
    expect(adds, 0);
  });

  testWidgets('empty cart place-order shows vue warning and does not post', (
    tester,
  ) async {
    var placed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          placeOrder:
              ({
                required String seatId,
                required List<String> cartItemIds,
              }) async {
                placed += 1;
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.placeOrderKey));
    await tester.pumpAndSettle();
    expect(find.text('购物车商品为空，请添加商品至购物车再下单！'), findsOneWidget);
    expect(placed, 0);
  });

  testWidgets('place-order posts cart ids then opens my-order', (tester) async {
    final posted = <List<String>>[];
    var items = [
      const OrderCartItem(
        id: '9',
        productId: '101',
        count: 1,
        unitPrice: '38',
        amount: '38',
      ),
    ];
    var orders = <OrderPlacedItem>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          loadCartItems: (seatId) async => Success(items),
          loadCartCount: (seatId) async => Success(items.length),
          placeOrder:
              ({
                required String seatId,
                required List<String> cartItemIds,
              }) async {
                posted.add(cartItemIds);
                items = [];
                orders = [
                  const OrderPlacedItem(
                    id: '9',
                    productId: '101',
                    name: '莫吉托',
                    count: 1,
                    unitPrice: '38',
                    amount: '38',
                    orderedAt: '12:00',
                    waiterName: '',
                  ),
                ];
                return const Success(null);
              },
          loadOrders: ({
            required String seatId,
            required int turnoverCount,
          }) async => Success(orders),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
    await tester.pumpAndSettle();
    expect(find.text('莫吉托'), findsWidgets);
    await tester.tap(find.byKey(OrderMealScreen.placeOrderKey));
    await tester.pumpAndSettle();
    expect(posted, [
      ['9'],
    ]);
    expect(find.text('下单成功'), findsOneWidget);
    expect(find.textContaining('数量 1'), findsOneWidget);
  });

  testWidgets('time-price product requires amount then posts addTimed', (
    tester,
  ) async {
    final timed = <({String productId, String amount, int count})>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(prdType: 3, productId: '201', name: '时价特饮'),
          remaining: const {'201': 4},
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          addTimed:
              ({
                required String seatId,
                required String productId,
                required int count,
                required String amount,
              }) async {
                timed.add((productId: productId, amount: amount, count: count));
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('时价特饮'));
    await tester.pumpAndSettle();
    expect(find.text('请输入金额'), findsOneWidget);
    await tester.enterText(find.byKey(OrderMealScreen.amountKey), '88');
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(timed.single.productId, '201');
    expect(timed.single.amount, '88');
    expect(timed.single.count, 1);
    expect(find.text('加入购物车成功'), findsOneWidget);
  });

  testWidgets('time-price product without amount shows vue warning', (
    tester,
  ) async {
    var timed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(prdType: 3, productId: '201', name: '时价特饮'),
          remaining: const {'201': 4},
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          addTimed:
              ({
                required String seatId,
                required String productId,
                required int count,
                required String amount,
              }) async {
                timed += 1;
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('时价特饮'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(find.text('请输入金额'), findsWidgets);
    expect(timed, 0);
  });

  testWidgets('set product posts addSet using fixed group details', (
    tester,
  ) async {
    final posted = <Map<String, Object?>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(prdType: 2, productId: '301', name: '双人套餐'),
          loadRemaining: () async => const Success({}),
          remaining: const {'301': 4},
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          setDetails: const [
            OrderSetDetail(
              productId: '301',
              groupId: '1',
              detailProductId: '11',
              detailCount: 1,
              groupSelectCount: 1,
              name: '配菜',
            ),
          ],
          addSet:
              ({
                required String seatId,
                required String productId,
                required int count,
                required int priceFen,
                required List<String> groupIds,
                required List<String> detailProductIds,
                required List<int> detailCounts,
                required List<int> selectCounts,
                List<String> requirements = const [],
              }) async {
                posted.add({
                  'productId': productId,
                  'groupIds': groupIds,
                  'detailProductIds': detailProductIds,
                });
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('双人套餐'));
    await tester.pumpAndSettle();
    expect(find.text('配菜'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(posted, isNotEmpty);
    expect(posted.single['productId'], '301');
    expect(posted.single['groupIds'], ['1']);
    expect(find.text('加入购物车成功'), findsOneWidget);
  });

  testWidgets('refund unpaid order requires reason then posts', (tester) async {
    final refunds = <String>[];
    final refundContext = ValueNotifier<Object?>(Object());
    addTearDown(refundContext.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          loadOrders:
              ({required String seatId, required int turnoverCount}) async =>
                  Success([
                    const OrderPlacedItem(
                      id: '9',
                      productId: '101',
                      name: '莫吉托',
                      count: 2,
                      unitPrice: '38',
                      amount: '76',
                      orderedAt: '12:00',
                      waiterName: '',
                    ),
                  ]),
          refundReasons: const ['客人不满意', '点错'],
          productTypeFor: (_) => 1,
          refundContext: refundContext,
          refundOrder:
              ({
                required String seatId,
                required String orderId,
                required int count,
                required String amount,
                required String remark,
                required bool online,
                String authEmpCode = '',
                String authEmpPasswd = '',
                int passType = 1,
              }) async {
                refunds.add(remark);
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退单'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-refund-count')), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(find.text('请选择退单理由'), findsOneWidget);
    expect(refunds, isEmpty);
    await tester.tap(find.text('客人不满意'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(refunds, ['客人不满意']);
    expect(find.text('退单成功'), findsOneWidget);
  });

  testWidgets('cart discount posts to_yh with self auth reason', (
    tester,
  ) async {
    final reasons = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          loadCartItems: (seatId) async => Success([
            const OrderCartItem(
              id: '9',
              productId: '101',
              count: 1,
              unitPrice: '38',
              amount: '38',
            ),
          ]),
          loadCartCount: (seatId) async => const Success(1),
          yhReasons: const ['招待'],
          convertCartToYh:
              ({
                required String seatId,
                required List<String> cartItemIds,
                required List<int> counts,
                required String reason,
              }) async {
                reasons.add(reason);
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('优惠'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('招待'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(reasons, ['招待']);
    expect(find.text('优惠成功'), findsOneWidget);
  });

  testWidgets('product discount posts addYh after choosing a reason', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final posted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          remaining: const {'101': 4},
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          yhReasons: const ['招待'],
          addYh:
              ({
                required String seatId,
                required String productId,
                required int count,
                required String amount,
                required String price,
                required String reason,
              }) async {
                posted.add(reason);
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('优惠').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('招待'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(posted, ['招待']);
    expect(find.text('加入购物车成功'), findsOneWidget);
  });

  testWidgets('cart requirement posts add_requirement', (tester) async {
    final notes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          loadCartItems: (seatId) async => Success([
            const OrderCartItem(
              id: '9',
              productId: '101',
              count: 1,
              unitPrice: '38',
              amount: '38',
            ),
          ]),
          loadCartCount: (seatId) async => const Success(1),
          addRequirement:
              ({
                required String seatId,
                required String itemId,
                required String requirement,
              }) async {
                notes.add(requirement);
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('要求'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(OrderMealScreen.requirementKey), '少冰');
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(notes, ['少冰']);
    expect(find.text('修改成功'), findsOneWidget);
  });

  testWidgets('chosen tab lists current cart lines read-only', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          loadCartItems: (seatId) async => Success([
            const OrderCartItem(
              id: '9',
              productId: '101',
              count: 2,
              unitPrice: '38',
              amount: '76',
            ),
          ]),
          loadCartCount: (seatId) async => const Success(2),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.chosenTabKey));
    await tester.pumpAndSettle();
    expect(find.text('莫吉托'), findsWidgets);
    expect(find.textContaining('数量 2'), findsOneWidget);
    expect(find.text('删除'), findsNothing);
  });

  testWidgets('my-order gift posts yh_prd after choosing a reason', (
    tester,
  ) async {
    final posted = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          loadOrders:
              ({required String seatId, required int turnoverCount}) async =>
                  Success([
                    const OrderPlacedItem(
                      id: '9',
                      productId: '101',
                      name: '莫吉托',
                      count: 1,
                      unitPrice: '38',
                      amount: '38',
                      orderedAt: '12:00',
                      waiterName: '',
                    ),
                  ]),
          yhReasons: const ['招待'],
          giftOrdered:
              ({
                required String seatId,
                required List<String> orderIds,
                required List<int> counts,
                required String reason,
              }) async {
                posted.add(reason);
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('赠送'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('招待'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(posted, ['招待']);
    expect(find.text('优惠成功'), findsOneWidget);
  });

  testWidgets('reprint kitchen ticket posts reprt_cp', (tester) async {
    final ids = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          loadOrders:
              ({required String seatId, required int turnoverCount}) async =>
                  Success([
                    const OrderPlacedItem(
                      id: '9',
                      productId: '101',
                      name: '莫吉托',
                      count: 1,
                      unitPrice: '38',
                      amount: '38',
                      orderedAt: '12:00',
                      waiterName: '',
                    ),
                  ]),
          reprintKitchen: (orderId) async {
            ids.add(orderId);
            return const Success(null);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('补打出品'));
    await tester.pumpAndSettle();
    expect(ids, ['9']);
    expect(find.text('打印成功'), findsOneWidget);
  });

  testWidgets('more menu cleans the current seat', (tester) async {
    var cleaned = '';
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          cleanSeat: (seatId) async {
            cleaned = seatId;
            return const Success(null);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderMealScreen.moreKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清台'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(cleaned, '100');
    expect(find.text('清台成功'), findsOneWidget);
  });

  testWidgets('redeem coupon posts kq_csm_by_code', (tester) async {
    final codes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: OrderMealScreen(
          pricingContext: const ProductPricingContext(
            isBusiness: false,
            isBox: false,
            isMember: false,
          ),
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          fcPriceCatalog: _prices(null),
          table: _table(),
          catalog: _catalog(),
          moduleIds: const {86},
          addProduct: ({
            required String seatId,
            required String productId,
            required int count,
            required String price,
            String amount = '',
          }) async => const Success(null),
          redeemCoupon: (authCode) async {
            codes.add(authCode);
            return const Success(null);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('核销卡券'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(OrderMealScreen.redeemFieldKey),
      'ABC123',
    );
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(codes, ['ABC123']);
    expect(find.text('卡券核销成功'), findsOneWidget);
  });
  testWidgets(
    'more menu opens vip recharge when callback provided and shows warning when absent',
    (tester) async {
      var rechargeCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              table: _table(),
              catalog: _catalog(),
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              addProduct: ({
                required String seatId,
                required String productId,
                required int count,
                required String price,
                String amount = '',
              }) async => const Success(null),
              onOpenVipRecharge: () async => rechargeCalls++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('充值'));
      await tester.pumpAndSettle();
      expect(rechargeCalls, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              table: _table(),
              catalog: _catalog(),
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              addProduct: ({
                required String seatId,
                required String productId,
                required int count,
                required String price,
                String amount = '',
              }) async => const Success(null),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('充值'));
      await tester.pumpAndSettle();
      expect(find.text('会员充值尚未接入点单页'), findsOneWidget);
    },
  );
  testWidgets(
    'more menu opens late deposit and transfer seat or warns if missing',
    (tester) async {
      var depositCalls = 0;
      var transferCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              table: _table(),
              catalog: _catalog(),
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              addProduct: ({
                required String seatId,
                required String productId,
                required int count,
                required String price,
                String amount = '',
              }) async => const Success(null),
              onOpenLateDeposit: () async => depositCalls++,
              onTransferSeat: () async => transferCalls++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('滞留金'));
      await tester.pumpAndSettle();
      expect(depositCalls, 1);

      await tester.tap(find.byKey(OrderMealScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('转台'));
      await tester.pumpAndSettle();
      expect(transferCalls, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              table: _table(),
              catalog: _catalog(),
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              addProduct: ({
                required String seatId,
                required String productId,
                required int count,
                required String price,
                String amount = '',
              }) async => const Success(null),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('滞留金'));
      await tester.pumpAndSettle();
      expect(find.text('滞留金尚未接入'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(find.byType(OrderMealScreen)))
          .clearSnackBars();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(OrderMealScreen.moreKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('转台'));
      await tester.pumpAndSettle();
      expect(find.text('转台尚未接入'), findsOneWidget);
    },
  );
}

FcPriceCatalog _prices(int? cents) {
  final data = List<Object?>.filled(60, null);
  data[58] = cents == null
      ? []
      : [
          [101, 1, cents, 1],
        ];
  data[59] = [
    [1, 11, 1],
  ];
  return FcPriceCatalog.unknown.apply(data);
}

CardTable _table({
  num orderAmount = 0,
  num paidAmount = 0,
  num paidValAmount = 0,
  num mainOrderAmount = 0,
  num discountAmount = 0,
  int turnoverCount = 0,
}) => CardTable(
  id: '100',
  name: 'A01',
  regionId: '1',
  seatType: 1,
  businessType: 1,
  capacity: 4,
  displayOrder: 1,
  businessStatus: 4,
  orderAmount: orderAmount,
  paidAmount: paidAmount,
  customerName: '',
  customerCount: 0,
  reservationTime: '',
  openTime: '20260909120000',
  remark: '',
  mark: '',
  paidValAmount: paidValAmount,
  mainOrderAmount: mainOrderAmount,
  discountAmount: discountAmount,
  turnoverCount: turnoverCount,
);

SoldOutProductCatalog _catalog({
  int prdType = 1,
  String productId = '101',
  String name = '莫吉托',
  String price = '38',
}) => SoldOutProductCatalog.forRegion(
  regionId: '1',
  firstCategories: [
    ['1', '酒水', '1', 1],
  ],
  secondCategories: [
    ['11', '鸡尾酒', '1', 1, '1'],
  ],
  products: [
    [
      productId,
      name,
      '1',
      1,
      'mjt',
      'Mojito',
      '1',
      '11',
      price,
      prdType,
      1,
      0,
      1,
      '',
      '2',
      '2',
    ],
  ],
  areaProducts: [
    ['1', '1', productId],
  ],
  padDevice: true,
);

Future<void> _openGuestDialog(
  WidgetTester tester, {
  required OrderMealSearchGuests search,
  OrderMealBindGuest? bind,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: _mobileOrderScreen(searchGuests: search, bindGuest: bind),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(OrderMealScreen.bindGuestKey));
  await tester.pumpAndSettle();
}

OrderMealScreen _mobileOrderScreen({
  OrderMealSearchGuests? searchGuests,
  OrderMealBindGuest? bindGuest,
  OrderMealListOrders? loadOrders,
}) => OrderMealScreen(
  pricingContext: const ProductPricingContext(
    isBusiness: false,
    isBox: false,
    isMember: false,
  ),
  table: _table(),
  catalog: _catalog(),
  operationContext: const AlwaysStoppedAnimation<Object?>(true),
  bindGuestEnabled: true,
  searchGuests: searchGuests,
  bindGuest: bindGuest,
  loadOrders: loadOrders,
  addProduct: ({
    required seatId,
    required productId,
    required count,
    required price,
    String amount = '',
  }) async => const Success(null),
);
