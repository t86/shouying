import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_sync/realtime_sync.dart';

List<Object?> _metadata() {
  final data = List<Object?>.filled(60, const <Object?>[]);
  data[18] = [
    [1, '', 'test'],
  ];
  data[4] = [
    [1, '不在当前区域的赔偿', 1, 0, '', '', 1, 1, 0, 5],
    [2, '停用历史商品', 2, 0, '', '', 1, 1, 0, 3],
  ];
  return data;
}

void main() {
  test(
    'rejected whole packet cannot retain a changed product classification',
    () {
      final store = LegacyCardTableStore();
      store.applyEnvelope(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920100000',
          data: _metadata(),
        ),
      );
      final result = store.applyEnvelope(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260920100001',
          data: {
            '4': [
              [1, 'changed', 1, 0, '', '', 1, 1, 0, 3],
            ],
            '14': [
              [100],
            ],
          },
        ),
      );
      expect(result.failureOrNull, isNotNull);
      expect(store.productTypeFor('1'), isNull);
    },
  );
  test('refund product type uses all metadata, including inactive history', () {
    final store = LegacyCardTableStore();
    expect(store.productTypeFor('1'), isNull);
    final result = store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260920100000',
        data: _metadata(),
      ),
    );
    expect(result.failureOrNull, isNull);
    expect(store.catalogForRegion('1').products, isEmpty);
    expect(store.productTypeFor('1'), 5);
    expect(store.productTypeFor('2'), 3);
    expect(store.productTypeFor('999'), isNull);
    store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260920100001',
        data: {
          '4': [
            [1, 'deleted', 3, 0, '', '', 1, 1, 0, 5],
          ],
        },
      ),
    );
    expect(store.productTypeFor('1'), isNull);
  });
  test('bad product update cannot leave a stale refund classification', () {
    final store = LegacyCardTableStore();
    store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260920100000',
        data: _metadata(),
      ),
    );
    store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260920100001',
        data: {
          '4': [
            [1, 'invalid'],
          ],
        },
      ),
    );
    expect(store.productTypeFor('1'), isNull);
    store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260920100002',
        data: {
          '4': [
            [1, 'part', 1, 0, '', '', 1, 1, 0, 5],
          ],
        },
      ),
    );
    expect(store.productTypeFor('1'), isNull);
    final restored = LegacyCardTableStore();
    restored.applyEnvelope(store.replayEnvelope!);
    expect(restored.productTypeFor('1'), isNull);
    store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260920100003',
        data: _metadata(),
      ),
    );
    expect(store.productTypeFor('1'), 5);
  });
}
