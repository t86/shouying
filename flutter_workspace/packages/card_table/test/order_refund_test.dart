import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/order_refund.dart';
import 'package:flutter_test/flutter_test.dart';

OrderPlacedItem order({
  int count = 4,
  bool online = false,
  String pp = '100',
  String pa = '150',
  int at = 0,
  bool refunded = false,
}) => OrderPlacedItem(
  id: '11',
  productId: '9',
  name: '记录商品',
  count: count,
  unitPrice: pp,
  recordedUnitPrice: '80',
  amount: pa,
  orderedAt: '',
  waiterName: '',
  authorizationType: at,
  online: online,
  refunded: refunded,
);
void main() {
  test('source priced compensation15 and voucher package12/22 keep ordinary amount contract', () {
    for (final type in [12, 13, 14, 15, 22]) {
      final draft = OrderRefundDraft.fromOrder(
        order: order(),
        productType: type,
        isCashier: false,
      ).withReason('理由');
      expect(draft.backAmount, '');
      expect(draft.quantityEditable, isTrue);
      expect(draft.withCount(2).validate(), isNull);
    }
  });
  test('priced tip14 is ordinary refund, unlike variable tip4', () {
    final draft = OrderRefundDraft.fromOrder(
      order: order(),
      productType: 14,
      isCashier: false,
    ).withReason('理由');
    expect(draft.quantityEditable, isTrue);
    expect(draft.count, 1);
    expect(draft.withCount(2).validate(), isNull);
    expect(draft.backAmount, '');
  });
  test(
    'ordinary operator defaults and wire amount follow type not pp or at',
    () {
      for (final cashier in [false, true]) {
        final draft = OrderRefundDraft.fromOrder(
          order: order(pp: '0', at: 2),
          productType: 1,
          isCashier: cashier,
        ).withReason('客人退单');
        expect(draft.count, cashier ? 4 : 1);
        expect(draft.quantityEditable, isTrue);
        expect(draft.backAmount, '');
        expect(draft.withCount(2).validate(), isNull);
        expect(draft.withCount(0).validate(), isNotNull);
        expect(draft.withCount(5).validate(), isNotNull);
      }
    },
  );
  test('online is full quantity and tip always fixed one', () {
    final online = OrderRefundDraft.fromOrder(
      order: order(online: true),
      productType: 1,
      isCashier: false,
    ).withReason('理由');
    expect(online.count, 4);
    expect(online.quantityEditable, isFalse);
    expect(online.withCount(1).validate(), isNotNull);
    final tip = OrderRefundDraft.fromOrder(
      order: order(),
      productType: 4,
      isCashier: true,
    ).withReason('理由');
    expect(tip.count, 1);
    expect(tip.quantityEditable, isFalse);
    expect(tip.withCount(2).validate(), isNotNull);
    expect(tip.backAmount, '');
  });
  test('special noncashier uses raw pa even for gifts and cannot split', () {
    for (final type in [3, 5, 8]) {
      final draft = OrderRefundDraft.fromOrder(
        order: order(at: 2, pa: '150.25'),
        productType: type,
        isCashier: false,
      ).withReason('理由');
      expect(draft.count, 4);
      expect(draft.quantityEditable, isFalse);
      expect(draft.amountEditable, isFalse);
      expect(draft.backAmount, '150.25');
      expect(draft.validate(), isNull);
      expect(draft.withCount(2).validate(), isNotNull);
      expect(draft.withAmount('1').validate(), isNotNull);
    }
  });
  test('special cashier partial count clears amount and requires bounded manual yuan', () {
    final whole = OrderRefundDraft.fromOrder(
      order: order(pa: '150'),
      productType: 3,
      isCashier: true,
    ).withReason('理由');
    expect(whole.count, 4);
    expect(whole.backAmount, '150');
    expect(whole.amountEditable, isFalse);
    final part = whole.withCount(2);
    expect(part.amount, '');
    expect(part.amountEditable, isTrue);
    expect(part.validate(), isNotNull);
    for (final invalid in ['', 'NaN', 'Infinity', '-1', '150.01']) {
      expect(part.withAmount(invalid).validate(), isNotNull);
    }
    expect(part.withAmount('0').validate(), isNull);
    expect(part.withAmount('80.50').backAmount, '80.50');
    expect(part.withAmount('80.50').validate(), isNull);
    expect(part.withAmount('80.50').withCount(1).amount, '');
    expect(part.withAmount('80.50').withCount(4).backAmount, '150');
  });
  test('unknown product type, stale/refunded order, missing pa and missing reason fail closed', () {
    expect(
      OrderRefundDraft.fromOrder(
        order: order(),
        productType: null,
        isCashier: false,
      ).withReason('理由').validate()?.code,
      orderRefundUnknownProductTypeCode,
    );
    expect(
      OrderRefundDraft.fromOrder(
        order: order(),
        productType: 99,
        isCashier: false,
      ).withReason('理由').validate()?.code,
      orderRefundUnknownProductTypeCode,
    );
    expect(
      OrderRefundDraft.fromOrder(
        order: order(refunded: true),
        productType: 1,
        isCashier: false,
      ).withReason('理由').validate(),
      isNotNull,
    );
    expect(
      OrderRefundDraft.fromOrder(
        order: order(pa: ''),
        productType: 3,
        isCashier: false,
      ).withReason('理由').validate(),
      isNotNull,
    );
    expect(
      OrderRefundDraft.fromOrder(
        order: order(),
        productType: 1,
        isCashier: false,
      ).validate(),
      isNotNull,
    );
  });
}
