import 'package:card_table/src/pay_order_api.dart';
import 'package:card_table/src/pay_order_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

void main() {
  test(
    'reopen sends empty remark and three empty arrays separately from refund',
    () async {
      final adapter = Adapter();
      final api = ProtocolPayOrderApi(client: makeApi(adapter).client);
      expect(
        (await api.reopenPaidPayment(
          ClientKind.cashier,
          seatId: '100',
          payId: '71',
        )).failureOrNull,
        isNull,
      );
      expect(adapter.requests.single.uri.path, '/sel/pay_order_back');
      expect(adapter.requests.single.data, {
        'seat_id': 100,
        'pay_id': 71,
        'remark': '',
        'wk_order_ids': [],
        'prd_back_cnts': [],
        'prd_back_amts': [],
      });
      expect(
        (await api.refundPayed(
          ClientKind.cashier,
          seatId: '100',
          payId: '71',
          orderIds: [],
          counts: [],
          amounts: [],
          remark: '',
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, hasLength(1));
    },
  );
  test('begin preserves yuan strings and exact aligned arrays including zero total', () async {
    final adapter = Adapter();
    final api = ProtocolPayOrderApi(client: makeApi(adapter).client);
    for (final amount in ['80.25', '0']) {
      expect(
        (await api.beginPaymentProcess(
          ClientKind.cashier,
          seatId: '100',
          orderIds: ['11', '12'],
          counts: [2, 1],
          totalAmount: amount,
        )).failureOrNull,
        isNull,
      );
      expect(adapter.requests.last.uri.path, '/sel/cart_begin_process');
      expect(adapter.requests.last.data, {
        'seat_id': 100,
        'wk_order_ids': [11, 12],
        'prd_cnts': [2, 1],
        'total_amt': amount,
      });
    }
  });
  test(
    'both mutations reject noncashier and invalid ids without HTTP',
    () async {
      final adapter = Adapter();
      final api = ProtocolPayOrderApi(client: makeApi(adapter).client);
      for (final kind in ClientKind.values.where(
        (kind) => kind != ClientKind.cashier,
      )) {
        expect(
          (await api.reopenPaidPayment(
            kind,
            seatId: '100',
            payId: '71',
          )).failureOrNull,
          isNotNull,
        );
        expect(
          (await api.beginPaymentProcess(
            kind,
            seatId: '100',
            orderIds: ['11'],
            counts: [1],
            totalAmount: '1',
          )).failureOrNull,
          isNotNull,
        );
      }
      for (final id in ['', 'x', '0', '-1', '9007199254740992']) {
        expect(
          (await api.reopenPaidPayment(
            ClientKind.cashier,
            seatId: id,
            payId: '71',
          )).failureOrNull,
          isNotNull,
        );
        expect(
          (await api.reopenPaidPayment(
            ClientKind.cashier,
            seatId: '100',
            payId: id,
          )).failureOrNull,
          isNotNull,
        );
        expect(
          (await api.beginPaymentProcess(
            ClientKind.cashier,
            seatId: id,
            orderIds: ['11'],
            counts: [1],
            totalAmount: '1',
          )).failureOrNull,
          isNotNull,
        );
      }
      for (final input in <(List<String>, List<int>, String)>[
        ([], [], '1'),
        (['11'], [], '1'),
        (['11', '011'], [1, 1], '1'),
        (['x'], [1], '1'),
        (['11'], [-1], '1'),
        (['11'], [9007199254740992], '1'),
        (['11'], [1], '-1'),
        (['11'], [1], 'NaN'),
        (['11'], [1], 'Infinity'),
        (['11'], [1], ''),
      ]) {
        expect(
          (await api.beginPaymentProcess(
            ClientKind.cashier,
            seatId: '100',
            orderIds: input.$1,
            counts: input.$2,
            totalAmount: input.$3,
          )).failureOrNull,
          isNotNull,
        );
      }
      expect(adapter.requests, isEmpty);
    },
  );
  test(
    'begin permits source full-refund parent rows with count zero',
    () async {
      final adapter = Adapter();
      final api = ProtocolPayOrderApi(client: makeApi(adapter).client);
      expect(
        (await api.beginPaymentProcess(
          ClientKind.cashier,
          seatId: '100',
          orderIds: ['11'],
          counts: [0],
          totalAmount: '0',
        )).failureOrNull,
        isNull,
      );
      expect((adapter.requests.single.data as Map)['prd_cnts'], [0]);
    },
  );
  test(
    'code2 and ordinary failures are not successful reopen or begin',
    () async {
      final adapter = Adapter();
      final api = ProtocolPayOrderApi(client: makeApi(adapter).client);
      for (final code in [0, 2, 3]) {
        adapter.code = code;
        expect(
          (await api.reopenPaidPayment(
            ClientKind.cashier,
            seatId: '100',
            payId: '71',
          )).failureOrNull,
          isNotNull,
        );
        expect(
          (await api.beginPaymentProcess(
            ClientKind.cashier,
            seatId: '100',
            orderIds: ['11'],
            counts: [1],
            totalAmount: '1',
          )).failureOrNull,
          isNotNull,
        );
      }
    },
  );
  test('loader guards both mutations before and after forwarding', () async {
    final adapter = Adapter(), sessionAdapter = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(sessionAdapter).client),
      credentialStore: Credentials(),
    );
    var phase = ConnectionPhase.blocked, epoch = 1;
    final loader = SessionBoundPayOrderLoader(
      session: session,
      api: ProtocolPayOrderApi(client: makeApi(adapter).client),
      phase: () => phase,
      generation: () => epoch,
    );
    final actions = <Future<Result<void>> Function()>[
      () => loader.reopenPaidPayment(seatId: '100', payId: '71'),
      () => loader.beginPaymentProcess(
        seatId: '100',
        orderIds: ['11'],
        counts: [2],
        totalAmount: '80.25',
      ),
    ];
    for (final action in actions) {
      expect((await action()).failureOrNull, isNotNull);
    }
    await loginSession(session, sessionAdapter, 8);
    for (final action in actions) {
      expect((await action()).failureOrNull, isNotNull);
    }
    expect(adapter.requests, isEmpty);
    phase = ConnectionPhase.online;
    for (final action in actions) {
      expect((await action()).failureOrNull, isNull);
    }
    expect((adapter.requests.last.data as Map)['total_amt'], '80.25');
    adapter.onFetch = () => epoch++;
    for (final action in actions) {
      expect(
        (await action()).failureOrNull?.code,
        'authentication.pay_order_context_changed',
      );
    }
  });
}
