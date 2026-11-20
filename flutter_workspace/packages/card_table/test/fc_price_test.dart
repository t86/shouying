import 'package:card_table/src/fc_price.dart';
import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_sync/realtime_sync.dart';

List<Object?> metadata({Object? prices, Object? employees}) {
  final data = List<Object?>.filled(60, const <Object?>[]);
  data[0] = [];
  data[1] = [];
  data[14] = [];
  data[18] = [
    [1, '2026-09-20', '门店'],
  ];
  data[58] =
      prices ??
      [
        ['9', '1', '3300', '1'],
        ['9', '2', '6300', '1'],
      ];
  data[59] =
      employees ??
      [
        ['1', '11', '1'],
        ['2', '22', '1'],
      ];
  return data;
}

SyncEnvelope event(Object data) => SyncEnvelope.fromValidatedReconciliation(
  cursor: '20260920100000',
  data: data,
);

void main() {
  test(
    'author takes priority without falling back when its plan is absent',
    () {
      final c = FcPriceCatalog.unknown.apply(metadata());
      expect(c.known, true);
      expect(c.resolve(productId: 9, authorId: 11, orderEmployeeId: 22), 33);
      expect(c.resolve(productId: 9, authorId: 0, orderEmployeeId: 22), 63);
      expect(c.resolve(productId: 9, authorId: 99, orderEmployeeId: 22), null);
      expect(c.resolve(productId: 9, authorId: 1.5, orderEmployeeId: 22), null);
    },
  );
  test('zero valid; invalid amounts are never converted to free prices', () {
    for (final amount in [0, '', null, 'NaN', -1, 33.5, 9007199254740992]) {
      final c = FcPriceCatalog.unknown.apply(
        metadata(
          prices: [
            [9, 1, amount, 1],
          ],
        ),
      );
      expect(
        c.resolve(productId: 9, orderEmployeeId: 11),
        amount == 0 ? 0 : null,
      );
    }
  });
  test('composite updates preserve other plans and revoke by status', () {
    final c = FcPriceCatalog.unknown.apply(metadata());
    final changed = c.apply({
      '58': [
        [9, 1, 0, 1],
      ],
      '59': [
        [1, 11, 3],
        [2, 11, 1],
      ],
    });
    expect(changed.resolve(productId: 9, orderEmployeeId: 11), 63);
    expect(c.resolve(productId: 9, orderEmployeeId: 11), 33);
    final revoked = changed.apply({
      '58': [
        [9, 2, 6300, 2],
      ],
    });
    expect(revoked.resolve(productId: 9, orderEmployeeId: 11), null);
  });
  test('unknown is distinct from confirmed empty; incomplete deltas cannot initialize', () {
    expect(FcPriceCatalog.unknown.known, false);
    final empty = FcPriceCatalog.unknown.apply(
      metadata(prices: [], employees: []),
    );
    expect(empty.known, true);
    expect(empty.resolve(productId: 9, orderEmployeeId: 11), null);
    expect(FcPriceCatalog.unknown.apply({'58': [], '59': []}).known, false);
    expect(empty.apply(metadata()..[59] = null).known, false);
  });
  test('malformed dataset invalidates pricing until another full snapshot', () {
    final c = FcPriceCatalog.unknown.apply(metadata()).apply({
      '58': [
        [9],
      ],
    });
    expect(c.known, false);
    expect(c.resolve(productId: 9, orderEmployeeId: 11), null);
    expect(
      c.apply({
        '58': [
          [9, 1, 3300, 1],
        ],
        '59': [
          [1, 11, 1],
        ],
      }).known,
      false,
    );
    expect(c.apply(metadata()).known, true);
  });
  test(
    'card store retains scheme data through incremental update and replay',
    () {
      final store = LegacyCardTableStore();
      expect(store.applyEnvelope(event(metadata())).failureOrNull, null);
      expect(
        store.fcPriceCatalog.resolve(productId: 9, orderEmployeeId: 11),
        33,
      );
      expect(
        store
            .applyEnvelope(
              event({
                '58': [
                  [9, 1, 0, 1],
                ],
              }),
            )
            .failureOrNull,
        null,
      );
      final replayed = LegacyCardTableStore();
      expect(replayed.applyEnvelope(store.replayEnvelope!).failureOrNull, null);
      expect(replayed.fcPriceCatalog.known, true);
      expect(
        replayed.fcPriceCatalog.resolve(productId: 9, orderEmployeeId: 11),
        0,
      );
    },
  );
  test('old card snapshot stays usable but replay does not manufacture scheme readiness', () {
    final old = metadata()
      ..[58] = null
      ..[59] = null;
    final store = LegacyCardTableStore();
    expect(store.applyEnvelope(event(old)).failureOrNull, null);
    expect(store.fcPriceCatalog.known, false);
    final replayed = LegacyCardTableStore();
    expect(replayed.applyEnvelope(store.replayEnvelope!).failureOrNull, null);
    expect(replayed.fcPriceCatalog.known, false);
  });
  test('a rejected packet containing scheme changes cannot leave stale prices ready', () {
    final store = LegacyCardTableStore();
    expect(store.applyEnvelope(event(metadata())).failureOrNull, null);
    expect(
      store
          .applyEnvelope(
            event({
              '1': 'broken',
              '58': [
                [9, 1, 9900, 1],
              ],
            }),
          )
          .failureOrNull,
      isNotNull,
    );
    expect(store.fcPriceCatalog.known, false);
    expect(
      store
          .applyEnvelope(
            event({
              '58': [
                [9, 1, 3300, 1],
              ],
            }),
          )
          .failureOrNull,
      null,
    );
    expect(store.fcPriceCatalog.known, false);
    expect(store.applyEnvelope(event(metadata())).failureOrNull, null);
    expect(store.fcPriceCatalog.known, true);
  });
}
