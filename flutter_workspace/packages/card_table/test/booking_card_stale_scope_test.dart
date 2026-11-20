import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

void main() {
  testWidgets('booking write cannot dispatch after its owner is covered', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    final pending = Completer<Result<void>>();
    bool Function()? dispatchGuard;
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.booking,
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
          onBookingCardWrite:
              ({
                required BookingCardWriteAction action,
                required String seatId,
                String bookId = '',
                Map<String, Object?> fields = const {},
                bool Function()? canDispatch,
              }) {
                dispatchGuard = canDispatch;
                return pending.future;
              },
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _snapshot(1),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(CardTableScreen.cardMenuKey),
        matching: find.text('锁定'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(dispatchGuard, isNotNull);
    expect(dispatchGuard!(), isTrue);
    unawaited(
      Navigator.of(tester.element(find.byType(CardTableScreen))).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('另一业务页面')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final allowedWhileCovered = dispatchGuard!();
    pending.complete(const Success(null));
    await tester.pumpAndSettle();
    expect(allowedWhileCovered, isFalse);
    expect(find.text('操作成功！'), findsNothing);
  });

  for (final change in ['status', 'round-trip', 'disconnect', 'amount-only']) {
    testWidgets('owned booking lock confirmation scope: $change', (
      tester,
    ) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final phases = StreamController<ConnectionPhase>.broadcast(sync: true);
      addTearDown(phases.close);
      final observer = BusinessRouteObserver();
      final writes = <BookingCardWriteAction>[];
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: CardTableScreen(
            system: BusinessSystem.booking,
            businessRouteObserver: observer,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            connectionPhases: phases.stream,
            onBookingCardWrite:
                ({
                  required BookingCardWriteAction action,
                  required String seatId,
                  String bookId = '',
                  Map<String, Object?> fields = const {},
                  bool Function()? canDispatch,
                }) async {
                  expect(seatId, '101');
                  expect(canDispatch?.call(), isTrue);
                  writes.add(action);
                  return const Success(null);
                },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _snapshot(1),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(CardTableScreen.cardMenuKey),
          matching: find.text('锁定'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('锁定卡台'), findsOneWidget);

      // The registered business owner stays alive. The same seat is now locked
      // by a new snapshot, so the previously authorized action is obsolete.
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010102',
          data: _snapshot(change == 'status' || change == 'round-trip' ? 2 : 1),
        ),
      );
      if (change == 'round-trip') {
        events.add(
          SyncEnvelope.fromValidatedReconciliation(
            cursor: '20260828010103',
            data: _snapshot(1),
          ),
        );
      }
      if (change == 'disconnect') {
        phases.add(ConnectionPhase.reconciling);
        phases.add(ConnectionPhase.online);
      }
      if (change == 'amount-only') {
        final price = _snapshot(1);
        ((price[14] as List).first as List)[6] = 99;
        events.add(
          SyncEnvelope.fromValidatedReconciliation(
            cursor: '20260828010103',
            data: price,
          ),
        );
      }
      await tester.pumpAndSettle();
      final confirm = find.widgetWithText(FilledButton, '确定');
      if (confirm.evaluate().isNotEmpty) {
        await tester.tap(confirm);
        await tester.pumpAndSettle();
      }
      expect(
        writes,
        change == 'amount-only' ? [BookingCardWriteAction.lock] : isEmpty,
        reason: 'The old confirmation must close or reject its stale seat snapshot even with BusinessRouteObserver attached.',
      );
    });
  }

  for (final change in ['generation', 'page', 'stable']) {
    test('booking loader checks $change during credential read', () async {
      final sessionAdapter = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(sessionAdapter).client),
        credentialStore: Credentials(),
      );
      await loginSession(session, sessionAdapter, 2);
      final adapter = Adapter();
      final credentials = _DelayedCredentials();
      final client = ProtocolClient(
        dio: Dio()..httpClientAdapter = adapter,
        config: ApiConfig(
          apiBase: Uri.parse('https://example.test/server'),
          onlineBase: Uri.parse('https://example.test/server'),
          websocketBase: Uri.parse('wss://example.test/server'),
        ),
        credentialStore: credentials,
        requestGate: RequestGate(clock: DateTime.now),
      );
      var generation = 1;
      var permitted = true;
      final loader = SessionBoundBookingCardLoader(
        session: session,
        api: ProtocolBookingCardApi(client: client),
        phase: () => ConnectionPhase.online,
        generation: () => generation,
      );
      final pending = loader.write(
        action: BookingCardWriteAction.lock,
        seatId: '101',
        canDispatch: () => permitted,
      );
      await credentials.started.future;
      expect(adapter.requests, isEmpty);
      if (change == 'generation') generation++;
      if (change == 'page') permitted = false;
      credentials.snapshot.complete(
        const CredentialSnapshot(tk: 'synthetic-tk', stk: null),
      );
      final result = await pending;
      expect(result.failureOrNull, change == 'stable' ? isNull : isNotNull);
      expect(
        adapter.requests,
        change == 'stable' ? hasLength(1) : isEmpty,
        reason: 'Returning session.changed after the HTTP request is too late to prevent a booking write.',
      );
    });
  }
}

class _DelayedCredentials extends Credentials {
  final started = Completer<void>();
  final snapshot = Completer<CredentialSnapshot>();
  @override
  Future<CredentialSnapshot> readSnapshot() {
    if (!started.isCompleted) started.complete();
    return snapshot.future;
  }
}

List<Object?> _snapshot(int status) {
  final data = List<Object?>.filled(57, const <Object?>[]);
  data[0] = [
    [1, '大厅', 1, 10, 0, 0, 0],
  ];
  data[1] = [
    [101, 'A02', 1, 1, 3, 1, 4, 2],
  ];
  final row = List<Object?>.filled(38, null);
  row[0] = 101;
  row[2] = '20260828120000';
  row[5] = '20260828123000';
  for (final index in [6, 7, 8, 9, 10, 11, 12]) {
    row[index] = 0;
  }
  row[13] = 1;
  row[16] = '';
  row[17] = '';
  row[18] = 0;
  row[19] = status;
  for (final index in [20, 24, 25]) {
    row[index] = '';
  }
  data[14] = [row];
  data[18] = [
    [9, '', '测试门店'],
  ];
  data[24] = [
    ['今天', '20260828'],
  ];
  data[39] = [
    [1, 0, 2],
    [3, 0, 2],
    [4, 0, 1],
    [20, 0, 1],
    [1, 1, 1],
    [4, 1, 1],
    [20, 1, 1],
    [1, 2, 1],
  ];
  data[41] = [
    [9, 5, 1],
    [9, 1, 1],
    [9, 91, 1],
  ];
  return data;
}
