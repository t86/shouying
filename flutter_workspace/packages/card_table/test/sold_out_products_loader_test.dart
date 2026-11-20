import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/sold_out_products.dart';
import 'package:card_table/src/sold_out_products_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

void main() {
  test('does not list without a machine and logged-in user', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    final loader = harness.bind();
    expect(
      (await loader.list()).failureOrNull?.kind,
      FailureKind.authentication,
    );
    await harness.authorize();
    expect(
      (await loader.list()).failureOrNull?.kind,
      FailureKind.authentication,
    );
    expect(harness.lists, 0);
  });

  test('does not mutate for a non-order terminal', () async {
    for (final client in [ClientKind.booking]) {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn(client: client);
      final loader = harness.bind();
      expect(
        (await loader.list()).failureOrNull?.kind,
        FailureKind.authentication,
      );
      expect(
        (await loader.set(productId: '11', count: 1)).failureOrNull?.kind,
        FailureKind.authentication,
      );
      expect(
        (await loader.delete('11')).failureOrNull?.kind,
        FailureKind.authentication,
      );
      expect(harness.lists, 0);
      expect(harness.sets, isEmpty);
      expect(harness.deletes, isEmpty);
    }
  });

  test(
    'cashier can maintain sale limits with its own terminal identity',
    () async {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn(client: ClientKind.cashier);
      final loader = harness.bind();
      expect((await loader.list()).valueOrNull, hasLength(1));
      expect(
        (await loader.set(productId: '11', count: 2)).failureOrNull,
        isNull,
      );
      expect((await loader.delete('11')).failureOrNull, isNull);
      expect(harness.lists, 1);
      expect(harness.sets, [
        ['11', 2],
      ]);
      expect(harness.deletes, ['11']);
      harness.phase = ConnectionPhase.blocked;
      expect((await loader.list()).failureOrNull?.kind, FailureKind.network);
      expect(harness.lists, 1);
    },
  );

  test('does not load while blocked or reconciling', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final loader = harness.bind();
    for (final phase in [
      ConnectionPhase.blocked,
      ConnectionPhase.reconciling,
    ]) {
      harness.phase = phase;
      expect((await loader.list()).failureOrNull?.kind, FailureKind.network);
    }
    expect(harness.lists, 0);
  });

  test('forwards list set and delete on a stable order session', () async {
    final harness = _Harness();
    addTearDown(harness.session.close);
    await harness.signIn();
    final loader = harness.bind();
    expect((await loader.list()).valueOrNull, hasLength(1));
    expect((await loader.set(productId: '11', count: 2)).failureOrNull, isNull);
    expect((await loader.delete('11')).failureOrNull, isNull);
    expect(harness.lists, 1);
    expect(harness.sets, [
      ['11', 2],
    ]);
    expect(harness.deletes, ['11']);
  });

  test(
    'drops an in-flight list if logout happens during the request',
    () async {
      final harness = _Harness();
      addTearDown(harness.session.close);
      await harness.signIn();
      final pending = Completer<Result<List<SoldOutItem>>>();
      final result = harness.bind(onList: () => pending.future).list();
      await harness.session.logout();
      pending.complete(
        Success([
          SoldOutItem.fromWire({'id': '11', 'n': '莫吉托', 'c': 1}),
        ]),
      );
      final discarded = await result;
      expect(discarded.valueOrNull, isNull);
      expect(discarded.failureOrNull?.safeMessage, isNot(contains('莫吉托')));
    },
  );
}

final class _Harness {
  _Harness() {
    var now = DateTime.utc(2026, 9, 8);
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
  int lists = 0;
  final List<List<Object>> sets = [];
  final List<String> deletes = [];

  SessionBoundSoldOutProductsLoader bind({
    Future<Result<List<SoldOutItem>>> Function()? onList,
  }) => SessionBoundSoldOutProductsLoader(
    session: session,
    listRemote: (client) {
      lists++;
      return onList?.call() ??
          Future.value(
            Success([
              SoldOutItem.fromWire({'id': '11', 'n': '莫吉托', 'c': 1}),
            ]),
          );
    },
    setRemote:
        ({
          required ClientKind client,
          required bool Function() canDispatch,
          required String productId,
          required int count,
        }) async {
          expect(client, session.currentMachine!.client);
          expect(canDispatch(), isTrue);
          sets.add([productId, count]);
          return const Success(null);
        },
    deleteRemote:
        (
          productId, {
          required ClientKind client,
          required bool Function() canDispatch,
        }) async {
          expect(client, session.currentMachine!.client);
          expect(canDispatch(), isTrue);
          deletes.add(productId);
          return const Success(null);
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

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) await requestStream.drain<void>();
    final data = switch (options.uri.path) {
      '/server/term/auth' => <String, Object?>{
        'id': 'machine-1',
        'n': 'Synthetic terminal',
        'am': client.termType,
        'tk': 'test-tk',
      },
      '/server/auth/login' => <String, Object?>{
        'emp_id': 'employee-1',
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
