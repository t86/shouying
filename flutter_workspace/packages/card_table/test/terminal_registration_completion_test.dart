import 'package:card_table/src/terminal_register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'super_admin_entry_safety_test.dart' show EntryLoader;

void main() {
  testWidgets('native code loads and completion retry never registers twice', (
    tester,
  ) async {
    final loader = EntryLoader();
    var completions = 0, success = 0;
    final observations = <(String, int, bool)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: TerminalRegisterScreen(
          loader: loader,
          loadMachineCode: () async => const Success('native-machine'),
          completeRegistration: (result, code, current) async {
            observations.add((code, result.authMode, current()));
            completions++;
            return completions == 1
                ? const FailureResult(
                    AppFailure(
                      kind: FailureKind.network,
                      code: 'failed',
                      safeMessage: '暂不可用',
                    ),
                  )
                : const Success(null);
          },
          onRegisterSuccess: (_) => success++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    tester.widget<TextField>(find.byType(TextField)).onSubmitted!('');
    await tester.pumpAndSettle();
    expect(loader.registrations, 1);
    expect(success, 0);
    expect(find.text('重试终端授权'), findsOneWidget);
    final retry = find.widgetWithText(FilledButton, '重试终端授权');
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(retry).onPressed, isNotNull);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(loader.registrations, 1);
    expect(
      completions,
      2,
      reason: tester
          .widget<TextField>(find.byType(TextField))
          .decoration
          ?.errorText,
    );
    expect(success, 1);
    expect(observations, [
      ('native-machine', 8, true),
      ('native-machine', 8, true),
    ]);
  });
}
