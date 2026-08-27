import 'dart:collection';

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
    final scope =
        PermissionEngine(result).decide(PermissionRequirement()).effectiveScope;
    expect(() => scope.moduleIds.add(99), throwsUnsupportedError);
  });

  test('canonical string rows produce an available snapshot', () {
    final result = make(r: <Map<String, String>>[
      {'station_id': '7', 'sys_role_id': '5', 'status': '1'}
    ], m: <Map<String, String>>[
      {'station_id': '7', 'sys_module_id': '101', 'status': '1'}
    ]);
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('integral double rows produce an available snapshot', () {
    final result = make(r: <Map<String, double>>[
      {'station_id': 7.0, 'sys_role_id': 5.0, 'status': 1.0}
    ], m: <Map<String, double>>[
      {'station_id': 7.0, 'sys_module_id': 101.0, 'status': 1.0}
    ]);
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('num-typed rows produce an available snapshot', () {
    final result = make(r: <Map<String, num>>[
      {'station_id': 7, 'sys_role_id': 5.0, 'status': 1}
    ], m: <Map<String, num>>[
      {'station_id': 7.0, 'sys_module_id': 101, 'status': 1.0}
    ]);
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('List.unmodifiable and Map.unmodifiable rows are normalized', () {
    final roleRows = List<Map<String, String>>.unmodifiable([
      Map<String, String>.unmodifiable(
          {'station_id': '7', 'sys_role_id': '5', 'status': '1'})
    ]);
    final moduleRows = List<Map<String, double>>.unmodifiable([
      Map<String, double>.unmodifiable(
          {'station_id': 7.0, 'sys_module_id': 101.0, 'status': 1.0})
    ]);
    final result = make(r: roleRows, m: moduleRows);
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('unmodifiable collection views are normalized', () {
    final roleRows = UnmodifiableListView<Map<String, Object?>>([
      UnmodifiableMapView<String, Object?>(
          {'station_id': 7, 'sys_role_id': 5, 'status': 1})
    ]);
    final moduleRows = UnmodifiableListView<Map<String, double>>([
      UnmodifiableMapView<String, double>(
          {'station_id': 7.0, 'sys_module_id': 101.0, 'status': 1.0})
    ]);
    final result = make(r: roleRows, m: moduleRows);
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
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
    expect(make(employee: 42, s: null).subPermissions, isEmpty);
    expect(make(employee: 42, s: 'malformed').subPermissions, isEmpty);
    final sub = make(employee: 42, s: [
      {'emp_id': 42, 'sub_permission_id': 9, 'parent_id': 101, 'status': 1},
      {'emp_id': 42, 'sub_permission_id': 3, 'parent_id': 101, 'status': 1},
      {'emp_id': 42, 'sub_permission_id': 9, 'parent_id': 101, 'status': 1},
      {'emp_id': 42, 'sub_permission_id': 4, 'parent_id': 101, 'status': 3},
      {'emp_id': 4, 'sub_permission_id': 1, 'parent_id': 101, 'status': 1},
    ]);
    expect(sub.subPermissions,
        [SubPermissionKey(101, 3), SubPermissionKey(101, 9)]);
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
    final unavailableDecision =
        PermissionEngine(unavailableSnapshot).decide(PermissionRequirement());
    expect(unavailableDecision.allowed, isFalse);
    expect(unavailableDecision.reason, 'permission.data_unavailable');
    expect(unavailableDecision.authorizationRequirement,
        AuthorizationRequirement.unknown);
    expect(unavailableDecision.effectiveScope, unavailableSnapshot);
    expect(unavailableDecision.effectiveScope.available, isFalse);
    expect(unavailableDecision.effectiveScope.stationId, 7);
    expect(unavailableDecision.effectiveScope.roleIds, isEmpty);
    expect(unavailableDecision.effectiveScope.moduleIds, isEmpty);
    expect(unavailableDecision.effectiveScope.subPermissions, isEmpty);

    final availableSnapshot = make(employee: 42, s: [
      {'emp_id': 42, 'sub_permission_id': 8, 'parent_id': 101, 'status': 1}
    ]);
    final availableDecision =
        PermissionEngine(availableSnapshot).decide(PermissionRequirement());
    expect(availableDecision.allowed, isTrue);
    expect(availableDecision.reason, 'permission.allowed');
    expect(availableDecision.authorizationRequirement,
        AuthorizationRequirement.unknown);
    expect(availableDecision.effectiveScope, availableSnapshot);
    expect(availableDecision.effectiveScope.available, isTrue);
    expect(availableDecision.effectiveScope.stationId, 7);
    expect(availableDecision.effectiveScope.roleIds, [5]);
    expect(availableDecision.effectiveScope.moduleIds, [101]);
    expect(availableDecision.effectiveScope.subPermissions,
        [SubPermissionKey(101, 8)]);
    expect(() => availableDecision.effectiveScope.roleIds.add(99),
        throwsUnsupportedError);
    final engine = PermissionEngine(availableSnapshot);
    expect(
        engine
            .decide(PermissionRequirement(
                anyRoleIds: {99},
                allModuleIds: {999},
                allSubPermissions: {SubPermissionKey(101, 999)}))
            .reason,
        'permission.role_missing');
    expect(
        engine
            .decide(PermissionRequirement(
                allModuleIds: {999},
                allSubPermissions: {SubPermissionKey(101, 999)}))
            .reason,
        'permission.module_missing');
    expect(
        engine
            .decide(PermissionRequirement(
                allSubPermissions: {SubPermissionKey(101, 999)}))
            .reason,
        'permission.sub_permission_missing');
    expect(engine.decide(PermissionRequirement(anyRoleIds: {5, 8})).allowed,
        isTrue);
    expect(
        engine.decide(PermissionRequirement(anyRoleIds: {8})).allowed, isFalse);
    expect(engine.decide(PermissionRequirement(allModuleIds: {101})).allowed,
        isTrue);
    expect(
        engine.decide(PermissionRequirement(allModuleIds: {101, 999})).allowed,
        isFalse);
    expect(
        engine
            .decide(PermissionRequirement(
                allSubPermissions: {SubPermissionKey(101, 8)}))
            .allowed,
        isTrue);
    expect(
        engine
            .decide(PermissionRequirement(allSubPermissions: {
              SubPermissionKey(101, 8),
              SubPermissionKey(101, 999)
            }))
            .allowed,
        isFalse);
    for (final requirement in [
      PermissionRequirement(),
      PermissionRequirement(anyRoleIds: {99}),
      PermissionRequirement(allModuleIds: {999}),
      PermissionRequirement(allSubPermissions: {SubPermissionKey(101, 999)})
    ]) {
      expect(engine.decide(requirement).authorizationRequirement,
          AuthorizationRequirement.unknown);
    }
  });

  test('composite subpermission keys prevent cross-module leakage', () {
    final result = make(
        m: [
          {'station_id': 7, 'sys_module_id': 101, 'status': 1},
          {'station_id': 7, 'sys_module_id': 202, 'status': 1},
        ],
        employee: 42,
        s: [
          {'emp_id': 42, 'sub_permission_id': 8, 'parent_id': 101, 'status': 1},
          {'emp_id': 42, 'sub_permission_id': 8, 'parent_id': 202, 'status': 1},
          {'emp_id': 42, 'sub_permission_id': 9, 'parent_id': 999, 'status': 1},
        ]);
    expect(result.subPermissions,
        [SubPermissionKey(101, 8), SubPermissionKey(202, 8)]);
    final engine = PermissionEngine(result);
    expect(
        engine
            .decide(PermissionRequirement(
                allSubPermissions: {SubPermissionKey(101, 8)}))
            .allowed,
        isTrue);
    expect(
        engine
            .decide(PermissionRequirement(
                allSubPermissions: {SubPermissionKey(303, 8)}))
            .allowed,
        isFalse);
  });

  test('requirements defensively copy inputs and have value semantics', () {
    final roles = <int>{5};
    final modules = <int>{101};
    final subs = <SubPermissionKey>{SubPermissionKey(101, 8)};
    final requirement = PermissionRequirement(
        anyRoleIds: roles, allModuleIds: modules, allSubPermissions: subs);
    roles.add(999);
    modules.add(999);
    subs.add(const SubPermissionKey(202, 8));
    expect(requirement.anyRoleIds, [5]);
    expect(requirement.allModuleIds, [101]);
    expect(requirement.allSubPermissions, [const SubPermissionKey(101, 8)]);
    expect(() => requirement.anyRoleIds.add(99), throwsUnsupportedError);
    final same = PermissionRequirement(
        anyRoleIds: {5},
        allModuleIds: {101},
        allSubPermissions: {const SubPermissionKey(101, 8)});
    expect(requirement, same);
    expect(requirement.hashCode, same.hashCode);
    expect(requirement.toString(), contains('5'));
  });

  test('row budget accepts exactly the boundary and rejects overflow', () {
    final rows = List<Map<String, Object?>>.generate(
        10000, (_) => {'station_id': 7, 'sys_role_id': 5, 'status': 1});
    expect(
        PermissionNormalizer.normalize(
            stationId: 7, sysRole: rows, sysRoleDetail: []).available,
        isTrue);
    rows.add({'station_id': 7, 'sys_role_id': 5, 'status': 1});
    expect(
        PermissionNormalizer.normalize(
            stationId: 7, sysRole: rows, sysRoleDetail: []).available,
        isFalse);
  });

  test('field budget accepts 64 fields and ignores a 65-field row', () {
    final accepted = <String, Object?>{
      'station_id': 7,
      'sys_role_id': 5,
      'status': 1,
    };
    final ignored = <String, Object?>{
      'station_id': 7,
      'sys_role_id': 99,
      'status': 1,
    };
    for (var index = 0; index < 61; index++) {
      accepted['filler_$index'] = index;
    }
    for (var index = 0; index < 62; index++) {
      ignored['filler_$index'] = index;
    }

    final result = make(r: [accepted, ignored], m: []);
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, isEmpty);
  });

  test('overlong numeric and control strings grant no unexpected role', () {
    final overlongNumeric = List.filled(33, '1').join();
    final overlongControl = '5${List.filled(32, '\u0000').join()}';
    final result = make(r: <Map<String, Object?>>[
      {
        'station_id': 7,
        'sys_role_id': '9007199254740991',
        'status': 1
      },
      {'station_id': 7, 'sys_role_id': overlongNumeric, 'status': 1},
      {'station_id': 7, 'sys_role_id': overlongControl, 'status': 1},
    ], m: <Map<String, Object?>>[]);

    expect(result.available, isTrue);
    expect(result.roleIds, [9007199254740991]);
    expect(result.moduleIds, isEmpty);
  });
}
