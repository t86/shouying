import 'package:design_system/src/connection_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  Widget subject(ConnectionPhase phase) => MaterialApp(
    home: Scaffold(body: ConnectionBanner(phase: phase)),
  );

  testWidgets('online banner is hidden', (tester) async {
    await tester.pumpWidget(subject(ConnectionPhase.online));

    expect(find.byType(ConnectionBanner), findsOneWidget);
    expect(find.text('连接已恢复'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(ConnectionBanner),
        matching: find.byType(Semantics),
      ),
      findsNothing,
    );
  });

  testWidgets('blocked banner is persistent red and accessible', (
    tester,
  ) async {
    await tester.pumpWidget(subject(ConnectionPhase.blocked));

    expect(find.text('服务连接不可用，写入操作已暂停'), findsOneWidget);
    final container = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(ConnectionBanner),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(container.color, const Color(0xFFB3261E));
    expect(
      tester.getSemantics(find.byType(ConnectionBanner)),
      isSemantics(label: '服务连接不可用，写入操作已暂停'),
    );
  });

  testWidgets('reconciling banner is amber and announces recovery', (
    tester,
  ) async {
    await tester.pumpWidget(subject(ConnectionPhase.reconciling));

    expect(find.text('正在恢复服务端状态'), findsOneWidget);
    final container = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(ConnectionBanner),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(container.color, const Color(0xFFFFB300));
    expect(
      tester.getSemantics(find.byType(ConnectionBanner)),
      isSemantics(label: '正在恢复服务端状态'),
    );
  });
}
