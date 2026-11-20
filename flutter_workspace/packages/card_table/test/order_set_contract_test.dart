import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/order_set_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';
import 'package:foundation/foundation.dart';
import 'package:dio/dio.dart';
import 'package:card_table/src/order_meal_loader.dart';

import 'bms_loader_guard_test.dart' show loginSession;

import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

void main() {
  test('add set loader preserves aligned requirement strings', () async {
    final adapter = Adapter(), sessionAdapter = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(sessionAdapter).client),
      credentialStore: Credentials(),
    );
    await loginSession(session, sessionAdapter, 4);
    final loader = SessionBoundOrderMealLoader(
      session: session,
      api: ProtocolOrderMealApi(client: makeApi(adapter).client),
      phase: () => ConnectionPhase.online,
      generation: () => 1,
    );
    final result = await loader.addSet(
      seatId: '100',
      productId: '50',
      count: 1,
      priceFen: 100,
      groupIds: ['2', '2'],
      detailProductIds: ['501', '501'],
      detailCounts: [1, 1],
      selectCounts: [1, 1],
      requirements: ['冷', '热'],
    );
    expect(result.failureOrNull, isNull);
    expect((adapter.requests.single.data as Map)['requirements'], ['冷', '热']);
  });
  test('unexpanded template cannot be submitted as a real product', () {
    for (final resolved in [false, true]) {
      final detail = OrderSetDetail(
        productId: '50',
        groupId: '2',
        detailProductId: '502',
        detailCount: 1,
        groupSelectCount: 1,
        name: '模板',
        typeId: '2',
        templateResolved: resolved,
      );
      final draft = OrderSetSelection(
        productId: '50',
        candidates: [detail],
        choices: [OrderSetChoice(detail: detail, selectCount: 1)],
      );
      expect(draft.validate(), resolved ? isNull : isNotNull);
    }
  });
  test(
    'set authorization loader preserves credentials and generation protection',
    () async {
      final adapter = Adapter(), sessionAdapter = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(sessionAdapter).client),
        credentialStore: Credentials(),
      );
      var epoch = 1;
      final loader = SessionBoundOrderMealLoader(
        session: session,
        api: ProtocolOrderMealApi(client: makeApi(adapter).client),
        phase: () => ConnectionPhase.online,
        generation: () => epoch,
      );
      Future<Result<void>> send() => loader.changeOrderedSet(
        seatId: '100',
        orderId: '301',
        orderDetailId: '9001',
        destDetailProductIds: ['502'],
        destSelectCounts: [1],
        destRequirements: [''],
        authEmpCode: 'staff',
        authEmpPasswd: 'abc',
        passType: 2,
      );
      expect((await send()).failureOrNull, isNotNull);
      expect(adapter.requests, isEmpty);
      await loginSession(session, sessionAdapter, 4);
      expect((await send()).failureOrNull, isNull);
      expect(
        (adapter.requests.last.data as Map)['auth_emp_passwd'],
        '900150983CD24FB0D6963F7D28E17F72',
      );
      adapter.onFetch = () => epoch++;
      expect((await send()).failureOrNull, isNotNull);
    },
  );
  test(
    'invalid set arrays cannot send HTTP or silently discard requirements',
    () async {
      final adapter = Adapter();
      final api = ProtocolOrderMealApi(client: makeApi(adapter).client);
      expect(
        (await api.addSet(
          ClientKind.order,
          seatId: '100',
          productId: '50',
          count: 1,
          priceFen: 100,
          groupIds: ['2'],
          detailProductIds: ['502'],
          detailCounts: [0],
          selectCounts: [1],
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await api.addSet(
          ClientKind.order,
          seatId: '100',
          productId: '50',
          count: 1,
          priceFen: 100,
          groupIds: ['2'],
          detailProductIds: ['502'],
          detailCounts: [1],
          selectCounts: [1],
          requirements: ['a', 'b'],
        )).failureOrNull,
        isNotNull,
      );
      for (final counts in <List<int>>[
        [],
        [0],
        [-1],
      ]) {
        expect(
          (await api.changeOrderedSet(
            ClientKind.order,
            seatId: '100',
            orderId: '301',
            orderDetailId: '9001',
            destDetailProductIds: ['502'],
            destSelectCounts: counts,
            destRequirements: [''],
          )).failureOrNull,
          isNotNull,
        );
      }
      expect(adapter.requests, isEmpty);
    },
  );
  test(
    'compact package children preserve distinct cart and order identities',
    () async {
      final adapter = Adapter();
      final api = ProtocolOrderMealApi(client: makeApi(adapter).client);
      final child = {'id': 9001, 'gid': 2, 'i': 501, 'c': 3, 's': 2, 'r': '少冰'};
      adapter.data = {
        'records': [
          {
            'id': 301,
            'pid': 50,
            'pc': 2,
            'is': 1,
            'si': [child],
          },
        ],
      };
      final cart = (await api.listItems(
        ClientKind.cashier,
        seatId: '100',
      )).valueOrNull!.single;
      expect(cart.isSet, isTrue);
      expect(cart.setEditable, isTrue);
      expect(cart.setItems.single.detailProductId, '501');
      expect(cart.setItems.single.groupId, '2');
      expect(cart.setItems.single.detailCount, 3);
      expect(cart.setItems.single.selectCount, 2);
      expect(cart.setItems.single.requirement, '少冰');
      final order = (await api.listOrders(
        ClientKind.cashier,
        seatId: '100',
        turnoverCount: 1,
      )).valueOrNull!.single;
      expect(order.setItems.single.id, '9001');
      expect(order.setEditable, isTrue);
      adapter.data = {
        'records': [
          {
            'id': 301,
            'pid': 50,
            'pc': 2,
            'is': 1,
            'si': [
              {'id': 9002, 'gid': 2, 'dpi': 502, 'dpc': 1, 'sc': 3, 'r': ''},
            ],
          },
        ],
      };
      final alternate = (await api.listOrders(
        ClientKind.cashier,
        seatId: '100',
        turnoverCount: 1,
      )).valueOrNull!.single;
      expect(alternate.setItems.single.id, '9002');
      expect(alternate.setItems.single.detailProductId, '502');
      expect(alternate.setItems.single.selectCount, 3);
    },
  );
  test('returned clones and missing child order id cannot be edited', () async {
    final adapter = Adapter();
    final api = ProtocolOrderMealApi(client: makeApi(adapter).client);
    adapter.data = {
      'records': [
        {
          'id': 301,
          'pid': 50,
          'pc': 2,
          'is': 1,
          'si': [
            {'id': 9001, 'gid': 2, 'i': 501, 'c': 1, 's': 1},
          ],
          'bs': [
            {'id': 302, 'pc': 1},
          ],
        },
      ],
    };
    final orders = (await api.listOrders(
      ClientKind.cashier,
      seatId: '100',
      turnoverCount: 1,
    )).valueOrNull!;
    expect(orders, hasLength(2));
    expect(orders.first.setEditable, isTrue);
    expect(orders.last.refunded, isTrue);
    expect(orders.last.setEditable, isFalse);
    adapter.data = {
      'records': [
        {
          'id': 301,
          'pid': 50,
          'pc': 2,
          'is': 1,
          'si': [
            {'gid': 2, 'i': 501, 'c': 1, 's': 1},
          ],
        },
      ],
    };
    final missing = (await api.listOrders(
      ClientKind.cashier,
      seatId: '100',
      turnoverCount: 1,
    )).valueOrNull!.single;
    expect(missing.setItems.single.id, '');
    expect(missing.setEditable, isFalse);
  });
  test('cart replacement preserves old scalar id and repeated targets with different requirements', () async {
    final adapter = Adapter();
    final api = ProtocolOrderMealApi(client: makeApi(adapter).client);
    expect(
      (await api.changeSetDetail(
        ClientKind.cashier,
        seatId: '100',
        itemId: '201',
        groupId: '2',
        detailProductId: '501',
        destDetailProductIds: ['502', '502'],
        destSelectCounts: [1, 1],
        requirement: '少冰',
        destRequirements: ['冷', '热'],
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'id': 201,
      'grp_ids': 2,
      'dtl_prd_ids': 501,
      'dest_dtl_prd_ids': [502, 502],
      'dest_sel_cnts': [1, 1],
      'requirement': '少冰',
      'dest_requirements': ['冷', '热'],
    });
  });
  test('ordered replacement separates cashier endpoint from password or card authorization', () async {
    final adapter = Adapter();
    var tick = DateTime.utc(2026, 9, 22);
    final api = ProtocolOrderMealApi(client: ProtocolClient(
      dio: Dio()..httpClientAdapter = adapter,
      config: ApiConfig(apiBase: Uri.parse('https://example.test'), onlineBase: Uri.parse('https://example.test'), websocketBase: Uri.parse('wss://example.test')),
      credentialStore: Credentials(),
      // This is an authorization contract test, not a same-millisecond throttle test.
      requestGate: RequestGate(clock: () => tick = tick.add(const Duration(milliseconds: 2))),
    ));
    for (final kind in [ClientKind.cashier, ClientKind.order]) {
      final result = await api.changeOrderedSet(
        kind,
        seatId: '100',
        orderId: '301',
        orderDetailId: '9001',
        destDetailProductIds: ['502'],
        destSelectCounts: [2],
        destRequirements: ['热'],
        authEmpCode: 'staff',
        authEmpPasswd: 'abc',
        passType: 2,
      );
      expect(result.failureOrNull, isNull);
      final body = adapter.requests.last.data as Map;
      expect(body['order_dtl_id'], 9001);
      expect(
        adapter.requests.last.uri.path,
        kind == ClientKind.cashier ? '/sel/chg_prd_set_dtl' : '/wo/set_chg',
      );
      if (kind == ClientKind.cashier) {
        expect(body.containsKey('auth_emp_code'), isFalse);
        expect(body.containsKey('pass_type'), isFalse);
      } else {
        expect(body['auth_emp_passwd'], '900150983CD24FB0D6963F7D28E17F72');
        expect(body['pass_type'], 2);
      }
    }
    adapter.code = 2;
    expect(
      (await api.changeOrderedSet(
        ClientKind.order,
        seatId: '100',
        orderId: '301',
        orderDetailId: '9001',
        destDetailProductIds: ['502'],
        destSelectCounts: [1],
        destRequirements: [''],
      )).failureOrNull?.code,
      orderSetAuthorizationRequiredCode,
    );
    expect(
      (await api.changeOrderedSet(
        ClientKind.cashier,
        seatId: '100',
        orderId: '301',
        orderDetailId: '9001',
        destDetailProductIds: ['502'],
        destSelectCounts: [1],
        destRequirements: [''],
      )).failureOrNull?.code,
      isNot(orderSetAuthorizationRequiredCode),
    );
  });
  test('selection requires exact fixed and optional group counts without merging requirements', () {
    const fixed = OrderSetDetail(
      productId: '50',
      groupId: '1',
      detailProductId: '500',
      detailCount: 1,
      groupSelectCount: 0,
      name: '固定',
    );
    const option = OrderSetDetail(
      productId: '50',
      groupId: '2',
      detailProductId: '502',
      detailCount: 3,
      groupSelectCount: 2,
      name: '可选',
    );
    const a = OrderSetChoice(detail: fixed, selectCount: 1);
    const b = OrderSetChoice(detail: option, selectCount: 1, requirement: '冷');
    const c = OrderSetChoice(detail: option, selectCount: 1, requirement: '热');
    final valid = OrderSetSelection(
      productId: '50',
      candidates: [fixed, option],
      choices: [a, b, c],
    );
    expect(valid.validate(), isNull);
    expect(valid.detailProductIds, ['500', '502', '502']);
    expect(valid.requirements, ['', '冷', '热']);
    expect(
      OrderSetSelection(
        productId: '50',
        candidates: [fixed, option],
        choices: [a, b],
      ).validate(),
      isNotNull,
    );
    expect(
      OrderSetSelection(
        productId: '50',
        candidates: [fixed, option],
        choices: [b, c],
      ).validate(),
      isNotNull,
    );
    expect(
      OrderSetSelection(
        productId: '50',
        candidates: [fixed, option],
        choices: [b],
        replacing: const OrderSetItem(
          groupId: '2',
          detailProductId: '501',
          detailCount: 1,
          selectCount: 1,
        ),
      ).validate(),
      isNull,
    );
  });
}
