import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'card_amount_metadata_test.dart' as fixture;
import 'cashier_profit_loss_metadata_test.dart' show profitMetadata;

void main() {
  for (final change in ['metadata', 'phase', 'stream', 'employee']) {
    testWidgets(
      'Card $change invalidates a pending stock write and never revives it',
      (tester) async {
        final events = StreamController<SyncEnvelope>.broadcast(sync: true);
        final nextEvents = StreamController<SyncEnvelope>.broadcast(sync: true);
        final phases = StreamController<ConnectionPhase>.broadcast(sync: true);
        addTearDown(events.close);
        addTearDown(nextEvents.close);
        addTearDown(phases.close);
        final pending = Completer<Result<void>>();
        bool Function()? dispatch;
        Widget app(Stream<SyncEnvelope> stream, String employee) => MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            employeeId: employee,
            stationId: '9',
            connectionPhase: ConnectionPhase.online,
            connectionPhases: phases.stream,
            events: stream,
            onLoadProfitLoss: () async => const Success([]),
            onSubmitProfitLoss: (draft, guard) {
              dispatch = guard;
              return pending.future;
            },
          ),
        );
        await tester.pumpWidget(app(events.stream, '7'));
        final data = profitMetadata();
        data[54] = [
          [1, 0],
        ];
        events.add(fixture.event(data));
        await tester.pumpAndSettle();
        tester
            .widget<PopupMenuButton<String>>(
              find.byKey(CardTableScreen.moreFunctionsKey),
            )
            .onSelected!('盘盈盘亏');
        await tester.pumpAndSettle();
        final screen = tester.widget<CashierProfitLossScreen>(
          find.byType(CashierProfitLossScreen),
        );
        await tester.tap(find.text('添加盘盈盘亏单'));
        await tester.pumpAndSettle();
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const ValueKey('profit-library')),
            )
            .onChanged!('7');
        await tester.pump();
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const ValueKey('profit-product-0')),
            )
            .onChanged!('101');
        await tester.pump();
        await tester.tap(find.text('确定'));
        await tester.pump();
        expect(dispatch?.call(), true);
        switch (change) {
          case 'metadata':
            events.add(
              fixture.event({
                '16': [
                  [1, 3, 101, 7],
                  [2, 3, 101, 7],
                ],
              }),
            );
          case 'phase':
            phases.add(ConnectionPhase.blocked);
            phases.add(ConnectionPhase.online);
          case 'stream':
            await tester.pumpWidget(app(nextEvents.stream, '7'));
          case 'employee':
            await tester.pumpWidget(app(events.stream, '8'));
        }
        await tester.pump();
        expect(dispatch?.call(), false);
        if (change == 'stream') {
          nextEvents.add(
            fixture.event({
              '30': [
                [7, '出品酒库', 1],
              ],
            }),
          );
          await tester.pump();
          expect(screen.catalog.value.libraries, isEmpty);
        }
        (change == 'stream' ? nextEvents : events).add(fixture.event(data));
        await tester.pump();
        expect(dispatch?.call(), false);
        pending.complete(const Success(null));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets(
    'cashier menu reaches source stock catalog and submits without a business day gate',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      var loads = 0;
      final drafts = <CashierProfitLossDraft>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            employeeId: '7',
            stationId: '9',
            connectionPhase: ConnectionPhase.online,
            events: events.stream,
            onLoadProfitLoss: () async {
              loads++;
              return const Success([]);
            },
            onSubmitProfitLoss: (draft, guard) async {
              expect(guard(), isTrue);
              drafts.add(draft);
              return const Success(null);
            },
          ),
        ),
      );
      final data = profitMetadata();
      data[54] = [
        [1, 0],
      ];
      data[18] = [
        [0, '', '测试门店'],
      ];
      events.add(fixture.event(data));
      await tester.pumpAndSettle();
      tester
          .widget<PopupMenuButton<String>>(
            find.byKey(CardTableScreen.moreFunctionsKey),
          )
          .onSelected!('盘盈盘亏');
      await tester.pumpAndSettle();
      expect(find.byType(CashierProfitLossScreen), findsOneWidget);
      expect(loads, 1);
      await tester.tap(find.text('添加盘盈盘亏单'));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('profit-library')),
          )
          .onChanged!('7');
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('profit-product-0')),
          )
          .onChanged!('101');
      await tester.pump();
      await tester.enterText(find.byKey(const ValueKey('profit-count-0')), '2');
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(drafts.single.libraryId, '7');
      expect(drafts.single.entries.single.productId, '101');
      expect(drafts.single.entries.single.profit, 2);
      expect(loads, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
