import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:card_table/src/wine_api.dart';
import 'package:card_table/src/wine_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

class DelayedAdapter extends Adapter {
  final started = Completer<void>(), release = Completer<void>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = await super.fetch(options, requestStream, cancelFuture);
    started.complete();
    await release.future;
    return body;
  }
}

void main() {
  for (final operation in [
    'context',
    'inventory',
    'submit',
    'confirm',
    'reject',
  ]) {
    for (final change in [
      'offline',
      'same-account',
      'other-account',
      'generation',
    ]) {
      test('pending $operation rejects late $change response', () async {
        final adapter = DelayedAdapter()
          ..data = {'records': [], 'need_waiter_auth': 2};
        final auth = Adapter();
        final session = SessionRepository(
          api: SessionApi(client: makeApi(auth).client),
          credentialStore: Credentials(),
        );
        await loginSession(session, auth, 256);
        var online = true, epoch = 1;
        final loader = SessionBoundWineLoader(
          session: session,
          api: ProtocolWineApi(client: makeApi(adapter).client),
          isOnline: () => online,
          generation: () => epoch,
        );
        final pending = switch (operation) {
          'context' => loader.loadPendingGetContext(),
          'inventory' => loader.loadPendingGetInventory('138'),
          'confirm' => loader.confirmGetNeedToLib(['71']),
          'reject' => loader.backGetNeedToLib(['71']),
          _ => loader.confirmAuthGetNeedToLib({
            'bef_out_id': 71,
            'invt_ids': [91],
            'prd_cnts': [1],
            'auth_emp_code': '',
            'auth_emp_passwd': '',
            'pass_type': 1,
          }),
        };
        await adapter.started.future;
        if (operation == 'confirm' || operation == 'reject') {
          expect(adapter.requests.single.uri.path, operation == 'confirm'
              ? '/wine/confirm_qj_bef_out' : '/wine/back_qj_bef_out');
          expect(adapter.requests.single.data,
              {operation == 'confirm' ? 'ids' : 'bef_out_ids': [71]});
        }
        if (change == 'offline') {
          online = false;
        } else if (change == 'generation') {
          epoch++;
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 2));
          auth.data = {
            'emp_id': change == 'same-account' ? '1' : '2',
            'name': '测试',
            'station_id': '1',
          };
          expect(
            (await session.login(
              account: 'test',
              password: 'test',
              type: EmployeeLoginType.account,
            )).failureOrNull,
            isNull,
          );
        }
        adapter.release.complete();
        expect((await pending).failureOrNull?.code, 'wine.session_changed');
      });
    }
  }
}
