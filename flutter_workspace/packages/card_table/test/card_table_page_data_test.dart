import 'package:card_table/card_table.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_sync/realtime_sync.dart';

void main() {
  test('dataset nine and thirty-two expose set details and reasons', () {
    final store = LegacyCardTableStore();
    final data = _fullData();
    data[4] = <Object?>[
      <Object?>[301, '双人套餐', 1, 1, 'TCA', '', 1, 1, '88', 2],
      <Object?>[11, '啤酒', 1, 1, 'PJ', '', 1, 1, '18', 1],
      <Object?>[12, '花生', 1, 1, 'HS', '', 1, 1, '8', 1],
    ];
    data[9] = <Object?>[
      <Object?>[301, 1, 1, 1, 11, 1, 1, 1],
      <Object?>[301, 1, 2, 1, 12, 1, 1, 1],
      <Object?>[301, 3, 2, 2, 99, 1, 1, 1],
    ];
    data[32] = <Object?>[
      <Object?>[1, '招待', 1, 1],
      <Object?>[2, '客人不满意', 1, 2],
      <Object?>[3, '删除理由', 3, 2],
      <Object?>[4, '无效优惠', 2, 1],
    ];
    _apply(store, data);
    expect(
      store.setDetails.map((item) => item.detailProductId).toList(),
      <String>['11', '12'],
    );
    expect(store.setDetails.first.name, '啤酒');
    expect(store.setDetails.first.fixed, isTrue);
    expect(store.setDetails.last.groupId, '2');
    expect(store.yhReasons, <String>['招待']);
    expect(store.refundReasons, <String>['客人不满意']);
  });

  test('dataset five exposes recharge employees and drops deleted rows', () {
    final store = LegacyCardTableStore(stationId: '7');
    final data = _fullData();
    data[5] = <Object?>[
      <Object?>[9, '李四', 1, 1, 1, 1, '', 'LS', 'E9', 0, 0, '李四'],
      <Object?>[1, '王五', 1, 1, 1, 1, '', 'WW', 'E1', 0, 0, '王五'],
      <Object?>[8, '删除', 3, 1, 1, 1, '', 'SC', 'E8', 0, 0, '删除'],
    ];
    _apply(store, data);
    expect(store.employees.map((item) => item.id), <String>['9', '1']);
    expect(store.employees.first.name, '李四');
    expect(store.employees.first.code, 'E9');
  });

  test('page permissions use current station active roles and modules', () {
    final store = LegacyCardTableStore(stationId: '7');
    final data = _fullData();
    data[13] = <Object?>[
      <Object?>['7', '2', '1'],
      <Object?>[7, 3, 1],
      <Object?>[7, 4, 2],
      <Object?>[8, 11, 1],
    ];
    data[41] = <Object?>[
      for (final id in <int>[1, 5, 91, 92, 93]) <Object?>[7, id, 1],
      <Object?>[7, 5, 1],
      <Object?>[7, 12, 2],
      <Object?>[8, 99, 1],
    ];
    final snapshot = _apply(store, data);
    expect(snapshot.pagePermissions?.available, isTrue);
    expect(snapshot.pagePermissions?.roleIds, <int>{2, 3});
    expect(snapshot.pagePermissions?.moduleIds, <int>{1, 5, 91, 92, 93});
    expect(snapshot.safeModeEnabled, isFalse);
  });

  test('invalid station and unknown datasets never grant modules', () {
    for (final station in <String?>[null, '', '0', '07', 'invalid']) {
      final store = LegacyCardTableStore(stationId: station);
      final result = store.applyEnvelope(_event(_fullData()));
      expect(result.valueOrNull?.pagePermissions?.available ?? false, isFalse);
    }
    final store = LegacyCardTableStore(stationId: '7');
    final data = _fullData().take(19).toList();
    final snapshot = _apply(store, data);
    expect(snapshot.pagePermissions?.available, isFalse);
    expect(snapshot.pagePermissions?.moduleIds, isEmpty);
    expect(snapshot.safeModeEnabled, isTrue);
  });

  test('known empty datasets are available with no grants', () {
    final data = _fullData();
    data[13] = <Object?>[];
    data[41] = <Object?>[];
    final snapshot = _apply(LegacyCardTableStore(stationId: '7'), data);
    expect(snapshot.pagePermissions?.available, isTrue);
    expect(snapshot.pagePermissions?.moduleIds, isEmpty);
    expect(snapshot.safeModeEnabled, isFalse);
  });

  test('module and role status updates revoke current station entries', () {
    final store = LegacyCardTableStore(stationId: '7');
    _apply(store, _fullData());
    final snapshot = _apply(store, <String, Object?>{
      '13': <Object?>[
        <Object?>[7, 2, 3],
      ],
      '41': <Object?>[
        <Object?>[7, 5, 2],
      ],
    });
    expect(snapshot.pagePermissions?.roleIds, isEmpty);
    expect(snapshot.pagePermissions?.moduleIds, isEmpty);
    final replaced = _fullData();
    replaced[41] = <Object?>[];
    expect(_apply(store, replaced).pagePermissions?.moduleIds, isEmpty);
  });

  test('safe mode follows id one and updates independently', () {
    final store = LegacyCardTableStore(stationId: '7');
    final data = _fullData();
    data[54] = <Object?>[
      <Object?>[2, 1],
      <Object?>[1, 2],
    ];
    expect(_apply(store, data).safeModeEnabled, isFalse);
    expect(
      _apply(store, <String, Object?>{
        '54': <Object?>[
          <Object?>['1', '1'],
        ],
      }).safeModeEnabled,
      isTrue,
    );
    expect(
      _apply(store, <String, Object?>{'41': <Object?>[]}).safeModeEnabled,
      isTrue,
    );
    expect(
      _apply(store, <String, Object?>{
        '54': <Object?>[
          <Object?>[1, 2],
        ],
      }).safeModeEnabled,
      isFalse,
    );
  });

  test(
    'late feed listener receives merged metadata and ownership fields',
    () async {
      final feed = CardTableEventFeed();
      addTearDown(feed.close);
      feed.add(_event(_fullData()));
      feed.add(
        _event(<String, Object?>{
          '41': <Object?>[
            <Object?>[7, 5, 3],
            <Object?>[7, 91, 1],
          ],
          '54': <Object?>[
            <Object?>[1, 1],
          ],
        }),
      );
      final replay = await feed.events.first;
      final store = LegacyCardTableStore(stationId: '7');
      final snapshot = _apply(store, replay.data);
      expect(snapshot.pagePermissions?.roleIds, <int>{2});
      expect(snapshot.pagePermissions?.moduleIds, <int>{91});
      expect(snapshot.safeModeEnabled, isTrue);
      expect(snapshot.tables.first.belongsToEmployee('12'), isTrue);
    },
  );

  test('replay preserves unknown versus known empty metadata', () {
    final source = LegacyCardTableStore();
    _apply(source, _fullData().take(19).toList());
    final late = LegacyCardTableStore(stationId: '7');
    final unknown = _apply(late, source.replayEnvelope!.data);
    expect(unknown.pagePermissions?.available, isFalse);
    expect(unknown.safeModeEnabled, isTrue);
    _apply(source, _fullData());
    final known = _apply(late, source.replayEnvelope!.data);
    expect(known.pagePermissions?.available, isTrue);
    expect(known.safeModeEnabled, isFalse);
  });

  for (final dataset in <int>[13, 41]) {
    test('malformed dataset $dataset denies until a valid full snapshot', () {
      final store = LegacyCardTableStore(stationId: '7');
      _apply(store, _fullData());
      final rejected = store.applyEnvelope(
        _event(<String, Object?>{
          '$dataset': <Object?>[
            <Object?>[7],
          ],
        }),
      );
      expect(rejected.failureOrNull?.code, 'protocol.card_table_shape');
      expect(store.currentSnapshot!.pagePermissions?.available, isFalse);
      expect(store.currentSnapshot!.pagePermissions?.moduleIds, isEmpty);
      final heartbeat = SyncEnvelope.parse(<String, Object?>{
        'p': 2,
        't': '20260831010101',
        'd': <Object?>[],
      }).valueOrNull!;
      expect(
        store.applyEnvelope(heartbeat).valueOrNull!.pagePermissions?.available,
        isFalse,
      );
      expect(
        _apply(store, <String, Object?>{
          '39': <Object?>[],
        }).pagePermissions?.available,
        isFalse,
      );
      expect(
        _apply(store, <String, Object?>{
          '41': <Object?>[
            <Object?>[7, 91, 1],
          ],
        }).pagePermissions?.available,
        isFalse,
      );
      final late = LegacyCardTableStore(stationId: '7');
      expect(
        _apply(late, store.replayEnvelope!.data).pagePermissions?.available,
        isFalse,
      );
      expect(_apply(store, _fullData()).pagePermissions?.moduleIds, <int>{5});
    });
  }

  test(
    'invalid permission value poisons grants rather than skipping the row',
    () {
      final store = LegacyCardTableStore(stationId: '7');
      _apply(store, _fullData());
      final rejected = store.applyEnvelope(
        _event(<String, Object?>{
          '41': <Object?>[
            <Object?>[7, 5, 'bad-status'],
          ],
        }),
      );
      expect(rejected.failureOrNull, isNotNull);
      expect(store.currentSnapshot!.pagePermissions?.available, isFalse);
    },
  );

  test('invalid safe mode cannot clear on heartbeat or empty delta', () {
    final store = LegacyCardTableStore(stationId: '7');
    _apply(store, _fullData());
    final rejected = store.applyEnvelope(
      _event(<String, Object?>{
        '54': <Object?>[
          <Object?>[1, 'invalid'],
        ],
      }),
    );
    expect(rejected.failureOrNull, isNotNull);
    expect(store.currentSnapshot!.safeModeEnabled, isTrue);
    expect(
      _apply(store, <String, Object?>{'54': <Object?>[]}).safeModeEnabled,
      isTrue,
    );
    expect(
      _apply(store, <String, Object?>{'39': <Object?>[]}).safeModeEnabled,
      isTrue,
    );
    final late = LegacyCardTableStore(stationId: '7');
    expect(_apply(late, store.replayEnvelope!.data).safeModeEnabled, isTrue);
    expect(
      _apply(store, <String, Object?>{
        '54': <Object?>[
          <Object?>[1, 2],
        ],
      }).safeModeEnabled,
      isFalse,
    );
  });

  test('bad card update without metadata retains the exact prior snapshot', () {
    final store = LegacyCardTableStore(stationId: '7');
    final before = _apply(store, _fullData());
    final result = store.applyEnvelope(
      _event(<String, Object?>{
        '1': <Object?>[
          <Object?>['broken'],
        ],
      }),
    );
    expect(result.failureOrNull, isNotNull);
    expect(identical(before, store.currentSnapshot), isTrue);
  });

  test('malformed dataset keys cannot bypass authority invalidation', () {
    final store = LegacyCardTableStore(stationId: '7');
    _apply(store, _fullData());
    final result = store.applyEnvelope(
      _event(<String, Object?>{
        'not-a-dataset': <Object?>[],
        '41': <Object?>[
          <Object?>[7, 5, 3],
        ],
        '54': <Object?>[
          <Object?>[1, 1],
        ],
      }),
    );
    expect(result.failureOrNull, isNotNull);
    expect(store.currentSnapshot!.pagePermissions?.available, isFalse);
    expect(store.currentSnapshot!.safeModeEnabled, isTrue);
  });

  test(
    'rejected role metadata never broadens supervisor visibility on replay',
    () {
      final data = _fullData();
      data[0] = <Object?>[
        <Object?>[1, '大厅', 1, 1],
        <Object?>[2, '包厢', 1, 2],
      ];
      data[1] = <Object?>[
        <Object?>[100, 'A01', 1, 1, 3, 1, 4, 1],
        <Object?>[200, 'B01', 1, 2, 3, 1, 4, 1],
      ];
      data[13] = <Object?>[
        <Object?>[7, 11, 1],
      ];
      data[56] = <Object?>[
        <Object?>[7, 1, 1],
      ];
      final source = LegacyCardTableStore(stationId: '7');
      expect(_apply(source, data).tables.map((table) => table.id), <String>[
        '100',
      ]);
      source.applyEnvelope(
        _event(<String, Object?>{
          '13': <Object?>[
            <Object?>[7],
          ],
        }),
      );
      final late = LegacyCardTableStore(stationId: '7');
      final snapshot = _apply(late, source.replayEnvelope!.data);
      expect(snapshot.pagePermissions?.available, isFalse);
      expect(snapshot.tables, isEmpty);
    },
  );

  for (final dataset in <int>[13, 41]) {
    test(
      'invalid dataset $dataset keeps scope closed across role revocation and replay',
      () {
        final store = LegacyCardTableStore(stationId: '7');
        expect(
          _apply(store, _supervisorData()).tables.map((table) => table.id),
          <String>['100'],
        );
        final rejected = store.applyEnvelope(
          _event(<String, Object?>{
            '$dataset': <Object?>[
              <Object?>[7],
            ],
          }),
        );
        expect(rejected.failureOrNull, isNotNull);
        expect(store.currentSnapshot!.tables, isEmpty);
        final revoked = _apply(store, <String, Object?>{
          '13': <Object?>[
            <Object?>[7, 11, 3],
          ],
        });
        expect(revoked.pagePermissions?.available, isFalse);
        expect(revoked.tables, isEmpty);
        expect(revoked.tablesForDate('tomorrow'), isEmpty);
        expect(revoked.statusCounts, isEmpty);
        final heartbeat = SyncEnvelope.parse(<String, Object?>{
          'p': 2,
          't': '20260831010101',
          'd': <Object?>[],
        }).valueOrNull!;
        expect(store.applyEnvelope(heartbeat).valueOrNull!.tables, isEmpty);
        expect(
          _apply(store, <String, Object?>{'39': <Object?>[]}).tables,
          isEmpty,
        );
        final late = LegacyCardTableStore(stationId: '7');
        final replayed = _apply(late, store.replayEnvelope!.data);
        expect(replayed.pagePermissions?.available, isFalse);
        expect(replayed.tables, isEmpty);
        expect(
          _apply(late, <String, Object?>{
            '13': <Object?>[
              <Object?>[7, 2, 1],
            ],
          }).tables,
          isEmpty,
        );
        final restored = _supervisorData();
        restored[13] = <Object?>[];
        final recovered = _apply(store, restored);
        expect(recovered.pagePermissions?.available, isTrue);
        expect(recovered.tables.map((table) => table.id), <String>[
          '100',
          '200',
        ]);
      },
    );
  }

  test('a rejected full snapshot conservatively invalidates page metadata', () {
    final store = LegacyCardTableStore(stationId: '7');
    _apply(store, _fullData());
    final invalid = _fullData();
    invalid[1] = <Object?>[
      <Object?>['bad'],
    ];
    expect(store.applyEnvelope(_event(invalid)).failureOrNull, isNotNull);
    expect(store.currentSnapshot!.tables, isEmpty);
    expect(store.currentSnapshot!.pagePermissions?.available, isFalse);
    expect(store.currentSnapshot!.safeModeEnabled, isTrue);
  });

  test(
    'an incomplete permission full snapshot cannot clear poisoned scope',
    () {
      final store = LegacyCardTableStore(stationId: '7');
      _apply(store, _supervisorData());
      store.applyEnvelope(
        _event(<String, Object?>{
          '13': <Object?>[
            <Object?>[7],
          ],
        }),
      );
      final incomplete = _supervisorData();
      incomplete[13] = <Object?>[];
      incomplete[41] = null;
      final snapshot = _apply(store, incomplete);
      expect(snapshot.pagePermissions?.available, isFalse);
      expect(snapshot.tables, isEmpty);
      final late = LegacyCardTableStore(stationId: '7');
      expect(_apply(late, store.replayEnvelope!.data).tables, isEmpty);
      incomplete[41] = <Object?>[];
      expect(_apply(store, incomplete).tables, hasLength(2));
    },
  );

  for (final full in <bool>[false, true]) {
    test(
      'unknown role ${full ? 'full snapshot' : 'delta'} cannot widen live or replay scope',
      () {
        final data = _supervisorData();
        final source = LegacyCardTableStore(stationId: '7');
        expect(_apply(source, data).tables.map((table) => table.id), <String>[
          '100',
        ]);
        final Object? unknown;
        if (full) {
          data[13] = null;
          unknown = data;
        } else {
          unknown = <String, Object?>{'13': null};
        }
        final current = _apply(source, unknown);
        expect(current.pagePermissions?.available, isFalse);
        expect(current.tables.map((table) => table.id), isNot(contains('200')));
        final replay = LegacyCardTableStore(stationId: '7');
        final late = _apply(replay, source.replayEnvelope!.data);
        expect(late.pagePermissions?.available, isFalse);
        expect(late.tables.map((table) => table.id), isNot(contains('200')));
        expect(
          late.tablesForDate('tomorrow').map((table) => table.id),
          isNot(contains('200')),
        );
        final restore = _supervisorData();
        restore[13] = <Object?>[];
        final knownEmpty = _apply(source, restore);
        expect(knownEmpty.pagePermissions?.available, isTrue);
        expect(knownEmpty.tables.map((table) => table.id), <String>[
          '100',
          '200',
        ]);
      },
    );
  }

  test('initially missing roles deny scoped tables until a complete known role list', () {
    final data = _supervisorData();
    final withoutRoles = <String, Object?>{
      for (var index = 0; index < data.length; index += 1)
        if (index != 13) '$index': data[index],
    };
    final store = LegacyCardTableStore(stationId: '7');
    final unknown = _apply(store, withoutRoles);
    expect(unknown.pagePermissions?.available, isFalse);
    expect(unknown.tables, isEmpty);
    expect(unknown.tablesForDate('tomorrow'), isEmpty);
    expect(unknown.statusCounts, isEmpty);
    final unrelated = _apply(store, <String, Object?>{
      '13': <Object?>[
        <Object?>[7, 2, 1],
      ],
    });
    expect(unrelated.tables, isEmpty);
    data[13] = <Object?>[];
    expect(_apply(store, data).tables, hasLength(2));
  });

  test(
    'mine uses exact historical waiter or sales id and immutable copied ids',
    () {
      final snapshot = _apply(LegacyCardTableStore(), _fullData());
      final table = snapshot.tables.first;
      expect(table.salesEmployeeId, '23');
      expect(table.waiterEmployeeIds, <String>{'12', '112'});
      expect(table.turnoverCount, 3);
      expect(table.belongsToEmployee('12'), isTrue);
      expect(table.belongsToEmployee('23'), isTrue);
      for (final id in <String?>[null, '', '2', '1', '34', '45', ' 12 ']) {
        expect(table.belongsToEmployee(id), isFalse, reason: 'id $id');
      }
      expect(() => table.waiterEmployeeIds.add('99'), throwsUnsupportedError);
      final ids = <String>{'7'};
      final copied = _table(waiters: ids);
      ids.add('8');
      expect(copied.waiterEmployeeIds, <String>{'7'});
    },
  );

  test('business row maps gift amount min-consume and directory names', () {
    final data = _fullData();
    final row = _businessRow(100);
    row[10] = 200;
    row[11] = 10;
    row[12] = 5;
    row[30] = 20;
    row[31] = 180;
    row[24] = '转台测试';
    row[25] = '抖';
    data[14] = <Object?>[row];
    data[5] = <Object?>[
      <Object?>[23, '大师兄', 1, 8, 1, 1, '', 'DSX', 'E23', 0, 0, '大师兄'],
    ];
    data[6] = <Object?>[
      <Object?>[8, '总经办', 1, 0],
      <Object?>[9, '停用部门', 2, 0],
    ];
    final snapshot = _apply(LegacyCardTableStore(), data);
    final table = snapshot.tables.first;
    expect(table.giftAmount, 15);
    expect(table.assignedMinConsumeAmount, 200);
    expect(table.mainOrderAmount, 180);
    expect(table.paidMainFreeAmount, 20);
    expect(table.minConsumeProgress, '80%');
    expect(table.remark, '转台测试');
    expect(table.mark, '抖');
    expect(snapshot.employees.single.name, '大师兄');
    expect(snapshot.employees.single.deptId, '8');
    expect(snapshot.departments.map((item) => item.name), <String>['总经办']);
  });

  test('missing ownership fields do not invent ownership', () {
    final data = _fullData();
    final row = _businessRow(100);
    row[13] = null;
    row[14] = null;
    row[20] = null;
    data[14] = <Object?>[row];
    final table = _apply(LegacyCardTableStore(), data).tables.first;
    expect(table.salesEmployeeId, isEmpty);
    expect(table.waiterEmployeeIds, isEmpty);
    expect(table.turnoverCount, 0);
    expect(table.belongsToEmployee('23'), isFalse);
  });

  test('personal counts use supplied tables and seat cumulative 30 and 31', () {
    final store = LegacyCardTableStore();
    final data = _fullData();
    data[39] = <Object?>[
      <Object?>[10, 0, 900],
      <Object?>[20, 0, 901],
      <Object?>[30, 100, 4],
      <Object?>[31, 100, 7],
      <Object?>[30, 101, 8],
      <Object?>[31, 101, 9],
      <Object?>[30, 999, 700],
      <Object?>[31, 999, 701],
    ];
    final snapshot = _apply(store, data);
    final supplied = <CardTable>[
      _table(id: '100', status: 5),
      _table(id: '101', status: 6),
      _table(id: '102', status: 1),
      _table(id: '103', status: 8),
      _table(id: '104', status: 7),
      _table(id: '105', status: 4),
      _table(id: '106', status: 2),
    ];
    final counts = snapshot.personalStatusCounts(supplied);
    expect(counts, <int, int>{1: 1, 8: 1, 5: 1, 6: 1, 7: 1, 10: 12, 20: 16});
    expect(snapshot.personalStatusCounts(const <CardTable>[]), <int, int>{
      1: 0,
      8: 0,
      5: 0,
      6: 0,
      7: 0,
      10: 0,
      20: 0,
    });
  });

  test('booking write fields keep book id pin platform and must-order', () {
    final data = _fullData();
    data[0] = <Object?>[
      <Object?>[1, '大厅', 1, 1, 88, 0, 0],
    ];
    final row = _businessRow(100);
    row[1] = 77;
    row[19] = 8;
    row[22] = 1;
    row[37] = 0;
    data[14] = <Object?>[row];
    data[29] = <Object?>[
      <Object?>[100, 3, 1],
    ];
    final table = _apply(LegacyCardTableStore(), data).tables.single;
    expect(table.bookId, '77');
    expect(table.pinned, isTrue);
    expect(table.platformId, 1);
    expect(table.mustOrderDisabled, isFalse);
  });

  test('must order stays disabled when the region has no must-order products', () {
    final data = _fullData();
    final row = _businessRow(100);
    row[19] = 4;
    row[37] = 0;
    data[14] = <Object?>[row];
    expect(
      _apply(LegacyCardTableStore(), data).tables.single.mustOrderDisabled,
      isTrue,
    );
  });
}

SyncEnvelope _event(Object? data) => SyncEnvelope.fromValidatedReconciliation(
  cursor: '20260831010101',
  data: data,
);

CardTableSnapshot _apply(LegacyCardTableStore store, Object? data) {
  final result = store.applyEnvelope(_event(data));
  expect(result.failureOrNull, isNull);
  return result.valueOrNull!;
}

List<Object?> _fullData() {
  final data = List<Object?>.filled(57, const <Object?>[]);
  data[0] = <Object?>[
    <Object?>[1, '大厅', 1, 1],
  ];
  data[1] = <Object?>[
    <Object?>[100, 'A01', 1, 1, 3, 1, 4, 1],
  ];
  data[13] = <Object?>[
    <Object?>[7, 2, 1],
  ];
  data[14] = <Object?>[_businessRow(100)];
  data[18] = <Object?>[
    <Object?>[9, '', '门店'],
  ];
  data[41] = <Object?>[
    <Object?>[7, 5, 1],
  ];
  return data;
}

List<Object?> _businessRow(int seatId) {
  final row = List<Object?>.filled(38, null);
  row[0] = seatId;
  row[2] = '20260831120000';
  row[5] = '20260831123000';
  row[6] = 100;
  row[8] = 20;
  row[13] = 3;
  row[14] = 23;
  row[15] = 34;
  row[16] = '';
  row[18] = 2;
  row[19] = 5;
  row[20] = ';12;112;12;';
  row[24] = '';
  row[25] = '';
  row[34] = 45;
  return row;
}

List<Object?> _supervisorData() {
  final data = _fullData();
  data[0] = <Object?>[
    <Object?>[1, '大厅', 1, 1],
    <Object?>[2, '包厢', 1, 2],
  ];
  data[1] = <Object?>[
    <Object?>[100, 'A01', 1, 1, 3, 1, 4, 1],
    <Object?>[200, 'B01', 1, 2, 3, 1, 4, 1],
  ];
  data[13] = <Object?>[
    <Object?>[7, 11, 1],
  ];
  data[24] = <Object?>[
    <Object?>['今天', 'today'],
    <Object?>['明天', 'tomorrow'],
  ];
  data[39] = <Object?>[
    <Object?>[10, 0, 4],
  ];
  data[56] = <Object?>[
    <Object?>[7, 1, 1],
  ];
  return data;
}

CardTable _table({
  String id = '100',
  int status = 1,
  Set<String> waiters = const {},
}) => CardTable(
  id: id,
  name: '台',
  regionId: '1',
  seatType: 3,
  businessType: 1,
  capacity: 2,
  displayOrder: 1,
  businessStatus: status,
  orderAmount: 0,
  paidAmount: 0,
  customerName: '',
  customerCount: 0,
  reservationTime: '',
  openTime: '',
  remark: '',
  mark: '',
  waiterEmployeeIds: waiters,
);
