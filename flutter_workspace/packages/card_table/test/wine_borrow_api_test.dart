import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/wine_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

class _Store implements CredentialStore {
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      const CredentialSnapshot(tk: 'test', stk: null);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Adapter implements HttpClientAdapter {
  final calls = <RequestOptions>[];
  Object data = const <Object>[];
  int code = 1;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    return ResponseBody.fromString(
      jsonEncode({'code': code, 'data': data, 'msg': '拒绝'}),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Adapter adapter;
  late ProtocolWineApi api;
  setUp(() {
    adapter = _Adapter();
    var now = DateTime.utc(2026);
    api = ProtocolWineApi(
      client: ProtocolClient(
        dio: Dio()..httpClientAdapter = adapter,
        credentialStore: _Store(),
        requestGate: RequestGate(
          clock: () => now = now.add(const Duration(seconds: 1)),
        ),
        config: ApiConfig(
          apiBase: Uri.parse('https://example.test/server'),
          onlineBase: Uri.parse('https://online.test/server'),
          websocketBase: Uri.parse('wss://socket.test/server'),
        ),
      ),
    );
  });
  test('paged records preserve date range/page and use row_cnt, null records valid', () async {
    adapter.data = {
      'records': [
        {
          'id': 1,
          'n': '酒',
          'c': 2,
          'bre': '甲',
          'oe': '乙',
          'u': '2026-09-20',
          't': 2,
        },
      ],
      'row_cnt': 41,
    };
    final result = await api.getWineBorrowReturnPage(
      ClientKind.wine,
      type: 2,
      page: 2,
      beginDay: '2026-08-01',
      endDay: '2026-08-31',
      keyword: '备注',
    );
    expect(
      adapter.calls.last.uri.path,
      '/server/wine/get_wine_borrow_return_list',
    );
    expect(adapter.calls.last.data, {
      'page_num': 2,
      'page_size': 20,
      'begin_day': '2026-08-01',
      'end_day': '2026-08-31',
      'op_type': 2,
      'prd_id': 0,
      'key': '备注',
    });
    expect(result.valueOrNull?.total, 41);
    expect(result.valueOrNull?.items.single.borrowerName, '甲');
    adapter.data = {'records': null, 'row_cnt': 0};
    expect(
      (await api.getWineBorrowReturnPage(
        ClientKind.wine,
        type: 1,
        page: 1,
        beginDay: '2026-09-01',
        endDay: '2026-09-20',
      )).valueOrNull?.items,
      isEmpty,
    );
    adapter.data = {'records': [], 'row_cnt': 'invalid'};
    expect(
      (await api.getWineBorrowReturnPage(
        ClientKind.wine,
        type: 1,
        page: 1,
        beginDay: '2026-09-01',
        endDay: '2026-09-20',
      )).failureOrNull,
      isNotNull,
    );
  });
  test(
    'borrow employee and inventory use Vue endpoints and original fields',
    () async {
      adapter.data = [
        {'id': 7, 'n': '员工'},
      ];
      expect(
        (await api.getWineBorrowEmployees(
          ClientKind.wine,
          '张',
        )).valueOrNull!.single['id'],
        7,
      );
      expect(adapter.calls.last.uri.path, '/server/emp/upper_items');
      expect(adapter.calls.last.data, {
        'name': '张',
        'page_num': 1,
        'page_size': 50,
        'mod_emp_ids': [],
      });
      adapter.data = {
        'records': [
          {'id': 11, 'n': '酒', 'c': 3},
        ],
      };
      expect(
        (await api.getWineCanBorrowList(
          ClientKind.wine,
          keyword: 'jiu',
        )).valueOrNull!.single['c'],
        3,
      );
      expect(
        adapter.calls.last.uri.path,
        '/server/wine/get_wine_can_borrow_list',
      );
      expect(adapter.calls.last.data, {'key': 'jiu'});
      expect(
        (await api.getWineReturnOptions(
          ClientKind.wine,
          keyword: '酒',
        )).valueOrNull!.single['id'],
        11,
      );
      expect(
        adapter.calls.last.uri.path,
        '/server/wine/get_wine_borrow_invt_list',
      );
      expect(adapter.calls.last.data, {'key': '酒'});
    },
  );
  test(
    'borrow and return post exactly four aligned fields and surface failure',
    () async {
      final fields = <String, Object?>{
        'br_emp_id': 7,
        'prd_ids': [11, 12],
        'prd_cnts': [2, 3],
        'remarks': ['甲', ''],
      };
      expect(
        (await api.newWineBorrow(
          ClientKind.wine,
          fields: fields,
        )).failureOrNull,
        isNull,
      );
      expect(adapter.calls.last.uri.path, '/server/wine/new_wine_borrow');
      expect(adapter.calls.last.data, fields);
      adapter.code = 2;
      expect(
        (await api.newWineReturn(
          ClientKind.wine,
          fields: fields,
        )).failureOrNull?.safeMessage,
        '拒绝',
      );
      expect(adapter.calls.last.uri.path, '/server/wine/new_wine_return');
      expect(adapter.calls.last.data, fields);
    },
  );
  test('legacy or mismatched payloads never reach backend', () async {
    for (final fields in <Map<String, Object?>>[
      {'prd_id': 11, 'count': 1, 'borrower': '甲'},
      {
        'br_emp_id': 7,
        'prd_ids': [11, 12],
        'prd_cnts': [1],
        'remarks': ['', ''],
      },
      {
        'br_emp_id': 7,
        'prd_ids': [11],
        'prd_cnts': [0],
        'remarks': [''],
      },
    ]) {
      expect(
        (await api.newWineBorrow(
          ClientKind.wine,
          fields: fields,
        )).failureOrNull,
        isNotNull,
      );
    }
    expect(adapter.calls, isEmpty);
  });
}
