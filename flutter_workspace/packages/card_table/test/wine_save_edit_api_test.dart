import 'package:card_table/src/wine_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi;

void main() {
  test(
    'source seat queries preserve linked/free shapes and exclude blocked seats',
    () async {
      final adapter = Adapter()
        ..data = {
          'regions': [
            {
              'id': 1,
              'ss': [
                {'id': 91, 'n': 'A1', 'b': 1},
                {'id': 92, 'n': '不可选', 'b': 2},
              ],
            },
          ],
        };
      final api = ProtocolWineApi(client: makeApi(adapter).client);
      expect(
        (await api.getSaveEditSeats(
          ClientKind.wine,
          day: '2026-09-20',
        )).valueOrNull!.single['id'],
        91,
      );
      expect(adapter.requests.last.uri.path, '/wo/get_relate_seat_items');
      expect(adapter.requests.last.data, {'biz_day': '2026-09-20'});
      adapter.data = {
        'regions': [
          {'id': 1},
        ],
        'seats': [
          {'id': 93, 's': '自由台', 'r': 1},
        ],
      };
      expect(
        (await api.getSaveEditSeats(ClientKind.wine)).valueOrNull!.single['n'],
        '自由台',
      );
      expect(adapter.requests.last.uri.path, '/wine/get_kf_seat_items');
      expect(adapter.requests.last.data, {});
      adapter.data = {
        'records': [
          {'id': 81, 's': '订位人'},
        ],
      };
      expect(
        (await api.getSaveEditOrders(
          ClientKind.wine,
          '2026-09-20',
          91,
        )).valueOrNull!.single['id'],
        81,
      );
      expect(adapter.requests.last.uri.path, '/wo/get_relate_seat_csm_items');
      expect(adapter.requests.last.data, {
        'biz_day': '2026-09-20',
        'seat_id': 91,
      });
    },
  );
  test('legacy partial save body must not reach backend', () async {
    final adapter = Adapter();
    final result = await ProtocolWineApi(
      client: makeApi(adapter).client,
    ).chgSaveNeedToLib(ClientKind.wine, fields: {'id': 71, 'remark': '旧假合同'});
    expect(result.failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });
}
