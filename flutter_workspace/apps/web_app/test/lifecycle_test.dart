import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:card_table/card_table.dart';
import 'package:design_system/design_system.dart';
import 'package:device_bridge_web/device_bridge_web.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';
import 'package:shouyin_web/main.dart';

void main() {
  test('web security accepts secure same-origin endpoint subtrees', () {
    final environment = AppRuntimeConfiguration.fromValues(
      apiBase: 'https://pos.example.test/api',
      onlineBase: 'https://pos.example.test/online',
      websocketBase: 'wss://pos.example.test/sync',
      servingOrigin: Uri.parse('https://pos.example.test/shouyin-v2/'),
    );
    expect(environment.config, isNotNull);
  });

  test('web security rejects insecure default and cross origin or port', () {
    for (final environment in <AppRuntimeConfiguration>[
      AppRuntimeConfiguration.fromValues(
        apiBase: 'http://pos.example.test/server',
        onlineBase: 'http://pos.example.test/server',
        websocketBase: 'ws://pos.example.test/server',
        servingOrigin: Uri.parse('http://pos.example.test/'),
      ),
      AppRuntimeConfiguration.fromValues(
        apiBase: 'https://other.example.test/server',
        onlineBase: 'https://pos.example.test/server',
        websocketBase: 'wss://pos.example.test/server',
        servingOrigin: Uri.parse('https://pos.example.test/'),
      ),
      AppRuntimeConfiguration.fromValues(
        apiBase: 'https://pos.example.test:444/server',
        onlineBase: 'https://pos.example.test/server',
        websocketBase: 'wss://pos.example.test/server',
        servingOrigin: Uri.parse('https://pos.example.test/'),
      ),
    ]) {
      expect(environment.config, isNull);
      expect(environment.invalidKeys, contains('SHOUYIN_WEB_SECURITY'));
    }
  });

  test('web security permits only explicitly enabled same-origin loopback', () {
    final local = AppRuntimeConfiguration.fromValues(
      apiBase: 'http://127.0.0.1:8183/api/server',
      onlineBase: 'http://127.0.0.1:8183/online/server',
      websocketBase: 'ws://127.0.0.1:8183/socket/server',
      servingOrigin: Uri.parse('http://127.0.0.1:8183/'),
      allowInsecureLoopback: true,
    );
    expect(local.config, isNotNull);

    for (final rejected in <AppRuntimeConfiguration>[
      AppRuntimeConfiguration.fromValues(
        apiBase: 'http://127.0.0.1:8183/api/server',
        onlineBase: 'http://127.0.0.1:8183/online/server',
        websocketBase: 'ws://127.0.0.1:8183/socket/server',
        servingOrigin: Uri.parse('http://127.0.0.1:8183/'),
      ),
      AppRuntimeConfiguration.fromValues(
        apiBase: 'http://dev.example.test/api/server',
        onlineBase: 'http://dev.example.test/online/server',
        websocketBase: 'ws://dev.example.test/socket/server',
        servingOrigin: Uri.parse('http://dev.example.test/'),
        allowInsecureLoopback: true,
      ),
      AppRuntimeConfiguration.fromValues(
        apiBase: 'http://127.0.0.1:8184/api/server',
        onlineBase: 'http://127.0.0.1:8183/online/server',
        websocketBase: 'ws://127.0.0.1:8183/socket/server',
        servingOrigin: Uri.parse('http://127.0.0.1:8183/'),
        allowInsecureLoopback: true,
      ),
    ]) {
      expect(rejected.config, isNull);
      expect(rejected.invalidKeys, contains('SHOUYIN_WEB_SECURITY'));
    }
  });

  testWidgets('loopback development selects a system before employee login', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    final environment = AppRuntimeConfiguration.fromValues(
      apiBase: 'http://127.0.0.1:8183/dev-api/server',
      onlineBase: 'http://127.0.0.1:8183/online/server',
      websocketBase: 'ws://127.0.0.1:8183/socket/server',
      servingOrigin: Uri.parse('http://127.0.0.1:8183/'),
      allowInsecureLoopback: true,
      developmentSystemSelection: true,
    );

    await tester.pumpWidget(
      ShouyinWebApp(environment: environment, dependenciesFactory: factory),
    );
    await tester.pumpAndSettle();

    expect(environment.developmentSystemSelection, isTrue);
    expect(find.byType(BusinessSystemSelectionScreen), findsOneWidget);
    expect(factory.dependencies.adapter.termAuthCalls, 0);
    await tester.tap(find.byKey(BusinessSystemSelectionScreen.cashierKey));
    await tester.pumpAndSettle();

    expect(factory.dependencies.adapter.termAuthCalls, 1);
    expect(factory.dependencies.sessionRepository.currentMachine, isNotNull);
    expect(
      factory.dependencies.sessionRepository.currentMachine?.client,
      ClientKind.cashier,
    );
    expect(find.byKey(LoginScreen.employeeFieldsKey), findsOneWidget);
    expect(find.byKey(LoginScreen.machineFieldsKey), findsNothing);
    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsNothing);
    expect(find.byKey(LoginScreen.accountFieldKey), findsOneWidget);
    expect(find.byKey(LoginScreen.passwordFieldKey), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => factory.dependencies.disposed.future);
  });

  test('development system selection cannot escape loopback debug mode', () {
    final secure = AppRuntimeConfiguration.fromValues(
      apiBase: 'https://pos.example.test/api',
      onlineBase: 'https://pos.example.test/online',
      websocketBase: 'wss://pos.example.test/socket',
      servingOrigin: Uri.parse('https://pos.example.test/'),
      developmentSystemSelection: true,
    );
    expect(secure.config, isNotNull);
    expect(secure.developmentSystemSelection, isFalse);
  });

  for (final (system, buttonKey, expectedTitle)
      in <(BusinessSystem, Key, String)>[
        (
          BusinessSystem.booking,
          BusinessSystemSelectionScreen.bookingKey,
          '预定 · 卡台列表',
        ),
        (
          BusinessSystem.order,
          BusinessSystemSelectionScreen.orderKey,
          '点单 · 卡台列表',
        ),
        (
          BusinessSystem.cashier,
          BusinessSystemSelectionScreen.cashierKey,
          '收银 · 卡台列表',
        ),
      ]) {
    testWidgets('${system.name} login lands on the legacy card route', (
      tester,
    ) async {
      final factory = _LifecycleFactory();
      final environment = AppRuntimeConfiguration.fromValues(
        apiBase: 'http://127.0.0.1:8183/dev-api/server',
        onlineBase: 'http://127.0.0.1:8183/online/server',
        websocketBase: 'ws://127.0.0.1:8183/socket/server',
        servingOrigin: Uri.parse('http://127.0.0.1:8183/'),
        allowInsecureLoopback: true,
        developmentSystemSelection: true,
      );
      await tester.pumpWidget(
        ShouyinWebApp(environment: environment, dependenciesFactory: factory),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();
      expect(
        factory.dependencies.sessionRepository.currentMachine?.client,
        system.client,
      );

      await tester.runAsync(
        () => factory.dependencies.sessionRepository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(expectedTitle), findsOneWidget);
      expect(
        GoRouterState.of(tester.element(find.text(expectedTitle))).uri.path,
        system.landingPath,
      );

      await tester.tap(find.byKey(CardTableScreen.switchSystemKey));
      await tester.pumpAndSettle();
      expect(find.byType(BusinessSystemSelectionScreen), findsOneWidget);
      expect(factory.dependencies.stopCalls, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => factory.dependencies.disposed.future);
    });
  }

  test('old insecure Web flag is absent and cannot downgrade startup', () {
    final prefix = File('lib/main.dart').existsSync() ? '' : 'apps/web_app/';
    final source = File('${prefix}lib/main.dart').readAsStringSync();
    expect(source, isNot(contains('SHOUYIN_ALLOW_INSECURE_WEB')));
    expect(source, isNot(contains('WebStorageCredentialBackend')));
  });

  testWidgets('insecure Web deployment shows Gate C error before deps', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinWebApp(
        environment: AppRuntimeConfiguration.fromValues(
          apiBase: 'http://pos.example.test/server',
          onlineBase: 'http://pos.example.test/server',
          websocketBase: 'ws://pos.example.test/server',
          servingOrigin: Uri.parse('http://pos.example.test/'),
        ),
        dependenciesFactory: factory,
      ),
    );
    expect(find.textContaining('HTTPS/WSS 同源部署'), findsOneWidget);
    expect(find.textContaining('Gate C'), findsOneWidget);
    expect(factory.createCalls, 0);
  });

  testWidgets('invalid config creates no shell or secure/network dependency', (
    tester,
  ) async {
    final factory = _LifecycleFactory();

    await tester.pumpWidget(
      ShouyinWebApp(
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
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinWebApp(
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
      '收银 Web 客户端',
    );
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 1);
    expect(dependencies.realtimeCreated, isTrue);
    expect(find.text('收银 · 卡台列表'), findsOneWidget);
    expect(find.text('正在等待完整卡台数据'), findsOneWidget);

    final businessContext = tester.element(find.text('收银 · 卡台列表'));
    GoRouter.of(businessContext).go('/diagnostics');
    await tester.pumpAndSettle();
    expect(find.byKey(DiagnosticPanel.wideLayoutKey), findsOneWidget);
    expect(find.text('收银 Web 客户端'), findsOneWidget);

    GoRouter.of(tester.element(find.text('收银 Web 客户端')))
        .go('/diagnostics/devices');
    await tester.pumpAndSettle();
    expect(find.byType(DeviceDiagnosticsScreen), findsOneWidget);
    final deviceContext = tester.element(find.byType(DeviceDiagnosticsScreen));
    final deviceContainer = ProviderScope.containerOf(deviceContext);
    expect(
      deviceContainer.read(scannerServiceProvider),
      isA<WebScannerService>(),
    );
    expect(
      deviceContainer.read(printerServiceProvider),
      isA<WebPrinterService>(),
    );
    GoRouter.of(deviceContext).go('/diagnostics');
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
      ShouyinWebApp(
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

  testWidgets('initially authenticated root starts realtime exactly once', (
    tester,
  ) async {
    final factory = (await tester.runAsync(
      () => _LifecycleFactory.authenticated(_validEnvironment.config!),
    ))!;

    await tester.pumpWidget(
      ShouyinWebApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();

    expect(factory.dependencies.startCalls, 1);
    expect(find.text('收银 · 卡台列表'), findsOneWidget);
    await tester.pump();
    expect(factory.dependencies.startCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => factory.dependencies.disposed.future);
    expect(factory.dependencies.disposeCalls, 1);
  });

  test(
    'shell phase and failure streams stay stable from construction',
    () async {
      final dependencies = _LifecycleDependencies(_validEnvironment.config!);
      final phaseStream = dependencies.connectionPhases;
      final failureStream = dependencies.realtimeFailures;
      final eventStream = dependencies.realtimeEvents;
      final phases = <ConnectionPhase>[];
      final failures = <AppFailure>[];
      final events = <SyncEnvelope>[];
      final phaseSubscription = phaseStream.listen(phases.add);
      final failureSubscription = failureStream.listen(failures.add);
      final eventSubscription = eventStream.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      expect(phases, <ConnectionPhase>[ConnectionPhase.blocked]);

      dependencies.emitFailure(
        const AppFailure(
          kind: FailureKind.realtime,
          code: 'realtime.synthetic',
          safeMessage: '测试实时错误',
        ),
      );
      dependencies.emitEvent(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: const <String, Object?>{'0': <Object?>[]},
        ),
      );
      await dependencies.startRealtime();
      await Future<void>.delayed(Duration.zero);
      expect(identical(phaseStream, dependencies.connectionPhases), isTrue);
      expect(identical(failureStream, dependencies.realtimeFailures), isTrue);
      expect(identical(eventStream, dependencies.realtimeEvents), isTrue);
      expect(phases, contains(ConnectionPhase.online));
      expect(failures.single.code, 'realtime.synthetic');
      expect(events.single.cursor, '20260828010101');

      await phaseSubscription.cancel();
      await failureSubscription.cancel();
      await eventSubscription.cancel();
      await dependencies.dispose();
      expect(dependencies.hasOpenStreams, isFalse);
    },
  );
  testWidgets('old stop completion cannot block a newer auth generation', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinWebApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();
    final dependencies = factory.dependencies;
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    dependencies.gateNextStop();
    await tester.runAsync(dependencies.logout);
    await tester.pump();
    await tester.runAsync(() => dependencies.stopStarted.future);
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 2);
    expect(dependencies.connectionPhase, ConnectionPhase.online);
    dependencies.releaseStoppedGeneration();
    await tester.runAsync(() => dependencies.stopFinished.future);
    await tester.pumpAndSettle();
    expect(dependencies.connectionPhase, ConnectionPhase.online);
    expect(dependencies.disposedGenerations, <int>[1]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => dependencies.disposed.future);
    expect(dependencies.disposedGenerations, <int>[1, 2]);
  });
}

final AppRuntimeConfiguration _validEnvironment =
    AppRuntimeConfiguration.fromValues(
      apiBase: 'https://api.example.test/server',
      onlineBase: 'https://online.example.test/server',
      websocketBase: 'wss://socket.example.test',
    );

final class _LifecycleFactory implements ShellDependenciesFactory {
  _LifecycleFactory();

  static Future<_LifecycleFactory> authenticated(ApiConfig config) async {
    final factory = _LifecycleFactory();
    final dependencies = _LifecycleDependencies(config);
    await dependencies.authenticate();
    factory._prepared = dependencies;
    return factory;
  }

  _LifecycleDependencies? _prepared;
  int createCalls = 0;
  int routerCreateCalls = 0;
  int routerDisposeCalls = 0;
  late _LifecycleDependencies dependencies;

  @override
  ShellDependencies create(ApiConfig config) {
    createCalls += 1;
    dependencies = _prepared ?? _LifecycleDependencies(config);
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
      _dio = Dio(),
      adapter = _AuthAdapter() {
    _dio.httpClientAdapter = adapter;
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
  final _AuthAdapter adapter;
  final StreamController<ConnectionPhase> _phases =
      StreamController<ConnectionPhase>.broadcast(sync: true);
  final StreamController<AppFailure> _failures =
      StreamController<AppFailure>.broadcast(sync: true);
  final StreamController<SyncEnvelope> _events =
      StreamController<SyncEnvelope>.broadcast(sync: true);
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
  int currentGeneration = 0;
  int openBusinessDayCalls = 0;
  int refreshRealtimeCalls = 0;
  final List<int> disposedGenerations = <int>[];
  Completer<void> stopStarted = Completer<void>();
  Completer<void> stopFinished = Completer<void>();
  Completer<void>? _stopRelease;

  bool get hasOpenStreams =>
      !_phases.isClosed || !_failures.isClosed || !_events.isClosed;

  @override
  ConnectionPhase get connectionPhase => _phase;

  @override
  late final Stream<ConnectionPhase> connectionPhases = _CurrentValueStream(
    _phases.stream,
    () => _phase,
  );

  @override
  late final Stream<AppFailure> realtimeFailures = _failures.stream;

  @override
  late final Stream<SyncEnvelope> realtimeEvents = _events.stream;

  void emitFailure(AppFailure failure) => _failures.add(failure);

  void emitEvent(SyncEnvelope event) => _events.add(event);

  @override
  Future<Result<void>> openBusinessDay() async {
    openBusinessDayCalls += 1;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> refreshRealtime() async {
    refreshRealtimeCalls += 1;
    return const Success<void>(null);
  }

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

  void gateNextStop() {
    stopStarted = Completer<void>();
    stopFinished = Completer<void>();
    _stopRelease = Completer<void>();
  }

  void releaseStoppedGeneration() => _stopRelease?.complete();

  @override
  Future<void> startRealtime() async {
    startCalls += 1;
    currentGeneration += 1;
    realtimeCreated = true;
    _active = true;
    _phase = ConnectionPhase.online;
    _phases.add(_phase);
  }

  @override
  Future<void> stopRealtime() async {
    if (!_active) return;
    final stoppedGeneration = currentGeneration;
    stopCalls += 1;
    _active = false;
    if (!stopStarted.isCompleted) stopStarted.complete();
    await _stopRelease?.future;
    disposedGenerations.add(stoppedGeneration);
    if (currentGeneration == stoppedGeneration && !_active) {
      _phase = ConnectionPhase.blocked;
      _phases.add(_phase);
    }
    if (!stopFinished.isCompleted) stopFinished.complete();
    _stopRelease = null;
  }

  @override
  Future<void> dispose() async {
    if (disposeCalls != 0) return;
    disposeCalls += 1;
    await stopRealtime();
    await sessionRepository.close();
    await _phases.close();
    await _failures.close();
    await _events.close();
    _dio.close(force: true);
    dioCloseCalls += 1;
    disposed.complete();
  }
}

final class _AuthAdapter implements HttpClientAdapter {
  int termAuthCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final requestBytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        requestBytes.addAll(chunk);
      }
    }
    final isTermAuth = options.path.endsWith('/term/auth');
    if (isTermAuth) termAuthCalls += 1;
    final requestBody = requestBytes.isEmpty
        ? const <String, Object?>{}
        : jsonDecode(utf8.decode(requestBytes)) as Map<String, Object?>;
    final accessMode = switch (requestBody['code']) {
      'loopback-development-book' => 2,
      'loopback-development-order' => 4,
      _ => 8,
    };
    final body = isTermAuth
        ? <String, Object?>{
            'code': 1,
            'data': <String, Object?>{
              'tk': 'synthetic-tk',
              'am': accessMode,
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

final class _CurrentValueStream<T> extends Stream<T> {
  const _CurrentValueStream(this.source, this.current);

  final Stream<T> source;
  final T Function() current;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    late final StreamController<T> controller;
    StreamSubscription<T>? subscription;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        subscription = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.add(current());
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
