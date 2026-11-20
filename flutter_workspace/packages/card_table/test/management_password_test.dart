import 'management_permission_fixture.dart';

import 'dart:async';

import 'package:card_table/src/account_password_screen.dart';
import 'package:card_table/src/bms_nav_screen.dart';
import 'package:card_table/src/erp_nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

import 'bms_nav_screen_test.dart' show FakeBmsLoader;
import 'erp_nav_screen_test.dart' show FakeErpLoader;

Future<void> fill(WidgetTester tester) async {
  await tester.enterText(find.byKey(ChangePasswordScreen.oldKey), '123456');
  await tester.enterText(find.byKey(ChangePasswordScreen.newKey), '654321');
  await tester.enterText(find.byKey(ChangePasswordScreen.confirmKey), '654321');
  await tester.pump();
}

void main() {
  for (final bms in [true, false]) {
    testWidgets(
      '${bms ? 'BMS' : 'ERP'} changes password and stays logged in like ManagementSystem.vue',
      (tester) async {
        tester.view.resetPhysicalSize();
        tester.view.physicalSize = const Size(1400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var changed = 0, exited = 0, calls = 0;
        Future<Result<void>> submit(String old, String next) async {
          calls++;
          expect(old, '123456');
          expect(next, '654321');
          return const Success(null);
        }

        final screen = bms
            ? BmsNavScreen(
                permissions: managementTestPermissions(),
                safeModeEnabled: false,
                loader: FakeBmsLoader(),
                onChangePassword: submit,
                onPasswordChanged: () => changed++,
                onBack: () => exited++,
              )
            : ErpNavScreen(
                permissions: managementTestPermissions(),
                safeModeEnabled: false,
                loader: FakeErpLoader(),
                onChangePassword: submit,
                onPasswordChanged: () => changed++,
                onBack: () => exited++,
              );
        await tester.pumpWidget(MaterialApp(home: screen));
        await tester.pumpAndSettle();
        if (bms) {
          await tester.tap(find.byType(PopupMenuButton<String>));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('修改密码'));
        await tester.pumpAndSettle();
        await fill(tester);
        await tester.tap(find.widgetWithText(FilledButton, '确认'));
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(changed, 1);
        expect(exited, 0);
        expect(find.byType(ChangePasswordScreen), findsNothing);
        if (bms) {
          await tester.tap(find.byType(PopupMenuButton<String>));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('修改密码'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(find.byKey(ChangePasswordScreen.oldKey))
              .controller!
              .text,
          isEmpty,
        );
        expect(
          tester
              .widget<TextField>(find.byKey(ChangePasswordScreen.newKey))
              .obscureText,
          isTrue,
        );
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        expect(calls, 1);
      },
    );
  }
  testWidgets('unexpected submit exception is safe and retryable', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          submit: (_, _) async {
            calls++;
            throw StateError('private-credential');
          },
        ),
      ),
    );
    await fill(tester);
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(find.text('密码修改失败，请重试'), findsOneWidget);
    expect(find.textContaining('private-credential'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
  testWidgets('password success callback cannot pop newly opened login route', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: Text('home')),
      ),
    );
    unawaited(
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => ChangePasswordScreen(
            submit: (_, _) async => const Success(null),
            onChanged: () {
              unawaited(
                nav.currentState!.push(
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('new login')),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await fill(tester);
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('new login'), findsOneWidget);
  });
  testWidgets(
    'late password completion cannot close a newer route or run success callback',
    (tester) async {
      final nav = GlobalKey<NavigatorState>();
      final pending = Completer<Result<void>>();
      var changed = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: ChangePasswordScreen(
            submit: (_, _) => pending.future,
            requiresRelogin: false,
            onChanged: () => changed++,
          ),
        ),
      );
      await fill(tester);
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认'))
            .onPressed,
        isNull,
      );
      unawaited(
        nav.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('new login')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      pending.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('new login'), findsOneWidget);
      expect(changed, 0);
    },
  );
}
