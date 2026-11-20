import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/minimum_consumption_report.dart';
import 'package:card_table/src/minimum_consumption_report_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

void main() {
  test('does not load without a machine and logged-in user', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    final loader = harness.bind(() async => _rows());
    expect(
      (await loader.load()).failureOrNull?.kind,
      FailureKind.authentication,
    );
    await harness.authorize();
    expect(
      (await loader.load()).failureOrNull?.kind,
      FailureKind.authentication,
    );
    expect(harness.loads, 0);
  });

  test('does not load for a non-order terminal', () async {
    for (final client in [ClientKind.booking, ClientKind.cashier]) {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn(client: client);
      final result = await harness.bind(() async => _rows()).load();
      expect(result.failureOrNull?.kind, FailureKind.authentication);
      expect(harness.loads, 0);
    }
  });

  test('does not load while blocked or reconciling', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final loader = harness.bind(() async => _rows());
    for (final phase in [
      ConnectionPhase.blocked,
      ConnectionPhase.reconciling,
    ]) {
      harness.phase = phase;
      expect((await loader.load()).failureOrNull?.kind, FailureKind.network);
    }
    expect(harness.loads, 0);
  });

  test(
    'returns the result unchanged for an online stable order session',
    () async {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn();
      final expected = _rows();
      final actual = await harness.bind(() async => expected).load();
      expect(identical(actual, expected), isTrue);
      expect(actual.valueOrNull!.single.cells[4], '报表订位人');
      expect(harness.loads, 1);
    },
  );

  test(
    'passes typed transport or business failures through without retrying',
    () async {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn();
      for (final kind in [
        FailureKind.network,
        FailureKind.business,
        FailureKind.protocol,
      ]) {
        final expected = FailureResult<List<MinimumConsumptionReportRow>>(
          AppFailure(
            kind: kind,
            code: 'test.safe_failure',
            safeMessage: '可安全显示的错误',
          ),
        );
        final actual = await harness.bind(() async => expected).load();
        expect(identical(actual, expected), isTrue);
      }
      expect(harness.loads, 3);
    },
  );

  test('drops rows if logout happens during a request', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
    final result = harness.bind(() => pending.future).load();
    await harness.session.logout();
    pending.complete(_rows());
    _expectDiscarded(await result);
  });

  test(
    'value-equal same-account re-login does not revive the old response',
    () async {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn();
      final originalUser = harness.session.currentUser!;
      final originalMachine = harness.session.currentMachine!;
      final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
      final result = harness.bind(() => pending.future).load();
      await harness.session.logout();
      await harness.signIn();
      expect(harness.session.currentUser, originalUser);
      expect(harness.session.currentMachine, originalMachine);
      expect(identical(harness.session.currentUser, originalUser), isFalse);
      expect(
        identical(harness.session.currentMachine, originalMachine),
        isFalse,
      );
      pending.complete(_rows());
      _expectDiscarded(await result);
    },
  );

  test('drops rows after changing employees on the same terminal', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final machine = harness.session.currentMachine;
    final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
    final result = harness.bind(() => pending.future).load();
    harness.adapter.employeeId = 'employee-2';
    await harness.login();
    expect(identical(harness.session.currentMachine, machine), isTrue);
    pending.complete(_rows());
    _expectDiscarded(await result);
  });

  test('drops rows after changing terminals and signing in again', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
    final result = harness.bind(() => pending.future).load();
    harness.adapter.machineId = 'machine-2';
    await harness.signIn();
    pending.complete(_rows());
    _expectDiscarded(await result);
  });

  test(
    'drops rows when the read generation changes while still online',
    () async {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn();
      final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
      final result = harness.bind(() => pending.future).load();
      harness.generation++;
      pending.complete(_rows());
      _expectDiscarded(await result);
    },
  );

  test('drops rows if the connection is not online at completion', () async {
    for (final phase in [
      ConnectionPhase.blocked,
      ConnectionPhase.reconciling,
    ]) {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn();
      final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
      final result = harness.bind(() => pending.future).load();
      harness.phase = phase;
      pending.complete(_rows());
      _expectDiscarded(await result);
    }
  });

  test(
    'disconnect and recover cannot replay a response from the old generation',
    () async {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn();
      final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
      final result = harness.bind(() => pending.future).load();
      harness.phase = ConnectionPhase.blocked;
      harness.generation++;
      harness.phase = ConnectionPhase.online;
      pending.complete(_rows());
      _expectDiscarded(await result);
      expect(harness.loads, 1);
    },
  );

  test('closing the session invalidates pending reads', () async {
    final harness = _Harness();
    await harness.signIn();
    final pending = Completer<Result<List<MinimumConsumptionReportRow>>>();
    final result = harness.bind(() => pending.future).load();
    await harness.session.close();
    pending.complete(_rows());
    _expectDiscarded(await result);
  });

  test('remote exceptions are safe failures with no automatic retry', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final failure =
        (await harness.bind(() => throw StateError('private response')).load())
            .failureOrNull!;
    expect(failure.kind, FailureKind.unknown);
    expect(failure.safeMessage, isNot(contains('private response')));
    expect(harness.loads, 1);
  });

  test('exceptions from either state provider are safe failures', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    for (final phaseThrows in [true, false]) {
      var calls = 0;
      final loader = SessionBoundMinimumConsumptionReportLoader(
        session: harness.session,
        loadRemote: () async {
          calls++;
          return _rows();
        },
        phase: () => phaseThrows
            ? throw StateError('private response')
            : ConnectionPhase.online,
        generation: () =>
            phaseThrows ? 0 : throw StateError('private response'),
      );
      final failure = (await loader.load()).failureOrNull!;
      expect(failure.kind, FailureKind.unknown);
      expect(failure.safeMessage, isNot(contains('private response')));
      expect(calls, 0);
    }
  });
}

Success<List<MinimumConsumptionReportRow>> _rows() => Success([
  MinimumConsumptionReportRow.fromWire({'se': '报表订位人'}),
]);

void _expectDiscarded(Result<List<MinimumConsumptionReportRow>> result) {
  expect(result.valueOrNull, isNull);
  expect(result.failureOrNull, isNotNull);
  expect(result.failureOrNull!.safeMessage, isNot(contains('报表订位人')));
}

final class _Harness {
  _Harness() {
    var now = DateTime.utc(2026, 8, 31);
    final store = _CredentialStore();
    session = SessionRepository(
      api: SessionApi(
        client: ProtocolClient(
          dio: Dio()..httpClientAdapter = adapter,
          config: ApiConfig(
            apiBase: Uri.parse('https://api.example.test/server'),
            onlineBase: Uri.parse('https://online.example.test/server'),
            websocketBase: Uri.parse('wss://socket.example.test/server'),
          ),
          credentialStore: store,
          requestGate: RequestGate(
            clock: () {
              now = now.add(const Duration(milliseconds: 101));
              return now;
            },
          ),
        ),
      ),
      credentialStore: store,
    );
  }

  final _SessionAdapter adapter = _SessionAdapter();
  late final SessionRepository session;
  ConnectionPhase phase = ConnectionPhase.online;
  int generation = 0;
  int loads = 0;

  SessionBoundMinimumConsumptionReportLoader bind(
    MinimumConsumptionLoader remote,
  ) => SessionBoundMinimumConsumptionReportLoader(
    session: session,
    loadRemote: () {
      loads++;
      return remote();
    },
    phase: () => phase,
    generation: () => generation,
  );

  Future<void> authorize() async {
    expect((await session.authorizeMachine('test-code')).failureOrNull, isNull);
  }

  Future<void> login() async {
    expect(
      (await session.login(
        account: 'employee',
        password: 'synthetic-password',
        type: EmployeeLoginType.account,
      )).failureOrNull,
      isNull,
    );
  }

  Future<void> signIn({ClientKind client = ClientKind.order}) async {
    adapter.client = client;
    await authorize();
    await login();
  }
}

final class _SessionAdapter implements HttpClientAdapter {
  ClientKind client = ClientKind.order;
  String machineId = 'machine-1';
  String employeeId = 'employee-1';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) await requestStream.drain<void>();
    final data = switch (options.uri.path) {
      '/server/term/auth' => <String, Object?>{
        'id': machineId,
        'n': 'Synthetic terminal',
        'am': client.termType,
        'tk': 'test-tk',
      },
      '/server/auth/login' => <String, Object?>{
        'emp_id': employeeId,
        'name': 'Synthetic employee',
        'station_id': 'station-1',
      },
      '/server/auth/logout' => <String, Object?>{},
      _ => throw StateError('Unexpected test route'),
    };
    return ResponseBody.fromString(
      jsonEncode({'code': 1, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _CredentialStore implements CredentialStore {
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
