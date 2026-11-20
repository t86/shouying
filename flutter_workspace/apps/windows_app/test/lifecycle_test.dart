import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/card_table.dart';
import 'package:design_system/design_system.dart';
import 'package:device_bridge_windows/device_bridge_windows.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';
import 'package:shouyin_windows/main.dart';

void main() {
  for (final system in [
    BusinessSystem.booking,
    BusinessSystem.order,
    BusinessSystem.cashier,
  ]) {
    testWidgets(
      'Windows ${system.label} uses its own system and full shared callbacks',
      (tester) async {
        final factory = _LifecycleFactory(clientKind: system.client);
        await tester.pumpWidget(
          ShouyinWindowsApp(
            environment: _validEnvironment,
            dependenciesFactory: factory,
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(factory.dependencies.authenticate);
        await tester.pumpAndSettle();
        final card = tester.widget<CardTableScreen>(
          find.byType(CardTableScreen),
        );
        expect(card.system, system);
        expect(card.onLoadPayOrders, isNotNull);
        expect(card.onSubmitPayOrder, isNotNull);
        expect(card.onAddOrderProduct, isNotNull);
        expect(card.onPlaceOrder, isNotNull);
        expect(card.onBookingCardWrite, isNotNull);
        expect(card.onOpenReserved, isNotNull);
        expect(
          card.onCloseBusinessDay != null,
          system == BusinessSystem.cashier,
        );
        expect(card.businessRouteObserver, isNotNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => factory.dependencies.disposed.future);
      },
    );
  }
  testWidgets('Windows cashier wires real business entry callbacks', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinWindowsApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(factory.dependencies.authenticate);
    await tester.pumpAndSettle();
    final card = tester.widget<CardTableScreen>(find.byType(CardTableScreen));
    expect(card.onAddOrderProduct, isNotNull);
    expect(card.onLoadPayOrders, isNotNull);
    expect(card.onBookingCardWrite, isNotNull);
    expect(card.onLoadCashierReport, isNotNull);
    expect(card.onLoadProfitLoss, isNotNull);
    expect(card.onLoadVouchers, isNotNull);
    expect(card.onCancelVoucher, isNotNull);
    expect(card.onExportVouchers, isNotNull);
    expect(card.onPrintCashierReportQuery, isNotNull);
    expect(card.onSubmitProfitLoss, isNotNull);
    expect(card.onSwitchSystem, isNotNull);
    await card.onAddOrderProduct!(
      seatId: '7',
      productId: '9',
      count: 2,
      price: '12.50',
    );
    expect(factory.dependencies.addedProduct, ('7', '9', 2, '12.50'));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => factory.dependencies.disposed.future);
  });
  testWidgets('delayed same-user restart cannot replace the newest login', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinWindowsApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();
    final dependencies = factory.dependencies;
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    Future<void> relogin() async {
      await dependencies.sessionRepository.login(
        account: 'employee',
        password: 'synthetic-password',
        type: EmployeeLoginType.account,
      );
    }

    dependencies.gateNextStop();
    await tester.runAsync(relogin);
    await tester.pump();
    await tester.runAsync(() => dependencies.stopStarted.future);
    await tester.runAsync(relogin);
    await tester.pumpAndSettle();
    final latest = tester.state(find.byType(CardTableScreen));
    unawaited(
      showDialog<void>(
        context: tester.element(find.byType(CardTableScreen)),
        builder: (_) => const AlertDialog(title: Text('新会话确认')),
      ),
    );
    await tester.pumpAndSettle();
    dependencies.releaseStoppedGeneration();
    await tester.runAsync(() => dependencies.stopFinished.future);
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 2);
    expect(dependencies.currentGeneration, 2);
    expect(dependencies.connectionPhase, ConnectionPhase.online);
    expect(find.text('新会话确认'), findsOneWidget);
    expect(
      identical(
        latest,
        tester.state(find.byType(CardTableScreen, skipOffstage: false)),
      ),
      isTrue,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => dependencies.disposed.future);
  });
  testWidgets(
    'same employee re-login replaces card owner and closes old dialogs',
    (tester) async {
      final factory = _LifecycleFactory();
      await tester.pumpWidget(
        ShouyinWindowsApp(
          environment: _validEnvironment,
          dependenciesFactory: factory,
        ),
      );
      await tester.pumpAndSettle();
      final dependencies = factory.dependencies;
      await tester.runAsync(dependencies.authenticate);
      await tester.pumpAndSettle();
      final before = tester.state(find.byType(CardTableScreen));
      final context = tester.element(find.byType(CardTableScreen));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('旧营业日确认')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await dependencies.sessionRepository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
      });
      await tester.pumpAndSettle();
      expect(find.text('旧营业日确认'), findsNothing);
      expect(
        identical(before, tester.state(find.byType(CardTableScreen))),
        isFalse,
      );
      expect(dependencies.startCalls, 2);
      expect(dependencies.stopCalls, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => dependencies.disposed.future);
    },
  );
  testWidgets('invalid config creates no shell or secure/network dependency', (
    tester,
  ) async {
    final factory = _LifecycleFactory();

    await tester.pumpWidget(
      ShouyinWindowsApp(
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
      ShouyinWindowsApp(
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
      '收银 Windows 客户端',
    );
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 1);
    expect(dependencies.realtimeCreated, isTrue);
    expect(find.byType(CardTableScreen), findsOneWidget);

    GoRouter.of(tester.element(find.byType(CardTableScreen)))
        .go('/diagnostics/devices');
    await tester.pumpAndSettle();
    expect(find.byType(DeviceDiagnosticsScreen), findsOneWidget);
    final deviceContext = tester.element(find.byType(DeviceDiagnosticsScreen));
    final deviceContainer = ProviderScope.containerOf(deviceContext);
    expect(
      deviceContainer.read(scannerServiceProvider),
      isA<WindowsScannerService>(),
    );
    expect(
      deviceContainer.read(printerServiceProvider),
      isA<WindowsPrinterService>(),
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
      ShouyinWindowsApp(
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
      ShouyinWindowsApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();

    expect(factory.dependencies.startCalls, 1);
    expect(find.byType(CardTableScreen), findsOneWidget);
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
      final phases = <ConnectionPhase>[];
      final failures = <AppFailure>[];
      final phaseSubscription = phaseStream.listen(phases.add);
      final failureSubscription = failureStream.listen(failures.add);
      await Future<void>.delayed(Duration.zero);
      expect(phases, <ConnectionPhase>[ConnectionPhase.blocked]);

      dependencies.emitFailure(
        const AppFailure(
          kind: FailureKind.realtime,
          code: 'realtime.synthetic',
          safeMessage: '测试实时错误',
        ),
      );
      await dependencies.startRealtime();
      await Future<void>.delayed(Duration.zero);
      expect(identical(phaseStream, dependencies.connectionPhases), isTrue);
      expect(identical(failureStream, dependencies.realtimeFailures), isTrue);
      expect(phases, contains(ConnectionPhase.online));
      expect(failures.single.code, 'realtime.synthetic');

      await phaseSubscription.cancel();
      await failureSubscription.cancel();
      await dependencies.dispose();
      expect(dependencies.hasOpenStreams, isFalse);
    },
  );

  testWidgets('old stop completion cannot block a newer auth generation', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinWindowsApp(
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
    expect(dependencies.currentGeneration, 2);

    dependencies.releaseStoppedGeneration();
    await tester.runAsync(() => dependencies.stopFinished.future);
    await tester.pumpAndSettle();
    expect(dependencies.connectionPhase, ConnectionPhase.online);
    expect(dependencies.currentGeneration, 2);
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
  _LifecycleFactory({this.clientKind = ClientKind.cashier});
  final ClientKind clientKind;

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
    dependencies =
        _prepared ?? _LifecycleDependencies(config, clientKind: clientKind);
    return dependencies;
  }

  @override
  void onRouterCreated() => routerCreateCalls += 1;

  @override
  void onRouterDisposed() => routerDisposeCalls += 1;
}

final class _StubOrderLateDepositLoader implements OrderLateDepositLoader {
  const _StubOrderLateDepositLoader();
  @override
  bool get needsVerification => false;
  @override
  Future<Result<OrderLateDepositPayment>> create({
    required String seatId,
    required int payType,
    required String amountYuan,
    String? authCode,
    required bool Function() canDispatch,
  }) async => throw UnimplementedError();
  @override
  Future<Result<int>> status(
    String payDetailId, {
    required bool Function() canDispatch,
  }) async => throw UnimplementedError();
}

final class _LifecycleDependencies implements ShellDependencies {
  @override
  CashierCreditAccountsLoader get creditAccountsLoader =>
      throw UnsupportedError(
        'Credit management is not used by this lifecycle fixture',
      );
  @override
  CashierMerchantManagementLoader get merchantManagementLoader =>
      throw UnsupportedError(
        'Merchant management is not used by this lifecycle fixture',
      );
  @override
  OrderLateDepositLoader get orderLateDepositLoader =>
      const _StubOrderLateDepositLoader();
  @override
  Future<Result<void>> printCashierReportQuery(
    CashierReportQuery query,
  ) async => const Success(null);
  @override
  Future<Result<List<CashierVoucherRecord>>> loadVouchers(
    CashierVoucherQuery query,
  ) async => const Success([]);
  @override
  Future<Result<void>> cancelVoucher(
    String recordId,
    bool Function() canDispatch,
  ) async => const Success(null);
  @override
  Future<Result<String>> exportVouchers(
    CashierVoucherQuery query,
    bool Function() canDispatch,
  ) async => const Success('test.xlsx');
  @override
  Future<Result<List<CashierProfitLossRecord>>> loadProfitLoss() async =>
      const Success([]);
  @override
  Future<Result<void>> submitProfitLoss(
    CashierProfitLossDraft draft,
    bool Function() canDispatch,
  ) async => const Success(null);
  // Unused business callbacks deliberately fail instead of pretending success.
  @override
  Future<Result<BookingDetailConfig>> loadBookingDetailConfig() async =>
      const Success(BookingDetailConfig.unrestrictedAll);

  @override
  Set<String> paidTransfersNeedingVerification(String seatId) => {};
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Unexpected lifecycle test callback: ${invocation.memberName}',
  );

  final ManagementPermissionFeed _managementFeed = ManagementPermissionFeed();
  @override
  ManagementPermissionFeed get managementAccess => _managementFeed;
  @override
  VipPages vipPages() => const VipPages();
  (String, String, int, String)? addedProduct;
  @override
  Future<Result<void>> addOrderProduct({
    required String seatId,
    required String productId,
    required int count,
    required String price,
    String amount = '',
  }) async {
    addedProduct = (seatId, productId, count, price);
    return const Success(null);
  }

  _LifecycleDependencies(
    ApiConfig config, {
    ClientKind clientKind = ClientKind.cashier,
  }) : _store = _MemoryCredentialStore(),
       _dio = Dio() {
    _dio.httpClientAdapter = _AuthAdapter(clientKind);
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
  int currentGeneration = 0;
  final List<int> disposedGenerations = <int>[];
  Completer<void> stopStarted = Completer<void>();
  Completer<void> stopFinished = Completer<void>();
  Completer<void>? _stopRelease;

  bool get hasOpenStreams => !_phases.isClosed || !_failures.isClosed;

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
  late final Stream<SyncEnvelope> cardTableEvents =
      const Stream<SyncEnvelope>.empty();

  @override
  Future<Result<void>> closeBusinessDay() async => const Success(null);

  @override
  Future<Result<void>> printShiftBill() async => const Success(null);

  @override
  Future<Result<AutoCloseConfig>> loadAutoClose() async =>
      const Success(AutoCloseConfig(enabled: false, hour: 0, minute: 0));

  @override
  Future<Result<void>> saveAutoClose({
    required bool enabled,
    required int hour,
    required int minute,
  }) async => const Success(null);

  void emitFailure(AppFailure failure) => _failures.add(failure);

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
    _managementFeed.dispose();
    await _phases.close();
    await _failures.close();
    _dio.close(force: true);
    dioCloseCalls += 1;
    disposed.complete();
  }
}

final class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter(this.clientKind);
  final ClientKind clientKind;
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
              'am': clientKind.termType,
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
