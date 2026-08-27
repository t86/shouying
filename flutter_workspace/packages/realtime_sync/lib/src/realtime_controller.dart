import 'dart:async';
import 'dart:convert';

import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/src/socket_transport.dart';
import 'package:realtime_sync/src/sync_api.dart';
import 'package:realtime_sync/src/sync_envelope.dart';

abstract interface class ScheduledHandle {
  void cancel();
}

abstract interface class Scheduler {
  ScheduledHandle schedule(Duration delay, void Function() callback);
}

final class TimerScheduler implements Scheduler {
  const TimerScheduler();

  @override
  ScheduledHandle schedule(Duration delay, void Function() callback) =>
      _TimerHandle(Timer(delay, callback));
}

final class StopwatchMonotonicClock {
  StopwatchMonotonicClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  Duration call() => _stopwatch.elapsed;
}

final class _TimerHandle implements ScheduledHandle {
  const _TimerHandle(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

final class RealtimeController {
  factory RealtimeController({
    required ApiConfig config,
    required ClientKind client,
    required CredentialStore credentialStore,
    required SyncApi syncApi,
    required SocketTransport socketTransport,
    Duration Function()? monotonicClock,
    Scheduler scheduler = const TimerScheduler(),
  }) => RealtimeController._(
    config,
    client,
    credentialStore,
    syncApi,
    socketTransport,
    monotonicClock,
    scheduler,
  );

  RealtimeController._(
    this._config,
    this._client,
    this._credentialStore,
    this._syncApi,
    this._socketTransport,
    Duration Function()? monotonicClock,
    this._scheduler,
  ) : _clock = monotonicClock ?? StopwatchMonotonicClock().call {
    phases = _CurrentValueStream<ConnectionPhase>(
      _phaseController.stream,
      () => _phase,
    );
    events = _eventController.stream;
    failures = _failureController.stream;
  }

  static const Duration heartbeatTimeout = Duration(seconds: 65);
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const int maxCredentialLength = 4096;
  static const int maxBufferedEnvelopeCount = 128;
  static const int maxBufferedEnvelopeBytes = 4 * 1024 * 1024;
  static const Duration _watchdogEpsilon = Duration(microseconds: 1);
  static const Set<String> _authorizationErrors = <String>{
    '第一个消息必须为授权信息',
    '未发现授权信息',
    '授权信息未找到或已过期',
  };

  final ApiConfig _config;
  final ClientKind _client;
  final CredentialStore _credentialStore;
  final SyncApi _syncApi;
  final SocketTransport _socketTransport;
  final Duration Function() _clock;
  final Scheduler _scheduler;
  final StreamController<ConnectionPhase> _phaseController =
      StreamController<ConnectionPhase>.broadcast(sync: true);
  final StreamController<SyncEnvelope> _eventController =
      StreamController<SyncEnvelope>.broadcast(sync: true);
  final StreamController<AppFailure> _failureController =
      StreamController<AppFailure>.broadcast(sync: true);

  late final Stream<ConnectionPhase> phases;
  late final Stream<SyncEnvelope> events;
  late final Stream<AppFailure> failures;

  ConnectionPhase _phase = ConnectionPhase.blocked;
  String? _cursor;
  Duration? _lastMessageAt;
  SocketConnection? _connection;
  // The subscription is cancelled on every recovery, stop, and dispose path.
  // ignore: cancel_subscriptions
  StreamSubscription<Object?>? _incomingSubscription;
  ScheduledHandle? _watchdogHandle;
  ScheduledHandle? _reconnectHandle;
  Object? _reconnectToken;
  _ReconciliationBuffer? _reconciliationBuffer;
  int _generation = 0;
  bool _running = false;
  bool _disposed = false;

  ConnectionPhase get phase => _phase;
  String? get cursor => _cursor;
  bool get isRunning => _running;
  bool get isDisposed => _disposed;

  Uri get socketUri => _config.websocketBase.replace(
    pathSegments: <String>[..._config.websocketBase.pathSegments, 'sync'],
  );

  Future<void> start() async {
    if (_disposed || _running) return;
    _running = true;
    final generation = ++_generation;
    _setPhase(ConnectionPhase.reconciling);
    await _attemptConnection(generation);
  }

  Future<void> _attemptConnection(int generation) async {
    if (!_isCurrent(generation)) return;
    final requestedCursor = _cursor;
    _reconciliationBuffer = _ReconciliationBuffer(generation);

    final CredentialSnapshot snapshot;
    try {
      snapshot = await _credentialStore.readSnapshot();
    } on Object {
      if (_isCurrent(generation)) {
        await _block(generation, _credentialsUnavailableFailure);
      }
      return;
    }
    if (!_isCurrent(generation)) return;
    final token = snapshot.tk;
    if (token == null || token.trim().isEmpty) {
      await _block(generation, _credentialRequiredFailure);
      return;
    }
    if (token.length > maxCredentialLength) {
      await _block(generation, _credentialInvalidFailure);
      return;
    }

    final SocketConnection connection;
    try {
      connection = await _socketTransport.connect(socketUri);
    } on Object {
      _recover(generation, _socketUnavailableFailure);
      return;
    }
    if (!_isCurrent(generation)) {
      await _closeQuietly(connection);
      return;
    }
    _connection = connection;

    try {
      await connection.ready;
      if (!_isCurrent(generation)) {
        await _closeQuietly(connection);
        return;
      }
      _incomingSubscription = connection.incoming.listen(
        (message) => unawaited(_handleIncoming(generation, token, message)),
        onError: (Object _, StackTrace _) =>
            _recover(generation, _socketUnavailableFailure),
        onDone: () => _recover(generation, _socketClosedFailure),
        cancelOnError: false,
      );
      await connection.sendText(jsonEncode(token));
    } on Object {
      _recover(generation, _socketUnavailableFailure);
      return;
    }
    if (!_isCurrent(generation)) return;
    _lastMessageAt = _clock();

    final Result<SyncBatch> syncResult;
    try {
      syncResult = requestedCursor == null
          ? await _syncApi.fetchAll(_client)
          : await _syncApi.fetchIncrement(_client, requestedCursor);
    } on Object {
      _recover(generation, _syncUnavailableFailure);
      return;
    }
    if (!_isCurrent(generation)) return;
    final failure = syncResult.failureOrNull;
    if (failure != null) {
      if (failure.kind == FailureKind.authentication) {
        await _block(generation, failure);
      } else {
        _recover(generation, failure);
      }
      return;
    }
    final batch = syncResult.valueOrNull!;
    if (!SyncEnvelope.isCanonicalCursor(batch.cursor)) {
      _recover(generation, _syncShapeFailure);
      return;
    }
    final batchCursor = batch.cursor;
    if (requestedCursor != null && batchCursor.compareTo(requestedCursor) < 0) {
      _recover(generation, _syncShapeFailure);
      return;
    }
    if (batch.hasChanges) {
      final batchEnvelope = SyncEnvelope.parse(<String, Object?>{
        'p': SyncEventType.data.code,
        't': batchCursor,
        'd': batch.data,
      });
      final envelopeFailure = batchEnvelope.failureOrNull;
      if (envelopeFailure != null) {
        _recover(generation, envelopeFailure);
        return;
      }
      if (!_eventController.isClosed) {
        _eventController.add(batchEnvelope.valueOrNull!);
      }
      if (!_isCurrent(generation)) return;
    }
    _cursor = batchCursor;
    if (!_replayBufferedEnvelopes(generation, batchCursor)) return;
    _setPhase(ConnectionPhase.online);
    _scheduleWatchdog(generation);
  }

  Future<void> _handleIncoming(
    int generation,
    String sentToken,
    Object? message,
  ) async {
    if (!_isCurrent(generation)) return;
    final result = SyncEnvelope.parse(message);
    final parseFailure = result.failureOrNull;
    if (parseFailure != null) {
      _recover(generation, parseFailure);
      return;
    }
    final envelope = result.valueOrNull!;
    switch (envelope.type) {
      case SyncEventType.data:
      case SyncEventType.heartbeat:
        _lastMessageAt = _clock();
        final buffer = _reconciliationBuffer;
        if (buffer != null && buffer.generation == generation) {
          final messageBytes = _encodedMessageBytes(message, envelope);
          if (!buffer.add(
            envelope,
            messageBytes,
            maxCount: maxBufferedEnvelopeCount,
            maxBytes: maxBufferedEnvelopeBytes,
          )) {
            _recover(generation, _bufferOverflowFailure);
          }
          return;
        }
        _applyLiveEnvelope(generation, envelope);
      case SyncEventType.serverError:
        if (_authorizationErrors.contains(envelope.data)) {
          if (!_eventController.isClosed) {
            _eventController.add(
              SyncEnvelope.safeServerError(cursor: envelope.cursor),
            );
          }
          await _blockAuthentication(generation, sentToken);
          return;
        }
        if (!_eventController.isClosed) {
          _eventController.add(
            SyncEnvelope.safeServerError(cursor: envelope.cursor),
          );
        }
        _recover(generation, _serverFailure);
    }
  }

  Future<void> _blockAuthentication(int generation, String sentToken) async {
    if (!_isCurrent(generation)) return;
    await _block(generation, _authorizationFailure);
    try {
      await _credentialStore.clearTkIfMatches(sentToken);
    } on Object {
      // Authentication is still blocked; conditional cleanup is best effort.
    }
  }

  Future<void> _block(int generation, AppFailure failure) {
    if (!_isCurrent(generation)) return Future<void>.value();
    _running = false;
    _generation += 1;
    _reconciliationBuffer = null;
    _cancelScheduledWork();
    final subscription = _incomingSubscription;
    _incomingSubscription = null;
    final connection = _connection;
    _connection = null;
    if (subscription != null) unawaited(subscription.cancel());
    if (connection != null) unawaited(_closeQuietly(connection));
    _emitFailure(failure);
    _setPhase(ConnectionPhase.blocked);
    return Future<void>.value();
  }

  void _recover(int generation, AppFailure failure) {
    if (!_isCurrent(generation) || _reconnectHandle != null) return;
    final recoveryGeneration = ++_generation;
    _reconciliationBuffer = null;
    _cancelWatchdog();
    final subscription = _incomingSubscription;
    _incomingSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    final connection = _connection;
    _connection = null;
    if (connection != null) unawaited(_closeQuietly(connection));
    _setPhase(ConnectionPhase.reconciling);
    final reconnectToken = Object();
    _reconnectToken = reconnectToken;
    final reconnectHandle = _scheduler.schedule(reconnectDelay, () {
      if (identical(_reconnectToken, reconnectToken)) {
        _reconnectToken = null;
        _reconnectHandle = null;
      }
      if (!_isCurrent(recoveryGeneration)) return;
      unawaited(_attemptConnection(recoveryGeneration));
    });
    if (identical(_reconnectToken, reconnectToken)) {
      _reconnectHandle = reconnectHandle;
    } else {
      reconnectHandle.cancel();
    }
    _emitFailure(failure);
  }

  void _scheduleWatchdog(int generation) {
    _cancelWatchdog();
    final lastMessageAt = _lastMessageAt;
    if (lastMessageAt == null || !_isCurrent(generation)) return;
    final elapsed = _clock() - lastMessageAt;
    final delay = elapsed > heartbeatTimeout
        ? Duration.zero
        : elapsed == heartbeatTimeout
        ? _watchdogEpsilon
        : heartbeatTimeout - elapsed;
    _watchdogHandle = _scheduler.schedule(delay, () {
      _watchdogHandle = null;
      if (!_isCurrent(generation)) return;
      final last = _lastMessageAt;
      if (last == null) return;
      if (_clock() - last > heartbeatTimeout) {
        _recover(generation, _heartbeatFailure);
      } else {
        _scheduleWatchdog(generation);
      }
    });
  }

  Future<void> stop() => _stopInternal();

  Future<void> _stopInternal() async {
    if (!_running &&
        _connection == null &&
        _incomingSubscription == null &&
        _reconnectHandle == null &&
        _watchdogHandle == null) {
      _setPhase(ConnectionPhase.blocked);
      return;
    }
    _running = false;
    _generation += 1;
    _reconciliationBuffer = null;
    _cancelScheduledWork();
    final subscription = _incomingSubscription;
    _incomingSubscription = null;
    final connection = _connection;
    _connection = null;
    _setPhase(ConnectionPhase.blocked);
    await Future.wait<void>(<Future<void>>[
      if (subscription != null) subscription.cancel(),
      if (connection != null) _closeQuietly(connection),
    ]);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _stopInternal();
    await Future.wait<void>(<Future<void>>[
      _phaseController.close(),
      _eventController.close(),
      _failureController.close(),
    ]);
  }

  bool _isCurrent(int generation) =>
      _running && !_disposed && generation == _generation;

  int _encodedMessageBytes(Object? message, SyncEnvelope envelope) {
    if (message is String) return utf8.encode(message).length;
    return utf8
        .encode(
          jsonEncode(<String, Object?>{
            'p': envelope.type.code,
            't': envelope.cursor,
            'd': envelope.data,
          }),
        )
        .length;
  }

  void _applyLiveEnvelope(int generation, SyncEnvelope envelope) {
    final currentCursor = _cursor;
    final envelopeCursor = envelope.cursor!;
    if (currentCursor == null || envelopeCursor.compareTo(currentCursor) > 0) {
      _cursor = envelopeCursor;
    }
    // Older and same-cursor payloads remain observable because they may carry
    // distinct changes, while the authoritative cursor never moves backward.
    if (!_eventController.isClosed) _eventController.add(envelope);
    if (_phase == ConnectionPhase.online && _isCurrent(generation)) {
      _scheduleWatchdog(generation);
    }
  }

  bool _replayBufferedEnvelopes(int generation, String batchCursor) {
    final buffer = _reconciliationBuffer;
    if (buffer == null || buffer.generation != generation) return false;
    var index = 0;
    while (index < buffer.envelopes.length) {
      if (!_isCurrent(generation)) return false;
      final envelope = buffer.envelopes[index++];
      final envelopeCursor = envelope.cursor!;
      if (envelopeCursor.compareTo(batchCursor) <= 0) continue;
      if (envelopeCursor.compareTo(_cursor!) > 0) _cursor = envelopeCursor;
      if (!_eventController.isClosed) _eventController.add(envelope);
    }
    if (!_isCurrent(generation)) return false;
    _reconciliationBuffer = null;
    return true;
  }

  void _cancelWatchdog() {
    _watchdogHandle?.cancel();
    _watchdogHandle = null;
  }

  void _cancelScheduledWork() {
    _cancelWatchdog();
    _reconnectToken = null;
    _reconnectHandle?.cancel();
    _reconnectHandle = null;
  }

  void _setPhase(ConnectionPhase value) {
    if (_phase == value) return;
    _phase = value;
    if (!_phaseController.isClosed) _phaseController.add(value);
  }

  void _emitFailure(AppFailure value) {
    if (!_failureController.isClosed) _failureController.add(value);
  }

  Future<void> _closeQuietly(SocketConnection connection) async {
    try {
      await connection.close();
    } on Object {
      // Never surface transport internals or credentials through cleanup errors.
    }
  }

  @override
  String toString() =>
      'RealtimeController(phase: ${_phase.name}, cursor: ${_cursor ?? 'none'})';

  static const AppFailure _credentialRequiredFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.tk_required',
    safeMessage: '请先完成终端授权',
  );
  static const AppFailure _credentialsUnavailableFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.credentials_unavailable',
    safeMessage: '登录信息不可用，请重新登录',
  );
  static const AppFailure _credentialInvalidFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.tk_invalid',
    safeMessage: '终端授权信息无效，请重新授权',
  );
  static const AppFailure _authorizationFailure = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.websocket_rejected',
    safeMessage: '实时连接授权已失效，请重新登录',
  );
  static const AppFailure _socketUnavailableFailure = AppFailure(
    kind: FailureKind.realtime,
    code: 'realtime.socket_unavailable',
    safeMessage: '实时连接暂时不可用，正在重试',
  );
  static const AppFailure _socketClosedFailure = AppFailure(
    kind: FailureKind.realtime,
    code: 'realtime.socket_closed',
    safeMessage: '实时连接已断开，正在恢复',
  );
  static const AppFailure _heartbeatFailure = AppFailure(
    kind: FailureKind.realtime,
    code: 'realtime.heartbeat_timeout',
    safeMessage: '实时连接响应超时，正在恢复',
  );
  static const AppFailure _serverFailure = AppFailure(
    kind: FailureKind.realtime,
    code: 'realtime.server_error',
    safeMessage: '实时同步服务返回错误，正在恢复',
  );
  static const AppFailure _syncUnavailableFailure = AppFailure(
    kind: FailureKind.realtime,
    code: 'realtime.reconciliation_failed',
    safeMessage: '服务端状态恢复失败，正在重试',
  );
  static const AppFailure _syncShapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.sync_cursor',
    safeMessage: '同步服务返回了无效游标',
  );
  static const AppFailure _bufferOverflowFailure = AppFailure(
    kind: FailureKind.realtime,
    code: 'realtime.reconciliation_buffer_overflow',
    safeMessage: '实时同步积压过多，正在重新恢复服务端状态',
  );
}

final class _ReconciliationBuffer {
  _ReconciliationBuffer(this.generation);

  final int generation;
  final List<SyncEnvelope> envelopes = <SyncEnvelope>[];
  int bytes = 0;

  bool add(
    SyncEnvelope envelope,
    int envelopeBytes, {
    required int maxCount,
    required int maxBytes,
  }) {
    if (envelopes.length >= maxCount || bytes + envelopeBytes > maxBytes) {
      return false;
    }
    envelopes.add(envelope);
    bytes += envelopeBytes;
    return true;
  }
}

final class _CurrentValueStream<T> extends Stream<T> {
  const _CurrentValueStream(this._source, this._current);

  final Stream<T> _source;
  final T Function() _current;

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
    StreamSubscription<T>? sourceSubscription;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        sourceSubscription = _source.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.add(_current());
      },
      onPause: () => sourceSubscription?.pause(),
      onResume: () => sourceSubscription?.resume(),
      onCancel: () => sourceSubscription?.cancel(),
    );
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
