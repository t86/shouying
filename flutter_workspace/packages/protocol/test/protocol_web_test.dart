@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:protocol/protocol.dart';
import 'package:protocol/src/protocol_adapter_web.dart';
import 'package:protocol/src/limited_response_adapter.dart';

void main() {
  test(
    'Fetch guard rechecks after asynchronous request body collection',
    () async {
      var valid = true;
      var sends = 0;
      final adapter = FetchHttpClientAdapter(
        maxRawResponseBytes: 1024,
        client: _FakeHttpClient((request) async {
          sends++;
          return http.StreamedResponse(const Stream<List<int>>.empty(), 200);
        }),
      );
      final options = _requestOptions(method: 'POST');
      options.extra[dispatchGuardKey] = () => valid;
      final body = StreamController<Uint8List>();
      final pending = adapter.fetch(options, body.stream, null);
      final rejection = expectLater(
        pending,
        throwsA(isA<DispatchInvalidatedException>()),
      );
      valid = false;
      await body.close();
      await rejection;
      expect(sends, 0);
    },
  );
  test('production Web factory replaces Dio XHR with Fetch', () {
    final dio = Dio();
    expect(dio.httpClientAdapter, isA<BrowserHttpClientAdapter>());

    _client(dio: dio);

    expect(dio.httpClientAdapter, isA<FetchHttpClientAdapter>());
    expect(dio.httpClientAdapter, isNot(isA<BrowserHttpClientAdapter>()));
  });

  test('Fetch adapter preserves request and response metadata', () async {
    final fakeClient = _FakeHttpClient(
      (request) async => http.StreamedResponse(
        Stream<List<int>>.value(utf8.encode('{"ok":true}')),
        201,
        headers: <String, String>{
          'content-type': 'application/json',
          'x-probe': 'mapped',
        },
        reasonPhrase: 'Created',
      ),
    );
    final adapter = FetchHttpClientAdapter(
      client: fakeClient,
      maxRawResponseBytes: 1024,
    );
    final bodyBytes = Uint8List.fromList(utf8.encode('{"name":"demo"}'));
    final options = _requestOptions(method: 'POST');

    final response = await adapter.fetch(
      options,
      Stream<Uint8List>.value(bodyBytes),
      null,
    );
    final responseBytes = await response.stream
        .expand<int>((chunk) => chunk)
        .toList();

    expect(response.statusCode, 201);
    expect(response.statusMessage, 'Created');
    expect(response.headers['x-probe'], <String>['mapped']);
    expect(utf8.decode(responseBytes), '{"ok":true}');
    expect(fakeClient.calls, 1);
    final request = fakeClient.requests.single as http.AbortableRequest;
    expect(request.method, 'POST');
    expect(request.url, options.uri);
    expect(request.headers['x-probe'], 'request');
    expect(request.headers['content-type'], Headers.jsonContentType);
    expect(request.bodyBytes, bodyBytes);
    expect(fakeClient.abortSignals, 0);
  });

  test('Fetch stream aborts before buffering an oversized body', () async {
    final probe = _HttpStreamingProbe(contentLength: 4);
    final fakeClient = _FakeHttpClient(
      (request) async => http.StreamedResponse(
        probe.chunks(),
        200,
        contentLength: probe.contentLength,
        headers: <String, String>{
          'content-length': '${probe.contentLength}',
          'content-type': 'text/plain',
        },
      ),
    );
    final fetchAdapter = FetchHttpClientAdapter(
      client: fakeClient,
      maxRawResponseBytes: 12,
    );
    final dio = Dio()..httpClientAdapter = fetchAdapter;
    final protocolClient = _client(
      dio: dio,
      responseLimits: const ProtocolResponseLimits(
        maxRawResponseBytes: 12,
        maxDepth: 32,
        maxNodes: 100,
      ),
      credentialStore: _MemoryCredentialStore(
        tk: 'synthetic-web-tk',
        stk: 'synthetic-web-stk',
      ),
    );
    final installedAdapter = dio.httpClientAdapter;
    _client(
      dio: dio,
      responseLimits: const ProtocolResponseLimits(
        maxRawResponseBytes: 8,
        maxDepth: 32,
        maxNodes: 100,
      ),
    );
    expect(identical(dio.httpClientAdapter, fetchAdapter), isTrue);
    expect(identical(dio.httpClientAdapter, installedAdapter), isTrue);

    final result = await protocolClient.post(
      '/stream',
      body: <String, Object?>{'value': 'demo'},
      client: ClientKind.order,
    );
    await Future<void>.delayed(Duration.zero);

    expect(result.failureOrNull?.code, 'protocol.response_too_large');
    expect(probe.chunksProduced, 2);
    expect(probe.chunksProduced, lessThan(probe.totalChunks));
    expect(probe.finalized, isTrue);
    expect(fakeClient.abortSignals, 1);
    expect(fakeClient.calls, 1, reason: 'Fetch requests are never retried');
    final request = fakeClient.requests.single as http.AbortableRequest;
    expect(request.method, 'POST');
    expect(request.url.path, '/server/stream');
    expect(request.headers['tk'], 'synthetic-web-tk');
    expect(request.headers['stk'], 'synthetic-web-stk');
    expect(request.headers['tt'], '4');
    expect(jsonDecode(utf8.decode(request.bodyBytes)), <String, Object?>{
      'value': 'demo',
    });
  });

  test('Dio cancellation completes the Fetch abort trigger', () async {
    final fakeClient = _FakeHttpClient((request) async {
      final abortable = request as http.Abortable;
      await abortable.abortTrigger;
      throw http.RequestAbortedException(request.url);
    });
    final adapter = FetchHttpClientAdapter(
      client: fakeClient,
      maxRawResponseBytes: 1024,
    );
    final cancel = Completer<void>();

    final pending = adapter.fetch(
      _requestOptions(method: 'GET'),
      null,
      cancel.future,
    );
    await Future<void>.delayed(Duration.zero);
    cancel.complete();

    await expectLater(
      pending,
      throwsA(
        isA<DioException>().having(
          (error) => error.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    expect(fakeClient.abortSignals, 1);
    expect(fakeClient.calls, 1);
  });

  test('Fetch connection timeout aborts the pending request', () async {
    final fakeClient = _FakeHttpClient((request) async {
      final abortable = request as http.Abortable;
      await abortable.abortTrigger;
      throw http.RequestAbortedException(request.url);
    });
    final adapter = FetchHttpClientAdapter(
      client: fakeClient,
      maxRawResponseBytes: 1024,
    );
    final options = _requestOptions(method: 'GET')
      ..connectTimeout = const Duration(milliseconds: 1);

    await expectLater(
      adapter.fetch(options, null, null),
      throwsA(
        isA<DioException>().having(
          (error) => error.type,
          'type',
          DioExceptionType.connectionTimeout,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(fakeClient.abortSignals, 1);
    expect(fakeClient.calls, 1);
  });
}

ProtocolClient _client({
  required Dio dio,
  CredentialStore? credentialStore,
  ProtocolResponseLimits responseLimits = const ProtocolResponseLimits(),
}) => ProtocolClient(
  dio: dio,
  config: ApiConfig(
    apiBase: Uri.parse('https://api.example/server'),
    onlineBase: Uri.parse('https://online.example/server'),
    websocketBase: Uri.parse('wss://socket.example/events'),
  ),
  credentialStore: credentialStore ?? _MemoryCredentialStore(),
  requestGate: RequestGate(
    clock: () => DateTime.fromMillisecondsSinceEpoch(1000),
  ),
  responseLimits: responseLimits,
);

RequestOptions _requestOptions({required String method}) => RequestOptions(
  path: 'https://api.example/server/probe',
  method: method,
  headers: <String, Object?>{
    Headers.contentTypeHeader: Headers.jsonContentType,
    'x-probe': 'request',
  },
  connectTimeout: const Duration(seconds: 12),
  sendTimeout: const Duration(seconds: 12),
  receiveTimeout: const Duration(seconds: 12),
);

typedef _SendHandler = Future<http.StreamedResponse> Function(
  http.BaseRequest request,
);

final class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._send);

  final _SendHandler _send;
  final List<http.BaseRequest> requests = <http.BaseRequest>[];
  int calls = 0;
  int abortSignals = 0;
  int closeCalls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    calls += 1;
    requests.add(request);
    if (request case http.Abortable(:final abortTrigger?)) {
      unawaited(abortTrigger.then((_) => abortSignals += 1));
    }
    return _send(request);
  }

  @override
  void close() => closeCalls += 1;
}

final class _HttpStreamingProbe {
  _HttpStreamingProbe({required this.contentLength});

  final int contentLength;
  final int chunkSize = 6;
  final int totalChunks = 4;
  int chunksProduced = 0;
  bool finalized = false;

  Stream<List<int>> chunks() async* {
    try {
      for (var index = 0; index < totalChunks; index += 1) {
        chunksProduced += 1;
        yield List<int>.filled(chunkSize, 0x61 + index);
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      finalized = true;
    }
  }
}

final class _MemoryCredentialStore implements CredentialStore {
  _MemoryCredentialStore({this.tk, this.stk});

  String? tk;
  String? stk;

  @override
  Future<void> clearStk() async => stk = null;

  @override
  Future<void> clearStkIfMatches(String? expected) async {
    if (stk == expected) stk = null;
  }

  @override
  Future<void> clearTk() async => tk = null;

  @override
  Future<void> clearTkIfMatches(String? expected) async {
    if (tk == expected) tk = null;
  }

  @override
  Future<String?> readStk() async => stk;

  @override
  Future<String?> readTk() async => tk;

  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      CredentialSnapshot(tk: tk, stk: stk);

  @override
  Future<void> writeStk(String value) async => stk = value;

  @override
  Future<void> writeTk(String value) async => tk = value;
}
