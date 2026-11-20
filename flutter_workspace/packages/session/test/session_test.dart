import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';
import 'package:session/src/session_api.dart'
    show MachineAuthorization, SessionRemoteApi;

void main() {
  test('successful equal-field relogin publishes fresh identity but rejected login preserves it', () async {
    final api = _FakeSessionApi();
    final repository = SessionRepository(api: api, credentialStore: _AtomicCredentialStore());
    addTearDown(repository.close);
    api.authorizeResult = _authorized(const MachineSession(machineId:'m',machineName:'Counter',client:ClientKind.cashier),tk:'synthetic-tk');
    await repository.authorizeMachine('TERM');
    final users = <UserSession?>[];
    final subscription = repository.userSessions.listen(users.add);
    addTearDown(subscription.cancel);
    api.loginResult = const Success(UserSession(employeeId:'7',name:'Employee',stationId:'9'));
    Future<Result<UserSession>> login() => repository.login(account:'employee',password:'synthetic-password',type:EmployeeLoginType.account);
    final first = (await login()).valueOrNull!;
    final second = (await login()).valueOrNull!;
    await Future<void>.delayed(Duration.zero);
    expect(first, second); // Preserve the public value-equality contract.
    expect(identical(first, second), false);
    expect(identical(second, repository.currentUser), true);
    expect(users.whereType<UserSession>().length, 2);
    for (final code in ['business.login_rejected', 'authentication.credentials_unavailable']) {
      api.loginResult = FailureResult(AppFailure(kind:FailureKind.authentication,code:code,safeMessage:'登录失败'));
      expect((await login()).failureOrNull, isNotNull);
      await Future<void>.delayed(Duration.zero);
      expect(identical(second, repository.currentUser),true);
      expect(users.whereType<UserSession>().length,2);
    }
  });
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

    test(
      'normalizes integral numbers consistently and rejects unsafe numerics',
      () {
        for (final value in <num>[1, 1.0]) {
          expect(
            MachineAccessMode.fromWire(value),
            MachineAccessMode.orgManager,
          );
        }
        for (final value in <num>[
          1.5,
          double.nan,
          double.infinity,
          -double.infinity,
          9007199254740992,
        ]) {
          expect(MachineAccessMode.fromWire(value), isNull, reason: '$value');
        }
      },
    );

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
      'posts the trimmed code without persisting tk in the remote API',
      () async {
        final store = _AtomicCredentialStore();
        final adapter = _StubAdapter(
          (_) => _jsonBody(<String, Object?>{
            'code': 1.0,
            'data': <String, Object?>{
              'tk': 'synthetic-issued-tk',
              'am': '8',
              'id': 'terminal-A7',
              'n': ' Front Counter ',
            },
          }),
        );
        final api = _api(adapter: adapter, credentialStore: store);

        final result = await api.authorizeMachine('  TERM-001  ');

        expect(
          result.valueOrNull?.session,
          const MachineSession(
            machineId: 'terminal-A7',
            machineName: 'Front Counter',
            client: ClientKind.cashier,
          ),
        );
        expect(await store.readTk(), isNull);
        expect(store.writeTkCalls, 0);
        expect(result.valueOrNull?.tk, 'synthetic-issued-tk');
        expect('${result.valueOrNull}', isNot(contains('synthetic-issued-tk')));
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
          <String, Object?>{
            'tk': 'synthetic-tk',
            'am': 8.5,
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
          <String, Object?>{
            'tk': 'synthetic-tk',
            'am': 8,
            'id': 1.5,
            'n': 'Counter',
          },
          <String, Object?>{
            'tk': 'synthetic-tk',
            'am': 8,
            'id': '',
            'n': 'Counter',
          },
          <String, Object?>{
            'tk': 'synthetic-tk',
            'am': 8,
            'id': 9007199254740992,
            'n': 'Counter',
          },
          <String, Object?>{
            'tk': 'synthetic-tk',
            'am': 8,
            'id': 'terminal\nA7',
            'n': 'Counter',
          },
          <String, Object?>{
            'tk': 'synthetic-tk',
            'am': 8,
            'id': List<String>.filled(129, 'x').join(),
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

    test('normalizes integral numeric am and machine ids', () async {
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{
          'code': 1,
          'data': <String, Object?>{
            'tk': 'synthetic-integral-tk',
            'am': 8.0,
            'id': 42.0,
            'n': 'Counter',
          },
        }),
      );

      final result = await _api(adapter: adapter).authorizeMachine('TERM-1');

      expect(result.valueOrNull?.session.machineId, '42');
      expect(result.valueOrNull?.session.client, ClientKind.cashier);
    });

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
      'rejects sensitive business-message patterns with a generic fallback',
      () async {
        final unsafeMessages = <String>[
          '请联系 13812345678',
          '请联系 +86 138 1234 5678',
          'Call +1 (415) 555-2671',
          '银行卡 6222021234567890',
          'payment code 123456',
          'auth code 654321',
          '支付码 123456',
          '<b>终端授权失败</b>',
          '终端授权失败\nstack',
        ];

        for (final message in unsafeMessages) {
          final adapter = _StubAdapter(
            (_) => _jsonBody(<String, Object?>{'code': 27, 'msg': message}),
          );

          final result = await _api(adapter: adapter)
              .authorizeMachine('TERM-1');

          expect(
            result.failureOrNull?.safeMessage,
            '终端授权失败，请检查授权码',
            reason: message,
          );
        }
      },
    );

    test('preserves an ordinary bounded Chinese business message', () async {
      const message = '该终端已停用，请联系管理员';
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{'code': 27, 'msg': message}),
      );

      final result = await _api(adapter: adapter).authorizeMachine('TERM-1');

      expect(result.failureOrNull?.safeMessage, message);
    });

    test(
      'rejects nonintegral, nonfinite, bool, and padded success codes',
      () async {
        for (final code in <Object>[1.5, true, ' 1', '01']) {
          final adapter = _StubAdapter(
            (_) => _jsonBody(<String, Object?>{
              'code': code,
              'msg': 'Ordinary rejection',
            }),
          );

          final result = await _api(adapter: adapter)
              .authorizeMachine('TERM-1');

          expect(result.failureOrNull?.code, 'business.term_auth_rejected');
        }

        final adapter = _StubAdapter(
          (_) => _jsonBody(<String, Object?>{'code': 2}),
        );
        final nonfinite = await _api(
          adapter: adapter,
          decodedResponse: <String, Object?>{'code': double.nan},
        ).authorizeMachine('TERM-1');
        expect(nonfinite.failureOrNull?.code, 'protocol.invalid_top_level');
      },
    );

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
            'emp_id': 'EMP-A7',
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
          employeeId: 'EMP-A7',
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

    test('accepts integral numeric success code for card login', () async {
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{
          'code': 1.0,
          'data': <String, Object?>{
            'emp_id': '8',
            'name': 'Synthetic Employee',
            'station_id': 9,
          },
        }),
      );

      final result = await _api(adapter: adapter).login(
        machine: machine,
        account: 'CARD-8',
        password: 'synthetic-card-password',
        type: EmployeeLoginType.card,
      );

      expect((adapter.requests.single.data as Map)['pt'], 2);
      expect(result, isA<Success<UserSession>>());
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

    test('rejects nonintegral and malformed user response fields', () async {
      final invalidData = <Map<String, Object?>>[
        <String, Object?>{'emp_id': 1.5, 'name': 'Employee', 'station_id': 2},
        <String, Object?>{'emp_id': 1, 'name': '', 'station_id': 2},
        <String, Object?>{'emp_id': 1, 'name': 'Employee', 'station_id': 2.5},
        <String, Object?>{'emp_id': true, 'name': 'Employee', 'station_id': 2},
        <String, Object?>{
          'emp_id': 9007199254740992,
          'name': 'Employee',
          'station_id': 2,
        },
        <String, Object?>{'emp_id': '', 'name': 'Employee', 'station_id': 2},
        <String, Object?>{
          'emp_id': 'EMP\u0000A7',
          'name': 'Employee',
          'station_id': 2,
        },
        <String, Object?>{
          'emp_id': List<String>.filled(129, 'x').join(),
          'name': 'Employee',
          'station_id': 2,
        },
        <String, Object?>{
          'emp_id': 1,
          'name': 'Employee',
          'station_id': 'station\n9',
        },
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

    test('normalizes integral numeric employee and station ids', () async {
      final adapter = _StubAdapter(
        (_) => _jsonBody(<String, Object?>{
          'code': 1,
          'data': <String, Object?>{
            'emp_id': 88.0,
            'name': 'Employee',
            'station_id': 9.0,
          },
        }),
      );

      final result = await _api(adapter: adapter).login(
        machine: machine,
        account: 'employee',
        password: 'synthetic-password',
        type: EmployeeLoginType.account,
      );

      expect(result.valueOrNull?.employeeId, '88');
      expect(result.valueOrNull?.stationId, '9');
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
        (_) => _jsonBody(<String, Object?>{'code': 1.0}),
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
      'uses only the repository credential store for authorization',
      () async {
        final protocolStore = _AtomicCredentialStore();
        final repositoryStore = _AtomicCredentialStore();
        final adapter = _StubAdapter(
          (_) => _jsonBody(<String, Object?>{
            'code': 1,
            'data': <String, Object?>{
              'tk': 'synthetic-repository-tk',
              'am': 8,
              'id': 1,
              'n': 'Counter',
            },
          }),
        );
        final repository = SessionRepository(
          api: _api(adapter: adapter, credentialStore: protocolStore),
          credentialStore: repositoryStore,
        );
        addTearDown(repository.close);

        final result = await repository.authorizeMachine('TERM-1');

        expect(result, isA<Success<MachineSession>>());
        expect(await protocolStore.readTk(), isNull);
        expect(await repositoryStore.readTk(), 'synthetic-repository-tk');
        expect(protocolStore.writeTkCalls, 0);
        expect(repositoryStore.writeTkCalls, 1);
      },
    );

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

        api.authorizeResult = _authorized(
          machine1,
          tk: 'synthetic-machine-1-tk',
        );
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
        expect(await store.readTk(), 'synthetic-machine-1-tk');
        expect(store.writeTkCalls, 1);

        api.authorizeResult = _authorized(
          machine2,
          tk: 'synthetic-machine-2-tk',
        );
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
      'credential write failure does not commit a machine session',
      () async {
        final store = _AtomicCredentialStore(failure: _StoreFailure.writeTk);
        final repository = SessionRepository(
          api: _FakeSessionApi()
            ..authorizeResult = _authorized(
              const MachineSession(
                machineId: 'machine-1',
                machineName: 'Counter',
                client: ClientKind.cashier,
              ),
              tk: 'synthetic-unwritten-tk',
            ),
          credentialStore: store,
        );
        addTearDown(repository.close);

        final result = await repository.authorizeMachine('TERM-1');

        expect(
          result.failureOrNull?.code,
          'authentication.credentials_unavailable',
        );
        expect(repository.currentMachine, isNull);
        expect(repository.currentUser, isNull);
        expect(_failureText(result), isNot(contains('synthetic-unwritten-tk')));
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
        final pending = Completer<Result<MachineAuthorization>>();
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
          _authorized(
            const MachineSession(
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
        final pending = Completer<Result<MachineAuthorization>>();
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
          _authorized(
            const MachineSession(
              machineId: 'machine-1',
              machineName: 'Counter',
              client: ClientKind.cashier,
            ),
          ),
        );
        await authorization;
      },
    );

    test('close during credential write removes the orphan token', () async {
      final writeGate = Completer<void>();
      final store = _AtomicCredentialStore(writeTkGate: writeGate);
      final repository = SessionRepository(
        api: _FakeSessionApi()
          ..authorizeResult = _authorized(
            const MachineSession(
              machineId: 'machine-1',
              machineName: 'Counter',
              client: ClientKind.cashier,
            ),
            tk: 'synthetic-close-race-tk',
          ),
        credentialStore: store,
      );

      final authorization = repository.authorizeMachine('TERM-1');
      await store.writeTkStarted.future;
      await repository.close();
      writeGate.complete();
      final result = await authorization;

      expect(result.failureOrNull?.code, 'session.repository_closed');
      expect(repository.currentMachine, isNull);
      expect(repository.currentUser, isNull);
      expect(await store.readTk(), isNull);
      expect(store.clearTkIfMatchesCalls, 1);
      expect(_failureText(result), isNot(contains('synthetic-close-race-tk')));
    });

    test(
      'close race reports credentials_not_cleared when compensation fails',
      () async {
        final writeGate = Completer<void>();
        final store = _AtomicCredentialStore(
          failure: _StoreFailure.clearTk,
          writeTkGate: writeGate,
        );
        final repository = SessionRepository(
          api: _FakeSessionApi()
            ..authorizeResult = _authorized(
              const MachineSession(
                machineId: 'machine-1',
                machineName: 'Counter',
                client: ClientKind.cashier,
              ),
              tk: 'synthetic-residual-race-tk',
            ),
          credentialStore: store,
        );

        final authorization = repository.authorizeMachine('TERM-1');
        await store.writeTkStarted.future;
        await repository.close();
        writeGate.complete();
        final result = await authorization;

        expect(result.failureOrNull?.kind, FailureKind.authentication);
        expect(result.failureOrNull?.code, 'session.credentials_not_cleared');
        expect(repository.isClosed, isTrue);
        expect(repository.currentMachine, isNull);
        expect(repository.currentUser, isNull);
        expect(store.clearTkIfMatchesCalls, 1);
        expect(await store.readTk(), 'synthetic-residual-race-tk');
        expect(
          _failureText(result),
          isNot(contains('synthetic-residual-race-tk')),
        );
      },
    );

    test(
      'successful reauthorization clears a user even for the same machine',
      () async {
        const machine = MachineSession(
          machineId: 'machine-1',
          machineName: 'Counter',
          client: ClientKind.cashier,
        );
        final api = _FakeSessionApi()..authorizeResult = _authorized(machine);
        final repository = SessionRepository(
          api: api,
          credentialStore: _AtomicCredentialStore(),
        );
        addTearDown(repository.close);
        await repository.authorizeMachine('TERM-1');
        api.loginResult = const Success(
          UserSession(
            employeeId: 'employee-1',
            name: 'Employee',
            stationId: 'station-1',
          ),
        );
        await repository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
        api.authorizeResult = _authorized(machine, tk: 'synthetic-new-tk');

        await repository.authorizeMachine('TERM-1');

        expect(repository.currentMachine, machine);
        expect(repository.currentUser, isNull);
      },
    );

    test(
      'logout returns remote failure but clears local state and matching tk',
      () async {
        final api = _FakeSessionApi();
        final store = _AtomicCredentialStore(tk: 'synthetic-machine-tk');
        final repository = SessionRepository(api: api, credentialStore: store);
        addTearDown(repository.close);
        api.authorizeResult = _authorized(
          const MachineSession(
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

    test('snapshot failure clears only the repository tk and reports unconfirmed cleanup', () async {
      final api = _FakeSessionApi();
      final store = _AtomicCredentialStore(
        tk: 'synthetic-fallback-tk',
        stk: 'synthetic-fallback-stk',
        failure: _StoreFailure.readSnapshot,
      );
      final repository = SessionRepository(api: api, credentialStore: store);
      addTearDown(repository.close);
      api.authorizeResult = _authorized(
        const MachineSession(
          machineId: 'machine-1',
          machineName: 'Counter',
          client: ClientKind.cashier,
        ),
      );
      api.logoutResult = const FailureResult(
        AppFailure(
          kind: FailureKind.network,
          code: 'network.timeout',
          safeMessage: 'Request timed out',
        ),
      );
      await repository.authorizeMachine('TERM-1');

      final result = await repository.logout();

      expect(result.failureOrNull?.code, 'session.credentials_not_cleared');
      expect(repository.currentMachine, isNull);
      expect(repository.currentUser, isNull);
      expect(store.clearTkCalls, 0);
      expect(store.clearStkCalls, 0);
      expect(store.clearTkIfMatchesCalls, 1);
      expect(await store.readTk(), isNull);
      expect(await store.readStk(), 'synthetic-fallback-stk');
      expect(_failureText(result), isNot(contains('synthetic-fallback-tk')));
      expect(_failureText(result), isNot(contains('synthetic-fallback-stk')));
    });

    test(
      'credential cleanup failure wins over simultaneous remote failure',
      () async {
        final api = _FakeSessionApi();
        final store = _AtomicCredentialStore(
          stk: 'synthetic-old-stk',
          failure: _StoreFailure.clearTk,
        );
        final repository = SessionRepository(api: api, credentialStore: store);
        addTearDown(repository.close);
        api.authorizeResult = _authorized(
          const MachineSession(
            machineId: 'machine-1',
            machineName: 'Counter',
            client: ClientKind.cashier,
          ),
        );
        api.logoutResult = const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'network.timeout',
            safeMessage: 'Request timed out',
          ),
        );
        await repository.authorizeMachine('TERM-1');

        final result = await repository.logout();

        expect(result.failureOrNull?.code, 'session.credentials_not_cleared');
        expect(repository.currentMachine, isNull);
        expect(repository.currentUser, isNull);
        expect(store.clearTkIfMatchesCalls, 1);
        expect(store.clearStkIfMatchesCalls, 1);
        expect(await store.readStk(), isNull);
        expect(await store.readTk(), 'synthetic-authorized-tk');
        expect(
          _failureText(result),
          isNot(contains('synthetic-authorized-tk')),
        );
      },
    );

    test(
      'new credentials written during remote logout survive matching clears',
      () async {
        final store = _AtomicCredentialStore(stk: 'synthetic-old-stk');
        final api = _FakeSessionApi(
          onLogout: (_) async {
            await store.writeTk('synthetic-new-tk');
            await store.writeStk('synthetic-new-stk');
            return const Success<void>(null);
          },
        );
        final repository = SessionRepository(api: api, credentialStore: store);
        addTearDown(repository.close);
        api.authorizeResult = _authorized(
          const MachineSession(
            machineId: 'machine-1',
            machineName: 'Counter',
            client: ClientKind.cashier,
          ),
          tk: 'synthetic-old-tk',
        );
        await repository.authorizeMachine('TERM-1');

        final result = await repository.logout();

        expect(result, isA<Success<void>>());
        expect(await store.readTk(), 'synthetic-new-tk');
        expect(await store.readStk(), 'synthetic-new-stk');
        expect(store.clearTkIfMatchesCalls, 1);
        expect(store.clearStkIfMatchesCalls, 1);
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
      api.authorizeResult = _authorized(
        const MachineSession(
          machineId: 'machine-1',
          machineName: 'Counter',
          client: ClientKind.cashier,
        ),
      );
      await repository.authorizeMachine('TERM-1');

      final result = await repository.logout();

      expect(result.failureOrNull?.code, 'session.credentials_not_cleared');
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
        api.authorizeResult = _authorized(
          const MachineSession(
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

      api.authorizeResult = _authorized(
        const MachineSession(
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
      final pending = Completer<Result<MachineAuthorization>>();
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
        _authorized(
          const MachineSession(
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
        api.authorizeResult = _authorized(
          const MachineSession(
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

    test(
      'reauthorization failure retains authenticated authoritative phase',
      () async {
        const machine = MachineSession(
          machineId: 'machine-1',
          machineName: 'Counter',
          client: ClientKind.cashier,
        );
        final api = _FakeSessionApi()..authorizeResult = _authorized(machine);
        final repository = SessionRepository(
          api: api,
          credentialStore: _AtomicCredentialStore(),
        );
        addTearDown(repository.close);
        await repository.authorizeMachine('TERM-1');
        api.loginResult = const Success(
          UserSession(
            employeeId: 'employee-1',
            name: 'Employee',
            stationId: 'station-1',
          ),
        );
        await repository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
        api.authorizeResult = const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'network.unavailable',
            safeMessage: 'Network unavailable',
          ),
        );
        final container = ProviderContainer.test(
          overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
        );

        await container
            .read(loginViewModelProvider.notifier)
            .authorizeMachine('TERM-failed');

        final state = container.read(loginViewModelProvider);
        expect(state.phase, LoginPhase.failure);
        expect(state.stablePhase, LoginPhase.authenticated);
        expect(state.failure?.code, 'network.unavailable');
      },
    );

    test(
      'logout failure presents failure over authoritative idle phase',
      () async {
        const machine = MachineSession(
          machineId: 'machine-1',
          machineName: 'Counter',
          client: ClientKind.cashier,
        );
        final api = _FakeSessionApi()..authorizeResult = _authorized(machine);
        final repository = SessionRepository(
          api: api,
          credentialStore: _AtomicCredentialStore(),
        );
        addTearDown(repository.close);
        await repository.authorizeMachine('TERM-1');
        api.logoutResult = const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'network.timeout',
            safeMessage: 'Request timed out',
          ),
        );
        final container = ProviderContainer.test(
          overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
        );

        await container.read(loginViewModelProvider.notifier).logout();

        final state = container.read(loginViewModelProvider);
        expect(state.phase, LoginPhase.failure);
        expect(state.stablePhase, LoginPhase.idle);
        expect(state.failure?.code, 'network.timeout');
        expect(repository.currentMachine, isNull);
      },
    );

    test(
      'external repository login and logout update authoritative state',
      () async {
        const machine = MachineSession(
          machineId: 'machine-1',
          machineName: 'Counter',
          client: ClientKind.cashier,
        );
        final api = _FakeSessionApi()..authorizeResult = _authorized(machine);
        final repository = SessionRepository(
          api: api,
          credentialStore: _AtomicCredentialStore(),
        );
        addTearDown(repository.close);
        final container = ProviderContainer.test(
          overrides: [sessionRepositoryProvider.overrideWithValue(repository)],
        );
        container.read(loginViewModelProvider);

        await repository.authorizeMachine('TERM-1');
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(loginViewModelProvider).stablePhase,
          LoginPhase.readyForLogin,
        );

        api.loginResult = const Success(
          UserSession(
            employeeId: 'employee-1',
            name: 'Employee',
            stationId: 'station-1',
          ),
        );
        await repository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(loginViewModelProvider).stablePhase,
          LoginPhase.authenticated,
        );

        await repository.logout();
        await Future<void>.delayed(Duration.zero);
        final state = container.read(loginViewModelProvider);
        expect(state.phase, LoginPhase.idle);
        expect(state.stablePhase, LoginPhase.idle);
      },
    );

    test(
      'external operation failure recovers when repository later changes',
      () async {
        final pending = Completer<Result<MachineAuthorization>>();
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
        final externalAuthorization = repository.authorizeMachine('TERM-1');

        final result = await viewModel.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );

        expect(result.failureOrNull?.code, 'session.operation_in_progress');
        expect(
          container.read(loginViewModelProvider).phase,
          LoginPhase.failure,
        );
        expect(
          container.read(loginViewModelProvider).stablePhase,
          LoginPhase.idle,
        );
        pending.complete(
          _authorized(
            const MachineSession(
              machineId: 'machine-1',
              machineName: 'Counter',
              client: ClientKind.cashier,
            ),
          ),
        );
        await externalAuthorization;
        await Future<void>.delayed(Duration.zero);

        final recovered = container.read(loginViewModelProvider);
        expect(recovered.phase, LoginPhase.readyForLogin);
        expect(recovered.stablePhase, LoginPhase.readyForLogin);
      },
    );
  });
}

SessionApi _api({
  required _StubAdapter adapter,
  _AtomicCredentialStore? credentialStore,
  Object? decodedResponse,
}) {
  final store = credentialStore ?? _AtomicCredentialStore();
  final dio = Dio()..httpClientAdapter = adapter;
  if (decodedResponse != null) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          response.data = decodedResponse;
          handler.next(response);
        },
      ),
    );
  }
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
  return SessionApi(client: protocolClient);
}

Result<MachineAuthorization> _authorized(
  MachineSession session, {
  String tk = 'synthetic-authorized-tk',
}) => Success(MachineAuthorization(session: session, tk: tk));

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
  _FakeSessionApi({this.onAuthorize, this.onLogout});

  final Future<Result<MachineAuthorization>> Function(String code)? onAuthorize;
  final Future<Result<void>> Function(MachineSession machine)? onLogout;
  Result<MachineAuthorization> authorizeResult = const FailureResult(
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
  Future<Result<MachineAuthorization>> authorizeMachine(String code) async {
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
    return onLogout?.call(machine) ?? logoutResult;
  }
}

enum _StoreFailure { none, writeTk, readSnapshot, clearTk }

final class _AtomicCredentialStore implements CredentialStore {
  factory _AtomicCredentialStore({
    String? tk,
    String? stk,
    _StoreFailure failure = _StoreFailure.none,
    Completer<void>? writeTkGate,
  }) => _AtomicCredentialStore._(tk, stk, failure, writeTkGate);

  _AtomicCredentialStore._(this._tk, this._stk, this.failure, this.writeTkGate);

  String? _tk;
  String? _stk;
  final _StoreFailure failure;
  final Completer<void>? writeTkGate;
  final Completer<void> writeTkStarted = Completer<void>();
  Future<void> _tail = Future<void>.value();
  int writeTkCalls = 0;
  int clearTkCalls = 0;
  int clearStkCalls = 0;
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
  Future<void> clearStk() => _atomic(() {
    clearStkCalls += 1;
    _stk = null;
  });

  @override
  Future<void> clearStkIfMatches(String? expected) => _atomic(() {
    clearStkIfMatchesCalls += 1;
    if (_stk == expected) _stk = null;
  });

  @override
  Future<void> clearTk() => _atomic(() {
    clearTkCalls += 1;
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
  Future<void> writeTk(String value) => _atomic(() async {
    writeTkCalls += 1;
    if (!writeTkStarted.isCompleted) writeTkStarted.complete();
    if (writeTkGate case final gate?) await gate.future;
    if (failure == _StoreFailure.writeTk) {
      throw StateError('synthetic-store-write-failure');
    }
    _tk = value;
  });

  @override
  String toString() => '_AtomicCredentialStore()';
}
