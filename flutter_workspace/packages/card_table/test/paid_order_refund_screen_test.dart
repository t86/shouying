import 'dart:async';

import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/pay_order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';

import 'live_order_operation_scope_test.dart' as scope_fixture show full, event;

CardTable table({int businessStatus = 5}) => CardTable(
  id: '100',
  name: 'A01',
  regionId: '1',
  seatType: 1,
  businessType: 1,
  capacity: 4,
  displayOrder: 1,
  businessStatus: businessStatus,
  orderAmount: 90,
  paidAmount: 90,
  customerName: '',
  customerCount: 1,
  reservationTime: '',
  openTime: '12:00',
  remark: '',
  mark: '',
  turnoverCount: 2,
);
PayedOrderRecord record({
  int count = 3,
  bool refunded = false,
  String paidAmt = '90',
  List<PayedChannelItem> channels = const [],
}) => PayedOrderRecord(
  id: '77',
  originalAmt: '90',
  paidAmt: paidAmt,
  channels: channels,
  items: [
    PayOrderItem(
      id: '9',
      productId: '101',
      name: '已结商品',
      count: count,
      unitPrice: '40',
      recordedUnitPrice: '30',
      amount: '90',
      status: 5,
      refunded: refunded,
    ),
  ],
);
PayOrderData data({PayedOrderRecord? paid}) => PayOrderData(
  seatId: '100',
  turnoverCount: 2,
  payedOrders: [paid ?? record()],
);
void main() {
  testWidgets('empty table blocks paid refund even with valid external token', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final token = ValueNotifier<Object?>(Object());
    addTearDown(token.dispose);
    var writes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PayOrderScreen(
          table: table(businessStatus: 1),
          refundContext: token,
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          productTypeFor: (_) => 1,
          refundReasons: const ['点错'],
          loadOrders: ({
            required String seatId,
            required int turnoverCount,
          }) async => Success(data()),
          refundPayed:
              ({
                required String seatId,
                required String payId,
                required List<String> orderIds,
                required List<int> counts,
                required List<String> amounts,
                required String remark,
              }) async {
                writes++;
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('已结支付单 77'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('pay-order-refund-payed')))
          .onPressed,
      isNull,
    );
    expect(writes, 0);
    expect(find.byKey(const Key('paid-refund-submit')), findsNothing);
  });
  testWidgets(
    'direct paid route requires a full live scope and disconnect invalidates its dialog',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = StreamController<SyncEnvelope>.broadcast(sync: true),
          phases = StreamController<ConnectionPhase>.broadcast(sync: true);
      addTearDown(events.close);
      addTearDown(phases.close);
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: table(),
            events: events.stream,
            connectionPhases: phases.stream,
            connectionPhase: ConnectionPhase.online,
            loadOrders: ({
              required String seatId,
              required int turnoverCount,
            }) async => Success(data()),
            refundPayed:
                ({
                  required String seatId,
                  required String payId,
                  required List<String> orderIds,
                  required List<int> counts,
                  required List<String> amounts,
                  required String remark,
                }) async {
                  writes++;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('已结支付单 77'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('pay-order-refund-payed')),
            )
            .onPressed,
        isNull,
      );
      events.add(
        scope_fixture.event(scope_fixture.full(turnover: 2, status: 5)),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('pay-order-refund-payed')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const Key('pay-order-refund-payed')));
      await tester.pumpAndSettle();
      expect(find.text('点错'), findsOneWidget);
      phases.add(ConnectionPhase.reconciling);
      await tester.pump();
      phases.add(ConnectionPhase.online);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('paid-refund-submit')))
            .onPressed,
        isNull,
      );
      expect(writes, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
  Future<void> setup(
    WidgetTester tester, {
    required ValueNotifier<Object?> token,
    required PayOrderLoad load,
    required PayOrderRefundPayed refund,
    int? type = 1,
    bool old = false,
  }) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: PayOrderScreen(
          table: table(),
          loadOrders: load,
          refundContext: token,
          operationContext: const AlwaysStoppedAnimation<Object?>(true),
          productTypeFor: (_) => type,
          refundReasons: const ['点错'],
          refundPayed: refund,
          isOldOrder: old,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('已结支付单 77'));
    await tester.pumpAndSettle();
    if (!old) {
      await tester.tap(find.byKey(const Key('pay-order-refund-payed')));
      await tester.pumpAndSettle();
    }
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('点错'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('paid-refund-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('paid-refund-final-confirm')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'paid selection preserves aligned arrays for only selected rows',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      List<String>? sentIds, sentAmounts;
      List<int>? sentCounts;
      final paid = PayedOrderRecord(
        id: '77',
        items: [
          ...record().items,
          const PayOrderItem(
            id: '10',
            productId: '102',
            name: '第二商品',
            count: 2,
            unitPrice: '10',
            recordedUnitPrice: '8',
            amount: '16',
            authorizationType: 2,
            status: 5,
          ),
        ],
      );
      await setup(
        tester,
        token: token,
        load: ({required String seatId, required int turnoverCount}) async =>
            Success(data(paid: paid)),
        refund:
            ({
              required String seatId,
              required String payId,
              required List<String> orderIds,
              required List<int> counts,
              required List<String> amounts,
              required String remark,
            }) async {
              sentIds = orderIds;
              sentCounts = counts;
              sentAmounts = amounts;
              return const Success(null);
            },
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('paid-refund-select-9')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('paid-refund-select-10')),
            )
            .value,
        isTrue,
      );
      await tester.tap(find.byKey(const Key('paid-refund-select-9')));
      await tester.pump();
      await confirm(tester);
      expect(sentIds, ['10']);
      expect(sentCounts, [2]);
      expect(sentAmounts, ['16']);
    },
  );
  for (final changed in ['paidAmt', 'channel', 'channelId']) {
    testWidgets('paid preflight rejects changed $changed before refund', (
      tester,
    ) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      var loads = 0, writes = 0;
      final pending = Completer<Result<PayOrderData>>();
      final original = record(
        channels: const [
          PayedChannelItem(channelId: '1', channelName: '现金', amount: 90),
        ],
      );
      await setup(
        tester,
        token: token,
        load: ({required String seatId, required int turnoverCount}) async =>
            ++loads == 1 ? Success(data(paid: original)) : pending.future,
        refund:
            ({
              required String seatId,
              required String payId,
              required List<String> orderIds,
              required List<int> counts,
              required List<String> amounts,
              required String remark,
            }) async {
              writes++;
              return const Success(null);
            },
      );
      await confirm(tester);
      pending.complete(
        Success(
          data(
            paid: record(
              paidAmt: changed == 'paidAmt' ? '100' : '90',
              channels: [
                PayedChannelItem(
                  channelId: changed == 'channelId' ? '2' : '1',
                  channelName: changed == 'channel' ? '银行卡' : '现金',
                  amount: 90,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.textContaining('支付金额或渠道已变化'), findsOneWidget);
    });
  }
  testWidgets(
    'partial paid refund uses one payid and historical price then reloads same tab',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      var loads = 0;
      Map<String, Object?>? sent;
      await setup(
        tester,
        token: token,
        load: ({required String seatId, required int turnoverCount}) async {
          loads++;
          return Success(data());
        },
        refund:
            ({
              required String seatId,
              required String payId,
              required List<String> orderIds,
              required List<int> counts,
              required List<String> amounts,
              required String remark,
            }) async {
              sent = {
                'seat': seatId,
                'pay': payId,
                'ids': orderIds,
                'counts': counts,
                'amounts': amounts,
                'remark': remark,
              };
              return const Success(null);
            },
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('paid-refund-count-9')))
            .controller!
            .text,
        '3',
      );
      await tester.enterText(find.byKey(const Key('paid-refund-count-9')), '1');
      await tester.pump();
      await confirm(tester);
      expect(sent, {
        'seat': '100',
        'pay': '77',
        'ids': ['9'],
        'counts': [1],
        'amounts': ['30'],
        'remark': '点错',
      });
      expect(loads, 3);
      expect(find.byKey(const Key('paid-refund-submit')), findsNothing);
      expect(find.byKey(const Key('pay-order-refund-payed')), findsOneWidget);
    },
  );
  testWidgets('paid preflight cancel prevents later write', (tester) async {
    final token = ValueNotifier<Object?>(Object());
    addTearDown(token.dispose);
    var loads = 0, writes = 0;
    final pending = Completer<Result<PayOrderData>>();
    await setup(
      tester,
      token: token,
      load: ({required String seatId, required int turnoverCount}) async =>
          ++loads == 1 ? Success(data()) : pending.future,
      refund:
          ({
            required String seatId,
            required String payId,
            required List<String> orderIds,
            required List<int> counts,
            required List<String> amounts,
            required String remark,
          }) async {
            writes++;
            return const Success(null);
          },
    );
    await confirm(tester);
    expect(loads, 2);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    pending.complete(Success(data()));
    await tester.pumpAndSettle();
    expect(writes, 0);
  });
  testWidgets(
    'special partial amount is explicit and server code2 is not unpaid authorization',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      List<String>? submitted;
      var writes = 0;
      await setup(
        tester,
        token: token,
        type: 3,
        load: ({required String seatId, required int turnoverCount}) async =>
            Success(data()),
        refund:
            ({
              required String seatId,
              required String payId,
              required List<String> orderIds,
              required List<int> counts,
              required List<String> amounts,
              required String remark,
            }) async {
              writes++;
              submitted = amounts;
              return const FailureResult(
                AppFailure(
                  kind: FailureKind.business,
                  code: 'pay_order.rejected',
                  safeMessage: '退款被拒绝',
                ),
              );
            },
      );
      await tester.enterText(find.byKey(const Key('paid-refund-count-9')), '1');
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('paid-refund-amount-9')))
            .controller!
            .text,
        '',
      );
      await tester.enterText(
        find.byKey(const Key('paid-refund-amount-9')),
        '20',
      );
      await confirm(tester);
      expect(writes, 1);
      expect(submitted, ['20']);
      expect(find.text('退款被拒绝'), findsOneWidget);
      expect(find.text('退单授权'), findsNothing);
      expect(find.byKey(const Key('paid-refund-amount-9')), findsOneWidget);
    },
  );
  testWidgets(
    'changed selected row fails fresh preflight and preserves draft',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      var loads = 0, writes = 0;
      await setup(
        tester,
        token: token,
        load: ({required String seatId, required int turnoverCount}) async =>
            Success(data(paid: record(count: ++loads == 1 ? 3 : 2))),
        refund:
            ({
              required String seatId,
              required String payId,
              required List<String> orderIds,
              required List<int> counts,
              required List<String> amounts,
              required String remark,
            }) async {
              writes++;
              return const Success(null);
            },
      );
      await confirm(tester);
      expect(writes, 0);
      expect(find.textContaining('所选商品已变化'), findsOneWidget);
      expect(find.byKey(const Key('paid-refund-submit')), findsOneWidget);
    },
  );
  testWidgets(
    'unknown type and historical context cannot submit guessed paid refund',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      var writes = 0;
      Future<Result<void>> refund({
        required String seatId,
        required String payId,
        required List<String> orderIds,
        required List<int> counts,
        required List<String> amounts,
        required String remark,
      }) async {
        writes++;
        return const Success(null);
      }

      await setup(
        tester,
        token: token,
        type: null,
        load: ({required String seatId, required int turnoverCount}) async =>
            Success(data()),
        refund: refund,
      );
      await tester.tap(find.text('点错'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('paid-refund-submit')));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.textContaining('商品类型未知'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await setup(
        tester,
        token: token,
        old: true,
        load: ({required String seatId, required int turnoverCount}) async =>
            Success(data()),
        refund: refund,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('pay-order-refund-payed')),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'paid refund only opens from a concrete paid tab with strong warning',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: table(),
            loadOrders: ({
              required String seatId,
              required int turnoverCount,
            }) async => Success(data()),
            refundContext: token,
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            productTypeFor: (_) => 1,
            refundReasons: const ['点错'],
            refundPayed:
                ({
                  required String seatId,
                  required String payId,
                  required List<String> orderIds,
                  required List<int> counts,
                  required List<String> amounts,
                  required String remark,
                }) async {
                  writes++;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pay-order-refund-payed')), findsNothing);
      await tester.tap(find.text('已结支付单 77'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-order-refund-payed')));
      await tester.pumpAndSettle();
      expect(find.textContaining('已支付渠道将进入滞留金'), findsOneWidget);
      expect(writes, 0);
    },
  );
}
