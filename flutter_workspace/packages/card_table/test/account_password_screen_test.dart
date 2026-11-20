import 'dart:async';

import 'package:card_table/src/account_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  for (final invalidLogin in [true, false]) {
    testWidgets('Vue rejects NaN in ${invalidLogin ? 'login' : 'auth'} password', (tester) async {
      var writes = 0;
      await tester.pumpWidget(MaterialApp(home: AuthPasswordScreen(
        loadEnabled: () async => const Success(true),
        submit: ({required bool enabled, required String loginPassword, required String authPassword}) async {
          writes++;
          return const Success(null);
        },
      )));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(AuthPasswordScreen.loginKey), invalidLogin ? 'NaN' : '123');
      await tester.enterText(find.byKey(AuthPasswordScreen.authKey), invalidLogin ? '456' : 'NaN');
      await tester.enterText(find.byKey(AuthPasswordScreen.confirmKey), invalidLogin ? '456' : 'NaN');
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(find.text('授权密码必须为数字'), findsOneWidget);
    });
  }
  testWidgets('late auth password completion cannot pop a newer page', (
    tester,
  ) async {
    final completion = Completer<Result<void>>();
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: AuthPasswordScreen(
          loadEnabled: () async => const Success(false),
          submit: ({
            required bool enabled,
            required String loginPassword,
            required String authPassword,
          }) => completion.future,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pump();
    unawaited(
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('后来打开的页面')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    completion.complete(const Success(null));
    await tester.pumpAndSettle();
    expect(find.text('后来打开的页面'), findsOneWidget);
  });
  testWidgets(
    'unknown authorization switch cannot submit and failed read can retry',
    (tester) async {
      final pending = Completer<Result<bool>>();
      var reads = 0, writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AuthPasswordScreen(
            loadEnabled: () => ++reads == 1
                ? pending.future
                : Future.value(const Success(true)),
            submit:
                ({
                  required bool enabled,
                  required String loginPassword,
                  required String authPassword,
                }) async {
                  writes++;
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认'))
            .onPressed,
        isNull,
      );
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
      pending.complete(
        const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'test.read_failed',
            safeMessage: '读取失败',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认'))
            .onPressed,
        isNull,
      );
      expect(writes, 0);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(tester.widget<Switch>(find.byType(Switch)).value, true);
      expect(reads, 2);
    },
  );
  testWidgets('change password keeps confirm disabled until fields match', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          submit: (oldPassword, newPassword) async => const Success(null),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('修改密码'), findsWidgets);
    expect(find.text('请输入原密码'), findsOneWidget);
    expect(find.text('请输入新密码'), findsOneWidget);
    expect(find.text('请确认新密码'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认'))
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byKey(ChangePasswordScreen.oldKey), '123456');
    await tester.enterText(find.byKey(ChangePasswordScreen.newKey), '654321');
    await tester.enterText(
      find.byKey(ChangePasswordScreen.confirmKey),
      '654321',
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('change password logs out after one second, matching Vue', (
    tester,
  ) async {
    var changed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          submit: (oldPassword, newPassword) async => const Success(null),
          onChanged: () => changed += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(ChangePasswordScreen.oldKey), '123456');
    await tester.enterText(find.byKey(ChangePasswordScreen.newKey), '654321');
    await tester.enterText(
      find.byKey(ChangePasswordScreen.confirmKey),
      '654321',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pump();
    expect(find.text('修改密码成功，请重新登录'), findsOneWidget);
    expect(changed, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(changed, 1);
  });

  testWidgets(
    'auth password loads enabled flag and can turn off without fields',
    (tester) async {
      var enabledCalls = 0;
      final saved = <({bool enabled, String login, String auth})>[];
      await tester.pumpWidget(
        MaterialApp(
          home: AuthPasswordScreen(
            loadEnabled: () async {
              enabledCalls += 1;
              return const Success(true);
            },
            submit:
                ({
                  required bool enabled,
                  required String loginPassword,
                  required String authPassword,
                }) async {
                  saved.add((
                    enabled: enabled,
                    login: loginPassword,
                    auth: authPassword,
                  ));
                  return const Success(null);
                },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(enabledCalls, 1);
      expect(find.text('授权密码'), findsWidgets);
      expect(find.text('开启授权密码'), findsOneWidget);
      expect(find.text('请输入登录密码'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(find.text('请输入登录密码'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, '确认'));
      await tester.pumpAndSettle();
      expect(saved.single.enabled, isFalse);
      expect(saved.single.login, isEmpty);
      expect(saved.single.auth, isEmpty);
    },
  );
}
