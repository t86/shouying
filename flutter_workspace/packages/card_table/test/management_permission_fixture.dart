import 'package:permissions/permissions.dart';

PermissionSnapshot managementTestPermissions({
  List<int> modules = const [],
  List<int> roles = const [],
}) => PermissionSnapshot(
  available: true,
  stationId: 1,
  roleIds: roles,
  moduleIds: modules,
  subPermissions: const [],
);
