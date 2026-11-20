import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/cocktail_detail_report.dart';
import 'package:card_table/src/cocktail_detail_report_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

void main() {
  test('does not load without a machine and logged-in user', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    final loader = harness.bind((_) async => _rows());
    expect(
      (await loader.load('')).failureOrNull?.kind,
      FailureKind.authentication,
    );
    await harness.authorize();
    expect(
      (await loader.load('')).failureOrNull?.kind,
      FailureKind.authentication,
    );
    expect(harness.keywords, isEmpty);
  });

  test('does not load for a non-order terminal', () async {
    for (final client in [ClientKind.booking, ClientKind.cashier]) {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn(client: client);
      final result = await harness.bind((_) async => _rows()).load('特饮');
      expect(result.failureOrNull?.kind, FailureKind.authentication);
      expect(harness.keywords, isEmpty);
    }
  });

  test('does not load while blocked or reconciling', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final loader = harness.bind((_) async => _rows());
    for (final phase in [
      ConnectionPhase.blocked,
      ConnectionPhase.reconciling,
    ]) {
      harness.phase = phase;
      expect((await loader.load('')).failureOrNull?.kind, FailureKind.network);
    }
    expect(harness.keywords, isEmpty);
  });

  test('forwards the keyword unchanged on a stable order session', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final expected = _rows();
    final actual = await harness
        .bind((keyword) async {
          expect(keyword, ' 特饮A ');
          return expected;
        })
        .load(' 特饮A ');
    expect(identical(actual, expected), isTrue);
    expect(harness.keywords, [' 特饮A ']);
  });

  test('drops rows if logout happens during a request', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final pending = Completer<Result<List<CocktailDetailReportRow>>>();
    final result = harness.bind((_) => pending.future).load('');
    await harness.session.logout();
    pending.complete(_rows());
    _expectDiscarded(await result);
  });

  test(
    'disconnect and recover cannot replay a response from the old generation',
    () async {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn();
      final pending = Completer<Result<List<CocktailDetailReportRow>>>();
      final result = harness.bind((_) => pending.future).load('');
      harness.phase = ConnectionPhase.blocked;
      harness.generation++;
      harness.phase = ConnectionPhase.online;
      pending.complete(_rows());
      _expectDiscarded(await result);
      expect(harness.keywords, ['']);
    },
  );

  test('remote exceptions are safe failures with no automatic retry', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final failure =
        (await harness
                .bind((_) => throw StateError('private response'))
                .load(''))
            .failureOrNull!;
    expect(failure.kind, FailureKind.unknown);
    expect(failure.safeMessage, isNot(contains('private response')));
  });
}

Success<List<CocktailDetailReportRow>> _rows() => Success([
  CocktailDetailReportRow.fromWire({'n': '莫吉托'}),
]);

void _expectDiscarded(Result<List<CocktailDetailReportRow>> result) {
  expect(result.valueOrNull, isNull);
  expect(result.failureOrNull, isNotNull);
  expect(result.failureOrNull!.safeMessage, isNot(contains('莫吉托')));
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
  final List<String> keywords = [];

  SessionBoundCocktailDetailReportLoader bind(CocktailDetailLoader remote) =>
      SessionBoundCocktailDetailReportLoader(
        session: session,
        loadRemote: (keyword) {
          keywords.add(keyword);
          return remote(keyword);
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
