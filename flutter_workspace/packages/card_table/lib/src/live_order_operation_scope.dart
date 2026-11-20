import 'dart:async';

import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';

/// A page-owned, read-only scope. Table extras never supply product authority.
/// The session owner must replace/dispose this scope when identity changes.
final class LiveOrderOperationScope {
  LiveOrderOperationScope({
    required this.table,
    required Stream<SyncEnvelope> events,
    required Stream<ConnectionPhase> phases,
    required ConnectionPhase initialPhase,
    SyncEnvelope? initialSnapshot,
    this.invalidateOnStatusChange = true,
    this.canOperateInStatus,
  }) : _phase = initialPhase {
    if (initialSnapshot != null) _onEvent(initialSnapshot);
    _phaseSubscription = phases.listen(
      (phase) {
        if (_disposed) return;
        final becameOnline =
            _phase != ConnectionPhase.online && phase == ConnectionPhase.online;
        _phase = phase;
        _publish();
        if (becameOnline && _context.value != null) {
          _currentTableRevision.value++;
        }
      },
      onError: (Object _) => _streamFailed(),
      onDone: _streamFailed,
    );
    _eventSubscription = events.listen(
      _onEvent,
      onError: (Object _) => _streamFailed(),
      onDone: _streamFailed,
    );
  }

  final CardTable table;
  final bool invalidateOnStatusChange;
  final bool Function(int status)? canOperateInStatus;
  final LegacyCardTableStore _store = LegacyCardTableStore();
  final ValueNotifier<Object?> _context = ValueNotifier(null);
  final ValueNotifier<Object?> _refundContext = ValueNotifier(null);
  final ValueNotifier<int> _currentTableRevision = ValueNotifier(0);
  late final StreamSubscription<ConnectionPhase> _phaseSubscription;
  late final StreamSubscription<SyncEnvelope> _eventSubscription;
  ConnectionPhase _phase;
  String? _businessDay;
  int? _businessStatus;
  bool _snapshotKnown = false, _typesKnown = false, _needsFull = true;
  bool _expired = false, _disposed = false, _streamUnavailable = false;
  Future<void>? _disposal;

  ValueListenable<Object?> get context => _context;
  CardTableSnapshot? get snapshot =>
      _context.value == null ? null : _store.currentSnapshot;
  ValueListenable<int> get currentTableRevision => _currentTableRevision;

  /// Refund attempts always expire on a status transition, even when new-order
  /// operations are configured to retain their wider same-business scope.
  ValueListenable<Object?> get refundContext => _refundContext;

  void _clearContexts() {
    _context.value = null;
    _refundContext.value = null;
  }

  int? productTypeFor(String productId) =>
      _context.value == null ? null : _store.productTypeFor(productId);
  String? productNameFor(String productId) =>
      _context.value == null ? null : _store.productNameFor(productId);
  List<String> get refundReasons =>
      _context.value == null ? const [] : _store.refundReasons;

  void _streamFailed() {
    if (_disposed) return;
    _streamUnavailable = true;
    _clearContexts();
  }

  void _onEvent(SyncEnvelope event) {
    if (_disposed || _expired) return;
    if (event.type == SyncEventType.heartbeat) return;
    if (event.type != SyncEventType.data) {
      _needsFull = true;
      _clearContexts();
      return;
    }
    final data = event.data;
    final full =
        data is List ||
        (!_snapshotKnown &&
            data is Map &&
            [0, 1, 4, 14, 18].every((id) => _has(data, id)));
    final result = _store.applyEnvelope(event);
    if (result.failureOrNull != null ||
        (_has(data, 4) && !_validProductRows(_dataset(data, 4)))) {
      _needsFull = true;
      _typesKnown = false;
      _clearContexts();
      return;
    }
    _snapshotKnown = true;
    if (full) {
      _typesKnown = _validProductRows(_dataset(data, 4));
      _needsFull = false;
    }
    _publish();
    if (_context.value != null && (full || _touchesCurrentBusiness(data))) {
      _currentTableRevision.value++;
    }
  }

  bool _touchesCurrentBusiness(Object? data) {
    final rows = _dataset(data, 14);
    return rows is List &&
        rows.any(
          (row) =>
              row is List &&
              row.isNotEmpty &&
              num.tryParse('${row.first}') == num.tryParse(table.id),
        );
  }

  void _publish() {
    if (_disposed || _expired || _streamUnavailable) {
      _clearContexts();
      return;
    }
    final snapshot = _store.currentSnapshot;
    final current = snapshot?.tables
        .where((item) => item.id == table.id)
        .firstOrNull;
    if (snapshot != null && !_needsFull) {
      if (_businessDay != null && snapshot.businessDayId != _businessDay) {
        _expired = true;
      }
      if (current == null ||
          current.turnoverCount != table.turnoverCount ||
          !(canOperateInStatus?.call(current.businessStatus) ??
              const {4, 5, 6, 7}.contains(current.businessStatus)) ||
          !snapshot.businessOpen) {
        _expired = true;
      }
      if (!_expired && current != null) {
        _businessDay ??= snapshot.businessDayId;
        if (_businessStatus != null &&
            _businessStatus != current.businessStatus) {
          _refundContext.value = null;
          if (invalidateOnStatusChange) _context.value = null;
        }
        _businessStatus = current.businessStatus;
      }
    }
    if (_expired ||
        !_snapshotKnown ||
        !_typesKnown ||
        _needsFull ||
        _phase != ConnectionPhase.online ||
        current == null) {
      _clearContexts();
    } else {
      _context.value ??= Object();
      _refundContext.value ??= Object();
    }
  }

  static bool _has(Object? data, int id) => data is List
      ? data.length > id
      : data is Map && (data.containsKey(id) || data.containsKey('$id'));
  static Object? _dataset(Object? data, int id) => data is List
      ? (data.length > id ? data[id] : null)
      : data is Map
      ? (data[id] ?? data['$id'])
      : null;
  static bool _validProductRows(Object? rows) {
    if (rows is! List) return false;
    for (final row in rows) {
      if (row is! List || row.length < 10) return false;
      for (final index in [0, 2, 9]) {
        final value = num.tryParse('${row[index]}');
        if (value == null ||
            !value.isFinite ||
            value != value.truncate() ||
            value > 9007199254740991 ||
            value < (index == 2 ? 0 : 1)) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> close() => dispose();
  Future<void> dispose() {
    if (_disposal != null) return _disposal!;
    _disposed = true;
    _clearContexts();
    return _disposal =
        Future.wait([_eventSubscription.cancel(), _phaseSubscription.cancel()])
            .then((_) {
              _context.dispose();
              _refundContext.dispose();
              _currentTableRevision.dispose();
            });
  }
}
