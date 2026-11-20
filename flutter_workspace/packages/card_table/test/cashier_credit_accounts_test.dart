import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/cashier_credit_accounts.dart';
import 'package:dio/dio.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi, Credentials;
import 'bms_loader_guard_test.dart' show loginSession;

ProtocolCashierCreditAccountsApi _api(
  HttpClientAdapter adapter, [
  CredentialStore? credentials,
]) {
  var now = DateTime(2026);
  return ProtocolCashierCreditAccountsApi(
    client: ProtocolClient(
      dio: Dio()..httpClientAdapter = adapter,
      config: ApiConfig(
        apiBase: Uri.parse('https://api.test'),
        onlineBase: Uri.parse('https://online.test'),
        websocketBase: Uri.parse('wss://api.test'),
      ),
      credentialStore: credentials ?? Credentials(),
      requestGate: RequestGate(
        clock: () => now = now.add(const Duration(seconds: 1)),
      ),
    ),
  );
}

class _Wire implements HttpClientAdapter {
  _Wire(this.responses, {this.delay});
  final List<Object?> responses;
  final Future<void> Function(int)? delay;
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    final index = requests.length;
    requests.add(options);
    final response = responses.removeAt(0);
    if (stream != null) await stream.drain<void>();
    await delay?.call(index);
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _WaitingCredentials extends Credentials {
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<CredentialSnapshot> readSnapshot() async {
    entered.complete();
    await release.future;
    return super.readSnapshot();
  }
}

void main() {
  test('repayment posts repeated order IDs with source channel labels and integer fen', () async {
    final wire = _Wire([
      {'code': 1},
    ]);
    final result = await _api(wire).repay(
      ClientKind.cashier,
      const CashierCreditRepayment(
        accountId: '7',
        orders: [
          CashierCreditOrder(
            id: '11',
            amountFen: 3000,
            time: '',
            seat: '',
            salesName: '',
          ),
        ],
        channelAmounts: {2: '10', 1: '5'},
      ),
      canDispatch: () => true,
    );
    expect(result.failureOrNull, isNull);
    expect(wire.requests.single.uri.path, '/cnlacct/return');
    expect(wire.requests.single.data, {
      'ids': [11, 11],
      'amts': [500, 1000],
      'cnl_names': ['现金还款', '微信还款'],
    });
  });
  test(
    'invalid draft and wrong client are rejected without any account mutations',
    () async {
      final wire = _Wire([]);
      final api = _api(wire);
      expect(
        (await _api(wire).save(
          ClientKind.cashier,
          const CashierCreditAccountDraft(name: ''),
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await _api(wire).save(
          ClientKind.cashier,
          const CashierCreditAccountDraft(name: '账户', contactPhone: '123'),
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await _api(wire).delete(
          ClientKind.cashier,
          '0',
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await api.save(
          ClientKind.order,
          const CashierCreditAccountDraft(name: '账户'),
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(wire.requests, isEmpty);
    },
  );
  test('logs remain yuan while unpaid order amounts are fen', () async {
    final adapter = Adapter()
      ..data = {
        'records': [
          {'o': '时间', 't': '挂账还款', 'a': '12.34', 'c': '现金还款', 'e': '员工'},
        ],
      };
    final api = ProtocolCashierCreditAccountsApi(
      client: makeApi(adapter).client,
    );
    expect(
      (await api.logs(
        ClientKind.cashier,
        '7',
        2,
      )).valueOrNull!.single.amountYuan,
      '12.34',
    );
    expect(adapter.requests.last.data, {'id': 7, 'type_id': 2});
    adapter.data = {
      'records': [
        {'id': 11, 'a': 1234, 'c': '时间', 's': 'A01', 'sn': '订位人'},
      ],
    };
    expect(
      (await api.orders(ClientKind.cashier, '7')).valueOrNull!.single.amountFen,
      1234,
    );
    expect(adapter.requests.last.uri.path, '/cnlacct/get_orders');
  });
  test('allocation keeps order-major arrays and JS positive half rounding', () {
    const orders = [
      CashierCreditOrder(
        id: '11',
        amountFen: 1000,
        time: '',
        seat: '',
        salesName: '',
      ),
      CashierCreditOrder(
        id: '12',
        amountFen: 2000,
        time: '',
        seat: '',
        salesName: '',
      ),
    ];
    expect(
      const CashierCreditRepayment(
        accountId: '7',
        orders: orders,
        channelAmounts: {2: '10', 1: '15'},
      ).toWire(),
      {
        'ids': [11, 12, 12],
        'amts': [1000, 500, 1000],
        'cnl_names': ['现金还款', '现金还款', '微信还款'],
      },
    );
    expect(
      (const CashierCreditRepayment(
        accountId: '7',
        orders: orders,
        channelAmounts: {1: '0.335'},
      ).toWire()['amts']),
      [34],
    );
    for (final amounts in [
      {1: '31'},
      {1: '-1', 2: '2'},
      {1: 'bad'},
      <int, String>{},
      {7: '1'},
    ]) {
      expect(
        () => CashierCreditRepayment(
          accountId: '7',
          orders: orders,
          channelAmounts: amounts,
        ).toWire(),
        throwsFormatException,
      );
    }
  });
  test('acknowledgement accepts integral success only', () async {
    for (final code in [1, 1.0, '1', 2, null]) {
      final wire = _Wire([
        {'code': code, 'data': {}},
      ]);
      final result = await _api(wire).save(
        ClientKind.cashier,
        const CashierCreditAccountDraft(name: '账户'),
        canDispatch: () => true,
      );
      expect(result.failureOrNull == null, [1, 1.0, '1'].contains(code));
    }
    expect(
      (await _api(
        _Wire([
          {
            'code': 1,
            'data': {
              'records': [
                {'id': 1, 'n': '缺余额'},
              ],
            },
          },
        ]),
      ).list(ClientKind.cashier, '')).failureOrNull,
      isNotNull,
    );
  });
  test('delete rechecks balance and repayment rechecks selected order fingerprints', () async {
    final auth = Adapter(),
        session = SessionRepository(
          api: SessionApi(client: makeApi(auth).client),
          credentialStore: Credentials(),
        );
    addTearDown(session.close);
    await loginSession(session, auth, 8);
    final wire = _Wire([
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 7, 'n': '账户', 'a': '1.00'},
          ],
        },
      },
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 11, 'a': 999, 'c': '', 's': '', 'sn': ''},
          ],
        },
      },
    ]);
    final loader = SessionBoundCashierCreditAccountsLoader(
      session: session,
      api: _api(wire),
      phase: () => ConnectionPhase.online,
      generation: () => 1,
    );
    expect(
      (await loader.delete(
        const CashierCreditAccount(id: '7', name: '账户', amountYuan: '0.00'),
        () => true,
      )).failureOrNull?.code,
      'credit.account_changed',
    );
    expect(
      (await loader.repay(
        const CashierCreditRepayment(
          accountId: '7',
          orders: [
            CashierCreditOrder(
              id: '11',
              amountFen: 1000,
              time: '',
              seat: '',
              salesName: '',
            ),
          ],
          channelAmounts: {1: '1'},
        ),
        () => true,
      )).failureOrNull?.code,
      'credit.orders_changed',
    );
    expect(wire.requests.map((r) => r.uri.path), [
      '/cnlacct/list',
      '/cnlacct/get_orders',
    ]);
    expect(loader.needsVerification, false);
  });
  test(
    'lost write scope stays uncertain until explicit successful query',
    () async {
      final auth = Adapter(),
          session = SessionRepository(
            api: SessionApi(client: makeApi(auth).client),
            credentialStore: Credentials(),
          );
      addTearDown(session.close);
      await loginSession(session, auth, 8);
      final entered = Completer<void>(), release = Completer<void>();
      var epoch = 1;
      final wire = _Wire(
        [
          {'code': 1},
          {
            'code': 1,
            'data': {'records': []},
          },
          {
            'code': 1,
            'data': {'records': []},
          },
        ],
        delay: (index) async {
          if (index == 0) {
            entered.complete();
            await release.future;
          }
        },
      );
      final loader = SessionBoundCashierCreditAccountsLoader(
        session: session,
        api: _api(wire),
        phase: () => ConnectionPhase.online,
        generation: () => epoch,
      );
      final pending = loader.save(
        const CashierCreditAccountDraft(name: '账户'),
        () => true,
      );
      await entered.future;
      expect(loader.needsVerification, true);
      epoch++;
      release.complete();
      expect((await pending).failureOrNull, isNotNull);
      expect(loader.needsVerification, true);
      await loader.list('');
      expect(loader.needsVerification, true);
      expect(
        (await loader.save(
          const CashierCreditAccountDraft(name: '重复'),
          () => true,
        )).failureOrNull?.code,
        'credit.busy',
      );
      await loader.list('', verify: true);
      expect(loader.needsVerification, false);
    },
  );
  test('late credential read cannot send after page guard revoked', () async {
    final credentials = _WaitingCredentials(), wire = _Wire([]);
    var current = true;
    final pending = _api(wire, credentials).save(
      ClientKind.cashier,
      const CashierCreditAccountDraft(name: '账户'),
      canDispatch: () => current,
    );
    await credentials.entered.future;
    current = false;
    credentials.release.complete();
    expect((await pending).failureOrNull, isNotNull);
    expect(wire.requests, isEmpty);
  });
  test('credit account query and CRUD preserve source fields', () async {
    final adapter = Adapter()
      ..data = {
        'records': [
          {'id': 7, 'n': '账户', 'a': '12.34', 'cn': '联系人', 'cp': '13800000000'},
        ],
      };
    final api = ProtocolCashierCreditAccountsApi(
      client: makeApi(adapter).client,
    );
    final rows = (await api.list(ClientKind.cashier, '账户')).valueOrNull!;
    expect(rows.single.amountYuan, '12.34');
    expect(adapter.requests.last.uri.path, '/cnlacct/list');
    expect(adapter.requests.last.data, {'key': '账户'});
    adapter.data = {};
    expect(
      (await api.save(
        ClientKind.cashier,
        const CashierCreditAccountDraft(
          name: '新增',
          contactName: '张三',
          contactPhone: '13800000000',
        ),
        canDispatch: () => true,
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.last.uri.path, '/cnlacct/new');
    expect(adapter.requests.last.data, {
      'name': '新增',
      'contact_name': '张三',
      'contact_phone': '13800000000',
    });
    await api.save(
      ClientKind.cashier,
      const CashierCreditAccountDraft(id: '7', name: '改名'),
      canDispatch: () => true,
    );
    expect(adapter.requests.last.uri.path, '/cnlacct/save');
    expect((adapter.requests.last.data as Map)['id'], 7);
    await api.delete(ClientKind.cashier, '7', canDispatch: () => true);
    expect(adapter.requests.last.uri.path, '/cnlacct/del');
    expect(adapter.requests.last.data, {'id': 7});
  });
  test('repayment assigns channels in numeric order then emits order/channel aligned arrays', () {
    final repayment = CashierCreditRepayment(
      accountId: '7',
      orders: const [
        CashierCreditOrder(
          id: '11',
          amountFen: 1000,
          time: 't1',
          seat: 'A',
          salesName: '甲',
        ),
        CashierCreditOrder(
          id: '12',
          amountFen: 2000,
          time: 't2',
          seat: 'B',
          salesName: '乙',
        ),
      ],
      channelAmounts: const {2: '15', 1: '10'},
    );
    expect(repayment.toWire(), {
      'ids': [11, 12],
      'amts': [1000, 1500],
      'cnl_names': ['现金还款', '微信还款'],
    });
  });
}
