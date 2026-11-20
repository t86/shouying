import 'dart:async';

import 'package:card_table/src/super_admin_loader.dart';
import 'package:card_table/src/super_admin_login_screen.dart';
import 'package:card_table/src/super_admin_models.dart';
import 'package:card_table/src/super_admin_views.dart';
import 'package:card_table/src/terminal_register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

final class FakeSuperAdminLoader extends ChangeNotifier
    implements SuperAdminLoader {
  @override
  bool isAuthenticated = true;
  @override
  bool isBusy = false;
  @override
  int sessionRevision = 0;
  @override
  Future<Result<void>> restore() async => const Success(null);
  void replaceSession({bool authenticated = true}) {
    isAuthenticated = authenticated;
    sessionRevision++;
    notifyListeners();
  }

  Completer<Result<void>>? pendingWrite;
  final changedPasswords = <List<String>>[];
  int resetCount = 0;
  int grantCount = 0;
  int loads = 0;
  bool loginCalled = false;
  String lastLoginPassword = '';
  bool logoutCalled = false;
  bool changePasswordCalled = false;
  bool setStationEnableCalled = false;
  bool toggleStationAdminCalled = false;
  bool resetEmpPasswordCalled = false;
  bool toggleEmpStatusCalled = false;
  bool registerTerminalCalled = false;
  int lastDeptId = 0;
  String lastStationId = '';
  String lastName = '';

  @override
  Future<Result<SuperAdminLoginResult>> login({
    required String md5Password,
    bool Function()? canDispatch,
  }) async {
    loginCalled = true;
    lastLoginPassword = md5Password;
    return const Success(SuperAdminLoginResult(token: 'stk-fake', empId: 2));
  }

  @override
  Future<Result<void>> logout({bool Function()? canDispatch}) async {
    logoutCalled = true;
    replaceSession(authenticated: false);
    return const Success(null);
  }

  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
    bool Function()? canDispatch,
  }) async {
    changePasswordCalled = true;
    changedPasswords.add([oldPassword, newPassword]);
    return const Success(null);
  }

  @override
  Future<Result<SmgrInitData>> loadEmps({
    int isInit = 2,
    int deptId = 0,
    String stationId = '',
    String name = '',
    bool Function()? canDispatch,
  }) async {
    loads++;
    lastDeptId = deptId;
    lastStationId = stationId;
    lastName = name;
    return const Success(
      SmgrInitData(
        departments: [
          SmgrDeptItem(
            id: 1,
            name: '运营管理中心',
            children: [
              SmgrDeptItem(
                id: 2,
                name: '门店运营',
                children: [SmgrDeptItem(id: 3, name: '夜班')],
              ),
            ],
          ),
        ],
        stations: [SmgrStationItem(id: 101, name: '收银领班')],
        stationRows: [
          SmgrStationRow(
            id: 101,
            name: '收银领班',
            empCount: 1,
            status: '有效',
            isAdmin: false,
            isExpanded: true,
            employees: [
              SmgrEmpItem(
                id: 1,
                code: '001',
                name: '张小凡',
                deptName: '运营管理中心',
                status: '有效',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Future<Result<void>> setStationEnable(
    int stationId, {
    bool Function()? canDispatch,
  }) async {
    setStationEnableCalled = true;
    return const Success(null);
  }

  @override
  Future<Result<void>> toggleStationAdmin(
    int stationId,
    bool grant, {
    bool Function()? canDispatch,
  }) async {
    grantCount++;
    toggleStationAdminCalled = true;
    if (pendingWrite case final pending?) return pending.future;
    return const Success(null);
  }

  @override
  Future<Result<void>> resetEmpPassword(
    int empId, {
    bool Function()? canDispatch,
  }) async {
    resetCount++;
    resetEmpPasswordCalled = true;
    return const Success(null);
  }

  @override
  Future<Result<void>> toggleEmpStatus(
    int empId,
    bool enable, {
    bool Function()? canDispatch,
  }) async {
    toggleEmpStatusCalled = true;
    return const Success(null);
  }

  @override
  Future<Result<TerminalRegisterResult>> registerTerminal({
    required String authCode,
    required String machineCode,
    bool Function()? canDispatch,
  }) async {
    registerTerminalCalled = true;
    return const Success(TerminalRegisterResult(authMode: 1, message: '注册成功'));
  }
}

void main() {
  testWidgets(
    'password change follows source either-password rule and invalidates an old dialog',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loader = FakeSuperAdminLoader();
      await tester.pumpWidget(
        MaterialApp(home: SuperAdminNavScreen(loader: loader)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('修改密码'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认修改'));
      await tester.pump();
      expect(find.text('新旧密码不能为空'), findsOneWidget);
      expect(loader.changedPasswords, isEmpty);
      await tester.enterText(find.byType(TextFormField).at(1), ' new ');
      await tester.tap(find.text('确认修改'));
      await tester.pumpAndSettle();
      expect(loader.changedPasswords, [
        ['', ' new '],
      ]);
      await tester.tap(find.text('修改密码'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'old');
      loader.replaceSession();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        isEmpty,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认修改'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(loader.changedPasswords.length, 1);
    },
  );

  Future<void> openManagement(
    WidgetTester tester,
    FakeSuperAdminLoader loader,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SuperAdminSmgrView(loader: loader)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'old employee confirmation never dispatches into a replacement session',
    (tester) async {
      final loader = FakeSuperAdminLoader();
      await openManagement(tester, loader);
      await tester.tap(find.widgetWithText(TextButton, '重置密码'));
      await tester.pumpAndSettle();
      loader.replaceSession(authenticated: false);
      await tester.pump();
      expect(find.text('张小凡'), findsNothing);
      loader.replaceSession();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认重置'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(loader.resetCount, 0);
    },
  );

  testWidgets(
    'pending manager change blocks duplicate clicks and preserves row expansion',
    (tester) async {
      final loader = FakeSuperAdminLoader()
        ..pendingWrite = Completer<Result<void>>();
      await openManagement(tester, loader);
      final button = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '设为管理员'),
      );
      button.onPressed!();
      button.onPressed!();
      await tester.pump();
      expect(loader.grantCount, 1);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      loader.pendingWrite!.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('张小凡'), findsOneWidget);
      expect(loader.loads, 2);
    },
  );

  testWidgets(
    'recursive department selection queries its own ID and resets filters',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loader = FakeSuperAdminLoader();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SuperAdminSmgrView(loader: loader)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('运营管理中心 / 门店运营 / 夜班').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('收银领班').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), ' 001 ');
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(loader.lastDeptId, 3);
      expect(loader.lastStationId, '101');
      expect(loader.lastName, ' 001 ');
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(loader.lastDeptId, 0);
      expect(loader.lastStationId, '');
      expect(loader.lastName, '');
    },
  );
  testWidgets(
    'SuperAdminLoginScreen renders keypad and handles login submission',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final loader = FakeSuperAdminLoader();
      SuperAdminLoginResult? loginResult;
      bool backCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SuperAdminLoginScreen(
            loader: loader,
            onLoginSuccess: (r) => loginResult = r,
            onBack: () => backCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('超级管理员登录'), findsOneWidget);
      expect(find.text('系统维护与超级权限中心'), findsOneWidget);

      // Tap keypad digits: 1, 2, 3
      await tester.tap(find.byKey(const ValueKey('keypad-1')));
      await tester.tap(find.byKey(const ValueKey('keypad-2')));
      await tester.tap(find.byKey(const ValueKey('keypad-3')));
      await tester.pump();

      // Tap backspace
      await tester.tap(find.byKey(const ValueKey('keypad-backspace')));
      await tester.pump();

      // Tap clear
      await tester.tap(find.byKey(const ValueKey('keypad-clear')));
      await tester.pump();

      // Tap 8, 8, 8, 8
      await tester.tap(find.byKey(const ValueKey('keypad-8')));
      await tester.tap(find.byKey(const ValueKey('keypad-8')));
      await tester.tap(find.byKey(const ValueKey('keypad-8')));
      await tester.tap(find.byKey(const ValueKey('keypad-8')));
      await tester.pump();

      // Tap login button
      await tester.tap(find.text('立即登录'));
      await tester.pumpAndSettle();

      expect(loader.loginCalled, true);
      expect(loginResult?.token, 'stk-fake');

      // Tap back button
      await tester.tap(find.text('返回收银系统'));
      await tester.pump();
      expect(backCalled, true);
    },
  );

  testWidgets(
    'SuperAdminSmgrView renders stations, employees and triggers actions',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final loader = FakeSuperAdminLoader();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SuperAdminSmgrView(loader: loader)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('收银领班'), findsWidgets);
      expect(find.text('员工数: 1'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(find.text('张小凡'), findsOneWidget);
      expect(find.text('001'), findsOneWidget);

      // Click set as admin
      await tester.tap(find.text('设为管理员'));
      await tester.pumpAndSettle();
      expect(loader.toggleStationAdminCalled, true);

      // Click set station enable
      await tester.tap(find.text('置为有效'));
      await tester.pumpAndSettle();
      expect(loader.setStationEnableCalled, true);

      // Click reset employee password
      await tester.tap(find.widgetWithText(TextButton, '重置密码'));
      await tester.pumpAndSettle();
      expect(find.text('重置密码确认'), findsOneWidget);
      await tester.tap(find.text('确认重置'));
      await tester.pumpAndSettle();
      expect(loader.resetEmpPasswordCalled, true);

      // Click toggle employee status (置为无效)
      await tester.tap(find.text('置为无效'));
      await tester.pumpAndSettle();
      expect(loader.toggleEmpStatusCalled, true);
    },
  );

  testWidgets(
    'SuperAdminNavScreen renders app bar, change password and logout',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final loader = FakeSuperAdminLoader();
      bool onBackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SuperAdminNavScreen(
            loader: loader,
            userName: '超管001',
            onBack: () => onBackCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('超级管理员后台 (AppInfo)'), findsOneWidget);
      expect(find.text('超管001'), findsOneWidget);

      // Click change password
      await tester.tap(find.text('修改密码'));
      await tester.pumpAndSettle();
      expect(find.text('修改超级管理员密码'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Click logout
      await tester.tap(find.text('退出超管'));
      await tester.pumpAndSettle();
      expect(loader.logoutCalled, true);
      expect(onBackCalled, true);
    },
  );

  testWidgets('TerminalRegisterScreen renders form and submits code', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final loader = FakeSuperAdminLoader();
    TerminalRegisterResult? result;
    bool backCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TerminalRegisterScreen(
          loader: loader,
          machineCode: 'MOCK-MACHINE-01',
          onRegisterSuccess: (r) => result = r,
          onBack: () => backCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('终端设备授权注册'), findsOneWidget);
    expect(find.text('机器码: MOCK-MACHINE-01'), findsOneWidget);

    // Enter code via keypad: 6, 6, 8, 8
    await tester.tap(find.byKey(const ValueKey('keypad-6')));
    await tester.tap(find.byKey(const ValueKey('keypad-6')));
    await tester.tap(find.byKey(const ValueKey('keypad-8')));
    await tester.tap(find.byKey(const ValueKey('keypad-8')));
    await tester.pump();

    // Submit
    await tester.tap(find.text('提交注册'));
    await tester.pumpAndSettle();

    expect(loader.registerTerminalCalled, true);
    expect(result?.authMode, 1);

    // Back
    await tester.tap(find.text('返回登录'));
    await tester.pump();
    expect(backCalled, true);
  });
}
