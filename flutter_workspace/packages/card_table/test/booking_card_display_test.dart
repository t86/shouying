import 'package:card_table/card_table.dart';
import 'package:flutter_test/flutter_test.dart';

CardTable _table({
  int status = 4,
  int capacity = 0,
  num minimum = 0,
  num main = 0,
  num paidFree = 0,
  String name = '张先生',
  String phone = '',
  String remark = '',
}) => CardTable(
  id: '1',
  name: 'A08',
  regionId: '1',
  seatType: 1,
  businessType: 1,
  capacity: capacity,
  displayOrder: 1,
  businessStatus: status,
  orderAmount: 0,
  paidAmount: 0,
  customerName: name,
  customerCount: 0,
  reservationTime: '',
  openTime: '20261119201500',
  remark: remark,
  mark: '',
  salesEmployeeId: '',
  waiterEmployeeIds: const [],
  turnoverCount: 0,
  giftAmount: 0,
  assignedMinConsumeAmount: minimum,
  mainOrderAmount: main,
  paidMainFreeAmount: paidFree,
  customerPhone: phone,
);

void main() {
  test('amounts only on open, ordering and paid tables', () {
    expect([1, 2, 4, 5, 6, 7, 8].where(BookingCardDisplay.showsAmounts),
        [4, 5, 6, 7]);
  });

  test('guest rows hidden on empty and locked tables', () {
    expect(BookingCardDisplay.showsGuest(1), isFalse);
    expect(BookingCardDisplay.showsGuest(2), isFalse);
    expect(BookingCardDisplay.showsGuest(8), isTrue);
  });

  test('capacity only on empty tables and defaults to 1', () {
    expect(BookingCardDisplay.showsCapacity(1), isTrue);
    expect(BookingCardDisplay.showsCapacity(4), isFalse);
    expect(BookingCardDisplay.capacity(_table(capacity: 0)), 1);
    expect(BookingCardDisplay.capacity(_table(capacity: 8)), 8);
  });

  test('minimum-spend progress matches the Vue diXiaoJindu rule', () {
    final half = _table(minimum: 2000, main: 1200, paidFree: 200);
    expect(BookingCardDisplay.mainAmount(half), 1000);
    expect(BookingCardDisplay.minConsumeLabel(half), '50%');
    expect(
      BookingCardDisplay.minConsumeLabel(_table(minimum: 100, main: 250)),
      '100%',
    );
    expect(BookingCardDisplay.minConsumeProgress(_table()), isNull);
    expect(BookingCardDisplay.minConsumeLabel(_table()), '');
  });

  test('guest label masks the middle of the phone number', () {
    expect(BookingCardDisplay.maskPhone('13812345678'), '138****5678');
    expect(BookingCardDisplay.maskPhone('123'), '123');
    expect(
      BookingCardDisplay.guestLabel(_table(phone: '13812345678')),
      '张先生 138****5678',
    );
    expect(BookingCardDisplay.guestLabel(_table(name: '')), '');
  });

  test('remark keeps six characters and open time shows HH:mm', () {
    expect(BookingCardDisplay.shortRemark('生日布置需要气球'), '生日布置需要…');
    expect(BookingCardDisplay.shortRemark('短备注'), '短备注');
    expect(BookingCardDisplay.openTime('20261119201500'), '20:15');
    expect(BookingCardDisplay.openTime(''), '');
  });
}
