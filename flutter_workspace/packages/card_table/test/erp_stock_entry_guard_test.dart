import 'package:card_table/src/erp_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Adapter, Credentials;
import 'bms_loader_guard_test.dart' show loginSession;
import 'erp_stock_entry_contract_test.dart' show erpApi;

void main() {
  test('ERP stock submission gates session, offline, wrong system, stale responses and uses current client header', () async {
    final adapter = Adapter(), sessionAdapter = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: erpApi(sessionAdapter).client),
      credentialStore: Credentials(),
    );
    var online = true, epoch = 1;
    final loader = ProtocolErpLoader(
      api: erpApi(adapter),
      session: session,
      isOnline: () => online,
      generation: () => epoch,
    );
    expect((await loader.createSinOrder({})).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
    await loginSession(session, sessionAdapter, 32);
    online = false;
    expect((await loader.loadSinOptions()).failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
    online = true;
    expect(
      (await loader.createSoutOrder({'store_id': 2})).failureOrNull,
      isNull,
    );
    expect(
      adapter.requests.last.headers['tt'],
      ClientKind.erp.termType.toString(),
    );
    adapter.onFetch = () => epoch++;
    expect(
      (await loader.createSinOrder({'store_id': 2})).failureOrNull,
      isNotNull,
    );
    await loginSession(session, sessionAdapter, 8);
    final count = adapter.requests.length;
    expect((await loader.createSinOrder({})).failureOrNull, isNotNull);
    expect(adapter.requests.length, count);
  });
}
