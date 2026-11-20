import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_sync/realtime_sync.dart';

List<Object?> business({
  num order = 4700.02,
  Object? discount = '1100.00',
  bool old = false,
  int turnover = 1,
}) {
  final row = List<Object?>.filled(old ? 38 : 39, null);
  row[0] = 100;
  row[2] = '20260920120000';
  row[5] = '20260920123000';
  row[6] = order;
  row[7] = 0;
  row[8] = 20;
  row[9] = 0;
  row[10] = 0;
  row[11] = 0;
  row[12] = 0;
  row[13] = turnover;
  row[16] = '顾客';
  row[17] = '';
  row[18] = 4;
  row[19] = 4;
  row[20] = '';
  row[24] = '';
  row[25] = '';
  row[27] = 200;
  row[31] = 400;
  row[37] = 2;
  if (!old) row[38] = discount;
  return row;
}

SyncEnvelope event(Object data) => SyncEnvelope.fromValidatedReconciliation(
  cursor: '20260920100000',
  data: data,
);
List<Object?> full(List<Object?> row) {
  final data = List<Object?>.filled(57, const <Object?>[]);
  data[0] = [
    [1, '大厅', 1, 1],
  ];
  data[1] = [
    [100, 'A01', 1, 1, 1, 1, 4, 1],
  ];
  data[14] = [row];
  data[18] = [
    [1, '', '测试门店'],
  ];
  return data;
}

void main() {
  test(
    'appended yuan discount augments only current original amount and replays',
    () {
      final store = LegacyCardTableStore();
      expect(store.applyEnvelope(event(full(business()))).failureOrNull, null);
      final table = store.currentSnapshot!.tables.single;
      expect(table.discountAmount, 1100);
      expect(table.originalAmount(), 5800.02);
      expect(table.originalAmount(historical: true), 4700.02);
      expect(table.orderAmount, 4700.02);
      expect(table.paidValAmount, 200);
      expect(table.mainOrderAmount, 400);
      final replay = LegacyCardTableStore()
        ..applyEnvelope(store.replayEnvelope!);
      expect(replay.currentSnapshot!.tables.single.originalAmount(), 5800.02);
    },
  );
  test('live discount zero/update replaces rather than accumulates', () {
    final store = LegacyCardTableStore()
      ..applyEnvelope(event(full(business())));
    expect(
      store
          .applyEnvelope(
            event({
              '14': [business(discount: 0)],
            }),
          )
          .failureOrNull,
      null,
    );
    expect(store.currentSnapshot!.tables.single.originalAmount(), 4700.02);
    store.applyEnvelope(
      event({
        '14': [business(discount: '800.00')],
      }),
    );
    expect(store.currentSnapshot!.tables.single.originalAmount(), 5500.02);
  });
  test('old backend absent null and empty columns all remain valid zero', () {
    for (final row in [
      business(old: true),
      business(discount: null),
      business(discount: ''),
    ]) {
      final store = LegacyCardTableStore();
      expect(store.applyEnvelope(event(full(row))).failureOrNull, null);
      expect(store.currentSnapshot!.tables.single.discountAmount, 0);
      expect(store.currentSnapshot!.tables.single.originalAmount(), 4700.02);
      expect(
        store
            .applyEnvelope(
              event({
                '14': [row],
              }),
            )
            .failureOrNull,
        null,
      );
      final replay = LegacyCardTableStore();
      expect(replay.applyEnvelope(store.replayEnvelope!).failureOrNull, null);
      expect(replay.currentSnapshot!.tables.single.originalAmount(), 4700.02);
    }
  });
  test('rounds operands to cents individually like source footer', () {
    final store = LegacyCardTableStore()
      ..applyEnvelope(event(full(business(order: 0.104, discount: 0.104))));
    expect(store.currentSnapshot!.tables.single.originalAmount(), 0.20);
  });
}
