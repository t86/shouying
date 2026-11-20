import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realtime_sync/realtime_sync.dart';

void main() {
  group('QueueBigScreen Tests', () {
    testWidgets('renders empty state when queue types are empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final fixedTime = DateTime(2026, 9, 15, 14, 30);
      var backCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: QueueBigScreen(
            nowProvider: () => fixedTime,
            onBack: () => backCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header store name fallback
      expect(find.text('叫号大屏'), findsOneWidget);
      // Check date
      expect(find.text('2026-09-15 星期二 14:30'), findsOneWidget);
      // Check empty state
      expect(find.text('暂无数据'), findsOneWidget);

      // Check back button
      await tester.tap(find.byKey(const Key('queue-big-screen-back')));
      expect(backCalled, isTrue);
    });

    testWidgets('renders 5 columns with formatted queue data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final snapshot = CardTableSnapshot(
        cursor: 'c1',
        businessDayId: '20260915',
        storeName: '测试旗舰店',
        regions: const [],
        tables: const [],
        businessDates: const [],
        queue: const CardTableQueueSnapshot(
          config: QueueConfig(numberType: 2), // pad 2 digits
          types: [
            QueueType(
              id: 1,
              status: 1,
              name: '小桌 (1-4人)',
              numPrefix: 'A',
            ),
            QueueType(
              id: 2,
              status: 1,
              name: '大桌 (5-10人)',
              numPrefix: 'B',
            ),
          ],
          curNumbers: [
            QueueCurNumber(
              wkdayId: '20260915',
              queueTypeId: 1,
              lastGenNum: 5,
              currNo: 2,
              currNoStatus: 1,
              waitCnt: 3,
              waitNo: 3,
            ),
            QueueCurNumber(
              wkdayId: '20260915',
              queueTypeId: 2,
              lastGenNum: 0,
              currNo: 0,
              currNoStatus: 0,
              waitCnt: 0,
              waitNo: 0,
            ),
          ],
        ),
      );

      final fixedTime = DateTime(2026, 9, 15, 15, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: QueueBigScreen(
            initialSnapshot: snapshot,
            nowProvider: () => fixedTime,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Store name
      expect(find.text('测试旗舰店'), findsOneWidget);
      expect(find.text('2026-09-15 星期二 15:00'), findsOneWidget);

      // Table headers
      expect(find.text('类型'), findsOneWidget);
      expect(find.text('当前叫号'), findsOneWidget);
      expect(find.text('当前取号'), findsOneWidget);
      expect(find.text('等待叫号'), findsOneWidget);
      expect(find.text('等待桌数'), findsOneWidget);

      // Row 1 (A02, A05, A03, 3)
      expect(find.text('小桌 (1-4人)'), findsOneWidget);
      expect(find.text('A02'), findsOneWidget);
      expect(find.text('A05'), findsOneWidget);
      expect(find.text('A03'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Row 2 (B - all zeros become '-')
      expect(find.text('大桌 (5-10人)'), findsOneWidget);
      expect(find.text('0'), findsOneWidget); // waitCnt is 0
    });

    testWidgets('updates live when realtime SyncEnvelope arrives', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final eventController = StreamController<SyncEnvelope>.broadcast();
      addTearDown(eventController.close);

      await tester.pumpWidget(
        MaterialApp(
          home: QueueBigScreen(
            events: eventController.stream,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('暂无数据'), findsOneWidget);

      // Emit SyncEnvelope containing queue tables
      final data = List<Object?>.filled(57, const <Object?>[]);
      data[0] = <Object?>[
        <Object?>[1, '大厅', 1, 1],
      ];
      data[1] = <Object?>[
        <Object?>[100, 'A01', 1, 1, 3, 1, 4, 1],
      ];
      data[18] = <Object?>[
        <Object?>[9, '20260915', '实时门店A'],
      ];
      data[46] = <Object?>[1, 1, 1, '', 1]; // numberType: 1
      data[47] = <Object?>[
        <Object?>[10, 1, '包厢排队', 'V', 1, 10, 0],
      ];
      data[49] = <Object?>[
        <Object?>['20260915', 10, 8, 6, 1, 2, 7],
      ];

      eventController.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260915010101',
          data: data,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('包厢排队'), findsOneWidget);
      expect(find.text('V6'), findsOneWidget); // currNo
      expect(find.text('V8'), findsOneWidget); // lastGenNum
      expect(find.text('V7'), findsOneWidget); // waitNo
      expect(find.text('2'), findsOneWidget);  // waitCnt
    });

    testWidgets('toggles fullscreen button and icon', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: QueueBigScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final fsBtn = find.byKey(const Key('queue-big-screen-fullscreen'));
      expect(fsBtn, findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      // Tap fullscreen
      await tester.tap(fsBtn);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);

      // Tap exit fullscreen
      await tester.tap(fsBtn);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });
  });
}
