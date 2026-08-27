import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';

void main() {
  group('SyncEnvelope', () {
    test('parses data, heartbeat, and server-error JSON', () {
      final data = SyncEnvelope.parse(
        '{"p":1,"t":"20260826010101","d":{"0":[1]}}',
      );
      final heartbeat = SyncEnvelope.parse(<String, Object?>{
        'p': 2.0,
        't': '20260826010102',
        'd': null,
      });
      final serverError = SyncEnvelope.parse(<String, Object?>{
        'p': 3,
        'd': 'service unavailable',
      });

      expect(data.valueOrNull?.type, SyncEventType.data);
      expect(data.valueOrNull?.cursor, '20260826010101');
      expect(heartbeat.valueOrNull?.type, SyncEventType.heartbeat);
      expect(serverError.valueOrNull?.type, SyncEventType.serverError);
      expect(serverError.valueOrNull?.cursor, isNull);
    });

    test('rejects malformed, invalid cursor, non-JSON, and mutable cycles', () {
      final cyclic = <String, Object?>{};
      cyclic['self'] = cyclic;
      final invalid = <Object?>[
        '[]',
        '{"t":"20260826010101","d":null}',
        '{"p":1,"t":"2026082601010","d":null}',
        '{"p":2,"t":"20260826010101"}',
        <String, Object?>{'p': 1, 't': '20260826010101', 'd': cyclic},
        <String, Object?>{'p': 4, 't': '20260826010101', 'd': null},
      ];

      for (final value in invalid) {
        final result = SyncEnvelope.parse(value);
        expect(result.failureOrNull?.kind, FailureKind.protocol);
      }
    });

    test('enforces raw character, UTF-8, depth, and node budgets', () {
      final tooManyChars = 'x' * (SyncEnvelope.maxRawMessageBytes + 1);
      final tooManyBytes = '${'界' * (SyncEnvelope.maxRawMessageBytes ~/ 3)}界';
      Object? tooDeep;
      for (var index = 0; index < 34; index += 1) {
        tooDeep = <Object?>[tooDeep];
      }
      final tooManyNodes = List<Object?>.filled(
        SyncEnvelope.maxJsonNodes + 1,
        null,
      );

      expect(SyncEnvelope.parse(tooManyChars).failureOrNull, isNotNull);
      expect(
        SyncEnvelope.parse('{"p":1,"t":"20260826010101","d":"$tooManyBytes"}')
            .failureOrNull,
        isNotNull,
      );
      expect(
        SyncEnvelope.parse(<String, Object?>{
          'p': 1,
          't': '20260826010101',
          'd': tooManyChars,
        }).failureOrNull,
        isNotNull,
      );
      expect(
        SyncEnvelope.parse(<String, Object?>{
          'p': 1,
          't': '20260826010101',
          'd': tooDeep,
        }).failureOrNull,
        isNotNull,
      );
      expect(
        SyncEnvelope.parse(<String, Object?>{
          'p': 1,
          't': '20260826010101',
          'd': tooManyNodes,
        }).failureOrNull,
        isNotNull,
      );
    });

    test('deep-freezes payload and never prints it', () {
      final source = <String, Object?>{
        'secret': <Object?>['raw-server-payload'],
      };
      final envelope = SyncEnvelope.parse(<String, Object?>{
        'p': 1,
        't': '20260826010101',
        'd': source,
      }).valueOrNull!;
      (source['secret']! as List<Object?>).add('changed');

      expect(
        () => (envelope.data! as Map<String, Object?>)['x'] = 1,
        throwsUnsupportedError,
      );
      expect(envelope.toString(), isNot(contains('raw-server-payload')));
    });
  });

  group('ProtocolSyncApi', () {
    test('uses exact paths/body and maps code 1/2 batches', () async {
      final responses = <ResponseBody>[
        _jsonBody(<String, Object?>{
          'code': 1,
          'data': <String, Object?>{
            'ts': '20260826010101',
            'ds': <String, Object?>{'0': <Object?>[]},
          },
        }),
        _jsonBody(<String, Object?>{
          'code': 2,
          'data': <String, Object?>{'ts': '20260826010102'},
        }),
      ];
      final adapter = _StubAdapter((_) => responses.removeAt(0));
      final api = ProtocolSyncApi(client: _protocolClient(adapter));

      final all = await api.fetchAll(ClientKind.cashier);
      final increment = await api.fetchIncrement(
        ClientKind.cashier,
        '20260826010101',
      );

      expect(adapter.requests[0].uri.path, '/server/sync_base/all');
      expect(adapter.requests[1].uri.path, '/server/sync_base/increment');
      expect(adapter.encodedBodies[0], anyOf(isEmpty, '{}'));
      expect(jsonDecode(adapter.encodedBodies[1]), <String, Object?>{
        'last_sync_time': '20260826010101',
      });
      expect(all.valueOrNull?.hasChanges, isTrue);
      expect(all.valueOrNull?.cursor, '20260826010101');
      expect(increment.valueOrNull?.hasChanges, isFalse);
      expect(increment.valueOrNull?.cursor, '20260826010102');
    });

    test(
      'rejects invalid cursors, response shapes, and business errors',
      () async {
        final adapter = _StubAdapter(
          (_) => _jsonBody(<String, Object?>{'code': 9, 'msg': 'raw-secret'}),
        );
        final api = ProtocolSyncApi(client: _protocolClient(adapter));

        final cursor = await api.fetchIncrement(ClientKind.cashier, 'bad');
        final business = await api.fetchAll(ClientKind.cashier);

        expect(cursor.failureOrNull?.kind, FailureKind.protocol);
        expect(adapter.calls, 1);
        expect(business.failureOrNull?.kind, FailureKind.business);
        expect(
          '${business.failureOrNull?.safeMessage}|$business',
          isNot(contains('raw-secret')),
        );
      },
    );

    test('rejects code 1 when ds is missing', () async {
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{
          'code': 1,
          'data': <String, Object?>{'ts': '20260826010101'},
        }),
      );
      final api = ProtocolSyncApi(client: _protocolClient(adapter));

      final result = await api.fetchAll(ClientKind.cashier);

      expect(result.failureOrNull?.kind, FailureKind.protocol);
      expect(result.failureOrNull?.code, 'protocol.sync_response_shape');
    });
  });

  group('RealtimeController', () {
    late _FakeScheduler scheduler;
    late _FakeClock clock;
    late _FakeCredentialStore credentials;
    late _FakeSyncApi api;
    late _FakeSocketTransport transport;
    late RealtimeController controller;

    setUp(() {
      scheduler = _FakeScheduler();
      clock = _FakeClock();
      credentials = _FakeCredentialStore(tk: r'tk"quoted');
      api = _FakeSyncApi();
      transport = _FakeSocketTransport();
      controller = RealtimeController(
        config: _config(),
        client: ClientKind.cashier,
        credentialStore: credentials,
        syncApi: api,
        socketTransport: transport,
        monotonicClock: clock.call,
        scheduler: scheduler,
      );
    });

    tearDown(() async {
      await controller.dispose();
    });

    test(
      'sends quoted tk first, preserves base path, reconciles, then online',
      () async {
        final phases = <ConnectionPhase>[];
        final order = <String>[];
        SyncEnvelope? batchEvent;
        final phaseSubscription = controller.phases.listen((phase) {
          phases.add(phase);
          order.add('phase:${phase.name}');
        });
        final eventSubscription = controller.events.listen((event) {
          batchEvent = event;
          order.add('event:${event.type.name}');
        });

        await controller.start();

        expect(
          transport.uris.single.toString(),
          'wss://socket.example/server/sync',
        );
        expect(transport.connections.single.sent, <String>[
          jsonEncode(r'tk"quoted'),
        ]);
        expect(api.allCalls, 1);
        expect(api.incrementCursors, isEmpty);
        expect(controller.cursor, '20260826010101');
        expect(batchEvent?.data, <String, Object?>{});
        expect(controller.phase, ConnectionPhase.online);
        expect(phases, <ConnectionPhase>[
          ConnectionPhase.blocked,
          ConnectionPhase.reconciling,
          ConnectionPhase.online,
        ]);
        expect(phases[1].allowsWrites, isFalse);
        expect(order, <String>[
          'phase:blocked',
          'phase:reconciling',
          'event:data',
          'phase:online',
        ]);
        await phaseSubscription.cancel();
        await eventSubscription.cancel();
      },
    );

    test(
      'buffers live messages until full sync and replays only newer cursors',
      () async {
        final pendingAll = Completer<Result<SyncBatch>>();
        api.allCompleter = pendingAll;
        transport.nextOnSend = (socket) => socket.addJson(<String, Object?>{
          'p': 1,
          't': '20260826010104',
          'd': <String, Object?>{'source': 'first-live'},
        });
        final events = <SyncEnvelope>[];
        final order = <String>[];
        final eventSubscription = controller.events.listen((event) {
          events.add(event);
          order.add('event:${event.cursor}');
        });
        final phaseSubscription = controller.phases.listen(
          (phase) => order.add('phase:${phase.name}'),
        );

        final starting = controller.start();
        await _flush();
        final socket = transport.connections.single;
        socket
          ..addJson(<String, Object?>{'p': 2, 't': '20260826010102', 'd': null})
          ..addJson(<String, Object?>{
            'p': 1,
            't': '20260826010103',
            'd': <String, Object?>{'source': 'overlap'},
          })
          ..addJson(<String, Object?>{
            'p': 1,
            't': '20260826010105',
            'd': <String, Object?>{'source': 'second-live'},
          });
        await _flush();

        expect(api.allCalls, 1);
        expect(api.incrementCursors, isEmpty);
        expect(events, isEmpty);
        expect(controller.cursor, isNull);
        expect(controller.phase, ConnectionPhase.reconciling);

        pendingAll.complete(
          const Success(
            SyncBatch(
              cursor: '20260826010103',
              data: <String, Object?>{'source': 'full'},
              hasChanges: true,
            ),
          ),
        );
        await starting;

        expect(events.map((event) => event.cursor), <String?>[
          '20260826010103',
          '20260826010104',
          '20260826010105',
        ]);
        expect(controller.cursor, '20260826010105');
        expect(order.last, 'phase:online');
        await eventSubscription.cancel();
        await phaseSubscription.cancel();
      },
    );

    test(
      'reconnect snapshots disconnected cursor before immediate socket data',
      () async {
        final events = <SyncEnvelope>[];
        final subscription = controller.events.listen(events.add);
        await controller.start();
        transport.connections.single.disconnect();
        await _flush();

        final pendingIncrement = Completer<Result<SyncBatch>>();
        api.incrementCompleter = pendingIncrement;
        transport.nextOnSend = (socket) => socket.addJson(<String, Object?>{
          'p': 1,
          't': '20260826010104',
          'd': <String, Object?>{'source': 'live'},
        });
        scheduler.elapse(const Duration(seconds: 3));
        await _flush();

        expect(api.incrementCursors, <String>['20260826010101']);
        expect(events.map((event) => event.cursor), <String?>[
          '20260826010101',
        ]);

        pendingIncrement.complete(
          const Success(
            SyncBatch(
              cursor: '20260826010103',
              data: <String, Object?>{'source': 'increment'},
              hasChanges: true,
            ),
          ),
        );
        await _flush();

        expect(events.map((event) => event.cursor), <String?>[
          '20260826010101',
          '20260826010103',
          '20260826010104',
        ]);
        expect(controller.cursor, '20260826010104');
        expect(controller.phase, ConnectionPhase.online);
        await subscription.cancel();
      },
    );

    test('drops buffered messages from a stale generation', () async {
      final pendingAll = Completer<Result<SyncBatch>>();
      api.allCompleter = pendingAll;
      transport.nextOnSend = (socket) => socket.addJson(<String, Object?>{
        'p': 1,
        't': '20260826010109',
        'd': <String, Object?>{'source': 'stale'},
      });
      final events = <SyncEnvelope>[];
      final subscription = controller.events.listen(events.add);

      final firstStart = controller.start();
      await _flush();
      transport.connections.single.fail();
      await _flush();
      pendingAll.complete(
        const Success(
          SyncBatch(
            cursor: '20260826010101',
            data: <String, Object?>{'source': 'old-batch'},
            hasChanges: true,
          ),
        ),
      );
      await firstStart;

      expect(events, isEmpty);
      expect(controller.cursor, isNull);
      api.allCompleter = null;
      scheduler.elapse(const Duration(seconds: 3));
      await _flush();

      expect(events.map((event) => event.cursor), <String?>['20260826010101']);
      expect(controller.cursor, '20260826010101');
      expect(controller.phase, ConnectionPhase.online);
      await subscription.cancel();
    });

    test(
      'bounded reconciliation buffer overflows into one safe reconnect',
      () async {
        final pendingAll = Completer<Result<SyncBatch>>();
        api.allCompleter = pendingAll;
        final failures = <AppFailure>[];
        final subscription = controller.failures.listen(failures.add);
        final starting = controller.start();
        await _flush();
        final socket = transport.connections.single;

        for (
          var index = 0;
          index <= RealtimeController.maxBufferedEnvelopeCount;
          index += 1
        ) {
          socket.addJson(<String, Object?>{
            'p': 2,
            't': '2026082601${index.toString().padLeft(4, '0')}',
            'd': null,
          });
        }
        await _flush();

        expect(controller.phase, ConnectionPhase.reconciling);
        expect(controller.cursor, isNull);
        expect(failures.last.code, 'realtime.reconciliation_buffer_overflow');
        expect(scheduler.activeDelays, <Duration>[const Duration(seconds: 3)]);
        pendingAll.complete(
          const Success(
            SyncBatch(
              cursor: '20260826010101',
              data: <String, Object?>{},
              hasChanges: true,
            ),
          ),
        );
        await starting;
        api.allCompleter = null;
        scheduler.elapse(const Duration(seconds: 3));
        await _flush();
        expect(api.allCalls, 2);
        expect(api.incrementCursors, isEmpty);
        expect(controller.phase, ConnectionPhase.online);
        await subscription.cancel();
      },
    );

    test('reconciliation buffer also enforces its byte budget', () async {
      final pendingAll = Completer<Result<SyncBatch>>();
      api.allCompleter = pendingAll;
      final failures = <AppFailure>[];
      final subscription = controller.failures.listen(failures.add);
      final starting = controller.start();
      await _flush();
      final socket = transport.connections.single;
      final payload =
          'x' * (RealtimeController.maxBufferedEnvelopeBytes ~/ 3 + 1024);

      for (var index = 1; index <= 3; index += 1) {
        socket.addRaw(<String, Object?>{
          'p': 1,
          't': '2026082601010$index',
          'd': payload,
        });
      }
      await _flush();

      expect(failures.last.code, 'realtime.reconciliation_buffer_overflow');
      expect(scheduler.activeDelays, <Duration>[const Duration(seconds: 3)]);
      pendingAll.complete(
        const Success(
          SyncBatch(
            cursor: '20260826010101',
            data: <String, Object?>{},
            hasChanges: true,
          ),
        ),
      );
      await starting;
      await subscription.cancel();
    });

    test(
      'no-change batch updates cursor without emitting a data event',
      () async {
        api.allResult = const Success(
          SyncBatch(cursor: '20260826010102', data: null, hasChanges: false),
        );
        final events = <SyncEnvelope>[];
        final subscription = controller.events.listen(events.add);

        await controller.start();

        expect(events, isEmpty);
        expect(controller.cursor, '20260826010102');
        expect(controller.phase, ConnectionPhase.online);
        await subscription.cancel();
      },
    );

    test(
      'uses increment on reconnect and ignores stale socket callbacks',
      () async {
        await controller.start();
        final first = transport.connections.single;
        first.addJson(<String, Object?>{
          'p': 1,
          't': '20260826010105',
          'd': <String, Object?>{'1': <Object?>[]},
        });
        await _flush();
        first.fail();
        first.fail();
        await _flush();

        expect(controller.phase, ConnectionPhase.reconciling);
        expect(scheduler.activeDelays, <Duration>[const Duration(seconds: 3)]);
        scheduler.elapse(const Duration(seconds: 3));
        await _flush();

        expect(transport.connections, hasLength(2));
        expect(api.incrementCursors, <String>['20260826010105']);
        expect(controller.phase, ConnectionPhase.online);
        first.addJson(<String, Object?>{
          'p': 1,
          't': '20991231235959',
          'd': null,
        });
        await _flush();
        expect(controller.cursor, isNot('20991231235959'));
      },
    );

    test(
      'times out strictly after 65 seconds and schedules one reconnect',
      () async {
        await controller.start();

        clock.advance(const Duration(seconds: 65));
        scheduler.elapse(const Duration(seconds: 65));
        await _flush();
        expect(controller.phase, ConnectionPhase.online);

        clock.advance(const Duration(microseconds: 1));
        scheduler.elapse(const Duration(microseconds: 1));
        await _flush();
        expect(controller.phase, ConnectionPhase.reconciling);
        expect(scheduler.activeDelays, <Duration>[const Duration(seconds: 3)]);
      },
    );

    test('messages reset heartbeat and update cursor/events', () async {
      final events = <SyncEnvelope>[];
      final subscription = controller.events.listen(events.add);
      await controller.start();
      final socket = transport.connections.single;
      clock.advance(const Duration(seconds: 64));
      socket.addJson(<String, Object?>{
        'p': 2,
        't': '20260826010109',
        'd': null,
      });
      await _flush();
      scheduler.elapse(const Duration(seconds: 65));
      clock.advance(const Duration(seconds: 65));
      await _flush();

      expect(events.map((event) => event.type), <SyncEventType>[
        SyncEventType.data,
        SyncEventType.heartbeat,
      ]);
      expect(controller.cursor, '20260826010109');
      expect(controller.phase, ConnectionPhase.online);
      await subscription.cancel();
    });

    for (final authText in const <String>[
      '第一个消息必须为授权信息',
      '未发现授权信息',
      '授权信息未找到或已过期',
    ]) {
      test(
        'blocks and conditionally clears tk for exact auth text: $authText',
        () async {
          await controller.start();
          final sentTk = credentials.tk;
          credentials.tk = 'new-token';
          transport.connections.single.addJson(<String, Object?>{
            'p': 3,
            'd': authText,
          });
          await _flush();

          expect(credentials.clearExpected, <String?>[sentTk]);
          expect(credentials.tk, 'new-token');
          expect(controller.phase, ConnectionPhase.blocked);
          expect(scheduler.activeDelays, isEmpty);
        },
      );
    }

    test('other server errors are sanitized and reconnect', () async {
      final events = <SyncEnvelope>[];
      final failures = <AppFailure>[];
      final eventSubscription = controller.events.listen(events.add);
      final failureSubscription = controller.failures.listen(failures.add);
      await controller.start();
      transport.connections.single.addJson(<String, Object?>{
        'p': 3,
        'd': 'raw-server-secret',
      });
      await _flush();

      expect(controller.phase, ConnectionPhase.reconciling);
      expect(events.last.toString(), isNot(contains('raw-server-secret')));
      expect(events.last.data, isNot('raw-server-secret'));
      expect(failures.single.safeMessage, isNot(contains('raw-server-secret')));
      expect(scheduler.activeDelays, <Duration>[const Duration(seconds: 3)]);
      await eventSubscription.cancel();
      await failureSubscription.cancel();
    });

    test(
      'no token and credential read exception block without a socket',
      () async {
        credentials.tk = '   ';
        await controller.start();
        expect(controller.phase, ConnectionPhase.blocked);
        expect(transport.connections, isEmpty);

        await controller.stop();
        credentials.throwOnRead = true;
        await controller.start();
        expect(controller.phase, ConnectionPhase.blocked);
        expect(transport.connections, isEmpty);
      },
    );

    test('oversized tk is rejected before opening a socket', () async {
      credentials.tk = 'x' * 4097;

      await controller.start();

      expect(controller.phase, ConnectionPhase.blocked);
      expect(transport.connections, isEmpty);
    });

    test(
      'connect, ready, send, sync, and malformed failures recover safely',
      () async {
        transport.connectError = StateError('raw-connect-secret');
        await controller.start();
        expect(controller.phase, ConnectionPhase.reconciling);
        expect(scheduler.activeDelays, <Duration>[const Duration(seconds: 3)]);

        transport.connectError = null;
        transport.readyError = StateError('raw-ready-secret');
        scheduler.elapse(const Duration(seconds: 3));
        await _flush();
        expect(controller.phase, ConnectionPhase.reconciling);

        transport.readyError = null;
        transport.sendError = StateError('raw-send-secret');
        scheduler.elapse(const Duration(seconds: 3));
        await _flush();
        expect(controller.phase, ConnectionPhase.reconciling);

        transport.sendError = null;
        api.allResult = const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'network.synthetic',
            safeMessage: '安全的测试故障',
          ),
        );
        scheduler.elapse(const Duration(seconds: 3));
        await _flush();
        expect(controller.phase, ConnectionPhase.reconciling);

        api.allResult = const Success(
          SyncBatch(
            cursor: '20260826010101',
            data: <String, Object?>{},
            hasChanges: true,
          ),
        );
        scheduler.elapse(const Duration(seconds: 3));
        await _flush();
        expect(controller.phase, ConnectionPhase.online);
        transport.connections.last.addRaw('{not-json raw-message-secret');
        await _flush();
        expect(controller.phase, ConnectionPhase.reconciling);
        expect(scheduler.activeDelays, <Duration>[const Duration(seconds: 3)]);
      },
    );

    test(
      'socket close reconnects once and reconciles from its cursor',
      () async {
        await controller.start();
        final socket = transport.connections.single;
        socket.addJson(<String, Object?>{
          'p': 2,
          't': '20260826010107',
          'd': null,
        });
        await _flush();
        socket.disconnect();
        await _flush();
        api.incrementResult = const Success(
          SyncBatch(
            cursor: '20260826010108',
            data: <String, Object?>{},
            hasChanges: false,
          ),
        );

        expect(controller.phase, ConnectionPhase.reconciling);
        expect(scheduler.activeDelays, <Duration>[const Duration(seconds: 3)]);
        scheduler.elapse(const Duration(seconds: 3));
        await _flush();
        expect(api.incrementCursors, <String>['20260826010107']);
        expect(controller.phase, ConnectionPhase.online);
      },
    );

    test(
      'slow stale block cleanup cannot flip a restarted controller',
      () async {
        final closeCompleter = Completer<void>();
        transport.nextCloseCompleter = closeCompleter;
        api.allResult = const FailureResult(
          AppFailure(
            kind: FailureKind.authentication,
            code: 'authentication.synthetic',
            safeMessage: '测试授权失败',
          ),
        );

        final firstStart = controller.start();
        await _flush();
        expect(controller.phase, ConnectionPhase.blocked);

        api.allResult = const Success(
          SyncBatch(
            cursor: '20260826010101',
            data: <String, Object?>{},
            hasChanges: true,
          ),
        );
        await controller.start();
        expect(controller.phase, ConnectionPhase.online);

        closeCompleter.complete();
        await firstStart;
        await _flush();
        expect(controller.phase, ConnectionPhase.online);
      },
    );

    test(
      'slow stale stop cleanup cannot flip a restarted controller',
      () async {
        final closeCompleter = Completer<void>();
        addTearDown(() {
          if (!closeCompleter.isCompleted) closeCompleter.complete();
        });
        transport.nextCloseCompleter = closeCompleter;
        await controller.start();

        final stopping = controller.stop();
        await _flush();
        expect(controller.phase, ConnectionPhase.blocked);

        await controller.start();
        expect(controller.phase, ConnectionPhase.online);

        closeCompleter.complete();
        await stopping;
        await _flush();
        expect(controller.phase, ConnectionPhase.online);
      },
    );

    test(
      'stop is idempotent, prevents callbacks, and supports clean restart',
      () async {
        await controller.start();
        final first = transport.connections.single;
        await controller.stop();
        await controller.stop();
        first.addJson(<String, Object?>{
          'p': 1,
          't': '20991231235959',
          'd': null,
        });
        scheduler.elapse(const Duration(days: 1));
        await _flush();

        expect(controller.phase, ConnectionPhase.blocked);
        expect(controller.cursor, '20260826010101');
        expect(transport.connections, hasLength(1));

        await controller.start();
        expect(transport.connections, hasLength(2));
        expect(controller.phase, ConnectionPhase.online);
      },
    );

    test('dispose closes streams and ignores later start', () async {
      var phaseDone = false;
      var eventDone = false;
      final phaseSubscription = controller.phases.listen(
        (_) {},
        onDone: () => phaseDone = true,
      );
      final eventSubscription = controller.events.listen(
        (_) {},
        onDone: () => eventDone = true,
      );
      await controller.start();
      await controller.dispose();
      await _flush();
      await controller.start();

      expect(phaseDone, isTrue);
      expect(eventDone, isTrue);
      expect(transport.connections, hasLength(1));
      await phaseSubscription.cancel();
      await eventSubscription.cancel();
    });
  });
}

ApiConfig _config() => ApiConfig(
  apiBase: Uri.parse('https://api.example/server'),
  onlineBase: Uri.parse('https://online.example/server'),
  websocketBase: Uri.parse('wss://socket.example/server'),
);

ProtocolClient _protocolClient(_StubAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  var now = 0;
  return ProtocolClient(
    dio: dio,
    config: _config(),
    credentialStore: _FakeCredentialStore(tk: 'tk'),
    requestGate: RequestGate(
      clock: () => DateTime.fromMillisecondsSinceEpoch(now++),
    ),
  );
}

ResponseBody _jsonBody(Object? value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

typedef _Responder = FutureOr<ResponseBody> Function(RequestOptions request);

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._responder);

  final _Responder _responder;
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

final class _FakeCredentialStore implements CredentialStore {
  _FakeCredentialStore({this.tk});

  String? tk;
  String? stk;
  bool throwOnRead = false;
  final List<String?> clearExpected = <String?>[];

  @override
  Future<CredentialSnapshot> readSnapshot() async {
    if (throwOnRead) throw StateError('raw-credential-secret');
    return CredentialSnapshot(tk: tk, stk: stk);
  }

  @override
  Future<String?> readTk() async => tk;

  @override
  Future<String?> readStk() async => stk;

  @override
  Future<void> writeTk(String value) async => tk = value;

  @override
  Future<void> writeStk(String value) async => stk = value;

  @override
  Future<void> clearTk() async => tk = null;

  @override
  Future<void> clearStk() async => stk = null;

  @override
  Future<void> clearTkIfMatches(String? expected) async {
    clearExpected.add(expected);
    if (tk == expected) tk = null;
  }

  @override
  Future<void> clearStkIfMatches(String? expected) async {
    if (stk == expected) stk = null;
  }
}

final class _FakeSyncApi implements SyncApi {
  int allCalls = 0;
  final List<String> incrementCursors = <String>[];
  Completer<Result<SyncBatch>>? allCompleter;
  Completer<Result<SyncBatch>>? incrementCompleter;
  Result<SyncBatch> allResult = const Success(
    SyncBatch(
      cursor: '20260826010101',
      data: <String, Object?>{},
      hasChanges: true,
    ),
  );
  Result<SyncBatch> incrementResult = const Success(
    SyncBatch(
      cursor: '20260826010106',
      data: <String, Object?>{},
      hasChanges: false,
    ),
  );

  @override
  Future<Result<SyncBatch>> fetchAll(ClientKind client) async {
    allCalls += 1;
    return allCompleter?.future ?? allResult;
  }

  @override
  Future<Result<SyncBatch>> fetchIncrement(
    ClientKind client,
    String lastSyncTime,
  ) async {
    incrementCursors.add(lastSyncTime);
    return incrementCompleter?.future ?? incrementResult;
  }
}

final class _FakeSocketTransport implements SocketTransport {
  final List<Uri> uris = <Uri>[];
  final List<_FakeSocketConnection> connections = <_FakeSocketConnection>[];
  Object? connectError;
  Object? readyError;
  Object? sendError;
  Completer<void>? nextCloseCompleter;
  void Function(_FakeSocketConnection socket)? nextOnSend;

  @override
  Future<SocketConnection> connect(Uri uri) async {
    final error = connectError;
    if (error != null) throw error;
    uris.add(uri);
    final sendCallback = nextOnSend;
    late final _FakeSocketConnection connection;
    connection = _FakeSocketConnection(
      readyError: readyError,
      sendError: sendError,
      closeCompleter: nextCloseCompleter,
      onSend: () => sendCallback?.call(connection),
    );
    nextCloseCompleter = null;
    nextOnSend = null;
    connections.add(connection);
    return connection;
  }
}

final class _FakeSocketConnection implements SocketConnection {
  _FakeSocketConnection({
    this.readyError,
    this.sendError,
    this.closeCompleter,
    this.onSend,
  });

  final Object? readyError;
  final Object? sendError;
  final Completer<void>? closeCompleter;
  final void Function()? onSend;
  final StreamController<Object?> _incoming =
      StreamController<Object?>.broadcast(sync: true);
  final List<String> sent = <String>[];
  int closeCalls = 0;

  @override
  Future<void> get ready async {
    final error = readyError;
    if (error != null) throw error;
  }

  @override
  Stream<Object?> get incoming => _incoming.stream;

  @override
  Future<void> sendText(String value) async {
    final error = sendError;
    if (error != null) throw error;
    sent.add(value);
    onSend?.call();
  }

  @override
  Future<void> close() async {
    closeCalls += 1;
    await closeCompleter?.future;
  }

  void addJson(Object? value) => _incoming.add(jsonEncode(value));
  void addRaw(Object? value) => _incoming.add(value);
  void fail() => _incoming.addError(StateError('synthetic socket failure'));
  void disconnect() => _incoming.close();
}

final class _FakeClock {
  Duration now = Duration.zero;
  Duration call() => now;
  void advance(Duration duration) => now += duration;
}

final class _FakeScheduler implements Scheduler {
  Duration _now = Duration.zero;
  final List<_FakeScheduledHandle> _handles = <_FakeScheduledHandle>[];

  List<Duration> get activeDelays => <Duration>[
    for (final handle in _handles)
      if (!handle.isCancelled && !handle.hasRun) handle.due - _now,
  ];

  @override
  ScheduledHandle schedule(Duration delay, void Function() callback) {
    final handle = _FakeScheduledHandle(_now + delay, callback);
    _handles.add(handle);
    return handle;
  }

  void elapse(Duration duration) {
    _now += duration;
    while (true) {
      _FakeScheduledHandle? next;
      for (final handle in _handles) {
        if (!handle.isCancelled && !handle.hasRun && handle.due <= _now) {
          if (next == null || handle.due < next.due) next = handle;
        }
      }
      if (next == null) return;
      next.hasRun = true;
      next.callback();
    }
  }
}

final class _FakeScheduledHandle implements ScheduledHandle {
  _FakeScheduledHandle(this.due, this.callback);

  final Duration due;
  final void Function() callback;
  bool isCancelled = false;
  bool hasRun = false;

  @override
  void cancel() => isCancelled = true;
}

Future<void> _flush() async {
  for (var index = 0; index < 8; index += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}
