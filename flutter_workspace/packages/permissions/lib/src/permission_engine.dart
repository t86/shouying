import 'package:permissions/src/permission_models.dart';

final class PermissionEngine {
  const PermissionEngine(this.snapshot);
  final PermissionSnapshot snapshot;

  PermissionDecision decide(PermissionRequirement requirement) {
    if (!snapshot.available) return _deny('permission.data_unavailable');
    if (requirement.anyRoleIds.isNotEmpty &&
        snapshot.roleIds.intersection(requirement.anyRoleIds).isEmpty) {
      return _deny('permission.role_missing');
    }
    if (!snapshot.moduleIds.containsAll(requirement.allModuleIds)) {
      return _deny('permission.module_missing');
    }
    if (!snapshot.subPermissions.containsAll(requirement.allSubPermissions)) {
      return _deny('permission.sub_permission_missing');
    }
    return PermissionDecision(
        allowed: true,
        reason: 'permission.allowed',
        authorizationRequirement: AuthorizationRequirement.unknown,
        effectiveScope: _copy());
  }

  PermissionDecision _deny(String reason) => PermissionDecision(
      allowed: false,
      reason: reason,
      authorizationRequirement: AuthorizationRequirement.unknown,
      effectiveScope: _copy());

  PermissionSnapshot _copy() => PermissionSnapshot(
      available: snapshot.available,
      stationId: snapshot.stationId,
      roleIds: snapshot.roleIds,
      moduleIds: snapshot.moduleIds,
      subPermissions: snapshot.subPermissions);
}
