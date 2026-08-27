import 'package:permissions/permissions.dart';
import 'package:test/test.dart';

void main() {
  final roles = [
    {'station_id': 7, 'sys_role_id': 7, 'status': 1},
    {'station_id': 7, 'sys_role_id': 5, 'status': '1'},
    {'station_id': 7, 'sys_role_id': 1, 'status': 1.0},
    {'station_id': 7, 'sys_role_id': 11, 'status': 3},
    {'station_id': 8, 'sys_role_id': 6, 'status': 1},
  ];
  final modules = [
    {'station_id': 7, 'sys_module_id': 101, 'status': 1},
    {'station_id': 7, 'sys_module_id': 102, 'status': 3},
  ];

  test('normalizes fixture, deduplicates and sorts', () {
    final snapshot = PermissionNormalizer.normalize(
        stationId: 7, sysRole: roles, sysRoleDetail: modules);
    expect(snapshot.available, isTrue);
    expect(snapshot.roleIds, [1, 5, 7]);
    expect(snapshot.moduleIds, [101]);
    expect(snapshot.subPermissionIds, isEmpty);
  });

  test('invalid rows are ignored and null required data is unavailable', () {
    final snapshot = PermissionNormalizer.normalize(
      stationId: '7',
      sysRole: [
        {'station_id': 7, 'sys_role_id': '5', 'status': '1'},
        {'station_id': '07', 'sys_role_id': 8, 'status': 1},
        {'station_id': 7, 'sys_role_id': true, 'status': 1},
        {'station_id': 7, 'sys_role_id': -1, 'status': 1},
      ],
      sysRoleDetail: [
        {'station_id': 7, 'sys_module_id': 2.5, 'status': 1},
        {'station_id': 7, 'sys_module_id': 2, 'status': 1},
      ],
    );
    expect(snapshot.roleIds, [5]);
    expect(snapshot.moduleIds, [2]);
    expect(
        PermissionNormalizer.normalize(
            stationId: 7, sysRole: null, sysRoleDetail: []).available,
        isFalse);
  });

  test('subpermissions filter employee and active rows', () {
    final snapshot = PermissionNormalizer.normalize(
      stationId: 7,
      employeeId: 42,
      sysRole: roles,
      sysRoleDetail: modules,
      subPermissions: [
        {'emp_id': 42, 'sub_permission_id': 9, 'parent_id': 101, 'status': 1},
        {'emp_id': 42, 'sub_permission_id': 3, 'parent_id': 101, 'status': 1},
        {'emp_id': 4, 'sub_permission_id': 1, 'parent_id': 101, 'status': 1},
      ],
    );
    expect(snapshot.subPermissionIds, [3, 9]);
  });

  test('engine applies any roles and all modules/subpermissions', () {
    final snapshot = PermissionNormalizer.normalize(
        stationId: 7, sysRole: roles, sysRoleDetail: modules);
    final engine = PermissionEngine(snapshot);
    expect(engine.decide(const PermissionRequirement()).reason,
        'permission.allowed');
    expect(
        engine.decide(const PermissionRequirement(anyRoleIds: {5, 99})).allowed,
        isTrue);
    expect(
        engine
            .decide(const PermissionRequirement(allModuleIds: {101, 102}))
            .reason,
        'permission.module_missing');
    expect(
        engine
            .decide(const PermissionRequirement(
                anyRoleIds: {99}, allModuleIds: {101}))
            .reason,
        'permission.role_missing');
  });
}
