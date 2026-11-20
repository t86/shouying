import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/pay_order_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi;

void main() {
  test('online unpaid groups respect expanded refunds and never bill package children twice', () async {
    Map<String, Object?> row(
      int id,
      num price,
      int count, {
      bool back = false,
    }) => {'id': id, 'pid': 9, 'pp': price, 'pc': count, 'back': back};
    final adapter = Adapter();
    adapter.onFetch = () =>
        adapter.data = adapter.requests.last.uri.path == '/wo/list'
        ? {}
        : {
            'unpay_order': {
              'oos': [
                {
                  'oid': 1,
                  'os': [row(1, 999, 1)],
                  'resultNotPayData': [
                    {
                      ...row(2, 10, 2),
                      'si': [row(3, 700, 3)],
                    },
                    row(4, 10, 1, back: true),
                  ],
                },
                {
                  'oid': 2,
                  'os': [row(5, 3, 2)],
                },
                {
                  'oid': 3,
                  'os': [row(6, 999, 1)],
                  'resultNotPayData': [],
                },
                {
                  'oid': 4,
                  'back': true,
                  'os': [row(7, 999, 1)],
                },
              ],
            },
          };
    final result = await ProtocolPayOrderApi(client: makeApi(adapter).client)
        .getCsmOrders(ClientKind.cashier, seatId: '31', turnoverCount: 2);
    expect(result.valueOrNull!.unpayAmt, 26);
  });
  test('wo/list preserves recorded prices and four summary fields including zero-count rows', () async {
    final adapter = Adapter()
      ..data = {
        'records': [
          {'id': 1, 'pid': 9, 'pp': 100, 'p2': 80, 'pa': 150, 'pc': 2, 'at': 2},
          {'id': 2, 'pid': 9, 'pp': 0, 'p2': 80, 'pa': 999, 'pc': 0},
        ],
        'pay_info': {
          'order_amt': 380000,
          'discount_amt': 120000,
          'payed_amt': 60000,
          'payed_free_amt': 1000,
          'yh_amt': 123,
        },
      };
    final result = await ProtocolOrderMealApi(
      client: makeApi(adapter).client,
    ).listOrdersWithSummary(ClientKind.order, seatId: '31', turnoverCount: 2);
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/wo/list');
    expect(adapter.requests.single.data, {'seat_id': 31, 'turnover_cnt': 2});
    final data = result.valueOrNull!;
    expect(data.summary!.notPayAmt, '3200.00');
    expect(data.summary!.allAmt, '5000.00');
    expect(data.items.first.unitPrice, '80');
    expect(data.items.first.amount, '0.0');
    expect(data.items.first.refundAmount(), 150);
    expect(data.items.last.isTimePrice, isTrue);
    expect(data.items.last.count, 0);
  });
  test(
    'cashier uses separate wo summary, not csm_orders or current item totals',
    () async {
      final adapter = Adapter();
      adapter.onFetch = () =>
          adapter.data = adapter.requests.last.uri.path == '/wo/list'
          ? {
              'pay_info': {
                'order_amt': 380000,
                'payed_amt': 60000,
                'discount_amt': 120000,
                'payed_free_amt': 1000,
                'yh_amt': 123,
              },
            }
          : {
              'pay_info': {'order_amt': 999999},
              'unpay_order': {
                'os': [
                  {'id': 1, 'pid': 9, 'pp': 100, 'p2': 80, 'pa': 150, 'pc': 2},
                ],
              },
            };
      final result = await ProtocolPayOrderApi(client: makeApi(adapter).client)
          .getCsmOrders(ClientKind.cashier, seatId: '31', turnoverCount: 2);
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.map((r) => r.uri.path), [
        '/sel/csm_orders',
        '/wo/list',
      ]);
      expect(result.valueOrNull!.summary!.notPayAmt, '3200.00');
      expect(result.valueOrNull!.unpayItems.single.price, 80);
      expect(result.valueOrNull!.unpayItems.single.subtotal, 150);
    },
  );
  test(
    'missing wo summary stays unknown and explicit zero summary stays zero',
    () async {
      final adapter = Adapter()
        ..data = {
          'records': [],
          'pay_info': {'order_amt': 0},
        };
      final orderApi = ProtocolOrderMealApi(client: makeApi(adapter).client);
      expect(
        (await orderApi.listOrdersWithSummary(
          ClientKind.order,
          seatId: '1',
          turnoverCount: 0,
        )).valueOrNull!.summary!.allAmt,
        '0.00',
      );
      adapter.data = {
        'unpay_order': {'os': []},
      };
      final result = await ProtocolPayOrderApi(client: makeApi(adapter).client)
          .getCsmOrders(ClientKind.cashier, seatId: '1', turnoverCount: 0);
      expect(result.valueOrNull!.summary, isNull);
      final missing = await ProtocolOrderMealApi(
        client: makeApi(adapter).client,
      ).listOrdersWithSummary(ClientKind.order, seatId: '1', turnoverCount: 0);
      expect(missing.valueOrNull!.summary, isNull);
    },
  );
}
