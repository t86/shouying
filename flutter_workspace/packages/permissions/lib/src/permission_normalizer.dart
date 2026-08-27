import 'dart:convert';

import 'package:permissions/src/permission_models.dart';

const _maxRows = 10000;
const _maxStringLength = 32;
const _safeInteger = 9007199254740991;

abstract final class PermissionNormalizer {
  /// Normalizes permission data from protocol-decoded JSON or explicitly
  /// normalized ordinary maps in materialized or copied core lists.
  ///
  /// [List.unmodifiable] copies are supported, but const maps, [Map.unmodifiable]
  /// wrappers, and delegating collection views are unsupported because the
  /// immutable map implementations cannot be distinguished safely on every
  /// Dart runtime. The finite runtime-type whitelist is a conservative security
  /// boundary; unsupported required datasets or map wrappers fail closed as
  /// unavailable.
  static PermissionSnapshot normalize({
    required Object? stationId,
    required Object? sysRole,
    required Object? sysRoleDetail,
    Object? subPermissions,
    Object? employeeId,
  }) {
    final station = _integer(stationId, positive: true);
    try {
      if (station == null ||
          !_materializedList(sysRole) ||
          !_materializedList(sysRoleDetail)) {
        return _unavailable(station);
      }
      final roleRows = sysRole as List;
      final moduleRows = sysRoleDetail as List;
      if (roleRows.length > _maxRows || moduleRows.length > _maxRows) {
        return _unavailable(station);
      }
      final roles = <int>{};
      for (final row in roleRows) {
        if (!_materializedMap(row)) {
          if (row is Map) return _unavailable(station);
          continue;
        }
        final map = row as Map;
        if (map.length > 64 ||
            _integer(map['station_id'], positive: true) != station ||
            _status(map['status']) != 1) {
          continue;
        }
        final id = _integer(map['sys_role_id'], positive: true);
        if (id != null) roles.add(id);
      }
      final modules = <int>{};
      for (final row in moduleRows) {
        if (!_materializedMap(row)) {
          if (row is Map) return _unavailable(station);
          continue;
        }
        final map = row as Map;
        if (map.length > 64 ||
            _integer(map['station_id'], positive: true) != station ||
            _status(map['status']) != 1) {
          continue;
        }
        final id = _integer(map['sys_module_id'], positive: true);
        if (id != null) modules.add(id);
      }
      final subs = <SubPermissionKey>{};
      final employee = _integer(employeeId, positive: true);
      if (employee != null && _materializedList(subPermissions)) {
        final rows = subPermissions as List;
        if (rows.length > _maxRows) return _unavailable(station);
        for (final row in rows) {
          if (!_materializedMap(row)) {
            if (row is Map) return _unavailable(station);
            continue;
          }
          final map = row as Map;
          if (map.length > 64 ||
              _integer(map['emp_id'], positive: true) != employee ||
              _status(map['status']) != 1) {
            continue;
          }
          final parent = _integer(map['parent_id'], positive: true);
          final id = _integer(map['sub_permission_id'], positive: true);
          if (parent != null && id != null && modules.contains(parent)) {
            subs.add(SubPermissionKey(parent, id));
          }
        }
      }
      return PermissionSnapshot(
        available: true,
        stationId: station,
        roleIds: roles,
        moduleIds: modules,
        subPermissions: subs,
      );
    } catch (_) {
      return _unavailable(station);
    }
  }
}

/// Convenience wrapper for [PermissionNormalizer.normalize].
PermissionSnapshot normalizePermissions({
  required Object? stationId,
  required Object? sysRole,
  required Object? sysRoleDetail,
  Object? subPermissions,
  Object? employeeId,
}) => PermissionNormalizer.normalize(
  stationId: stationId,
  sysRole: sysRole,
  sysRoleDetail: sysRoleDetail,
  subPermissions: subPermissions,
  employeeId: employeeId,
);

PermissionSnapshot _unavailable(int? station) => PermissionSnapshot(
  available: false,
  stationId: station,
  roleIds: const {},
  moduleIds: const {},
  subPermissions: const {},
);

final _listTypes = <Type>{
  <dynamic>[].runtimeType,
  <Object>[].runtimeType,
  <Object?>[].runtimeType,
  <Map<String, String>>[].runtimeType,
  <Map<String, int>>[].runtimeType,
  <Map<String, double>>[].runtimeType,
  <Map<String, num>>[].runtimeType,
  <Map<String, Object>>[].runtimeType,
  <Map<String, Object?>>[].runtimeType,
  <Map<String, dynamic>>[].runtimeType,
  const <dynamic>[].runtimeType,
  const <Object>[].runtimeType,
  const <Object?>[].runtimeType,
  const <Map<String, String>>[].runtimeType,
  const <Map<String, int>>[].runtimeType,
  const <Map<String, double>>[].runtimeType,
  const <Map<String, num>>[].runtimeType,
  const <Map<String, Object>>[].runtimeType,
  const <Map<String, Object?>>[].runtimeType,
  const <Map<String, dynamic>>[].runtimeType,
  List<dynamic>.unmodifiable(const <dynamic>[]).runtimeType,
  List<Object>.unmodifiable(const <Object>[]).runtimeType,
  List<Object?>.unmodifiable(const <Object?>[]).runtimeType,
  List<Map<String, String>>.unmodifiable(const <Map<String, String>>[])
      .runtimeType,
  List<Map<String, int>>.unmodifiable(const <Map<String, int>>[]).runtimeType,
  List<Map<String, double>>.unmodifiable(const <Map<String, double>>[])
      .runtimeType,
  List<Map<String, num>>.unmodifiable(const <Map<String, num>>[]).runtimeType,
  List<Map<String, Object>>.unmodifiable(const <Map<String, Object>>[])
      .runtimeType,
  List<Map<String, Object?>>.unmodifiable(const <Map<String, Object?>>[])
      .runtimeType,
  List<Map<String, dynamic>>.unmodifiable(const <Map<String, dynamic>>[])
      .runtimeType,
  (jsonDecode('[]') as Object).runtimeType,
};
final _mapTypes = <Type>{
  <dynamic, dynamic>{}.runtimeType,
  <String, String>{}.runtimeType,
  <String, int>{}.runtimeType,
  <String, double>{}.runtimeType,
  <String, num>{}.runtimeType,
  <String, Object>{}.runtimeType,
  <String, Object?>{}.runtimeType,
  <String, dynamic>{}.runtimeType,
  (jsonDecode('{}') as Object).runtimeType,
};
bool _materializedList(Object? value) =>
    value is List && _listTypes.contains(value.runtimeType);
bool _materializedMap(Object? value) =>
    value is Map && _mapTypes.contains(value.runtimeType);

int? _integer(Object? value, {required bool positive}) {
  if (value is bool || value == null) {
    return null;
  }
  int? result;
  if (value is int) {
    result = value;
  } else if (value is num && value.isFinite && value == value.truncate()) {
    result = value.toInt();
  } else if (value is String &&
      value.length <= _maxStringLength &&
      _canonicalInteger(value)) {
    result = int.tryParse(value);
  }
  if (result == null ||
      result.abs() > _safeInteger ||
      (positive ? result <= 0 : result < 0)) {
    return null;
  }
  return result;
}

bool _canonicalInteger(String value) {
  if (value.isEmpty || (value.length > 1 && value.codeUnitAt(0) == 48)) {
    return false;
  }
  for (final unit in value.codeUnits) {
    if (unit < 48 || unit > 57) return false;
  }
  return true;
}

int? _status(Object? value) => _integer(value, positive: false);
