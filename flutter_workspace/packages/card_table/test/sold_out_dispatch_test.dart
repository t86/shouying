import 'dart:async';

import 'package:card_table/src/sold_out_products.dart';
import 'package:card_table/src/sold_out_products_loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

class WaitingCredentials extends Credentials {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<CredentialSnapshot> readSnapshot() async {
    entered.complete();
    await release.future;
    return super.readSnapshot();
  }
}

ProtocolSoldOutProductsApi remote(
  Adapter adapter,
  CredentialStore credentials,
) {
  var tick = DateTime(2026);
  return ProtocolSoldOutProductsApi(
    client: ProtocolClient(
      dio: Dio()..httpClientAdapter = adapter,
      config: ApiConfig(
        apiBase: Uri.parse('https://api.test'),
        onlineBase: Uri.parse('https://online.test'),
        websocketBase: Uri.parse('wss://api.test'),
      ),
      credentialStore: credentials,
      requestGate: RequestGate(
        clock: () => tick = tick.add(const Duration(milliseconds: 2)),
      ),
    ),
  );
}

SessionBoundSoldOutProductsLoader bind(
  SessionRepository session,
  ProtocolSoldOutProductsApi api,
  int Function() generation,
) => SessionBoundSoldOutProductsLoader(
  session: session,
  phase: () => ConnectionPhase.online,
  generation: generation,
  listRemote: api.list,
  setRemote:
      ({
        required ClientKind client,
        required bool Function() canDispatch,
        required String productId,
        required int count,
      }) => api.set(
        client,
        productId: productId,
        count: count,
        canDispatch: canDispatch,
      ),
  deleteRemote: (
    productId, {
    required ClientKind client,
    required bool Function() canDispatch,
  }) => api.delete(client, productId: productId, canDispatch: canDispatch),
);

void main() {
  for (final mode in [4, 8]) {
    test('all maintenance calls preserve terminal header $mode', () async {
      final login = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(login).client),
        credentialStore: Credentials(),
      );
      addTearDown(session.close);
      await loginSession(session, login, mode);
      final adapter = Adapter()..data = {'items': <Object?>[]};
      final loader = bind(session, remote(adapter, Credentials()), () => 0);
      expect((await loader.list()).failureOrNull, isNull);
      expect(
        (await loader.set(productId: '100', count: 0)).failureOrNull,
        isNull,
      );
      expect((await loader.delete('100')).failureOrNull, isNull);
      expect(adapter.requests.map((r) => r.headers['tt']), [
        '$mode',
        '$mode',
        '$mode',
      ]);
      expect(adapter.requests[0].data, isNull);
      expect(adapter.requests[1].data, {'prd_id': 100, 'cnt': 0});
      expect(adapter.requests[2].data, {'prd_id': 100});
    });
  }
  for (final operation in ['set', 'delete']) {
    for (final change in ['page', 'generation', 'logout', 'same-account']) {
      test(
        '$operation is not sent after $change during credential read',
        () async {
          final login = Adapter();
          final session = SessionRepository(
            api: SessionApi(client: makeApi(login).client),
            credentialStore: Credentials(),
          );
          addTearDown(session.close);
          await loginSession(session, login, 8);
          final adapter = Adapter();
          final credentials = WaitingCredentials();
          var epoch = 1, pageOpen = true;
          final loader = bind(
            session,
            remote(adapter, credentials),
            () => epoch,
          );
          final pending = operation == 'set'
              ? loader.set(
                  productId: '100',
                  count: 0,
                  canDispatch: () => pageOpen,
                )
              : loader.delete('100', canDispatch: () => pageOpen);
          await credentials.entered.future;
          if (change == 'page') pageOpen = false;
          if (change == 'generation') epoch++;
          if (change == 'logout') await session.logout();
          if (change == 'same-account') await loginSession(session, login, 8);
          credentials.release.complete();
          expect((await pending).failureOrNull, isNotNull);
          expect(adapter.requests, isEmpty);
        },
      );
    }
  }
}
