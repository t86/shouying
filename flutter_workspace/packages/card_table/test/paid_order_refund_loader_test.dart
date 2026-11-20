import 'package:card_table/src/pay_order_api.dart';
import 'package:card_table/src/pay_order_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;
import 'bms_loader_guard_test.dart' show loginSession;

void main() {
  test('paid refund loader forwards arrays while retaining session/online/generation protection', () async {
    final adapter = Adapter(), sessionAdapter = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(sessionAdapter).client),
      credentialStore: Credentials(),
    );
    var phase = ConnectionPhase.blocked, epoch = 1;
    final loader = SessionBoundPayOrderLoader(
      session: session,
      api: ProtocolPayOrderApi(client: makeApi(adapter).client),
      phase: () => phase,
      generation: () => epoch,
    );
    Future<Result<void>> refund() => loader.refundPayed(
      seatId: '100',
      payId: '71',
      orderIds: ['11'],
      counts: [2],
      amounts: ['80.25'],
      remark: '理由',
    );
    expect((await refund()).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
    await loginSession(session, sessionAdapter, 8);
    expect((await refund()).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
    phase = ConnectionPhase.online;
    expect((await refund()).failureOrNull, isNull);
    expect((adapter.requests.last.data as Map)['prd_back_cnts'], [2]);
    adapter.onFetch = () => epoch++;
    expect(
      (await refund()).failureOrNull?.code,
      'authentication.pay_order_context_changed',
    );
  });
}
