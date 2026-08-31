import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:design_system/design_system.dart';
import 'package:device_bridge_android/device_bridge_android.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:permissions/permissions.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

const _appLabel = '收银 Android 客户端';
const _platformLabel = 'Android';

void main() {
  runApp(
    ShouyinAndroidApp(environment: AppRuntimeConfiguration.fromEnvironment()),
  );
}

final class AppRuntimeConfiguration {
  const AppRuntimeConfiguration._({
    required this.config,
    required this.invalidKeys,
    required this.developmentSystemSelection,
  });

  factory AppRuntimeConfiguration.fromEnvironment() =>
      AppRuntimeConfiguration.fromValues(
        apiBase: const String.fromEnvironment('SHOUYIN_API_BASE'),
        onlineBase: const String.fromEnvironment('SHOUYIN_ONLINE_BASE'),
        websocketBase: const String.fromEnvironment('SHOUYIN_WS_BASE'),
        developmentSystemSelection: const bool.fromEnvironment(
          'SHOUYIN_DEV_SYSTEM_SELECTION',
        ),
      );

  factory AppRuntimeConfiguration.fromValues({
    required String apiBase,
    required String onlineBase,
    required String websocketBase,
    bool developmentSystemSelection = false,
  }) {
    final invalidKeys = <String>[];
    final api = _validatedEndpoint(apiBase, _EndpointKind.api);
    final online = _validatedEndpoint(onlineBase, _EndpointKind.online);
    final websocket = _validatedEndpoint(
      websocketBase,
      _EndpointKind.websocket,
    );
    if (api == null) invalidKeys.add('SHOUYIN_API_BASE');
    if (online == null) invalidKeys.add('SHOUYIN_ONLINE_BASE');
    if (websocket == null) invalidKeys.add('SHOUYIN_WS_BASE');
    ApiConfig? config;
    if (invalidKeys.isEmpty) {
      config = ApiConfig(
        apiBase: api!,
        onlineBase: online!,
        websocketBase: websocket!,
      );
    }
    return AppRuntimeConfiguration._(
      config: config,
      invalidKeys: List<String>.unmodifiable(invalidKeys),
      developmentSystemSelection:
          developmentSystemSelection &&
          config != null &&
          _validLoopbackDevelopment(api, online, websocket),
    );
  }

  final ApiConfig? config;
  final List<String> invalidKeys;
  final bool developmentSystemSelection;

  static bool _validLoopbackDevelopment(Uri? api, Uri? online, Uri? websocket) {
    if (api == null || online == null || websocket == null) return false;
    if (api.scheme != 'http' ||
        online.scheme != 'http' ||
        websocket.scheme != 'ws') {
      return false;
    }
    if (!_isLoopback(api.host) ||
        api.host != online.host ||
        api.host != websocket.host) {
      return false;
    }
    int port(Uri uri) => uri.hasPort ? uri.port : 80;
    if (port(api) != port(online) || port(api) != port(websocket)) {
      return false;
    }
    return api.path == '/dev-api/server' &&
        online.path == '/online/server' &&
        websocket.path == '/socket/server';
  }

  static bool _isLoopback(String host) =>
      host == '127.0.0.1' || host == 'localhost' || host == '::1';

  static Uri? _validatedEndpoint(String raw, _EndpointKind kind) {
    if (raw.trim().isEmpty) return null;
    final candidate = Uri.tryParse(raw);
    if (candidate == null) return null;
    final safeHttp = Uri.parse('https://config.invalid');
    final safeWebsocket = Uri.parse('wss://config.invalid');
    try {
      switch (kind) {
        case _EndpointKind.api:
          ApiConfig(
            apiBase: candidate,
            onlineBase: safeHttp,
            websocketBase: safeWebsocket,
          );
        case _EndpointKind.online:
          ApiConfig(
            apiBase: safeHttp,
            onlineBase: candidate,
            websocketBase: safeWebsocket,
          );
        case _EndpointKind.websocket:
          ApiConfig(
            apiBase: safeHttp,
            onlineBase: safeHttp,
            websocketBase: candidate,
          );
      }
      return candidate;
    } on ArgumentError {
      return null;
    }
  }
}

enum _EndpointKind { api, online, websocket }

abstract interface class ShellDependenciesFactory {
  ShellDependencies create(ApiConfig config);

  void onRouterCreated();

  void onRouterDisposed();
}

abstract interface class ShellDependencies {
  SessionRepository get sessionRepository;

  ConnectionPhase get connectionPhase;

  Stream<ConnectionPhase> get connectionPhases;

  Stream<AppFailure> get realtimeFailures;

  Stream<SyncEnvelope> get cardTableEvents;

  Future<Result<void>> refreshRealtime();

  Future<void> startRealtime();

  Future<void> stopRealtime();

  Future<void> dispose();
}

final class DefaultShellDependenciesFactory
    implements ShellDependenciesFactory {
  const DefaultShellDependenciesFactory();

  @override
  ShellDependencies create(ApiConfig config) =>
      _DefaultShellDependencies(config);

  @override
  void onRouterCreated() {}

  @override
  void onRouterDisposed() {}
}

final class _DefaultShellDependencies implements ShellDependencies {
  _DefaultShellDependencies(this._config)
    : _credentialStore = FlutterSecureCredentialStore(),
      _dio = Dio(),
      _syncDio = Dio() {
    _protocolClient = ProtocolClient(
      dio: _dio,
      config: _config,
      credentialStore: _credentialStore,
      requestGate: RequestGate(clock: DateTime.now),
    );
    _syncProtocolClient = ProtocolClient(
      dio: _syncDio,
      config: _config,
      credentialStore: _credentialStore,
      requestGate: RequestGate(clock: DateTime.now),
      responseLimits: const ProtocolResponseLimits(
        maxRawResponseBytes: 64 * 1024 * 1024,
        maxDepth: 64,
        maxNodes: 1000000,
      ),
    );
    sessionRepository = SessionRepository(
      api: SessionApi(client: _protocolClient),
      credentialStore: _credentialStore,
    );
    connectionPhases = _CurrentValueStream<ConnectionPhase>(
      _phaseEvents.stream,
      () => _currentPhase,
    );
    realtimeFailures = _OptionalCurrentValueStream<AppFailure>(
      _failureEvents.stream,
      () => _lastFailure,
    );
  }

  final ApiConfig _config;
  final CredentialStore _credentialStore;
  final Dio _dio;
  final Dio _syncDio;
  late final ProtocolClient _protocolClient;
  late final ProtocolClient _syncProtocolClient;
  RealtimeController? _realtimeController;
  final StreamController<ConnectionPhase> _phaseEvents =
      StreamController<ConnectionPhase>.broadcast(sync: true);
  final StreamController<AppFailure> _failureEvents =
      StreamController<AppFailure>.broadcast(sync: true);
  final CardTableEventFeed _cardEvents = CardTableEventFeed();
  // ignore: cancel_subscriptions
  StreamSubscription<ConnectionPhase>? _phaseSubscription;
  // ignore: cancel_subscriptions
  StreamSubscription<AppFailure>? _failureSubscription;
  // ignore: cancel_subscriptions
  StreamSubscription<SyncEnvelope>? _eventSubscription;
  ConnectionPhase _currentPhase = ConnectionPhase.blocked;
  AppFailure? _lastFailure;
  int _realtimeGeneration = 0;
  int? _activeRealtimeGeneration;
  bool _disposed = false;

  @override
  late final SessionRepository sessionRepository;

  @override
  late final Stream<ConnectionPhase> connectionPhases;

  @override
  late final Stream<AppFailure> realtimeFailures;

  @override
  Stream<SyncEnvelope> get cardTableEvents => _cardEvents.events;

  RealtimeController get _realtime {
    final existing = _realtimeController;
    if (existing != null) return existing;
    final controller = RealtimeController(
      config: _config,
      client: sessionRepository.currentMachine?.client ?? ClientKind.cashier,
      credentialStore: _credentialStore,
      syncApi: ProtocolSyncApi(client: _syncProtocolClient),
      socketTransport: const WebSocketChannelTransport(),
    );
    final generation = ++_realtimeGeneration;
    _activeRealtimeGeneration = generation;
    _realtimeController = controller;
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _phaseSubscription = controller.phases.listen((phase) {
      if (!identical(_realtimeController, controller) ||
          _activeRealtimeGeneration != generation) {
        return;
      }
      _currentPhase = phase;
      if (!_phaseEvents.isClosed) _phaseEvents.add(phase);
    });
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _failureSubscription = controller.failures.listen((failure) {
      if (!identical(_realtimeController, controller) ||
          _activeRealtimeGeneration != generation) {
        return;
      }
      _lastFailure = failure;
      if (!_failureEvents.isClosed) _failureEvents.add(failure);
    });
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _eventSubscription = controller.events.listen((event) {
      if (!identical(_realtimeController, controller) ||
          _activeRealtimeGeneration != generation) {
        return;
      }
      _cardEvents.add(event);
    });
    return controller;
  }

  @override
  ConnectionPhase get connectionPhase => _currentPhase;

  @override
  Future<Result<void>> refreshRealtime() async {
    final user = sessionRepository.currentUser;
    final machine = sessionRepository.currentMachine;
    if (_disposed || user == null || machine == null) {
      return const FailureResult<void>(_refreshUnavailable);
    }
    try {
      await stopRealtime();
      if (_disposed ||
          !identical(user, sessionRepository.currentUser) ||
          !identical(machine, sessionRepository.currentMachine)) {
        return const FailureResult<void>(_refreshUnavailable);
      }
      await startRealtime();
      return const Success<void>(null);
    } on Object {
      return const FailureResult<void>(
        AppFailure(
          kind: FailureKind.realtime,
          code: 'realtime.refresh_failed',
          safeMessage: '刷新卡台数据失败，请重试',
        ),
      );
    }
  }

  @override
  Future<void> startRealtime() async {
    if (_disposed || sessionRepository.currentUser == null) return;
    await _realtime.start();
  }

  @override
  Future<void> stopRealtime() async {
    _cardEvents.reset();
    _lastFailure = null;
    _currentPhase = ConnectionPhase.blocked;
    if (!_phaseEvents.isClosed) _phaseEvents.add(_currentPhase);
    final controller = _realtimeController;
    if (controller == null) return;
    final generation = _activeRealtimeGeneration;
    _realtimeController = null;
    _activeRealtimeGeneration = null;
    final phaseSubscription = _phaseSubscription;
    final failureSubscription = _failureSubscription;
    final eventSubscription = _eventSubscription;
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _phaseSubscription = null;
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _failureSubscription = null;
    // Stored and cancelled by stopRealtime/dispose.
    // ignore: cancel_subscriptions
    _eventSubscription = null;
    await controller.dispose();
    await phaseSubscription?.cancel();
    await failureSubscription?.cancel();
    await eventSubscription?.cancel();
    if (_realtimeController == null && _realtimeGeneration == generation) {
      _currentPhase = ConnectionPhase.blocked;
      if (!_phaseEvents.isClosed) _phaseEvents.add(_currentPhase);
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopRealtime();
    await sessionRepository.close();
    await _phaseEvents.close();
    await _failureEvents.close();
    await _cardEvents.close();
    _dio.close(force: true);
    _syncDio.close(force: true);
  }

  static const _refreshUnavailable = AppFailure(
    kind: FailureKind.authentication,
    code: 'realtime.refresh_unavailable',
    safeMessage: '当前登录状态不可刷新',
  );
}

final _apiConfigProvider = Provider<ApiConfig>(
  (ref) => throw StateError('api config must be overridden'),
);
final _dependenciesFactoryProvider = Provider<ShellDependenciesFactory>(
  (ref) => const DefaultShellDependenciesFactory(),
);
final _shellDependenciesProvider = Provider<ShellDependencies>((ref) {
  final dependencies = ref
      .watch(_dependenciesFactoryProvider)
      .create(ref.watch(_apiConfigProvider));
  ref.onDispose(() => unawaited(dependencies.dispose()));
  return dependencies;
});
final _appSessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => ref.watch(_shellDependenciesProvider).sessionRepository,
);
final _permissionSnapshotProvider = Provider<PermissionSnapshot>(
  (ref) => PermissionSnapshot(
    available: false,
    roleIds: const <int>{},
    moduleIds: const <int>{},
    subPermissions: const <SubPermissionKey>{},
    stationId: null,
  ),
);
final _currentUserProvider = StreamProvider<UserSession?>((ref) {
  return ref.watch(_appSessionRepositoryProvider).userSessions;
});
final _realtimeLifecycleProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<UserSession?>>(_currentUserProvider, (previous, next) {
    if (next.value != null) {
      unawaited(ref.read(_shellDependenciesProvider).startRealtime());
    } else if (previous?.value != null) {
      unawaited(ref.read(_shellDependenciesProvider).stopRealtime());
    }
  }, fireImmediately: true);
});
final _connectionPhaseProvider = StreamProvider<ConnectionPhase>((ref) {
  return ref.watch(_shellDependenciesProvider).connectionPhases;
});
final _realtimeFailureProvider = StreamProvider<AppFailure>((ref) {
  return ref.watch(_shellDependenciesProvider).realtimeFailures;
});
final _initialLocationProvider = Provider<String>((ref) => '/login');
final _developmentSystemSelectionProvider = Provider<bool>((ref) => false);
final _routerProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(_appSessionRepositoryProvider);
  final factory = ref.watch(_dependenciesFactoryProvider);
  final developmentSystemSelection = ref.watch(
    _developmentSystemSelectionProvider,
  );
  final refresh = _SessionRefresh(repository);
  ref.onDispose(refresh.dispose);
  final router = GoRouter(
    initialLocation: ref.watch(_initialLocationProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final machine = repository.currentMachine;
      final authenticated = repository.currentUser != null;
      final location = state.matchedLocation;
      if (developmentSystemSelection && machine == null) {
        return location == '/select-system' ? null : '/select-system';
      }
      if (machine == null || !authenticated) {
        return location == '/login' ? null : '/login';
      }
      final system = BusinessSystem.fromClient(machine.client);
      final landingPath = system?.landingPath ?? '/diagnostics';
      if (location == '/login' || location == '/select-system') {
        return landingPath;
      }
      if (BusinessSystem.values.any((value) => value.landingPath == location) &&
          location != landingPath) {
        return landingPath;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/select-system',
        builder: (context, state) => BusinessSystemSelectionScreen(
          authorize: (system) => ref
              .read(loginViewModelProvider.notifier)
              .authorizeMachine(system.developmentAuthorizationPlaceholder),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const _SystemLoginScreen(),
      ),
      for (final system in BusinessSystem.values)
        GoRoute(
          path: system.landingPath,
          builder: (context, state) => _BusinessHomeScreen(system: system),
        ),
      GoRoute(
        path: '/diagnostics',
        builder: (context, state) => const _DiagnosticsScreen(),
      ),
      GoRoute(
        path: '/diagnostics/devices',
        builder: (context, state) => const DeviceDiagnosticsScreen(
          appVersion: '1.0.0+1',
          platformLabel: _platformLabel,
        ),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('页面不可用'))),
  );
  factory.onRouterCreated();
  ref.onDispose(() {
    router.dispose();
    factory.onRouterDisposed();
  });
  return router;
});

final class ShouyinAndroidApp extends StatelessWidget {
  const ShouyinAndroidApp({
    this.environment,
    this.dependenciesFactory,
    this.initialLocation = '/login',
    super.key,
  });

  final AppRuntimeConfiguration? environment;
  final ShellDependenciesFactory? dependenciesFactory;
  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    final resolved = environment ?? AppRuntimeConfiguration.fromEnvironment();
    final config = resolved.config;
    if (config == null) {
      return MaterialApp(
        title: _appLabel,
        home: ConfigurationErrorScreen(missingKeys: resolved.invalidKeys),
      );
    }
    return ProviderScope(
      overrides: [
        _apiConfigProvider.overrideWithValue(config),
        if (dependenciesFactory case final value?)
          _dependenciesFactoryProvider.overrideWithValue(value),
        _initialLocationProvider.overrideWithValue(initialLocation),
        _developmentSystemSelectionProvider.overrideWithValue(
          resolved.developmentSystemSelection,
        ),
        sessionRepositoryProvider.overrideWith(
          (ref) => ref.watch(_appSessionRepositoryProvider),
        ),
        scannerServiceProvider.overrideWith((ref) {
          final scanner = AndroidScannerService();
          ref.onDispose(() => unawaited(scanner.dispose()));
          return scanner;
        }),
        printerServiceProvider.overrideWith((ref) => AndroidPrinterService()),
      ],
      child: const _AppView(),
    );
  }
}

final class _AppView extends ConsumerWidget {
  const _AppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(_currentUserProvider);
    ref.watch(_realtimeLifecycleProvider);
    ref.watch(_permissionSnapshotProvider);
    return MaterialApp.router(
      title: _appLabel,
      routerConfig: ref.watch(_routerProvider),
    );
  }
}

final class _SystemLoginScreen extends ConsumerWidget {
  const _SystemLoginScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(loginViewModelProvider);
    final machine = ref.watch(_appSessionRepositoryProvider).currentMachine;
    final system = machine == null
        ? null
        : BusinessSystem.fromClient(machine.client);
    if (system == null) return const LoginScreen();
    return Scaffold(
      appBar: AppBar(
        title: Text('${system.label}登录'),
        actions: <Widget>[
          TextButton(
            onPressed: () => ref.read(loginViewModelProvider.notifier).logout(),
            child: const Text('切换系统'),
          ),
        ],
      ),
      body: const LoginScreen(),
    );
  }
}

final class _BusinessHomeScreen extends ConsumerWidget {
  const _BusinessHomeScreen({required this.system});

  final BusinessSystem system;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dependencies = ref.watch(_shellDependenciesProvider);
    final phase =
        ref.watch(_connectionPhaseProvider).value ??
        dependencies.connectionPhase;
    return CardTableScreen(
      key: ValueKey(system),
      system: system,
      events: dependencies.cardTableEvents,
      connectionPhase: phase,
      lastFailure: ref.watch(_realtimeFailureProvider).value,
      onLogout: ref.read(loginViewModelProvider.notifier).logout,
      onSwitchSystem: ref.read(loginViewModelProvider.notifier).logout,
      onRefresh: dependencies.refreshRealtime,
      onOpenDiagnostics: () => context.push('/diagnostics/devices'),
      userName: dependencies.sessionRepository.currentUser?.name,
      machineId: dependencies.sessionRepository.currentMachine?.machineId,
      stationId: dependencies.sessionRepository.currentUser?.stationId,
    );
  }
}

final class _DiagnosticsScreen extends ConsumerWidget {
  const _DiagnosticsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(_appSessionRepositoryProvider);
    final config = ref.watch(_apiConfigProvider);
    final dependencies = ref.watch(_shellDependenciesProvider);
    final phase =
        ref.watch(_connectionPhaseProvider).value ??
        dependencies.connectionPhase;
    final failure = ref.watch(_realtimeFailureProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text(_appLabel)),
      body: Column(
        children: <Widget>[
          ConnectionBanner(phase: phase),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DiagnosticPanel(
                appVersion: '1.0.0+1',
                platformLabel: _platformLabel,
                phase: phase,
                machineId: repository.currentMachine?.machineId,
                machineName: repository.currentMachine?.machineName,
                userId: repository.currentUser?.employeeId,
                userName: repository.currentUser?.name,
                apiBase: config.apiBase,
                onlineBase: config.onlineBase,
                websocketBase: config.websocketBase,
                lastFailure: failure,
                onWriteCommand: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(SessionRepository repository) {
    _machineSubscription = repository.machineSessions.listen((_) {
      notifyListeners();
    });
    _userSubscription = repository.userSessions.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<MachineSession?> _machineSubscription;
  late final StreamSubscription<UserSession?> _userSubscription;

  @override
  void dispose() {
    unawaited(_machineSubscription.cancel());
    unawaited(_userSubscription.cancel());
    super.dispose();
  }
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
  }) => _replayStream(
    source: source,
    initial: current(),
    onData: onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

final class _OptionalCurrentValueStream<T> extends Stream<T> {
  const _OptionalCurrentValueStream(this.source, this.current);

  final Stream<T> source;
  final T? Function() current;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => _replayStream(
    source: source,
    initial: current(),
    onData: onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

StreamSubscription<T> _replayStream<T>({
  required Stream<T> source,
  required T? initial,
  required void Function(T event)? onData,
  required Function? onError,
  required void Function()? onDone,
  required bool? cancelOnError,
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
      if (initial != null) controller.add(initial);
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
