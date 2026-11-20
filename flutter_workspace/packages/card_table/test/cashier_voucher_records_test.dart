import 'package:card_table/src/cashier_voucher_records.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:dio/dio.dart';

import 'dart:typed_data';
import 'dart:convert';

import 'package:session/session.dart';
import 'package:foundation/foundation.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi, Credentials;
import 'bms_loader_guard_test.dart' show loginSession;

void main() {
  test('load and cancel accept integral double code; export preserves actual endpoint and selected filters', () async {
    final adapter = _VoucherAdapter({
      'code': 1.0,
      'data': {'records': []},
    });
    final api = ProtocolCashierVoucherApi(client: _client(adapter));
    expect(
      (await api.load(
        ClientKind.cashier,
        const CashierVoucherQuery(),
      )).failureOrNull,
      isNull,
    );
    expect(
      (await api.cancel(
        ClientKind.cashier,
        '7',
        canDispatch: () => true,
      )).failureOrNull,
      isNull,
    );
    adapter.binary = true;
    final file = await api.export(
      ClientKind.cashier,
      const CashierVoucherQuery(typeId: 32, keyword: 'xyz'),
    );
    expect(file.failureOrNull, isNull);
    expect(file.valueOrNull!.bytes, [80, 75, 3, 4]);
    expect(adapter.requests.last.uri.path, '/sel/rpt/exp_kq_csm_list_for_back');
    expect(adapter.requests.last.data, {'type_id': 32, 'key': 'xyz'});
  });
  test('session generation changed during header preparation sends no cancellation', () async {
    final login = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(login).client),
      credentialStore: Credentials(),
    );
    await loginSession(session, login, 8);
    final adapter = _VoucherAdapter({'code': 1});
    var epoch = 1;
    final loader = SessionBoundCashierVoucherLoader(
      session: session,
      api: ProtocolCashierVoucherApi(client: _client(adapter)),
      phase: () => ConnectionPhase.online,
      generation: () => epoch,
    );
    final pending = loader.cancel('7', () => true);
    epoch++;
    expect((await pending).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
    expect(
      (await loader.export(
        const CashierVoucherQuery(),
        () => false,
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests, isEmpty);
  });
  test(
    'fractional business code and malformed records never succeed',
    () async {
      for (final response in [
        {
          'code': 1.5,
          'data': {'records': []},
        },
        {
          'code': 1,
          'data': {
            'records': [
              {'id': 7, 'a': 'bad', 'a2': 0},
            ],
          },
        },
        {
          'code': 1,
          'data': {
            'records': [false],
          },
        },
      ]) {
        expect(
          (await ProtocolCashierVoucherApi(
                client: _client(_VoucherAdapter(response)),
              ).load(ClientKind.cashier, const CashierVoucherQuery()))
              .failureOrNull,
          isNotNull,
        );
      }
    },
  );
  test(
    'actual refundable report maps all fields and strict refund eligibility',
    () async {
      final adapter = Adapter()
        ..data = {
          'records': [
            {
              'id': 7,
              'b': 1,
              't': 12,
              'a': 12345,
              'a2': -100,
              'o': '操作员',
              'k': '券ID',
              'l': '券名',
              'c': '券码',
              'p': '套餐',
              'os': '已下单',
              's': '已核销',
              'g': '领取',
              'sn': 'A01',
              'ot': '开台',
              'se': '订位',
              'uc': 2,
              'um': '使用',
              'vt': '核销',
              'ct': '退券',
              'ce': '退券人',
            },
            {'id': 8, 'b': '1', 't': 22, 'a': 0, 'a2': 0},
          ],
        };
      final rows =
          (await ProtocolCashierVoucherApi(client: makeApi(adapter).client)
                  .load(
                    ClientKind.cashier,
                    const CashierVoucherQuery(typeId: 12, keyword: 'abc'),
                  ))
              .valueOrNull!;
      expect(
        adapter.requests.single.uri.path,
        '/sel/rpt/get_kq_csm_list_for_back',
      );
      expect(adapter.requests.single.data, {'type_id': 12, 'key': 'abc'});
      expect(rows.first.canCancel, true);
      expect(rows.last.canCancel, false);
      expect(rows.first.cells['卡券类型'], '抖音券');
      expect(rows.first.cells['卡券金额'], '123.45');
      expect(rows.first.cells['当台二消金额'], '-1.00');
      expect(rows.first.cells.length, 19);
    },
  );
  test(
    'cancel posts actual order id and business rejection remains failure',
    () async {
      final adapter = Adapter()..code = 2;
      final result = await ProtocolCashierVoucherApi(
        client: makeApi(adapter).client,
      ).cancel(ClientKind.cashier, '7', canDispatch: () => true);
      expect(result.failureOrNull, isNotNull);
      expect(adapter.requests.single.uri.path, '/sel/cancel_kq_csm');
      expect(adapter.requests.single.data, {'kq_order_id': 7});
    },
  );
  test('invalid IDs filters and noncashier contexts send nothing', () async {
    final adapter = Adapter();
    final api = ProtocolCashierVoucherApi(client: makeApi(adapter).client);
    expect(
      (await api.load(
        ClientKind.order,
        const CashierVoucherQuery(),
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await api.load(
        ClientKind.cashier,
        const CashierVoucherQuery(typeId: 1),
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await api.cancel(
        ClientKind.cashier,
        '0',
        canDispatch: () => true,
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests, isEmpty);
  });
}

ProtocolClient _client(_VoucherAdapter adapter) {
  var tick = DateTime(2026);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.test'),
      onlineBase: Uri.parse('https://online.test'),
      websocketBase: Uri.parse('wss://api.test'),
    ),
    credentialStore: Credentials(),
    requestGate: RequestGate(
      clock: () => tick = tick.add(const Duration(milliseconds: 2)),
    ),
  );
}

class _VoucherAdapter implements HttpClientAdapter {
  _VoucherAdapter(this.payload);
  final Map<String, Object?> payload;
  final requests = <RequestOptions>[];
  bool binary = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    if (stream != null) await stream.drain<void>();
    return binary
        ? ResponseBody.fromBytes([80, 75, 3, 4], 200)
        : ResponseBody.fromString(jsonEncode(payload), 200);
  }

  @override
  void close({bool force = false}) {}
}
