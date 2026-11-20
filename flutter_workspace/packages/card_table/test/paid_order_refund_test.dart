import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/paid_order_refund.dart';
import 'package:flutter_test/flutter_test.dart';

PayOrderItem line(
  String id, {
  int count = 3,
  String pp = '100',
  String pa = '210',
  bool online = false,
  bool back = false,
  int at = 0,
}) => PayOrderItem(
  id: id,
  productId: id,
  name: '商品$id',
  count: count,
  unitPrice: pp,
  recordedUnitPrice: '80',
  amount: pa,
  online: online,
  refunded: back,
  authorizationType: at,
);
PaidOrderRefundDraft draft(
  List<PayOrderItem> items, {
  int? type = 1,
  bool old = false,
}) => PaidOrderRefundDraft.fromRecord(
  record: PayedOrderRecord(id: '71', items: items),
  seatId: '100',
  turnoverCount: 2,
  isOldOrder: old,
  productTypeFor: (_) => type,
).withReason('客人退单');

void main() {
  test(
    'a line with another real payment owner cannot be mixed into this receipt',
    () {
      const item = PayOrderItem(
        id: '11',
        productId: '9',
        name: '商品',
        count: 1,
        unitPrice: '80',
        amount: '80',
        paidOrderId: '72',
      );
      expect(draft([item]).validate()?.safeMessage, '订单不属于当前付款单');
    },
  );
  test('unknown type has no assumed ordinary refund quote', () {
    final value = draft([line('11')], type: null);
    expect(value.amounts, ['']);
    expect(value.lines.single.quantityEditable, isFalse);
    expect(value.validate(), isNotNull);
  });
  test('paid selection preserves pay identity and aligned historical amount arrays', () {
    final value = draft([
      line('11', at: 2),
      line('12', back: true),
      line('13', count: 0),
    ]);
    expect(value.payId, '71');
    expect(value.orderIds, ['11']);
    expect(value.counts, [3]);
    expect(value.amounts, ['210']);
    expect(value.validate(), isNull);
    final part = value.withCount('11', 1);
    expect(part.amounts, ['80']);
    expect(part.validate(), isNull);
    expect(part.selectAll(false).validate(), isNotNull);
  });
  test('paid online and tip are not restricted by unpaid quantity rules', () {
    for (final type in [1, 4]) {
      final value = draft([
        line('11', online: true, pp: '0'),
      ], type: type).withCount('11', 1);
      expect(value.lines.single.quantityEditable, isTrue);
      expect(value.counts, [1]);
      expect(value.amounts, ['210']);
      expect(value.validate(), isNull);
    }
  });
  test('special partial refund needs new bounded amount and whole count restores raw pa', () {
    for (final type in [3, 5, 8]) {
      final whole = draft([line('11', pa: '210.25')], type: type);
      expect(whole.amounts, ['210.25']);
      expect(whole.lines.single.amountEditable, isFalse);
      final part = whole.withCount('11', 1);
      expect(part.lines.single.amount, '');
      expect(part.validate(), isNotNull);
      expect(part.withAmount('11', '80.25').amounts, ['80.25']);
      expect(part.withAmount('11', '80.25').validate(), isNull);
      for (final amount in ['211', '-1', 'NaN', 'Infinity']) {
        expect(part.withAmount('11', amount).validate(), isNotNull);
      }
      expect(part.withAmount('11', '0').validate(), isNull);
      expect(part.withAmount('11', '80').withCount('11', 3).amounts, [
        '210.25',
      ]);
    }
  });
  test('historical turnover, unknown type, duplicate ids and bad quantities fail closed', () {
    expect(draft([line('11')], old: true).validate(), isNotNull);
    expect(draft([line('11')], type: null).validate(), isNotNull);
    expect(draft([line('11'), line('011')]).validate(), isNotNull);
    expect(draft([line('11')]).withCount('11', 4).validate(), isNotNull);
    expect(draft([line('11')]).withCount('11', 0).validate(), isNotNull);
    expect(draft([line('11')]).withReason('').validate(), isNotNull);
  });
  test('metadata loss after opening invalidates the selected draft', () {
    int? type = 1;
    final value = PaidOrderRefundDraft.fromRecord(
      record: PayedOrderRecord(id: '71', items: [line('11')]),
      seatId: '100',
      turnoverCount: 2,
      isOldOrder: false,
      productTypeFor: (_) => type,
    ).withReason('理由');
    expect(value.validate(), isNull);
    type = null;
    expect(value.validate(), isNotNull);
  });
}
