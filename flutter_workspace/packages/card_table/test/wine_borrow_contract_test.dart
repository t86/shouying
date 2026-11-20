import 'package:card_table/src/wine_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'bms_staff_contract_test.dart' show Adapter, makeApi;

void main() {
  for (final type in [1, 2]) {
    test('borrow return type $type uses Vue request and response fields', () async {
      final adapter = Adapter()..data = {
        'records': [
          {'id': 51, 'n': '测试酒', 'c': 7, 'bre': '借还人',
            'u': '2026-09-20 12:30', 'oe': '操作人', 'r': '备注', 't': type},
        ],
        'row_cnt': 1,
      };
      final api = ProtocolWineApi(client: makeApi(adapter).client);
      final result = await api.getWineBorrowReturnList(ClientKind.wine,
        page: 3, pageSize: 50, keyword: '测试', type: type);
      final row = result.valueOrNull!.single;
      expect([row.type, row.count, row.borrowerName, row.operatorName,
        row.operateTime, row.remark, row.unit],
        [type, 7, '借还人', '操作人', '2026-09-20 12:30', '备注', '']);
      final body = adapter.requests.single.data as Map;
      expect(body['page_num'], 3);
      expect(body['op_type'], type);
      expect(body['prd_id'], 0);
      expect(body['begin_day'], '');
      expect(body['end_day'], '');
      expect(body.containsKey('page'), false);
      expect(body.containsKey('type'), false);
    });
  }
}
