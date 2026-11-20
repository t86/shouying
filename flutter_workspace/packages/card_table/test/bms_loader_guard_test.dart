import 'package:card_table/src/bms_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

void main() {
  test('missing authenticated session cannot read or write BMS', () async {
    final adapter = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(Adapter()).client),
      credentialStore: Credentials(),
    );
    final loader = ProtocolBmsLoader(
      api: makeApi(adapter),
      sessionRepository: session,
    );
    expect((await loader.loadGenRule()).failureOrNull, isNotNull);
    expect((await loader.batchResetEmpPwd(['1'])).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });
  test(
    'online org manager only; generation changed during request is rejected',
    () async {
      final adapter = Adapter();
      final sessionAdapter = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(sessionAdapter).client),
        credentialStore: Credentials(),
      );
      await loginSession(session, sessionAdapter, 1);
      var online = false, epoch = 1;
      final loader = ProtocolBmsLoader(
        api: makeApi(adapter),
        sessionRepository: session,
        phase: () => online ? ConnectionPhase.online : ConnectionPhase.blocked,
        generation: () => epoch,
      );
      expect((await loader.batchResetEmpPwd(['1'])).failureOrNull, isNotNull);
      expect(adapter.requests, isEmpty);
      online = true;
      expect((await loader.batchResetEmpPwd(['1'])).failureOrNull, isNull);
      adapter.onFetch = () => epoch++;
      expect((await loader.batchResetEmpPwd(['1'])).failureOrNull, isNotNull);
      await loginSession(session, sessionAdapter, 8);
      final count = adapter.requests.length;
      expect((await loader.batchResetEmpPwd(['1'])).failureOrNull, isNotNull);
      expect(adapter.requests.length, count);
    },
  );
}

Future<void> loginSession(
  SessionRepository session,
  Adapter adapter,
  int mode,
) async {
  adapter.data = {'id': '1', 'n': '测试', 'am': mode, 'tk': 'test'};
  expect((await session.authorizeMachine('test')).failureOrNull, isNull);
  adapter.data = {'emp_id': '1', 'name': '测试', 'station_id': '1'};
  expect(
    (await session.login(
      account: 'test',
      password: 'test',
      type: EmployeeLoginType.account,
    )).failureOrNull,
    isNull,
  );
}
