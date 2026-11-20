import 'dart:async';
import 'dart:convert';

import 'package:card_table/src/super_admin_loader.dart';
import 'package:card_table/src/super_admin_login_screen.dart';
import 'package:card_table/src/super_admin_models.dart';
import 'package:card_table/src/super_admin_views.dart';
import 'package:card_table/src/terminal_register_screen.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class EntryLoader extends ChangeNotifier implements SuperAdminLoader {
  @override
  bool get isAuthenticated => true;
  @override
  bool get isBusy => false;
  @override
  int get sessionRevision => 0;
  final pending = Completer<Result<SuperAdminLoginResult>>();
  final passwords = <String>[];
  int registrations = 0;
  Completer<Result<TerminalRegisterResult>>? registration;
  final changes = <List<String>>[];
  @override
  Future<Result<SmgrInitData>> loadEmps({
    int isInit = 2,
    int deptId = 0,
    String stationId = '',
    String name = '',
    bool Function()? canDispatch,
  }) async => const Success(SmgrInitData());
  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
    bool Function()? canDispatch,
  }) async {
    changes.add([oldPassword, newPassword]);
    return const Success(null);
  }

  @override
  Future<Result<SuperAdminLoginResult>> login({
    required String md5Password,
    bool Function()? canDispatch,
  }) {
    passwords.add(md5Password);
    return pending.future;
  }

  @override
  Future<Result<TerminalRegisterResult>> registerTerminal({
    required String authCode,
    required String machineCode,
    bool Function()? canDispatch,
  }) async {
    registrations++;
    if (registration case final pending?) return pending.future;
    return const Success(TerminalRegisterResult(authMode: 8));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected operation');
}

void main() {
  testWidgets(
    'register result for an old machine never completes a rebound page',
    (tester) async {
      final loader = EntryLoader()
        ..registration = Completer<Result<TerminalRegisterResult>>();
      var callbacks = 0;
      Widget page(String code) => MaterialApp(
        home: TerminalRegisterScreen(
          loader: loader,
          machineCode: code,
          onRegisterSuccess: (_) => callbacks++,
        ),
      );
      await tester.pumpWidget(page('first-machine'));
      await tester.enterText(find.byType(TextField), '123456');
      tester.widget<TextField>(find.byType(TextField)).onSubmitted!('');
      await tester.pump();
      await tester.pumpWidget(page('second-machine'));
      loader.registration!.complete(
        const Success(TerminalRegisterResult(authMode: 8)),
      );
      await tester.pumpAndSettle();
      expect(callbacks, 0);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );
  testWidgets(
    'password change UI preserves raw passwords for protocol hashing',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loader = EntryLoader();
      await tester.pumpWidget(
        MaterialApp(home: SuperAdminNavScreen(loader: loader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('修改密码'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), ' old secret ');
      await tester.enterText(find.byType(TextFormField).at(1), ' 123 ');
      await tester.tap(find.text('确认修改'));
      await tester.pumpAndSettle();
      expect(loader.changes, [
        [' old secret ', ' 123 '],
      ]);
    },
  );
  testWidgets(
    'login preserves raw password, clears entry and ignores duplicate submit',
    (tester) async {
      final loader = EntryLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: SuperAdminLoginScreen(loader: loader, onLoginSuccess: (_) {}),
        ),
      );
      await tester.enterText(find.byType(TextField), ' 123456 ');
      final field = tester.widget<TextField>(find.byType(TextField));
      field.onSubmitted!('');
      field.onSubmitted!('');
      await tester.pump();
      expect(loader.passwords, [
        md5.convert(utf8.encode(' 123456 ')).toString().toUpperCase(),
      ]);
      expect(field.controller!.text, isEmpty);
      loader.pending.complete(
        const Success(SuperAdminLoginResult(token: 'test')),
      );
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'failed login exception exits busy state without exposing details',
    (tester) async {
      final loader = EntryLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: SuperAdminLoginScreen(loader: loader, onLoginSuccess: (_) {}),
        ),
      );
      await tester.enterText(find.byType(TextField), 'secret');
      tester.widget<TextField>(find.byType(TextField)).onSubmitted!('');
      await tester.pump();
      loader.pending.completeError(StateError('private diagnostic'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('登录失败，请重试'), findsOneWidget);
      expect(find.textContaining('private diagnostic'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );
  testWidgets('late login result during return animation cannot navigate', (
    tester,
  ) async {
    final loader = EntryLoader();
    var callbacks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SuperAdminLoginScreen(
                  loader: loader,
                  onLoginSuccess: (_) => callbacks++,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'secret');
    tester.widget<TextField>(find.byType(TextField)).onSubmitted!('');
    await tester.pump();
    Navigator.of(tester.element(find.byType(SuperAdminLoginScreen))).pop();
    await tester.pump();
    loader.pending.complete(
      const Success(SuperAdminLoginResult(token: 'test')),
    );
    await tester.pumpAndSettle();
    expect(callbacks, 0);
  });
  testWidgets('registration never submits a fabricated default machine code', (
    tester,
  ) async {
    final loader = EntryLoader();
    await tester.pumpWidget(
      MaterialApp(
        home: TerminalRegisterScreen(loader: loader, onRegisterSuccess: (_) {}),
      ),
    );
    await tester.enterText(find.byType(TextField), '123456');
    tester.widget<TextField>(find.byType(TextField)).onSubmitted!('');
    await tester.pumpAndSettle();
    expect(loader.registrations, 0);
    expect(find.text('当前设备未提供机器码，不能注册'), findsOneWidget);
  });
}
