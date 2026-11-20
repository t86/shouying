import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'live_order_operation_scope_test.dart' as fixture;
import 'card_amount_metadata_test.dart' as card_fixture;

void main() {
  testWidgets('refresh keeps only still-valid selected unpaid ids', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final context = ValueNotifier<Object?>(Object()),
        revision = ValueNotifier(0);
    addTearDown(context.dispose);
    addTearDown(revision.dispose);
    var stage = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PayOrderScreen(
          table: fixture.table(),
          operationContext: context,
          currentTableRevision: revision,
          loadOrders:
              ({required String seatId, required int turnoverCount}) async =>
                  Success(
                    PayOrderData(
                      seatId: seatId,
                      unpayItems: [
                        if (stage == 0)
                          const PayOrderItem(
                            id: '1',
                            productId: '101',
                            name: '待结1',
                            count: 1,
                            unitPrice: '1',
                            amount: '1',
                          ),
                        PayOrderItem(
                          id: '2',
                          productId: '102',
                          name: '待结2',
                          count: 1,
                          unitPrice: '2',
                          amount: '2',
                          refunded: stage == 2,
                        ),
                      ],
                    ),
                  ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('待结1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('待结2'));
    await tester.pumpAndSettle();
    expect(find.text('结账 ￥3.0'), findsOneWidget);
    stage = 1;
    revision.value++;
    await tester.pumpAndSettle();
    expect(find.text('结账 ￥2.0'), findsOneWidget);
    stage = 2;
    revision.value++;
    await tester.pumpAndSettle();
    expect(find.text('结账 ￥0.0'), findsOneWidget);
  });
  testWidgets(
    'card-table pushed payment receives revisions without a duplicate initial read',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      var reads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            stationId: '9',
            employeeId: '7',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onLoadPayOrders:
                ({required String seatId, required int turnoverCount}) async {
                  reads++;
                  return Success(
                    PayOrderData(
                      seatId: seatId,
                      turnoverCount: turnoverCount,
                      unpayItems: [
                        PayOrderItem(
                          id: '1',
                          productId: '101',
                          name: '读取$reads',
                          count: 1,
                          unitPrice: '1',
                          amount: '1',
                        ),
                      ],
                    ),
                  );
                },
          ),
        ),
      );
      events.add(
        card_fixture.event(card_fixture.full(card_fixture.business())),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(find.text('读取1'), findsOneWidget);
      events.add(
        card_fixture.event({
          '14': [card_fixture.business(order: 5000)],
        }),
      );
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('读取2'), findsOneWidget);
    },
  );
  testWidgets(
    'refresh retains active payment by id when another payment is inserted',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final context = ValueNotifier<Object?>(Object()),
          revision = ValueNotifier(0);
      addTearDown(context.dispose);
      addTearDown(revision.dispose);
      var updated = false;
      PayedOrderRecord record(String id) => PayedOrderRecord(
        id: id,
        items: [
          PayOrderItem(
            id: id,
            productId: '101',
            name: '支付单$id商品',
            count: 1,
            unitPrice: '1',
            amount: '1',
            paidOrderId: id,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: fixture.table(),
            operationContext: context,
            currentTableRevision: revision,
            loadOrders:
                ({required String seatId, required int turnoverCount}) async =>
                    Success(
                      PayOrderData(
                        seatId: seatId,
                        payedOrders: [
                          if (updated) record('3'),
                          record('1'),
                          record('2'),
                        ],
                      ),
                    ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('已结支付单 2'));
      await tester.pumpAndSettle();
      expect(find.text('支付单2商品'), findsOneWidget);
      updated = true;
      revision.value++;
      await tester.pumpAndSettle();
      expect(find.text('支付单2商品'), findsOneWidget);
      expect(find.text('支付单1商品'), findsNothing);
    },
  );
  testWidgets(
    'pushes during an active read coalesce and discard its stale result',
    (tester) async {
      final context = ValueNotifier<Object?>(Object()),
          revision = ValueNotifier(0);
      addTearDown(context.dispose);
      addTearDown(revision.dispose);
      final pending = Completer<Result<PayOrderData>>();
      var reads = 0;
      PayOrderData data(String name) => PayOrderData(
        seatId: '100',
        unpayItems: [
          PayOrderItem(
            id: '1',
            productId: '101',
            name: name,
            count: 1,
            unitPrice: '1',
            amount: '1',
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: fixture.table(),
            operationContext: context,
            currentTableRevision: revision,
            loadOrders: ({required String seatId, required int turnoverCount}) {
              reads++;
              return reads == 1
                  ? pending.future
                  : Future.value(Success(data('最新读取')));
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(reads, 1);
      revision.value++;
      revision.value++;
      revision.value++;
      await tester.pump();
      expect(reads, 1);
      pending.complete(Success(data('旧读取')));
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('旧读取'), findsNothing);
      expect(find.text('最新读取'), findsOneWidget);
    },
  );
  testWidgets(
    'many live pushes during a write wait and coalesce without unlocking the write',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final context = ValueNotifier<Object?>(Object()),
          revision = ValueNotifier(0);
      addTearDown(context.dispose);
      addTearDown(revision.dispose);
      final write = Completer<Result<void>>();
      var reads = 0, writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: fixture.table(),
            operationContext: context,
            currentTableRevision: revision,
            loadOrders:
                ({required String seatId, required int turnoverCount}) async {
                  reads++;
                  return Success(PayOrderData(seatId: seatId));
                },
            setSettleMode: ({required String seatId, required int settleMode}) {
              writes++;
              return write.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, 1);
      await tester.tap(find.text('先后买单'));
      await tester.pump();
      expect(writes, 1);
      revision.value++;
      revision.value++;
      revision.value++;
      await tester.pump();
      expect(reads, 1);
      expect(
        tester
            .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, '先后买单'))
            .onPressed,
        null,
      );
      write.complete(
        const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'test.failed',
            safeMessage: '写失败',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(writes, 1);
    },
  );
  testWidgets(
    'revoked scope discards pending reads and new scope never shows old rows',
    (tester) async {
      final context = ValueNotifier<Object?>(Object()),
          revision = ValueNotifier(0);
      addTearDown(context.dispose);
      addTearDown(revision.dispose);
      final oldRead = Completer<Result<PayOrderData>>();
      var reads = 0;
      PayOrderData data(String name) => PayOrderData(
        seatId: '100',
        unpayItems: [
          PayOrderItem(
            id: '1',
            productId: '101',
            name: name,
            count: 1,
            unitPrice: '38',
            amount: '38',
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: fixture.table(),
            operationContext: context,
            currentTableRevision: revision,
            loadOrders: ({required String seatId, required int turnoverCount}) {
              reads++;
              return reads == 1
                  ? oldRead.future
                  : Future.value(Success(data('新身份数据')));
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(reads, 1);
      context.value = null;
      await tester.pump();
      oldRead.complete(Success(data('旧身份迟到数据')));
      await tester.pumpAndSettle();
      expect(find.text('旧身份迟到数据'), findsNothing);
      context.value = Object();
      revision.value++;
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(find.text('新身份数据'), findsOneWidget);
      expect(find.text('旧身份迟到数据'), findsNothing);
    },
  );
  testWidgets(
    'same-business remote mutation automatically refreshes payment rows and summary',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      final phases = StreamController<ConnectionPhase>.broadcast(sync: true);
      addTearDown(events.close);
      addTearDown(phases.close);
      var orderReads = 0, cartReads = 0, remoteUpdated = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PayOrderScreen(
            table: fixture.table(),
            events: events.stream,
            connectionPhases: phases.stream,
            connectionPhase: ConnectionPhase.online,
            loadOrders:
                ({required String seatId, required int turnoverCount}) async {
                  orderReads++;
                  return Success(
                    PayOrderData(
                      seatId: seatId,
                      turnoverCount: turnoverCount,
                      unpayItems: [
                        PayOrderItem(
                          id: '1',
                          productId: '101',
                          name: remoteUpdated ? '其他终端更新后商品' : '原商品',
                          count: 1,
                          unitPrice: '38',
                          amount: remoteUpdated ? '76' : '38',
                        ),
                      ],
                      summary: OrderSummary(
                        allAmt: remoteUpdated ? '76.00' : '38.00',
                        giveAmt: '0.00',
                        discountAmt: '0.00',
                        notPayAmt: remoteUpdated ? '56.00' : '38.00',
                      ),
                    ),
                  );
                },
            loadCart: (seatId) async {
              cartReads++;
              return const Success([]);
            },
          ),
        ),
      );
      final initial = fixture.full();
      events.add(fixture.event(initial));
      await tester.pumpAndSettle();
      expect(orderReads, 1);
      expect(cartReads, 1);
      expect(find.text('原商品'), findsOneWidget);
      remoteUpdated = true;
      final changed = List<Object?>.of((initial[14] as List).single as List);
      changed[6] = 76;
      changed[8] = 20;
      events.add(
        fixture.event({
          '14': [changed],
        }),
      );
      await tester.pumpAndSettle();
      expect(orderReads, 2);
      expect(cartReads, 2);
      expect(find.text('其他终端更新后商品'), findsOneWidget);
      expect(find.text('未结金额: ￥76.00'), findsOneWidget);
      await tester.tap(find.text('全部消费'));
      await tester.pumpAndSettle();
      expect(find.text('未结金额: ￥56.00'), findsOneWidget);
    },
  );
}
