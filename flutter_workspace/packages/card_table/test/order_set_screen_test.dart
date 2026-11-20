import 'package:card_table/src/product_pricing.dart';

import 'dart:async';

import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/order_set_catalog.dart';
import 'package:card_table/src/order_set_dialog.dart';
import 'package:card_table/src/order_set_selection.dart';
import 'package:card_table/src/fc_price.dart';
import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/order_meal_screen.dart';
import 'package:card_table/src/sold_out_products.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'order_set_catalog_test.dart' as set_fixture show data;

CardTable table() => CardTable(
  id: '100',
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
  customerCount: 1,
  reservationTime: '',
  openTime: '',
  remark: '',
  mark: '',
);
SoldOutProductCatalog catalog({int productId = 301}) =>
    SoldOutProductCatalog.forRegion(
      regionId: '1',
      firstCategories: [
        [1, '套餐', 1, 1],
      ],
      secondCategories: [
        [11, '套餐', 1, 1, 1],
      ],
      products: [
        [productId, '测试套餐', 1, 1, '', '', 1, 11, '100', 2, 1, 0, 1, '', 2, 2],
      ],
      areaProducts: [
        [1, 1, productId],
      ],
      padDevice: true,
    );
const details = [
  OrderSetDetail(
    productId: '301',
    groupId: '2',
    detailProductId: '11',
    detailCount: 1,
    groupSelectCount: 1,
    name: '候选A',
  ),
  OrderSetDetail(
    productId: '301',
    groupId: '2',
    detailProductId: '12',
    detailCount: 2,
    groupSelectCount: 1,
    name: '候选B',
  ),
];
void main() {
  for (final stock in ['unlimited', 'zero', 'division', 'parent', 'unknown']) {
    testWidgets(
      'set card projects fixed detail stock $stock and live recovery',
      (tester) async {
        final raw = set_fixture.data();
        raw[8] = switch (stock) {
          'zero' => [
            [11, 0, 1],
          ],
          'division' => [
            [11, 7, 1],
          ],
          'parent' => [
            [900, 1, 1],
            [11, 7, 1],
          ],
          'unknown' => null,
          _ => [],
        };
        var source = OrderSetCatalog.unknown.apply(raw);
        final prices = ValueNotifier(
          FcPriceCatalog.unknown.apply({'58': [], '59': []}, isFull: true),
        );
        addTearDown(prices.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              table: table(),
              catalog: catalog(productId: 900),
              currentSetCatalog: () => source,
              fcPrices: prices,
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
        );
        await tester.pumpAndSettle();
        if (stock == 'zero') expect(find.text('售罄'), findsOneWidget);
        if (stock == 'division') expect(find.text('余:3'), findsOneWidget);
        if (stock == 'parent') expect(find.text('余:1'), findsOneWidget);
        if (stock == 'unknown') expect(find.text('库存待同步'), findsOneWidget);
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, '加入'),
        );
        expect(button.onPressed == null, stock == 'zero' || stock == 'unknown');
        source = OrderSetCatalog.unknown.apply(
          set_fixture.data()
            ..[8] = [
              [11, 8, 1],
            ],
        );
        prices.value = prices.value.apply({'58': [], '59': []});
        await tester.pump();
        expect(find.text('余:4'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, '加入'))
              .onPressed,
          isNotNull,
        );
      },
    );
  }
  for (final inventory in ['many', 'limited', 'failed', 'missing']) {
    testWidgets(
      'set detail inventory $inventory is distinguished before mutation',
      (tester) async {
        var writes = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              table: table(),
              catalog: catalog(),
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              fcPriceCatalog: FcPriceCatalog.unknown.apply({
                '58': [],
                '59': [],
              }, isFull: true),
              setDetails: const [
                OrderSetDetail(
                  productId: '301',
                  groupId: '2',
                  detailProductId: '12',
                  detailCount: 2,
                  groupSelectCount: 2,
                  name: '候选B',
                ),
              ],
              loadRemaining: inventory == 'missing'
                  ? null
                  : () async => inventory == 'failed'
                        ? const FailureResult(
                            AppFailure(
                              kind: FailureKind.network,
                              code: 'test',
                              safeMessage: '库存查询失败',
                            ),
                          )
                        : Success(
                            inventory == 'limited'
                                ? {'12': 6}
                                : <String, int>{},
                          ),
              addProduct: ({
                required String seatId,
                required String productId,
                required int count,
                required String price,
                String amount = '',
              }) async => const Success(null),
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
                    writes++;
                    return const Success(null);
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('测试套餐'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('set-add-2-12')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('set-add-2-12')));
        await tester.pump();
        await tester.enterText(find.byKey(const Key('set-package-count')), '2');
        await tester.tap(find.widgetWithText(FilledButton, '确认'));
        await tester.pumpAndSettle();
        expect(writes, inventory == 'many' ? 1 : 0);
      },
    );
  }
  Future<void> large(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<Result<void>> addProduct({
    required String seatId,
    required String productId,
    required int count,
    required String price,
    String amount = '',
  }) async => const Success(null);
  for (final stock in ['many', 'unknown', 'changed']) {
    testWidgets(
      'live set inventory $stock does not depend on management query',
      (tester) async {
        await large(tester);
        final raw = set_fixture.data();
        var source = OrderSetCatalog.unknown.apply(raw);
        var writes = 0;
        var managementReads = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              table: table(),
              catalog: catalog(productId: 900),
              currentSetCatalog: () => source,
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              fcPriceCatalog: FcPriceCatalog.unknown.apply({
                '58': [],
                '59': [],
              }, isFull: true),
              loadRemaining: () async {
                managementReads++;
                return const FailureResult(
                  AppFailure(
                    kind: FailureKind.business,
                    code: 'test',
                    safeMessage: '无估清管理权限',
                  ),
                );
              },
              addProduct: addProduct,
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
                    writes++;
                    return const Success(null);
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final initialReads = managementReads;
        await tester.tap(find.text('测试套餐'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('set-add-2-12')));
        await tester.pump();
        await tester.enterText(
          find.byKey(const Key('set-choice-count-1')),
          '3',
        );
        if (stock == 'changed') {
          source = source.apply({
            '8': [
              [12, 5, 1],
            ],
          });
        }
        if (stock == 'unknown') source = source.apply({'8': null});
        await tester.tap(find.widgetWithText(FilledButton, '确认'));
        await tester.pumpAndSettle();
        expect(writes, stock == 'many' ? 1 : 0);
        expect(managementReads, initialReads);
        if (stock != 'many') {
          expect(find.byType(OrderSetDialog), findsOneWidget);
          expect(find.byKey(const Key('set-choice-count-1')), findsOneWidget);
          expect(find.textContaining('配置已变化'), findsNothing);
        }
      },
    );
  }
  for (final cashier in [false, true]) {
    testWidgets(
      'ordered replacement uses selected old si id and same-group target cashier=$cashier',
      (tester) async {
        await large(tester);
        var reads = 0;
        final writes = <Map<String, Object?>>[];
        const old = OrderSetItem(
          id: '501',
          groupId: '2',
          detailProductId: '11',
          detailCount: 1,
          selectCount: 1,
          requirement: '少冰',
        );
        const item = OrderPlacedItem(
          id: '9',
          productId: '301',
          name: '已下单套餐',
          count: 2,
          unitPrice: '100',
          amount: '200',
          orderedAt: '12:00',
          waiterName: '',
          isSet: true,
          setItems: [old],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              loadRemaining: () async => const Success(<String, int>{}),
              table: table(),
              catalog: catalog(),
              setDetails: details,
              isCashier: cashier,
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              addProduct: addProduct,
              loadOrders:
                  ({required String seatId, required int turnoverCount}) async {
                    reads++;
                    return const Success([item]);
                  },
              changeOrderedSet:
                  ({
                    required String seatId,
                    required String orderId,
                    required String orderDetailId,
                    required List<String> destDetailProductIds,
                    required List<int> destSelectCounts,
                    required List<String> destRequirements,
                    String authEmpCode = '',
                    String authEmpPasswd = '',
                    int passType = 1,
                  }) async {
                    writes.add({
                      'parent': orderId,
                      'old': orderDetailId,
                      'targets': destDetailProductIds,
                      'counts': destSelectCounts,
                      'code': authEmpCode,
                      'password': authEmpPasswd,
                      'passType': passType,
                    });
                    return !cashier && writes.length == 1
                        ? const FailureResult(
                            AppFailure(
                              kind: FailureKind.business,
                              code: orderSetAuthorizationRequiredCode,
                              safeMessage: '需要授权',
                            ),
                          )
                        : const Success(null);
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('改明细'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('set-add-2-12')), findsNothing);
        await tester.tap(find.byKey(const Key('set-old-0')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('set-add-2-12')));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, '确认'));
        await tester.pumpAndSettle();
        if (!cashier) {
          expect(find.text('套餐变更授权'), findsOneWidget);
          await tester.tap(find.text('卡码输入'));
          await tester.pump();
          await tester.enterText(
            find.byKey(const Key('set-auth-code')),
            'synthetic-card',
          );
          await tester.enterText(
            find.byKey(const Key('set-auth-password')),
            'synthetic-decoded',
          );
          await tester.tap(find.text('授权提交'));
          await tester.pumpAndSettle();
          expect(writes.last['passType'], 2);
        } else {
          expect(writes.single['code'], '');
        }
        expect(writes.first['parent'], '9');
        expect(writes.first['old'], '501');
        expect(writes.first['targets'], ['12']);
        expect(reads, greaterThanOrEqualTo(3));
      },
    );
  }
  for (final scenario in ['success', 'old-changed', 'cancel']) {
    testWidgets(
      'cart replacement preserves original group/product/requirement and guards $scenario',
      (tester) async {
        await large(tester);
        var hold = false, changed = false;
        final pending = Completer<Result<List<OrderCartItem>>>();
        Map<String, Object?>? write;
        OrderCartItem cart() => OrderCartItem(
          id: 'cart-9',
          productId: '301',
          count: 2,
          unitPrice: '100',
          amount: '200',
          isSet: true,
          setItems: [
            OrderSetItem(
              groupId: '2',
              detailProductId: changed ? '99' : '11',
              detailCount: 1,
              selectCount: 1,
              requirement: '少冰',
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              loadRemaining: () async => const Success(<String, int>{}),
              table: table(),
              catalog: catalog(),
              setDetails: details,
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              addProduct: addProduct,
              loadCartItems: (_) async =>
                  hold ? pending.future : Success([cart()]),
              changeSetDetail:
                  ({
                    required String seatId,
                    required String itemId,
                    required String groupId,
                    required String detailProductId,
                    required List<String> destDetailProductIds,
                    required List<int> destSelectCounts,
                    required String requirement,
                    required List<String> destRequirements,
                  }) async {
                    write = {
                      'parent': itemId,
                      'group': groupId,
                      'old': detailProductId,
                      'requirement': requirement,
                      'targets': destDetailProductIds,
                    };
                    return const Success(null);
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(OrderMealScreen.cartTabKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('更改明细'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('set-old-0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('set-add-2-12')));
        await tester.pump();
        changed = scenario == 'old-changed';
        hold = scenario == 'cancel';
        await tester.tap(find.widgetWithText(FilledButton, '确认'));
        await tester.pumpAndSettle();
        if (scenario == 'cancel') {
          await tester.tap(find.text('取消'));
          await tester.pumpAndSettle();
          pending.complete(Success([cart()]));
          await tester.pumpAndSettle();
        }
        if (scenario == 'success') {
          expect(write, {
            'parent': 'cart-9',
            'group': '2',
            'old': '11',
            'requirement': '少冰',
            'targets': ['12'],
          });
        } else {
          expect(write, isNull);
        }
      },
    );
  }
  testWidgets(
    'new set retains package quantity and rejects changed template before write',
    (tester) async {
      await large(tester);
      var source = OrderSetCatalog.unknown.apply(set_fixture.data());
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            loadRemaining: () async => const Success(<String, int>{}),
            table: table(),
            catalog: catalog(productId: 900),
            currentSetCatalog: () => source,
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            fcPriceCatalog: FcPriceCatalog.unknown.apply({
              '58': [],
              '59': [],
            }, isFull: true),
            addProduct: addProduct,
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
                  writes++;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('测试套餐'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('set-package-count')), '2');
      await tester.tap(find.byKey(const Key('set-add-2-12')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('set-choice-count-1')), '3');
      final changed = set_fixture.data();
      (changed[9] as List)[1] = [900, 1, 2, 2, 501, 0, 4, 2];
      source = OrderSetCatalog.unknown.apply(changed);
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.textContaining('配置已变化'), findsOneWidget);
    },
  );
  testWidgets(
    'same product with different configured requirements keeps separate rows',
    (tester) async {
      await large(tester);
      OrderSetSelection? sent;
      final configuration = OrderSetConfiguration(
        known: true,
        details: const [
          OrderSetDetail(
            productId: '301',
            groupId: '2',
            detailProductId: '11',
            detailCount: 1,
            groupSelectCount: 2,
            name: '同商品',
          ),
        ],
        requirementsByProduct: {
          '11': [
            OrderSetRequirementGroup(
              id: '1',
              name: '温度',
              modeType: 1,
              items: const [
                OrderSetRequirementItem(id: '1', name: '少冰'),
                OrderSetRequirementItem(id: '2', name: '正常'),
              ],
            ),
          ],
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: ctx,
                  builder: (_) => OrderSetDialog(
                    productId: '301',
                    title: '选择套餐',
                    configuration: configuration,
                    contextToken: const AlwaysStoppedAnimation<Object?>(true),
                    submit: (selection, _, _, _, _) async {
                      sent = selection;
                      return const Success(null);
                    },
                  ),
                ),
                child: const Text('打开'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set-add-2-11')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('set-add-2-11')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('set-requirements-0')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('set-require-0-1-1')));
      await tester.tap(find.byKey(const Key('set-require-0-1-1')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('set-requirements-1')));
      await tester.tap(find.byKey(const Key('set-requirements-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('set-require-1-1-2')));
      await tester.tap(find.byKey(const Key('set-require-1-1-2')));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(sent!.detailProductIds, ['11', '11']);
      expect(sent!.requirements, ['少冰', '正常']);
    },
  );
  testWidgets(
    'new package does not automatically choose every optional candidate',
    (tester) async {
      var writes = 0;
      int? packageCount;
      List<String>? selectedProducts;
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            loadRemaining: () async => const Success(<String, int>{}),
            table: table(),
            catalog: catalog(),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            fcPriceCatalog: FcPriceCatalog.unknown.apply({
              '58': [],
              '59': [],
            }, isFull: true),
            setDetails: details,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
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
                  writes++;
                  packageCount = count;
                  selectedProducts = detailProductIds;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('测试套餐'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      await tester.tap(find.byKey(const Key('set-add-2-12')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('set-package-count')), '3');
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(packageCount, 3);
      expect(selectedProducts, ['12']);
    },
  );
}
