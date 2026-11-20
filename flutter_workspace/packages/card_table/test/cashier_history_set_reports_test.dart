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
  testWidgets(
    'set printing cannot double dispatch or stay current during return animation',
    (tester) async {
      final pending = Completer<Result<void>>();
      bool Function()? current;
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              child: const Text('open'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CashierReportScreen(
                    title: '套餐统计表',
                    onLoadPage: (_) async => const Success(
                      CashierReportPage(
                        setCategories: [
                          CashierSetReportCategory(
                            id: 1,
                            name: '套餐',
                            products: {7: '套餐A'},
                          ),
                        ],
                      ),
                    ),
                    onPrintQuery: (query) {
                      calls++;
                      current = query.canDispatch;
                      return pending.future;
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final print = tester
          .widget<TextButton>(find.widgetWithText(TextButton, '打印'))
          .onPressed!;
      print();
      print();
      await tester.pump();
      expect(calls, 1);
      expect(current!(), true);
      Navigator.of(tester.element(find.byType(CashierReportScreen))).pop();
      await tester.pump();
      expect(current!(), false);
      pending.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('打印成功'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    },
  );
  test(
    'malformed history children and tree options never produce partial success',
    () async {
      for (final data in [
        {
          'records': [
            {'os': false},
          ],
        },
        {
          'records': [
            {
              'os': [false],
            },
          ],
        },
      ]) {
        expect(
          (await _api(
                _Adapter([
                  {'code': 1, 'data': data},
                ]),
              ).loadReportPage(
                ClientKind.cashier,
                query: const CashierReportQuery(title: '历史点单记录', wkdayId: 9),
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
                    'two_cates': [
                      {'id': 1, 'n': '套餐', 'ss': false},
                    ],
                  },
                },
              ]),
            ).loadReportPage(
              ClientKind.cashier,
              query: const CashierReportQuery(title: '套餐统计表', initialize: true),
            ))
            .failureOrNull,
        isNotNull,
      );
      expect(
        (await _api(
              _Adapter([
                {'code': 2},
              ]),
            ).printReportQuery(
              ClientKind.cashier,
              query: const CashierReportQuery(title: '套餐统计表'),
            ))
            .failureOrNull,
        isNotNull,
      );
    },
  );
  test('history initializes days then queries and exports selected day with fen detail amounts', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 9, 'n': '2026-09-21'},
            {'id': 8, 'n': '2026-09-20'},
          ],
        },
      },
      {
        'code': 1,
        'data': {
          'records': [
            {
              'c': 7,
              'b': '2026-09-21',
              'r': 'A区',
              's': 'A01-1',
              'se': '订位甲',
              'sd': '营销',
              'ss': '主管',
              'o': 12345,
              'p': 10000,
              'pi': '现金',
              'os': [
                {
                  'o': '21:00',
                  'pm': '22:00',
                  'd': '点单部',
                  'w': '员工',
                  'ws': '组长',
                  'ri': 'B01',
                  'co': '是',
                  'on': '酒',
                  'tn': '啤酒',
                  'p': '套餐',
                  'pt': '套餐类',
                  'bt': '主营',
                  'c': 2,
                  'oa': 12345,
                  'pa': 10000,
                  'pi': '现金',
                },
              ],
            },
          ],
        },
      },
      <int>[80, 75, 3, 4, 0, 0, 0, 0],
    ]);
    final api = _api(adapter);
    final initial = (await api.loadReportPage(
      ClientKind.cashier,
      query: const CashierReportQuery(title: '历史点单记录', initialize: true),
    )).valueOrNull!;
    expect(initial.historyDays.keys, [9, 8]);
    expect(adapter.requests.single.data, isNull);
    expect(
      adapter.requests.single.uri.path,
      '/sel/rpt/get_csm_his_wkday_items',
    );
    const query = CashierReportQuery(
      title: '历史点单记录',
      wkdayId: 9,
      keyword: 'A01',
    );
    final page = (await api.loadReportPage(
      ClientKind.cashier,
      query: query,
    )).valueOrNull!;
    expect(adapter.requests.last.data, {'wkday_id': 9, 'key': 'A01'});
    expect(page.rows.single['总订单金额'], '123.45');
    expect(page.rows.single['总实收金额'], '100.00');
    final detail = page.rows.single.details.single;
    expect(detail.cells.length, 16);
    expect(detail['点单金额'], '123.45');
    expect(detail['实收金额'], '100.00');
    expect(detail['点单人岗位'], '组长');
    expect(detail['关联台'], 'B01');
    expect(
      (await api.exportReport(ClientKind.cashier, query: query)).failureOrNull,
      isNull,
    );
    expect(adapter.requests.last.uri.path, '/sel/rpt/exp_csm_his');
    expect(adapter.requests.last.data, {'wkday_id': 9, 'key': 'A01'});
  });
  test('set tree init flattened parent and child quantities plus identical print payload', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'two_cates': [
            {
              'id': 2,
              'n': '啤酒套餐',
              'ss': [
                {'id': 7, 'n': '套餐A'},
              ],
            },
          ],
        },
      },
      {
        'code': 1,
        'data': {
          'prd_sets': [
            {
              'n': '套餐A',
              'c': 2,
              'ss': [
                {'n': '啤酒', 'c': 12},
                {'n': '小吃', 'c': 2},
              ],
            },
          ],
        },
      },
      {'code': 1},
    ]);
    final api = _api(adapter);
    final initial = (await api.loadReportPage(
      ClientKind.cashier,
      query: const CashierReportQuery(title: '套餐统计表', initialize: true),
    )).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/sel/rpt/get_set_cnt_items');
    expect(adapter.requests.single.data, isNull);
    expect(initial.setCategories.single.products, {7: '套餐A'});
    const query = CashierReportQuery(
      title: '套餐统计表',
      setAll: false,
      setCategoryIds: [2],
      setProductIds: [8],
      setStatus: 5,
    );
    final page = (await api.loadReportPage(
      ClientKind.cashier,
      query: query,
    )).valueOrNull!;
    expect(page.rows.map((r) => r['售出数量']), ['2', '12', '2']);
    expect(page.rows.first['套餐'], '套餐A');
    expect(page.rows[1]['商品名称'], '啤酒');
    expect(adapter.requests.last.data, {
      'all': 2,
      'two_cate_ids': [2],
      'prd_ids': [8],
      'status': 5,
    });
    expect(
      (await api.printReportQuery(
        ClientKind.cashier,
        query: query,
        canDispatch: () => true,
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.last.uri.path, '/sel/rpt/prt_set_cnt_rpt');
    expect(adapter.requests.last.data, adapter.requests[1].data);
  });
  test(
    'invalid IDs statuses initialization and both print guards block request',
    () async {
      final adapter = _Adapter([]);
      final api = _api(adapter);
      for (final query in [
        const CashierReportQuery(title: '历史点单记录'),
        const CashierReportQuery(title: '历史点单记录', wkdayId: 0),
        const CashierReportQuery(title: '套餐统计表', setStatus: 2),
        const CashierReportQuery(
          title: '套餐统计表',
          setAll: false,
          setProductIds: [-1],
        ),
      ]) {
        expect(
          (await api.loadReportPage(
            ClientKind.cashier,
            query: query,
          )).failureOrNull,
          isNotNull,
        );
      }
      expect(
        (await api.printReportQuery(
          ClientKind.cashier,
          query: CashierReportQuery(title: '套餐统计表', canDispatch: () => false),
          canDispatch: () => true,
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await api.printReportQuery(
          ClientKind.cashier,
          query: CashierReportQuery(title: '套餐统计表', canDispatch: () => true),
          canDispatch: () => false,
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await api.printReportQuery(
          ClientKind.order,
          query: const CashierReportQuery(title: '套餐统计表'),
        )).failureOrNull,
        isNotNull,
      );
      expect(
        (await api.exportReport(
          ClientKind.cashier,
          query: const CashierReportQuery(title: '套餐统计表'),
        )).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
    },
  );
  testWidgets(
    'history first day autoquery switch reset expand and export match source',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final queries = <CashierReportQuery>[], exports = <CashierReportQuery>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '历史点单记录',
            onLoadPage: (q) async {
              queries.add(q);
              return Success(
                q.initialize
                    ? const CashierReportPage(historyDays: {9: '今天', 8: '昨天'})
                    : const CashierReportPage(
                        rows: [
                          CashierReportRow(
                            id: '1',
                            cells: {'卡台流水': 'A01', '总订单金额': '10.00'},
                            details: [
                              CashierReportRow(
                                id: 'd',
                                cells: {'商品名称': '历史商品', '点单金额': '10.00'},
                              ),
                            ],
                          ),
                        ],
                      ),
              );
            },
            onExportData: (q) async {
              exports.add(q);
              return const Success('history.xlsx');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(queries.length, 2);
      expect(queries.last.wkdayId, 9);
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      expect(find.text('历史商品'), findsOneWidget);
      tester
          .widget<DropdownButtonFormField<int>>(
            find.widgetWithText(DropdownButtonFormField<int>, '营业日'),
          )
          .onChanged!(8);
      await tester.pumpAndSettle();
      expect(queries.last.wkdayId, 8);
      await tester.enterText(
        find.byKey(const Key('cashier-report-keyword')),
        'A01',
      );
      await tester.tap(find.text('导出Excel'));
      await tester.pumpAndSettle();
      expect(exports.single.wkdayId, 8);
      expect(exports.single.keyword, 'A01');
      await tester.tap(find.text('重置'));
      await tester.pumpAndSettle();
      expect(queries.last.wkdayId, 9);
      expect(queries.last.keyword, isEmpty);
      expect(find.text('打印'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'set whole category overrides children partial selection and print use same query',
    (tester) async {
      final queries = <CashierReportQuery>[], prints = <CashierReportQuery>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '套餐统计表',
            onLoadPage: (q) async {
              queries.add(q);
              return Success(
                q.initialize
                    ? const CashierReportPage(
                        setCategories: [
                          CashierSetReportCategory(
                            id: 2,
                            name: '啤酒',
                            products: {7: '套餐A', 8: '套餐B'},
                          ),
                          CashierSetReportCategory(
                            id: 3,
                            name: '洋酒',
                            products: {9: '套餐C'},
                          ),
                        ],
                      )
                    : const CashierReportPage(),
              );
            },
            onPrintQuery: (q) async {
              prints.add(q);
              expect(q.canDispatch!(), true);
              return const Success(null);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(queries.length, 1);
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();
      expect(queries.last.setAll, true);
      expect(queries.last.setProductIds, isEmpty);
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('report-set-product-2-8')),
          )
          .onChanged!(false);
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<int>>(
            find.widgetWithText(DropdownButtonFormField<int>, '订单类型'),
          )
          .onChanged!(5);
      await tester.pump();
      await tester.tap(find.text('统计'));
      await tester.pumpAndSettle();
      expect(queries.last.setAll, false);
      expect(queries.last.setCategoryIds, [3]);
      expect(queries.last.setProductIds, [7]);
      expect(queries.last.setStatus, 5);
      await tester.tap(find.text('打印'));
      await tester.pumpAndSettle();
      expect(prints.single.setCategoryIds, [3]);
      expect(prints.single.setProductIds, [7]);
      expect(prints.single.setStatus, 5);
      expect(find.text('导出Excel'), findsNothing);
    },
  );
  testWidgets('empty history days suppress query and options failure retries', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '历史点单记录',
          onLoadPage: (q) async {
            calls++;
            return calls == 1
                ? const FailureResult(
                    AppFailure(
                      kind: FailureKind.network,
                      code: 'test',
                      safeMessage: '初始化失败',
                    ),
                  )
                : const Success(CashierReportPage());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('初始化失败'), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('暂无可查询营业日'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '查询'))
          .onPressed,
      isNull,
    );
  });
  for (final title in ['历史点单记录', '套餐统计表']) {
    testWidgets('$title initializes its actual report workspace', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: title,
            onLoadPage: (query) async {
              calls++;
              return const Success(CashierReportPage());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.textContaining('尚未'), findsNothing);
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
