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
    'order filters use returned IDs and export exactly the selected query',
    () async {
      final adapter = _Adapter([
        {
          'code': 1,
          'data': {
            'records': [
              {
                'r': 'A区',
                's': 'A01',
                'ri': 'B02',
                'pm': '21:00',
                'ws': '主管',
                'ic': '是',
                'a': '100.50',
                'v': '88.25',
                'ss': '营销',
                'pi': '现金',
              },
            ],
            'prd_type': [
              {'id': 0, 'n': '全部'},
              {'id': 3, 'n': '套餐'},
            ],
            'biz_types': [
              {'id': 7, 'n': '晚场'},
            ],
          },
        },
        <int>[80, 75, 3, 4, 0, 0, 0, 0],
      ]);
      final api = _api(adapter);
      const query = CashierReportQuery(
        title: '点单记录',
        keyword: '员工甲',
        productType: 3,
        businessType: 7,
        paymentType: 2,
        customerType: 1,
      );
      final page = (await api.loadReportPage(
        ClientKind.cashier,
        query: query,
      )).valueOrNull!;
      expect(page.productTypes, {0: '全部', 3: '套餐'});
      expect(page.businessTypes, {7: '晚场'});
      expect(page.rows.single['实收金额'], '88.25');
      expect(page.rows.single['关联卡台'], 'B02');
      expect(page.rows.single['订位人岗位'], '营销');
      expect(page.rows.single.cells.length, 21);
      expect(adapter.requests.single.data, {
        'key': '员工甲',
        'prd_type': 3,
        'biz_type': 7,
        'pay_type': 2,
        'is_cust': 1,
      });
      expect(
        (await api.exportReport(
          ClientKind.cashier,
          query: query,
        )).failureOrNull,
        isNull,
      );
      expect(adapter.requests.last.data, adapter.requests.first.data);
    },
  );
  test(
    'related orders retain both independent tables and unchanged yuan fields',
    () async {
      final api = _api(
        _Adapter([
          {
            'code': 1,
            'data': {
              'orders': [
                {
                  'rn': 'A区',
                  'we': '员工甲',
                  'a': '1234.50',
                  'bs': 'C01',
                  'p': '银行卡',
                },
              ],
              'pays': [
                {'n': '现金', 'c': 2, 'a': '66.60'},
                {'n': '合计', 'c': 3, 'a': '1234.50'},
              ],
            },
          },
        ]),
      );
      final page = (await api.loadReportPage(
        ClientKind.cashier,
        query: const CashierReportQuery(title: '非鸡尾酒类补交报表', keyword: '员工甲'),
      )).valueOrNull!;
      expect(page.rows.single['点单金额'], '1234.50');
      expect(page.rows.single['点单人'], '员工甲');
      expect(page.paymentRows.first['金额'], '66.60');
      expect(page.paymentRows.last['渠道'], '合计');
    },
  );
  test('turnover and salesperson history keep every source column', () async {
    for (final title in ['翻台记录', '修改订位人记录']) {
      final meta = CashierReportCatalog.reports[title]!;
      final row = {
        for (final field in meta.fields.where((f) => f.isNotEmpty))
          field: '原值-$field',
      };
      final page =
          (await _api(
                _Adapter([
                  {
                    'code': 1,
                    'data': {
                      'records': [row],
                    },
                  },
                ]),
              ).loadReportPage(
                ClientKind.cashier,
                query: CashierReportQuery(title: title),
              ))
              .valueOrNull!;
      for (var i = 1; i < meta.fields.length; i++) {
        expect(page.rows.single[meta.columns[i]], '原值-${meta.fields[i]}');
      }
      expect(meta.requiresDateRange, false);
      expect(meta.supportsKeyword, false);
    }
  });
  test('invalid report payloads and rejected responses do not become empty success', () async {
    for (final data in [
      {'orders': {}, 'pays': []},
      {
        'orders': [],
        'pays': [false],
      },
    ]) {
      expect(
        (await _api(
              _Adapter([
                {'code': 1, 'data': data},
              ]),
            ).loadReportPage(
              ClientKind.cashier,
              query: const CashierReportQuery(title: '非鸡尾酒类补交报表'),
            ))
            .failureOrNull,
        isNotNull,
      );
    }
    expect(
      (await _api(
            _Adapter([
              {
                'code': 1,
                'data': {
                  'records': [],
                  'prd_type': [
                    {'id': 'bad', 'n': 'bad'},
                  ],
                },
              },
            ]),
          ).loadReportPage(
            ClientKind.cashier,
            query: const CashierReportQuery(title: '点单记录'),
          ))
          .failureOrNull,
      isNotNull,
    );
    final adapter = _Adapter([]);
    expect(
      (await _api(adapter).loadReportPage(
        ClientKind.cashier,
        query: const CashierReportQuery(title: '点单记录', customerType: 9),
      )).failureOrNull,
      isNotNull,
    );
    expect(adapter.requests, isEmpty);
    expect(
      (await _api(
            _Adapter([
              {'code': 0, 'msg': 'secret'},
            ]),
          ).loadReportPage(
            ClientKind.cashier,
            query: const CashierReportQuery(title: '翻台记录'),
          ))
          .failureOrNull,
      isNotNull,
    );
  });
  testWidgets(
    'order filters query export and reset without inventing defaults at 390 width',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final queries = <CashierReportQuery>[], exports = <CashierReportQuery>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '点单记录',
            onLoadPage: (query) async {
              queries.add(query);
              return const Success(
                CashierReportPage(
                  productTypes: {0: '全部', 3: '套餐'},
                  businessTypes: {7: '晚场'},
                ),
              );
            },
            onExportData: (query) async {
              exports.add(query);
              return const Success('result.xlsx');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final entry in [
        ('商品类型', 3),
        ('是否自助', 1),
        ('支付方式', 2),
        ('营业类型', 7),
      ]) {
        final select = tester.widget<DropdownButtonFormField<int>>(
          find.widgetWithText(DropdownButtonFormField<int>, entry.$1),
        );
        select.onChanged!(entry.$2);
        await tester.pump();
      }
      await tester.enterText(
        find.byKey(const Key('cashier-report-keyword')),
        '员工甲',
      );
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('导出Excel'));
      await tester.pumpAndSettle();
      expect(queries.last.productType, 3);
      expect(exports.single.businessType, 7);
      expect(exports.single.paymentType, 2);
      expect(exports.single.customerType, 1);
      expect(exports.single.keyword, '员工甲');
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(queries.last.productType, isNull);
      expect(queries.last.businessType, isNull);
      expect(queries.last.paymentType, isNull);
      expect(queries.last.customerType, isNull);
      expect(queries.last.keyword, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'related channel-only data is visible and revoked pending results cannot return',
    (tester) async {
      final allowed = ValueNotifier(true);
      addTearDown(allowed.dispose);
      final pending = Completer<Result<CashierReportPage>>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '非鸡尾酒类补交报表',
            canRead: allowed,
            onLoadPage: (_) async {
              if (++calls > 1) return pending.future;
              return const Success(
                CashierReportPage(
                  paymentRows: [
                    CashierReportRow(
                      id: 'p',
                      cells: {'渠道': '现金', '笔数': '2', '金额': '12.50'},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('现金'), findsOneWidget);
      expect(find.text('渠道汇总'), findsOneWidget);
      await tester.tap(find.text('查询'));
      await tester.pump();
      allowed.value = false;
      await tester.pumpAndSettle();
      pending.complete(
        const Success(
          CashierReportPage(
            rows: [
              CashierReportRow(id: 'x', cells: {'商品名称': '旧数据'}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('旧数据'), findsNothing);
      expect(find.text('现金'), findsNothing);
    },
  );
  testWidgets('history report exposes error retry and valid empty state', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '修改订位人记录',
          onLoadPage: (_) async {
            if (++calls == 1) {
              return const FailureResult(
                AppFailure(
                  kind: FailureKind.network,
                  code: 'test',
                  safeMessage: '网络不可用',
                ),
              );
            }
            return const Success(CashierReportPage());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('网络不可用'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(find.text('暂无记录'), findsOneWidget);
    expect(find.byKey(const Key('cashier-report-start-day')), findsNothing);
  });
  for (final item in [
    ('翻台记录', 'get_turnover_csm_list', 'exp_turnover_cms_list', null),
    (
      '点单记录',
      'get_order_prd_list',
      'exp_order_prd_list',
      <String, Object?>{'is_cust': null},
    ),
    (
      '非鸡尾酒类补交报表',
      'get_relate_prd_list',
      'exp_relate_prd_list',
      <String, Object?>{'key': ''},
    ),
    (
      '修改订位人记录',
      'get_csm_sales_chg_list',
      'exp_csm_sales_chg_list',
      <String, Object?>{},
    ),
  ]) {
    test('${item.$1} queries and exports the actual drawer contract', () async {
      final adapter = _Adapter([
        {
          'code': 1,
          'data': {
            'records': [],
            'orders': [],
            'pays': [],
            'prd_type': [],
            'biz_types': [],
          },
        },
        <int>[80, 75, 3, 4, 0, 0, 0, 0],
      ]);
      final api = _api(adapter);
      final query = CashierReportQuery(title: item.$1);
      final result = await api.loadReportPage(ClientKind.cashier, query: query);
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.first.uri.path, '/sel/rpt/${item.$2}');
      expect(adapter.requests.first.data, item.$4);
      final exported = await api.exportReport(ClientKind.cashier, query: query);
      expect(exported.failureOrNull, isNull);
      expect(adapter.requests.last.uri.path, '/sel/rpt/${item.$3}');
      expect(adapter.requests.last.data, item.$4);
      expect(adapter.requests.map((r) => r.headers['tt']), everyElement('8'));
      final count = adapter.requests.length;
      expect(
        (await api.loadReportPage(
          ClientKind.order,
          query: query,
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests.length, count);
    });
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
