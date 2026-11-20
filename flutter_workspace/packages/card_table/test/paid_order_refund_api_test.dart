import 'package:card_table/src/pay_order_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi;

void main() {
  test(
    'paid receipt retains original ps channel amounts and receipt payment time',
    () async {
      final adapter = Adapter();
      adapter.onFetch = () =>
          adapter.data = adapter.requests.last.uri.path == '/wo/list'
          ? {}
          : {
              'payed_order': [
                {
                  'id': 71,
                  'pt': '2026-09-20 20:00',
                  'ps': [
                    {
                      'pc': 500,
                      'cn': '会员卡',
                      'c': 'CARD1',
                      'pa': '80.25',
                      'pv': '70.00',
                      'pf': '10.25',
                    },
                    {'pc': 1, 'cn': '现金', 'pa': '10', 'pv': '', 'pf': ''},
                  ],
                  'os': [],
                },
              ],
            };
      final data =
          (await ProtocolPayOrderApi(client: makeApi(adapter).client)
                  .getCsmOrders(
                    ClientKind.cashier,
                    seatId: '100',
                    turnoverCount: 2,
                  ))
              .valueOrNull!;
      final channel = data.payedOrders.single.channels.first;
      expect(channel.channelName, '会员卡');
      expect(channel.channelId, '500');
      expect(channel.amount, 80.25);
      expect(channel.cardStoredAmt, 70);
      expect(channel.cardDiscountAmt, 10.25);
      expect(channel.payTime, '2026-09-20 20:00');
      expect(data.payedOrders.single.channels.last.amount, 10);
    },
  );
  test('noncashier cannot submit paid refunds', () async {
    final adapter = Adapter();
    final api = ProtocolPayOrderApi(client: makeApi(adapter).client);
    for (final kind in ClientKind.values.where(
      (kind) => kind != ClientKind.cashier,
    )) {
      expect(
        (await api.refundPayed(
          kind,
          seatId: '100',
          payId: '71',
          orderIds: ['11'],
          counts: [1],
          amounts: ['80'],
          remark: '理由',
        )).failureOrNull,
        isNotNull,
      );
    }
    expect(adapter.requests, isEmpty);
  });
  test('paid os and online os keep actual pay id without charging group or package children', () async {
    final adapter = Adapter();
    adapter.onFetch = () =>
        adapter.data = adapter.requests.last.uri.path == '/wo/list'
        ? {}
        : {
            'payed_order': [
              {
                'id': 71,
                'os': [
                  {'id': 11, 'pid': 9, 'pc': 3, 'pp': 100, 'p2': 80, 'pa': 210},
                ],
                'oos': [
                  {
                    'oid': 999,
                    'id': 333,
                    'pc': 100,
                    'pa': 999,
                    'os': [
                      {
                        'id': 12,
                        'pid': 8,
                        'pc': 2,
                        'pp': 50,
                        'pa': 100,
                        'is': 1,
                        'si': [
                          {'id': 55, 'dpi': 77, 'pc': 10, 'pa': 900},
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          };
    final data =
        (await ProtocolPayOrderApi(
              client: makeApi(adapter).client,
            ).getCsmOrders(ClientKind.cashier, seatId: '100', turnoverCount: 2))
            .valueOrNull!;
    final record = data.payedOrders.single;
    expect(record.id, '71');
    expect(record.items.map((item) => item.id), ['11', '12']);
    expect(
      record.items.every((item) => item.paid && item.paidOrderId == '71'),
      isTrue,
    );
    expect(record.items.last.online, isTrue);
  });
  test(
    'paid refund sends exactly the six source fields and no unpaid auth fields',
    () async {
      final adapter = Adapter();
      final result = await ProtocolPayOrderApi(client: makeApi(adapter).client)
          .refundPayed(
            ClientKind.cashier,
            seatId: '100',
            payId: '71',
            orderIds: ['11', '12'],
            counts: [1, 2],
            amounts: ['80', '0'],
            remark: '客人退单',
          );
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.single.uri.path, '/sel/pay_order_back');
      expect(adapter.requests.single.data, {
        'seat_id': 100,
        'pay_id': 71,
        'remark': '客人退单',
        'wk_order_ids': [11, 12],
        'prd_back_cnts': [1, 2],
        'prd_back_amts': ['80', '0'],
      });
    },
  );
  test('paid code2 is ordinary refusal, not success or unpaid authorization escalation', () async {
    final adapter = Adapter()
      ..code = 2
      ..msg = 'private-body';
    final result = await ProtocolPayOrderApi(client: makeApi(adapter).client)
        .refundPayed(
          ClientKind.cashier,
          seatId: '100',
          payId: '71',
          orderIds: ['11'],
          counts: [1],
          amounts: ['80'],
          remark: '理由',
        );
    expect(result.failureOrNull, isNotNull);
    expect(
      result.failureOrNull!.code,
      isNot('order_refund.authorization_required'),
    );
  });
  test('invalid or mixed paid refund arrays cannot send a request', () async {
    final adapter = Adapter();
    final api = ProtocolPayOrderApi(client: makeApi(adapter).client);
    for (final input in <(List<String>, List<int>, List<String>)>[
      ([], [], []),
      (['11'], [], ['1']),
      (['11'], [1], []),
      (['11', '011'], [1, 1], ['1', '1']),
      (['x'], [1], ['1']),
      (['11'], [0], ['1']),
      (['11'], [1], ['NaN']),
      (['11'], [1], ['-1']),
    ]) {
      expect(
        (await api.refundPayed(
          ClientKind.cashier,
          seatId: '100',
          payId: '71',
          orderIds: input.$1,
          counts: input.$2,
          amounts: input.$3,
          remark: '理由',
        )).failureOrNull,
        isNotNull,
      );
    }
    expect(adapter.requests, isEmpty);
  });
}
