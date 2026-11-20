import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'card_amount_metadata_test.dart' as fixture show full, business, event;

List<Object?> product(int id, Object pc, Object pad) => [
  id,
  '酒$id',
  1,
  id,
  'jiu$id',
  '',
  1,
  11,
  10,
  1,
  1,
  0,
  1,
  '',
  pc,
  pad,
];

void main() {
  test('default catalog keeps legacy PAD behavior', () {
    final store = LegacyCardTableStore();
    final data = fixture.full(fixture.business());
    expect(store.applyEnvelope(fixture.event(data)).failureOrNull, isNull);
    expect(store.soldOutCatalog.padDevice, true);
    expect(store.catalogForRegion('1').padDevice, true);
  });
  for (final pad in [true, false]) {
    test(
      'store propagates ${pad ? 'PAD' : 'PC'} to both catalog paths and replay',
      () {
        final store = LegacyCardTableStore(padDevice: pad);
        final data = fixture.full(fixture.business());
        data[2] = [
          [1, '酒水', 1, 1],
        ];
        data[3] = [
          [11, '啤酒', 1, 1, 1],
        ];
        data[4] = [
          product(101, '1', '2'),
          product(102, '2', '1'),
          product(103, 1, 1),
        ];
        data[16] = [
          [1, 1, 101],
          [1, 1, 102],
          [1, 1, 103],
        ];
        expect(store.applyEnvelope(fixture.event(data)).failureOrNull, isNull);
        final replay = LegacyCardTableStore(padDevice: pad);
        expect(
          replay.applyEnvelope(store.replayEnvelope!).failureOrNull,
          isNull,
        );
        for (final catalog in [
          store.soldOutCatalog,
          store.catalogForRegion('1'),
          replay.soldOutCatalog,
        ]) {
          expect(catalog.products.map((p) => p.id), ['101', '102', '103']);
          final visible = pad ? ['101', '103'] : ['102', '103'];
          expect(
            catalog.productsIn(firstId: '1', secondId: '11').map((p) => p.id),
            visible,
          );
          expect(
            catalog
                .search(keyword: '', firstId: '1', secondId: '11')
                .map((p) => p.id),
            visible,
          );
          // Legacy newProductListGQ uses allProductsList for nonempty searches.
          expect(
            catalog
                .search(keyword: '酒', firstId: '1', secondId: '11')
                .map((p) => p.id),
            ['101', '102', '103'],
          );
        }
      },
    );
  }
}
