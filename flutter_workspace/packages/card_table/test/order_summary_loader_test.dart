import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/card_table.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

void main() {
  test(
    'order summary uses guarded online session and discards changed context',
    () async {
      final adapter = _Adapter();
      final credentials = _Credentials();
      var now = DateTime.utc(2026, 9, 20);
      final client = ProtocolClient(
        dio: Dio()..httpClientAdapter = adapter,
        config: ApiConfig(
          apiBase: Uri.parse('https://test.invalid/server'),
          onlineBase: Uri.parse('https://test.invalid/server'),
          websocketBase: Uri.parse('wss://test.invalid/server'),
        ),
        credentialStore: credentials,
        requestGate: RequestGate(
          clock: () => now = now.add(const Duration(seconds: 1)),
        ),
      );
      final session = SessionRepository(
        api: SessionApi(client: client),
        credentialStore: credentials,
      );
      addTearDown(session.close);
      var phase = ConnectionPhase.online;
      var generation = 0;
      final loader = SessionBoundOrderMealLoader(
        session: session,
        api: ProtocolOrderMealApi(client: client),
        phase: () => phase,
        generation: () => generation,
      );
      expect(
        (await loader.listOrdersWithSummary(
          seatId: '100',
          turnoverCount: 1,
        )).failureOrNull?.kind,
        FailureKind.authentication,
      );
      expect(adapter.orderReads, 0);
      expect(
        (await session.authorizeMachine('synthetic')).failureOrNull,
        isNull,
      );
      expect(
        (await session.login(
          account: '1',
          password: 'synthetic',
          type: EmployeeLoginType.account,
        )).failureOrNull,
        isNull,
      );
      phase = ConnectionPhase.blocked;
      expect(
        (await loader.listOrdersWithSummary(
          seatId: '100',
          turnoverCount: 1,
        )).failureOrNull?.kind,
        FailureKind.network,
      );
      expect(adapter.orderReads, 0);
      phase = ConnectionPhase.online;
      final value = (await loader.listOrdersWithSummary(
        seatId: '100',
        turnoverCount: 1,
      )).valueOrNull;
      expect(value?.summary?.notPayAmt, '7.00');
      expect(adapter.orderReads, 1);
      adapter.onRead = () => generation++;
      final stale = await loader.listOrdersWithSummary(
        seatId: '100',
        turnoverCount: 1,
      );
      expect(stale.valueOrNull, isNull);
      expect(
        stale.failureOrNull?.code,
        'authentication.order_meal_context_changed',
      );
    },
  );
}

final class _Adapter implements HttpClientAdapter {
  int orderReads = 0;
  void Function()? onRead;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    final Object data;
    switch (options.uri.path) {
      case '/server/term/auth':
        data = {
          'id': 1,
          'n': 'test',
          'am': ClientKind.order.termType,
          'tk': 'synthetic',
        };
      case '/server/auth/login':
        data = {'emp_id': 1, 'name': 'test', 'station_id': 1};
      case '/server/auth/logout':
        data = {};
      case '/server/wo/list':
        orderReads++;
        onRead?.call();
        data = {
          'orders': [],
          'pay_info': {'order_amt': 1000, 'payed_amt': 300},
        };
      default:
        throw StateError('Unexpected route ${options.uri.path}');
    }
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

final class _Credentials implements CredentialStore {
  String? tk, stk;
  @override
  Future<void> clearStk() async => stk = null;
  @override
  Future<void> clearTk() async => tk = null;
  @override
  Future<void> clearStkIfMatches(String? expected) async {
    if (stk == expected) stk = null;
  }

  @override
  Future<void> clearTkIfMatches(String? expected) async {
    if (tk == expected) tk = null;
  }

  @override
  Future<String?> readStk() async => stk;
  @override
  Future<String?> readTk() async => tk;
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      CredentialSnapshot(tk: tk, stk: stk);
  @override
  Future<void> writeStk(String value) async => stk = value;
  @override
  Future<void> writeTk(String value) async => tk = value;
}
