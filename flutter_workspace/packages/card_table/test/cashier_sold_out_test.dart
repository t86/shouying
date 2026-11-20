import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'card_amount_metadata_test.dart' as fixture;
import 'card_catalog_platform_test.dart' show product;

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.windows]) {
    testWidgets(
      'cashier opens maintenance without order module 5 on $platform',
      (tester) async {
        final events = StreamController<SyncEnvelope>.broadcast(sync: true);
        addTearDown(events.close);
        var lists = 0;
        final deleted = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: CardTableScreen(
              system: BusinessSystem.cashier,
              employeeId: '7',
              stationId: '9',
              events: events.stream,
              connectionPhase: ConnectionPhase.online,
              onListSoldOutProducts: () async {
                lists++;
                return Success([
                  SoldOutItem.fromWire({'id': 101, 'n': '估清商品A', 'c': 0}),
                ]);
              },
              onSetSoldOutProduct: ({
                required String productId,
                required int count,
                bool Function()? canDispatch,
              }) async => const Success(null),
              onDeleteSoldOutProduct:
                  (id, {bool Function()? canDispatch}) async {
                    deleted.add(id);
                    return const Success(null);
                  },
            ),
          ),
        );
        final data = fixture.full(fixture.business());
        data[54] = [
          [1, 0],
        ];
        data[2] = [
          [1, '酒水', 1, 1],
        ];
        data[3] = [
          [11, '啤酒', 1, 1, 1],
        ];
        data[4] = [product(101, '1', '2'), product(102, '2', '1')];
        data[16] = [
          [1, 1, 101],
          [1, 1, 102],
        ];
        events.add(fixture.event(data));
        await tester.pumpAndSettle();
        tester
            .widget<PopupMenuButton<String>>(
              find.byKey(CardTableScreen.moreFunctionsKey),
            )
            .onSelected!('估清商品');
        await tester.pumpAndSettle();
        expect(find.byType(SoldOutProductsScreen), findsOneWidget);
        final catalog = tester
            .widget<SoldOutProductsScreen>(find.byType(SoldOutProductsScreen))
            .catalog;
        expect(catalog.padDevice, platform == TargetPlatform.android);
        expect(
          catalog.productsIn(firstId: '1', secondId: '11').single.id,
          platform == TargetPlatform.android ? '101' : '102',
        );
        expect(lists, 1);
        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();
        expect(deleted, ['101']);
        expect(tester.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(platform),
    );
  }

  for (final system in [BusinessSystem.order, BusinessSystem.cashier]) {
    for (final change in [
      'permission',
      'phaseError',
      'phaseDone',
      'dataError',
      'dataDone',
      'back',
    ]) {
      testWidgets(
        '$system invalidates a pending maintenance write after $change',
        (tester) async {
          final events = StreamController<SyncEnvelope>.broadcast(sync: true);
          addTearDown(() {
            if (!events.isClosed) return events.close();
          });
          final phases = StreamController<ConnectionPhase>.broadcast(
            sync: true,
          );
          addTearDown(() {
            if (!phases.isClosed) return phases.close();
          });
          final pending = Completer<Result<void>>();
          addTearDown(() {
            if (!pending.isCompleted) pending.complete(const Success(null));
          });
          bool Function()? allowed;
          await tester.pumpWidget(
            MaterialApp(
              home: CardTableScreen(
                system: system,
                employeeId: '7',
                stationId: '9',
                events: events.stream,
                connectionPhase: ConnectionPhase.online,
                connectionPhases: phases.stream,
                onListSoldOutProducts: () async => Success([
                  SoldOutItem.fromWire({'id': 101, 'n': '估清商品A', 'c': 0}),
                ]),
                onSetSoldOutProduct: ({
                  required String productId,
                  required int count,
                  bool Function()? canDispatch,
                }) async => const Success(null),
                onDeleteSoldOutProduct: (id, {bool Function()? canDispatch}) {
                  allowed = canDispatch;
                  return pending.future;
                },
              ),
            ),
          );
          final data = fixture.full(fixture.business());
          data[54] = [
            [1, 0],
          ];
          data[41] = [
            [9, 5, 1],
          ];
          events.add(fixture.event(data));
          await tester.pumpAndSettle();
          tester
              .widget<PopupMenuButton<String>>(
                find.byKey(CardTableScreen.moreFunctionsKey),
              )
              .onSelected!('估清商品');
          await tester.pumpAndSettle();
          await tester.tap(find.text('删除'));
          await tester.pump();
          expect(allowed?.call(), isTrue);
          switch (change) {
            case 'permission':
              events.add(
                fixture.event(
                  system == BusinessSystem.order
                      ? {
                          '41': [
                            [9, 5, 0],
                          ],
                        }
                      : {
                          '54': [
                            [1, 1],
                          ],
                        },
                ),
              );
            case 'phaseError':
              phases.addError(StateError('test'));
            case 'phaseDone':
              unawaited(phases.close());
            case 'dataError':
              events.addError(StateError('test'));
            case 'dataDone':
              unawaited(events.close());
            case 'back':
              Navigator.of(tester.element(find.byType(SoldOutProductsScreen)))
                  .pop();
          }
          await tester.pump();
          expect(allowed?.call(), isFalse);
          if (!events.isClosed) events.add(fixture.event(data));
          await tester.pump();
          expect(allowed?.call(), isFalse);
          pending.complete(const Success(null));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
        },
      );
    }
  }
}
