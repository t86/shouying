import 'package:flutter/foundation.dart';
import 'package:foundation/foundation.dart';
import 'package:permissions/permissions.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:card_table/src/management_permissions.dart';

final class ManagementAccess {
  const ManagementAccess({
    required this.snapshot,
    required this.safeModeEnabled,
    this.sessionOnline = false,
  });
  final PermissionSnapshot snapshot;
  final bool safeModeEnabled;

  /// True only after the authenticated session owner starts this feed and the
  /// connection is online; role metadata may still be unknown.
  final bool sessionOnline;
  static ManagementAccess unavailable() => ManagementAccess(
    snapshot: PermissionSnapshot(
      available: false,
      roleIds: const {},
      moduleIds: const {},
      subPermissions: const {},
      stationId: null,
    ),
    safeModeEnabled: true,
  );
}

final class ManagementPermissionFeed extends ValueNotifier<ManagementAccess> {
  ManagementPermissionFeed() : super(ManagementAccess.unavailable());
  ManagementPermissionStore? _store;
  bool _online = false;
  int _revision = 0;
  int get revision => _revision;

  void start(String stationId) {
    _revision++;
    _store = ManagementPermissionStore(stationId: stationId);
    _online = false;
    _publish();
  }

  void setPhase(ConnectionPhase phase) {
    // RealtimeController retains its cursor on automatic reconnect, delivers
    // the reconciled increment and buffered data synchronously, then publishes
    // online. Keep this session's validated full baseline for that increment,
    // but never expose it while disconnected. start/reset discard identities;
    // malformed metadata still invalidates the store until a new full snapshot.
    _online = phase == ConnectionPhase.online;
    _publish();
  }

  void add(SyncEnvelope event) {
    if (event.type != SyncEventType.data || _store == null) return;
    _store!.apply(event.data);
    _publish();
  }

  void reset() {
    _revision++;
    _store = null;
    _online = false;
    _publish();
  }

  void _publish() {
    final store = _store;
    final next = !_online || store == null
        ? ManagementAccess.unavailable()
        : ManagementAccess(
            snapshot: store.snapshot,
            safeModeEnabled: store.safeModeEnabled,
            sessionOnline: true,
          );
    if (next.snapshot != value.snapshot ||
        next.safeModeEnabled != value.safeModeEnabled ||
        next.sessionOnline != value.sessionOnline) {
      _revision++;
    }
    value = next;
  }

  @override
  void dispose() {
    _store = null;
    super.dispose();
  }
}
