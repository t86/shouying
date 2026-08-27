import 'dart:collection';
import 'dart:convert';

import 'package:permissions/permissions.dart';
import 'package:test/test.dart';

final class _HostileList extends ListBase<dynamic> {
  int accesses = 0;

  @override
  int get length {
    accesses++;
    return 1 << 30;
  }

  @override
  set length(int value) {
    accesses++;
    throw StateError('hostile list length mutation');
  }

  @override
  dynamic operator [](int index) {
    accesses++;
    throw StateError('hostile list read');
  }

  @override
  void operator []=(int index, dynamic value) {
    accesses++;
    throw StateError('hostile list write');
  }
}

final class _HostileMap extends MapBase<dynamic, dynamic> {
  int accesses = 0;

  @override
  dynamic operator [](Object? key) {
    accesses++;
    throw StateError('hostile map read');
  }

  @override
  void operator []=(dynamic key, dynamic value) {
    accesses++;
    throw StateError('hostile map write');
  }

  @override
  void clear() {
    accesses++;
    throw StateError('hostile map clear');
  }

  @override
  Iterable<dynamic> get keys {
    accesses++;
    throw StateError('hostile map iteration');
  }

  @override
  dynamic remove(Object? key) {
    accesses++;
    throw StateError('hostile map removal');
  }
}

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
  PermissionSnapshot make({
    Object? r,
    Object? m,
    Object? s,
    Object? employee,
  }) => PermissionNormalizer.normalize(
    stationId: 7,
    sysRole: r ?? roles(),
    sysRoleDetail: m ?? modules(),
    subPermissions: s,
    employeeId: employee,
  );
  PermissionSnapshot unmodifiableRows<T>({
    required T stationId,
    required T roleId,
    required T moduleId,
    required T status,
  }) => make(
    r: List<Map<String, T>>.unmodifiable([
      Map<String, T>.unmodifiable({
        'station_id': stationId,
        'sys_role_id': roleId,
        'status': status,
      }),
    ]),
    m: List<Map<String, T>>.unmodifiable([
      Map<String, T>.unmodifiable({
        'station_id': stationId,
        'sys_module_id': moduleId,
        'status': status,
      }),
    ]),
  );
  PermissionSnapshot copiedListRows<T>({
    required T stationId,
    required T roleId,
    required T moduleId,
    required T status,
  }) => make(
    r: List<Map<String, T>>.unmodifiable([
      <String, T>{
        'station_id': stationId,
        'sys_role_id': roleId,
        'status': status,
      },
    ]),
    m: List<Map<String, T>>.unmodifiable([
      <String, T>{
        'station_id': stationId,
        'sys_module_id': moduleId,
        'status': status,
      },
    ]),
  );
  PermissionSnapshot unmodifiableViewRows<T>({
    required T stationId,
    required T roleId,
    required T moduleId,
    required T status,
  }) => make(
    r: UnmodifiableListView<Map<String, T>>([
      UnmodifiableMapView<String, T>({
        'station_id': stationId,
        'sys_role_id': roleId,
        'status': status,
      }),
    ]),
    m: UnmodifiableListView<Map<String, T>>([
      UnmodifiableMapView<String, T>({
        'station_id': stationId,
        'sys_module_id': moduleId,
        'status': status,
      }),
    ]),
  );

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
        .decide(PermissionRequirement())
        .effectiveScope;
    expect(() => scope.moduleIds.add(99), throwsUnsupportedError);
  });

  test('canonical string rows produce an available snapshot', () {
    final result = make(
      r: <Map<String, String>>[
        {'station_id': '7', 'sys_role_id': '5', 'status': '1'},
      ],
      m: <Map<String, String>>[
        {'station_id': '7', 'sys_module_id': '101', 'status': '1'},
      ],
    );
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('integral double rows produce an available snapshot', () {
    final result = make(
      r: <Map<String, double>>[
        {'station_id': 7.0, 'sys_role_id': 5.0, 'status': 1.0},
      ],
      m: <Map<String, double>>[
        {'station_id': 7.0, 'sys_module_id': 101.0, 'status': 1.0},
      ],
    );
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('num-typed rows produce an available snapshot', () {
    final result = make(
      r: <Map<String, num>>[
        {'station_id': 7, 'sys_role_id': 5.0, 'status': 1},
      ],
      m: <Map<String, num>>[
        {'station_id': 7.0, 'sys_module_id': 101, 'status': 1.0},
      ],
    );
    expect(result.available, isTrue);
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('Map.unmodifiable rows make copied list datasets unavailable', () {
    final roleRows = List<Map<String, String>>.unmodifiable([
      Map<String, String>.unmodifiable({
        'station_id': '7',
        'sys_role_id': '5',
        'status': '1',
      }),
    ]);
    final moduleRows = List<Map<String, double>>.unmodifiable([
      Map<String, double>.unmodifiable({
        'station_id': 7.0,
        'sys_module_id': 101.0,
        'status': 1.0,
      }),
    ]);
    final result = make(r: roleRows, m: moduleRows);
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('const map rows make copied list datasets unavailable', () {
    final result = make(
      r: List<Map<String, int>>.unmodifiable(const [
        {'station_id': 7, 'sys_role_id': 5, 'status': 1},
      ]),
      m: List<Map<String, int>>.unmodifiable(const [
        {'station_id': 7, 'sys_module_id': 101, 'status': 1},
      ]),
    );

    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('delegating collection views are unavailable', () {
    final roleRows = UnmodifiableListView<Map<String, Object?>>([
      UnmodifiableMapView<String, Object?>({
        'station_id': 7,
        'sys_role_id': 5,
        'status': 1,
      }),
    ]);
    final moduleRows = UnmodifiableListView<Map<String, double>>([
      UnmodifiableMapView<String, double>({
        'station_id': 7.0,
        'sys_module_id': 101.0,
        'status': 1.0,
      }),
    ]);
    final result = make(r: roleRows, m: moduleRows);
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('List.unmodifiable rejects Map<String, int>.unmodifiable rows', () {
    final roleRows = List<Map<String, int>>.unmodifiable([
      Map<String, int>.unmodifiable({
        'station_id': 7,
        'sys_role_id': 5,
        'status': 1,
      }),
    ]);
    final moduleRows = List<Map<String, int>>.unmodifiable([
      Map<String, int>.unmodifiable({
        'station_id': 7,
        'sys_module_id': 101,
        'status': 1,
      }),
    ]);
    final result = make(r: roleRows, m: moduleRows);
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('List.unmodifiable rejects Map<String, num>.unmodifiable rows', () {
    final roleRows = List<Map<String, num>>.unmodifiable([
      Map<String, num>.unmodifiable({
        'station_id': 7,
        'sys_role_id': 5.0,
        'status': 1,
      }),
    ]);
    final moduleRows = List<Map<String, num>>.unmodifiable([
      Map<String, num>.unmodifiable({
        'station_id': 7.0,
        'sys_module_id': 101,
        'status': 1.0,
      }),
    ]);
    final result = make(r: roleRows, m: moduleRows);
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('UnmodifiableListView rejects int UnmodifiableMapView rows', () {
    final roleRows = UnmodifiableListView<Map<String, int>>([
      UnmodifiableMapView<String, int>({
        'station_id': 7,
        'sys_role_id': 5,
        'status': 1,
      }),
    ]);
    final moduleRows = UnmodifiableListView<Map<String, int>>([
      UnmodifiableMapView<String, int>({
        'station_id': 7,
        'sys_module_id': 101,
        'status': 1,
      }),
    ]);
    final result = make(r: roleRows, m: moduleRows);
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('UnmodifiableListView rejects num UnmodifiableMapView rows', () {
    final roleRows = UnmodifiableListView<Map<String, num>>([
      UnmodifiableMapView<String, num>({
        'station_id': 7,
        'sys_role_id': 5.0,
        'status': 1,
      }),
    ]);
    final moduleRows = UnmodifiableListView<Map<String, num>>([
      UnmodifiableMapView<String, num>({
        'station_id': 7.0,
        'sys_module_id': 101,
        'status': 1.0,
      }),
    ]);
    final result = make(r: roleRows, m: moduleRows);
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('List.unmodifiable rejects Map<String, Object>.unmodifiable rows', () {
    final result = unmodifiableRows<Object>(
      stationId: 7,
      roleId: 5,
      moduleId: 101,
      status: 1,
    );
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('List.unmodifiable rejects Map<String, dynamic>.unmodifiable rows', () {
    final result = unmodifiableRows<dynamic>(
      stationId: 7,
      roleId: 5,
      moduleId: 101,
      status: 1,
    );
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('UnmodifiableListView rejects Object UnmodifiableMapView rows', () {
    final result = unmodifiableViewRows<Object>(
      stationId: 7,
      roleId: 5,
      moduleId: 101,
      status: 1,
    );
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('UnmodifiableListView rejects dynamic UnmodifiableMapView rows', () {
    final result = unmodifiableViewRows<dynamic>(
      stationId: 7,
      roleId: 5,
      moduleId: 101,
      status: 1,
    );
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test(
    'copied lists succeed while map wrappers and views fail symmetrically',
    () {
      final copiedSnapshots = <String, PermissionSnapshot>{
        'List.unmodifiable<String>': copiedListRows<String>(
          stationId: '7',
          roleId: '5',
          moduleId: '101',
          status: '1',
        ),
        'List.unmodifiable<int>': copiedListRows<int>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
        'List.unmodifiable<double>': copiedListRows<double>(
          stationId: 7.0,
          roleId: 5.0,
          moduleId: 101.0,
          status: 1.0,
        ),
        'List.unmodifiable<num>': copiedListRows<num>(
          stationId: 7,
          roleId: 5.0,
          moduleId: 101,
          status: 1,
        ),
        'List.unmodifiable<Object>': copiedListRows<Object>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
        'List.unmodifiable<Object?>': copiedListRows<Object?>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
        'List.unmodifiable<dynamic>': copiedListRows<dynamic>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
      };
      final wrappedMapSnapshots = <String, PermissionSnapshot>{
        'Map.unmodifiable<String>': unmodifiableRows<String>(
          stationId: '7',
          roleId: '5',
          moduleId: '101',
          status: '1',
        ),
        'Map.unmodifiable<int>': unmodifiableRows<int>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
        'Map.unmodifiable<double>': unmodifiableRows<double>(
          stationId: 7.0,
          roleId: 5.0,
          moduleId: 101.0,
          status: 1.0,
        ),
        'Map.unmodifiable<num>': unmodifiableRows<num>(
          stationId: 7,
          roleId: 5.0,
          moduleId: 101,
          status: 1,
        ),
        'Map.unmodifiable<Object>': unmodifiableRows<Object>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
        'Map.unmodifiable<Object?>': unmodifiableRows<Object?>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
        'Map.unmodifiable<dynamic>': unmodifiableRows<dynamic>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
      };
      final delegatingSnapshots = <String, PermissionSnapshot>{
        'UnmodifiableListView<String>': unmodifiableViewRows<String>(
          stationId: '7',
          roleId: '5',
          moduleId: '101',
          status: '1',
        ),
        'UnmodifiableListView<int>': unmodifiableViewRows<int>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
        'UnmodifiableListView<double>': unmodifiableViewRows<double>(
          stationId: 7.0,
          roleId: 5.0,
          moduleId: 101.0,
          status: 1.0,
        ),
        'UnmodifiableListView<num>': unmodifiableViewRows<num>(
          stationId: 7,
          roleId: 5.0,
          moduleId: 101,
          status: 1,
        ),
        'UnmodifiableListView<Object>': unmodifiableViewRows<Object>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
        'UnmodifiableListView<Object?>': unmodifiableViewRows<Object?>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
        'UnmodifiableListView<dynamic>': unmodifiableViewRows<dynamic>(
          stationId: 7,
          roleId: 5,
          moduleId: 101,
          status: 1,
        ),
      };

      for (final entry in copiedSnapshots.entries) {
        expect(entry.value.available, isTrue, reason: entry.key);
        expect(entry.value.roleIds, [5], reason: entry.key);
        expect(entry.value.moduleIds, [101], reason: entry.key);
      }
      for (final entry in wrappedMapSnapshots.entries) {
        expect(entry.value.available, isFalse, reason: entry.key);
        expect(entry.value.roleIds, isEmpty, reason: entry.key);
        expect(entry.value.moduleIds, isEmpty, reason: entry.key);
      }
      for (final entry in delegatingSnapshots.entries) {
        expect(entry.value.available, isFalse, reason: entry.key);
        expect(entry.value.roleIds, isEmpty, reason: entry.key);
        expect(entry.value.moduleIds, isEmpty, reason: entry.key);
      }
    },
  );

  final copiedRawContainers = <String, Object Function(Map<dynamic, dynamic>)>{
    'List<dynamic>.unmodifiable + Map<dynamic, dynamic>': (row) =>
        List<dynamic>.unmodifiable([row]),
    'List<Object>.unmodifiable + Map<dynamic, dynamic>': (row) =>
        List<Object>.unmodifiable([row]),
    'List<Object?>.unmodifiable + Map<dynamic, dynamic>': (row) =>
        List<Object?>.unmodifiable([row]),
  };
  final wrappedRawMapContainers =
      <String, Object Function(Map<dynamic, dynamic>)>{
        'List<dynamic>.unmodifiable + Map<dynamic, dynamic>.unmodifiable':
            (row) => List<dynamic>.unmodifiable([
              Map<dynamic, dynamic>.unmodifiable(row),
            ]),
        'List<Object>.unmodifiable + Map<dynamic, dynamic>.unmodifiable':
            (row) => List<Object>.unmodifiable([
              Map<dynamic, dynamic>.unmodifiable(row),
            ]),
        'List<Object?>.unmodifiable + Map<dynamic, dynamic>.unmodifiable':
            (row) => List<Object?>.unmodifiable([
              Map<dynamic, dynamic>.unmodifiable(row),
            ]),
      };
  final delegatingRawContainers =
      <String, Object Function(Map<dynamic, dynamic>)>{
        'UnmodifiableListView<dynamic> + UnmodifiableMapView<dynamic, dynamic>':
            (row) => UnmodifiableListView<dynamic>([
              UnmodifiableMapView<dynamic, dynamic>(row),
            ]),
        'UnmodifiableListView<Object> + UnmodifiableMapView<dynamic, dynamic>':
            (row) => UnmodifiableListView<Object>([
              UnmodifiableMapView<dynamic, dynamic>(row),
            ]),
        'UnmodifiableListView<Object?> + UnmodifiableMapView<dynamic, dynamic>':
            (row) => UnmodifiableListView<Object?>([
              UnmodifiableMapView<dynamic, dynamic>(row),
            ]),
      };
  for (final entry in copiedRawContainers.entries) {
    test('${entry.key} normalizes decoded untyped rows', () {
      final roleRow = Map<dynamic, dynamic>.from(
        jsonDecode('{"station_id":7,"sys_role_id":5,"status":1}') as Map,
      );
      final moduleRow = Map<dynamic, dynamic>.from(
        jsonDecode('{"station_id":7,"sys_module_id":101,"status":1}') as Map,
      );
      final result = make(r: entry.value(roleRow), m: entry.value(moduleRow));

      expect(result.available, isTrue);
      expect(result.roleIds, [5]);
      expect(result.moduleIds, [101]);
    });
  }
  for (final entry in delegatingRawContainers.entries) {
    test('${entry.key} rejects decoded untyped rows', () {
      final roleRow = Map<dynamic, dynamic>.from(
        jsonDecode('{"station_id":7,"sys_role_id":5,"status":1}') as Map,
      );
      final moduleRow = Map<dynamic, dynamic>.from(
        jsonDecode('{"station_id":7,"sys_module_id":101,"status":1}') as Map,
      );
      final result = make(r: entry.value(roleRow), m: entry.value(moduleRow));

      expect(result.available, isFalse);
      expect(result.roleIds, isEmpty);
      expect(result.moduleIds, isEmpty);
    });
  }
  for (final entry in wrappedRawMapContainers.entries) {
    test('${entry.key} rejects decoded untyped rows', () {
      final roleRow = Map<dynamic, dynamic>.from(
        jsonDecode('{"station_id":7,"sys_role_id":5,"status":1}') as Map,
      );
      final moduleRow = Map<dynamic, dynamic>.from(
        jsonDecode('{"station_id":7,"sys_module_id":101,"status":1}') as Map,
      );
      final result = make(r: entry.value(roleRow), m: entry.value(moduleRow));

      expect(result.available, isFalse);
      expect(result.roleIds, isEmpty);
      expect(result.moduleIds, isEmpty);
    });
  }

  test('hostile delegating list view is rejected without backing access', () {
    final hostileList = _HostileList();
    final hostileMap = _HostileMap();
    final result = make(
      r: UnmodifiableListView<dynamic>(hostileList),
      m: UnmodifiableListView<dynamic>([
        UnmodifiableMapView<dynamic, dynamic>(hostileMap),
      ]),
    );

    expect(result.available, isFalse);
    expect(hostileList.accesses, 0);
    expect(hostileMap.accesses, 0);
  });

  test('hostile delegating map view is rejected without backing access', () {
    final hostileMap = _HostileMap();
    final result = make(
      r: List<dynamic>.unmodifiable([
        UnmodifiableMapView<dynamic, dynamic>(hostileMap),
      ]),
      m: List<dynamic>.unmodifiable(const []),
    );

    expect(hostileMap.accesses, 0);
    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
  });

  test('broad Map<Object, Object> row containers are unavailable', () {
    final result = make(
      r: <Map<Object, Object>>[
        {'station_id': 7, 'sys_role_id': 5, 'status': 1},
      ],
      m: <Map<Object, Object>>[
        {'station_id': 7, 'sys_module_id': 101, 'status': 1},
      ],
    );

    expect(result.available, isFalse);
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('invalid values and malformed rows are ignored', () {
    final result = make(
      r: [
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
      ],
      m: [
        {'station_id': 7, 'sys_module_id': true, 'status': 1},
        {'station_id': 7, 'sys_module_id': 2.5, 'status': 1},
        'malformed',
      ],
    );
    expect(result.roleIds, isEmpty);
    expect(result.moduleIds, isEmpty);
  });

  test('required dataset availability and optional subpermissions', () {
    expect(
      PermissionNormalizer.normalize(
        stationId: 7,
        sysRole: null,
        sysRoleDetail: [],
      ).available,
      isFalse,
    );
    expect(
      PermissionNormalizer.normalize(
        stationId: 7,
        sysRole: [],
        sysRoleDetail: null,
      ).available,
      isFalse,
    );
    expect(
      PermissionNormalizer.normalize(
        stationId: 7,
        sysRole: {},
        sysRoleDetail: [],
      ).available,
      isFalse,
    );
    final empty = PermissionNormalizer.normalize(
      stationId: 7,
      sysRole: [],
      sysRoleDetail: [],
    );
    expect(empty.available, isTrue);
    expect(empty.roleIds, isEmpty);
    expect(make(employee: 42, s: null).subPermissions, isEmpty);
    expect(make(employee: 42, s: 'malformed').subPermissions, isEmpty);
    final sub = make(
      employee: 42,
      s: [
        {'emp_id': 42, 'sub_permission_id': 9, 'parent_id': 101, 'status': 1},
        {'emp_id': 42, 'sub_permission_id': 3, 'parent_id': 101, 'status': 1},
        {'emp_id': 42, 'sub_permission_id': 9, 'parent_id': 101, 'status': 1},
        {'emp_id': 42, 'sub_permission_id': 4, 'parent_id': 101, 'status': 3},
        {'emp_id': 4, 'sub_permission_id': 1, 'parent_id': 101, 'status': 1},
      ],
    );
    expect(sub.subPermissions, [
      SubPermissionKey(101, 3),
      SubPermissionKey(101, 9),
    ]);
  });

  test('product, region, and limit fields do not expand scope', () {
    final result = make(
      r: [
        {
          'station_id': 7,
          'sys_role_id': 5,
          'status': 1,
          'product_id': 99,
          'region_id': 3,
          'limit': 100,
        },
      ],
      m: [
        {
          'station_id': 7,
          'sys_module_id': 101,
          'status': 1,
          'product_id': 99,
          'region_id': 3,
          'limit': 100,
        },
      ],
    );
    expect(result.roleIds, [5]);
    expect(result.moduleIds, [101]);
  });

  test('engine precedence and any/all semantics', () {
    final unavailableSnapshot = PermissionNormalizer.normalize(
      stationId: 7,
      sysRole: null,
      sysRoleDetail: [],
    );
    final unavailableDecision = PermissionEngine(unavailableSnapshot)
        .decide(PermissionRequirement());
    expect(unavailableDecision.allowed, isFalse);
    expect(unavailableDecision.reason, 'permission.data_unavailable');
    expect(
      unavailableDecision.authorizationRequirement,
      AuthorizationRequirement.unknown,
    );
    expect(unavailableDecision.effectiveScope, unavailableSnapshot);
    expect(unavailableDecision.effectiveScope.available, isFalse);
    expect(unavailableDecision.effectiveScope.stationId, 7);
    expect(unavailableDecision.effectiveScope.roleIds, isEmpty);
    expect(unavailableDecision.effectiveScope.moduleIds, isEmpty);
    expect(unavailableDecision.effectiveScope.subPermissions, isEmpty);

    final availableSnapshot = make(
      employee: 42,
      s: [
        {'emp_id': 42, 'sub_permission_id': 8, 'parent_id': 101, 'status': 1},
      ],
    );
    final availableDecision = PermissionEngine(availableSnapshot)
        .decide(PermissionRequirement());
    expect(availableDecision.allowed, isTrue);
    expect(availableDecision.reason, 'permission.allowed');
    expect(
      availableDecision.authorizationRequirement,
      AuthorizationRequirement.unknown,
    );
    expect(availableDecision.effectiveScope, availableSnapshot);
    expect(availableDecision.effectiveScope.available, isTrue);
    expect(availableDecision.effectiveScope.stationId, 7);
    expect(availableDecision.effectiveScope.roleIds, [5]);
    expect(availableDecision.effectiveScope.moduleIds, [101]);
    expect(availableDecision.effectiveScope.subPermissions, [
      SubPermissionKey(101, 8),
    ]);
    expect(
      () => availableDecision.effectiveScope.roleIds.add(99),
      throwsUnsupportedError,
    );
    final engine = PermissionEngine(availableSnapshot);
    expect(
      engine
          .decide(
            PermissionRequirement(
              anyRoleIds: {99},
              allModuleIds: {999},
              allSubPermissions: {SubPermissionKey(101, 999)},
            ),
          )
          .reason,
      'permission.role_missing',
    );
    expect(
      engine
          .decide(
            PermissionRequirement(
              allModuleIds: {999},
              allSubPermissions: {SubPermissionKey(101, 999)},
            ),
          )
          .reason,
      'permission.module_missing',
    );
    expect(
      engine
          .decide(
            PermissionRequirement(
              allSubPermissions: {SubPermissionKey(101, 999)},
            ),
          )
          .reason,
      'permission.sub_permission_missing',
    );
    expect(
      engine.decide(PermissionRequirement(anyRoleIds: {5, 8})).allowed,
      isTrue,
    );
    expect(
      engine.decide(PermissionRequirement(anyRoleIds: {8})).allowed,
      isFalse,
    );
    expect(
      engine.decide(PermissionRequirement(allModuleIds: {101})).allowed,
      isTrue,
    );
    expect(
      engine.decide(PermissionRequirement(allModuleIds: {101, 999})).allowed,
      isFalse,
    );
    expect(
      engine
          .decide(
            PermissionRequirement(
              allSubPermissions: {SubPermissionKey(101, 8)},
            ),
          )
          .allowed,
      isTrue,
    );
    expect(
      engine
          .decide(
            PermissionRequirement(
              allSubPermissions: {
                SubPermissionKey(101, 8),
                SubPermissionKey(101, 999),
              },
            ),
          )
          .allowed,
      isFalse,
    );
    for (final requirement in [
      PermissionRequirement(),
      PermissionRequirement(anyRoleIds: {99}),
      PermissionRequirement(allModuleIds: {999}),
      PermissionRequirement(allSubPermissions: {SubPermissionKey(101, 999)}),
    ]) {
      expect(
        engine.decide(requirement).authorizationRequirement,
        AuthorizationRequirement.unknown,
      );
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
      ],
    );
    expect(result.subPermissions, [
      SubPermissionKey(101, 8),
      SubPermissionKey(202, 8),
    ]);
    final engine = PermissionEngine(result);
    expect(
      engine
          .decide(
            PermissionRequirement(
              allSubPermissions: {SubPermissionKey(101, 8)},
            ),
          )
          .allowed,
      isTrue,
    );
    expect(
      engine
          .decide(
            PermissionRequirement(
              allSubPermissions: {SubPermissionKey(303, 8)},
            ),
          )
          .allowed,
      isFalse,
    );
  });

  test('snapshot filters subpermissions outside its module scope', () {
    final sourceModules = <int>{101};
    final sourceSubPermissions = <SubPermissionKey>{
      const SubPermissionKey(101, 8),
      const SubPermissionKey(999, 8),
    };
    final snapshot = PermissionSnapshot(
      available: true,
      stationId: 7,
      roleIds: const {5},
      moduleIds: sourceModules,
      subPermissions: sourceSubPermissions,
    );

    sourceModules.add(999);
    sourceSubPermissions.add(const SubPermissionKey(101, 9));
    expect(snapshot.moduleIds, [101]);
    expect(snapshot.subPermissions, [const SubPermissionKey(101, 8)]);
    expect(() => snapshot.moduleIds.add(999), throwsUnsupportedError);
    expect(
      () => snapshot.subPermissions.add(const SubPermissionKey(101, 9)),
      throwsUnsupportedError,
    );

    final engine = PermissionEngine(snapshot);
    final inconsistent = engine.decide(
      PermissionRequirement(
        allSubPermissions: {const SubPermissionKey(999, 8)},
      ),
    );
    expect(inconsistent.allowed, isFalse);
    expect(inconsistent.reason, 'permission.sub_permission_missing');
    expect(
      engine
          .decide(
            PermissionRequirement(
              allSubPermissions: {const SubPermissionKey(101, 8)},
            ),
          )
          .allowed,
      isTrue,
    );
  });

  test('requirements defensively copy inputs and have value semantics', () {
    final roles = <int>{5};
    final modules = <int>{101};
    final subs = <SubPermissionKey>{SubPermissionKey(101, 8)};
    final requirement = PermissionRequirement(
      anyRoleIds: roles,
      allModuleIds: modules,
      allSubPermissions: subs,
    );
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
      allSubPermissions: {const SubPermissionKey(101, 8)},
    );
    expect(requirement, same);
    expect(requirement.hashCode, same.hashCode);
    expect(requirement.toString(), contains('5'));
  });

  test('row budget accepts exactly the boundary and rejects overflow', () {
    final rows = List<Map<String, Object?>>.generate(
      10000,
      (_) => {'station_id': 7, 'sys_role_id': 5, 'status': 1},
    );
    expect(
      PermissionNormalizer.normalize(
        stationId: 7,
        sysRole: rows,
        sysRoleDetail: [],
      ).available,
      isTrue,
    );
    rows.add({'station_id': 7, 'sys_role_id': 5, 'status': 1});
    expect(
      PermissionNormalizer.normalize(
        stationId: 7,
        sysRole: rows,
        sysRoleDetail: [],
      ).available,
      isFalse,
    );
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
    final result = make(
      r: <Map<String, Object?>>[
        {'station_id': 7, 'sys_role_id': '9007199254740991', 'status': 1},
        {'station_id': 7, 'sys_role_id': overlongNumeric, 'status': 1},
        {'station_id': 7, 'sys_role_id': overlongControl, 'status': 1},
      ],
      m: <Map<String, Object?>>[],
    );

    expect(result.available, isTrue);
    expect(result.roleIds, [9007199254740991]);
    expect(result.moduleIds, isEmpty);
  });
}
