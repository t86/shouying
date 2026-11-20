import 'package:card_table/src/erp_api.dart';
import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi;

void main() {
  test(
    'legacy id-only partial reversal never sends an invented body',
    () async {
      final a = Adapter();
      final result = await ProtocolErpApi(client: makeApi(a).client)
          .redPunchSoutOrder('1');
      expect(result.failureOrNull, isNotNull);
      expect(a.requests, isEmpty);
    },
  );
  test('other-out list uses source fields and preserves row count', () async {
    final a = Adapter()
      ..data = {
        'datas': [
          {
            'id': 1,
            'cd': 'OUT1',
            'rt': '报损出库',
            'sn': '仓库',
            'ta': '20.00',
            'sa': '30.00',
            'r': '备注',
            'st': '2026-09-21',
            'en': '员工',
          },
        ],
        'row_cnt': 41,
      };
    final page =
        (await ProtocolErpApi(client: makeApi(a).client).getOtherOutPage(
          beginDay: '2026-09-01',
          endDay: '2026-09-21',
          recordType: 62,
          remark: '备注',
          page: 2,
        )).valueOrNull!;
    expect(a.requests.single.data, {
      'begin_day': '2026-09-01',
      'end_day': '2026-09-21',
      'record_type': 62,
      'remark': '备注',
      'page_num': 2,
      'page_size': 20,
    });
    expect(page.total, 41);
    expect(page.rows.single['rt'], '报损出库');
  });
  test(
    'copy read and partial versus whole reversal have distinct contracts',
    () async {
      final a = Adapter()
        ..data = {
          'store_id': 3,
          'record_type': 17,
          'remark': '源',
          'stores': [
            {'id': 3, 'n': '仓库'},
          ],
          'dtls': [
            {'id': 8, 'n': '物料', 'un': '瓶', 'ic': 10, 'c': 2, 'sa': 5},
          ],
        };
      final api = ProtocolErpApi(client: makeApi(a).client);
      final copy = (await api.getOtherOutDocument(
        '1',
        ErpSoutDocumentMode.copy,
      )).valueOrNull!;
      expect(copy.data['store_id'], 3);
      expect(a.requests.last.uri.path, '/sout/get_f_copy');
      expect(a.requests.last.data, {'id': 1});
      await api.reverseOtherOutWhole('1');
      expect(a.requests.last.uri.path, '/sout/cs');
      expect(a.requests.last.data, {'id': 1});
      await api.reverseOtherOutLines({8: 1.5});
      expect(a.requests.last.uri.path, '/sout/hc');
      expect(a.requests.last.data, {
        'dtl_ids': [8],
        'cnts': [1.5],
      });
    },
  );
}
