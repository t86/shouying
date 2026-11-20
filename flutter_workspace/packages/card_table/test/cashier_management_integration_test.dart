import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'card_amount_metadata_test.dart' as fixture;
import 'cashier_credit_accounts_screen_test.dart' show CreditLoader;
import 'cashier_merchant_management_screen_test.dart' show MerchantFake;

void main() {
  test('merchant amounts full delta reset and malformed rows fail closed', () {
    final store = CashierMerchantAmounts();
    addTearDown(store.dispose);
    final full = List<Object?>.filled(55, null);
    full[38] = [
      [1, 25000, 10000, 8, 0, 0, 0],
    ];
    store.add(
      fixture.event({
        '38': [
          [1, 99, 0, 8, 0, 0, 0],
        ],
      }),
    );
    expect(store.value, isNull);
    store.add(fixture.event(full));
    expect(store.value!.single.display, '2.5');
    store.add(
      fixture.event({
        '38': [
          [1, 35000, 11000, 8, 9, 46000, 12000],
        ],
      }),
    );
    expect(store.value!.length, 2);
    expect(store.value!.first.amount, 35000);
    store.add(fixture.event({'14': []}));
    expect(store.value!.first.id, 8);
    store.invalidate();
    store.add(
      fixture.event({
        '38': [
          [1, 5, 0, 8, 0, 0, 0],
        ],
      }),
    );
    expect(store.value, isNull);
    store.add(fixture.event(full));
    store.add(
      fixture.event({
        '38': [
          [1, 'bad', 0, 8, 0, 0, 0],
        ],
      }),
    );
    expect(store.value, isNull);
    full[38] = [];
    store.add(fixture.event(full));
    expect(store.value, isEmpty);
  });
  testWidgets(
    'management loaders are lazy and persist when screens reopen; amount updates preserve config scope',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final credit = CreditLoader(), merchant = MerchantFake();
      var creditFactories = 0, merchantFactories = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            employeeId: '7',
            stationId: '9',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            createCreditAccountsLoader: () {
              creditFactories++;
              return credit;
            },
            createMerchantManagementLoader: () {
              merchantFactories++;
              return merchant;
            },
          ),
        ),
      );
      final data = fixture.full(fixture.business());
      data[54] = [
        [1, 0],
      ];
      data[38] = [
        [1, 25000, 10000, 8, 9, 46000, 20000],
      ];
      events.add(fixture.event(data));
      await tester.pumpAndSettle();
      expect(creditFactories, 0);
      expect(merchantFactories, 0);
      void menu(String label) => tester
          .widget<PopupMenuButton<String>>(
            find.byKey(CardTableScreen.moreFunctionsKey),
          )
          .onSelected!(label);
      menu('挂账账户');
      await tester.pumpAndSettle();
      expect(find.byType(CashierCreditAccountsScreen), findsOneWidget);
      expect(creditFactories, 1);
      credit.needsVerification = true;
      Navigator.of(tester.element(find.byType(CashierCreditAccountsScreen)))
          .pop();
      await tester.pumpAndSettle();
      menu('挂账账户');
      await tester.pumpAndSettle();
      expect(creditFactories, 1);
      expect(credit.needsVerification, true);
      Navigator.of(tester.element(find.byType(CashierCreditAccountsScreen)))
          .pop();
      await tester.pumpAndSettle();
      menu('商户号管理');
      await tester.pumpAndSettle();
      expect(find.byType(CashierMerchantManagementScreen), findsOneWidget);
      expect(merchantFactories, 1);
      final management = tester.widget<CashierMerchantManagementScreen>(
        find.byType(CashierMerchantManagementScreen),
      );
      final edges = <bool>[];
      management.canOperate.addListener(
        () => edges.add(management.canOperate.value),
      );
      events.add(
        fixture.event({
          '38': [
            [1, 35000, 11000, 8, 9, 46000, 20000],
          ],
        }),
      );
      await tester.pumpAndSettle();
      expect(edges, isEmpty);
      expect(management.canOperate.value, true);
      Navigator.of(tester.element(find.byType(CashierMerchantManagementScreen)))
          .pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('3.5'));
      await tester.pumpAndSettle();
      final info = tester.widget<CashierMerchantInformationScreen>(
        find.byType(CashierMerchantInformationScreen),
      );
      expect(info.merchantId, 8);
      expect(info.amount, 35000);
      expect(info.publicAmount, 11000);
      expect(merchantFactories, 1);
    },
  );
  testWidgets(
    'offline and replaced connection streams immediately remove amount labels',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = StreamController<SyncEnvelope>.broadcast(sync: true),
          phases = StreamController<ConnectionPhase>.broadcast(sync: true),
          replacement = StreamController<ConnectionPhase>.broadcast(sync: true);
      addTearDown(events.close);
      addTearDown(phases.close);
      addTearDown(replacement.close);
      Widget app(Stream<ConnectionPhase> stream) => MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.cashier,
          employeeId: '7',
          stationId: '9',
          events: events.stream,
          connectionPhases: stream,
          connectionPhase: ConnectionPhase.online,
        ),
      );
      await tester.pumpWidget(app(phases.stream));
      final data = fixture.full(fixture.business());
      data[54] = [
        [1, 0],
      ];
      data[38] = [
        [1, 25000, 10000, 8, 0, 0, 0],
      ];
      events.add(fixture.event(data));
      await tester.pumpAndSettle();
      expect(find.text('2.5'), findsOneWidget);
      phases.add(ConnectionPhase.blocked);
      await tester.pumpAndSettle();
      expect(find.text('2.5'), findsNothing);
      phases.add(ConnectionPhase.online);
      events.add(fixture.event(data));
      await tester.pumpAndSettle();
      expect(find.text('2.5'), findsOneWidget);
      await tester.pumpWidget(app(replacement.stream));
      await tester.pumpAndSettle();
      expect(find.text('2.5'), findsNothing);
    },
  );
  testWidgets(
    'cashier footer renders both dataset38 merchant amounts without scaling raw state',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            employeeId: '7',
            stationId: '9',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
          ),
        ),
      );
      final data = fixture.full(fixture.business());
      data[54] = [
        [1, 0],
      ];
      data[38] = [
        [1, 25000, 10000, 8, 9, 46000, 20000],
      ];
      events.add(fixture.event(data));
      await tester.pumpAndSettle();
      expect(find.text('2.5'), findsOneWidget);
      expect(find.text('4.6'), findsOneWidget);
    },
  );
}
