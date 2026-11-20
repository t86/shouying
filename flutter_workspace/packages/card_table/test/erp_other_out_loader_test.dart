import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Adapter, Credentials;
import 'bms_loader_guard_test.dart' show loginSession;
import 'erp_stock_entry_contract_test.dart' show erpApi;

void main() {
  test('sout context changes on same-account login and blocks offline or stale requests', () async {
    final a = Adapter(), auth = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: erpApi(auth).client),
      credentialStore: Credentials(),
    );
    addTearDown(session.close);
    await loginSession(session, auth, 32);
    var online = true, epoch = 1;
    final loader = ProtocolErpLoader(
      api: erpApi(a),
      session: session,
      isOnline: () => online,
      generation: () => epoch,
    );
    final before = loader.soutContext;
    expect(before, isNotNull);
    auth.data = {'emp_id': '1', 'name': '测试', 'station_id': '1'};
    await session.login(
      account: 'test',
      password: 'test',
      type: EmployeeLoginType.account,
    );
    expect(loader.soutContext, isNot(before));
    online = false;
    expect(loader.soutContext, isNull);
    expect((await loader.reverseOtherOutWhole('1')).failureOrNull, isNotNull);
    expect(a.requests, isEmpty);
    online = true;
    a.data = {'dtls': []};
    a.onFetch = () => epoch++;
    expect(
      (await loader.loadOtherOutDocument(
        '1',
        ErpSoutDocumentMode.copy,
      )).failureOrNull?.code,
      'erp.context_changed',
    );
  });
}
