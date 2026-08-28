import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/card_table.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('uses the legacy booking business-day start contract', () async {
    final adapter = _StubAdapter(<Map<String, Object?>>[
      <String, Object?>{'code': 1},
      <String, Object?>{'code': 2, 'msg': 'rejected'},
      <String, Object?>{'code': true},
    ]);
    final api = ProtocolBusinessDayApi(client: _client(adapter));

    expect((await api.open(ClientKind.booking)).failureOrNull, isNull);
    expect(
      (await api.open(ClientKind.booking)).failureOrNull?.code,
      'business.business_day_rejected',
    );
    expect(
      (await api.open(ClientKind.booking)).failureOrNull?.code,
      'protocol.business_day_shape',
    );
    expect(
      adapter.requests.map((request) => request.uri.path),
      everyElement('/server/wkd/start'),
    );
    expect(adapter.requests, everyElement(isA<RequestOptions>()));
  });
}

ProtocolClient _client(HttpClientAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  var now = DateTime.utc(2026, 8, 28);
  return ProtocolClient(
    dio: dio,
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

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.responses);

  final List<Map<String, Object?>> responses;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) await requestStream.drain<void>();
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(responses.removeAt(0)),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
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
