import 'dart:async';
import 'dart:typed_data';

import 'package:card_table/src/pay_order_api.dart';
import 'package:card_table/src/pay_order_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

class _PendingAdapter extends Adapter {
  final started = Completer<void>(), release = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    started.complete();
    await release.future;
    return super.fetch(options, stream, cancelFuture);
  }
}

void main() {
  test('same-account successful reauthentication invalidates old pending payment response by identity alone', () async {
    final sessionAdapter = Adapter(), adapter = _PendingAdapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(sessionAdapter).client),
      credentialStore: Credentials(),
    );
    addTearDown(session.close);
    await loginSession(session, sessionAdapter, 8);
    final first = session.currentUser;
    final loader = SessionBoundPayOrderLoader(
      session: session,
      api: ProtocolPayOrderApi(client: makeApi(adapter).client),
      phase: () => ConnectionPhase.online,
      generation: () => 1,
    );
    final pending = loader.setSettleMode(seatId: '100', settleMode: 2);
    await adapter.started.future;
    expect(
      (await session.login(
        account: 'test',
        password: 'test',
        type: EmployeeLoginType.account,
      )).failureOrNull,
      isNull,
    );
    expect(session.currentUser, first);
    expect(identical(session.currentUser, first), false);
    adapter.release.complete();
    expect(
      (await pending).failureOrNull?.code,
      'authentication.pay_order_context_changed',
    );
  });
}
