import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/wine_order.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('lists save-wine consumption rows for a seat', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'cust_in_need_sms': 1,
          'records': [
            {'id': 7, 'p': '13800000000', 'mp': '138****0000', 'n': '张三'},
          ],
        },
      },
    ]);
    final rows = (await ProtocolWineOrderApi(client: _client(adapter)).listCsms(
      ClientKind.order,
      seatId: '100',
    )).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/wine/get_csms_f_cj');
    expect(adapter.requests.single.data, {'seat_id': 100});
    expect(rows.single.id, '7');
    expect(rows.single.phone, '13800000000');
    expect(rows.single.name, '张三');
    expect(rows.single.needSms, isTrue);
  });

  test('adds a non-auth save-wine cart line', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolWineOrderApi(client: _client(adapter)).addCart(
      ClientKind.order,
      csmId: '7',
      productId: '101',
      unitTypes: const ['1'],
      counts: const [1],
      grams: const [0],
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wine/add_sc_csm_cj_prd');
    expect(adapter.requests.single.data, {
      'csm_id': 7,
      'prd_id': 101,
      'unit_types': ['1'],
      'prd_cnts': [1],
      'g_cnts': [0],
    });
  });

  test('submits a two-step save-wine order', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolWineOrderApi(client: _client(adapter)).submitSave(
      ClientKind.order,
      cartIds: const ['3'],
      phone: '13800000000',
      name: '张三',
      authCode: '1234',
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wine/new_cj_bef_in');
    expect(adapter.requests.single.data, {
      'sc_ids': [3],
      'phone_num_auth_code': '1234',
      'phone_num': '13800000000',
      'cust_name': '张三',
      'remark_cust_phone': '',
      'remark_cust_name': '-',
      'remark': '',
    });
  });

  test('takes wine out of inventory', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolWineOrderApi(client: _client(adapter)).submitTake(
      ClientKind.order,
      seatId: '100',
      inventoryIds: const ['5'],
      counts: const [1],
      phone: '13800000000',
      authCode: '1234',
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wine/new_qj_bef_out');
    expect(adapter.requests.single.data, {
      'seat_id': 100,
      'invt_ids': [5],
      'prd_cnts': [1],
      'phone_num_auth_code': '1234',
      'phone_num': '13800000000',
    });
  });

  test('confiscates leftover wine', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolWineOrderApi(
      client: _client(adapter),
    ).submitConfiscate(
      ClientKind.order,
      seatId: '100',
      date: '2026-09-14',
      salesEmpId: '8',
      productIds: const ['101'],
      unitTypes: const ['1'],
      counts: const [1],
      grams: const [0],
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/wine/new_csm_cg_bef_in');
    expect(adapter.requests.single.data, {
      'cg_day': '2026-09-14',
      'sales_emp_id': 8,
      'seat_id': 100,
      'prd_ids': [101],
      'unit_types': ['1'],
      'prd_cnts': [1],
      'g_cnts': [0],
    });
  });
}

ProtocolClient _client(_Adapter adapter) {
  var now = DateTime.utc(2026, 9, 9);
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
