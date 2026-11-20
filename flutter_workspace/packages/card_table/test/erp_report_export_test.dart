import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/erp_api.dart';
import 'package:card_table/src/erp_loader.dart';
import 'package:card_table/src/erp_models.dart';
import 'package:card_table/src/erp_report_views.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials, makeApi;

const _paths = [
  ('/rpt_erp/get_now_mat_invt', '/rpt_erp/exp_now_mat_invt'),
  ('/rpt_erp/get_mat_invt', '/rpt_erp/exp_mat_invt'),
  ('/rpt_erp/in_recs', '/rpt_erp/exp_in_recs'),
  ('/rpt_erp/out_recs', '/rpt_erp/exp_out_recs'),
  ('/rpt_erp/in_sum', '/rpt_erp/exp_in_sum'),
  ('/rpt_erp/out_sum', '/rpt_erp/exp_out_sum'),
  ('/rpt_erp/get_store_invt_reps', '/rpt_erp/exp_store_invt_reps'),
  ('/rtn_bt/get_rtn_bt_in_opers', '/rtn_bt/exp_rtn_bt_in_opers'),
  ('/rtn_bt/get_rtn_bt_out_opers', '/rtn_bt/exp_rtn_bt_out_opers'),
];
const _detail = {
  'begin_day': '2026-09-01',
  'end_day': '2026-09-22',
  'store_id': 3,
  'record_type': 7,
  'mat_one_cate_id': 4,
  'mat_two_cate_id': 5,
  'name': '果汁',
  'page_num': 2,
  'page_size': 20,
};
final _bodies = <Map<String, Object?>>[
  {'store_id': 3, 'name': '果汁'},
  {
    'start_day': '2026-09-01',
    'end_day': '2026-09-22',
    'store_id': 3,
    'name': '果汁',
  },
  {..._detail, 'supplier_id': 6},
  {..._detail},
  {
    'begin_day': '2026-09-01',
    'end_day': '2026-09-22',
    'in_store_id': 3,
    'record_type': 7,
    'mat_one_cate_id': 4,
    'mat_two_cate_id': 5,
    'name': '果汁',
  },
  {
    'begin_day': '2026-09-01',
    'end_day': '2026-09-22',
    'out_store_id': 3,
    'record_type': 7,
    'mat_one_cate_id': 4,
    'mat_two_cate_id': 5,
    'name': '果汁',
  },
  {'store_id': 3, 'day': '2026-09-01', 'key': '果汁'},
  {
    'start_day': '2026-09-01',
    'end_day': '2026-09-22',
    'waiter_key': '张三',
    'mat_key': '果汁',
  },
  {'start_day': '2026-09-01', 'end_day': '2026-09-22', 'mat_key': '果汁'},
];
ErpReportQuery _query(ErpReportKind kind) => ErpReportQuery(
  kind: kind,
  startDay: '2026-09-01',
  endDay: '2026-09-22',
  storeId: 3,
  keyword: '果汁',
  recordType: 7,
  oneCateId: 4,
  twoCateId: 5,
  supplierId: 6,
  waiterKey: '张三',
  page: 2,
);

void main() {
  for (final kind in [ErpReportKind.inSummary, ErpReportKind.outSummary]) {
    test(
      '${kind.name} accepts the Vue data array and rejects record wrappers',
      () async {
        final row = {
          'rt': '其他出入库',
          'n': '果汁',
          'un': '瓶',
          'ia': '120.50',
          'sa': '150.00',
        };
        final adapter = _BinaryAdapter()..dataOverride = [row];
        final api = ProtocolErpApi(client: _client(adapter));
        final page = await api.readReport(
          _query(kind),
          canDispatch: () => true,
        );
        expect(page.failureOrNull, isNull);
        expect(page.valueOrNull!.rows, [row]);
        expect(page.valueOrNull!.total, 1);
        adapter.dataOverride = [];
        expect(
          (await api.readReport(
            _query(kind),
            canDispatch: () => true,
          )).valueOrNull!.rows,
          isEmpty,
        );
        adapter.nullData = true;
        expect(
          (await api.readReport(
            _query(kind),
            canDispatch: () => true,
          )).valueOrNull!.rows,
          isEmpty,
        );
        adapter.nullData = false;
        adapter.dataOverride = {
          'records': [row],
        };
        expect(
          (await api.readReport(
            _query(kind),
            canDispatch: () => true,
          )).failureOrNull,
          isNotNull,
        );
        adapter.dataOverride = [42];
        expect(
          (await api.readReport(
            _query(kind),
            canDispatch: () => true,
          )).failureOrNull,
          isNotNull,
        );
      },
    );
  }
  for (var i = 0; i < _paths.length; i++) {
    test(
      'report $i reads and exports exact Vue path/body without currency conversion',
      () async {
        final adapter = _BinaryAdapter();
        final api = ProtocolErpApi(client: _client(adapter));
        final query = _query(ErpReportKind.values[i]);
        final page = await api.readReport(query, canDispatch: () => true);
        expect(page.valueOrNull!.rows.single['a'], '120.50');
        final expectedRead = {
          ..._bodies[i],
          if (i == 6) ...{'page_num': 2, 'page_size': 20},
        };
        expect(adapter.requests.first.uri.path, _paths[i].$1);
        expect(adapter.requests.first.data, expectedRead);
        final file = await api.exportReport(query, canDispatch: () => true);
        expect(adapter.requests.last.uri.path, _paths[i].$2);
        expect(adapter.requests.last.data, _bodies[i]);
        expect(file.valueOrNull!.bytes, [80, 75, 3, 4, 1, 2, 3, 4]);
      },
    );
  }

  test(
    'binary JSON error and empty response are failures, not downloadable files',
    () async {
      final adapter = _BinaryAdapter()
        ..binaryOverride = utf8.encode('{"code":2,"msg":"拒绝"}');
      final api = ProtocolErpApi(client: _client(adapter));
      expect(
        (await api.exportReport(
          _query(ErpReportKind.values.first),
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
      adapter.binaryOverride = [];
      expect(
        (await api.exportReport(
          _query(ErpReportKind.values.first),
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
    },
  );

  test(
    'loader refuses offline, wrong role and changed epoch after credentials',
    () async {
      final sessionAdapter = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: makeApi(sessionAdapter).client),
        credentialStore: Credentials(),
      );
      await loginSession(session, sessionAdapter, 64);
      var online = false, epoch = 1;
      final credentials = _DelayedCredentials();
      final adapter = _BinaryAdapter();
      final loader = ProtocolErpLoader(
        session: session,
        api: ProtocolErpApi(client: _client(adapter, credentials)),
        isOnline: () => online,
        generation: () => epoch,
      );
      final query = _query(ErpReportKind.values.first);
      expect(
        (await loader.exportReport(
          query,
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
      online = true;
      credentials.delay = true;
      final pending = loader.exportReport(query, canDispatch: () => true);
      await credentials.started.future;
      epoch++;
      credentials.gate.complete();
      expect((await pending).failureOrNull, isNotNull);
      expect(adapter.requests, isEmpty);
      final wrongAdapter = Adapter();
      final wrongSession = SessionRepository(
        api: SessionApi(client: makeApi(wrongAdapter).client),
        credentialStore: Credentials(),
      );
      await loginSession(wrongSession, wrongAdapter, 8);
      final wrongLoader = ProtocolErpLoader(
        session: wrongSession,
        api: ProtocolErpApi(client: _client(adapter)),
        isOnline: () => true,
        generation: () => 1,
      );
      expect(
        (await wrongLoader.exportReport(
          query,
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
    },
  );

  testWidgets(
    'all nine export buttons invoke their own report and save real bytes',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final kind in ErpReportKind.values) {
        final loader = _ReportLoader();
        var saved = 0;
        await tester.pumpWidget(
          MaterialApp(
            builder: (_, child) => Scaffold(body: child),
            home: ErpReportView(
              key: ValueKey(kind),
              loader: loader,
              kind: kind,
              canOperate: () => true,
              saveExport: (file, {canSave}) async {
                expect(canSave!(), true);
                expect(file.bytes, [80, 75, 3, 4]);
                saved++;
                return const Success('fixture.xlsx');
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('导出Excel'));
        await tester.pumpAndSettle();
        expect(loader.exports.single.kind, kind);
        expect(saved, 1);
        expect(find.text('已保存：fixture.xlsx'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'changed current filters reach export; empty data still exports',
    (tester) async {
      final loader = _ReportLoader();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => Scaffold(body: child),
          home: ErpReportView(
            loader: loader,
            kind: ErpReportKind.values.first,
            canOperate: () => true,
            saveExport: (file, {canSave}) async => const Success('x.xlsx'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('暂无数据'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('erp-report-keyword')),
        '新筛选',
      );
      await tester.tap(find.text('导出Excel'));
      await tester.pumpAndSettle();
      expect(loader.exports.single.keyword, '新筛选');
      expect(loader.exports.single.toWire(export: true), {
        'store_id': 0,
        'name': '新筛选',
      });
    },
  );

  for (final cancel in ['page', 'scope', 'permission']) {
    testWidgets(
      '$cancel change while downloading blocks saving and late success',
      (tester) async {
        final loader = _ReportLoader()
          ..pending = Completer<Result<ProtocolBinaryFile>>();
        var allowed = true, saved = 0;
        await tester.pumpWidget(
          MaterialApp(
            builder: (_, child) => Scaffold(body: child),
            home: ErpReportView(
              loader: loader,
              kind: ErpReportKind.values.first,
              canOperate: () => allowed,
              saveExport: (file, {canSave}) async {
                saved++;
                return const Success('x.xlsx');
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('导出Excel'));
        await tester.pump();
        if (cancel == 'page') {
          await tester.pumpWidget(const MaterialApp(home: Text('新页面')));
        }
        if (cancel == 'scope') loader.reportContext = Object();
        if (cancel == 'permission') allowed = false;
        loader.pending!.complete(
          Success(
            ProtocolBinaryFile(bytes: [80, 75, 3, 4], fileName: 'x.xlsx'),
          ),
        );
        await tester.pumpAndSettle();
        expect(saved, 0);
        expect(find.textContaining('已保存'), findsNothing);
      },
    );
  }

  testWidgets('record filters and page are shared by query and export', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final loader = _ReportLoader()
      ..total = 45
      ..options = ErpReportParams.fromWire({
        'stores': [
          {'id': 3, 'n': '总仓'},
        ],
        'suppliers': [
          {'id': 6, 'n': '供应商甲'},
        ],
        'cates': [
          {
            'id': 4,
            'n': '饮品',
            'ss': [
              {'id': 5, 'n': '果汁'},
            ],
          },
        ],
      });
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => Scaffold(body: child),
        home: ErpReportView(
          loader: loader,
          kind: ErpReportKind.inRecords,
          canOperate: () => true,
          saveExport: (file, {canSave}) async => const Success('x.xlsx'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final selection in [
      ('仓库', 3),
      ('订单类型', 7),
      ('一级分类', 4),
      ('二级分类', 5),
      ('供应商', 6),
    ]) {
      final finder = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<int> &&
            w.decoration.labelText == selection.$1,
      );
      tester.widget<DropdownButtonFormField<int>>(finder).onChanged!(
        selection.$2,
      );
      await tester.pump();
    }
    await tester.enterText(find.byKey(const Key('erp-report-keyword')), '苹果');
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('下一页'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导出Excel'));
    await tester.pumpAndSettle();
    expect(
      loader.exports.single.toWire(export: true),
      loader.queries.last.toWire(),
    );
    expect(
      loader.exports.single.toWire(export: true),
      containsPair('page_num', 2),
    );
    expect(
      loader.exports.single.toWire(export: true),
      containsPair('supplier_id', 6),
    );
    expect(
      loader.exports.single.toWire(export: true),
      containsPair('mat_two_cate_id', 5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'save failure has no success and late save cannot publish success',
    (tester) async {
      var permission = true, calls = 0;
      final gate = Completer<Result<String>>();
      bool Function()? guard;
      final loader = _ReportLoader();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => Scaffold(body: child),
          home: ErpReportView(
            loader: loader,
            kind: ErpReportKind.materialNow,
            canOperate: () => permission,
            saveExport: (file, {canSave}) {
              calls++;
              guard = canSave;
              return gate.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('导出Excel'));
      await tester.pump();
      await tester.tap(find.text('导出Excel'));
      await tester.pump();
      expect(calls, 1);
      expect(loader.exports.length, 1);
      permission = false;
      expect(guard!(), false);
      gate.complete(
        const FailureResult(
          AppFailure(
            kind: FailureKind.unknown,
            code: 'save.failed',
            safeMessage: '未保存',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('已保存'), findsNothing);
    },
  );

  test(
    'invalid filters and malformed report rows fail without fake empty success',
    () async {
      final adapter = _BinaryAdapter();
      final api = ProtocolErpApi(client: _client(adapter));
      final query = ErpReportQuery(
        kind: ErpReportKind.inRecords,
        startDay: '2026-02-30',
        endDay: '2026-03-01',
      );
      expect(
        (await api.exportReport(query, canDispatch: () => true)).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
      adapter.dataOverride = {'records': 'invalid'};
      expect(
        (await api.readReport(
          _query(ErpReportKind.materialNow),
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
    },
  );
}

ProtocolClient _client(
  HttpClientAdapter adapter, [
  CredentialStore? credentials,
]) {
  var now = DateTime(2026);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://example.test'),
      onlineBase: Uri.parse('https://example.test'),
      websocketBase: Uri.parse('wss://example.test'),
    ),
    credentialStore: credentials ?? Credentials(),
    requestGate: RequestGate(
      clock: () {
        now = now.add(const Duration(seconds: 1));
        return now;
      },
    ),
  );
}

class _BinaryAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  List<int>? binaryOverride;
  Object? dataOverride;
  bool nullData = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.uri.path.contains('/exp_')) {
      return ResponseBody.fromBytes(
        binaryOverride ?? [80, 75, 3, 4, 1, 2, 3, 4],
        200,
        headers: {
          'content-disposition': ['attachment; filename="report.xlsx"'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'code': 1,
        'data': nullData
            ? null
            : dataOverride ??
                  (options.uri.path.endsWith('/in_sum') ||
                          options.uri.path.endsWith('/out_sum')
                      ? [
                          {'a': '120.50'},
                        ]
                      : {
                          (options.uri.path.endsWith('/in_recs') ||
                                  options.uri.path.endsWith('/out_recs')
                              ? 'datas'
                              : 'records'): [
                            {'a': '120.50'},
                          ],
                          'row_cnt': 1,
                        }),
      }),
      200,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _DelayedCredentials extends Credentials {
  bool delay = false;
  final started = Completer<void>(), gate = Completer<void>();
  @override
  Future<CredentialSnapshot> readSnapshot() async {
    if (delay) {
      if (!started.isCompleted) started.complete();
      await gate.future;
    }
    return super.readSnapshot();
  }
}

class _ReportLoader implements ErpLoader, ErpReportLoader {
  @override
  Object? reportContext = Object();
  final exports = <ErpReportQuery>[];
  final queries = <ErpReportQuery>[];
  int total = 0;
  ErpReportParams options = const ErpReportParams();
  Completer<Result<ProtocolBinaryFile>>? pending;
  @override
  Future<Result<ErpReportPage>> loadReport(
    ErpReportQuery query, {
    required bool Function() canDispatch,
  }) async {
    queries.add(query);
    return Success(ErpReportPage(rows: [], total: total, options: options));
  }

  @override
  Future<Result<ErpReportParams>> loadReportParams() async =>
      const Success(ErpReportParams());
  @override
  Future<Result<ErpReportParams>> loadReportOptions({
    required bool Function() canDispatch,
  }) async => Success(options);
  @override
  Future<Result<ProtocolBinaryFile>> exportReport(
    ErpReportQuery query, {
    required bool Function() canDispatch,
  }) async {
    exports.add(query);
    return pending?.future ??
        Success(
          ProtocolBinaryFile(bytes: [80, 75, 3, 4], fileName: 'fixture.xlsx'),
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
