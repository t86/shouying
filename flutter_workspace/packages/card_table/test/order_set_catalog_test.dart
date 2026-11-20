import 'package:card_table/src/order_set_catalog.dart';
import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'card_amount_metadata_test.dart' as fixture;

List<Object?> data() {
  final d = fixture.full(fixture.business());
  d[4] = [
    [900, '套餐', 1, 1, '', '', 1, 10, 100, 2],
    [11, '固定商品', 1, 1, '', '', 1, 10, 10, 1],
    [12, '模板商品甲', 2, 1, '', '', 1, 10, 10, 1],
    [13, '模板商品乙', 1, 1, '', '', 1, 11, 10, 1],
    [501, '与模板同ID的普通商品', 1, 1, '', '', 1, 11, 10, 1],
  ];
  d[9] = [
    [900, 1, 1, 1, 11, 2, 0, 1],
    [900, 1, 2, 2, 501, 0, 3, 2],
  ];
  d[52] = [
    [501, 1, 12, 2, 99, 1, '模板'],
    [501, 2, 13, 1, 99, 1, '模板'],
  ];
  d[19] = [
    [1, '口味', 1, 2, 1],
    [2, '加料', 1, 1, 2],
  ];
  d[20] = [
    [101, '少冰', 1, 1, 2],
    [102, '正常', 1, 1, 1],
    [103, '柠檬', 1, 2, 1],
    [104, '停用', 2, 1, 0],
  ];
  d[21] = [
    [10, 1, 1],
    [10, 2, 1],
  ];
  return d;
}

void main() {
  test('sale limits distinguish unknown from unlimited without changing configuration readiness', () {
    final missing = data()..[8] = null;
    final c = OrderSetCatalog.unknown.apply(missing);
    expect(c.known, true);
    expect(c.configurationFor('900').known, true);
    expect(c.saleLimits, null);
    expect(c.apply({'8': []}).saleLimits, null);
    final empty = OrderSetCatalog.unknown.apply(data());
    expect(empty.saleLimits, isEmpty);
    expect(empty.known, true);
  });
  test('active zero stock, replacements, disabled rows and deletion follow dataset eight', () {
    final raw = data()
      ..[8] = [
        [11, 0, 1],
        [12, '4', 1],
        [13, 2, 2],
      ];
    final c = OrderSetCatalog.unknown.apply(raw);
    expect(c.saleLimits, {'11': 0, '12': 4});
    expect(() => c.saleLimits!['11'] = 3, throwsUnsupportedError);
    final next = c.apply({
      '8': [
        [11, 2, 1],
        [12, null, 3],
        [13, 0, 1],
      ],
    });
    expect(next.saleLimits, {'11': 2, '13': 0});
    expect(
      next.apply({
        '8': [
          [11, null, 2],
        ],
      }).saleLimits,
      {'13': 0},
    );
    expect(c.saleLimits, {'11': 0, '12': 4});
  });
  test(
    'invalid or ambiguous stock poisons only stock until a new full baseline',
    () {
      for (final patch in [
        {
          '8': [
            [11, -1, 1],
          ],
        },
        {
          '8': [
            [11, 0.5, 1],
          ],
        },
        {'8': null},
        {'08': []},
        {8: [], '8': []},
      ]) {
        final bad = OrderSetCatalog.unknown.apply(data()).apply(patch);
        expect(bad.known, true);
        expect(bad.saleLimits, null);
        expect(
          bad.apply({
            '8': [
              [11, 2, 1],
            ],
          }).saleLimits,
          null,
        );
        expect(bad.apply(data()).saleLimits, isEmpty);
      }
    },
  );
  test('card replay preserves known and unknown stock independently', () {
    for (final stock in [
      null,
      [],
      [
        [11, 0, 1],
        [12, 3, 1],
      ],
    ]) {
      final raw = data()..[8] = stock;
      final store = LegacyCardTableStore();
      expect(store.applyEnvelope(fixture.event(raw)).failureOrNull, null);
      final replay = LegacyCardTableStore();
      expect(replay.applyEnvelope(store.replayEnvelope!).failureOrNull, null);
      expect(replay.orderSetCatalog.known, true);
      expect(
        replay.orderSetCatalog.saleLimits,
        store.orderSetCatalog.saleLimits,
      );
    }
  });
  test('unknown package datasets remain unknown on replay without poisoning valid product types', () {
    for (final invalid in [
      {
        '52': [
          [501],
        ],
      },
      {'9': null},
    ]) {
      final store = LegacyCardTableStore()
        ..applyEnvelope(fixture.event(data()));
      expect(store.applyEnvelope(fixture.event(invalid)).failureOrNull, null);
      expect(store.orderSetCatalog.known, false);
      final replay = LegacyCardTableStore();
      expect(replay.applyEnvelope(store.replayEnvelope!).failureOrNull, null);
      expect(replay.productTypeFor('11'), 1);
      expect(replay.orderSetCatalog.configurationFor('900').known, false);
    }
  });
  test(
    'ambiguous package dataset aliases cannot retain stale trusted choices',
    () {
      expect(
        OrderSetCatalog.unknown.apply(data()).apply({'09': []}).known,
        false,
      );
    },
  );
  test('expands type2 through52 actual IDs and quantities, preserving group quota and provenance', () {
    final c = OrderSetCatalog.unknown.apply(data());
    final config = c.configurationFor('900');
    expect(c.known, true);
    expect(config.known, true);
    expect(config.details.map((d) => d.detailProductId), ['11', '12', '13']);
    expect(config.details.first.fixed, true);
    expect(config.details.first.detailCount, 2);
    expect(config.details[1].typeId, '2');
    expect(config.details[1].templateResolved, true);
    expect(config.details[1].groupSelectCount, 3);
    expect(config.details[1].detailCount, 2);
    expect(config.details[1].seqId, 2);
    expect(
      config.details.map((d) => d.detailProductId),
      isNot(contains('501')),
    );
  });
  test(
    'requires complete snapshots and distinguishes known empty configuration',
    () {
      expect(OrderSetCatalog.unknown.configurationFor('900').known, false);
      expect(
        OrderSetCatalog.unknown.apply({
          '4': [],
          '9': [],
          '19': [],
          '20': [],
          '21': [],
          '52': [],
        }).known,
        false,
      );
      final empty = data()..[9] = [];
      final known = OrderSetCatalog.unknown
          .apply(empty)
          .configurationFor('900');
      expect(known.known, true);
      expect(known.details, isEmpty);
      final missing = data()..[52] = null;
      expect(
        OrderSetCatalog.unknown.apply(missing).configurationFor('900').known,
        false,
      );
    },
  );
  test('9 composite key is parent/group/seq so changing target replaces old candidate', () {
    final d = data()
      ..[9] = [
        [900, 1, 2, 1, 11, 1, 2, 1],
      ];
    final c = OrderSetCatalog.unknown.apply(d).apply({
      '9': [
        [900, 1, 2, 1, 13, 3, 2, 1],
      ],
    });
    expect(c.configurationFor('900').details.map((d) => d.detailProductId), [
      '13',
    ]);
    expect(c.configurationFor('900').details.single.detailCount, 3);
  });
  test(
    'template and product deletions cannot leave a fake or dangling candidate',
    () {
      final c = OrderSetCatalog.unknown.apply(data());
      final removed = c.apply({
        '52': [
          [501, 1, 12, 0, 0, 3, ''],
          [501, 2, 13, 0, 0, 3, ''],
        ],
      });
      expect(removed.configurationFor('900').known, false);
      final missingProduct = c.apply({
        '4': [
          [12, '', 3, 0, '', '', 0, 0, 0, 0],
        ],
      });
      expect(missingProduct.configurationFor('900').known, false);
      expect(c.configurationFor('900').known, true);
    },
  );
  test('requirement groups preserve single/multi selection, ordering and active status', () {
    final c = OrderSetCatalog.unknown.apply(data());
    final groups = c.configurationFor('900').requirementsByProduct['12']!;
    expect(groups.map((g) => g.name), ['加料', '口味']);
    expect(groups.map((g) => g.modeType), [2, 1]);
    expect(groups.last.items.map((item) => item.name), ['正常', '少冰']);
    final updated = c
        .apply({
          '20': [
            [102, '正常', 3, 1, 1],
          ],
          '21': [
            [10, 2, 3],
          ],
        })
        .configurationFor('900');
    expect(updated.requirementsByProduct['12']!.single.items.single.name, '少冰');
    expect(updated.requirementsByProduct['13'], isEmpty);
    expect(() => groups.add(groups.first), throwsUnsupportedError);
  });
  test('bad metadata invalidates only its dataset and cannot be revived by partial patches', () {
    final bad = OrderSetCatalog.unknown.apply(data()).apply({
      '52': [
        [501],
      ],
    });
    expect(bad.known, false);
    expect(bad.rowsForReplay(4), isNotNull);
    expect(bad.rowsForReplay(52), null);
    expect(
      bad.apply({
        '52': [
          [501, 1, 12, 2, 1, 1, ''],
        ],
      }).known,
      false,
    );
    expect(bad.apply(data()).known, true);
  });
  test('card store preserves templates and requirements through replay and invalidation', () {
    final store = LegacyCardTableStore();
    expect(store.applyEnvelope(fixture.event(data())).failureOrNull, null);
    expect(store.orderSetCatalog.configurationFor('900').details.length, 3);
    store.applyEnvelope(
      fixture.event({
        '52': [
          [501, 1, 13, 4, 7, 1, ''],
        ],
      }),
    );
    final replay = LegacyCardTableStore();
    expect(replay.applyEnvelope(store.replayEnvelope!).failureOrNull, null);
    expect(
      replay.orderSetCatalog.configurationFor('900').details[1].detailCount,
      4,
    );
    expect(
      replay.orderSetCatalog
          .configurationFor('900')
          .requirementsByProduct['11']!
          .length,
      2,
    );
  });
}
