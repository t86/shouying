import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:card_table/src/cashier_reports.dart';
import 'package:card_table/src/card_table_screen.dart';
import 'package:card_table/src/cashier_reports_screens.dart';
import 'package:card_table/src/wine_export_saver.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Credentials;
import 'card_amount_metadata_test.dart'
    as card_fixture
    show full, business, event;

class ReportAdapter implements HttpClientAdapter {
  Object data = {
    'code': 1,
    'data': {'records': []},
  };
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    if (body != null) await body.drain<void>();
    return data is List<int>
        ? ResponseBody.fromBytes(
            data as List<int>,
            200,
            headers: {
              'content-type': ['application/octet-stream'],
            },
          )
        : ResponseBody.fromString(
            jsonEncode(data),
            200,
            headers: {
              'content-type': ['application/json'],
            },
          );
  }

  @override
  void close({bool force = false}) {}
}

ProtocolClient client(ReportAdapter adapter) {
  var tick = DateTime(2026);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.test'),
      onlineBase: Uri.parse('https://online.test'),
      websocketBase: Uri.parse('wss://api.test'),
    ),
    credentialStore: Credentials(),
    requestGate: RequestGate(
      clock: () => tick = tick.add(const Duration(milliseconds: 2)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'cashier Card dispatches all four real reports through existing guarded callbacks',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final queries = <CashierReportQuery>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            employeeId: '7',
            stationId: '9',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onLoadCashierReportPage: (query) async {
              queries.add(query);
              return const Success(CashierReportPage());
            },
          ),
        ),
      );
      final data = card_fixture.full(card_fixture.business());
      data[54] = [
        [1, 0],
      ];
      events.add(card_fixture.event(data));
      await tester.pumpAndSettle();
      for (final title in ['转台记录', '线上预订记录', '商品卡台销售表', '商品出库表']) {
        tester
            .widget<PopupMenuButton<String>>(
              find.byKey(CardTableScreen.moreFunctionsKey),
            )
            .onSelected!(title);
        await tester.pumpAndSettle();
        expect(queries.last.title, title);
        expect(find.text('暂无记录'), findsOneWidget);
        expect(find.textContaining('尚未接入'), findsNothing);
        Navigator.of(tester.element(find.byType(CashierReportScreen))).pop();
        await tester.pumpAndSettle();
      }
    },
  );
  test(
    'bad dates and wrong system send nothing; business failures stay failures',
    () async {
      for (final days in [
        ('2026-02-30', '2026-03-01'),
        ('2026-09-22', '2026-09-01'),
        ('', ''),
      ]) {
        final adapter = ReportAdapter();
        final result = await ProtocolCashierReportsApi(client: client(adapter))
            .loadReportPage(
              ClientKind.cashier,
              query: CashierReportQuery(
                title: '商品出库表',
                startDay: days.$1,
                endDay: days.$2,
              ),
            );
        expect(result.failureOrNull, isNotNull);
        expect(adapter.requests, isEmpty);
      }
      final adapter = ReportAdapter()..data = {'code': 2, 'msg': '拒绝'};
      final api = ProtocolCashierReportsApi(client: client(adapter));
      expect(
        (await api.loadReportPage(
          ClientKind.order,
          query: const CashierReportQuery(title: '转台记录'),
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
      expect(
        (await api.loadReportPage(
          ClientKind.cashier,
          query: const CashierReportQuery(title: '转台记录'),
        )).failureOrNull,
        isNotNull,
      );
    },
  );
  final cases = [
    (
      '转台记录',
      '/bk/get_chg_seat_log',
      null,
      {'o': '20:00', 'i': 'A→B\nB→C'},
      '转台记录',
      'A→B\nB→C',
    ),
    (
      '线上预订记录',
      '/sel/rpt/get_ol_book_list',
      null,
      {'s': 'A01', 'pa': '150.25', 'ua': '50', 'b': '100.25', 'ba': '0'},
      '预付金',
      '150.25',
    ),
    (
      '商品卡台销售表',
      '/sel/rpt/get_prd_set_sold_cnt',
      <String, Object?>{'key': '酒'},
      {'p': '酒', 'dc': 2, 'sc': 3, 'tc': 5},
      '合计数',
      '5',
    ),
    (
      '商品出库表',
      '/sel/rpt/get_rpt_prd_out_list',
      <String, Object?>{
        'key': '酒',
        'start_day': '2026-09-01',
        'end_day': '2026-09-21',
      },
      {'on': '饮品', 'dc': 2, 'sc': 3, 'c': 5},
      '总出库量',
      '5',
    ),
  ];
  for (final c in cases) {
    test('source read contract ${c.$1}', () async {
      final adapter = ReportAdapter()
        ..data = {
          'code': 1,
          'data': {
            'records': [c.$4],
          },
        };
      final result = await ProtocolCashierReportsApi(client: client(adapter))
          .loadReportPage(
            ClientKind.cashier,
            query: CashierReportQuery(
              title: c.$1,
              keyword: '酒',
              startDay: '2026-09-01',
              endDay: '2026-09-21',
            ),
          );
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.single.uri.path, c.$2);
      expect(adapter.requests.single.data, c.$3);
      expect(adapter.requests.single.headers['tt'], '8');
      expect(result.valueOrNull!.rows.single[c.$5], c.$6);
    });
  }
  test('three exports are real bytes with exact filters and no-body booking export', () async {
    final directory = await Directory.systemTemp.createTemp(
      'cashier-report-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    for (final c in [
      ('线上预订记录', 'exp_ol_book_list'),
      ('商品卡台销售表', 'exp_prd_set_sold_cnt'),
      ('商品出库表', 'exp_rpt_prd_out_list'),
    ]) {
      final adapter = ReportAdapter()..data = <int>[80, 75, 3, 4];
      final result = await ProtocolCashierReportsApi(client: client(adapter))
          .exportReport(
            ClientKind.cashier,
            query: CashierReportQuery(
              title: c.$1,
              keyword: '酒',
              startDay: '2026-09-01',
              endDay: '2026-09-21',
            ),
          );
      expect(result.failureOrNull, isNull);
      expect(result.valueOrNull!.bytes, [80, 75, 3, 4]);
      final saved = await saveWineExport(result.valueOrNull!);
      expect(saved.failureOrNull, isNull);
      expect(await File(saved.valueOrNull!).readAsBytes(), [80, 75, 3, 4]);
      expect(adapter.requests.single.uri.path, '/sel/rpt/${c.$2}');
      expect(
        adapter.requests.single.data,
        c.$1 == '线上预订记录'
            ? null
            : c.$1 == '商品出库表'
            ? {'key': '酒', 'start_day': '2026-09-01', 'end_day': '2026-09-21'}
            : {'key': '酒'},
      );
    }
  });
  testWidgets('new report clears stale data after access is revoked', (
    tester,
  ) async {
    final allowed = ValueNotifier(true);
    addTearDown(allowed.dispose);
    final pending = Completer<Result<CashierReportPage>>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '线上预订记录',
          canRead: allowed,
          onLoadPage: (_) {
            calls++;
            return pending.future;
          },
        ),
      ),
    );
    await tester.pump();
    allowed.value = false;
    await tester.pumpAndSettle();
    pending.complete(
      const Success(
        CashierReportPage(
          rows: [
            CashierReportRow(id: '1', cells: {'客人姓名': '旧客户'}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('旧客户'), findsNothing);
    expect(find.text('下一页'), findsNothing);
  });
  test(
    'binary explicit null body differs from compatible default empty map',
    () async {
      final adapter = ReportAdapter()..data = <int>[80, 75, 3, 4];
      final api = client(adapter);
      await api.postBinary('/one', client: ClientKind.cashier, body: null);
      await api.postBinary('/two', client: ClientKind.cashier);
      expect(adapter.requests.first.data, isNull);
      expect(adapter.requests.last.data, {});
    },
  );
  testWidgets(
    'product out dates default eight hours earlier and query/export preserve chosen dates',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final loaded = <CashierReportQuery>[], exported = <CashierReportQuery>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '商品出库表',
            now: () => DateTime(2026, 9, 21, 7, 30),
            canRead: const AlwaysStoppedAnimation(true),
            onLoadPage: (q) async {
              loaded.add(q);
              return const Success(CashierReportPage());
            },
            onExportData: (q) async {
              exported.add(q);
              return const Success('下载/商品出库表.xlsx');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(loaded.single.startDay, '2026-09-20');
      expect(loaded.single.endDay, '2026-09-20');
      expect(find.text('下一页'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('cashier-report-start-day')),
        '2026-09-01',
      );
      await tester.enterText(
        find.byKey(const Key('cashier-report-keyword')),
        '酒',
      );
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(loaded.last.startDay, '2026-09-01');
      expect(loaded.last.keyword, '酒');
      await tester.tap(find.text('导出Excel'));
      await tester.pumpAndSettle();
      expect(exported.single.startDay, '2026-09-01');
      expect(find.textContaining('商品出库表.xlsx'), findsWidgets);
    },
  );
}
