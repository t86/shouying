import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';
import 'package:shouyin_windows/main.dart';

void main() {
  test('authenticated fake composition starts and disposes', () async {
    final harness = await _Harness.authenticated().timeout(
      const Duration(seconds: 2),
    );
    expect(harness.repository.currentUser, isNotNull);
    await harness.dispose().timeout(const Duration(seconds: 2));
  });

  testWidgets('invalid runtime configuration is visible without composition', (
    tester,
  ) async {
    await tester.pumpWidget(
      ShouyinWindowsApp(
        environment: AppRuntimeConfiguration.fromValues(
          apiBase: '',
          onlineBase: 'https://online.example.test',
          websocketBase: 'not-a-websocket',
        ),
      ),
    );

    expect(find.text('应用配置不可用'), findsOneWidget);
    expect(find.textContaining('SHOUYIN_API_BASE'), findsOneWidget);
    expect(find.textContaining('SHOUYIN_WS_BASE'), findsOneWidget);
    expect(find.byType(ProviderScope), findsNothing);
  });

  testWidgets('unauthenticated diagnostics route redirects to login', (
    tester,
  ) async {
    final harness = await _Harness.unauthenticated();
    await tester.pumpWidget(
      ShouyinWindowsApp(
        environment: harness.environment,
        credentialStore: harness.store,
        sessionRepository: harness.repository,
        realtimeController: harness.realtime,
        initialLocation: '/diagnostics',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      '收银 Windows 客户端',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await harness.dispose();
  });

  testWidgets('authenticated login route redirects to wide diagnostics', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final harness = (await tester.runAsync(_Harness.authenticated))!;
    await tester.pumpWidget(
      ShouyinWindowsApp(
        environment: harness.environment,
        credentialStore: harness.store,
        sessionRepository: harness.repository,
        realtimeController: harness.realtime,
        initialLocation: '/login',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('收银 Windows 客户端'), findsOneWidget);
    expect(find.byKey(DiagnosticPanel.wideLayoutKey), findsOneWidget);
    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(harness.dispose);
  });

  testWidgets('device diagnostics route is refresh-safe placeholder', (
    tester,
  ) async {
    final harness = (await tester.runAsync(_Harness.authenticated))!;
    await tester.pumpWidget(
      ShouyinWindowsApp(
        environment: harness.environment,
        credentialStore: harness.store,
        sessionRepository: harness.repository,
        realtimeController: harness.realtime,
        initialLocation: '/diagnostics/devices',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('设备检查将在 Task 11 中实现'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(harness.dispose);
  });
}

final class _Harness {
  _Harness({
    required this.environment,
    required this.store,
    required this.dio,
    required this.repository,
    required this.realtime,
  });

  final AppRuntimeConfiguration environment;
  final _MemoryCredentialStore store;
  final Dio dio;
  final SessionRepository repository;
  final RealtimeController realtime;

  static Future<_Harness> unauthenticated() => _create(false);
  static Future<_Harness> authenticated() => _create(true);

  static Future<_Harness> _create(bool authenticate) async {
    final environment = AppRuntimeConfiguration.fromValues(
      apiBase: 'https://api.example.test/server',
      onlineBase: 'https://online.example.test/server',
      websocketBase: 'wss://socket.example.test',
    );
    final config = environment.config!;
    final store = _MemoryCredentialStore();
    final dio = Dio()..httpClientAdapter = _AuthAdapter();
    final client = ProtocolClient(
      dio: dio,
      config: config,
      credentialStore: store,
      requestGate: RequestGate(clock: DateTime.now),
    );
    final repository = SessionRepository(
      api: SessionApi(client: client),
      credentialStore: store,
    );
    if (authenticate) {
      await repository.authorizeMachine('TERM-001');
      await repository.login(
        account: 'employee',
        password: 'synthetic-password',
        type: EmployeeLoginType.account,
      );
    }
    final realtime = RealtimeController(
      config: config,
      client: ClientKind.cashier,
      credentialStore: store,
      syncApi: _FakeSyncApi(),
      socketTransport: _FakeSocketTransport(),
    );
    return _Harness(
      environment: environment,
      store: store,
      dio: dio,
      repository: repository,
      realtime: realtime,
    );
  }

  Future<void> dispose() async {
    await realtime.dispose();
    await repository.close();
    dio.close(force: true);
  }
}

final class _AuthAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) await requestStream.drain<void>();
    final body = options.path.endsWith('/term/auth')
        ? <String, Object?>{
            'code': 1,
            'data': <String, Object?>{
              'tk': 'synthetic-tk',
              'am': 8,
              'id': 'machine-1',
              'n': 'Front Counter',
            },
          }
        : <String, Object?>{
            'code': 1,
            'data': <String, Object?>{
              'emp_id': 'employee-1',
              'name': 'Synthetic Employee',
              'station_id': 'station-1',
            },
          };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _MemoryCredentialStore implements CredentialStore {
  String? _tk;
  String? _stk;

  @override
  Future<void> clearStk() async => _stk = null;
  @override
  Future<void> clearStkIfMatches(String? expected) async {
    if (_stk == expected) _stk = null;
  }

  @override
  Future<void> clearTk() async => _tk = null;
  @override
  Future<void> clearTkIfMatches(String? expected) async {
    if (_tk == expected) _tk = null;
  }

  @override
  Future<String?> readStk() async => _stk;
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      CredentialSnapshot(tk: _tk, stk: _stk);
  @override
  Future<String?> readTk() async => _tk;
  @override
  Future<void> writeStk(String value) async => _stk = value;
  @override
  Future<void> writeTk(String value) async => _tk = value;
}

final class _FakeSyncApi implements SyncApi {
  @override
  Future<Result<SyncBatch>> fetchAll(ClientKind client) async => const Success(
    SyncBatch(cursor: '20260827000000', data: null, hasChanges: false),
  );
  @override
  Future<Result<SyncBatch>> fetchIncrement(
    ClientKind client,
    String lastSyncTime,
  ) => fetchAll(client);
}

final class _FakeSocketTransport implements SocketTransport {
  @override
  Future<SocketConnection> connect(Uri uri) async => _FakeSocketConnection();
}

final class _FakeSocketConnection implements SocketConnection {
  final StreamController<Object?> _incoming = StreamController<Object?>();
  @override
  Stream<Object?> get incoming => _incoming.stream;
  @override
  Future<void> get ready async {}
  @override
  Future<void> sendText(String value) async {}
  @override
  Future<void> close() => _incoming.close();
}
