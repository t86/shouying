import 'package:permissions/src/permission_models.dart';

abstract final class PermissionNormalizer {
  static PermissionSnapshot normalize({
    required Object? stationId,
    required Object? sysRole,
    required Object? sysRoleDetail,
    Object? subPermissions,
    Object? employeeId,
  }) {
    final station = _integer(stationId, positive: true);
    final valid = station != null && sysRole is List && sysRoleDetail is List;
    if (!valid) {
      return PermissionSnapshot(
          available: false,
          stationId: station,
          roleIds: const {},
          moduleIds: const {},
          subPermissionIds: const {});
    }
    final roles = <int>{};
    for (final row in sysRole) {
      if (row is! Map) {
        continue;
      }
      if (_integer(row['station_id'], positive: true) != station ||
          _status(row['status']) != 1) {
        continue;
      }
      final id = _integer(row['sys_role_id'], positive: true);
      if (id != null) roles.add(id);
    }
    final modules = <int>{};
    for (final row in sysRoleDetail) {
      if (row is! Map) {
        continue;
      }
      if (_integer(row['station_id'], positive: true) != station ||
          _status(row['status']) != 1) {
        continue;
      }
      final id = _integer(row['sys_module_id'], positive: true);
      if (id != null) modules.add(id);
    }
    final subs = <int>{};
    final employee = _integer(employeeId, positive: true);
    if (employee != null && subPermissions is List) {
      for (final row in subPermissions) {
        if (row is! Map ||
            _integer(row['emp_id'], positive: true) != employee ||
            _status(row['status']) != 1) {
          continue;
        }
        final parent = _integer(row['parent_id'], positive: true);
        final id = _integer(row['sub_permission_id'], positive: true);
        if (parent != null && id != null) subs.add(id);
      }
    }
    return PermissionSnapshot(
        available: true,
        stationId: station,
        roleIds: roles,
        moduleIds: modules,
        subPermissionIds: subs);
  }
}

PermissionSnapshot normalizePermissions({
  required Object? stationId,
  required Object? sysRole,
  required Object? sysRoleDetail,
  Object? subPermissions,
  Object? employeeId,
}) =>
    PermissionNormalizer.normalize(
        stationId: stationId,
        sysRole: sysRole,
        sysRoleDetail: sysRoleDetail,
        subPermissions: subPermissions,
        employeeId: employeeId);

int? _integer(Object? value, {required bool positive}) {
  if (value is bool || value == null) {
    return null;
  }
  int? result;
  if (value is int) {
    result = value;
  } else if (value is num && value.isFinite && value == value.truncate()) {
    result = value.toInt();
  } else if (value is String && _canonicalInteger(value)) {
    result = int.tryParse(value);
  }
  if (result == null ||
      result.abs() > 9007199254740991 ||
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
