import 'dart:collection';

final class PermissionSnapshot {
  PermissionSnapshot({
    required this.available,
    required Iterable<int> roleIds,
    required Iterable<int> moduleIds,
    required Iterable<int> subPermissionIds,
    required this.stationId,
  })  : roleIds = UnmodifiableSetView(SplayTreeSet.from(roleIds)),
        moduleIds = UnmodifiableSetView(SplayTreeSet.from(moduleIds)),
        subPermissionIds =
            UnmodifiableSetView(SplayTreeSet.from(subPermissionIds));

  final bool available;
  final Set<int> roleIds;
  final Set<int> moduleIds;
  final Set<int> subPermissionIds;
  final int? stationId;

  @override
  bool operator ==(Object other) =>
      other is PermissionSnapshot &&
      available == other.available &&
      stationId == other.stationId &&
      _same(roleIds, other.roleIds) &&
      _same(moduleIds, other.moduleIds) &&
      _same(subPermissionIds, other.subPermissionIds);

  @override
  int get hashCode => Object.hash(available, stationId, Object.hashAll(roleIds),
      Object.hashAll(moduleIds), Object.hashAll(subPermissionIds));

  @override
  String toString() =>
      'PermissionSnapshot(available: $available, stationId: $stationId, '
      'roles: $roleIds, modules: $moduleIds, subPermissions: $subPermissionIds)';
}

typedef PermissionContext = PermissionSnapshot;

final class PermissionRequirement {
  const PermissionRequirement({
    this.anyRoleIds = const {},
    this.allModuleIds = const {},
    this.allSubPermissionIds = const {},
  });

  final Set<int> anyRoleIds;
  final Set<int> allModuleIds;
  final Set<int> allSubPermissionIds;
}

final class PermissionDecision {
  const PermissionDecision({
    required this.allowed,
    required this.reason,
    required this.requiredAuthorization,
    required this.effectiveScope,
  });

  final bool allowed;
  final String reason;
  final bool requiredAuthorization;
  final PermissionSnapshot effectiveScope;
}

bool _same(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);
