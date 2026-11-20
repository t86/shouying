import 'package:card_table/card_table.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WineModels Tests', () {
    test('WineSaveSubItem parses from wire map', () {
      final item = WineSaveSubItem.fromWire({
        'prd_name': '轩尼诗VSOP',
        'unit_name': '瓶',
        'c': 2,
        'g': '700ml',
      });
      expect(item.name, '轩尼诗VSOP');
      expect(item.count, 2);
      expect(item.unit, '瓶');
      expect(item.gram, '700ml');
    });

    test('WineSaveRecord parses nested sub products', () {
      final record = WineSaveRecord.fromWire({
        'id': 'rec-1',
        'customer_name': '张三',
        'customer_phone': '13800000000',
        'seat_name': 'V01',
        'sales_name': '营销A',
        'waiter_name': '服务员B',
        'time': '2026-09-15 10:00:00',
        'remark': '生日存酒',
        'ss': [
          {'prd_name': '黑方', 'c': 1, 'unit_name': '瓶'},
        ],
      });
      expect(record.id, 'rec-1');
      expect(record.customerName, '张三');
      expect(record.customerPhone, '13800000000');
      expect(record.items.length, 1);
      expect(record.items.first.name, '黑方');
    });

    test('WineGridItem supports id, productName, and partials aliases', () {
      final grid = WineGridItem.fromWire({
        'prd_id': 'prd-99',
        'prd_name': '马爹利蓝带',
        'whole_bottle': '10',
        'p1': '3',
      });
      expect(grid.id, 'prd-99');
      expect(grid.productName, '马爹利蓝带');
      expect(grid.wholeBottle, '10');
      expect(grid.partials['0.1'], '3');
    });

    test('WineCustomerItem supports isSmsOpen alias', () {
      final cust = WineCustomerItem.fromWire({
        'id': 'c-1',
        'name': '李四',
        'phone': '13900001111',
        'enable_sms': 1,
      });
      expect(cust.id, 'c-1');
      expect(cust.name, '李四');
      expect(cust.isSmsOpen, isTrue);
      expect(cust.enableSms, isTrue);
    });

    test('WineBorrowReturnItem supports borrower, orderNo and operator aliases', () {
      final item = WineBorrowReturnItem.fromWire({
        'id': 'b-1',
        'order_no': 'BR-20260915-01',
        'borrower': '王五',
        'operator': '操作员C',
        'wine_name': '野格',
        'count': 2,
        'op_time': '2026-09-15 12:00:00',
        'type': 1,
      });
      expect(item.id, 'b-1');
      expect(item.orderNo, 'BR-20260915-01');
      expect(item.borrowerName, '王五');
      expect(item.operatorName, '操作员C');
      expect(item.wineName, '野格');
      expect(item.count, 2);
    });

    test('WineReportRow dynamically reads fields with defaults', () {
      const row = WineReportRow(data: {'prdName': '百威啤酒', 'total': 24});
      expect(row.get('prdName'), '百威啤酒');
      expect(row.get('total'), '24');
      expect(row.get('non_existent', '默认值'), '默认值');
    });
  });
}
