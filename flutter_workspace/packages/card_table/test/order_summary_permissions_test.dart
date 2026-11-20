import 'package:card_table/src/product_pricing.dart';
import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:permissions/permissions.dart';

PermissionSnapshot permission({
  bool available = true,
  Set<int> roles = const {3},
  Set<int> modules = const {12, 99},
}) => PermissionSnapshot(
  available: available,
  stationId: 1,
  roleIds: roles,
  moduleIds: modules,
  subPermissions: const {},
);

void main() {
  test(
    'summary fails closed until permissions known and PC restriction is exact',
    () {
      expect(
        OrderCardDisplay.canShowOrderSummary(permissions: null, isPc: true),
        false,
      );
      expect(
        OrderCardDisplay.canShowOrderSummary(
          permissions: permission(available: false),
          isPc: false,
        ),
        false,
      );
      expect(
        OrderCardDisplay.canShowOrderSummary(
          permissions: permission(),
          isPc: true,
        ),
        false,
      );
      expect(
        OrderCardDisplay.canShowOrderSummary(
          permissions: permission(),
          isPc: false,
        ),
        true,
      );
      expect(
        OrderCardDisplay.canShowOrderSummary(
          permissions: permission(roles: {}),
          isPc: true,
        ),
        true,
      );
      expect(
        OrderCardDisplay.canShowOrderSummary(
          permissions: permission(modules: {12}),
          isPc: true,
        ),
        true,
      );
      expect(
        OrderCardDisplay.canShowOrderSummary(
          permissions: permission(modules: {99}),
          isPc: true,
        ),
        true,
      );
    },
  );
  testWidgets(
    'pushed-style live visibility revokes and default hides summary',
    (tester) async {
      final visible = ValueNotifier(false);
      addTearDown(visible.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            pricingContext: const ProductPricingContext(
              isBusiness: false,
              isBox: false,
              isMember: false,
            ),
            table: CardTable(
              id: '1',
              name: 'A',
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
            orderSummaryVisibility: visible,
            addProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
              String amount = '',
            }) async => const Success(null),
            loadOrderDetails:
                ({required String seatId, required int turnoverCount}) async =>
                    const Success(
                      OrderPlacedData(
                        summary: OrderSummary(
                          allAmt: '12.00',
                          giveAmt: '2.00',
                          discountAmt: '1.00',
                          notPayAmt: '9.00',
                        ),
                      ),
                    ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(OrderMealScreen.myOrderTabKey));
      await tester.pumpAndSettle();
      expect(find.text('折前金额 ￥12.00'), findsNothing);
      expect(find.textContaining('折前金额:'), findsNothing);
      visible.value = true;
      await tester.pumpAndSettle();
      expect(find.text('折前金额 ￥12.00'), findsOneWidget);
      visible.value = false;
      await tester.pumpAndSettle();
      expect(find.text('折前金额 ￥12.00'), findsNothing);
      expect(find.textContaining('折前金额:'), findsNothing);
      expect(find.byKey(OrderMealScreen.myOrderTabKey), findsOneWidget);
    },
  );
}
