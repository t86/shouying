import 'dart:collection';

final class SubPermissionKey implements Comparable<SubPermissionKey> {
  const SubPermissionKey(this.parentId, this.subPermissionId);
  final int parentId;
  final int subPermissionId;

  @override
  int compareTo(SubPermissionKey other) => parentId == other.parentId
      ? subPermissionId.compareTo(other.subPermissionId)
      : parentId.compareTo(other.parentId);

  @override
  bool operator ==(Object other) =>
      other is SubPermissionKey &&
      parentId == other.parentId &&
      subPermissionId == other.subPermissionId;

  @override
  int get hashCode => Object.hash(parentId, subPermissionId);

  @override
  String toString() => 'SubPermissionKey($parentId, $subPermissionId)';
}

final class PermissionSnapshot {
  factory PermissionSnapshot({
    required bool available,
    required Iterable<int> roleIds,
    required Iterable<int> moduleIds,
    required Iterable<SubPermissionKey> subPermissions,
    required int? stationId,
  }) {
    final copiedModuleIds = SplayTreeSet<int>.from(moduleIds);
    final copiedSubPermissions = SplayTreeSet<SubPermissionKey>.from(
      subPermissions.where(
        (subPermission) => copiedModuleIds.contains(subPermission.parentId),
      ),
    );
    return PermissionSnapshot._(
      available: available,
      roleIds: SplayTreeSet<int>.from(roleIds),
      moduleIds: copiedModuleIds,
      subPermissions: copiedSubPermissions,
      stationId: stationId,
    );
  }

  PermissionSnapshot._({
    required this.available,
    required SplayTreeSet<int> roleIds,
    required SplayTreeSet<int> moduleIds,
    required SplayTreeSet<SubPermissionKey> subPermissions,
    required this.stationId,
  }) : roleIds = UnmodifiableSetView(roleIds),
       moduleIds = UnmodifiableSetView(moduleIds),
       subPermissions = UnmodifiableSetView(subPermissions);

  final bool available;
  final Set<int> roleIds;
  final Set<int> moduleIds;
  final Set<SubPermissionKey> subPermissions;
  final int? stationId;

  @override
  bool operator ==(Object other) =>
      other is PermissionSnapshot &&
      available == other.available &&
      stationId == other.stationId &&
      _same(roleIds, other.roleIds) &&
      _same(moduleIds, other.moduleIds) &&
      _same(subPermissions, other.subPermissions);

  @override
  int get hashCode => Object.hash(
    available,
    stationId,
    Object.hashAll(roleIds),
    Object.hashAll(moduleIds),
    Object.hashAll(subPermissions),
  );

  @override
  String toString() =>
      'PermissionSnapshot(available: $available, stationId: $stationId, '
      'roles: $roleIds, modules: $moduleIds, subPermissions: $subPermissions)';
}

typedef PermissionContext = PermissionSnapshot;

final class PermissionRequirement {
  PermissionRequirement({
    Iterable<int> anyRoleIds = const {},
    Iterable<int> allModuleIds = const {},
    Iterable<SubPermissionKey> allSubPermissions = const {},
  }) : anyRoleIds = UnmodifiableSetView(SplayTreeSet.from(anyRoleIds)),
       allModuleIds = UnmodifiableSetView(SplayTreeSet.from(allModuleIds)),
       allSubPermissions = UnmodifiableSetView(
         SplayTreeSet.from(allSubPermissions),
       );

  final Set<int> anyRoleIds;
  final Set<int> allModuleIds;
  final Set<SubPermissionKey> allSubPermissions;

  @override
  bool operator ==(Object other) =>
      other is PermissionRequirement &&
      _same(anyRoleIds, other.anyRoleIds) &&
      _same(allModuleIds, other.allModuleIds) &&
      _same(allSubPermissions, other.allSubPermissions);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(anyRoleIds),
    Object.hashAll(allModuleIds),
    Object.hashAll(allSubPermissions),
  );

  @override
  String toString() =>
      'PermissionRequirement(anyRoleIds: $anyRoleIds, allModuleIds: $allModuleIds, allSubPermissions: $allSubPermissions)';
}

enum AuthorizationRequirement { unknown, notRequired, required }

final class PermissionDecision {
  const PermissionDecision({
    required this.allowed,
    required this.reason,
    required this.authorizationRequirement,
    required this.effectiveScope,
  });

  final bool allowed;
  final String reason;
  final AuthorizationRequirement authorizationRequirement;
  final PermissionSnapshot effectiveScope;

  @override
  bool operator ==(Object other) =>
      other is PermissionDecision &&
      allowed == other.allowed &&
      reason == other.reason &&
      authorizationRequirement == other.authorizationRequirement &&
      effectiveScope == other.effectiveScope;

  @override
  int get hashCode =>
      Object.hash(allowed, reason, authorizationRequirement, effectiveScope);

  @override
  String toString() =>
      'PermissionDecision(allowed: $allowed, reason: $reason, authorizationRequirement: $authorizationRequirement, effectiveScope: $effectiveScope)';
}

bool _same<T>(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);
