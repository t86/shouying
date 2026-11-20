import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/cashier_reports.dart';
import 'package:card_table/src/cashier_reports_screens.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

void main() {
  test(
    'category grand total follows source group-sum order before rounding',
    () async {
      final page =
          (await _api(
                _Adapter([
                  {
                    'code': 1,
                    'data': {
                      'cnls': [
                        {'id': 1, 'n': '现金'},
                      ],
                      'records': [
                        {'c': 'A', 'l': 1, 'a': -0.3},
                        {'c': 'B', 'l': 1, 'a': -0.275},
                        {'c': 'A', 'l': 1, 'a': 0.03},
                      ],
                    },
                  },
                ]),
              ).loadReportPage(
                ClientKind.cashier,
                query: const CashierReportQuery(title: '分类渠道汇总表'),
              ))
              .valueOrNull!;
      expect(page.rows.map((row) => row['类别']), ['A', 'B']);
      expect(page.grandTotal, '-0.55');
    },
  );
  test(
    'fixed reports preserve every source field and never rescale yuan',
    () async {
      for (final title in ['现抽明细表', '现抽汇总表', '非主营分类渠道', '部门销售明细表', '部门销售汇总表']) {
        final meta = CashierReportCatalog.reports[title]!;
        final record = <String, Object?>{
          for (final field in meta.fields.where((f) => f.isNotEmpty))
            field: '字段-$field',
        };
        record['a'] = '1234.56';
        record['ca'] = '20.05';
        record['c'] = 3;
        final page =
            (await _api(
                  _Adapter([
                    {
                      'code': 1,
                      'data': {
                        'records': [record],
                      },
                    },
                  ]),
                ).loadReportPage(
                  ClientKind.cashier,
                  query: CashierReportQuery(title: title),
                ))
                .valueOrNull!;
        expect(page.rows, hasLength(1));
        for (var i = 1; i < meta.fields.length; i++) {
          expect(
            page.rows.single[meta.columns[i]],
            '${record[meta.fields[i]]}',
          );
        }
        expect(meta.requiresDateRange, false);
      }
      final summary = CashierReportCatalog.reports['现抽汇总表']!;
      expect(summary.fields[summary.columns.indexOf('抽成对象')], 'o');
      expect(summary.fields[summary.columns.indexOf('抽成人')], 'tn');
    },
  );
  test('category channels preserve order duplicate labels last cell values and all totals', () async {
    final page =
        (await _api(
              _Adapter([
                {
                  'code': 1,
                  'data': {
                    'cnls': [
                      {'id': 3, 'n': '现金'},
                      {'id': 7, 'n': '现金'},
                      {'id': 8, 'n': '空渠道'},
                    ],
                    'records': [
                      {'c': '酒水', 'l': 3, 'a': '10.10'},
                      {'c': '小吃', 'l': 7, 'a': 2},
                      {'c': '酒水', 'l': 7, 'a': '20.20'},
                      {'c': '酒水', 'l': 3, 'a': '3.30'},
                      {'c': '小吃', 'l': 99, 'a': 1},
                    ],
                  },
                },
              ]),
            ).loadReportPage(
              ClientKind.cashier,
              query: const CashierReportQuery(title: '分类渠道汇总表'),
            ))
            .valueOrNull!;
    expect(page.channelColumns, {
      'channel:3': '现金',
      'channel:7': '现金',
      'channel:8': '空渠道',
    });
    expect(page.rows.map((r) => r['类别']), ['酒水', '小吃']);
    expect(page.rows.first['channel:3'], '3.30');
    expect(page.rows.first['channel:7'], '20.20');
    expect(page.rows.first['合计'], '33.60');
    expect(page.rows.last['合计'], '3.00');
    expect(page.grandTotal, '36.60');
  });
  test(
    'matrix malformed values fail and unauthorized readers do not dispatch',
    () async {
      for (final data in [
        {'records': {}, 'cnls': []},
        {
          'records': [],
          'cnls': [false],
        },
        {
          'records': [],
          'cnls': [
            {'id': 1, 'n': 'a'},
            {'id': 1, 'n': 'b'},
          ],
        },
        {
          'records': [
            {'c': '酒', 'l': 1, 'a': 'bad'},
          ],
          'cnls': [],
        },
      ]) {
        expect(
          (await _api(
                _Adapter([
                  {'code': 1, 'data': data},
                ]),
              ).loadReportPage(
                ClientKind.cashier,
                query: const CashierReportQuery(title: '分类渠道汇总表'),
              ))
              .failureOrNull,
          isNotNull,
        );
      }
      final adapter = _Adapter([]),
          query = const CashierReportQuery(title: '现抽明细表');
      expect(
        (await _api(
          adapter,
        ).loadReportPage(ClientKind.order, query: query)).failureOrNull,
        isNotNull,
      );
      expect(
        (await _api(
          adapter,
        ).exportReport(ClientKind.order, query: query)).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
    },
  );
  testWidgets(
    'dynamic matrix at 390 shows full channel columns zero cells and grand total',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '分类渠道汇总表',
            onLoadPage: (_) async => const Success(
              CashierReportPage(
                channelColumns: {
                  'channel:1': '现金',
                  'channel:2': '微信',
                  'channel:3': '其他渠道',
                },
                grandTotal: '12345678.90',
                rows: [
                  CashierReportRow(
                    id: '1',
                    cells: {
                      '类别': '酒水',
                      'channel:1': '12345678.90',
                      '合计': '12345678.90',
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('微信'), findsOneWidget);
      expect(find.text('0.00'), findsNWidgets(2));
      expect(find.text('总合计: 12345678.90'), findsOneWidget);
      expect(find.text('12345678.90'), findsNWidgets(2));
      expect(find.text('下一页'), findsNothing);
      expect(find.text('打印'), findsNothing);
      final scrolls = tester.widgetList<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrolls.any((w) => w.scrollDirection == Axis.horizontal), true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'commission keyword export reset and failed query retry follow the drawer',
    (tester) async {
      final queries = <CashierReportQuery>[], exports = <CashierReportQuery>[];
      var fail = false;
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '现抽明细表',
            onLoadPage: (q) async {
              queries.add(q);
              return fail
                  ? const FailureResult(
                      AppFailure(
                        kind: FailureKind.network,
                        code: 'test',
                        safeMessage: '网络失败',
                      ),
                    )
                  : const Success(CashierReportPage());
            },
            onExportData: (q) async {
              exports.add(q);
              return const Success('report.xlsx');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('商品名称/点单人'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('cashier-report-keyword')),
        '酒水',
      );
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('导出Excel'));
      await tester.pumpAndSettle();
      expect(exports.single.keyword, '酒水');
      fail = true;
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(find.text('网络失败'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(find.text('暂无记录'), findsOneWidget);
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(queries.last.keyword, isEmpty);
      expect(find.byType(DropdownButton<int>), findsNothing);
      expect(find.text('下一页'), findsNothing);
    },
  );
  testWidgets('revoked matrix does not publish a delayed response', (
    tester,
  ) async {
    final allowed = ValueNotifier(true);
    addTearDown(allowed.dispose);
    final pending = Completer<Result<CashierReportPage>>();
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '分类渠道汇总表',
          canRead: allowed,
          onLoadPage: (_) => pending.future,
        ),
      ),
    );
    await tester.pump();
    allowed.value = false;
    await tester.pumpAndSettle();
    pending.complete(
      const Success(
        CashierReportPage(
          channelColumns: {'channel:1': '敏感渠道'},
          grandTotal: '100.00',
          rows: [
            CashierReportRow(id: '1', cells: {'类别': '旧记录'}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('敏感渠道'), findsNothing);
    expect(find.text('旧记录'), findsNothing);
    expect(find.text('总合计: 100.00'), findsNothing);
  });
  for (final item in [
    ('现抽明细表', 'xian_chou_list', true),
    ('现抽汇总表', 'xian_chou_sum_list', true),
    ('非主营分类渠道', 'not_zy_cate_cnls', false),
    ('分类渠道汇总表', 'jk_list', false),
    ('部门销售明细表', 'waiter_sales_prd_amt_list', false),
    ('部门销售汇总表', 'waiter_sales_prd_amt_sums', false),
  ]) {
    test(
      '${item.$1} source read and export without invented filters',
      () async {
        final adapter = _Adapter([
          {
            'code': 1,
            'data': {'records': [], 'cnls': []},
          },
          <int>[80, 75, 3, 4, 0, 0, 0, 0],
        ]);
        final api = _api(adapter),
            query = CashierReportQuery(title: item.$1, keyword: '商品甲');
        expect(
          (await api.loadReportPage(
            ClientKind.cashier,
            query: query,
          )).failureOrNull,
          isNull,
        );
        expect(adapter.requests.single.uri.path, '/sel/rpt/get_${item.$2}');
        expect(adapter.requests.single.data, item.$3 ? {'key': '商品甲'} : null);
        expect(
          (await api.exportReport(
            ClientKind.cashier,
            query: query,
          )).failureOrNull,
          isNull,
        );
        expect(adapter.requests.last.uri.path, '/sel/rpt/exp_${item.$2}');
        expect(adapter.requests.last.data, adapter.requests.first.data);
      },
    );
  }
}

ProtocolCashierReportsApi _api(_Adapter adapter) {
  var now = DateTime(2026);
  return ProtocolCashierReportsApi(
    client: ProtocolClient(
      dio: Dio()..httpClientAdapter = adapter,
      config: ApiConfig(
        apiBase: Uri.parse('https://example.test'),
        onlineBase: Uri.parse('https://online.example.test'),
        websocketBase: Uri.parse('wss://example.test'),
      ),
      credentialStore: _Credentials(),
      requestGate: RequestGate(
        clock: () => now = now.add(const Duration(seconds: 1)),
      ),
    ),
  );
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);
  final List<Object?> responses;
  final List<RequestOptions> requests = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) await requestStream.drain<void>();
    final response = responses.removeAt(0);
    if (response is List<int>) {
      return ResponseBody.fromBytes(
        response,
        200,
        headers: {
          'content-type': ['application/octet-stream'],
          'content-disposition': ['attachment; filename=report.xlsx'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Credentials implements CredentialStore {
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      const CredentialSnapshot(tk: 'test', stk: null);
  @override
  Future<String?> readTk() async => 'test';
  @override
  Future<String?> readStk() async => null;
  @override
  Future<void> clearTk() async {}
  @override
  Future<void> clearStk() async {}
  @override
  Future<void> clearTkIfMatches(String? expected) async {}
  @override
  Future<void> clearStkIfMatches(String? expected) async {}
  @override
  Future<void> writeTk(String token) async {}
  @override
  Future<void> writeStk(String token) async {}
}
