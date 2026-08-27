import 'package:permissions/permissions.dart';
import 'package:test/test.dart';

void main() {
  List<Map<String, Object?>> roles() => [
        {'station_id': 7, 'sys_role_id': 5, 'status': 1},
        {'station_id': 7, 'sys_role_id': 11, 'status': 3},
        {'station_id': 8, 'sys_role_id': 6, 'status': 1},
      ];
  List<Map<String, Object?>> modules() => [
        {'station_id': 7, 'sys_module_id': 101, 'status': 1},
        {'station_id': 7, 'sys_module_id': 102, 'status': 3},
      ];
  PermissionSnapshot make(
          {Object? r, Object? m, Object? s, Object? employee}) =>
      PermissionNormalizer.normalize(
          stationId: 7,
          sysRole: r ?? roles(),
          sysRoleDetail: m ?? modules(),
          subPermissions: s,
          employeeId: employee);

  test('canonical synthetic fixture', () {
    final result = make();
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('deduplicates, sorts, and preserves inputs and scopes', () {
    final r = <Map<String, Object?>>[
      {'station_id': 7, 'sys_role_id': 9, 'status': 1},
      {'station_id': 7, 'sys_role_id': 2, 'status': 1},
      {'station_id': 7, 'sys_role_id': 9, 'status': 1},
    ];
    final m = <Map<String, Object?>>[
      {'station_id': 7, 'sys_module_id': 30, 'status': 1},
      {'station_id': 7, 'sys_module_id': 4, 'status': 1},
      {'station_id': 7, 'sys_module_id': 30, 'status': 1},
    ];
    final beforeR = r.map((row) => Map<String, Object?>.from(row)).toList();
    final beforeM = m.map((row) => Map<String, Object?>.from(row)).toList();
    final result = make(r: r, m: m);
    expect(result.roleIds, [2, 9]);
    expect(result.moduleIds, [4, 30]);
    expect(r, beforeR);
    expect(m, beforeM);
    expect(() => result.roleIds.add(99), throwsUnsupportedError);
    final scope = PermissionEngine(result)
        .decide(const PermissionRequirement())
        .effectiveScope;
    expect(() => scope.moduleIds.add(99), throwsUnsupportedError);
  });

  test('integral doubles and canonical strings match', () {
    final doubles = make(r: [
      {'station_id': 7.0, 'sys_role_id': 5.0, 'status': 1.0}
    ], m: [
      {'station_id': 7.0, 'sys_module_id': 101.0, 'status': 1.0}
    ]);
    final strings = make(r: [
      {'station_id': '7', 'sys_role_id': '5', 'status': '1'}
    ], m: [
      {'station_id': '7', 'sys_module_id': '101', 'status': '1'}
    ]);
    expect(doubles, strings);
  });

  test('invalid values and malformed rows are ignored', () {
    final result = make(r: [
      {'station_id': 7, 'sys_role_id': true, 'status': 1},
      {'station_id': 7, 'sys_role_id': 2.5, 'status': 1},
      {'station_id': 7, 'sys_role_id': double.nan, 'status': 1},
      {'station_id': 7, 'sys_role_id': double.infinity, 'status': 1},
      {'station_id': 7, 'sys_role_id': 9007199254740992, 'status': 1},
      {'station_id': 7, 'sys_role_id': '07', 'status': 1},
      {'station_id': 7, 'sys_role_id': '5\u0000', 'status': 1},
      {'station_id': 7, 'sys_role_id': 0, 'status': 1},
      {'station_id': 7, 'sys_role_id': -1, 'status': 1},
      'malformed',
    ], m: [
      {'station_id': 7, 'sys_module_id': true, 'status': 1},
      {'station_id': 7, 'sys_module_id': 2.5, 'status': 1},
      'malformed',
    ]);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('required dataset availability and optional subpermissions', () {
    expect(
        PermissionNormalizer.normalize(
            stationId: 7, sysRole: null, sysRoleDetail: []).available,
        isFalse);
    expect(
        PermissionNormalizer.normalize(
                stationId: 7, sysRole: [], sysRoleDetail: null)
            .available,
        isFalse);
    expect(
        PermissionNormalizer.normalize(
            stationId: 7, sysRole: {}, sysRoleDetail: []).available,
        isFalse);
    final empty = PermissionNormalizer.normalize(
        stationId: 7, sysRole: [], sysRoleDetail: []);
    expect(empty.available, isTrue);
    expect(empty.roleIds, isEmpty);
    expect(make(employee: 42, s: null).subPermissionIds, isEmpty);
    expect(make(employee: 42, s: 'malformed').subPermissionIds, isEmpty);
    final sub = make(employee: 42, s: [
      {'emp_id': 42, 'sub_permission_id': 9, 'parent_id': 101, 'status': 1},
      {'emp_id': 42, 'sub_permission_id': 3, 'parent_id': 101, 'status': 1},
      {'emp_id': 42, 'sub_permission_id': 9, 'parent_id': 101, 'status': 1},
      {'emp_id': 42, 'sub_permission_id': 4, 'parent_id': 101, 'status': 3},
      {'emp_id': 4, 'sub_permission_id': 1, 'parent_id': 101, 'status': 1},
    ]);
    expect(sub.subPermissionIds, [3, 9]);
  });

  test('product, region, and limit fields do not expand scope', () {
    final result = make(r: [
      {
        'station_id': 7,
        'sys_role_id': 5,
        'status': 1,
        'product_id': 99,
        'region_id': 3,
        'limit': 100
      }
    ], m: [
      {
        'station_id': 7,
        'sys_module_id': 101,
        'status': 1,
        'product_id': 99,
        'region_id': 3,
        'limit': 100
      }
    ]);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('engine precedence and any/all semantics', () {
    final unavailableSnapshot = PermissionNormalizer.normalize(
        stationId: 7, sysRole: null, sysRoleDetail: []);
    final unavailableDecision = PermissionEngine(unavailableSnapshot)
        .decide(const PermissionRequirement());
    expect(unavailableDecision.allowed, isFalse);
    expect(unavailableDecision.reason, 'permission.data_unavailable');
    expect(unavailableDecision.requiredAuthorization, isFalse);
    expect(unavailableDecision.effectiveScope, unavailableSnapshot);
    expect(unavailableDecision.effectiveScope.available, isFalse);
    expect(unavailableDecision.effectiveScope.stationId, 7);
    expect(unavailableDecision.effectiveScope.roleIds, isEmpty);
    expect(unavailableDecision.effectiveScope.moduleIds, isEmpty);
    expect(unavailableDecision.effectiveScope.subPermissionIds, isEmpty);

    final availableSnapshot = make(employee: 42, s: [
      {'emp_id': 42, 'sub_permission_id': 8, 'parent_id': 101, 'status': 1}
    ]);
    final availableDecision = PermissionEngine(availableSnapshot)
        .decide(const PermissionRequirement());
    expect(availableDecision.allowed, isTrue);
    expect(availableDecision.reason, 'permission.allowed');
    expect(availableDecision.requiredAuthorization, isFalse);
    expect(availableDecision.effectiveScope, availableSnapshot);
    expect(availableDecision.effectiveScope.available, isTrue);
    expect(availableDecision.effectiveScope.stationId, 7);
    expect(availableDecision.effectiveScope.roleIds, [5]);
    expect(availableDecision.effectiveScope.moduleIds, [101]);
    expect(availableDecision.effectiveScope.subPermissionIds, [8]);
    expect(() => availableDecision.effectiveScope.roleIds.add(99),
        throwsUnsupportedError);
    final engine = PermissionEngine(availableSnapshot);
    expect(
        engine
            .decide(const PermissionRequirement(
                anyRoleIds: {99},
                allModuleIds: {999},
                allSubPermissionIds: {999}))
            .reason,
        'permission.role_missing');
    expect(
        engine
            .decide(const PermissionRequirement(
                allModuleIds: {999}, allSubPermissionIds: {999}))
            .reason,
        'permission.module_missing');
    expect(
        engine
            .decide(const PermissionRequirement(allSubPermissionIds: {999}))
            .reason,
        'permission.sub_permission_missing');
    expect(
        engine.decide(const PermissionRequirement(anyRoleIds: {5, 8})).allowed,
        isTrue);
    expect(engine.decide(const PermissionRequirement(anyRoleIds: {8})).allowed,
        isFalse);
    expect(
        engine.decide(const PermissionRequirement(allModuleIds: {101})).allowed,
        isTrue);
    expect(
        engine
            .decide(const PermissionRequirement(allModuleIds: {101, 999}))
            .allowed,
        isFalse);
    expect(
        engine
            .decide(const PermissionRequirement(allSubPermissionIds: {8}))
            .allowed,
        isTrue);
    expect(
        engine
            .decide(const PermissionRequirement(allSubPermissionIds: {8, 999}))
            .allowed,
        isFalse);
    for (final requirement in [
      const PermissionRequirement(),
      const PermissionRequirement(anyRoleIds: {99}),
      const PermissionRequirement(allModuleIds: {999}),
      const PermissionRequirement(allSubPermissionIds: {999})
    ]) {
      expect(engine.decide(requirement).requiredAuthorization, isFalse);
    }
  });
}
