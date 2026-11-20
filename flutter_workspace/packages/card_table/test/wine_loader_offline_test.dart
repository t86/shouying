import 'package:card_table/src/wine_api.dart';
import 'package:card_table/src/wine_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

void main() {
  for (final online in <bool?>[false, true, null]) {
    test('Wine read/write online=$online respects explicit offline only', () async {
      final adapter = Adapter();
      final client = makeApi(adapter).client;
      final session = SessionRepository(
        api: SessionApi(client: client),
        credentialStore: Credentials(),
      );
      addTearDown(session.close);
      await loginSession(session, adapter, 256);
      adapter.requests.clear();
      adapter.data = [];
      final loader = SessionBoundWineLoader(
        session: session,
        api: ProtocolWineApi(client: client),
        isOnline: online == null ? null : () => online,
      );
      final read = await loader.loadSaveNeedToLib();
      final write = await loader.confirmSaveNeedToLib(['1']);
      if (online == false) {
        expect(read.failureOrNull?.code, 'wine.offline');
        expect(write.failureOrNull?.code, 'wine.offline');
        expect(adapter.requests, isEmpty);
      } else {
        expect(read.failureOrNull, isNull);
        expect(write.failureOrNull, isNull);
        expect(adapter.requests, hasLength(2));
      }
    });
  }
}
