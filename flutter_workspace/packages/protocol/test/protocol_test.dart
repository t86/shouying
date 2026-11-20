import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

void main() {
  test(
    'no-body write guard rejects changed scope after awaited credentials',
    () async {
      var valid = true, sent = 0;
      final entered = Completer<void>(), release = Completer<void>();
      final store = _MemoryCredentialStore()
        ..beforeSnapshot = () async {
          entered.complete();
          await release.future;
        };
      final dio = Dio()
        ..httpClientAdapter = _StubAdapter((options) {
          sent++;
          expect(options.data, isNull);
          return ResponseBody.fromString('{"code":1}', 200);
        });
      final pending = _client(dio: dio, credentialStore: store).postWithoutBody(
        '/sel/cancel_wkday_cnl_switch',
        client: ClientKind.cashier,
        canDispatch: () => valid,
      );
      await entered.future;
      valid = false;
      release.complete();
      expect((await pending).failureOrNull, isNotNull);
      expect(sent, 0);
    },
  );
  for (final during in ['credentials', 'interceptor']) {
    test(
      'dispatch guard blocks changes during $during before transport',
      () async {
        var valid = true;
        var sent = 0;
        final release = Completer<void>();
        final entered = Completer<void>();
        final store = _MemoryCredentialStore();
        if (during == 'credentials') {
          store.beforeSnapshot = () async {
            entered.complete();
            await release.future;
          };
        }
        final dio = Dio()
          ..httpClientAdapter = _StubAdapter((_) {
            sent++;
            return ResponseBody.fromString('{"code":1}', 200);
          });
        if (during == 'interceptor') {
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) async {
                entered.complete();
                await release.future;
                handler.next(options);
              },
            ),
          );
        }
        final pending = _client(dio: dio, credentialStore: store).post(
          '/wkd/close',
          client: ClientKind.cashier,
          canDispatch: () => valid,
        );
        await entered.future;
        valid = false;
        release.complete();
        expect((await pending).failureOrNull, isNotNull);
        expect(sent, 0);
      },
    );
  }
  group('binary export filename decoding', () {
    for (final example in <(String?, String)>[
      (null, '区域实时营收.xlsx'),
      ("attachment; filename*=UTF-8''%E5%8C%BA%E5%9F%9F.xlsx", '区域.xlsx'),
      ('attachment; filename=%ZZ.xlsx', '区域实时营收.xlsx'),
      ('attachment; filename=%FF.xlsx', '区域实时营收.xlsx'),
      ('attachment; filename=区域.xlsx', '区域.xlsx'),
    ]) {
      test(
        '${example.$1 ?? 'no disposition'} preserves a usable Unicode filename',
        () async {
          final adapter = _StubAdapter(
            (_) => ResponseBody.fromBytes(
              [80, 75, 3, 4, 1],
              200,
              headers: {
                if (example.$1 != null) 'content-disposition': [example.$1!],
              },
            ),
          );
          final result = await _client(dio: Dio()..httpClientAdapter = adapter)
              .postBinary(
                '/wine/export',
                client: ClientKind.wine,
                fallbackFileName: '区域实时营收.xlsx',
              );
          expect(result.failureOrNull, isNull);
          expect(result.valueOrNull!.fileName, example.$2);
          expect(result.valueOrNull!.bytes, [80, 75, 3, 4, 1]);
        },
      );
    }
  });
  group('ClientKind', () {
    test('has the exact client order, names, and terminal values', () {
      expect(ClientKind.values, <ClientKind>[
        ClientKind.orgManager,
        ClientKind.booking,
        ClientKind.order,
        ClientKind.cashier,
        ClientKind.vip,
        ClientKind.erp,
        ClientKind.erpAdmin,
        ClientKind.wine,
        ClientKind.queueDisplay,
        ClientKind.superAdmin,
      ]);
      expect(ClientKind.values.map((kind) => kind.clientName), <String>[
        'org_mgr',
        'book',
        'order',
        'money',
        'vip',
        'erp',
        'erpAdmin',
        'wine',
        'queuedsp',
        'appinfo',
      ]);
      expect(ClientKind.values.map((kind) => kind.termType), <int?>[
        1,
        2,
        4,
        8,
        16,
        32,
        64,
        256,
        512,
        null,
      ]);
    });
  });

  group('ApiConfig', () {
    test('holds absolute endpoints and removes trailing slashes', () {
      final config = ApiConfig(
        apiBase: Uri.parse('https://api.example/server///'),
        onlineBase: Uri.parse('http://online.example:8080/server/'),
        websocketBase: Uri.parse('wss://socket.example/events/'),
      );

      expect(config.apiBase, Uri.parse('https://api.example/server'));
      expect(config.onlineBase, Uri.parse('http://online.example:8080/server'));
      expect(config.websocketBase, Uri.parse('wss://socket.example/events'));
    });

    test('rejects relative HTTP endpoints with a clear argument error', () {
      expect(
        () => ApiConfig(
          apiBase: Uri.parse('/server'),
          onlineBase: Uri.parse('https://online.example/server'),
          websocketBase: Uri.parse('wss://socket.example/events'),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('apiBase'),
          ),
        ),
      );
    });

    test('rejects wrong HTTP and websocket schemes', () {
      expect(
        () => ApiConfig(
          apiBase: Uri.parse('ftp://api.example/server'),
          onlineBase: Uri.parse('https://online.example/server'),
          websocketBase: Uri.parse('wss://socket.example/events'),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('http'),
          ),
        ),
      );
      expect(
        () => ApiConfig(
          apiBase: Uri.parse('https://api.example/server'),
          onlineBase: Uri.parse('https://online.example/server'),
          websocketBase: Uri.parse('https://socket.example/events'),
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.message,
            'message',
            contains('websocketBase'),
          ),
        ),
      );
    });

    test('rejects endpoint userinfo, fragments, and queries', () {
      final invalidApiBases = <Uri>[
        Uri.parse('https://user:synthetic@example.com/server'),
        Uri.parse('https://api.example/server#fragment'),
        Uri.parse('https://api.example/server?mode=test'),
        Uri.parse('https://api.example/server%2Fadmin'),
        Uri.parse('https://api.example/server/%252e%252e/admin'),
        Uri.parse('https://api.example/server/a%3Fadmin'),
      ];

      for (final apiBase in invalidApiBases) {
        expect(
          () => ApiConfig(
            apiBase: apiBase,
            onlineBase: Uri.parse('https://online.example/server'),
            websocketBase: Uri.parse('wss://socket.example/events'),
          ),
          throwsA(isA<ArgumentError>()),
          reason: apiBase.toString(),
        );
      }
    });
  });

  group('CredentialStore', () {
    test('declares asynchronous read, write, and clear operations', () async {
      final store = _MemoryCredentialStore();

      await store.writeTk('synthetic-tk');
      await store.writeStk('synthetic-stk');
      expect(await store.readTk(), 'synthetic-tk');
      expect(await store.readStk(), 'synthetic-stk');

      await store.clearTk();
      await store.clearStk();
      expect(await store.readTk(), isNull);
      expect(await store.readStk(), isNull);
    });

    test('supports atomic snapshots and matching invalidation', () async {
      final store = _MemoryCredentialStore(
        tk: 'synthetic-snapshot-tk',
        stk: 'synthetic-snapshot-stk',
      );

      final snapshot = await store.readSnapshot();
      expect(snapshot.tk, 'synthetic-snapshot-tk');
      expect(snapshot.stk, 'synthetic-snapshot-stk');

      await store.writeTk('synthetic-new-tk');
      await store.writeStk('synthetic-new-stk');
      await store.clearTkIfMatches(snapshot.tk);
      await store.clearStkIfMatches(snapshot.stk);
      expect(await store.readTk(), 'synthetic-new-tk');
      expect(await store.readStk(), 'synthetic-new-stk');

      await store.clearTkIfMatches('synthetic-new-tk');
      await store.clearStkIfMatches('synthetic-new-stk');
      expect(await store.readTk(), isNull);
      expect(await store.readStk(), isNull);
    });
  });

  group('HeaderPolicy', () {
    test('adds JSON, credential, and terminal headers', () async {
      final store = _MemoryCredentialStore(
        tk: 'synthetic-header-tk',
        stk: 'synthetic-header-stk',
      );
      final policy = HeaderPolicy(config: _config(), credentialStore: store);

      final headers = await policy.headersFor(
        target: Uri.parse('https://api.example/server/orders'),
        client: ClientKind.cashier,
      );

      expect(headers, <String, String>{
        Headers.acceptHeader: Headers.jsonContentType,
        Headers.contentTypeHeader: Headers.jsonContentType,
        'tk': 'synthetic-header-tk',
        'stk': 'synthetic-header-stk',
        'tt': '8',
      });
      expect(policy.toString(), isNot(contains('synthetic-header-tk')));
      expect(policy.toString(), isNot(contains('synthetic-header-stk')));
    });

    test('reads tk and stk from one consistent credential snapshot', () async {
      final store = _MemoryCredentialStore(
        tk: 'synthetic-snapshot-header-tk',
        stk: 'synthetic-snapshot-header-stk',
      );
      final policy = HeaderPolicy(config: _config(), credentialStore: store);

      final headers = await policy.headersFor(
        target: Uri.parse('https://api.example/server/orders'),
        client: ClientKind.order,
      );

      expect(headers['tk'], 'synthetic-snapshot-header-tk');
      expect(headers['stk'], 'synthetic-snapshot-header-stk');
      expect(store.readSnapshotCalls, 1);
      expect(store.readTkCalls, 0);
      expect(store.readStkCalls, 0);
    });

    test('omits empty credentials and a null terminal value', () async {
      final policy = HeaderPolicy(
        config: _config(),
        credentialStore: _MemoryCredentialStore(tk: '', stk: '   '),
      );

      final headers = await policy.headersFor(
        target: Uri.parse('https://api.example/server/admin'),
        client: ClientKind.superAdmin,
      );

      expect(headers.keys, <String>[
        Headers.acceptHeader,
        Headers.contentTypeHeader,
      ]);
    });

    test(
      'omits tt only for the exact online origin and path subtree',
      () async {
        final store = _MemoryCredentialStore(
          tk: 'synthetic-online-tk',
          stk: 'synthetic-online-stk',
        );
        final policy = HeaderPolicy(
          config: _config(
            onlineBase: Uri.parse('https://online.example:443/server'),
          ),
          credentialStore: store,
        );

        final onlineTargets = <Uri>[
          Uri.parse('https://online.example/server'),
          Uri.parse('https://online.example/server/orders'),
          Uri.parse('https://online.example:443/server/orders?day=today'),
        ];
        for (final target in onlineTargets) {
          final headers = await policy.headersFor(
            target: target,
            client: ClientKind.order,
          );
          expect(headers['tk'], 'synthetic-online-tk');
          expect(headers['stk'], 'synthetic-online-stk');
          expect(headers, isNot(contains('tt')), reason: target.toString());
        }

        final untrustedTargets = <Uri>[
          Uri.parse('https://online.example.evil/server/orders'),
          Uri.parse('https://online.example/serverevil/orders'),
          Uri.parse('https://online.example:444/server/orders'),
          Uri.parse('http://online.example/server/orders'),
          Uri.parse('https://api.example/outside/orders'),
          Uri.parse('https://[::1]/server/orders'),
          Uri.parse('https://online.example/server%2Forders'),
          Uri.parse('https://online.example/server/%252e%252e/orders'),
          Uri.parse('https://online.example/server/a%5Cb'),
          Uri.parse('https://online.example/server/a%3Foutside'),
          Uri.parse('https://online.example/server/a%23outside'),
        ];
        for (final target in untrustedTargets) {
          final headers = await policy.headersFor(
            target: target,
            client: ClientKind.order,
          );
          expect(headers, <String, String>{
            Headers.acceptHeader: Headers.jsonContentType,
            Headers.contentTypeHeader: Headers.jsonContentType,
          }, reason: target.toString());
        }
      },
    );

    test('online classification wins when trusted subtrees overlap', () async {
      final policy = HeaderPolicy(
        config: _config(
          onlineBase: Uri.parse('https://api.example/server/online'),
        ),
        credentialStore: _MemoryCredentialStore(tk: 'synthetic-overlap-tk'),
      );

      final headers = await policy.headersFor(
        target: Uri.parse('https://api.example/server/online/orders'),
        client: ClientKind.order,
      );

      expect(headers['tk'], 'synthetic-overlap-tk');
      expect(headers, isNot(contains('tt')));
    });
  });

  group('RequestGate', () {
    test('allows the first occurrence of a normalized URL', () {
      final gate = RequestGate(
        clock: () => DateTime.fromMillisecondsSinceEpoch(1000),
      );

      expect(
        gate.allow(Uri.parse('https://api.example/a/../orders?q=1')),
        isTrue,
      );
    });

    test('requires strictly more than 100ms for csm order selection', () {
      var now = DateTime.fromMillisecondsSinceEpoch(1000);
      final gate = RequestGate(clock: () => now);
      final target = Uri.parse(
        'https://api.example/server/sel/csm_orders?store=one',
      );

      expect(gate.allow(target), isTrue);
      now = DateTime.fromMillisecondsSinceEpoch(1100);
      expect(gate.allow(target), isFalse);
      now = DateTime.fromMillisecondsSinceEpoch(1101);
      expect(gate.allow(target), isTrue);
    });

    test('requires more than zero milliseconds for other URLs', () {
      var now = DateTime.fromMillisecondsSinceEpoch(1000);
      final gate = RequestGate(clock: () => now);
      final target = Uri.parse('https://api.example/server/orders');

      expect(gate.allow(target), isTrue);
      expect(gate.allow(target), isFalse);
      now = DateTime.fromMillisecondsSinceEpoch(1001);
      expect(gate.allow(target), isTrue);
    });

    test('does not advance the last allowed time when blocked', () {
      var now = DateTime.fromMillisecondsSinceEpoch(1000);
      final gate = RequestGate(clock: () => now);
      final target = Uri.parse(
        'https://api.example/server/sel/csm_orders?store=one',
      );

      expect(gate.allow(target), isTrue);
      now = DateTime.fromMillisecondsSinceEpoch(1050);
      expect(gate.allow(target), isFalse);
      now = DateTime.fromMillisecondsSinceEpoch(1101);
      expect(gate.allow(target), isTrue);
    });

    test('uses the canonical route without query as the key', () {
      final gate = RequestGate(
        clock: () => DateTime.fromMillisecondsSinceEpoch(1000),
      );

      expect(
        gate.allow(Uri.parse('https://api.example/server/a/../orders?q=1')),
        isTrue,
      );
      expect(
        gate.allow(Uri.parse('https://api.example/server/orders?q=1')),
        isFalse,
      );
      expect(
        gate.allow(Uri.parse('https://api.example/server/orders?q=2')),
        isFalse,
      );
      expect(gate.toString(), isNot(contains('q=1')));
      expect(gate.toString(), isNot(contains('q=2')));
    });

    test('bounds retained hashes and evicts the oldest route', () {
      final gate = RequestGate(
        clock: () => DateTime.fromMillisecondsSinceEpoch(1000),
        maxEntries: 3,
      );

      expect(gate.allow(Uri.parse('https://api.example/server/a')), isTrue);
      expect(gate.allow(Uri.parse('https://api.example/server/b')), isTrue);
      expect(gate.allow(Uri.parse('https://api.example/server/c')), isTrue);
      expect(gate.trackedRequestCount, 3);
      expect(gate.allow(Uri.parse('https://api.example/server/d')), isTrue);
      expect(gate.trackedRequestCount, 3);
      expect(
        gate.allow(
          Uri.parse('https://api.example/server/a?token=synthetic-secret'),
        ),
        isTrue,
        reason: 'the oldest route hash was evicted',
      );
      expect(gate.trackedRequestCount, 3);
      expect(gate.toString(), isNot(contains('synthetic-secret')));
    });

    test('evicts expired route hashes using the injected clock', () {
      var now = DateTime.fromMillisecondsSinceEpoch(1000);
      final gate = RequestGate(
        clock: () => now,
        maxEntries: 3,
        retention: const Duration(milliseconds: 100),
      );

      expect(gate.allow(Uri.parse('https://api.example/server/a')), isTrue);
      expect(gate.trackedRequestCount, 1);
      now = DateTime.fromMillisecondsSinceEpoch(1101);
      expect(gate.allow(Uri.parse('https://api.example/server/b')), isTrue);
      expect(gate.trackedRequestCount, 1);
      expect(gate.allow(Uri.parse('https://api.example/server/a')), isTrue);
      expect(gate.trackedRequestCount, 2);
    });

    test('resets the route baseline when the clock moves backwards', () {
      var now = DateTime.fromMillisecondsSinceEpoch(10000);
      final gate = RequestGate(clock: () => now);
      final target = Uri.parse('https://api.example/server/sel/csm_orders');

      expect(gate.allow(target), isTrue);
      now = DateTime.fromMillisecondsSinceEpoch(1000);
      expect(gate.allow(target), isTrue);
      expect(gate.allow(target), isFalse);
      now = DateTime.fromMillisecondsSinceEpoch(1100);
      expect(gate.allow(target), isFalse);
      now = DateTime.fromMillisecondsSinceEpoch(1101);
      expect(gate.allow(target), isTrue);
    });
  });

  group('ProtocolClient requests', () {
    test('rejects invalid response limits before configuring Dio', () {
      final invalidLimits = <ProtocolResponseLimits>[
        const _InvalidResponseLimits(
          maxRawResponseBytes: 0,
          maxDepth: 32,
          maxNodes: 100,
        ),
        const _InvalidResponseLimits(
          maxRawResponseBytes: 1024,
          maxDepth: -1,
          maxNodes: 100,
        ),
        const _InvalidResponseLimits(
          maxRawResponseBytes: 1024,
          maxDepth: 32,
          maxNodes: 0,
        ),
      ];

      for (final limits in invalidLimits) {
        final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
        final dio = Dio()..httpClientAdapter = adapter;

        expect(
          () => ProtocolClient(
            dio: dio,
            config: _config(),
            credentialStore: _MemoryCredentialStore(),
            requestGate: RequestGate(clock: DateTime.now),
            responseLimits: limits,
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(identical(dio.httpClientAdapter, adapter), isTrue);
        expect(dio.options.connectTimeout, isNull);
        expect(dio.options.sendTimeout, isNull);
        expect(dio.options.receiveTimeout, isNull);
        expect(adapter.calls, 0);
      }
    });

    test(
      'POST joins paths, uses JSON, exact headers, and 12s timeouts',
      () async {
        final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
        final dio = Dio()..httpClientAdapter = adapter;
        final store = _MemoryCredentialStore(
          tk: 'synthetic-post-tk',
          stk: 'synthetic-post-stk',
        );
        final client = _client(dio: dio, credentialStore: store);
        final body = <String, Object?>{'user': 'demo', 'count': 1};

        final result = await client.post(
          '/auth/login',
          body: body,
          client: ClientKind.orgManager,
        );

        expect(result, isA<Success<Map<String, Object?>>>());
        expect(adapter.calls, 1);
        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.uri, Uri.parse('https://api.example/server/auth/login'));
        expect(request.connectTimeout, const Duration(seconds: 12));
        expect(request.sendTimeout, const Duration(seconds: 12));
        expect(request.receiveTimeout, const Duration(seconds: 12));
        expect(request.headers[Headers.acceptHeader], Headers.jsonContentType);
        expect(
          request.headers[Headers.contentTypeHeader],
          Headers.jsonContentType,
        );
        expect(request.headers['tk'], 'synthetic-post-tk');
        expect(request.headers['stk'], 'synthetic-post-stk');
        expect(request.headers['tt'], '1');
        expect(request.data, body);
        final encodedBody = adapter.encodedBodies.single;
        expect(jsonDecode(encodedBody), body);
        expect(encodedBody, isNot(contains('user=demo')));
      },
    );

    test('GET preserves supplied query values', () async {
      final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
      final dio = Dio()..httpClientAdapter = adapter;
      final client = _client(dio: dio);

      await client.get(
        'orders',
        query: <String, Object?>{'state': 'paid', 'page': '2'},
        client: ClientKind.booking,
      );

      expect(adapter.requests.single.uri.path, '/server/orders');
      expect(adapter.requests.single.uri.queryParameters, <String, String>{
        'state': 'paid',
        'page': '2',
      });
    });

    test(
      'GET disables bodyless Web send timeout but keeps base limits',
      () async {
        final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
        final dio = Dio()..httpClientAdapter = adapter;
        final client = _client(dio: dio);

        await client.get('/orders', client: ClientKind.booking);

        expect(dio.options.connectTimeout, const Duration(seconds: 12));
        expect(dio.options.sendTimeout, const Duration(seconds: 12));
        expect(dio.options.receiveTimeout, const Duration(seconds: 12));
        final request = adapter.requests.single;
        expect(request.connectTimeout, const Duration(seconds: 12));
        expect(request.sendTimeout, Duration.zero);
        expect(request.receiveTimeout, const Duration(seconds: 12));
        expect(request.responseType, ResponseType.plain);
      },
    );

    test('shared ProtocolClients reuse one strict response wrapper', () async {
      final adapter = _StubAdapter((_) => _textBody('{"sharedValue":1}'));
      final dio = Dio()..httpClientAdapter = adapter;
      final firstClient = _client(
        dio: dio,
        responseLimits: const ProtocolResponseLimits(
          maxRawResponseBytes: 64,
          maxDepth: 32,
          maxNodes: 100,
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

      expect(identical(dio.httpClientAdapter, installedAdapter), isTrue);
      final result = await firstClient.get(
        '/shared-wrapper',
        client: ClientKind.booking,
      );
      expect(result.failureOrNull?.code, 'protocol.response_too_large');
      expect(adapter.calls, 1);
    });

    test(
      'rejects external, ambiguous, traversal, and embedded query paths',
      () async {
        final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
        final dio = Dio()..httpClientAdapter = adapter;
        final client = _client(dio: dio);
        final invalidPaths = <String>[
          'https://evil.example/collect',
          '//evil.example/collect',
          '../admin',
          'auth/../admin',
          '/auth/%2e%2e/admin',
          r'auth\login',
          '/auth/login?value=synthetic-path-secret',
          '/auth/login#fragment',
        ];

        for (final path in invalidPaths) {
          final result = await client.get(path, client: ClientKind.booking);
          expect(
            result.failureOrNull?.kind,
            FailureKind.protocol,
            reason: path,
          );
          expect(
            result.failureOrNull?.code,
            'protocol.invalid_path',
            reason: path,
          );
          expect(
            _failureText(result),
            isNot(contains('synthetic-path-secret')),
          );
        }
        expect(adapter.calls, 0);
      },
    );

    test(
      'rejects encoded separators, controls, and nested encodings',
      () async {
        final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
        final dio = Dio()..httpClientAdapter = adapter;
        final client = _client(dio: dio);
        final invalidPaths = <String>[
          '/auth/a%2Fb',
          '/auth/a%2fb',
          '/auth/a%5Cb',
          '/auth/a%5cb',
          '/auth/%2E%2E/admin',
          '/auth/%2e%2E/admin',
          '/auth/%252F/admin',
          '/auth/%255c/admin',
          '/auth/%252e%252E/admin',
          '/auth/a%3Fadmin',
          '/auth/a%23admin',
          '/auth/a%253fadmin',
          '/auth/a%2523admin',
          '/auth/%00/admin',
          '/auth/%1f/admin',
          '/auth/%7F/admin',
        ];

        for (final path in invalidPaths) {
          final result = await client.get(path, client: ClientKind.booking);
          expect(
            result.failureOrNull?.code,
            'protocol.invalid_path',
            reason: path,
          );
        }
        expect(adapter.calls, 0);
      },
    );

    test(
      'canonicalizes safe decoded segments while preserving api base',
      () async {
        final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
        final dio = Dio()..httpClientAdapter = adapter;
        final client = _client(dio: dio);

        final result = await client.get(
          '/orders/a%20b/%7Eready',
          client: ClientKind.booking,
        );

        expect(result, isA<Success<Map<String, Object?>>>());
        expect(adapter.requests.single.uri.pathSegments, <String>[
          'server',
          'orders',
          'a b',
          '~ready',
        ]);
      },
    );

    test('a request gate rejection does not call the adapter', () async {
      final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
      final dio = Dio()..httpClientAdapter = adapter;
      final gate = RequestGate(
        clock: () => DateTime.fromMillisecondsSinceEpoch(1000),
      );
      final client = _client(dio: dio, gate: gate);

      final first = await client.get('/orders', client: ClientKind.order);
      final blocked = await client.get('/orders', client: ClientKind.order);

      expect(first, isA<Success<Map<String, Object?>>>());
      expect(blocked.failureOrNull?.kind, FailureKind.protocol);
      expect(blocked.failureOrNull?.code, 'protocol.request_throttled');
      expect(blocked.failureOrNull?.safeMessage, '请求过于频繁，请稍后重试');
      expect(adapter.calls, 1);
    });

    test(
      'concurrent clients keep credentials in per-request headers',
      () async {
        final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
        final dio = Dio()..httpClientAdapter = adapter;
        final firstClient = _client(
          dio: dio,
          credentialStore: _MemoryCredentialStore(
            tk: 'synthetic-concurrent-one',
            readDelay: const Duration(milliseconds: 2),
          ),
        );
        final secondClient = _client(
          dio: dio,
          credentialStore: _MemoryCredentialStore(
            tk: 'synthetic-concurrent-two',
          ),
        );

        await Future.wait(<Future<Result<Map<String, Object?>>>>[
          firstClient.get('/one', client: ClientKind.booking),
          secondClient.get('/two', client: ClientKind.cashier),
        ]);

        final requestsByPath = <String, RequestOptions>{
          for (final request in adapter.requests) request.uri.path: request,
        };
        expect(
          requestsByPath['/server/one']?.headers['tk'],
          'synthetic-concurrent-one',
        );
        expect(requestsByPath['/server/one']?.headers['tt'], '2');
        expect(
          requestsByPath['/server/two']?.headers['tk'],
          'synthetic-concurrent-two',
        );
        expect(requestsByPath['/server/two']?.headers['tt'], '8');
        expect(dio.options.headers, isNot(contains('tk')));
        expect(dio.options.headers, isNot(contains('stk')));
        expect(dio.options.headers, isNot(contains('tt')));
      },
    );
  });

  group('ProtocolClient responses', () {
    test('returns a fresh string-keyed top-level map', () async {
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{
          'code': 0,
          'data': <String, Object?>{'id': 7},
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(dio: dio)
          .get('/orders', client: ClientKind.order);

      expect(result.valueOrNull, <String, Object?>{
        'code': 0,
        'data': <String, Object?>{'id': 7},
      });
    });

    test('decodes a JSON object returned as a plain string', () async {
      final adapter = _StubAdapter((_) => _textBody('{"code":0,"label":"ok"}'));
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(dio: dio)
          .get('/orders', client: ClientKind.order);

      expect(result.valueOrNull, <String, Object?>{'code': 0, 'label': 'ok'});
    });

    test('rejects non-string keys without coercion', () async {
      final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
      final dio = Dio()..httpClientAdapter = adapter;
      dio.interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            response.data = <Object?, Object?>{1: 'not-a-string-key'};
            handler.next(response);
          },
        ),
      );

      final result = await _client(dio: dio)
          .get('/orders', client: ClientKind.order);

      expect(result.failureOrNull?.kind, FailureKind.protocol);
      expect(result.failureOrNull?.code, 'protocol.invalid_top_level');
    });

    test('rejects arrays, scalars, null, and malformed JSON', () async {
      final bodies = <ResponseBody>[
        _jsonBody(<Object?>[1, 2]),
        _jsonBody(3),
        _jsonBody(null),
        _textBody('{malformed'),
      ];

      for (final body in bodies) {
        final adapter = _StubAdapter((_) => body);
        final dio = Dio()..httpClientAdapter = adapter;
        final result = await _client(dio: dio)
            .get('/orders', client: ClientKind.order);

        expect(result.failureOrNull?.kind, FailureKind.protocol);
        expect(result.failureOrNull?.code, 'protocol.invalid_top_level');
        expect(result.failureOrNull?.safeMessage, '服务返回了无法识别的数据');
      }
    });

    test('rejects raw responses over the UTF-8 byte budget', () async {
      final secret = List<String>.filled(20, '界').join();
      final adapter = _StubAdapter(
        (_) => _textBody(jsonEncode(<String, Object?>{'payload': secret})),
      );
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(
        dio: dio,
        responseLimits: const ProtocolResponseLimits(
          maxRawResponseBytes: 50,
          maxDepth: 32,
          maxNodes: 100,
        ),
      ).get('/orders', client: ClientKind.order);

      expect(result.failureOrNull?.code, 'protocol.response_too_large');
      expect(_failureText(result), isNot(contains(secret)));
    });

    test('cancels an unbounded stream before buffering every chunk', () async {
      final probe = _StreamingResponseProbe();
      final adapter = _StubAdapter((_) => probe.responseBody());
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(
        dio: dio,
        responseLimits: const ProtocolResponseLimits(
          maxRawResponseBytes: 12,
          maxDepth: 32,
          maxNodes: 100,
        ),
      ).get('/stream', client: ClientKind.order);
      await Future<void>.delayed(Duration.zero);

      expect(result.failureOrNull?.code, 'protocol.response_too_large');
      expect(probe.chunksProduced, 2);
      expect(probe.chunksProduced, lessThan(probe.totalChunks));
      expect(probe.finalized, isTrue);
      expect(probe.closeCalls, greaterThanOrEqualTo(1));
      expect(adapter.calls, 1, reason: 'oversized responses are not retried');
    });

    test('stream limit overrides a dishonest small Content-Length', () async {
      final probe = _StreamingResponseProbe(contentLength: 4);
      final adapter = _StubAdapter((_) => probe.responseBody());
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(
        dio: dio,
        responseLimits: const ProtocolResponseLimits(
          maxRawResponseBytes: 12,
          maxDepth: 32,
          maxNodes: 100,
        ),
      ).get('/lying-length', client: ClientKind.order);
      await Future<void>.delayed(Duration.zero);

      expect(result.failureOrNull?.code, 'protocol.response_too_large');
      expect(probe.chunksProduced, 2);
      expect(probe.finalized, isTrue);
      expect(probe.closeCalls, greaterThanOrEqualTo(1));
      expect(adapter.calls, 1);
    });

    test(
      'rejects Content-Length case-insensitively before streaming',
      () async {
        final probe = _StreamingResponseProbe(
          contentLength: 999,
          contentLengthHeader: 'Content-Length',
        );
        final adapter = _StubAdapter((_) => probe.responseBody());
        final dio = Dio()..httpClientAdapter = adapter;

        final result = await _client(
          dio: dio,
          responseLimits: const ProtocolResponseLimits(
            maxRawResponseBytes: 12,
            maxDepth: 32,
            maxNodes: 100,
          ),
        ).get('/declared-large', client: ClientKind.order);

        expect(result.failureOrNull?.code, 'protocol.response_too_large');
        expect(probe.chunksProduced, 0);
        expect(probe.closeCalls, greaterThanOrEqualTo(1));
        expect(adapter.calls, 1);
      },
    );

    test('rejects an oversized content-length before JSON parsing', () async {
      final adapter = _StubAdapter(
        (_) => ResponseBody.fromString(
          '{malformed',
          200,
          headers: <String, List<String>>{
            Headers.contentLengthHeader: <String>['999'],
            Headers.contentTypeHeader: <String>['text/plain'],
          },
        ),
      );
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(
        dio: dio,
        responseLimits: const ProtocolResponseLimits(
          maxRawResponseBytes: 64,
          maxDepth: 32,
          maxNodes: 100,
        ),
      ).get('/orders', client: ClientKind.order);

      expect(result.failureOrNull?.code, 'protocol.response_too_large');
      expect(_failureText(result), isNot(contains('{malformed')));
    });

    test('rejects decoded responses beyond depth and node budgets', () async {
      Object? deep = <String, Object?>{'leaf': true};
      for (var index = 0; index < 5; index += 1) {
        deep = <String, Object?>{'level$index': deep};
      }
      final wide = <String, Object?>{
        for (var index = 0; index < 20; index += 1) 'item$index': index,
      };
      final cases = <(Object?, ProtocolResponseLimits, String)>[
        (
          deep,
          const ProtocolResponseLimits(
            maxRawResponseBytes: 1024,
            maxDepth: 3,
            maxNodes: 100,
          ),
          'protocol.response_too_deep',
        ),
        (
          wide,
          const ProtocolResponseLimits(
            maxRawResponseBytes: 1024,
            maxDepth: 32,
            maxNodes: 10,
          ),
          'protocol.response_too_large',
        ),
      ];

      for (final (data, limits, expectedCode) in cases) {
        final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
        final dio = Dio()..httpClientAdapter = adapter;
        dio.interceptors.add(
          InterceptorsWrapper(
            onResponse: (response, handler) {
              response.data = data;
              handler.next(response);
            },
          ),
        );

        final result = await _client(
          dio: dio,
          responseLimits: limits,
        ).get('/orders', client: ClientKind.order);

        expect(result.failureOrNull?.code, expectedCode);
      }
    });

    test('rejects non-finite and unsupported decoded values', () async {
      final invalidValues = <Object>[double.nan, double.infinity, DateTime(0)];

      for (final invalidValue in invalidValues) {
        final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
        final dio = Dio()..httpClientAdapter = adapter;
        dio.interceptors.add(
          InterceptorsWrapper(
            onResponse: (response, handler) {
              response.data = <String, Object?>{'value': invalidValue};
              handler.next(response);
            },
          ),
        );

        final result = await _client(
          dio: dio,
          responseLimits: const ProtocolResponseLimits(
            maxRawResponseBytes: 1024,
            maxDepth: 32,
            maxNodes: 100,
          ),
        ).get('/orders', client: ClientKind.order);

        expect(result.failureOrNull?.code, 'protocol.invalid_top_level');
      }
    });

    test(
      'auth codes 11 and 12 clear only tk and return a safe failure',
      () async {
        for (final code in <Object>[11, '12']) {
          final adapter = _StubAdapter(
            (_) => _jsonBody(<String, Object?>{
              'code': code,
              'raw': 'synthetic-auth-server-body',
            }),
          );
          final dio = Dio()..httpClientAdapter = adapter;
          final store = _MemoryCredentialStore(
            tk: 'synthetic-expired-tk',
            stk: 'synthetic-preserved-stk',
          );

          final result = await _client(
            dio: dio,
            credentialStore: store,
          ).get('/orders', client: ClientKind.order);

          expect(result.failureOrNull?.kind, FailureKind.authentication);
          expect(result.failureOrNull?.code, 'authentication.tk_expired');
          expect(result.failureOrNull?.safeMessage, '登录已失效，请重新登录');
          expect(store.clearTkCalls, 1);
          expect(store.clearStkCalls, 0);
          final failureText = _failureText(result);
          expect(failureText, isNot(contains('synthetic-expired-tk')));
          expect(failureText, isNot(contains('synthetic-preserved-stk')));
          expect(failureText, isNot(contains('synthetic-auth-server-body')));
        }
      },
    );

    test(
      'auth codes 14 and 15 clear only stk and return a safe failure',
      () async {
        for (final code in <Object>[14, '15']) {
          final adapter = _StubAdapter(
            (_) => _jsonBody(<String, Object?>{'code': code}),
          );
          final dio = Dio()..httpClientAdapter = adapter;
          final store = _MemoryCredentialStore(
            tk: 'synthetic-preserved-tk',
            stk: 'synthetic-expired-stk',
          );

          final result = await _client(
            dio: dio,
            credentialStore: store,
          ).get('/orders', client: ClientKind.order);

          expect(result.failureOrNull?.kind, FailureKind.authentication);
          expect(result.failureOrNull?.code, 'authentication.stk_expired');
          expect(result.failureOrNull?.safeMessage, '授权已失效，请重新登录');
          expect(store.clearTkCalls, 0);
          expect(store.clearStkCalls, 1);
          expect(
            _failureText(result),
            isNot(contains('synthetic-expired-stk')),
          );
        }
      },
    );

    test('an old tk-expired response cannot clear a newer tk', () async {
      final store = _MemoryCredentialStore(tk: 'synthetic-old-tk');
      final adapter = _StubAdapter((_) async {
        await store.writeTk('synthetic-newer-tk');
        return _jsonBody(<String, Object?>{'code': 11});
      });
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(
        dio: dio,
        credentialStore: store,
      ).get('/orders', client: ClientKind.order);

      expect(result.failureOrNull?.code, 'authentication.tk_expired');
      expect(store.tk, 'synthetic-newer-tk');
      expect(store.clearTkCalls, 1);
    });

    test('an old stk-expired response cannot clear a newer stk', () async {
      final store = _MemoryCredentialStore(stk: 'synthetic-old-stk');
      final adapter = _StubAdapter((_) async {
        await store.writeStk('synthetic-newer-stk');
        return _jsonBody(<String, Object?>{'code': 14});
      });
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(
        dio: dio,
        credentialStore: store,
      ).get('/orders', client: ClientKind.order);

      expect(result.failureOrNull?.code, 'authentication.stk_expired');
      expect(store.stk, 'synthetic-newer-stk');
      expect(store.clearStkCalls, 1);
    });

    test(
      'does not treat doubles, booleans, or padded strings as auth codes',
      () async {
        for (final code in <Object>[11.0, true, ' 11 ', '11.0']) {
          final adapter = _StubAdapter(
            (_) => code is double
                ? _textBody('{"code":11.0}')
                : _jsonBody(<String, Object?>{'code': code}),
          );
          final dio = Dio()..httpClientAdapter = adapter;
          final store = _MemoryCredentialStore(tk: 'synthetic-tk');

          final result = await _client(
            dio: dio,
            credentialStore: store,
          ).get('/orders', client: ClientKind.order);

          expect(result.valueOrNull?['code'], code);
          expect(store.clearTkCalls, 0);
        }
      },
    );

    test('returns other business codes unchanged for caller policy', () async {
      final response = <String, Object?>{
        'code': 27,
        'message': 'business decision belongs to caller',
      };
      final adapter = _StubAdapter((_) => _jsonBody(response));
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(dio: dio)
          .get('/orders', client: ClientKind.order);

      expect(result, isA<Success<Map<String, Object?>>>());
      expect(result.valueOrNull, response);
    });
  });

  group('ProtocolClient failures', () {
    test(
      'maps timeout and connection failures to stable network codes',
      () async {
        final cases = <DioExceptionType, String>{
          DioExceptionType.connectionTimeout: 'network.timeout',
          DioExceptionType.sendTimeout: 'network.timeout',
          DioExceptionType.receiveTimeout: 'network.timeout',
          DioExceptionType.connectionError: 'network.unavailable',
        };

        for (final entry in cases.entries) {
          late final _StubAdapter adapter;
          adapter = _StubAdapter(
            (request) => throw DioException(
              requestOptions: request,
              type: entry.key,
              message: 'synthetic-transport-secret',
            ),
          );
          final dio = Dio()..httpClientAdapter = adapter;

          final result = await _client(dio: dio)
              .get('/orders', client: ClientKind.order);

          expect(result.failureOrNull?.kind, FailureKind.network);
          expect(result.failureOrNull?.code, entry.value);
          expect(
            _failureText(result),
            isNot(contains('synthetic-transport-secret')),
          );
          expect(
            adapter.calls,
            1,
            reason: 'transport requests are never retried',
          );
        }
      },
    );

    test('maps cancellation to a stable safe failure', () async {
      late final _StubAdapter adapter;
      adapter = _StubAdapter(
        (request) => throw DioException(
          requestOptions: request,
          type: DioExceptionType.cancel,
          message: 'synthetic-cancel-secret',
        ),
      );
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(dio: dio)
          .get('/orders', client: ClientKind.order);

      expect(result.failureOrNull?.kind, FailureKind.network);
      expect(result.failureOrNull?.code, 'network.cancelled');
      expect(result.failureOrNull?.safeMessage, '请求已取消');
      expect(_failureText(result), isNot(contains('synthetic-cancel-secret')));
    });

    test('maps unknown failures without exposing exception details', () async {
      final adapter = _StubAdapter(
        (_) => throw StateError('synthetic-unknown-secret'),
      );
      final dio = Dio()..httpClientAdapter = adapter;

      final result = await _client(dio: dio)
          .get('/orders', client: ClientKind.order);

      expect(result.failureOrNull?.kind, FailureKind.unknown);
      expect(result.failureOrNull?.code, 'unknown.request_failed');
      expect(result.failureOrNull?.safeMessage, '请求失败，请稍后重试');
      expect(_failureText(result), isNot(contains('synthetic-unknown-secret')));
      expect(adapter.calls, 1);
    });

    test(
      'credential read failure is safe and prevents a network call',
      () async {
        for (final failure in <_CredentialFailure>[
          _CredentialFailure.readTk,
          _CredentialFailure.readStk,
        ]) {
          final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
          final dio = Dio()..httpClientAdapter = adapter;
          final store = _MemoryCredentialStore(
            tk: 'synthetic-read-tk',
            stk: 'synthetic-read-stk',
            failure: failure,
          );

          final result = await _client(
            dio: dio,
            credentialStore: store,
          ).get('/orders', client: ClientKind.order);

          expect(result.failureOrNull?.kind, FailureKind.authentication);
          expect(
            result.failureOrNull?.code,
            'authentication.credentials_unavailable',
          );
          expect(result.failureOrNull?.safeMessage, '登录信息不可用，请重新登录');
          expect(
            _failureText(result),
            isNot(contains('synthetic-read-secret')),
          );
          expect(adapter.calls, 0);
        }
      },
    );

    test('credential clear failure still returns the auth failure', () async {
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{
          'code': 11,
          'raw': 'synthetic-clear-body',
        }),
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final store = _MemoryCredentialStore(
        tk: 'synthetic-clear-tk',
        failure: _CredentialFailure.clearTk,
      );

      final result = await _client(
        dio: dio,
        credentialStore: store,
      ).get('/orders', client: ClientKind.order);

      expect(result.failureOrNull?.kind, FailureKind.authentication);
      expect(result.failureOrNull?.code, 'authentication.tk_expired');
      expect(store.clearTkCalls, 1);
      expect(_failureText(result), isNot(contains('synthetic-clear-secret')));
      expect(_failureText(result), isNot(contains('synthetic-clear-body')));
    });
  });
}

ApiConfig _config({Uri? onlineBase}) => ApiConfig(
  apiBase: Uri.parse('https://api.example/server'),
  onlineBase: onlineBase ?? Uri.parse('https://online.example/server'),
  websocketBase: Uri.parse('wss://socket.example/events'),
);

ProtocolClient _client({
  required Dio dio,
  CredentialStore? credentialStore,
  RequestGate? gate,
  ProtocolResponseLimits? responseLimits,
}) => ProtocolClient(
  dio: dio,
  config: _config(),
  credentialStore: credentialStore ?? _MemoryCredentialStore(),
  requestGate:
      gate ??
      RequestGate(clock: () => DateTime.fromMillisecondsSinceEpoch(1000)),
  responseLimits: responseLimits ?? const ProtocolResponseLimits(),
);

String _failureText(Result<Map<String, Object?>> result) {
  final failure = result.failureOrNull;
  return '${failure?.kind}|${failure?.code}|${failure?.safeMessage}|$result';
}

ResponseBody _jsonBody(Object? value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

ResponseBody _textBody(String value) => ResponseBody.fromString(
  value,
  200,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>['text/plain'],
  },
);

typedef _AdapterResponder = FutureOr<ResponseBody> Function(
  RequestOptions request,
);

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._responder);

  final _AdapterResponder _responder;
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<String> encodedBodies = <String>[];
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    requests.add(options);
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    encodedBodies.add(utf8.decode(bytes));
    return _responder(options);
  }

  @override
  void close({bool force = false}) {}
}

enum _CredentialFailure { none, readTk, readStk, clearTk, clearStk }

final class _MemoryCredentialStore implements CredentialStore {
  Future<void> Function()? beforeSnapshot;
  _MemoryCredentialStore({
    this.tk,
    this.stk,
    this.failure = _CredentialFailure.none,
    this.readDelay,
  });

  String? tk;
  String? stk;
  final _CredentialFailure failure;
  final Duration? readDelay;
  int readSnapshotCalls = 0;
  int readTkCalls = 0;
  int readStkCalls = 0;
  int clearTkCalls = 0;
  int clearStkCalls = 0;

  @override
  Future<void> clearStk() async {
    clearStkCalls += 1;
    if (failure == _CredentialFailure.clearStk) {
      throw StateError('synthetic-clear-secret');
    }
    stk = null;
  }

  @override
  Future<void> clearStkIfMatches(String? expected) async {
    clearStkCalls += 1;
    if (failure == _CredentialFailure.clearStk) {
      throw StateError('synthetic-clear-secret');
    }
    if (stk == expected) stk = null;
  }

  @override
  Future<void> clearTk() async {
    clearTkCalls += 1;
    if (failure == _CredentialFailure.clearTk) {
      throw StateError('synthetic-clear-secret');
    }
    tk = null;
  }

  @override
  Future<void> clearTkIfMatches(String? expected) async {
    clearTkCalls += 1;
    if (failure == _CredentialFailure.clearTk) {
      throw StateError('synthetic-clear-secret');
    }
    if (tk == expected) tk = null;
  }

  @override
  Future<String?> readStk() async {
    readStkCalls += 1;
    if (readDelay case final delay?) await Future<void>.delayed(delay);
    if (failure == _CredentialFailure.readStk) {
      throw StateError('synthetic-read-secret');
    }
    return stk;
  }

  @override
  Future<String?> readTk() async {
    readTkCalls += 1;
    if (readDelay case final delay?) await Future<void>.delayed(delay);
    if (failure == _CredentialFailure.readTk) {
      throw StateError('synthetic-read-secret');
    }
    return tk;
  }

  @override
  Future<CredentialSnapshot> readSnapshot() async {
    readSnapshotCalls += 1;
    await beforeSnapshot?.call();
    if (readDelay case final delay?) await Future<void>.delayed(delay);
    if (failure == _CredentialFailure.readTk ||
        failure == _CredentialFailure.readStk) {
      throw StateError('synthetic-read-secret');
    }
    return CredentialSnapshot(tk: tk, stk: stk);
  }

  @override
  Future<void> writeStk(String value) async {
    stk = value;
  }

  @override
  Future<void> writeTk(String value) async {
    tk = value;
  }
}

final class _InvalidResponseLimits implements ProtocolResponseLimits {
  const _InvalidResponseLimits({
    required this.maxRawResponseBytes,
    required this.maxDepth,
    required this.maxNodes,
  });

  @override
  final int maxRawResponseBytes;

  @override
  final int maxDepth;

  @override
  final int maxNodes;
}

final class _StreamingResponseProbe {
  _StreamingResponseProbe({
    this.contentLength,
    this.contentLengthHeader = Headers.contentLengthHeader,
  });

  final int? contentLength;
  final String contentLengthHeader;
  final int totalChunks = 4;
  int chunksProduced = 0;
  int closeCalls = 0;
  bool finalized = false;

  ResponseBody responseBody() => ResponseBody(
    _chunks(),
    200,
    onClose: () => closeCalls += 1,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>['text/plain'],
      if (contentLength case final value?)
        contentLengthHeader: <String>[value.toString()],
    },
  );

  Stream<Uint8List> _chunks() async* {
    try {
      for (var index = 0; index < totalChunks; index += 1) {
        chunksProduced += 1;
        yield Uint8List.fromList(List<int>.filled(8, 0x61 + index));
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      finalized = true;
    }
  }
}
