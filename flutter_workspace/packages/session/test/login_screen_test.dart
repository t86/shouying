import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';
import 'package:session/src/session_api.dart'
    show MachineAuthorization, SessionRemoteApi;

void main() {
  late _FakeSessionApi api;
  late SessionRepository repository;

  setUp(() {
    api = _FakeSessionApi();
    repository = SessionRepository(
      api: api,
      credentialStore: _MemoryCredentialStore(),
    );
  });

  tearDown(() async {
    await repository.close();
  });

  Future<void> pumpSubject(
    WidgetTester tester, {
    ConnectionPhase phase = ConnectionPhase.online,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(home: LoginScreen(connectionPhase: phase)),
    ),
  );

  testWidgets('requires machine code before terminal authorization', (
    tester,
  ) async {
    await pumpSubject(tester);

    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsOneWidget);
    expect(find.byKey(LoginScreen.accountFieldKey), findsNothing);
    await tester.tap(find.byKey(LoginScreen.machineSubmitKey));
    await tester.pump();

    expect(find.text('请输入终端授权码'), findsOneWidget);
    expect(api.authorizeCalls, 0);
  });

  testWidgets('keyboard enter authorizes then shows account and password', (
    tester,
  ) async {
    await pumpSubject(tester);
    await tester.enterText(
      find.byKey(LoginScreen.machineCodeFieldKey),
      'TERM-001',
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(api.authorizeCalls, 1);
    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsNothing);
    expect(find.byKey(LoginScreen.accountFieldKey), findsOneWidget);
    expect(find.byKey(LoginScreen.passwordFieldKey), findsOneWidget);
  });

  testWidgets('requires both account and password before login', (
    tester,
  ) async {
    await repository.authorizeMachine('TERM-001');
    await pumpSubject(tester);

    await tester.tap(find.byKey(LoginScreen.loginSubmitKey));
    await tester.pump();
    expect(find.text('请输入员工账号'), findsOneWidget);
    expect(find.text('请输入密码'), findsOneWidget);
    expect(api.loginCalls, 0);
  });

  testWidgets('password is obscured and cleared immediately after submit', (
    tester,
  ) async {
    await repository.authorizeMachine('TERM-001');
    final pending = Completer<Result<UserSession>>();
    api.loginResult = pending.future;
    await pumpSubject(tester);

    await tester.enterText(find.byKey(LoginScreen.accountFieldKey), 'employee');
    await tester.enterText(
      find.byKey(LoginScreen.passwordFieldKey),
      'synthetic-password',
    );
    final passwordField = tester.widget<TextField>(
      find.byKey(LoginScreen.passwordFieldKey),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(api.loginCalls, 1);
    expect(
      tester
          .widget<TextField>(find.byKey(LoginScreen.passwordFieldKey))
          .controller
          ?.text,
      isEmpty,
    );
    pending.complete(
      const Success(
        UserSession(
          employeeId: 'employee-1',
          name: 'Synthetic Employee',
          stationId: 'station-1',
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('duplicate submit is disabled while login is pending', (
    tester,
  ) async {
    await repository.authorizeMachine('TERM-001');
    final pending = Completer<Result<UserSession>>();
    api.loginResult = pending.future;
    await pumpSubject(tester);
    await tester.enterText(find.byKey(LoginScreen.accountFieldKey), 'employee');
    await tester.enterText(
      find.byKey(LoginScreen.passwordFieldKey),
      'synthetic-password',
    );

    await tester.tap(find.byKey(LoginScreen.loginSubmitKey));
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(LoginScreen.loginSubmitKey),
    );
    expect(button.onPressed, isNull);
    await tester.tap(find.byKey(LoginScreen.loginSubmitKey));
    expect(api.loginCalls, 1);

    pending.complete(
      const FailureResult(
        AppFailure(
          kind: FailureKind.authentication,
          code: 'authentication.rejected',
          safeMessage: '账号或密码不正确',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('账号或密码不正确'), findsOneWidget);
    expect(find.textContaining('authentication.rejected'), findsNothing);
  });

  testWidgets('connection recovery phase is shown without state diagnostics', (
    tester,
  ) async {
    await pumpSubject(tester, phase: ConnectionPhase.reconciling);

    expect(find.text('正在恢复服务端状态'), findsOneWidget);
    expect(find.textContaining('LoginState'), findsNothing);
    expect(find.textContaining('LoginPhase'), findsNothing);
  });
}

final class _FakeSessionApi implements SessionRemoteApi {
  int authorizeCalls = 0;
  int loginCalls = 0;
  Future<Result<UserSession>> loginResult = Future<Result<UserSession>>.value(
    const FailureResult(
      AppFailure(
        kind: FailureKind.authentication,
        code: 'authentication.rejected',
        safeMessage: '账号或密码不正确',
      ),
    ),
  );

  @override
  Future<Result<MachineAuthorization>> authorizeMachine(String code) async {
    authorizeCalls += 1;
    return const Success(
      MachineAuthorization(
        session: MachineSession(
          machineId: 'machine-1',
          machineName: 'Front Counter',
          client: ClientKind.cashier,
        ),
        tk: 'synthetic-tk',
      ),
    );
  }

  @override
  Future<Result<UserSession>> login({
    required MachineSession machine,
    required String account,
    required String password,
    required EmployeeLoginType type,
  }) {
    loginCalls += 1;
    return loginResult;
  }

  @override
  Future<Result<void>> logout(MachineSession machine) async =>
      const Success<void>(null);
}

final class _MemoryCredentialStore implements CredentialStore {
  String? _tk;
  String? _stk;

  @override
  Future<void> clearStk() async => _stk = null;

  @override
  Future<void> clearStkIfMatches(String? expected) async {
    if (_stk == expected) _stk = null;
  }

  @override
  Future<void> clearTk() async => _tk = null;

  @override
  Future<void> clearTkIfMatches(String? expected) async {
    if (_tk == expected) _tk = null;
  }

  @override
  Future<String?> readStk() async => _stk;

  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      CredentialSnapshot(tk: _tk, stk: _stk);

  @override
  Future<String?> readTk() async => _tk;

  @override
  Future<void> writeStk(String value) async => _stk = value;

  @override
  Future<void> writeTk(String value) async => _tk = value;
}
