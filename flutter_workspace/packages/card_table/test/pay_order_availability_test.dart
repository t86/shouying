import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/pay_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  Future<void> pumpSubject(
    WidgetTester tester, {
    PayOrderCustomerCodePay? pay,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: PayOrderScreen(
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          table: CardTable(
            id: '1',
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
            openTime: '',
            remark: '',
            mark: '',
            paidValAmount: 0,
          ),
          loadOrders: ({required seatId, required turnoverCount}) async =>
              Success(PayOrderData(seatId: seatId)),
          customerPaymentCodePay: pay,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('unavailable payment code cannot open a misleading charge form', (
    tester,
  ) async {
    await pumpSubject(tester);
    final finder = find.widgetWithText(FilledButton, '付款码');
    expect(tester.widget<FilledButton>(finder).onPressed, isNull);
    expect(find.byTooltip('付款码支付暂不可用'), findsOneWidget);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(find.text('立即扣款'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('configured payment code remains available', (tester) async {
    await pumpSubject(
      tester,
      pay: ({required seatId, required paymentCode, required amount}) async =>
          const Success(null),
    );
    final finder = find.widgetWithText(FilledButton, '付款码');
    expect(tester.widget<FilledButton>(finder).onPressed, isNotNull);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(find.text('客人付款码支付'), findsOneWidget);
    expect(find.text('立即扣款'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
