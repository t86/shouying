import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'card_amount_metadata_test.dart' as fixture;

void main() {
  testWidgets(
    'cashier opens voucher records and business day changes revoke pending work',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      var loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            employeeId: '7',
            stationId: '9',
            connectionPhase: ConnectionPhase.online,
            events: events.stream,
            onLoadVouchers: (query) async {
              loads++;
              return const Success([]);
            },
            onCancelVoucher: (id, guard) async => const Success(null),
            onExportVouchers: (query, guard) async =>
                const Success('test.xlsx'),
          ),
        ),
      );
      final data = fixture.full(fixture.business());
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
          .onSelected!('当日卡券核销记录表');
      await tester.pumpAndSettle();
      expect(find.byType(CashierVoucherRecordsScreen), findsOneWidget);
      expect(loads, 1);
      final screen = tester.widget<CashierVoucherRecordsScreen>(
        find.byType(CashierVoucherRecordsScreen),
      );
      expect(screen.canOperate.value, true);
      final edges = <bool>[];
      screen.canOperate.addListener(() => edges.add(screen.canOperate.value));
      events.add(
        fixture.event({
          '18': [
            [1, '', '测试门店'],
          ],
        }),
      );
      await tester.pumpAndSettle();
      expect(edges, containsAllInOrder([false, true]));
      expect(loads, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
