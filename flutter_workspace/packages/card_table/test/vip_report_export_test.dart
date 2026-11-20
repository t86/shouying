import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';

import 'package:card_table/src/vip_pages_loader.dart';
import 'package:card_table/src/vip_manager.dart';
import 'package:foundation/foundation.dart';
import 'package:session/session.dart';
import 'package:card_table/src/vip_pages.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Credentials, Adapter, makeApi;
import 'bms_loader_guard_test.dart' show loginSession;

const paths = [
  'exp_deposit_log',
  'exp_consume_log',
  'exp_subtract_log',
  'exp_pt_log',
  'exp_mb_card_bal_list',
  'exp_mb_card_top_consume',
  'exp_mb_card_consume_list',
  'exp_mb_card_zx_list',
  'exp_mb_card_updown_log',
];
ProtocolClient clientFor(ExportAdapter adapter) => ProtocolClient(
  dio: Dio()..httpClientAdapter = adapter,
  config: ApiConfig(
    apiBase: Uri.parse('https://api.test'),
    onlineBase: Uri.parse('https://online.test'),
    websocketBase: Uri.parse('wss://api.test'),
  ),
  credentialStore: Credentials(),
  requestGate: RequestGate(clock: DateTime.now),
);

void main() {
  test(
    'unselected referral employee uses source empty value, not invented zero',
    () async {
      final adapter = ExportAdapter();
      await ProtocolVipPagesApi(client: clientFor(adapter))
          .exportReport(ClientKind.vip, kind: VipReportKind.customerRelation);
      expect((adapter.requests.single.data as Map)['sales_emp_id'], '');
    },
  );
  test(
    'level export carries chosen page while other exports omit it',
    () async {
      final adapter = ExportAdapter();
      final result = await ProtocolVipPagesApi(client: clientFor(adapter))
          .exportReport(
            ClientKind.vip,
            kind: VipReportKind.changeLevel,
            pageNum: 3,
            pageSize: 20,
          );
      expect(result.failureOrNull, isNull);
      expect((adapter.requests.single.data as Map)['page_num'], 3);
    },
  );
  for (final invalidateAt in ['none', 'headers', 'response', 'save', 'page']) {
    test(
      'loader downloads and saves only within current $invalidateAt scope',
      () async {
        final auth = Adapter(), adapter = ExportAdapter();
        final session = SessionRepository(
          api: SessionApi(client: makeApi(auth).client),
          credentialStore: Credentials(),
        );
        await loginSession(session, auth, 16);
        var epoch = 1, saves = 0;
        final client = clientFor(adapter);
        if (invalidateAt == 'response') adapter.beforeReturn = () => epoch++;
        final loader = SessionBoundVipPagesLoader(
          session: session,
          pages: ProtocolVipPagesApi(client: client),
          cards: ProtocolVipManagerApi(client: client),
          phase: () => ConnectionPhase.online,
          generation: () => epoch,
          saveExport: (file, {canSave}) async {
              expect(file.fileName, 'vip.xlsx');
              expect(file.bytes, [80, 75, 3, 4, 9]);
            if (invalidateAt == 'save') {
              await Future<void>.delayed(Duration.zero);
              epoch++;
            }
            if (!(canSave?.call() ?? false))
              return const FailureResult(
                AppFailure(
                  kind: FailureKind.authentication,
                  code: 'stale',
                  safeMessage: '取消',
                ),
              );
            saves++;
            return const Success('fake/vip.xlsx');
          },
        );
        final result = loader.workspace.exportReport!(
          kind: VipReportKind.balance,
          canDispatch: () => invalidateAt != 'page',
        );
        if (invalidateAt == 'headers') epoch++;
        expect((await result).failureOrNull == null, invalidateAt == 'none');
        expect(saves, invalidateAt == 'none' ? 1 : 0);
        if (invalidateAt == 'headers' || invalidateAt == 'page')
          expect(adapter.requests, isEmpty);
      },
    );
  }
  test('JSON business failure never becomes a spreadsheet', () async {
    final adapter = ExportAdapter()..jsonFailure = true;
    final result = await ProtocolVipPagesApi(client: clientFor(adapter))
        .exportReport(ClientKind.vip, kind: VipReportKind.balance);
    expect(result.failureOrNull, isNotNull);
  });
  for (final kind in VipReportKind.values) {
    test(
      '$kind downloads binary with exact source export filter body',
      () async {
        final adapter = ExportAdapter();
        final result = await ProtocolVipPagesApi(client: clientFor(adapter))
            .exportReport(
              ClientKind.vip,
              kind: kind,
              beginDay: '2026-09-01',
              endDay: '2026-09-22',
              keyword: '会员',
              typeId: 2,
              salesEmpId: '9',
            );
        expect(result.failureOrNull, isNull);
        final request = adapter.requests.single;
        expect(request.responseType, ResponseType.bytes);
        expect(request.uri.path, '/mb/rpt/${paths[kind.index]}');
        expect(request.data, {
          'key': '会员',
          if (kind != VipReportKind.balance) ...{
            'begin_day': '2026-09-01',
            'end_day': '2026-09-22',
          },
          if ([
            VipReportKind.depositLog,
            VipReportKind.subtractLog,
            VipReportKind.pointLog,
          ].contains(kind))
            'type_id': 2,
          if (kind == VipReportKind.customerRelation) 'sales_emp_id': 9,
          if (kind == VipReportKind.changeLevel) ...{
            'page_num': 1,
            'page_size': 20,
          },
        });
      },
    );
  }
}

class ExportAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  void Function()? beforeReturn;
  bool jsonFailure = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    if (stream != null) await stream.drain<void>();
    beforeReturn?.call();
    if (jsonFailure)
      return ResponseBody.fromBytes(
        utf8.encode('{"code":2,"msg":"拒绝"}'),
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    return ResponseBody.fromBytes(
      [80, 75, 3, 4, 9],
      200,
      headers: {
        'content-type': [
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ],
        'content-disposition': ['attachment; filename="vip.xlsx"'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
