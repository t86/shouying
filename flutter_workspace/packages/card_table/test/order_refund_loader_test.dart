import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/order_meal_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;
import 'bms_loader_guard_test.dart' show loginSession;

void main() {
  test('refund authorization and amount check preserve online-session generation guard', () async {
    final adapter = Adapter(), sessionAdapter = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(sessionAdapter).client),
      credentialStore: Credentials(),
    );
    var phase = ConnectionPhase.blocked, epoch = 1;
    final loader = SessionBoundOrderMealLoader(
      session: session,
      api: ProtocolOrderMealApi(client: makeApi(adapter).client),
      phase: () => phase,
      generation: () => epoch,
    );
    expect((await loader.checkOrderAmounts('100')).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
    await loginSession(session, sessionAdapter, 4);
    expect(
      (await loader.refundOrder(
        seatId: '100',
        orderId: '11',
        count: 1,
        amount: '',
        remark: '理由',
        online: false,
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests, isEmpty);
    phase = ConnectionPhase.online;
    adapter.code = 2;
    expect((await loader.checkOrderAmounts('100')).valueOrNull, isFalse);
    final auth = await loader.refundOrder(
      seatId: '100',
      orderId: '11',
      count: 1,
      amount: '',
      remark: '理由',
      online: false,
      authEmpCode: '0012',
      authEmpPasswd: 'password',
    );
    expect(auth.failureOrNull?.code, orderRefundAuthorizationRequiredCode);
    expect(
      (adapter.requests.last.data as Map)['auth_emp_passwd'],
      '5F4DCC3B5AA765D61D8327DEB882CF99',
    );
    adapter.onFetch = () => epoch++;
    final stale = await loader.refundOrder(
      seatId: '100',
      orderId: '11',
      count: 1,
      amount: '',
      remark: '理由',
      online: false,
    );
    expect(
      stale.failureOrNull?.code,
      'authentication.order_meal_context_changed',
    );
  });
}
