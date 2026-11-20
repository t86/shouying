import 'package:card_table/src/cashier_profit_loss_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

import 'card_amount_metadata_test.dart' as fixture;

List<Object?> profitMetadata() {
  final data = fixture.full(fixture.business());
  data[2] = [
    [1, '酒水', 1, 1],
    [2, '隐藏分类', 2, 1],
  ];
  data[3] = [
    [11, '啤酒', 1, 1, 1],
    [12, '停用二级', 2, 1, 2],
  ];
  List<Object?> product(
    int id,
    int state,
    int material, [
    int one = 1,
    int two = 11,
  ]) => [
    id,
    '商品$id',
    state,
    1,
    '',
    '',
    one,
    two,
    10,
    1,
    1,
    material,
    1,
    '',
    '1',
    '1',
  ];
  data[4] = [
    product(101, 1, 8),
    product(102, 2, 9),
    product(103, 1, 0),
    product(104, 1, 9, 2, 12),
    product(105, 1, 10),
  ];
  data[16] = [
    [1, 1, 101, 7],
    [2, 1, 101, 7],
    [1, 1, 102, 7],
    [1, 1, 103, 7],
    [1, 1, 104, 7],
    [1, 1, 105, 9],
  ];
  data[30] = [
    [7, '出品酒库', 1],
    [8, '停用库', 2],
    [9, '餐库', 1],
  ];
  return data;
}

void main() {
  test('unassigned library relations do not erase valid libraries', () {
    for (final relation in [
      [3, 1, 101, 0],
      [3, 1, 101],
      [3, 1, 101, null],
      [3, 1, 101, ''],
    ]) {
      final feed = CashierProfitLossMetadata();
      addTearDown(feed.dispose);
      final data = profitMetadata();
      data[16] = [...data[16] as List, relation];
      feed.add(fixture.event(data));
      expect(feed.value.libraries.length, 2);
      expect(feed.value.productsByLibrary['7']!.map((p) => p.id), [
        '101',
        '104',
      ]);
    }
  });
  test('profit catalog uses library and material relations not order PC PAD restrictions', () {
    final feed = CashierProfitLossMetadata();
    addTearDown(feed.dispose);
    feed.add(fixture.event(profitMetadata()));
    expect(feed.value.libraries, {'7': '出品酒库', '9': '餐库'});
    expect(feed.value.productsByLibrary['7']!.map((p) => p.id), ['101', '104']);
    expect(feed.value.productsByLibrary['7']!.first.firstCategory, '酒水');
    expect(feed.value.productsByLibrary['7']!.last.firstCategory, '');
    expect(feed.value.productsByLibrary['9']!.single.id, '105');
  });
  test('incremental relation move and removal use region/product key', () {
    final feed = CashierProfitLossMetadata();
    addTearDown(feed.dispose);
    feed.add(fixture.event(profitMetadata()));
    final original = feed.value;
    feed.add(
      fixture.event({
        '16': [
          [1, 1, 101, 9],
          [2, 3, 101, 7],
        ],
      }),
    );
    expect(identical(original, feed.value), isFalse);
    expect(feed.value.productsByLibrary['7']!.map((p) => p.id), ['104']);
    expect(feed.value.productsByLibrary['9']!.map((p) => p.id), ['101', '105']);
    feed.add(
      fixture.event({
        '30': [
          [9, '餐库', 3],
        ],
      }),
    );
    expect(feed.value.libraries.containsKey('9'), isFalse);
  });
  test('irrelevant updates retain identity; invalid metadata requires full recovery', () {
    final feed = CashierProfitLossMetadata();
    addTearDown(feed.dispose);
    feed.add(fixture.event(profitMetadata()));
    final original = feed.value;
    feed.add(fixture.event({'14': []}));
    expect(identical(feed.value, original), isTrue);
    feed.add(fixture.event({'30': 'bad'}));
    expect(feed.value.libraries, isEmpty);
    feed.add(
      fixture.event({
        '30': [
          [9, '餐库', 1],
        ],
      }),
    );
    expect(feed.value.libraries, isEmpty);
    feed.add(fixture.event(profitMetadata()));
    expect(feed.value.libraries.length, 2);
    feed.invalidate();
    expect(feed.value.libraries, isEmpty);
  });
}
