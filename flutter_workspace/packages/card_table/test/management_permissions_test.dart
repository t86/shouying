import 'package:card_table/src/management_permissions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

List<Object?> full({Object? roles, Object? modules, Object? safety}) {
  final data = List<Object?>.filled(55, null);
  data[13] =
      roles ??
      [
        [9, 10, 1],
        [8, 99, 1],
      ];
  data[41] =
      modules ??
      [
        [9, 25, 1],
        [9, 50, 2],
      ];
  data[54] =
      safety ??
      [
        [1, 0],
      ];
  return data;
}

void main() {
  test('explicit online direct membership is independent of unknown roles', () {
    final unknown = ManagementPermissionStore(stationId: '9').snapshot;
    bool visible({bool? online, bool direct = true}) => managementGroupVisible(
      client: ClientKind.wine,
      groupName: '存酒管理',
      systems: direct ? [ClientKind.wine] : [ClientKind.orgManager],
      authorizationClients: [ClientKind.wine],
      needsAuthorization: true,
      snapshot: unknown,
      safeModeEnabled: true,
      sessionOnline: online,
    );
    expect(visible(online: true), isTrue);
    expect(visible(online: true, direct: false), isFalse);
    expect(visible(online: false), isFalse);
    expect(visible(), isFalse);
  });
  test('real raw arrays normalize without card/day datasets', () {
    final store = ManagementPermissionStore(stationId: '9');
    expect(store.snapshot.available, false);
    expect(store.safeModeEnabled, true);
    store.apply(full());
    expect(store.snapshot.available, true);
    expect(store.snapshot.roleIds, {10});
    expect(store.snapshot.moduleIds, {25});
    expect(store.safeModeKnown, true);
    expect(store.safeModeEnabled, false);
  });

  test('incremental composite keys revoke only matching station and id', () {
    final store = ManagementPermissionStore(stationId: '9')..apply(full());
    store.apply({
      '13': [
        [8, 10, 0],
        [9, 10, 0],
        [9, 11, 1],
      ],
      '41': [
        [9, 50, 1],
        [9, 25, 0],
      ],
    });
    expect(store.snapshot.roleIds, {11});
    expect(store.snapshot.moduleIds, {50});
    store.apply({
      '41': [
        [8, 50, 0],
      ],
    });
    expect(store.snapshot.moduleIds, {50});
  });

  test('map is never an initial complete snapshot', () {
    final store = ManagementPermissionStore(stationId: '9');
    store.apply({
      13: [
        [9, 10, 1],
      ],
      41: [
        [9, 25, 1],
      ],
      54: [
        [1, 0],
      ],
    });
    expect(store.snapshot.available, false);
  });

  test('invalid permission data requires complete snapshot to reauthorize', () {
    final store = ManagementPermissionStore(stationId: '9')..apply(full());
    store.apply({
      '13': [
        [9, 10],
      ],
    });
    expect(store.snapshot.available, false);
    expect(store.safeModeEnabled, true);
    store.apply({
      '13': [
        [9, 10, 1],
      ],
      '41': [
        [9, 25, 1],
      ],
      '54': [
        [1, 0],
      ],
    });
    expect(store.snapshot.available, false);
    store.apply(full());
    expect(store.snapshot.available, true);
  });

  test('explicit invalidation survives incremental data', () {
    final store = ManagementPermissionStore(stationId: '9')..apply(full());
    store.invalidate();
    store.apply({
      '41': [
        [9, 50, 1],
      ],
    });
    expect(store.snapshot.available, false);
    expect(store.snapshot.roleIds, isEmpty);
  });

  test('full snapshot replaces cached grants rather than merging', () {
    final store = ManagementPermissionStore(stationId: '9')..apply(full());
    store.apply(full(roles: [], modules: [], safety: []));
    expect(store.snapshot.available, true);
    expect(store.snapshot.roleIds, isEmpty);
    expect(store.snapshot.moduleIds, isEmpty);
    expect(store.safeModeEnabled, false);
  });

  test('unrelated datasets and status rows cannot grant permissions', () {
    final store = ManagementPermissionStore(stationId: '9')..apply(full());
    store.apply({'14': 'not needed', '18': null});
    expect(store.snapshot.roleIds, {10});
    store.apply({
      '41': [
        ['9', '25', '2'],
        ['9', '50', '0'],
      ],
    });
    expect(store.snapshot.moduleIds, isEmpty);
  });

  test('unknown and malformed values fail closed without throwing', () {
    for (final invalid in [
      null,
      42,
      'bad',
      {'13': null},
      {
        '41': [
          [9, true, 1],
        ],
      },
      {
        '41': [
          [9, '025', 1],
        ],
      },
      {
        '54': [
          [1, 'bad'],
        ],
      },
      {
        '013': [
          [9, 10, 1],
        ],
      },
    ]) {
      final store = ManagementPermissionStore(stationId: '9')..apply(full());
      store.apply(invalid);
      expect(store.snapshot.available, false, reason: '$invalid');
      expect(store.safeModeEnabled, true);
    }
  });

  test('unknown safety stays closed until explicit flag arrives', () {
    final data = full()..[54] = null;
    final store = ManagementPermissionStore(stationId: '9')..apply(data);
    expect(store.safeModeKnown, false);
    expect(store.safeModeEnabled, true);
    store.apply({
      '54': [
        [2, 0],
      ],
    });
    expect(store.safeModeEnabled, true);
    store.apply({
      '54': [
        [1, 0],
      ],
    });
    expect(store.safeModeKnown, true);
    expect(store.safeModeEnabled, false);
    store.apply({
      '54': [
        [1, 1],
      ],
    });
    expect(store.safeModeEnabled, true);
  });

  test('bad station and incomplete full snapshot are unavailable', () {
    final store = ManagementPermissionStore(stationId: '09')..apply(full());
    expect(store.snapshot.available, false);
    final valid = ManagementPermissionStore(stationId: '9')..apply(full());
    valid.apply(full()..[41] = null);
    expect(valid.snapshot.available, false);
  });

  test(
    'menu mirrors direct clients, ERP module25, Wine extension and safety',
    () {
      final store = ManagementPermissionStore(stationId: '9')..apply(full());
      bool visible(
        ClientKind client,
        String name,
        List<ClientKind> systems, {
        List<ClientKind> auth = const [],
        bool need = false,
      }) => managementGroupVisible(
        client: client,
        groupName: name,
        systems: systems,
        authorizationClients: auth,
        needsAuthorization: need,
        snapshot: store.snapshot,
        safeModeEnabled: store.safeModeEnabled,
      );
      expect(visible(ClientKind.erp, '物料管理', [ClientKind.erpAdmin]), false);
      expect(visible(ClientKind.erpAdmin, '物料管理', [ClientKind.erpAdmin]), true);
      expect(
        visible(
          ClientKind.erp,
          '空瓶管理',
          [ClientKind.erpAdmin],
          auth: [ClientKind.erp],
          need: true,
        ),
        true,
      );
      expect(
        visible(
          ClientKind.wine,
          '扩展',
          [ClientKind.orgManager],
          auth: [ClientKind.wine],
          need: true,
        ),
        true,
      );
      store.apply({
        '41': [
          [9, 25, 0],
          [9, 50, 1],
        ],
      });
      expect(
        visible(
          ClientKind.erp,
          '空瓶管理',
          [ClientKind.erpAdmin],
          auth: [ClientKind.erp],
          need: true,
        ),
        false,
      );
      expect(
        visible(
          ClientKind.wine,
          '扩展',
          [ClientKind.orgManager],
          auth: [ClientKind.wine],
          need: true,
        ),
        false,
      );
      expect(
        visible(
          ClientKind.wine,
          '存酒管理',
          [ClientKind.wine],
          auth: [ClientKind.wine],
          need: true,
        ),
        true,
      );
      store.apply({
        '54': [
          [1, 1],
        ],
      });
      expect(
        visible(ClientKind.orgManager, '人员管理', [ClientKind.orgManager]),
        false,
      );
      expect(
        visible(ClientKind.orgManager, '商品管理', [ClientKind.orgManager]),
        true,
      );
      store.invalidate();
      expect(
        visible(ClientKind.orgManager, '商品管理', [ClientKind.orgManager]),
        false,
      );
    },
  );
}
