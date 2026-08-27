import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';
import 'package:shouyin_android/main.dart';

void main() {
  testWidgets('invalid config creates no shell or secure/network dependency', (
    tester,
  ) async {
    final factory = _LifecycleFactory();

    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: AppRuntimeConfiguration.fromValues(
          apiBase: '',
          onlineBase: 'https://online.example.test',
          websocketBase: 'invalid',
        ),
        dependenciesFactory: factory,
      ),
    );

    expect(find.text('应用配置不可用'), findsOneWidget);
    expect(factory.createCalls, 0);
    expect(factory.routerCreateCalls, 0);
  });

  testWidgets('root owns lazy auth realtime and disposal lifecycle', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
        initialLocation: '/diagnostics',
      ),
    );
    await tester.pumpAndSettle();
    final dependencies = factory.dependencies;

    expect(factory.createCalls, 1);
    expect(factory.routerCreateCalls, 1);
    expect(dependencies.startCalls, 0);
    expect(dependencies.realtimeCreated, isFalse);
    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      '收银 Android 客户端',
    );

    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 1);
    expect(dependencies.realtimeCreated, isTrue);
    expect(find.byKey(DiagnosticPanel.narrowLayoutKey), findsOneWidget);
    expect(find.text('收银 Android 客户端'), findsOneWidget);

    GoRouter.of(tester.element(find.text('收银 Android 客户端')))
        .go('/diagnostics/devices');
    await tester.pumpAndSettle();
    expect(find.text('设备检查将在 Task 11 中实现'), findsOneWidget);
    GoRouter.of(tester.element(find.text('收银 Android 客户端'))).go('/diagnostics');
    await tester.pumpAndSettle();

    await tester.pump();
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 1);

    await tester.runAsync(dependencies.logout);
    await tester.pumpAndSettle();
    expect(dependencies.stopCalls, 1);
    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => dependencies.disposed.future);
    expect(dependencies.disposeCalls, 1);
    expect(dependencies.stopCalls, 1);
    expect(dependencies.dioCloseCalls, 1);
    expect(dependencies.hasOpenStreams, isFalse);
    expect(factory.routerDisposeCalls, 1);
  });

  testWidgets('authenticated unmount stops and disposes resources once', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();
    final dependencies = factory.dependencies;
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => dependencies.disposed.future);

    expect(dependencies.stopCalls, 1);
    expect(dependencies.disposeCalls, 1);
    expect(dependencies.dioCloseCalls, 1);
    expect(dependencies.hasOpenStreams, isFalse);
    expect(factory.routerDisposeCalls, 1);
  });
}

final AppRuntimeConfiguration _validEnvironment =
    AppRuntimeConfiguration.fromValues(
      apiBase: 'https://api.example.test/server',
      onlineBase: 'https://online.example.test/server',
      websocketBase: 'wss://socket.example.test',
    );

final class _LifecycleFactory implements ShellDependenciesFactory {
  int createCalls = 0;
  int routerCreateCalls = 0;
  int routerDisposeCalls = 0;
  late _LifecycleDependencies dependencies;

  @override
  ShellDependencies create(ApiConfig config) {
    createCalls += 1;
    dependencies = _LifecycleDependencies(config);
    return dependencies;
  }

  @override
  void onRouterCreated() => routerCreateCalls += 1;

  @override
  void onRouterDisposed() => routerDisposeCalls += 1;
}

final class _LifecycleDependencies implements ShellDependencies {
  _LifecycleDependencies(ApiConfig config)
    : _store = _MemoryCredentialStore(),
      _dio = Dio() {
    _dio.httpClientAdapter = _AuthAdapter();
    final client = ProtocolClient(
      dio: _dio,
      config: config,
      credentialStore: _store,
      requestGate: RequestGate(clock: DateTime.now),
    );
    sessionRepository = SessionRepository(
      api: SessionApi(client: client),
      credentialStore: _store,
    );
  }

  final _MemoryCredentialStore _store;
  final Dio _dio;
  final StreamController<ConnectionPhase> _phases =
      StreamController<ConnectionPhase>.broadcast(sync: true);
  final StreamController<AppFailure> _failures =
      StreamController<AppFailure>.broadcast(sync: true);
  final Completer<void> disposed = Completer<void>();

  @override
  late final SessionRepository sessionRepository;
  ConnectionPhase _phase = ConnectionPhase.blocked;
  bool _active = false;
  bool realtimeCreated = false;
  int startCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;
  int dioCloseCalls = 0;

  bool get hasOpenStreams => !_phases.isClosed || !_failures.isClosed;

  @override
  ConnectionPhase get connectionPhase => _phase;

  @override
  Stream<ConnectionPhase> get connectionPhases => _phases.stream;

  @override
  Stream<AppFailure> get realtimeFailures => _failures.stream;

  Future<void> authenticate() async {
    await sessionRepository.authorizeMachine('TERM-001');
    await sessionRepository.login(
      account: 'employee',
      password: 'synthetic-password',
      type: EmployeeLoginType.account,
    );
  }

  Future<void> logout() async {
    await sessionRepository.logout();
  }

  @override
  Future<void> startRealtime() async {
    startCalls += 1;
    realtimeCreated = true;
    _active = true;
    _phase = ConnectionPhase.online;
    _phases.add(_phase);
  }

  @override
  Future<void> stopRealtime() async {
    if (!_active) return;
    stopCalls += 1;
    _active = false;
    _phase = ConnectionPhase.blocked;
    _phases.add(_phase);
  }

  @override
  Future<void> dispose() async {
    if (disposeCalls != 0) return;
    disposeCalls += 1;
    await stopRealtime();
    await sessionRepository.close();
    await _phases.close();
    await _failures.close();
    _dio.close(force: true);
    dioCloseCalls += 1;
    disposed.complete();
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
