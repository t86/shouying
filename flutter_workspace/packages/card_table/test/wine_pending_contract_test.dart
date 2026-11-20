import 'package:card_table/src/wine_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi;

void main() {
  for (final save in [true, false]) {
    test(
      '${save ? 'save' : 'get'} pending uses Vue order and detail fields',
      () async {
        final adapter = Adapter()
          ..data = {
            'need_waiter_auth': 1,
            'records': [
              {
                'o': 71,
                'id': 999,
                'c': '客人',
                'p': '13800000000',
                's': 'A1',
                'e': '订位人',
                'w': '服务员',
                't': '2026/09/20 12:00:00',
                'r': '存酒备注',
                'us': '是',
                'b': 1,
                'ss': [
                  {
                    'id': 81,
                    'i': 91,
                    'n': '酒',
                    'u': '整瓶',
                    'c': 2,
                    'g': 700,
                    'e': '2026/10/20',
                    'a': '授权人',
                    'ss': 'B1',
                    's': '原订位人',
                    'w': '取酒备注',
                  },
                ],
              },
            ],
          };
        final api = ProtocolWineApi(client: makeApi(adapter).client);
        if (save) {
          final row = (await api.getSaveNeedToLib(ClientKind.wine))
              .valueOrNull!
              .single;
          expect(row.id, '71');
          expect(
            [
              row.customerName,
              row.customerPhone,
              row.seatName,
              row.salesName,
              row.waiterName,
              row.saveTime,
              row.remark,
            ],
            [
              '客人',
              '13800000000',
              'A1',
              '订位人',
              '服务员',
              '2026/09/20 12:00:00',
              '存酒备注',
            ],
          );
          final item = row.items.single;
          expect(
            [
              item.name,
              item.unit,
              item.count,
              item.gram,
              item.expireTime,
              item.auther,
            ],
            ['酒', '整瓶', 2, '700', '2026/10/20', '授权人'],
          );
          await api.confirmSaveNeedToLib(ClientKind.wine, ids: [row.id]);
        } else {
          final row = (await api.getNeedToLib(ClientKind.wine))
              .valueOrNull!
              .single;
          expect(row.id, '71');
          expect(
            [
              row.customerName,
              row.customerPhone,
              row.seatName,
              row.salesName,
              row.waiterName,
              row.getTime,
              row.superCode,
              row.isBlack,
            ],
            [
              '客人',
              '13800000000',
              'A1',
              '订位人',
              '服务员',
              '2026/09/20 12:00:00',
              '是',
              true,
            ],
          );
          final item = row.items.single;
          expect(
            [
              item.id,
              item.name,
              item.unit,
              item.count,
              item.gram,
              item.expireTime,
              item.auther,
              item.saveSeat,
              item.saveSales,
              item.remark,
            ],
            [
              '91',
              '酒',
              '整瓶',
              2,
              '700',
              '2026/10/20',
              '授权人',
              'B1',
              '原订位人',
              '取酒备注',
            ],
          );
          await api.confirmGetNeedToLib(ClientKind.wine, ids: [row.id]);
        }
        expect(adapter.requests.last.data, {
          'ids': [71],
        });
      },
    );
  }
  test('get rejection uses bef_out_ids without invented reason', () async {
    final adapter = Adapter();
    await ProtocolWineApi(client: makeApi(adapter).client).backGetNeedToLib(
      ClientKind.wine,
      ids: ['71', '72'],
      reason: 'not a Vue request field',
    );
    expect(adapter.requests.single.uri.path, '/wine/back_qj_bef_out');
    expect(adapter.requests.single.data, {
      'bef_out_ids': [71, 72],
    });
  });
}
