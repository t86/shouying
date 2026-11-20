import 'package:card_table/src/vip_recharge.dart';
import 'package:card_table/src/vip_recharge_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;
import 'bms_loader_guard_test.dart' show loginSession;

const body = <String, Object?>{
  'mode': 1,
  'id': 1,
  'deposit_amt': 10001,
  'free_amt': 0,
  'free_pt_amt': 0,
  'free_kq_id': 0,
  'sales_emp_id': 2,
  'remark': '',
};
void main() {
  test(
    'cashier entry keeps cashier client instead of hardcoded order',
    () async {
      final auth = Adapter(), adapter = Adapter()..data = {'records': []};
      final session = SessionRepository(
        api: SessionApi(client: makeApi(auth).client),
        credentialStore: Credentials(),
      );
      await loginSession(session, auth, 8);
      final loader = SessionBoundVipRechargeLoader(
        session: session,
        api: ProtocolVipRechargeApi(client: makeApi(adapter).client),
        phase: () => ConnectionPhase.online,
        generation: () => 1,
      );
      expect((await loader.search('1234')).failureOrNull, isNull);
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.headers['tt'], '8');
    },
  );
  test('create order credential-window revocation prevents dispatch', () async {
    final auth = Adapter(),
        adapter = Adapter()..data = {'order_id': 'o', 'pay_id': 'p'};
    final session = SessionRepository(
      api: SessionApi(client: makeApi(auth).client),
      credentialStore: Credentials(),
    );
    await loginSession(session, auth, 4);
    var epoch = 1;
    final loader = SessionBoundVipRechargeLoader(
      session: session,
      api: ProtocolVipRechargeApi(client: makeApi(adapter).client),
      phase: () => ConnectionPhase.online,
      generation: () => epoch,
    );
    final pending = loader.createOrder(body);
    epoch++;
    expect((await pending).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });
  test(
    'created order reserves loader against a reconstructed page creating again',
    () async {
      final auth = Adapter(),
          adapter = Adapter()..data = {'order_id': 'o', 'pay_id': 'p'};
      final session = SessionRepository(
        api: SessionApi(client: makeApi(auth).client),
        credentialStore: Credentials(),
      );
      await loginSession(session, auth, 4);
      final loader = SessionBoundVipRechargeLoader(
        session: session,
        api: ProtocolVipRechargeApi(client: makeApi(adapter).client),
        phase: () => ConnectionPhase.online,
        generation: () => 1,
      );
      expect((await loader.createOrder(body)).failureOrNull, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      expect((await loader.createOrder(body)).failureOrNull, isNotNull);
      expect(adapter.requests, hasLength(1));
    },
  );
}
