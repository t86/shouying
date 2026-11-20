import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:session/session.dart';
import 'package:card_table/src/pay_order_loader.dart';
import 'package:card_table/src/pay_order_api.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/pay_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

import 'pay_order_stale_context_audit_test.dart' as seat_fixture;
import 'bms_staff_contract_test.dart' as wire_fixture;
import 'bms_loader_guard_test.dart' show loginSession;

Map<String, Object?> payload({String amount = '12.345', int lock = 0}) => {
  'unpay_order': {
    'os': [
      {'id': 20, 'pid': 92, 'pc': 1, 'pp': 1, 'pa': 1, 'l': lock},
    ],
  },
  'payed_order': [
    {
      'id': 80,
      'amts': {'p': amount, 'pv': 8, 'pzv': 5},
      'os': [
        {'id': 9, 'pid': 90, 'n': '已结商品', 'pc': 1, 'pp': 50, 'pa': 50},
      ],
      'oos': [
        {
          'os': [
            {'id': 10, 'pid': 91, 'n': '线上商品', 'pc': 1, 'pp': 60, 'pa': 60},
          ],
        },
      ],
    },
  ],
};

Future<PayOrderData> orders() async {
  final adapter = wire_fixture.Adapter()
    ..data = {
      'payed_order': [
        {
          'id': 80,
          'amts': {'p': '12.345', 'pv': 8, 'pzv': 5},
          'os': [
            {'id': 9, 'pid': 90, 'n': '已结商品', 'pc': 1, 'pp': 50, 'pa': 50},
          ],
          'oos': [
            {
              'os': [
                {'id': 10, 'pid': 91, 'n': '线上商品', 'pc': 1, 'pp': 60, 'pa': 60},
              ],
            },
          ],
        },
      ],
    };
  return (await ProtocolPayOrderApi(
        client: wire_fixture.makeApi(adapter).client,
      ).getCsmOrders(ClientKind.cashier, seatId: '100', turnoverCount: 2))
      .valueOrNull!;
}

void main() {
  testWidgets(
    'cleared table defaults to previous turnover and excludes current empty round',
    (tester) async {
      final table = CardTable(
        id: '100',
        name: 'A01',
        regionId: '1',
        seatType: 1,
        businessType: 1,
        capacity: 4,
        displayOrder: 1,
        businessStatus: 1,
        orderAmount: 0,
        paidAmount: 0,
        customerName: '',
        customerCount: 0,
        reservationTime: '',
        openTime: '',
        remark: '',
        mark: '',
        turnoverCount: 2,
      );
      int? loaded;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: table,
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            loadOrders: ({required seatId, required turnoverCount}) async {
              loaded = turnoverCount;
              return const Success(PayOrderData(seatId: '100'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final picker = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      expect(picker.items!.map((item) => item.value).toList(), [1, 0]);
      expect(picker.value, 1);
      expect(loaded, 1);
    },
  );
  test(
    'paid transfer guard is rechecked after write credentials wait',
    () async {
      final adapter = PaidAdapter(), credentials = DelayedCredentials();
      final loader = await makeLoader(adapter, credentials: credentials);
      final record = (await loader.loadOrders(
        seatId: '100',
        turnoverCount: 2,
      )).valueOrNull!.payedOrders.single;
      credentials.deferAt = credentials.reads + 3;
      var current = true;
      final pending = move(loader, record, current: () => current);
      await credentials.started.future;
      current = false;
      credentials.pending.complete(
        const CredentialSnapshot(tk: 'test', stk: null),
      );
      expect((await pending).failureOrNull, isNotNull);
      expect(
        adapter.requests.where(
          (r) => r.uri.path.endsWith('move_payed_wk_order'),
        ),
        isEmpty,
      );
      expect(loader.paidTransfersNeedingVerification('100'), {'80'});
    },
  );
  testWidgets(
    'turnover selector uses source range and discards late old selection before historical transfer',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = (await tester.runAsync(orders))!;
      final delayed = Completer<Result<PayOrderData>>();
      final readTurns = <int>[];
      int? movedTurnover;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: seat_fixture.table(),
            tables: () => [seat_fixture.table()],
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            loadOrders: ({required seatId, required turnoverCount}) async {
              readTurns.add(turnoverCount);
              return turnoverCount == 1 ? delayed.future : Success(data);
            },
            movePayedOrder:
                ({
                  required seatId,
                  required destSeatId,
                  required payId,
                  required totalAmtFen,
                  required turnoverCount,
                  required receiptFingerprint,
                  selectedUnpaidIds = const [],
                  canDispatch,
                }) async {
                  expect(canDispatch!(), isTrue);
                  movedTurnover = turnoverCount;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<int>), findsOneWidget);
      final picker = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      expect(picker.items!.map((item) => item.value).toList(), [2, 1, 0]);
      expect(picker.value, 2);
      picker.onChanged!(1);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(readTurns, [2, 1]);
      tester
          .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
          .onChanged!(0);
      delayed.complete(
        const Success(PayOrderData(seatId: '100', customerName: '迟到旧轮次')),
      );
      await tester.pumpAndSettle();
      expect(readTurns, [2, 1, 0]);
      expect(find.textContaining('迟到旧轮次'), findsNothing);
      await tester.tap(find.text('已结支付单 80'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('整笔转单'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RadioListTile<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认整笔转单'));
      await tester.pumpAndSettle();
      expect(movedTurnover, 0);
    },
  );
  test(
    'paid transfer amount preserves JS rounding and never falls back to pv',
    () {
      expect(
        const PayedOrderRecord(
          id: '1',
          transferAmount: '-0.005',
        ).transferAmountFen,
        0,
      );
      expect(
        const PayedOrderRecord(id: '1', transferAmount: '0').transferAmountFen,
        0,
      );
      expect(
        const PayedOrderRecord(id: '1', paidAmt: '88').transferAmountFen,
        isNull,
      );
    },
  );
  testWidgets(
    'concrete receipt missing amts.p does not dispatch a made-up zero',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: seat_fixture.table(),
            tables: () => [seat_fixture.table()],
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            loadOrders: ({required seatId, required turnoverCount}) async =>
                const Success(
                  PayOrderData(
                    seatId: '100',
                    payedOrders: [PayedOrderRecord(id: '80', paidAmt: '88')],
                  ),
                ),
            movePayedOrder:
                ({
                  required seatId,
                  required destSeatId,
                  required payId,
                  required totalAmtFen,
                  required turnoverCount,
                  required receiptFingerprint,
                  selectedUnpaidIds = const [],
                  canDispatch,
                }) async {
                  calls++;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('已结支付单 80'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('整笔转单'));
      await tester.pumpAndSettle();
      expect(find.text('支付单缺少有效 amts.p 金额，请重新读取'), findsOneWidget);
      expect(find.text('确认整笔转单'), findsNothing);
      expect(calls, 0);
    },
  );
  test(
    'paid transfer fresh read and true wire use receipt p, not pv or rows',
    () async {
      final adapter = PaidAdapter();
      final loader = await makeLoader(adapter);
      final data = (await loader.loadOrders(
        seatId: '100',
        turnoverCount: 2,
      )).valueOrNull!;
      final record = data.payedOrders.single;
      final result = await move(loader, record);
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.last.uri.path, '/sel/move_payed_wk_order');
      expect(adapter.requests.last.data, {
        'seat_id': 100,
        'dest_seat_id': 101,
        'pay_id': 80,
        'total_amt': 1235,
      });
      expect(
        adapter.requests.where((r) => r.uri.path.endsWith('csm_orders')),
        hasLength(2),
      );
      expect(loader.paidTransfersNeedingVerification('100'), isEmpty);
    },
  );
  for (final change in ['amount', 'selected lock']) {
    test('paid transfer rejects fresh $change before wire dispatch', () async {
      final adapter = PaidAdapter();
      final loader = await makeLoader(adapter);
      final record = (await loader.loadOrders(
        seatId: '100',
        turnoverCount: 2,
      )).valueOrNull!.payedOrders.single;
      adapter.data = payload(
        amount: change == 'amount' ? '90' : '12.345',
        lock: change == 'selected lock' ? 1 : 0,
      );
      final result = await move(loader, record, selected: ['20']);
      expect(result.failureOrNull?.code, 'pay_order.paid_transfer_changed');
      expect(
        adapter.requests.where(
          (r) => r.uri.path.endsWith('move_payed_wk_order'),
        ),
        isEmpty,
      );
    });
  }
  test('pending or unknown paid transfer survives reopen and reads until explicit valid verification', () async {
    final adapter = PaidAdapter();
    final loader = await makeLoader(adapter);
    final record = (await loader.loadOrders(
      seatId: '100',
      turnoverCount: 2,
    )).valueOrNull!.payedOrders.single;
    adapter.pending = Completer<ResponseBody>();
    var current = true;
    final operation = move(loader, record, current: () => current);
    await adapter.writeStarted.future;
    expect((await move(loader, record)).failureOrNull, isNotNull);
    current = false;
    adapter.pending!.complete(response({'code': 1}));
    expect((await operation).failureOrNull, isNotNull);
    current = true;
    await loader.loadOrders(seatId: '100', turnoverCount: 2);
    expect(loader.paidTransfersNeedingVerification('100'), {'80'});
    final wrongTurn = await loader.verifyPaidTransfer(
      seatId: '100',
      payId: '80',
      turnoverCount: 1,
      canDispatch: () => true,
    );
    expect(wrongTurn.failureOrNull, isNotNull);
    expect(loader.paidTransfersNeedingVerification('100'), {'80'});
    expect((await move(loader, record)).failureOrNull, isNotNull);
    await loader.verifyPaidTransfer(
      seatId: '100',
      payId: '80',
      turnoverCount: 2,
      canDispatch: () => false,
    );
    expect(loader.paidTransfersNeedingVerification('100'), {'80'});
    expect(
      (await loader.verifyPaidTransfer(
        seatId: '100',
        payId: '80',
        turnoverCount: 2,
        canDispatch: () => true,
      )).failureOrNull,
      isNull,
    );
    expect(loader.paidTransfersNeedingVerification('100'), isEmpty);
    expect(
      adapter.requests.where((r) => r.uri.path.endsWith('move_payed_wk_order')),
      hasLength(1),
    );
  });
  testWidgets(
    'paid receipt transfer uses amts.p and does not filter online receipt rows',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = (await tester.runAsync(orders))!;
      int? amount;
      String? payment;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: seat_fixture.table(),
            tables: () => [seat_fixture.table()],
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            loadOrders: ({required seatId, required turnoverCount}) async =>
                Success(data),
            movePayedOrder:
                ({
                  required seatId,
                  required destSeatId,
                  required payId,
                  required totalAmtFen,
                  required turnoverCount,
                  required receiptFingerprint,
                  selectedUnpaidIds = const [],
                  canDispatch,
                }) async {
                  payment = payId;
                  amount = totalAmtFen;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('整笔转单'), findsNothing);
      await tester.tap(find.text('全部消费'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('整笔转单'));
      await tester.pumpAndSettle();
      expect(find.text('请选择具体已结支付单后再整笔转单'), findsOneWidget);
      expect(payment, isNull);
      await tester.tap(find.text('已结支付单 80'));
      await tester.pumpAndSettle();
      expect(find.text('整笔转单'), findsOneWidget);
      await tester.tap(find.text('整笔转单'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(RadioListTile<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认整笔转单'));
      await tester.pumpAndSettle();
      expect(payment, '80');
      expect(amount, 1235);
      expect(find.text('整笔转单'), findsNothing);
    },
  );
}

Future<Result<void>> move(
  SessionBoundPayOrderLoader loader,
  PayedOrderRecord record, {
  bool Function()? current,
  List<String> selected = const [],
}) => loader.movePayedOrder(
  seatId: '100',
  destSeatId: '101',
  payId: record.id,
  totalAmtFen: record.transferAmountFen!,
  turnoverCount: 2,
  receiptFingerprint: record.transferFingerprint,
  selectedUnpaidIds: selected,
  canDispatch: current ?? () => true,
);

Future<SessionBoundPayOrderLoader> makeLoader(
  PaidAdapter adapter, {
  CredentialStore? credentials,
}) async {
  final sessionAdapter = wire_fixture.Adapter();
  final session = SessionRepository(
    api: SessionApi(client: wire_fixture.makeApi(sessionAdapter).client),
    credentialStore: wire_fixture.Credentials(),
  );
  await loginSession(session, sessionAdapter, 8);
  var clock = DateTime(2026);
  final client = ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://example.test'),
      onlineBase: Uri.parse('https://example.test'),
      websocketBase: Uri.parse('wss://example.test'),
    ),
    credentialStore: credentials ?? wire_fixture.Credentials(),
    requestGate: RequestGate(
      clock: () => clock = clock.add(const Duration(seconds: 1)),
    ),
  );
  return SessionBoundPayOrderLoader(
    session: session,
    api: ProtocolPayOrderApi(client: client),
    phase: () => ConnectionPhase.online,
    generation: () => 0,
  );
}

ResponseBody response(Object body) => ResponseBody.fromString(
  jsonEncode(body),
  200,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

class PaidAdapter extends wire_fixture.Adapter {
  PaidAdapter() {
    data = payload();
  }
  Completer<ResponseBody>? pending;
  final writeStarted = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    if (body != null) await body.drain<void>();
    if (options.uri.path.endsWith('move_payed_wk_order')) {
      if (!writeStarted.isCompleted) writeStarted.complete();
      return pending?.future ?? response({'code': 1});
    }
    return response({
      'code': 1,
      'data': options.uri.path.endsWith('csm_orders')
          ? data
          : <String, Object?>{},
    });
  }
}

class DelayedCredentials extends wire_fixture.Credentials {
  int reads = 0, deferAt = -1;
  final started = Completer<void>();
  final pending = Completer<CredentialSnapshot>();
  @override
  Future<CredentialSnapshot> readSnapshot() {
    if (++reads == deferAt) {
      started.complete();
      return pending.future;
    }
    return super.readSnapshot();
  }
}
