import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:permissions/permissions.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

const _appLabel = '收银 Windows 客户端';
const _platformLabel = 'Windows';

void main() {
  runApp(
    ShouyinWindowsApp(environment: AppRuntimeConfiguration.fromEnvironment()),
  );
}

final class AppRuntimeConfiguration {
  const AppRuntimeConfiguration._({
    required this.config,
    required this.invalidKeys,
  });

  factory AppRuntimeConfiguration.fromEnvironment() =>
      AppRuntimeConfiguration.fromValues(
        apiBase: const String.fromEnvironment('SHOUYIN_API_BASE'),
        onlineBase: const String.fromEnvironment('SHOUYIN_ONLINE_BASE'),
        websocketBase: const String.fromEnvironment('SHOUYIN_WS_BASE'),
      );

  factory AppRuntimeConfiguration.fromValues({
    required String apiBase,
    required String onlineBase,
    required String websocketBase,
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
    );
  }

  final ApiConfig? config;
  final List<String> invalidKeys;

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
      _dio = Dio() {
    _protocolClient = ProtocolClient(
      dio: _dio,
      config: _config,
      credentialStore: _credentialStore,
      requestGate: RequestGate(clock: DateTime.now),
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
  late final ProtocolClient _protocolClient;
  RealtimeController? _realtimeController;
  final StreamController<ConnectionPhase> _phaseEvents =
      StreamController<ConnectionPhase>.broadcast(sync: true);
  final StreamController<AppFailure> _failureEvents =
      StreamController<AppFailure>.broadcast(sync: true);
  StreamSubscription<ConnectionPhase>? _phaseSubscription;
  StreamSubscription<AppFailure>? _failureSubscription;
  ConnectionPhase _currentPhase = ConnectionPhase.blocked;
  AppFailure? _lastFailure;
  bool _disposed = false;

  @override
  late final SessionRepository sessionRepository;

  @override
  late final Stream<ConnectionPhase> connectionPhases;

  @override
  late final Stream<AppFailure> realtimeFailures;

  RealtimeController get _realtime {
    final existing = _realtimeController;
    if (existing != null) return existing;
    final controller = RealtimeController(
      config: _config,
      client: sessionRepository.currentMachine?.client ?? ClientKind.cashier,
      credentialStore: _credentialStore,
      syncApi: ProtocolSyncApi(client: _protocolClient),
      socketTransport: const WebSocketChannelTransport(),
    );
    _realtimeController = controller;
    _phaseSubscription = controller.phases.listen((phase) {
      _currentPhase = phase;
      if (!_phaseEvents.isClosed) _phaseEvents.add(phase);
    });
    _failureSubscription = controller.failures.listen((failure) {
      _lastFailure = failure;
      if (!_failureEvents.isClosed) _failureEvents.add(failure);
    });
    return controller;
  }

  @override
  ConnectionPhase get connectionPhase => _currentPhase;

  @override
  Future<void> startRealtime() async {
    if (_disposed || sessionRepository.currentUser == null) return;
    await _realtime.start();
  }

  @override
  Future<void> stopRealtime() async {
    await _realtimeController?.stop();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _realtimeController?.dispose();
    await _phaseSubscription?.cancel();
    await _failureSubscription?.cancel();
    await sessionRepository.close();
    await _phaseEvents.close();
    await _failureEvents.close();
    _dio.close(force: true);
  }
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
final _routerProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(_appSessionRepositoryProvider);
  final factory = ref.watch(_dependenciesFactoryProvider);
  final refresh = _SessionRefresh(repository);
  ref.onDispose(refresh.dispose);
  final router = GoRouter(
    initialLocation: ref.watch(_initialLocationProvider),
    refreshListenable: refresh,
    redirect: (context, state) {
      final authenticated = repository.currentUser != null;
      final atLogin = state.matchedLocation == '/login';
      if (!authenticated && !atLogin) return '/login';
      if (authenticated && atLogin) return '/diagnostics';
      return null;
    },
    routes: <RouteBase>[
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/diagnostics',
        builder: (context, state) => const _DiagnosticsScreen(),
      ),
      GoRoute(
        path: '/diagnostics/devices',
        builder: (context, state) => const _DevicePlaceholderScreen(),
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

final class ShouyinWindowsApp extends StatelessWidget {
  const ShouyinWindowsApp({
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
        sessionRepositoryProvider.overrideWith(
          (ref) => ref.watch(_appSessionRepositoryProvider),
        ),
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

final class _DevicePlaceholderScreen extends StatelessWidget {
  const _DevicePlaceholderScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(_appLabel)),
    body: const Center(child: Text('设备检查将在 Task 11 中实现')),
  );
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
