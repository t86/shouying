import 'package:design_system/src/diagnostic_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  Widget subject({
    required double width,
    ConnectionPhase phase = ConnectionPhase.online,
    AppFailure? failure,
    VoidCallback? onWriteCommand,
  }) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        child: DiagnosticPanel(
          appVersion: '1.2.3+4',
          platformLabel: 'Windows',
          phase: phase,
          machineId: 'machine-7',
          machineName: '前台终端',
          userId: 'employee-8',
          userName: '测试员工',
          apiBase: Uri.parse('https://user:pass@example.test/api?q=tk-secret'),
          onlineBase: Uri.parse('https://online.example.test/v1#token'),
          websocketBase: Uri.parse('wss://socket.example.test/sync?stk=secret'),
          lastFailure: failure,
          onWriteCommand: onWriteCommand,
        ),
      ),
    ),
  );

  testWidgets('shows only safe operational diagnostics', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    const secret = 'super-secret-token';
    await tester.pumpWidget(
      subject(
        width: 1000,
        failure: const AppFailure(
          kind: FailureKind.unknown,
          code: 'tk=$secret',
          safeMessage: 'password=$secret 请求体 $secret',
        ),
      ),
    );

    expect(find.text('1.2.3+4'), findsOneWidget);
    expect(find.text('Windows'), findsOneWidget);
    expect(find.text('machine-7'), findsOneWidget);
    expect(find.text('前台终端'), findsOneWidget);
    expect(find.text('employee-8'), findsOneWidget);
    expect(find.text('测试员工'), findsOneWidget);
    expect(find.text('https://example.test/api'), findsOneWidget);
    final selectableText = tester
        .widgetList<SelectableText>(find.byType(SelectableText))
        .map((widget) => widget.data ?? '')
        .toList();
    expect(
      selectableText,
      contains(
        predicate<String>(
          (value) =>
              value.contains('online.example.test') && value.endsWith('/v1'),
        ),
      ),
    );
    expect(
      selectableText,
      contains(
        predicate<String>(
          (value) =>
              value.contains('socket.example.test') && value.endsWith('/sync'),
        ),
      ),
    );

    final allText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .followedBy(selectableText)
        .join('\n');
    expect(allText, isNot(contains(secret)));
    expect(allText, isNot(contains('user:pass')));
    expect(allText, isNot(contains('?')));
    expect(allText, isNot(contains('请求体')));
  });

  testWidgets('wide constraints select two-column layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    await tester.pumpWidget(subject(width: 900));

    expect(find.byKey(DiagnosticPanel.wideLayoutKey), findsOneWidget);
    expect(find.byKey(DiagnosticPanel.narrowLayoutKey), findsNothing);
  });

  testWidgets('narrow constraints select one-column layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    await tester.pumpWidget(subject(width: 899));

    expect(find.byKey(DiagnosticPanel.narrowLayoutKey), findsOneWidget);
    expect(find.byKey(DiagnosticPanel.wideLayoutKey), findsNothing);
  });

  testWidgets('write command is disabled while blocked or reconciling', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    for (final phase in <ConnectionPhase>[
      ConnectionPhase.blocked,
      ConnectionPhase.reconciling,
    ]) {
      var calls = 0;
      await tester.pumpWidget(
        subject(width: 500, phase: phase, onWriteCommand: () => calls += 1),
      );

      final button = tester.widget<FilledButton>(
        find.byKey(DiagnosticPanel.writeCommandKey),
      );
      expect(button.onPressed, isNull);
      await tester.tap(find.byKey(DiagnosticPanel.writeCommandKey));
      expect(calls, 0);
    }
  });

  testWidgets('write command is enabled only while online', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    var calls = 0;
    await tester.pumpWidget(
      subject(width: 500, onWriteCommand: () => calls += 1),
    );

    await tester.tap(find.byKey(DiagnosticPanel.writeCommandKey));
    expect(calls, 1);
  });
}
