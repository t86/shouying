import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/vip_recharge.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('searches cards with the order keyword POST', () async {
    final adapter = _Adapter([
      _ok({
        'records': [
          {'id': '88', 'n': '张三 138****1234'},
        ],
      }),
    ]);
    final rows = (await ProtocolVipRechargeApi(
      client: _client(adapter),
    ).search(ClientKind.order, keyword: '1234')).valueOrNull!;
    expect(adapter.requests.single.method, 'POST');
    expect(
      adapter.requests.single.uri.path,
      '/server/sel/get_cust_card_list_for_dept',
    );
    expect(adapter.requests.single.data, {'key': '1234'});
    expect(rows.single.id, '88');
    expect(rows.single.label, '张三 138****1234');
    expect(rows.single.toString(), isNot(contains('张三')));
  });

  test('search treats a non-success envelope as no hits', () async {
    final rows = (await ProtocolVipRechargeApi(
      client: _client(
        _Adapter([
          {'code': 2, 'msg': 'private-permission', 'data': <String, Object?>{}},
        ]),
      ),
    ).search(ClientKind.order, keyword: '5863')).valueOrNull;
    expect(rows, isEmpty);
  });

  test('search treats null records as no hits', () async {
    final rows = (await ProtocolVipRechargeApi(
      client: _client(_Adapter([_ok({'records': null})])),
    ).search(ClientKind.order, keyword: '5863')).valueOrNull;
    expect(rows, isEmpty);
  });

  test('loads member detail and deposit rules in fen', () async {
    final adapter = _Adapter([
      _ok({
        'mb_card': {
          'id': '88',
          'card_no': 'C001',
          'name': '张三',
          'bind_phone': '13800138000',
          'val_bal': '10.00',
          'free_bal': '2.00',
          'bal': '12.00',
          'sales_emp_id': '9',
        },
      }),
      _ok({
        'records': [
          {'d': 10000, 'f': 2000, 'fp': 10, 'fkn': '券A', 'fk': 3},
        ],
      }),
    ]);
    final api = ProtocolVipRechargeApi(client: _client(adapter));
    final member = (await api.detail(
      ClientKind.order,
      cardId: '88',
    )).valueOrNull!;
    final rules = (await api.rules(
      ClientKind.order,
      cardId: '88',
    )).valueOrNull!;
    expect(
      adapter.requests[0].uri.path,
      '/server/mb/card/get_mb_card_f_deposit',
    );
    expect(adapter.requests[0].data, {'id': 88});
    expect(
      adapter.requests[1].uri.path,
      '/server/sel/get_deposit_rules_for_dept',
    );
    expect(adapter.requests[1].data, {'id': 88});
    expect(member.cardNo, 'C001');
    expect(member.name, '张三');
    expect(member.bindPhone, '13800138000');
    expect(member.storedBalance, '10.00');
    expect(rules.single.displayPrice, '100.00');
    expect(rules.single.giftAmount, 20.0);
    expect(rules.single.giftPoints, 10);
    expect(rules.single.giftCoupon, '券A');
  });

  test('creates a pad recharge order then pay order', () async {
    final adapter = _Adapter([
      _ok({'order_id': 'o1', 'pay_id': 'p1'}),
      _ok({'scan_url': 'https://pay.example/qr', 'pay_rst': 0}),
    ]);
    final api = ProtocolVipRechargeApi(client: _client(adapter));
    final order = (await api.createOrder(
      ClientKind.order,
      body: const {
        'mode': 1,
        'id': 88,
        'deposit_amt': 10000,
        'free_amt': 2000,
        'free_pt_amt': 10,
        'free_kq_id': 3,
        'sales_emp_id': 9,
        'remark': '备注',
      },
    )).valueOrNull!;
    final pay = (await api.createPay(
      ClientKind.order,
      payId: order.payId,
      payAmtFen: 10000,
      payType: 1,
    )).valueOrNull!;
    expect(adapter.requests[0].uri.path, '/server/wo/new_cust_dept_order');
    expect(adapter.requests[1].uri.path, '/server/wo/new_cust_dept_order_pay');
    expect(adapter.requests[1].data, {
      'pay_id': 'p1',
      'pay_amt': 10000,
      'pay_type': 1,
      'auth_code': '',
    });
    expect(order.orderId, 'o1');
    expect(pay.scanUrl, 'https://pay.example/qr');
  });

  test('loads last sales recommender and polls order pay status', () async {
    final adapter = _Adapter([
      _ok({'id': '9', 'name': '李四'}),
      _ok({'pay_rst': 1}),
    ]);
    final api = ProtocolVipRechargeApi(client: _client(adapter));
    final last = (await api.lastSales(
      ClientKind.order,
      cardId: '88',
    )).valueOrNull!;
    final status = (await api.orderStatus(
      ClientKind.order,
      orderId: 'o1',
    )).valueOrNull!;
    expect(
      adapter.requests[0].uri.path,
      '/server/wo/get_cust_card_last_sales',
    );
    expect(adapter.requests[0].data, {'card_id': 88});
    expect(last.id, '9');
    expect(last.name, '李四');
    expect(
      adapter.requests[1].uri.path,
      '/server/wo/get_cust_dept_order_status',
    );
    expect(adapter.requests[1].data, {'order_id': 'o1'});
    expect(status.payResult, 1);
  });

  test('treats last sales without an id as empty', () async {
    final last = (await ProtocolVipRechargeApi(
      client: _client(_Adapter([_ok(<String, Object?>{})])),
    ).lastSales(ClientKind.order, cardId: '88')).valueOrNull;
    expect(last, isNull);
  });

  test('last sales treats a non-success envelope as empty', () async {
    final result = await ProtocolVipRechargeApi(
      client: _client(
        _Adapter([
          {'code': 2, 'msg': 'private-permission', 'data': <String, Object?>{}},
        ]),
      ),
    ).lastSales(ClientKind.order, cardId: '88');
    expect(result.failureOrNull, isNull);
    expect(result.valueOrNull, isNull);
  });

  test('rejects private server bodies', () async {
    final failure = (await ProtocolVipRechargeApi(
      client: _client(
        _Adapter([
          {'code': 2, 'msg': 'private response'},
        ]),
      ),
    ).detail(ClientKind.order, cardId: '88')).failureOrNull!;
    expect(failure.kind, FailureKind.business);
    expect(failure.safeMessage, isNot(contains('private response')));
  });
}

Map<String, Object?> _ok(Map<String, Object?> data) => {
  'code': 1,
  'data': data,
};

ProtocolClient _client(_Adapter adapter) {
  var now = DateTime.utc(2026, 9, 8);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.example.test/server'),
      onlineBase: Uri.parse('https://online.example.test/server'),
      websocketBase: Uri.parse('wss://socket.example.test/server'),
    ),
    credentialStore: _CredentialStore(),
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

final class _CredentialStore implements CredentialStore {
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
