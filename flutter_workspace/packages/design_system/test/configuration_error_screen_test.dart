import 'package:design_system/src/configuration_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('configuration failure is visible without raw values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ConfigurationErrorScreen(
          missingKeys: <String>['SHOUYIN_API_BASE', 'SHOUYIN_WS_BASE'],
        ),
      ),
    );

    expect(find.text('应用配置不可用'), findsOneWidget);
    expect(find.textContaining('SHOUYIN_API_BASE'), findsOneWidget);
    expect(find.textContaining('SHOUYIN_WS_BASE'), findsOneWidget);
    expect(find.textContaining('http'), findsNothing);
  });
}
