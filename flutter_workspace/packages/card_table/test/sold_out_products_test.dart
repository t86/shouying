import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/sold_out_products.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('lists sold-out items with the order POST and no body', () async {
    final adapter = _Adapter([
      _successItems([
        {'id': '11', 'n': '莫吉托', 'c': 3, 'require': '少冰'},
      ]),
    ]);
    final rows = (await ProtocolSoldOutProductsApi(
      client: _client(adapter),
    ).list(ClientKind.order)).valueOrNull!;

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.uri.path, '/server/sel/get_prd_sold_outs');
    expect(adapter.requests.single.uri.query, isEmpty);
    expect(adapter.requests.single.data, isNull);
    expect(adapter.requests.single.headers['tt'], '4');
    expect(rows.single.id, '11');
    expect(rows.single.name, '莫吉托');
    expect(rows.single.remaining, '3');
    expect(rows.single.require, '少冰');
    expect(rows.single.toString(), isNot(contains('莫吉托')));
    expect(() => rows.clear(), throwsUnsupportedError);
  });

  test('null items become an empty sold-out list', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'items': null},
      },
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolSoldOutProductsApi(client: _client(adapter));
    expect((await api.list(ClientKind.order)).valueOrNull, isEmpty);
    expect((await api.list(ClientKind.order)).valueOrNull, isEmpty);
  });

  test('sets remaining count with prd_id and cnt only', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    expect(
      (await ProtocolSoldOutProductsApi(
        client: _client(adapter),
      ).set(ClientKind.order, productId: '11', count: 0)).failureOrNull,
      isNull,
    );
    expect(adapter.requests.single.uri.path, '/server/sel/set_prd_sold_out');
    expect(adapter.requests.single.data, {'prd_id': 11, 'cnt': 0});
  });

  test('deletes with prd_id only', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    expect(
      (await ProtocolSoldOutProductsApi(
        client: _client(adapter),
      ).delete(ClientKind.order, productId: '11')).failureOrNull,
      isNull,
    );
    expect(adapter.requests.single.uri.path, '/server/sel/del_prd_sold_out');
    expect(adapter.requests.single.data, {'prd_id': 11});
  });

  test(
    'rejects malformed list payloads without echoing server values',
    () async {
      for (final items in <Object?>[
        'private response',
        [
          {'n': true},
        ],
        List.filled(10001, <String, Object?>{'id': '1', 'n': 'x', 'c': 1}),
      ]) {
        final failure = (await ProtocolSoldOutProductsApi(
          client: _client(_Adapter([_successItems(items)])),
        ).list(ClientKind.order)).failureOrNull!;
        expect(failure.kind, FailureKind.protocol);
        expect(failure.safeMessage, isNot(contains('private response')));
      }
    },
  );

  test('business rejection stays typed and safe', () async {
    final failure = (await ProtocolSoldOutProductsApi(
      client: _client(
        _Adapter([
          {'code': 2, 'msg': 'private response'},
        ]),
      ),
    ).list(ClientKind.order)).failureOrNull!;
    expect(failure.kind, FailureKind.business);
    expect(failure.safeMessage, isNot(contains('private response')));
  });
}

Map<String, Object?> _successItems(Object? items) => {
  'code': 1,
  'data': {'items': items},
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
