import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/pay_order_api.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/pay_order_loader.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/pay_order_screen.dart';
import 'package:flutter/material.dart';

import 'pay_order_stale_context_audit_test.dart' as seat_fixture;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' as session_fixture;

void main() {
  testWidgets(
    'batch details resolve wei ae and si dpi without inventing self service',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = _Adapter([
        {
          'code': 1,
          'data': {
            'unpay_order': {
              'os': [
                {
                  'id': 9,
                  'pid': 90,
                  'n': '套餐',
                  'pc': 2,
                  'pp': '10',
                  'pa': '20',
                  'wei': 7,
                  'ae': 8,
                  'is': 1,
                  'si': [
                    {'dpi': 101, 'sc': 2, 'dpc': 3},
                  ],
                },
                {
                  'id': 10,
                  'pid': 90,
                  'n': '缺元数据',
                  'pc': 1,
                  'pp': '10',
                  'pa': '10',
                  'wei': 999,
                  'ae': 998,
                },
                {
                  'id': 11,
                  'pid': 90,
                  'n': '自助单',
                  'pc': 1,
                  'pp': '10',
                  'pa': '10',
                  'wei': 0,
                  'ae': 0,
                },
              ],
            },
          },
        },
        {'code': 1, 'data': <String, Object?>{}},
      ]);
      final result = (await tester.runAsync(
        () => ProtocolPayOrderApi(client: _client(adapter))
            .getCsmOrders(ClientKind.cashier, seatId: '100', turnoverCount: 2),
      ))!;
      expect(
        result.valueOrNull!.unpayItems.first.packageDetails.single.count,
        12,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: seat_fixture.table(),
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            employees: () => const [
              CardEmployee(id: '7', name: '张三', deptId: '1'),
              CardEmployee(id: '8', name: '李四', deptId: '1'),
            ],
            productNameFor: (id) => id == '101' ? '套餐可选啤酒' : null,
            loadOrders: ({required seatId, required turnoverCount}) async =>
                result,
            batchUpdateOrderWaiter: ({
              required seatId,
              required orderIds,
              required waiterEmpId,
              canDispatch,
            }) async => const Success(null),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('全部消费'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('改服务员'));
      await tester.pumpAndSettle();
      expect(find.textContaining('服务员 张三'), findsOneWidget);
      expect(find.textContaining('授权人 李四'), findsOneWidget);
      expect(find.textContaining('未知员工（999）'), findsOneWidget);
      expect(find.textContaining('服务员 自助'), findsOneWidget);
      expect(find.textContaining('套餐可选啤酒 × 12'), findsOneWidget);
    },
  );
  for (final initiallyLocked in [true, false]) {
    testWidgets(
      'transfer rejects ${initiallyLocked ? 'initial' : 'fresh'} wire lock l',
      (tester) async {
        tester.view.physicalSize = const Size(1500, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var locked = initiallyLocked, writes = 0;
        final revision = ValueNotifier(0);
        addTearDown(revision.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: PayOrderScreen(
              table: seat_fixture.table(),
              tables: () => [seat_fixture.table()],
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              currentTableRevision: revision,
              loadOrders: ({required seatId, required turnoverCount}) async {
                final adapter = _Adapter([
                  {
                    'code': 1,
                    'data': {
                      'unpay_order': {
                        'os': [
                          {
                            'id': 9,
                            'pid': 101,
                            'n': '锁单商品',
                            'pc': 1,
                            'pp': '10',
                            'pa': '10',
                            'l': locked ? 2 : 0,
                          },
                        ],
                      },
                    },
                  },
                  {'code': 1, 'data': <String, Object?>{}},
                ]);
                return ProtocolPayOrderApi(client: _client(adapter))
                    .getCsmOrders(
                      ClientKind.cashier,
                      seatId: seatId,
                      turnoverCount: turnoverCount,
                    );
              },
              moveOrder:
                  ({
                    required seatId,
                    required destSeatId,
                    required orderIds,
                    counts = const [],
                    totalAmtFen,
                    canDispatch,
                  }) async {
                    writes++;
                    return const Success(null);
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('转单'));
        await tester.pumpAndSettle();
        if (initiallyLocked) {
          expect(find.text('确认转单'), findsNothing);
        } else {
          await tester.tap(find.byType(RadioListTile<String>));
          await tester.pumpAndSettle();
          locked = true;
          revision.value++;
          await tester.pumpAndSettle();
          await tester.tap(find.text('确认转单'));
          await tester.pumpAndSettle();
        }
        expect(writes, 0);
      },
    );
  }
  test(
    'batch loader cancels same-account re-login while credentials wait',
    () async {
      final sessionAdapter = session_fixture.Adapter();
      final session = SessionRepository(
        api: SessionApi(client: session_fixture.makeApi(sessionAdapter).client),
        credentialStore: session_fixture.Credentials(),
      );
      await loginSession(session, sessionAdapter, 8);
      final adapter = _Adapter([
        {'code': 1},
      ]);
      final credentials = _DelayedCredentials();
      final loader = SessionBoundPayOrderLoader(
        session: session,
        api: ProtocolPayOrderApi(
          client: _client(adapter, credentials: credentials),
        ),
        phase: () => ConnectionPhase.online,
        generation: () => 0,
      );
      final pending = loader.batchUpdateOrderWaiter(
        seatId: '100',
        orderIds: ['9'],
        waiterEmpId: '7',
      );
      await credentials.started.future;
      await loginSession(session, sessionAdapter, 8);
      credentials.snapshot.complete(
        const CredentialSnapshot(tk: 'test-tk', stk: null),
      );
      expect((await pending).failureOrNull, isNotNull);
      expect(adapter.requests, isEmpty);
    },
  );
  test(
    'batch and transfer recheck operation after delayed credentials',
    () async {
      for (final batch in [false, true]) {
        final adapter = _Adapter([
          {'code': 1},
        ]);
        final credentials = _DelayedCredentials();
        final api = ProtocolPayOrderApi(
          client: _client(adapter, credentials: credentials),
        );
        var current = true;
        final pending = batch
            ? api.batchUpdateOrderAuther(
                ClientKind.cashier,
                seatId: '100',
                orderIds: ['9'],
                authEmpId: '8',
                canDispatch: () => current,
              )
            : api.moveWkOrder(
                ClientKind.cashier,
                seatId: '100',
                destSeatId: '101',
                orderIds: ['9'],
                counts: [1],
                totalAmtFen: 100,
                canDispatch: () => current,
              );
        await credentials.started.future;
        current = false;
        credentials.snapshot.complete(
          const CredentialSnapshot(tk: 'test-tk', stk: null),
        );
        expect((await pending).failureOrNull, isNotNull);
        expect(adapter.requests, isEmpty);
      }
    },
  );
  test(
    'batch guard is checked for each order and transfer before dispatch',
    () async {
      final adapter = _Adapter([
        {'code': 1},
      ]);
      final api = ProtocolPayOrderApi(client: _client(adapter));
      final result = await api.batchUpdateOrderWaiter(
        ClientKind.cashier,
        seatId: '100',
        orderIds: ['9', '10'],
        waiterEmpId: '7',
        canDispatch: () => adapter.requests.isEmpty,
      );
      expect(result.failureOrNull, isNotNull);
      expect(adapter.requests, hasLength(1));
      final move = await api.moveWkOrder(
        ClientKind.cashier,
        seatId: '100',
        destSeatId: '101',
        orderIds: ['9'],
        counts: [1],
        totalAmtFen: 100,
        canDispatch: () => false,
      );
      expect(move.failureOrNull, isNotNull);
      expect(adapter.requests, hasLength(1));
    },
  );
  test(
    'batch business rejection continues and reports partial result truthfully',
    () async {
      final adapter = _Adapter([
        {'code': 0, 'msg': '拒绝'},
        {'code': 1},
      ]);
      final result = await ProtocolPayOrderApi(client: _client(adapter))
          .batchUpdateOrderWaiter(
            ClientKind.cashier,
            seatId: '100',
            orderIds: ['9', '10'],
            waiterEmpId: '7',
          );
      expect(adapter.requests, hasLength(2));
      expect(result.failureOrNull?.safeMessage, contains('成功1个，失败1个'));
    },
  );
  test(
    'batch waiter follows Vue one order_id request per selected order',
    () async {
      final adapter = _Adapter([
        {'code': 1},
        {'code': 1.0},
      ]);
      final result = await ProtocolPayOrderApi(client: _client(adapter))
          .batchUpdateOrderWaiter(
            ClientKind.cashier,
            seatId: '100',
            orderIds: ['9', '10'],
            waiterEmpId: '7',
          );
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.map((r) => r.data).toList(), [
        {'seat_id': 100, 'order_id': 9, 'waiter_emp_id': 7},
        {'seat_id': 100, 'order_id': 10, 'waiter_emp_id': 7},
      ]);
    },
  );
  test('batch author follows Vue individual order_id contract', () async {
    final adapter = _Adapter([
      {'code': '1'},
      {'code': 1},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter))
        .batchUpdateOrderAuther(
          ClientKind.cashier,
          seatId: '100',
          orderIds: ['9', '10'],
          authEmpId: '8',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.map((r) => r.data).toList(), [
      {'seat_id': 100, 'order_id': 9, 'auth_emp_id': 8},
      {'seat_id': 100, 'order_id': 10, 'auth_emp_id': 8},
    ]);
  });
  test(
    'tab totals use recorded net rows, not package children or live prices',
    () {
      PayOrderItem row(
        String id,
        String pp,
        String? p2,
        String pa,
        int count, {
        int at = 0,
        bool back = false,
      }) => PayOrderItem(
        id: id,
        productId: id,
        name: id,
        count: count,
        unitPrice: pp,
        recordedUnitPrice: p2,
        amount: pa,
        authorizationType: at,
        refunded: back,
        packageDetails: const [
          PayOrderPackageDetail(id: 'child', name: 'child', count: 99),
        ],
      );
      final summary = OrderSummary.fromRows([
        row('1', '100', '90', '170', 2),
        row('2', '100', '0', '', 1),
        row('3', '0', null, '75', 2),
        row('4', '0.10', null, '', 3),
        row('5', '0.20', '0.10', '', 1),
        row('6', '100', null, '0', 2, at: 2),
        row('7', '0', null, '30', 1, at: 3),
        row('8', '900', null, '800', 1, back: true),
        row('9', '100', null, '999', 0),
      ]);
      expect(summary.allAmt, '375.50');
      expect(summary.giveAmt, '230.00');
      expect(summary.discountAmt, '130.10');
      expect(summary.notPayAmt, '245.40');
    },
  );
  test('move order sends quantities and integer fen total', () async {
    final adapter = _Adapter([
      {'code': 1},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter))
        .moveWkOrder(
          ClientKind.cashier,
          seatId: '100',
          destSeatId: '101',
          orderIds: ['9'],
          counts: [2],
          totalAmtFen: 7600,
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'dest_seat_id': 101,
      'wk_order_ids': [9],
      'prd_cnts': [2],
      'total_amt': 7600,
    });
  });
  test('package detail uses the original cashier wire keys', () async {
    final adapter = _Adapter([
      {'code': 1},
    ]);
    await ProtocolPayOrderApi(client: _client(adapter)).changePackageDetail(
      ClientKind.cashier,
      seatId: '100',
      orderId: '9',
      orderDetailId: '12',
      destProductIds: ['13'],
      destCounts: [2],
    );
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'order_id': 9,
      'order_dtl_id': 12,
      'dest_dtl_prd_ids': [13],
      'dest_dtl_prd_sel_cnts': [2],
      'dest_requirements': [''],
    });
  });

  test('specialized channels cannot use generic payment path', () async {
    final adapter = _Adapter([
      {'code': 1},
    ]);
    final api = ProtocolPayOrderApi(client: _client(adapter));
    for (final id in [
      '5',
      '6',
      '10',
      '202',
      '500',
      '1000',
      '01000',
      '9999',
      '010',
      '0500',
      '06',
      ' 10 ',
      ' 1 ',
      '-1',
      '0',
      'cash',
      '1.0',
    ]) {
      final result = await api.addChannel(
        ClientKind.cashier,
        seatId: '100',
        channelId: id,
        amount: '10',
      );
      expect(result.failureOrNull, isNotNull);
    }
    expect(adapter.requests, isEmpty);
  });
  test('loads unpaid and paid orders for a seat turnover', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'waiter_emp_id': 8,
          'settle_mode': 1,
          'csm_cust_name': '张三',
          'csm_cust_phone': '13800000000',
          'unpay_order': {
            'os': [
              {
                'id': 9,
                'pid': 101,
                'pc': 2,
                'pp': '38',
                'pa': '76',
                'n': '莫吉托',
                'ot': '12:00',
                's': 0,
              },
            ],
            'oos': [
              {
                'os': [
                  {
                    'id': 10,
                    'pid': 102,
                    'pc': 1,
                    'pp': '18',
                    'pa': '18',
                    'n': '花生',
                    'ot': '12:01',
                    's': 0,
                  },
                ],
              },
            ],
          },
          'payed_order': [
            {
              'id': 3,
              'amts': {'o': 100, 'pv': 88, 'pzv': 80},
              'os': [
                {
                  'id': 11,
                  'pid': 101,
                  'pc': 1,
                  'pp': '38',
                  'pa': '38',
                  'n': '莫吉托',
                  's': 5,
                },
              ],
            },
          ],
        },
      },
    ]);
    adapter.responses.add({'code': 1, 'data': <String, Object?>{}});
    final data =
        (await ProtocolPayOrderApi(client: _client(adapter)).getCsmOrders(
          ClientKind.cashier,
          seatId: '100',
          turnoverCount: 1,
        )).valueOrNull!;
    expect(adapter.requests.first.uri.path, '/server/sel/csm_orders');
    expect(adapter.requests.first.data, {'seat_id': 100, 'turnover_cnt': 1});
    expect(adapter.requests.last.uri.path, '/server/wo/list');
    expect(data.unpayItems.map((item) => item.id).toList(), <String>[
      '9',
      '10',
    ]);
    expect(data.unpayItems.first.name, '莫吉托');
    expect(data.unpayItems.last.online, isTrue);
    expect(data.payedOrders.single.id, '3');
    expect(data.payedOrders.single.mainReceivedAmt, '80');
    expect(data.waiterEmpId, '8');
    expect(data.customerName, '张三');
  });

  test('lists settlement cart channels with seat id field', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': [
          {'id': 7, 'pid': 1, 'pa': '50.00'},
        ],
      },
    ]);
    final rows = (await ProtocolPayOrderApi(
      client: _client(adapter),
    ).listCart(ClientKind.cashier, seatId: '100')).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/sel/cart_items');
    expect(adapter.requests.single.data, {'id': 100});
    expect(rows.single.id, '7');
    expect(rows.single.channelId, '1');
    expect(rows.single.amount, '50.00');
  });

  test('adds a pay channel with yuan amount string', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter))
        .addChannel(
          ClientKind.cashier,
          seatId: '100',
          channelId: '1',
          amount: '50',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/cart_add_cnl');
    expect(adapter.requests.single.data, {
      'id': 100,
      'pay_cnl_id': 1,
      'pay_amt': '50',
      'biz_id': 0,
    });
  });

  test('pays selected unpaid lines with total amount string', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter)).payOrder(
      ClientKind.cashier,
      seatId: '100',
      orderIds: const ['9', '10'],
      counts: const [2, 1],
      totalAmount: '94',
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/pay_order');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'wk_order_ids': [9, 10],
      'prd_cnts': [2, 1],
      'total_amt': '94',
    });
  });

  test('rejects pay without selected orders before posting', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter)).payOrder(
      ClientKind.cashier,
      seatId: '100',
      orderIds: const [],
      counts: const [],
      totalAmount: '0',
    );
    expect(result.failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });

  test('adds a late deposit channel by seat id and late id', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter))
        .addLateChannel(ClientKind.cashier, seatId: '100', lateId: '8');
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/cart_add_late_cnl');
    expect(adapter.requests.single.data, {'id': 100, 'late_id': 8});
  });

  test('adds a member card channel in fen with phone auth', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter))
        .addMemberCardChannel(
          ClientKind.cashier,
          seatId: '100',
          cardId: '88',
          amountFen: 5000,
          phone: '13800000000',
          authCode: 'AUTH',
          authType: 2,
        );
    expect(result.failureOrNull, isNull);
    expect(
      adapter.requests.single.uri.path,
      '/server/sel/cart_add_mb_card_cnl',
    );
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'auth_type': 2,
      'auth_code': 'AUTH',
      'mb_card_id': 88,
      'amt': 5000,
      'phone_num': '13800000000',
    });
  });

  test('adds a booking deposit channel with auth code', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter))
        .addPrepayChannel(
          ClientKind.cashier,
          seatId: '100',
          prepayId: '3',
          amount: '20.00',
          authCode: 'AUTH',
        );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/cart_add_prepay_cnl');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'auth_code': 'AUTH',
      'prepay_id': 3,
      'amt': '20.00',
    });
  });

  test('adds wipe-zero auth channel with empty self credentials', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter))
        .addAuthChannel(ClientKind.cashier, seatId: '100', amount: '0.5');
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/cart_add_auth_cnl');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'pay_cnl_id': 10,
      'pay_amt': '0.5',
      'auth_emp_code': '',
      'auth_emp_passwd': '',
      'pass_type': 1,
    });
  });

  test('cleans a cashier seat', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter))
        .cleanSeat(ClientKind.cashier, seatId: '100');
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/seat_clean');
    expect(adapter.requests.single.data, {'seat_id': 100});
  });

  test('toggles settle mode', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolPayOrderApi(client: _client(adapter))
        .setSettleMode(ClientKind.cashier, seatId: '100', settleMode: 2);
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sel/chg_settle_mode');
    expect(adapter.requests.single.data, {'seat_id': 100, 'settle_mode': 2});
  });
}

ProtocolClient _client(_Adapter adapter, {CredentialStore? credentials}) {
  var now = DateTime.utc(2026, 9, 9);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.example.test/server'),
      onlineBase: Uri.parse('https://online.example.test/server'),
      websocketBase: Uri.parse('wss://socket.example.test/server'),
    ),
    credentialStore: credentials ?? _CredentialStore(),
    requestGate: RequestGate(
      clock: () {
        now = now.add(const Duration(milliseconds: 101));
        return now;
      },
    ),
  );
}

final class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);
  final List<Object?> responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) await requestStream.drain<void>();
    return ResponseBody.fromString(
      jsonEncode(responses.removeAt(0)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _CredentialStore implements CredentialStore {
  @override
  Future<void> clearStk() async {}
  @override
  Future<void> clearStkIfMatches(String? expected) async {}
  @override
  Future<void> clearTk() async {}
  @override
  Future<void> clearTkIfMatches(String? expected) async {}
  @override
  Future<String?> readStk() async => null;
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      const CredentialSnapshot(tk: 'test-tk', stk: null);
  @override
  Future<String?> readTk() async => 'test-tk';
  @override
  Future<void> writeStk(String value) async {}
  @override
  Future<void> writeTk(String value) async {}
}

final class _DelayedCredentials extends _CredentialStore {
  final started = Completer<void>();
  final snapshot = Completer<CredentialSnapshot>();
  @override
  Future<CredentialSnapshot> readSnapshot() {
    if (!started.isCompleted) started.complete();
    return snapshot.future;
  }
}
