import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/wine_order.dart';
import 'package:card_table/src/wine_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('save wine submits two-step order with cart id and phone', (
    tester,
  ) async {
    final posted = <Map<String, Object?>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: WineOrderScreen(
          table: _table(),
          action: WineOrderAction.save,
          listCsms: (seatId) async => const Success([
            WineSaveCsm(id: '7', phone: '13800000000', name: '张三'),
          ]),
          submitSave:
              ({
                required List<String> cartIds,
                required String phone,
                required String name,
                required String authCode,
              }) async {
                posted.add({
                  'cartIds': cartIds,
                  'phone': phone,
                  'name': name,
                  'authCode': authCode,
                });
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('张三'), findsOneWidget);
    await tester.enterText(find.byKey(WineOrderScreen.cartIdsKey), '3');
    await tester.enterText(find.byKey(WineOrderScreen.authCodeKey), '1234');
    await tester.tap(find.widgetWithText(FilledButton, '存酒'));
    await tester.pumpAndSettle();
    expect(posted, isNotEmpty);
    expect(posted.single['cartIds'], ['3']);
    expect(posted.single['phone'], '13800000000');
    expect(find.text('存酒成功'), findsOneWidget);
  });

  testWidgets('take wine posts inventory ids for the current seat', (
    tester,
  ) async {
    final posted = <Map<String, Object?>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: WineOrderScreen(
          table: _table(),
          action: WineOrderAction.take,
          submitTake:
              ({
                required String seatId,
                required List<String> inventoryIds,
                required List<int> counts,
                required String phone,
                required String authCode,
              }) async {
                posted.add({
                  'seatId': seatId,
                  'inventoryIds': inventoryIds,
                  'counts': counts,
                  'phone': phone,
                });
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(WineOrderScreen.phoneKey), '13800000000');
    await tester.enterText(find.byKey(WineOrderScreen.cartIdsKey), '5');
    await tester.enterText(find.byKey(WineOrderScreen.authCodeKey), '1234');
    await tester.tap(find.widgetWithText(FilledButton, '取酒'));
    await tester.pumpAndSettle();
    expect(posted.single['seatId'], '100');
    expect(posted.single['inventoryIds'], ['5']);
    expect(find.text('取酒成功'), findsOneWidget);
  });

  testWidgets('confiscate posts leftover wine for the current seat', (
    tester,
  ) async {
    final posted = <Map<String, Object?>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: WineOrderScreen(
          table: _table(),
          action: WineOrderAction.confiscate,
          submitConfiscate:
              ({
                required String seatId,
                required String date,
                required String salesEmpId,
                required List<String> productIds,
                required List<String> unitTypes,
                required List<int> counts,
                required List<int> grams,
              }) async {
                posted.add({
                  'seatId': seatId,
                  'salesEmpId': salesEmpId,
                  'productIds': productIds,
                });
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(WineOrderScreen.salesEmpKey), '8');
    await tester.enterText(find.byKey(WineOrderScreen.cartIdsKey), '101');
    await tester.tap(find.widgetWithText(FilledButton, '充公'));
    await tester.pumpAndSettle();
    expect(posted.single['seatId'], '100');
    expect(posted.single['salesEmpId'], '8');
    expect(posted.single['productIds'], ['101']);
    expect(find.text('充公成功'), findsOneWidget);
  });
}

CardTable _table() => CardTable(
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
  customerCount: 0,
  reservationTime: '',
  openTime: '20260909120000',
  remark: '',
  mark: '',
  paidValAmount: 0,
);
