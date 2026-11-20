import 'package:card_table/src/wine_api.dart';
import 'package:card_table/src/wine_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

void main() {
  test(
    'same-account relogin invalidates form even without generation change',
    () async {
      final adapter = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(adapter).client),
        credentialStore: Credentials(),
      );
      addTearDown(session.close);
      await loginSession(session, adapter, 256);
      final loader = SessionBoundWineLoader(
        session: session,
        api: ProtocolWineApi(client: makeApi(adapter).client),
        isOnline: () => true,
        generation: () => 0,
      );
      final before = loader.borrowFormContext;
      expect(before, loader.borrowFormContext);
      final user = session.currentUser;
      final machine = session.currentMachine;
      adapter.data = {'emp_id': '1', 'name': '测试', 'station_id': '1'};
      await session.login(account:'test', password:'test', type:EmployeeLoginType.account);
      expect(identical(machine, session.currentMachine),true);
      expect(session.currentUser, user);
      expect(identical(session.currentUser, user), false);
      expect(before, isNot(loader.borrowFormContext));
    },
  );
  test('borrow read rejects epoch changes and offline never sends', () async {
    final adapter = Adapter(), sessionAdapter = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(sessionAdapter).client),
      credentialStore: Credentials(),
    );
    addTearDown(session.close);
    await loginSession(session, sessionAdapter, 256);
    var online = false, epoch = 0;
    final loader = SessionBoundWineLoader(
      session: session,
      api: ProtocolWineApi(client: makeApi(adapter).client),
      isOnline: () => online,
      generation: () => epoch,
    );
    expect(
      (await loader.loadWineBorrowEmployees('甲')).failureOrNull?.code,
      'wine.offline',
    );
    expect(adapter.requests, isEmpty);
    online = true;
    adapter.onFetch = () => epoch++;
    expect(
      (await loader.loadWineReturnOptions()).failureOrNull?.code,
      'wine.session_changed',
    );
  });
}
