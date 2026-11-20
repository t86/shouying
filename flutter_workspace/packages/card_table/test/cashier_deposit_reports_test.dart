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
    'repayment and all deposit money fields convert fen exactly once',
    () async {
      for (final title in ['挂账还款记录表', '预订金流水表', '预订金余额表']) {
        final row = title == '挂账还款记录表'
            ? {'o': '21:00', 'a': '挂账A', 'e': '操作员', 'r': '现金', 'm': 12345}
            : title == '预订金流水表'
            ? {
                's': 'A01',
                'n': '客人',
                'p': '13800000000',
                't': '使用',
                'b': '2026-09-20',
                'o': '21:00',
                'a': -101,
                'bb': 10000,
                'ab': 9899,
              }
            : {
                'id': 7,
                'n': '客人',
                'p': '13800000000',
                'ub': 12345,
                'la': 0,
                'ca': 200,
                'ba': 1,
              };
        final result =
            (await _api(
                  _Adapter([
                    {
                      'code': 1,
                      'data': {
                        'records': [row],
                        'row_cnt': 23,
                      },
                    },
                  ]),
                ).loadReportPage(
                  ClientKind.cashier,
                  query: CashierReportQuery(
                    title: title,
                    page: 2,
                    pageSize: 10,
                    startDay: '2026-09-20',
                    endDay: '2026-09-22',
                  ),
                ))
                .valueOrNull!;
        if (title == '挂账还款记录表') {
          expect(result.rows.single['还款金额'], '123.45');
          expect(result.rows.single['挂账账号'], '挂账A');
        }
        if (title == '预订金流水表') {
          expect(result.rows.single['操作金额'], '-1.01');
          expect(result.rows.single['操作前余额'], '100.00');
          expect(result.rows.single['操作后余额'], '98.99');
        }
        if (title == '预订金余额表') {
          expect(result.rows.single.id, '7');
          expect(result.rows.single['可用金额'], '123.45');
          expect(result.rows.single['锁定金额'], '0.00');
          expect(result.rows.single['退款金额'], '0.01');
        }
        if (title != '挂账还款记录表') {
          expect(result.page, 2);
          expect(result.pageSize, 10);
          expect(result.total, 23);
        }
      }
    },
  );
  test('customer detail reads and exports only actual cust_id without guessed pagination', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'a': 10, 'bb': 20, 'ab': 30},
          ],
        },
      },
      <int>[80, 75, 3, 4, 0, 0, 0, 0],
    ]);
    final api = _api(adapter);
    const query = CashierReportQuery(
      title: '预订金余额表',
      customerId: '7',
      page: 4,
      pageSize: 10,
      keyword: '不应发送',
    );
    final page = (await api.loadReportPage(
      ClientKind.cashier,
      query: query,
    )).valueOrNull!;
    expect(page.rows.single['操作金额'], '0.10');
    expect(
      adapter.requests.single.uri.path,
      '/sel/rpt/get_one_cust_prepay_log',
    );
    expect(adapter.requests.single.data, {'cust_id': 7});
    await api.exportReport(ClientKind.cashier, query: query);
    expect(adapter.requests.last.uri.path, '/sel/rpt/exp_one_cust_prepay_log');
    expect(adapter.requests.last.data, {'cust_id': 7});
  });
  test(
    'invalid dates identifiers payloads and roles are not silently accepted',
    () async {
      final adapter = _Adapter([]);
      final api = _api(adapter);
      for (final query in [
        const CashierReportQuery(
          title: '预订金流水表',
          startDay: '2026-02-30',
          endDay: '2026-03-01',
        ),
        const CashierReportQuery(
          title: '预订金流水表',
          startDay: '2026-09-22',
          endDay: '2026-09-21',
        ),
        const CashierReportQuery(title: '预订金余额表', customerId: '0'),
        const CashierReportQuery(title: '预订金余额表', customerId: 'bad'),
      ]) {
        expect(
          (await api.loadReportPage(
            ClientKind.cashier,
            query: query,
          )).failureOrNull,
          isNotNull,
        );
        expect(
          (await api.exportReport(
            ClientKind.cashier,
            query: query,
          )).failureOrNull,
          isNotNull,
        );
      }
      expect(
        (await api.loadReportPage(
          ClientKind.order,
          query: const CashierReportQuery(title: '挂账还款记录表'),
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
      for (final data in [
        {'records': [], 'row_cnt': 'bad'},
        {
          'records': [
            {'n': '没有真实ID'},
          ],
          'row_cnt': 1,
        },
        {
          'records': [
            {'id': 7, 'ub': 'not-money'},
          ],
          'row_cnt': 1,
        },
      ]) {
        expect(
          (await _api(
                _Adapter([
                  {'code': 1, 'data': data},
                ]),
              ).loadReportPage(
                ClientKind.cashier,
                query: const CashierReportQuery(title: '预订金余额表'),
              ))
              .failureOrNull,
          isNotNull,
        );
      }
    },
  );
  testWidgets(
    'deposit history defaults now minus eight hours and preserves keyword on reset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final queries = <CashierReportQuery>[], exports = <CashierReportQuery>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '预订金流水表',
            now: () => DateTime(2026, 9, 22, 7, 30),
            onLoadPage: (q) async {
              queries.add(q);
              return Success(
                CashierReportPage(
                  total: 25,
                  page: q.page,
                  pageSize: q.pageSize,
                ),
              );
            },
            onExportData: (q) async {
              exports.add(q);
              return const Success('log.xlsx');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(queries.last.startDay, '2026-09-21');
      expect(queries.last.pageSize, 10);
      await tester.enterText(
        find.byKey(const Key('cashier-report-keyword')),
        '张三',
      );
      await tester.tap(find.text('下一页'));
      await tester.pumpAndSettle();
      expect(queries.last.page, 2);
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(queries.last.page, 2);
      await tester.tap(find.text('导出Excel'));
      await tester.pumpAndSettle();
      expect(exports.single.page, 2);
      expect(exports.single.keyword, '张三');
      await tester.enterText(
        find.byKey(const Key('cashier-report-start-day')),
        '2026-08-01',
      );
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(queries.last.startDay, '2026-09-21');
      expect(queries.last.keyword, '张三');
      expect(queries.last.page, 1);
      expect(queries.last.pageSize, 10);
      expect(find.text('打印'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'balance details export customer then back restores list page and keyword',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final queries = <CashierReportQuery>[], exports = <CashierReportQuery>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '预订金余额表',
            onLoadPage: (q) async {
              queries.add(q);
              return Success(
                q.customerId == null
                    ? CashierReportPage(
                        total: 21,
                        page: q.page,
                        pageSize: 10,
                        rows: const [
                          CashierReportRow(
                            id: '7',
                            cells: {'客人姓名': '客人甲', '可用金额': '12.34'},
                          ),
                        ],
                      )
                    : const CashierReportPage(
                        rows: [
                          CashierReportRow(
                            id: 'd',
                            cells: {'卡台名称': 'A01', '操作金额': '1.00'},
                          ),
                        ],
                      ),
              );
            },
            onExportData: (q) async {
              exports.add(q);
              return const Success('balance.xlsx');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('cashier-report-keyword')),
        '客人甲',
      );
      await tester.tap(find.text('下一页'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('查看详情'));
      await tester.pumpAndSettle();
      expect(queries.last.customerId, '7');
      expect(find.text('预订金流水详情'), findsOneWidget);
      expect(find.text('下一页'), findsNothing);
      await tester.tap(find.text('导出Excel'));
      await tester.pumpAndSettle();
      expect(exports.single.customerId, '7');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(queries.last.customerId, isNull);
      expect(queries.last.page, 2);
      expect(queries.last.keyword, '客人甲');
      expect(find.text('客人甲'), findsWidgets);
      expect(find.text('打印'), findsNothing);
    },
  );
  testWidgets('leaving customer detail discards a delayed response', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<Result<CashierReportPage>>();
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '预订金余额表',
          onLoadPage: (q) async => q.customerId != null
              ? pending.future
              : const Success(
                  CashierReportPage(
                    total: 1,
                    pageSize: 10,
                    rows: [
                      CashierReportRow(id: '7', cells: {'客人姓名': '甲'}),
                    ],
                  ),
                ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看详情'));
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    pending.complete(
      const Success(
        CashierReportPage(
          rows: [
            CashierReportRow(id: 'stale', cells: {'卡台名称': '旧明细'}),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('旧明细'), findsNothing);
    expect(find.text('查看详情'), findsOneWidget);
  });
  for (final entry in [
    ('挂账还款记录表', 'get_cnl_account_rtn_list', 'exp_cnl_account_rtn_list'),
    ('预订金流水表', 'get_cust_prepay_log', 'get_cust_prepay_log'),
    ('预订金余额表', 'get_cust_prepay_bal', 'exp_cust_prepay_bal'),
  ]) {
    test('${entry.$1} real read and binary export contracts', () async {
      final adapter = _Adapter([
        {
          'code': 1,
          'data': {'records': [], 'row_cnt': 0},
        },
        <int>[80, 75, 3, 4, 0, 0, 0, 0],
      ]);
      final api = _api(adapter);
      final query = CashierReportQuery(
        title: entry.$1,
        page: 2,
        pageSize: 10,
        startDay: '2026-09-20',
        endDay: '2026-09-22',
        keyword: '客人',
      );
      final result = await api.loadReportPage(ClientKind.cashier, query: query);
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.single.uri.path, '/sel/rpt/${entry.$2}');
      final body = entry.$1 == '挂账还款记录表'
          ? null
          : <String, Object?>{
              'page_num': 2,
              'page_size': 10,
              'key': '客人',
              if (entry.$1 == '预订金流水表') ...{
                'begin_day': '2026-09-20',
                'end_day': '2026-09-22',
              },
            };
      expect(adapter.requests.single.data, body);
      expect(
        (await api.exportReport(
          ClientKind.cashier,
          query: query,
        )).failureOrNull,
        isNull,
      );
      expect(adapter.requests.last.uri.path, '/sel/rpt/${entry.$3}');
      expect(adapter.requests.last.data, body);
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
