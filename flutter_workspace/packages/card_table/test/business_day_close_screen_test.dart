import 'dart:async';

import 'package:card_table/src/business_day_close_screen.dart';
import 'package:card_table/src/business_day_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:card_table/src/card_table_screen.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'card_amount_metadata_test.dart' as fixture show full, business, event;

void main() {
  testWidgets(
    'uncertain close result cannot submit a second close on the same page',
    (tester) async {
      var writes = 0;
      var logouts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BusinessDayCloseScreen(
            automatic: false,
            closeDay: () async {
              writes++;
              return const FailureResult(
                AppFailure(
                  kind: FailureKind.network,
                  code: 'timeout',
                  safeMessage: '超时',
                ),
              );
            },
            onClosed: () async {
              logouts++;
            },
          ),
        ),
      );
      await tester.tap(find.text('结束营业日'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('结束营业日'));
      await tester.pumpAndSettle();
      if (find.text('确定').evaluate().isNotEmpty) {
        await tester.tap(find.text('确定'));
        await tester.pumpAndSettle();
      }
      expect(writes, 1);
      expect(logouts, 0);
      expect(find.textContaining('结果尚未确认'), findsWidgets);
    },
  );
  testWidgets('disposed old session ignores late successful close', (
    tester,
  ) async {
    final pending = Completer<Result<void>>();
    var logouts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BusinessDayCloseScreen(
          automatic: false,
          closeDay: () => pending.future,
          onClosed: () async {
            logouts++;
          },
        ),
      ),
    );
    await tester.tap(find.text('结束营业日'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('新会话'))),
    );
    pending.complete(const Success(null));
    await tester.pumpAndSettle();
    expect(logouts, 0);
    expect(find.text('新会话'), findsOneWidget);
  });
  for (final succeeds in [true, false]) {
    testWidgets('Card close success=$succeeds logs out only on success', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      var logouts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            employeeId: '7',
            stationId: '9',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onLogout: () async {
              logouts++;
              return const Success(null);
            },
            onCloseBusinessDay: () async {
              if (!succeeds)
                return const FailureResult(
                  AppFailure(
                    kind: FailureKind.business,
                    code: 'rejected',
                    safeMessage: '拒绝',
                  ),
                );
              events.add(
                fixture.event({
                  '18': [
                    [0, '', '测试门店'],
                  ],
                }),
              );
              return const Success(null);
            },
          ),
        ),
      );
      events.add(fixture.event(fixture.full(fixture.business())));
      await tester.pumpAndSettle();
      tester
          .widget<PopupMenuButton<String>>(
            find.byKey(CardTableScreen.moreFunctionsKey),
          )
          .onSelected!('结束营业日');
      await tester.pumpAndSettle();
      await tester.tap(find.text('结束营业日'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(logouts, succeeds ? 1 : 0);
      expect(
        find.byType(BusinessDayCloseScreen),
        succeeds ? findsNothing : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final change in ['day', 'connection', 'safe-mode']) {
    testWidgets('Card invalidates pending confirmation on $change change', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      final phases = StreamController<ConnectionPhase>.broadcast(sync: true);
      addTearDown(events.close);
      addTearDown(phases.close);
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            employeeId: '7',
            stationId: '9',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            connectionPhases: phases.stream,
            onCloseBusinessDay: () async {
              writes++;
              return const Success(null);
            },
          ),
        ),
      );
      final data = fixture.full(fixture.business());
      data[54] = [
        [1, 0],
      ];
      events.add(fixture.event(data));
      await tester.pumpAndSettle();
      tester
          .widget<PopupMenuButton<String>>(
            find.byKey(CardTableScreen.moreFunctionsKey),
          )
          .onSelected!('结束营业日');
      await tester.pumpAndSettle();
      await tester.tap(find.text('结束营业日'));
      await tester.pumpAndSettle();
      if (change == 'day') {
        events.add(
          fixture.event({
            '18': [
              [2, '', '测试门店'],
            ],
          }),
        );
      } else if (change == 'safe-mode') {
        events.add(fixture.event({'54': [[1, 1]]}));
      } else {
        phases.add(ConnectionPhase.blocked);
        phases.add(ConnectionPhase.online);
      }
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.text('连接、会话或营业日已变化，请返回重新打开'), findsOneWidget);
    });
  }
  testWidgets(
    'confirmation expires permanently after a day or connection change',
    (tester) async {
      final access = ValueNotifier(true);
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BusinessDayCloseScreen(
            automatic: false,
            canOperate: access,
            closeDay: () async {
              writes++;
              return const Success(null);
            },
          ),
        ),
      );
      await tester.tap(find.text('结束营业日'));
      await tester.pumpAndSettle();
      access.value = false;
      access.value = true;
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.text('连接、会话或营业日已变化，请返回重新打开'), findsOneWidget);
    },
  );

  testWidgets('failed configuration load blocks save and can retry', (
    tester,
  ) async {
    var loads = 0;
    var writes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BusinessDayCloseScreen(
          automatic: true,
          loadAutoClose: () async {
            loads++;
            if (loads == 1)
              return const FailureResult(
                AppFailure(
                  kind: FailureKind.network,
                  code: 'test',
                  safeMessage: '读取失败',
                ),
              );
            return const Success(
              AutoCloseConfig(enabled: true, hour: 4, minute: 15),
            );
          },
          saveAutoClose:
              ({required enabled, required hour, required minute}) async {
                expect(enabled, true);
                expect(hour, 4);
                expect(minute, 15);
                writes++;
                return const Success(null);
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    expect(writes, 0);
    await tester.tap(find.text('重新读取配置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(writes, 1);
  });

  testWidgets('successful close logs out but removes only its original route', (
    tester,
  ) async {
    final pending = Completer<Result<void>>();
    var logouts = 0;
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('首页')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => BusinessDayCloseScreen(
          automatic: false,
          closeDay: () => pending.future,
          onClosed: () async {
            logouts++;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('结束营业日'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('新页面')),
      ),
    );
    await tester.pumpAndSettle();
    pending.complete(const Success(null));
    await tester.pumpAndSettle();
    expect(find.text('新页面'), findsOneWidget);
    expect(logouts, 1);
  });

  testWidgets('configuration cannot save before its load completes', (
    tester,
  ) async {
    final pending = Completer<Result<AutoCloseConfig>>();
    var writes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BusinessDayCloseScreen(
          automatic: true,
          loadAutoClose: () => pending.future,
          saveAutoClose:
              ({required enabled, required hour, required minute}) async {
                writes++;
                return const Success(null);
              },
        ),
      ),
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    expect(writes, 0);
    pending.complete(
      const Success(AutoCloseConfig(enabled: true, hour: 5, minute: 10)),
    );
    await tester.pumpAndSettle();
  });
}
