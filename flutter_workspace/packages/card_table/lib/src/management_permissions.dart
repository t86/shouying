import 'package:permissions/permissions.dart';
import 'package:protocol/protocol.dart';

/// Management metadata has no dependency on card tables or business days.
/// Lists are complete snapshots; maps contain incremental dataset updates.
final class ManagementPermissionStore {
  ManagementPermissionStore({required this.stationId});

  final String stationId;
  final Map<String, List<int>> _roles = {};
  final Map<String, List<int>> _modules = {};
  final Map<int, int> _safety = {};
  bool _permissionsKnown = false;
  bool _safeModeKnown = false;

  PermissionSnapshot get snapshot => PermissionNormalizer.normalize(
    stationId: stationId,
    sysRole: _permissionsKnown ? _wireRows(_roles, 'sys_role_id') : null,
    sysRoleDetail: _permissionsKnown
        ? _wireRows(_modules, 'sys_module_id')
        : null,
  );

  bool get safeModeKnown => _safeModeKnown;
  bool get safeModeEnabled => !_safeModeKnown || _safety[1] == 1;

  void invalidate() {
    _permissionsKnown = false;
    _safeModeKnown = false;
    _roles.clear();
    _modules.clear();
    _safety.clear();
  }

  void apply(Object? rawData) {
    try {
      final full = rawData is List;
      final datasets = <int, Object?>{};
      if (rawData is List) {
        for (final id in [13, 41, 54]) {
          datasets[id] = id < rawData.length ? rawData[id] : null;
        }
      } else if (rawData is Map) {
        for (final entry in rawData.entries) {
          final key = entry.key;
          final index = key is int ? key : int.tryParse('$key');
          if (![13, 41, 54].contains(index)) continue;
          // Reject ambiguous aliases instead of depending on map iteration order.
          if ((key is! int && key != '$index') || datasets.containsKey(index)) {
            throw const FormatException('Ambiguous permission dataset');
          }
          datasets[index!] = entry.value;
        }
      } else {
        throw const FormatException('Expected full list or incremental map');
      }
      if (full) invalidate();
      for (final id in [13, 41]) {
        if (!datasets.containsKey(id)) continue;
        final value = datasets[id];
        if (full && value == null) continue;
        final rows = _rows(value, 3);
        final target = id == 13 ? _roles : _modules;
        for (final row in rows) {
          target['${row[0]}|${row[1]}'] = row;
        }
        if (target.length > 10000) throw const FormatException('Too many rows');
      }
      if (full) {
        _permissionsKnown = datasets[13] != null && datasets[41] != null;
      }
      if (datasets.containsKey(54)) {
        if (full && datasets[54] == null) return;
        final rows = _rows(datasets[54], 2);
        for (final row in rows) {
          _safety[row[0]] = row[1];
        }
        if (_safety.length > 10000) {
          throw const FormatException('Too many rows');
        }
        if (full || rows.any((row) => row[0] == 1)) _safeModeKnown = true;
      }
    } on Object {
      // Neither an old grant nor a subsequent partial patch may restore access.
      invalidate();
    }
  }

  static List<Map<String, Object?>> _wireRows(
    Map<String, List<int>> rows,
    String idKey,
  ) => [
    for (final row in rows.values)
      {'station_id': row[0], idKey: row[1], 'status': row[2]},
  ];

  static List<List<int>> _rows(Object? value, int width) {
    if (value is! List || value.length > 10000) {
      throw const FormatException('Invalid permission rows');
    }
    return [
      for (final row in value)
        if (row is List && row.length >= width && row.length <= 64)
          [
            for (var i = 0; i < width; i++)
              _integer(row[i], positive: i < width - 1),
          ]
        else
          throw const FormatException('Invalid permission row'),
    ];
  }

  static int _integer(Object? value, {required bool positive}) {
    final int? parsed;
    if (value is int) {
      parsed = value;
    } else if (value is num && value.isFinite && value == value.truncate()) {
      parsed = value.toInt();
    } else if (value is String &&
        value.length <= 16 &&
        RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(value)) {
      parsed = int.tryParse(value);
    } else {
      parsed = null;
    }
    if (parsed == null ||
        parsed > 9007199254740991 ||
        (positive ? parsed <= 0 : parsed < 0)) {
      throw const FormatException('Invalid permission integer');
    }
    return parsed;
  }
}

/// Vue ManagementSystem.authority group metadata, not arbitrary role guessing.
/// `systems` grants direct client visibility; `authorizationClients` adds only
/// the explicitly marked ERP empty-bottle or Wine cross-system extensions.
bool managementGroupVisible({
  required ClientKind client,
  required String groupName,
  required Iterable<ClientKind> systems,
  Iterable<ClientKind> authorizationClients = const [],
  bool needsAuthorization = false,
  required PermissionSnapshot snapshot,
  required bool safeModeEnabled,
  bool? sessionOnline,
}) {
  // Legacy callers use a validated snapshot as their online evidence. New
  // callers explicitly supply authenticated session connectivity, independently
  // of whether role datasets have arrived.
  if (!(sessionOnline ?? snapshot.available) ||
      (safeModeEnabled && groupName == '人员管理')) {
    return false;
  }
  if (systems.contains(client)) return true;
  if (!snapshot.available) return false;
  if (!needsAuthorization || !authorizationClients.contains(client)) {
    return false;
  }
  return (client == ClientKind.erp && snapshot.moduleIds.contains(25)) ||
      (client == ClientKind.wine &&
          snapshot.roleIds.contains(10) &&
          !snapshot.moduleIds.contains(50));
}
