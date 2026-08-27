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

const _appLabel = '收银 Web 客户端';
const _platformLabel = 'Web';

void main() {
  runApp(ShouyinWebApp(environment: AppRuntimeConfiguration.fromEnvironment()));
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

final _apiConfigProvider = Provider<ApiConfig>(
  (ref) => throw StateError('api config must be overridden'),
);
final _credentialStoreProvider = Provider<CredentialStore>(
  (ref) => FlutterSecureCredentialStore(),
);
final _dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
final _protocolClientProvider = Provider<ProtocolClient>(
  (ref) => ProtocolClient(
    dio: ref.watch(_dioProvider),
    config: ref.watch(_apiConfigProvider),
    credentialStore: ref.watch(_credentialStoreProvider),
    requestGate: RequestGate(clock: DateTime.now),
  ),
);
final _sessionApiProvider = Provider<SessionApi>(
  (ref) => SessionApi(client: ref.watch(_protocolClientProvider)),
);
final _appSessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final repository = SessionRepository(
    api: ref.watch(_sessionApiProvider),
    credentialStore: ref.watch(_credentialStoreProvider),
  );
  ref.onDispose(() => unawaited(repository.close()));
  return repository;
});
final _socketTransportProvider = Provider<SocketTransport>(
  (ref) => const WebSocketChannelTransport(),
);
final _syncApiProvider = Provider<SyncApi>(
  (ref) => ProtocolSyncApi(client: ref.watch(_protocolClientProvider)),
);
final _realtimeControllerProvider = Provider<RealtimeController>((ref) {
  final repository = ref.watch(_appSessionRepositoryProvider);
  final controller = RealtimeController(
    config: ref.watch(_apiConfigProvider),
    client: repository.currentMachine?.client ?? ClientKind.cashier,
    credentialStore: ref.watch(_credentialStoreProvider),
    syncApi: ref.watch(_syncApiProvider),
    socketTransport: ref.watch(_socketTransportProvider),
  );
  ref.onDispose(() => unawaited(controller.dispose()));
  return controller;
});
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
final _connectionPhaseProvider = StreamProvider<ConnectionPhase>((ref) {
  return ref.watch(_realtimeControllerProvider).phases;
});
final _realtimeFailureProvider = StreamProvider<AppFailure>((ref) {
  return ref.watch(_realtimeControllerProvider).failures;
});
final _initialLocationProvider = Provider<String>((ref) => '/login');
final _routerProvider = Provider<GoRouter>((ref) {
  final repository = ref.watch(_appSessionRepositoryProvider);
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
  ref.onDispose(router.dispose);
  return router;
});

final class ShouyinWebApp extends StatelessWidget {
  const ShouyinWebApp({
    this.environment,
    this.credentialStore,
    this.sessionRepository,
    this.realtimeController,
    this.initialLocation = '/login',
    super.key,
  });

  final AppRuntimeConfiguration? environment;
  final CredentialStore? credentialStore;
  final SessionRepository? sessionRepository;
  final RealtimeController? realtimeController;
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
        if (credentialStore case final value?)
          _credentialStoreProvider.overrideWithValue(value),
        if (sessionRepository case final value?)
          _appSessionRepositoryProvider.overrideWithValue(value),
        if (realtimeController case final value?)
          _realtimeControllerProvider.overrideWithValue(value),
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
    final currentUser = ref.watch(_currentUserProvider);
    ref.watch(_permissionSnapshotProvider);
    ref.listen<AsyncValue<UserSession?>>(_currentUserProvider, (
      previous,
      next,
    ) {
      if (next.value != null) {
        unawaited(ref.read(_realtimeControllerProvider).start());
      } else if (previous?.value != null) {
        unawaited(ref.read(_realtimeControllerProvider).stop());
      }
    });
    if (currentUser.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(ref.read(_realtimeControllerProvider).start());
      });
    }
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
    final controller = ref.watch(_realtimeControllerProvider);
    final phase = ref.watch(_connectionPhaseProvider).value ?? controller.phase;
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
