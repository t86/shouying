import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

void main() {
  group('session models', () {
    test('maps only exact terminal access modes', () {
      expect(
        <Object>[
          1,
          '2',
          4,
          '8',
          16,
          '32',
          64,
          '256',
          512,
        ].map(MachineAccessMode.fromWire).map((mode) => mode?.client),
        <ClientKind?>[
          ClientKind.orgManager,
          ClientKind.booking,
          ClientKind.order,
          ClientKind.cashier,
          ClientKind.vip,
          ClientKind.erp,
          ClientKind.erpAdmin,
          ClientKind.wine,
          ClientKind.queueDisplay,
        ],
      );

      for (final invalid in <Object?>[
        null,
        true,
        false,
        if (!kIsWeb) 1.0,
        0,
        128,
        1024,
        ' 1',
        '1 ',
        '01',
        '+1',
        '1.0',
        '',
      ]) {
        expect(MachineAccessMode.fromWire(invalid), isNull, reason: '$invalid');
      }
    });

    test('sessions expose identity without credential fields', () {
      const machine = MachineSession(
        machineId: 'machine-7',
        machineName: 'Front Counter',
        client: ClientKind.cashier,
      );
      const user = UserSession(
        employeeId: 'employee-8',
        name: 'Synthetic Employee',
        stationId: 'station-9',
      );

      expect(machine.machineId, 'machine-7');
      expect(machine.machineName, 'Front Counter');
      expect(machine.client, ClientKind.cashier);
      expect(user.employeeId, 'employee-8');
      expect(user.name, 'Synthetic Employee');
      expect(user.stationId, 'station-9');
      expect('$machine$user', isNot(contains('password')));
      expect('$machine$user', isNot(contains('token')));
    });
  });

  group('SessionApi machine authorization', () {
    test(
      'posts the trimmed code and atomically stores tk after validation',
      () async {
        final store = _AtomicCredentialStore();
        final adapter = _StubAdapter(
          (_) => _jsonBody(<String, Object?>{
            'code': 1,
            'data': <String, Object?>{
              'tk': 'synthetic-issued-tk',
              'am': '8',
              'id': 42,
              'n': ' Front Counter ',
            },
          }),
        );
        final api = _api(adapter: adapter, credentialStore: store);

        final result = await api.authorizeMachine('  TERM-001  ');

        expect(
          result.valueOrNull,
          const MachineSession(
            machineId: '42',
            machineName: 'Front Counter',
            client: ClientKind.cashier,
          ),
        );
        expect(await store.readTk(), 'synthetic-issued-tk');
        expect(store.writeTkCalls, 1);
        final request = adapter.requests.single;
        expect(request.uri.path, '/server/term/auth');
        expect(request.data, <String, Object?>{'code': 'TERM-001'});
        expect(request.headers, isNot(contains('tt')));
        expect(adapter.calls, 1);
      },
    );

    test('rejects invalid input without making a remote call', () async {
      final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
      final api = _api(adapter: adapter);

      for (final code in <String>[
        '',
        '   ',
        List<String>.filled(129, 'x').join(),
      ]) {
        final result = await api.authorizeMachine(code);
        expect(
          result.failureOrNull?.code,
          'authentication.machine_code_invalid',
        );
      }

      expect(adapter.calls, 0);
    });

    test(
      'rejects malformed response fields before credential writes',
      () async {
        final invalidData = <Map<String, Object?>>[
          <String, Object?>{'tk': '', 'am': 8, 'id': 1, 'n': 'Counter'},
          if (!kIsWeb)
            <String, Object?>{
              'tk': 'synthetic-tk',
              'am': 8.0,
              'id': 1,
              'n': 'Counter',
            },
          <String, Object?>{
            'tk': 'synthetic-tk',
            'am': ' 8',
            'id': 1,
            'n': 'Counter',
          },
          <String, Object?>{
            'tk': 'synthetic-tk',
            'am': 128,
            'id': 1,
            'n': 'Counter',
          },
          if (!kIsWeb)
            <String, Object?>{
              'tk': 'synthetic-tk',
              'am': 8,
              'id': 1.0,
              'n': 'Counter',
            },
          <String, Object?>{
            'tk': 'synthetic-tk',
            'am': 8,
            'id': '',
            'n': 'Counter',
          },
          <String, Object?>{'tk': 'synthetic-tk', 'am': 8, 'id': 1, 'n': ''},
          <String, Object?>{'tk': 'synthetic-tk', 'am': 8, 'id': 1, 'n': true},
        ];

        for (final data in invalidData) {
          final store = _AtomicCredentialStore();
          final adapter = _StubAdapter(
            (_) => _jsonBody(<String, Object?>{'code': 1, 'data': data}),
          );
          final result = await _api(
            adapter: adapter,
            credentialStore: store,
          ).authorizeMachine('TERM-001');

          expect(result.failureOrNull?.code, 'protocol.term_auth_shape');
          expect(store.writeTkCalls, 0);
          expect(await store.readTk(), isNull);
        }
      },
    );

    test(
      'maps missing or wrongly typed data to a stable shape failure',
      () async {
        for (final data in <Object?>[null, true, <Object?>[], 'payload']) {
          final adapter = _StubAdapter(
            (_) => _jsonBody(<String, Object?>{'code': 1, 'data': data}),
          );
          final result = await _api(adapter: adapter)
              .authorizeMachine('TERM-001');
          expect(result.failureOrNull?.code, 'protocol.term_auth_shape');
        }
      },
    );

    test(
      'returns credentials unavailable when the validated tk cannot be written',
      () async {
        final store = _AtomicCredentialStore(failure: _StoreFailure.writeTk);
        final adapter = _StubAdapter(
          (_) => _jsonBody(<String, Object?>{
            'code': 1,
            'data': <String, Object?>{
              'tk': 'synthetic-unwritten-tk',
              'am': 8,
              'id': 1,
              'n': 'Counter',
            },
          }),
        );

        final result = await _api(
          adapter: adapter,
          credentialStore: store,
        ).authorizeMachine('TERM-001');

        expect(result.valueOrNull, isNull);
        expect(result.failureOrNull?.kind, FailureKind.authentication);
        expect(
          result.failureOrNull?.code,
          'authentication.credentials_unavailable',
        );
        expect(_failureText(result), isNot(contains('synthetic-unwritten-tk')));
      },
    );

    test('sanitizes and caps rejected server messages', () async {
      final raw =
          '<b>Denied</b>\n#0 stack password=123456 tk=synthetic-server-tk';
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{'code': 27, 'msg': raw}),
      );

      final result = await _api(adapter: adapter).authorizeMachine('TERM-001');
      final failure = result.failureOrNull!;

      expect(failure.kind, FailureKind.business);
      expect(failure.code, 'business.term_auth_rejected');
      expect(failure.safeMessage.length, lessThanOrEqualTo(160));
      for (final unsafe in <String>[
        '<b>',
        '\n',
        '#0',
        'password',
        '123456',
        'synthetic-server-tk',
      ]) {
        expect(failure.safeMessage, isNot(contains(unsafe)));
      }
      expect(adapter.calls, 1, reason: 'business failures are not retried');
    });

    test(
      'propagates ProtocolClient auth failures before mapping response data',
      () async {
        final store = _AtomicCredentialStore(tk: 'synthetic-expired-tk');
        final adapter = _StubAdapter(
          (_) => _jsonBody(<String, Object?>{'code': 11, 'msg': 'raw'}),
        );

        final result = await _api(
          adapter: adapter,
          credentialStore: store,
        ).authorizeMachine('TERM-001');

        expect(result.failureOrNull?.code, 'authentication.tk_expired');
        expect(store.clearTkIfMatchesCalls, 1);
      },
    );
  });

  group('SessionApi employee lifecycle', () {
    const machine = MachineSession(
      machineId: 'machine-7',
      machineName: 'Front Counter',
      client: ClientKind.cashier,
    );

    test('hashes the original password with uppercase MD5 and sends terminal headers', () async {
      final store = _AtomicCredentialStore(tk: 'synthetic-machine-tk');
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{
          'code': '1',
          'data': <String, Object?>{
            'emp_id': 88,
            'name': ' Synthetic Employee ',
            'station_id': 'station-9',
          },
        }),
      );

      final api = _api(adapter: adapter, credentialStore: store);
      final result = await api.login(
        machine: machine,
        account: '  employee-8  ',
        password: '123456',
        type: EmployeeLoginType.account,
      );

      expect(
        result.valueOrNull,
        const UserSession(
          employeeId: '88',
          name: 'Synthetic Employee',
          stationId: 'station-9',
        ),
      );
      final request = adapter.requests.single;
      expect(request.uri.path, '/server/auth/login');
      expect(request.headers['tt'], '8');
      expect(request.headers['tk'], 'synthetic-machine-tk');
      expect(request.data, <String, Object?>{
        'code': 'employee-8',
        'passwd': 'E10ADC3949BA59ABBE56E057F20F883E',
        'client_name': 'money',
        'pt': 1,
      });
      expect('$api$result', isNot(contains('123456')));
      expect(
        '$api$result',
        isNot(contains('E10ADC3949BA59ABBE56E057F20F883E')),
      );
    });

    test('uses pt 2 for card login', () async {
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{
          'code': 1,
          'data': <String, Object?>{
            'emp_id': 'employee-8',
            'name': 'Synthetic Employee',
            'station_id': 9,
          },
        }),
      );

      await _api(adapter: adapter).login(
        machine: machine,
        account: 'CARD-8',
        password: 'synthetic-card-password',
        type: EmployeeLoginType.card,
      );

      expect((adapter.requests.single.data as Map)['pt'], 2);
    });

    test('rejects invalid login input without hashing or transport', () async {
      final adapter = _StubAdapter((_) => _jsonBody(<String, Object?>{}));
      final api = _api(adapter: adapter);

      for (final input in <(String, String)>[
        ('', 'synthetic-password'),
        ('   ', 'synthetic-password'),
        ('employee', ''),
        ('employee', '   '),
        (List<String>.filled(129, 'x').join(), 'synthetic-password'),
        ('employee', List<String>.filled(257, 'x').join()),
      ]) {
        final result = await api.login(
          machine: machine,
          account: input.$1,
          password: input.$2,
          type: EmployeeLoginType.account,
        );
        expect(
          result.failureOrNull?.code,
          'authentication.login_input_invalid',
        );
      }

      expect(adapter.calls, 0);
    });

    test('rejects doubles and malformed user response fields', () async {
      final invalidData = <Map<String, Object?>>[
        if (!kIsWeb)
          <String, Object?>{'emp_id': 1.0, 'name': 'Employee', 'station_id': 2},
        <String, Object?>{'emp_id': 1, 'name': '', 'station_id': 2},
        if (!kIsWeb)
          <String, Object?>{'emp_id': 1, 'name': 'Employee', 'station_id': 2.0},
        <String, Object?>{'emp_id': true, 'name': 'Employee', 'station_id': 2},
      ];

      for (final data in invalidData) {
        final adapter = _StubAdapter(
          (_) => _jsonBody(<String, Object?>{'code': 1, 'data': data}),
        );
        final result = await _api(adapter: adapter).login(
          machine: machine,
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
        expect(result.failureOrNull?.code, 'protocol.login_shape');
      }
    });

    test('never exposes password, hash, tk, HTML, or stack text in business failures', () async {
      const password = 'synthetic-login-password';
      const hash = '4D8AB88C6DF0D4DD1E5DA11C210F7F82';
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{
          'code': 2,
          'message': '<p>$password $hash tk=synthetic-machine-tk</p>\n#1 stack',
        }),
      );

      final result = await _api(adapter: adapter).login(
        machine: machine,
        account: 'employee',
        password: password,
        type: EmployeeLoginType.account,
      );

      final text = _failureText(result);
      for (final unsafe in <String>[
        password,
        hash,
        'synthetic-machine-tk',
        '<p>',
        '#1',
      ]) {
        expect(text, isNot(contains(unsafe)));
      }
      expect(adapter.calls, 1);
    });

    test('posts logout once using the current machine client', () async {
      final store = _AtomicCredentialStore(tk: 'synthetic-machine-tk');
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{'code': 1}),
      );

      final result = await _api(
        adapter: adapter,
        credentialStore: store,
      ).logout(machine);

      expect(result, isA<Success<void>>());
      final request = adapter.requests.single;
      expect(request.uri.path, '/server/auth/logout');
      expect(request.data, isA<Map<String, Object?>>());
      expect((request.data as Map), isEmpty);
      expect(request.headers['tt'], '8');
      expect(request.headers['tk'], 'synthetic-machine-tk');
      expect(adapter.calls, 1);
    });
  });

  group('SessionRepository', () {
    test(
      'replays current state and applies transactional session updates',
      () async {
        final api = _FakeSessionApi();
        final store = _AtomicCredentialStore();
        final repository = SessionRepository(api: api, credentialStore: store);
        addTearDown(repository.close);
        const machine1 = MachineSession(
          machineId: 'machine-1',
          machineName: 'Counter 1',
          client: ClientKind.cashier,
        );
        const machine2 = MachineSession(
          machineId: 'machine-2',
          machineName: 'Counter 2',
          client: ClientKind.order,
        );
        const user = UserSession(
          employeeId: 'employee-1',
          name: 'Employee',
          stationId: 'station-1',
        );
        final machines = <MachineSession?>[];
        final users = <UserSession?>[];
        final machineSub = repository.machineSessions.listen(machines.add);
        final userSub = repository.userSessions.listen(users.add);
        addTearDown(machineSub.cancel);
        addTearDown(userSub.cancel);

        api.authorizeResult = const Success(machine1);
        expect(
          await repository.authorizeMachine('TERM-1'),
          isA<Success<MachineSession>>(),
        );
        api.loginResult = const Success(user);
        expect(
          await repository.login(
            account: 'employee',
            password: 'synthetic-password',
            type: EmployeeLoginType.account,
          ),
          isA<Success<UserSession>>(),
        );

        api.authorizeResult = const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'network.unavailable',
            safeMessage: 'Network unavailable',
          ),
        );
        await repository.authorizeMachine('TERM-FAILED');
        expect(repository.currentMachine, machine1);
        expect(repository.currentUser, user);

        api.authorizeResult = const Success(machine2);
        await repository.authorizeMachine('TERM-2');
        await Future<void>.delayed(Duration.zero);

        expect(repository.currentMachine, machine2);
        expect(repository.currentUser, isNull);
        expect(machines, <MachineSession?>[null, machine1, machine2]);
        expect(users, <UserSession?>[null, user, null]);

        final replayed = await repository.machineSessions.first;
        expect(replayed, machine2);
      },
    );

    test(
      'requires a machine before login and never creates an orphan user',
      () async {
        final api = _FakeSessionApi();
        final repository = SessionRepository(
          api: api,
          credentialStore: _AtomicCredentialStore(),
        );
        addTearDown(repository.close);

        final result = await repository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );

        expect(result.failureOrNull?.code, 'authentication.machine_required');
        expect(repository.currentUser, isNull);
        expect(api.loginCalls, 0);
      },
    );

    test(
      'suppresses concurrent repository submissions without duplicate calls',
      () async {
        final pending = Completer<Result<MachineSession>>();
        final api = _FakeSessionApi(onAuthorize: (_) => pending.future);
        final repository = SessionRepository(
          api: api,
          credentialStore: _AtomicCredentialStore(),
        );
        addTearDown(repository.close);

        final first = repository.authorizeMachine('TERM-1');
        final duplicate = await repository.authorizeMachine('TERM-2');

        expect(duplicate.failureOrNull?.code, 'session.operation_in_progress');
        expect(api.authorizeCalls, 1);
        pending.complete(
          const Success(
            MachineSession(
              machineId: 'machine-1',
              machineName: 'Counter',
              client: ClientKind.cashier,
            ),
          ),
        );
        expect(await first, isA<Success<MachineSession>>());
      },
    );

    test(
      'reports operation_in_progress across different repository commands',
      () async {
        final pending = Completer<Result<MachineSession>>();
        final api = _FakeSessionApi(onAuthorize: (_) => pending.future);
        final repository = SessionRepository(
          api: api,
          credentialStore: _AtomicCredentialStore(),
        );
        addTearDown(repository.close);

        final authorization = repository.authorizeMachine('TERM-1');
        final login = await repository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );

        expect(login.failureOrNull?.code, 'session.operation_in_progress');
        expect(api.loginCalls, 0);
        pending.complete(
          const Success(
            MachineSession(
              machineId: 'machine-1',
              machineName: 'Counter',
              client: ClientKind.cashier,
            ),
          ),
        );
        await authorization;
      },
    );

    test(
      'logout returns remote failure but clears local state and matching tk',
      () async {
        final api = _FakeSessionApi();
        final store = _AtomicCredentialStore(tk: 'synthetic-machine-tk');
        final repository = SessionRepository(api: api, credentialStore: store);
        addTearDown(repository.close);
        api.authorizeResult = const Success(
          MachineSession(
            machineId: 'machine-1',
            machineName: 'Counter',
            client: ClientKind.cashier,
          ),
        );
        api.loginResult = const Success(
          UserSession(
            employeeId: 'employee-1',
            name: 'Employee',
            stationId: 'station-1',
          ),
        );
        await repository.authorizeMachine('TERM-1');
        await repository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
        api.logoutResult = const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'network.timeout',
            safeMessage: 'Request timed out',
          ),
        );

        final result = await repository.logout();

        expect(result.failureOrNull?.code, 'network.timeout');
        expect(repository.currentMachine, isNull);
        expect(repository.currentUser, isNull);
        expect(await store.readTk(), isNull);
        expect(store.clearTkIfMatchesCalls, 1);
        expect(api.logoutCalls, 1);
      },
    );

    test('logout exposes credential clearing failure only when remote logout succeeds', () async {
      final api = _FakeSessionApi();
      final store = _AtomicCredentialStore(
        tk: 'synthetic-machine-tk',
        failure: _StoreFailure.clearTk,
      );
      final repository = SessionRepository(api: api, credentialStore: store);
      addTearDown(repository.close);
      api.authorizeResult = const Success(
        MachineSession(
          machineId: 'machine-1',
          machineName: 'Counter',
          client: ClientKind.cashier,
        ),
      );
      await repository.authorizeMachine('TERM-1');

      final result = await repository.logout();

      expect(
        result.failureOrNull?.code,
        'authentication.credentials_unavailable',
      );
      expect(repository.currentMachine, isNull);
      expect(repository.currentUser, isNull);
      expect(_failureText(result), isNot(contains('synthetic-machine-tk')));
      expect(store.clearStkIfMatchesCalls, 1);
    });

    test(
      'close is idempotent and later methods return a stable safe failure',
      () async {
        final repository = SessionRepository(
          api: _FakeSessionApi(),
          credentialStore: _AtomicCredentialStore(),
        );

        await repository.close();
        await repository.close();
        final auth = await repository.authorizeMachine('TERM-1');
        final login = await repository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
        final logout = await repository.logout();

        for (final result in <Result<Object?>>[auth, login, logout]) {
          expect(result.failureOrNull?.code, 'session.repository_closed');
        }
      },
    );
  });

  group('LoginViewModel Riverpod composition', () {
    test(
      'transitions through authorization, login, authentication, and logout',
      () async {
        final api = _FakeSessionApi();
        final repository = SessionRepository(
          api: api,
          credentialStore: _AtomicCredentialStore(),
        );
        addTearDown(repository.close);
        api.authorizeResult = const Success(
          MachineSession(
            machineId: 'machine-1',
            machineName: 'Counter',
            client: ClientKind.cashier,
          ),
        );
        api.loginResult = const Success(
          UserSession(
            employeeId: 'employee-1',
            name: 'Employee',
            stationId: 'station-1',
          ),
        );
        final container = ProviderContainer.test(
          overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
        );
        final phases = <LoginPhase>[];
        container.listen(
          loginViewModelProvider,
          (_, next) => phases.add(next.phase),
          fireImmediately: true,
        );
        final viewModel = container.read(loginViewModelProvider.notifier);

        await viewModel.authorizeMachine('TERM-1');
        await viewModel.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
        await viewModel.logout();

        expect(phases, <LoginPhase>[
          LoginPhase.idle,
          LoginPhase.authorizingMachine,
          LoginPhase.readyForLogin,
          LoginPhase.loggingIn,
          LoginPhase.authenticated,
          LoginPhase.idle,
        ]);
        expect(container.read(loginViewModelProvider).failure, isNull);
        expect(repository.currentMachine, isNull);
        expect(repository.currentUser, isNull);
      },
    );

    test('shows safe failures and supports retry', () async {
      final api = _FakeSessionApi();
      final repository = SessionRepository(
        api: api,
        credentialStore: _AtomicCredentialStore(),
      );
      addTearDown(repository.close);
      final container = ProviderContainer.test(
        overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
      );
      final viewModel = container.read(loginViewModelProvider.notifier);
      api.authorizeResult = const FailureResult(
        AppFailure(
          kind: FailureKind.network,
          code: 'network.unavailable',
          safeMessage: 'Network unavailable',
        ),
      );

      await viewModel.authorizeMachine('TERM-1');
      expect(container.read(loginViewModelProvider).phase, LoginPhase.failure);
      expect(
        container.read(loginViewModelProvider).failure?.code,
        'network.unavailable',
      );

      api.authorizeResult = const Success(
        MachineSession(
          machineId: 'machine-1',
          machineName: 'Counter',
          client: ClientKind.cashier,
        ),
      );
      await viewModel.authorizeMachine('TERM-1');
      expect(
        container.read(loginViewModelProvider).phase,
        LoginPhase.readyForLogin,
      );
      expect(container.read(loginViewModelProvider).failure, isNull);
    });

    test('duplicate taps return operation_in_progress and do not duplicate transport', () async {
      final pending = Completer<Result<MachineSession>>();
      final api = _FakeSessionApi(onAuthorize: (_) => pending.future);
      final repository = SessionRepository(
        api: api,
        credentialStore: _AtomicCredentialStore(),
      );
      addTearDown(repository.close);
      final container = ProviderContainer.test(
        overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
      );
      final viewModel = container.read(loginViewModelProvider.notifier);

      final first = viewModel.authorizeMachine('TERM-1');
      final duplicate = await viewModel.authorizeMachine('TERM-1');

      expect(duplicate.failureOrNull?.code, 'session.operation_in_progress');
      expect(
        container.read(loginViewModelProvider).phase,
        LoginPhase.authorizingMachine,
      );
      expect(api.authorizeCalls, 1);
      pending.complete(
        const Success(
          MachineSession(
            machineId: 'machine-1',
            machineName: 'Counter',
            client: ClientKind.cashier,
          ),
        ),
      );
      await first;
      expect(
        container.read(loginViewModelProvider).phase,
        LoginPhase.readyForLogin,
      );
    });

    test(
      'provider initialization reflects an already authenticated repository',
      () async {
        final api = _FakeSessionApi();
        final repository = SessionRepository(
          api: api,
          credentialStore: _AtomicCredentialStore(),
        );
        addTearDown(repository.close);
        api.authorizeResult = const Success(
          MachineSession(
            machineId: 'machine-1',
            machineName: 'Counter',
            client: ClientKind.cashier,
          ),
        );
        api.loginResult = const Success(
          UserSession(
            employeeId: 'employee-1',
            name: 'Employee',
            stationId: 'station-1',
          ),
        );
        await repository.authorizeMachine('TERM-1');
        await repository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
        final container = ProviderContainer.test(
          overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
        );

        expect(
          container.read(loginViewModelProvider).phase,
          LoginPhase.authenticated,
        );
      },
    );
  });
}

SessionApi _api({
  required _StubAdapter adapter,
  _AtomicCredentialStore? credentialStore,
}) {
  final store = credentialStore ?? _AtomicCredentialStore();
  final dio = Dio()..httpClientAdapter = adapter;
  var now = 0;
  final protocolClient = ProtocolClient(
    dio: dio,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.example/server'),
      onlineBase: Uri.parse('https://online.example/server'),
      websocketBase: Uri.parse('wss://socket.example/events'),
    ),
    credentialStore: store,
    requestGate: RequestGate(
      clock: () => DateTime.fromMillisecondsSinceEpoch(now++),
    ),
  );
  return SessionApi(client: protocolClient, credentialStore: store);
}

String _failureText<T>(Result<T> result) {
  final failure = result.failureOrNull;
  return '${failure?.kind}|${failure?.code}|${failure?.safeMessage}|$result';
}

ResponseBody _jsonBody(Object? value) => ResponseBody.fromString(
  jsonEncode(value),
  200,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

typedef _Responder = FutureOr<ResponseBody> Function(RequestOptions request);

final class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this._responder);

  final _Responder _responder;
  final List<RequestOptions> requests = <RequestOptions>[];
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    requests.add(options);
    if (requestStream != null) {
      await requestStream.drain<void>();
    }
    return _responder(options);
  }

  @override
  void close({bool force = false}) {}
}

final class _FakeSessionApi implements SessionRemoteApi {
  _FakeSessionApi({this.onAuthorize});

  final Future<Result<MachineSession>> Function(String code)? onAuthorize;
  Result<MachineSession> authorizeResult = const FailureResult(
    AppFailure(
      kind: FailureKind.unknown,
      code: 'test.authorize_unconfigured',
      safeMessage: 'Synthetic authorize response missing',
    ),
  );
  Result<UserSession> loginResult = const FailureResult(
    AppFailure(
      kind: FailureKind.unknown,
      code: 'test.login_unconfigured',
      safeMessage: 'Synthetic login response missing',
    ),
  );
  Result<void> logoutResult = const Success<void>(null);
  int authorizeCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<Result<MachineSession>> authorizeMachine(String code) async {
    authorizeCalls += 1;
    return onAuthorize?.call(code) ?? authorizeResult;
  }

  @override
  Future<Result<UserSession>> login({
    required MachineSession machine,
    required String account,
    required String password,
    required EmployeeLoginType type,
  }) async {
    loginCalls += 1;
    return loginResult;
  }

  @override
  Future<Result<void>> logout(MachineSession machine) async {
    logoutCalls += 1;
    return logoutResult;
  }
}

enum _StoreFailure { none, writeTk, readSnapshot, clearTk }

final class _AtomicCredentialStore implements CredentialStore {
  factory _AtomicCredentialStore({
    String? tk,
    String? stk,
    _StoreFailure failure = _StoreFailure.none,
  }) => _AtomicCredentialStore._(tk, stk, failure);

  _AtomicCredentialStore._(this._tk, this._stk, this.failure);

  String? _tk;
  String? _stk;
  final _StoreFailure failure;
  Future<void> _tail = Future<void>.value();
  int writeTkCalls = 0;
  int clearTkIfMatchesCalls = 0;
  int clearStkIfMatchesCalls = 0;

  Future<T> _atomic<T>(FutureOr<T> Function() operation) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await operation());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  @override
  Future<void> clearStk() => _atomic(() => _stk = null);

  @override
  Future<void> clearStkIfMatches(String? expected) => _atomic(() {
    clearStkIfMatchesCalls += 1;
    if (_stk == expected) _stk = null;
  });

  @override
  Future<void> clearTk() => _atomic(() {
    if (failure == _StoreFailure.clearTk) {
      throw StateError('synthetic-store-clear-failure');
    }
    _tk = null;
  });

  @override
  Future<void> clearTkIfMatches(String? expected) => _atomic(() {
    clearTkIfMatchesCalls += 1;
    if (failure == _StoreFailure.clearTk) {
      throw StateError('synthetic-store-clear-failure');
    }
    if (_tk == expected) _tk = null;
  });

  @override
  Future<String?> readStk() => _atomic(() => _stk);

  @override
  Future<CredentialSnapshot> readSnapshot() => _atomic(() {
    if (failure == _StoreFailure.readSnapshot) {
      throw StateError('synthetic-store-read-failure');
    }
    return CredentialSnapshot(tk: _tk, stk: _stk);
  });

  @override
  Future<String?> readTk() => _atomic(() => _tk);

  @override
  Future<void> writeStk(String value) => _atomic(() => _stk = value);

  @override
  Future<void> writeTk(String value) => _atomic(() {
    writeTkCalls += 1;
    if (failure == _StoreFailure.writeTk) {
      throw StateError('synthetic-store-write-failure');
    }
    _tk = value;
  });

  @override
  String toString() => '_AtomicCredentialStore()';
}
