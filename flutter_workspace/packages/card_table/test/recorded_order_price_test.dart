import 'package:card_table/src/pay_order_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('missing pc retains full recorded pa while explicit zero or null pc is exhausted', () {
    expect(RecordedOrderPrice.fromWire({'pp': 100, 'pa': 77}).amountFor(), 77);
    expect(
      RecordedOrderPrice.fromWire({'pp': 100, 'pa': 77, 'pc': null})
          .amountFor(),
      0,
    );
    expect(
      RecordedOrderPrice.fromWire({'pp': 100, 'pa': 77, 'pc': 0}).amountFor(),
      0,
    );
    expect(
      const PayOrderItem(
        id: '1',
        productId: '1',
        name: 'bad',
        count: 1,
        unitPrice: '10',
        amount: 'NaN',
      ).hasValidPaymentAmount,
      isFalse,
    );
  });
  test(
    'history uses p2/pp snapshots, full pa and split recorded unit price',
    () {
      final price = RecordedOrderPrice.fromWire({
        'pp': 100,
        'p2': 80,
        'pa': 150,
        'pc': 2,
      });
      expect(price.unitPrice, 80);
      expect(price.amountFor(), 150);
      expect(price.amountFor(changeCount: 1), 80);
      expect(price.amountFor(changeCount: 0), 0);
      expect(price.amountFor(changeCount: 2), 150);
      expect(
        RecordedOrderPrice.fromWire({'pp': 100, 'p2': 0, 'pa': 0, 'pc': 2})
            .unitPrice,
        0,
      );
      expect(
        RecordedOrderPrice.fromWire({'pp': 100, 'p2': '', 'pc': 2}).amountFor(),
        200,
      );
      expect(
        RecordedOrderPrice.fromWire({'pp': 100, 'p2': null, 'pc': 2}).unitPrice,
        100,
      );
      expect(
        RecordedOrderPrice.fromWire({'pa': 77, 'pc': 2})
            .amountFor(changeCount: 1),
        77,
      );
    },
  );
  test('time prices remain indivisible even with p2 and gifts charge zero but refund snapshot', () {
    final time = RecordedOrderPrice.fromWire({
      'pp': '0',
      'p2': 80,
      'pa': 150,
      'pc': 2,
    });
    expect(time.isTimePrice, isTrue);
    expect(time.unitPrice, isNull);
    expect(time.amountFor(changeCount: 1), 150);
    for (final at in [2, 3]) {
      final gift = RecordedOrderPrice.fromWire({
        'pp': 100,
        'p2': 80,
        'pa': 150,
        'pc': 2,
        'at': at,
      });
      expect(gift.amountFor(), 0);
      expect(gift.amountFor(changeCount: 1), 0);
      expect(gift.amountFor(refund: true), 150);
      expect(gift.amountFor(changeCount: 1, refund: true), 80);
    }
    expect(
      RecordedOrderPrice.fromWire({'pp': 100, 'pa': 999, 'pc': 0}).amountFor(),
      0,
    );
  });
  test('unpaid remaining totals ignore refunded/exhausted rows and round each line to cents', () {
    PayOrderItem item(
      String id, {
      String pp = '0.335',
      String pa = '',
      int count = 1,
      bool back = false,
      int at = 0,
    }) => PayOrderItem(
      id: id,
      productId: '9',
      name: '历史物料',
      count: count,
      unitPrice: pp,
      amount: pa,
      refunded: back,
      authorizationType: at,
    );
    final data = PayOrderData(
      seatId: '1',
      unpayItems: [
        item('1'),
        item('2'),
        item('3', pp: '0.1'),
        item('4', pp: '0.2'),
        item('5', pp: '0', pa: '12.34', count: 3),
        item('6', pp: '0', pa: '999', count: 0),
        item('7', pp: '999', back: true),
        item('8', pp: '999', at: 2),
      ],
    );
    expect(data.unpayAmt.toStringAsFixed(2), '13.32');
  });
  test('wo pay_info uses cents and four distinct source formulas, missing fields zero', () {
    final summary = OrderSummary.fromWire({
      'order_amt': '380000',
      'discount_amt': '120000',
      'payed_amt': '60000',
      'payed_free_amt': '1000',
      'yh_amt': '123',
    });
    expect(summary.allAmt, '5000.00');
    expect(summary.giveAmt, '1.23');
    expect(summary.discountAmt, '1210.00');
    expect(summary.notPayAmt, '3200.00');
    expect(OrderSummary.fromWire({}).notPayAmt, '0.00');
    expect(
      OrderSummary.fromWire({'order_amt': 0, 'payed_amt': 0}).allAmt,
      '0.00',
    );
  });
}
