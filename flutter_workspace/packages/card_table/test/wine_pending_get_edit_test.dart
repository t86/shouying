import 'package:card_table/src/wine_api.dart';
import 'package:card_table/src/wine_pending_get.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi;

void main() {
  test('pending originals never infer inventory id or coerce missing or fractional counts', () async {
    final adapter = Adapter();
    for (final item in <Object?>[
      {'id': 999, 'c': 2},
      {'i': 91},
      {'i': 91, 'c': 'bad'},
      {'i': 91, 'c': 1.5},
      {'i': 91, 'c': -1},
      'bad',
    ]) {
      adapter.data = {
        'need_waiter_auth': 1,
        'records': [
          {
            'o': 71,
            'ss': [item],
          },
        ],
      };
      expect(
        (await ProtocolWineApi(client: makeApi(adapter).client).getPendingGetContext(ClientKind.wine)).failureOrNull?.code,
        'protocol.wine_shape',
      );
    }
    adapter.data = {
      'need_waiter_auth': 1,
      'records': [
        {
          'o': 71,
          'ss': [
            {'id': 999, 'i': 91, 'c': '2'},
          ],
        },
      ],
    };
      final valid = await ProtocolWineApi(client: makeApi(adapter).client).getPendingGetContext(ClientKind.wine);
      expect(valid.failureOrNull, isNull);
      final record = valid.valueOrNull!.records.single;
    expect(record.id, '71');
    expect(record.items.single.id, '91');
    expect(record.items.single.count, 2);
  });
  test(
    'pending context preserves authorization setting and inventory contract',
    () async {
      final adapter = Adapter()..data = {'need_waiter_auth': 2, 'records': []};
      final api = ProtocolWineApi(client: makeApi(adapter).client);
      expect(
        (await ProtocolWineApi(client: makeApi(adapter).client).getPendingGetContext(ClientKind.wine))
            .valueOrNull!
            .needsAuthorization,
        false,
      );
      adapter.data = {'records': []};
      expect(
        (await ProtocolWineApi(client: makeApi(adapter).client).getPendingGetContext(ClientKind.wine))
            .valueOrNull!
            .needsAuthorization,
        isNull,
      );
      adapter.data = {
        'records': [
          {'id': 92, 'i': '2026/09/20', 'n': '酒', 'u': '整瓶', 'g': 700, 'c': 3},
        ],
      };
      final rows = (await api.getPendingGetInventory(
        ClientKind.wine,
        phone: '138',
      )).valueOrNull!;
      expect(rows.single.id, '92');
      expect(rows.single.count, 3);
      expect(adapter.requests.last.uri.path, '/wine/get_qj_invt');
      expect(adapter.requests.last.data, {'phone_num': '138', 'key': ''});
    },
  );
  test('authorization body pairs real inventory ids with counts and hashes both modes', () {
    for (final mode in [1, 2]) {
      expect(
        winePendingGetBody(
          orderId: '71',
          counts: {'91': 2, '92': 3},
          needsAuthorization: true,
          account: 'employee',
          secret: 'abc',
          passType: mode,
        ),
        {
          'bef_out_id': 71,
          'invt_ids': [91, 92],
          'prd_cnts': [2, 3],
          'auth_emp_code': 'employee',
          'auth_emp_passwd': '900150983CD24FB0D6963F7D28E17F72',
          'pass_type': mode,
        },
      );
    }
    expect(
      winePendingGetBody(
        orderId: '71',
        counts: {'91': 1},
        needsAuthorization: false,
      )['auth_emp_passwd'],
      '',
    );
    expect(
      () => winePendingGetBody(
        orderId: '71',
        counts: {'91': 0},
        needsAuthorization: false,
      ),
      throwsArgumentError,
    );
    expect(
      () => winePendingGetBody(
        orderId: '71',
        counts: {'91': 1},
        needsAuthorization: null,
      ),
      throwsArgumentError,
    );
  });
}
