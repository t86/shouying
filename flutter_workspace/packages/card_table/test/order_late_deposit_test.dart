import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/order_late_deposit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

void main() {
  test('failed credential read is zero dispatch and does not poison future creation', () async {
    final session = await _session();
    final adapter = _Adapter();
    final credentials = _FailOnceCredentials();
    final loader = SessionBoundOrderLateDepositLoader(
      session: session,
      api: ProtocolOrderLateDepositApi(client: _client(adapter, credentials)),
      phase: () => ConnectionPhase.online,
      generation: () => 1,
    );
    expect(
      (await loader.create(
        seatId: '101',
        payType: 2,
        amountYuan: '10',
        canDispatch: () => true,
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests, isEmpty);
    expect(loader.needsVerification, isFalse);
    expect(
      (await loader.create(
        seatId: '101',
        payType: 2,
        amountYuan: '10',
        canDispatch: () => true,
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.length, 1);
  });
  test(
    'four source channels use yuan strings and exact late-payment endpoints',
    () async {
      final adapter = _Adapter();
      final api = ProtocolOrderLateDepositApi(client: _client(adapter));
      for (final type in [1, 2, 5, 6]) {
        final result = await api.create(
          ClientKind.order,
          seatId: '101',
          payType: type,
          amountYuan: '12.50',
          authCode: type >= 5 ? 'synthetic-code' : null,
          canDispatch: () => true,
        );
        expect(result.valueOrNull!.payDetailId, '81');
        expect(result.valueOrNull!.payUrl, 'https://pay.example.invalid/qr');
        expect(result.valueOrNull!.result, 0);
        expect(adapter.requests.last.uri.path, '/wo/do_waiter_late_olpay');
        expect(adapter.requests.last.data, {
          'seat_id': 101,
          'pay_type': type,
          'pay_amt': '12.50',
          'auth_code': type >= 5 ? 'synthetic-code' : null,
        });
      }
      adapter.data = {'status': 5};
      expect(
        (await api.status(
          ClientKind.order,
          '81',
          canDispatch: () => true,
        )).valueOrNull,
        5,
      );
      expect(
        adapter.requests.last.uri.path,
        '/wo/get_waiter_late_olpay_status',
      );
      expect(adapter.requests.last.data, {'id': 81});
    },
  );
  test('invalid amount or channel never sends and rejected response is not success', () async {
    final adapter = _Adapter();
    final api = ProtocolOrderLateDepositApi(client: _client(adapter));
    for (final amount in ['0', '-1', 'NaN', 'Infinity', '1.001', '1e2', '']) {
      expect(
        (await api.create(
          ClientKind.order,
          seatId: '101',
          payType: 2,
          amountYuan: amount,
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
    }
    expect(
      (await api.create(
        ClientKind.order,
        seatId: '101',
        payType: 7,
        amountYuan: '10',
        canDispatch: () => true,
      )).failureOrNull,
      isNotNull,
    );
    expect(
      (await api.create(
        ClientKind.order,
        seatId: '101',
        payType: 5,
        amountYuan: '10',
        canDispatch: () => true,
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests, isEmpty);
    adapter.code = 2;
    expect(
      (await api.create(
        ClientKind.order,
        seatId: '101',
        payType: 2,
        amountYuan: '10',
        canDispatch: () => true,
      )).failureOrNull?.kind,
      FailureKind.business,
    );
  });
  for (final changePage in [false, true]) {
    test(
      '${changePage ? 'page' : 'generation'} loss during credentials prevents HTTP dispatch',
      () async {
        final fixture = await _session();
        final adapter = _Adapter();
        final credentials = _DelayedCredentials();
        var epoch = 1, allowed = true;
        final loader = SessionBoundOrderLateDepositLoader(
          session: fixture,
          api: ProtocolOrderLateDepositApi(
            client: _client(adapter, credentials),
          ),
          phase: () => ConnectionPhase.online,
          generation: () => epoch,
        );
        final pending = loader.create(
          seatId: '101',
          payType: 2,
          amountYuan: '12.50',
          canDispatch: () => allowed,
        );
        await credentials.started.future;
        if (changePage) {
          allowed = false;
        } else {
          epoch++;
        }
        credentials.gate.complete();
        expect((await pending).failureOrNull, isNotNull);
        expect(adapter.requests, isEmpty);
        expect(loader.needsVerification, isFalse);
      },
    );
  }
  test('unknown creation cannot be retried; concurrent creation is mutually exclusive', () async {
    final session = await _session();
    final adapter = _Adapter()
      ..pending = Completer<void>()
      ..fail = true;
    final loader = SessionBoundOrderLateDepositLoader(
      session: session,
      api: ProtocolOrderLateDepositApi(client: _client(adapter)),
      phase: () => ConnectionPhase.online,
      generation: () => 1,
    );
    Future<Result<OrderLateDepositPayment>> create() => loader.create(
      seatId: '101',
      payType: 2,
      amountYuan: '10',
      canDispatch: () => true,
    );
    final first = create();
    await adapter.started.future;
    expect((await create()).failureOrNull, isNotNull);
    expect(adapter.requests.length, 1);
    adapter.pending!.complete();
    expect((await first).failureOrNull?.code, 'order_late.result_unknown');
    expect(loader.needsVerification, isTrue);
    expect((await create()).failureOrNull, isNotNull);
    expect(adapter.requests.length, 1);
  });
  test('offline and wrong client are rejected before transport', () async {
    final adapter = _Adapter();
    for (final mode in [4, 8]) {
      final session = await _session(mode);
      final loader = SessionBoundOrderLateDepositLoader(
        session: session,
        api: ProtocolOrderLateDepositApi(client: _client(adapter)),
        phase: () =>
            mode == 4 ? ConnectionPhase.blocked : ConnectionPhase.online,
        generation: () => 1,
      );
      expect(
        (await loader.create(
          seatId: '101',
          payType: 2,
          amountYuan: '10',
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
    }
    expect(adapter.requests, isEmpty);
  });
}

Future<SessionRepository> _session([int mode = 4]) async {
  final adapter = Adapter();
  final session = SessionRepository(
    api: SessionApi(client: makeApi(adapter).client),
    credentialStore: Credentials(),
  );
  await loginSession(session, adapter, mode);
  return session;
}

ProtocolClient _client(
  HttpClientAdapter adapter, [
  CredentialStore? credentials,
]) {
  var now = DateTime(2026);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://example.invalid'),
      onlineBase: Uri.parse('https://example.invalid'),
      websocketBase: Uri.parse('wss://example.invalid'),
    ),
    credentialStore: credentials ?? Credentials(),
    requestGate: RequestGate(
      clock: () {
        now = now.add(const Duration(seconds: 1));
        return now;
      },
    ),
  );
}

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[], started = Completer<void>();
  Object? data = {
    'pay_url': 'https://pay.example.invalid/qr',
    'pay_dtl_id': 81,
    'r': 0,
  };
  int code = 1;
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (!started.isCompleted) started.complete();
    if (pending != null) await pending!.future;
    if (fail) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'code': code, 'data': data}),
      200,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _DelayedCredentials extends Credentials {
  final started = Completer<void>(), gate = Completer<void>();
  @override
  Future<CredentialSnapshot> readSnapshot() async {
    if (!started.isCompleted) started.complete();
    await gate.future;
    return super.readSnapshot();
  }
}

class _FailOnceCredentials extends Credentials {
  bool fail = true;
  @override
  Future<CredentialSnapshot> readSnapshot() async {
    if (fail) {
      fail = false;
      throw StateError('synthetic unavailable credentials');
    }
    return super.readSnapshot();
  }
}
