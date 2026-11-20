import 'package:card_table/src/cashier_report_printer.dart';
import 'package:card_table/src/cashier_reports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';
import 'package:dio/dio.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;
import 'bms_loader_guard_test.dart' show loginSession;
import 'sold_out_dispatch_test.dart' show WaitingCredentials;

void main() {
  test('cashier report printing forwards source parameters only in an authorized session', () async {
    final login = Adapter(), transport = Adapter();
    final session = SessionRepository(
      api: SessionApi(client: makeApi(login).client),
      credentialStore: Credentials(),
    );
    addTearDown(session.close);
    final printer = SessionBoundCashierReportPrinter(
      session: session,
      api: ProtocolCashierReportsApi(client: makeApi(transport).client),
      phase: () => ConnectionPhase.online,
      generation: () => 1,
    );
    const query = CashierReportQuery(title: '套餐统计表');
    expect((await printer.print(query)).failureOrNull, isNotNull);
    expect(transport.requests, isEmpty);
    await loginSession(session, login, 8);
    expect((await printer.print(query)).failureOrNull, isNull);
    expect(transport.requests.single.uri.path, '/sel/rpt/prt_set_cnt_rpt');
  });
  for (final change in ['generation', 'same-account', 'offline', 'page']) {
    test('print cannot dispatch after $change while awaiting credential lookup', () async {
      final login = Adapter(), transport = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(login).client),
        credentialStore: Credentials(),
      );
      addTearDown(session.close);
      await loginSession(session, login, 8);
      var epoch = 1, available = true, page = true;
      final credentials = WaitingCredentials();
      final protocol = ProtocolClient(
        dio: Dio()..httpClientAdapter = transport,
        config: ApiConfig(
          apiBase: Uri.parse('https://api.test'),
          onlineBase: Uri.parse('https://online.test'),
          websocketBase: Uri.parse('wss://api.test'),
        ),
        credentialStore: credentials,
        requestGate: RequestGate(clock: DateTime.now),
      );
      final printer = SessionBoundCashierReportPrinter(
        session: session,
        api: ProtocolCashierReportsApi(client: protocol),
        phase: () =>
            available ? ConnectionPhase.online : ConnectionPhase.blocked,
        generation: () => epoch,
      );
      final pending = printer.print(
        CashierReportQuery(title: '套餐统计表', canDispatch: () => page),
      );
      // A real request must enter credential selection before any invalidation.
      await credentials.entered.future;
      if (change == 'generation') epoch++;
      if (change == 'offline') available = false;
      if (change == 'page') page = false;
      if (change == 'same-account') await loginSession(session, login, 8);
      credentials.release.complete();
      expect((await pending).failureOrNull, isNotNull);
      expect(transport.requests, isEmpty);
    });
  }
}
