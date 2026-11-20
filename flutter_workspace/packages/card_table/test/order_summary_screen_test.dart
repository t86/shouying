import 'package:card_table/src/product_pricing.dart';
import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  for (final known in [true, false]) {
    testWidgets(
      'my order summary ${known ? 'uses pay_info' : 'does not invent zero'}',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: OrderMealScreen(
              pricingContext: const ProductPricingContext(
                isBusiness: false,
                isBox: false,
                isMember: false,
              ),
              showOrderSummary: true,
              table: CardTable(
                id: '100',
                name: 'A01',
                regionId: '1',
                seatType: 1,
                businessType: 1,
                capacity: 4,
                displayOrder: 1,
                businessStatus: 4,
                orderAmount: 9999,
                paidAmount: 0,
                customerName: '',
                customerCount: 0,
                reservationTime: '',
                openTime: '',
                remark: '',
                mark: '',
              ),
              catalog: SoldOutProductCatalog.forRegion(
                regionId: '1',
                firstCategories: [],
                secondCategories: [],
                products: [],
                areaProducts: [],
                padDevice: false,
              ),
              addProduct: ({
                required String seatId,
                required String productId,
                required int count,
                required String price,
                String amount = '',
              }) async => const Success(null),
              loadOrderDetails:
                  ({
                    required String seatId,
                    required int turnoverCount,
                  }) async => Success(
                    OrderPlacedData(
                      summary: known
                          ? const OrderSummary(
                              allAmt: '12.00',
                              giveAmt: '2.00',
                              discountAmt: '1.50',
                              notPayAmt: '7.00',
                            )
                          : null,
                    ),
                  ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
        await tester.pumpAndSettle();
        expect(find.text(known ? '折前金额 ￥12.00' : '折前金额 --'), findsOneWidget);
        expect(find.text(known ? '优惠金额 ￥2.00' : '优惠金额 --'), findsOneWidget);
        expect(find.text(known ? '折扣金额 ￥1.50' : '折扣金额 --'), findsOneWidget);
        expect(find.text(known ? '未结账金额 ￥7.00' : '未结账金额 --'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
