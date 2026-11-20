import 'dart:async';

import 'package:card_table/src/card_table_screen.dart';
import 'package:card_table/src/fc_price.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';
import 'package:card_table/src/legacy_card_table_store.dart';
import 'package:card_table/src/order_meal_screen.dart';
import 'package:card_table/src/order_set_dialog.dart';
import 'package:card_table/src/order_set_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'live_order_operation_scope_test.dart' as fixture show full, event;

List<Object?> pricingData({bool member = false, int type = 1}) {
  final data = fixture.full();
  (data[1] as List).first[4] = 4;
  final business = (data[14] as List).first as List;
  business[14] = 7;
  business[35] = member ? '13800000000' : '';
  data[2] = [
    [1, '分类', 1, 0],
  ];
  data[3] = [
    [1, '分类二', 1, 0, 1],
  ];
  data[4] = [
    [
      101,
      '饮品',
      1,
      0,
      '',
      '',
      1,
      1,
      '100.00',
      type,
      ...List<Object?>.filled(8, null),
      '90',
      '80',
      '70',
      '60',
      '50',
      '40',
      '30',
    ],
  ];
  data[16] = [
    [1, 1, 101],
  ];
  data[57] = [
    [7, 1],
  ];
  data[9] = type == 2
      ? [
          [101, 1, 1, 1, 101, 1, 0, 1],
        ]
      : [];
  return data;
}

void main() {
  testWidgets(
    'FC original tracks live base price, not contextual business tier',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = LegacyCardTableStore();
      final data = pricingData();
      data[58] = [
        [101, 1, 2000, 1],
      ];
      data[59] = [
        [1, 7, 1],
      ];
      store.applyEnvelope(fixture.event(data));
      final changes = ValueNotifier(0);
      addTearDown(changes.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: OrderMealScreen(
            table: store.currentSnapshot!.tables.single,
            catalog: store.catalogForRegion('1'),
            employeeId: '7',
            fcPriceCatalog: store.fcPriceCatalog,
            productQuoteFor: (id) => store.productQuoteFor('100', id),
            productPricingChanges: changes,
            operationContext: const AlwaysStoppedAnimation<Object?>(true),
            addProduct: ({
              required seatId,
              required productId,
              required count,
              required price,
              String amount = '',
            }) async => const Success(null),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('原价：￥100.00'), findsOneWidget);
      final goods = (data[4] as List).first as List;
      goods[8] = '120';
      goods[23] = '45';
      store.applyEnvelope(
        fixture.event({
          '4': [goods],
        }),
      );
      changes.value++;
      await tester.pump();
      expect(find.text('原价：￥120.00'), findsOneWidget);
      expect(find.text('原价：￥45.00'), findsNothing);
      expect(find.text('方案价：￥20.00'), findsOneWidget);
    },
  );
  testWidgets(
    'Card route forwards live employee pricing and rejects a bad pricing update',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final sent = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            stationId: '9',
            employeeId: '7',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onAddOrderProduct:
                ({
                  required seatId,
                  required productId,
                  required count,
                  required price,
                  String amount = '',
                }) async {
                  sent.add(price);
                  return const Success(null);
                },
          ),
        ),
      );
      final data = pricingData();
      data[13] = [
        [9, 11, 1],
      ];
      data[56] = [
        [9, 1, 1],
      ];
      events.add(fixture.event(data));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      expect(find.byType(OrderMealScreen), findsOneWidget);
      events.add(
        fixture.event({
          '57': [
            [7, 0],
          ],
        }),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('饮品'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(sent, ['60']);
      events.add(
        fixture.event({
          '57': [
            [7],
          ],
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('价格待同步'), findsOneWidget);
      await tester.tap(find.text('饮品'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(sent, ['60']);
    },
  );
  test('store quotes track current business membership, employee eligibility and tiers', () {
    final store = LegacyCardTableStore();
    final data = pricingData();
    store.applyEnvelope(fixture.event(data));
    expect(store.productQuoteFor('100', '101')?.actualPrice, '40');
    final business = (data[14] as List).first as List;
    business[35] = '13800000000';
    store.applyEnvelope(
      fixture.event({
        '14': [business],
      }),
    );
    expect(store.productQuoteFor('100', '101')?.actualPrice, '30');
    store.applyEnvelope(
      fixture.event({
        '57': [
          [7, 0],
        ],
      }),
    );
    expect(store.productQuoteFor('100', '101')?.actualPrice, '50');
    final goods = (data[4] as List).first as List;
    goods[22] = '45';
    store.applyEnvelope(
      fixture.event({
        '4': [goods],
      }),
    );
    expect(store.productQuoteFor('100', '101')?.actualPrice, '45');
    store.applyEnvelope(
      fixture.event({
        '57': [
          [7],
        ],
      }),
    );
    expect(store.productQuoteFor('100', '101'), isNull);
    store.applyEnvelope(
      fixture.event({
        '57': [
          [7, 1],
        ],
      }),
    );
    expect(store.productQuoteFor('100', '101'), isNull);
    store.applyEnvelope(fixture.event(data));
    expect(store.productQuoteFor('100', '101')?.actualPrice, '30');
  });
  for (final type in [1, 2]) {
    testWidgets(
      'live tier updates reach ${type == 2 ? 'package' : 'regular'} request instead of member hint',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = LegacyCardTableStore();
        final data = pricingData(type: type);
        store.applyEnvelope(fixture.event(data));
        final changes = ValueNotifier(0);
        addTearDown(changes.dispose);
        final sent = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: OrderMealScreen(
              table: store.currentSnapshot!.tables.single,
              catalog: store.catalogForRegion('1'),
              fcPriceCatalog: type == 2
                  ? FcPriceCatalog.unknown
                  : store.fcPriceCatalog,
              operationContext: const AlwaysStoppedAnimation<Object?>(true),
              productQuoteFor: (id) => store.productQuoteFor('100', id),
              productPricingChanges: changes,
              currentSetCatalog: () => store.orderSetCatalog,
              addProduct:
                  ({
                    required seatId,
                    required productId,
                    required count,
                    required price,
                    String amount = '',
                  }) async {
                    sent.add(price);
                    return const Success(null);
                  },
              addSet:
                  ({
                    required seatId,
                    required productId,
                    required count,
                    required priceFen,
                    required groupIds,
                    required detailProductIds,
                    required detailCounts,
                    required selectCounts,
                    List<String> requirements = const [],
                  }) async {
                    sent.add('$priceFen');
                    return const Success(null);
                  },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('饮品'));
        await tester.pumpAndSettle();
        // The quote is re-evaluated after the modal opens; never use its stale product object.
        final goods = (data[4] as List).first as List;
        goods[23] = '42';
        store.applyEnvelope(
          fixture.event({
            '4': [goods],
          }),
        );
        changes.value++;
        await tester.pump();
        if (type == 1) {
          await tester.tap(find.widgetWithText(FilledButton, '确认'));
        } else {
          final dialog = tester.widget<OrderSetDialog>(
            find.byType(OrderSetDialog),
          );
          final d = dialog.configuration.details.single;
          expect(
            (await dialog.submit(
              OrderSetSelection(
                productId: '101',
                candidates: [d],
                choices: [OrderSetChoice(detail: d, selectCount: 1)],
              ),
              '',
              '',
              1,
              () => true,
            )).failureOrNull,
            isNull,
          );
        }
        await tester.pumpAndSettle();
        expect(sent, [type == 2 ? '4200' : '42']);
      },
    );
  }
}
