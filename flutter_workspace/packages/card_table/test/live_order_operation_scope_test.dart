import 'dart:async';

import 'package:card_table/src/card_table_event_feed.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/live_order_operation_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';

CardTable table() => CardTable(
  id: '100',
  name: 'A',
  regionId: '1',
  seatType: 1,
  businessType: 1,
  capacity: 4,
  displayOrder: 1,
  businessStatus: 4,
  turnoverCount: 1,
  orderAmount: 0,
  paidAmount: 0,
  customerName: '',
  customerCount: 0,
  reservationTime: '',
  openTime: '',
  remark: '',
  mark: '',
);
List<Object?> full({
  int day = 9,
  int turnover = 1,
  int status = 4,
  bool products = true,
}) {
  final data = List<Object?>.filled(60, const <Object?>[]);
  data[0] = [
    [1, '大厅', 1, 1],
  ];
  data[1] = [
    [100, 'A', 1, 1, 1, 1, 4, 1],
  ];
  final business = List<Object?>.filled(38, null);
  business[0] = 100;
  business[2] = '';
  business[5] = '';
  for (final i in [6, 7, 8, 9, 10, 11, 12]) {
    business[i] = 0;
  }
  business[13] = turnover;
  business[16] = '';
  business[17] = '';
  business[18] = 1;
  business[19] = status;
  business[20] = '';
  business[24] = '';
  business[25] = '';
  data[14] = [business];
  data[18] = [
    [day, '', '门店'],
  ];
  data[4] = products
      ? [
          [101, '已停售商品', 2, 0, '', '', 1, 1, 0, 5],
        ]
      : null;
  data[32] = [
    [1, '点错', 1, 2],
  ];
  return data;
}

SyncEnvelope event(Object data) => SyncEnvelope.fromValidatedReconciliation(
  cursor: '20260920100000',
  data: data,
);

void main() {
  test('table revisions are independent from tokens and ignore prices and other tables', () async {
    final data = StreamController<SyncEnvelope>.broadcast(sync: true);
    final phase = StreamController<ConnectionPhase>.broadcast(sync: true);
    final scoped = LiveOrderOperationScope(
      table: table(),
      events: data.stream,
      phases: phase.stream,
      initialPhase: ConnectionPhase.online,
      initialSnapshot: event(full()),
      invalidateOnStatusChange: false,
    );
    expect(scoped.currentTableRevision.value, 1);
    final token = scoped.context.value;
    data.add(
      event({
        '58': [
          [101, 1, 500, 1],
        ],
      }),
    );
    expect(scoped.currentTableRevision.value, 1);
    final other = List<Object?>.of((full()[14] as List).first as List)
      ..[0] = 200;
    data.add(
      event({
        '14': [other],
      }),
    );
    expect(scoped.currentTableRevision.value, 1);
    final current = List<Object?>.of((full()[14] as List).first as List)
      ..[6] = 50;
    data.add(
      event({
        '14': [current],
      }),
    );
    expect(scoped.currentTableRevision.value, 2);
    expect(identical(token, scoped.context.value), true);
    phase.add(ConnectionPhase.reconciling);
    data.add(
      event({
        '14': [current],
      }),
    );
    expect(scoped.currentTableRevision.value, 2);
    phase.add(ConnectionPhase.online);
    expect(scoped.currentTableRevision.value, 3);
    await scoped.dispose();
    await data.close();
    await phase.close();
  });
  test('initial snapshot seeds a broadcast stream and order status transitions preserve token when configured', () async {
    final data = StreamController<SyncEnvelope>.broadcast(sync: true);
    final phase = StreamController<ConnectionPhase>.broadcast(sync: true);
    final seeded = LiveOrderOperationScope(
      table: table(),
      events: data.stream,
      phases: phase.stream,
      initialPhase: ConnectionPhase.online,
      initialSnapshot: event(full()),
      invalidateOnStatusChange: false,
      canOperateInStatus: (status) => !const {1, 2, 8}.contains(status),
    );
    final token = seeded.context.value;
    expect(token, isNotNull);
    final refundToken = seeded.refundContext.value;
    for (final status in [5, 6, 7, 4, 3, 20]) {
      data.add(event(full(status: status)));
      expect(identical(seeded.context.value, token), true);
      expect(identical(seeded.refundContext.value, refundToken), false);
    }
    data.add(event(full(turnover: 2)));
    expect(seeded.context.value, null);
    data.add(event(full()));
    expect(seeded.context.value, null);
    await seeded.dispose();
    await data.close();
    await phase.close();
  });
  test('default paid operation policy still invalidates its active attempt on status transition', () async {
    final data = StreamController<SyncEnvelope>.broadcast(sync: true);
    final phase = StreamController<ConnectionPhase>.broadcast(sync: true);
    final seeded = LiveOrderOperationScope(
      table: table(),
      events: data.stream,
      phases: phase.stream,
      initialPhase: ConnectionPhase.online,
      initialSnapshot: event(full()),
    );
    final token = seeded.context.value;
    data.add(event(full(status: 5)));
    expect(seeded.context.value, isNotNull);
    expect(identical(seeded.context.value, token), false);
    await seeded.dispose();
    await data.close();
    await phase.close();
  });
  late StreamController<SyncEnvelope> events;
  late StreamController<ConnectionPhase> phases;
  late LiveOrderOperationScope scope;
  setUp(() {
    events = StreamController.broadcast(sync: true);
    phases = StreamController.broadcast(sync: true);
    scope = LiveOrderOperationScope(
      table: table(),
      events: events.stream,
      phases: phases.stream,
      initialPhase: ConnectionPhase.online,
    );
  });
  tearDown(() async {
    await scope.dispose();
    await events.close();
    await phases.close();
  });
  test(
    'table extra and deltas alone cannot authorize unknown product types',
    () {
      expect(scope.context.value, null);
      expect(scope.productTypeFor('101'), null);
      events.add(
        event({
          '4': [
            [101, 'x', 1, 0, '', '', 1, 1, 0, 5],
          ],
        }),
      );
      expect(scope.context.value, null);
      events.add(event(full(products: false)));
      expect(scope.context.value, null);
      events.add(event(full()));
      expect(scope.context.value, isNotNull);
      expect(scope.productTypeFor('101'), 5);
      expect(scope.refundReasons, ['点错']);
    },
  );
  test('reconnect receives a new token, while price changes retain historical scope', () {
    events.add(event(full()));
    final token = scope.context.value;
    events.add(
      event({
        '58': [
          [101, 1, 500, 1],
        ],
        '59': [
          [1, 7, 1],
        ],
      }),
    );
    expect(identical(scope.context.value, token), true);
    phases.add(ConnectionPhase.reconciling);
    expect(scope.context.value, null);
    expect(scope.productTypeFor('101'), null);
    phases.add(ConnectionPhase.online);
    expect(scope.context.value, isNotNull);
    expect(identical(scope.context.value, token), false);
  });
  for (final change in ['day', 'turnover', 'empty']) {
    test(
      '$change permanently expires old page even if a later snapshot rolls back',
      () {
        events.add(event(full()));
        expect(scope.context.value, isNotNull);
        events.add(
          event(
            full(
              day: change == 'day' ? 10 : 9,
              turnover: change == 'turnover' ? 2 : 1,
              status: change == 'empty' ? 1 : 4,
            ),
          ),
        );
        expect(scope.context.value, null);
        events.add(event(full()));
        phases.add(ConnectionPhase.online);
        expect(scope.context.value, null);
        expect(scope.refundReasons, isEmpty);
      },
    );
  }
  test('bad product or business metadata requires a new full snapshot', () {
    for (final broken in [
      {
        '4': [
          [101],
        ],
      },
      {
        '14': [
          [100],
        ],
      },
    ]) {
      events.add(event(full()));
      expect(scope.context.value, isNotNull);
      events.add(event(broken));
      expect(scope.context.value, null);
      events.add(event({'58': []}));
      expect(scope.context.value, null);
      events.add(event(full()));
      expect(scope.context.value, isNotNull);
    }
  });
  test('dispose clears synchronously and prevents queued data from restoring access', () async {
    events.add(event(full()));
    expect(scope.context.value, isNotNull);
    final closed = scope.dispose();
    expect(scope.context.value, null);
    events.add(event(full()));
    phases.add(ConnectionPhase.online);
    await closed;
    expect(scope.context.value, null);
  });
  test('late subscribers receive real full replay even when latest event was a delta', () async {
    final feed = CardTableEventFeed()
      ..add(event(full()))
      ..add(event({'58': []}));
    final lateScope = LiveOrderOperationScope(
      table: table(),
      events: feed.events,
      phases: phases.stream,
      initialPhase: ConnectionPhase.online,
    );
    await Future<void>.delayed(Duration.zero);
    expect(lateScope.context.value, isNotNull);
    expect(lateScope.productTypeFor('101'), 5);
    await lateScope.close();
    await feed.close();
  });
}
