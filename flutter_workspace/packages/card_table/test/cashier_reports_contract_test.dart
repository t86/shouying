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
    'cashier cocktail detail and total preserve historical sa including zero',
    () async {
      for (final title in ['鸡尾酒明细表', '鸡尾酒汇总表']) {
        final adapter = _Adapter([
          {
            'code': 1,
            'data': {
              'records': [
                {'a': '77', 'sa': '100'},
                {'a': '5', 'sa': '0'},
                {'a': '2'},
                {'a': '84', 'sa': '102', 'n': '合计'},
              ],
            },
          },
        ]);
        final result = await _api(adapter)
            .loadReportData(ClientKind.cashier, reportTitle: title);
        final rows = result.valueOrNull!;
        expect(rows[0]['点单金额'], '原价：100.00\n方案价：77.00');
        expect(rows[1]['点单金额'], '原价：0.00\n方案价：5.00');
        expect(rows[2]['点单金额'], '2.00');
        expect(rows[3]['点单金额'], '原价：102.00\n方案价：84.00');
      }
    },
  );
  testWidgets(
    'revoking payment dialog removes only that route, never newer login',
    (tester) async {
      tester.view.physicalSize = const Size(2200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final access = ValueNotifier(true), modify = ValueNotifier(true);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: CashierReportScreen(
            title: '支付记录',
            canRead: access,
            canModifyPayment: modify,
            onLoadPage: (_) async => const Success(
              CashierReportPage(
                rows: [
                  CashierReportRow(
                    id: '91',
                    cells: {'卡台': 'A01', '支付方式': '现金', '订单绑定会员': '客户'},
                  ),
                ],
              ),
            ),
            onChangePaymentCustomer: (_, _) async => const Success(null),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('修改订单绑定会员'));
      await tester.pumpAndSettle();
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('新的登录页')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      access.value = false;
      await tester.pumpAndSettle();
      expect(find.text('新的登录页'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('payment-member-phone')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      access.dispose();
      modify.dispose();
    },
  );
  testWidgets(
    'successful unbind reloads row and disables repeated cancellation',
    (tester) async {
      tester.view.physicalSize = const Size(2200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final modify = ValueNotifier(true);
      var bound = true, loads = 0, writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '支付记录',
            canModifyPayment: modify,
            onLoadPage: (_) async {
              loads++;
              return Success(
                CashierReportPage(
                  rows: [
                    CashierReportRow(
                      id: '91',
                      cells: {
                        '卡台': 'A01',
                        '支付方式': '现金',
                        '订单绑定会员': bound ? '客户' : '',
                      },
                    ),
                  ],
                ),
              );
            },
            onChangePaymentCustomer: (id, phone) async {
              expect(id, '91');
              expect(phone, '');
              writes++;
              bound = false;
              return const Success(null);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消绑定'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(loads, 2);
      expect(writes, 1);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '取消绑定'))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      modify.dispose();
    },
  );
  test('payment rows without real identity fail closed instead of inventing write ids', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'n': 'A01', 'pa': 2, 'pi': '现金'},
          ],
        },
      },
    ]);
    final result = await _api(adapter).loadReportPage(
      ClientKind.cashier,
      query: const CashierReportQuery(title: '支付记录'),
    );
    expect(result.failureOrNull?.code, 'report.invalid_data');
  });
  testWidgets('typed region selection is used by query and export', (
    tester,
  ) async {
    CashierReportQuery? loaded, exported;
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '区域实时营收',
          onLoadOptions: (_) async =>
              const Success(CashierReportOptions(regions: {7: '七区'})),
          onLoadPage: (query) async {
            loaded = query;
            return const Success(CashierReportPage());
          },
          onExportData: (query) async {
            exported = query;
            return const Success('下载文件.xlsx');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('七区').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    expect(loaded!.regionId, 7);
    await tester.tap(find.text('导出Excel'));
    await tester.pumpAndSettle();
    expect(exported!.regionId, 7);
    expect(find.text('导出完成：下载文件.xlsx'), findsOneWidget);
  });
  testWidgets(
    'KPI salesperson matches code and pinyin without replacing selected ids',
    (tester) async {
      CashierReportQuery? loaded;
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '业绩日报表',
            onLoadOptions: (_) async => const Success(
              CashierReportOptions(
                salesEmployees: {9: '张三'},
                salesSearchTerms: {9: '0009 zs'},
                departments: {8: '市场部'},
              ),
            ),
            onLoadPage: (query) async {
              loaded = query;
              return const Success(CashierReportPage());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zs');
      await tester.pumpAndSettle();
      await tester.tap(find.text('张三').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(loaded!.salesEmpId, 9);
    },
  );
  testWidgets(
    'typed payment pagination and permission revocation ignore old completion',
    (tester) async {
      final access = ValueNotifier(true);
      final pending = Completer<Result<CashierReportPage>>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '支付记录',
            canRead: access,
            onLoadPage: (query) async {
              calls++;
              return calls == 1
                  ? const Success(
                      CashierReportPage(
                        rows: [
                          CashierReportRow(id: '91', cells: {'卡台': 'A01'}),
                        ],
                        total: 41,
                      ),
                    )
                  : pending.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一页'));
      await tester.pump();
      access.value = false;
      await tester.pumpAndSettle();
      pending.complete(
        const Success(
          CashierReportPage(
            rows: [
              CashierReportRow(id: '92', cells: {'卡台': '不应显示'}),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('不应显示'), findsNothing);
      expect(find.textContaining('当前无法读取报表'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      access.dispose();
    },
  );
  testWidgets(
    'payment binding handles missing member and leaves failures visible',
    (tester) async {
      tester.view.physicalSize = const Size(2200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final modify = ValueNotifier(true);
      String? target, phone;
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '支付记录',
            canModifyPayment: modify,
            onLoadPage: (_) async => const Success(
              CashierReportPage(
                rows: [
                  CashierReportRow(
                    id: '91',
                    cells: {'卡台': 'A01', '支付方式': '现金', '订单绑定会员': '旧客户'},
                  ),
                ],
                total: 1,
              ),
            ),
            onFindPaymentCustomer: (_) async => const Success(null),
            onChangePaymentCustomer: (id, value) async {
              target = id;
              phone = value;
              return const FailureResult(
                AppFailure(
                  kind: FailureKind.business,
                  code: 'test',
                  safeMessage: '绑定被拒绝',
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('修改订单绑定会员'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('payment-member-phone')),
        '13800000000',
      );
      await tester.tap(find.text('搜索会员'));
      await tester.pumpAndSettle();
      expect(find.textContaining('仍可绑定'), findsOneWidget);
      await tester.tap(find.text('确认更改'));
      await tester.pumpAndSettle();
      expect(target, '91');
      expect(phone, '13800000000');
      expect(find.text('修改订单绑定会员'), findsWidgets);
      expect(find.text('绑定被拒绝'), findsWidgets);
      await tester.tap(find.text('取消').last);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      modify.dispose();
    },
  );
  test(
    'pay records preserve keyword pagination and real binding identity',
    () async {
      final adapter = _Adapter([
        {
          'code': 1,
          'data': {
            'row_cnt': 41,
            'page_num': 2,
            'page_size': 20,
            'records': [
              {
                'id': 91,
                'n': 'A01',
                'p': '10:00',
                'pe': '-',
                'pa': '12.50',
                'pi': '自助微信',
                'c': '客户',
                'pt': '卡-2',
              },
            ],
          },
        },
      ]);
      final result = await _api(adapter).loadReportPage(
        ClientKind.cashier,
        query: const CashierReportQuery(title: '支付记录', keyword: 'A01', page: 2),
      );
      expect(adapter.requests.single.uri.path, '/sel/get_pay_list');
      expect(adapter.requests.single.data, {
        'key': 'A01',
        'page_num': 2,
        'page_size': 20,
      });
      expect(result.valueOrNull!.rows.single.id, '91');
      expect(result.valueOrNull!.rows.single['结账人'], '自助收银');
      expect(result.valueOrNull!.total, 41);
    },
  );
  test(
    'online summary uses no body and retains header and every payment total',
    () async {
      final adapter = _Adapter([
        {
          'code': 1,
          'data': {
            'org_name': '店',
            'biz_day': '2026-09-20',
            'pays': [
              {'n': '微信', 'pc': 3, 'pa': '12.50', 'bc': 1, 'ba': '1.00'},
            ],
          },
        },
        {'code': 1},
      ]);
      final api = _api(adapter);
      final result = await api.loadReportPage(
        ClientKind.cashier,
        query: const CashierReportQuery(title: '线上支付汇总'),
      );
      expect(adapter.requests.single.uri.path, '/sel/get_ol_pay_bill');
      expect(adapter.requests.single.data, isNull);
      expect(result.valueOrNull!.rows.single['营业日期'], '2026-09-20');
      expect(result.valueOrNull!.rows.single['成功金额'], '12.50');
      expect(
        (await api.printReport(
          ClientKind.cashier,
          title: '线上支付汇总',
        )).failureOrNull,
        isNull,
      );
      expect(adapter.requests.last.uri.path, '/sel/prt_ol_pay_bill');
      expect(adapter.requests.last.data, isNull);
    },
  );
  test('region and KPI use selected ids and convert cents once', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {
              'r': 'A区',
              'c': 2,
              'zp': 1234,
              'zup': 1,
              't': 1235,
              'fzp': 200,
              'fzup': 0,
              'ft': 200,
            },
          ],
        },
      },
      {
        'code': 1,
        'data': {
          'records': [
            {
              'n': '  部门',
              'r': 'A',
              's': '01',
              'e': '员工',
              'oc': 2,
              'z': 1234,
              'v': 1000,
              'y': 800,
              'u': 200,
              'h': 234,
            },
          ],
        },
      },
    ]);
    final api = _api(adapter);
    final region = await api.loadReportPage(
      ClientKind.cashier,
      query: const CashierReportQuery(title: '区域实时营收', regionId: 7),
    );
    expect(adapter.requests.last.uri.path, '/sel/rpt/get_region_real_amts');
    expect(adapter.requests.last.data, {'id': 7});
    expect(region.valueOrNull!.rows.single['主营已付'], '12.34');
    final kpi = await api.loadReportPage(
      ClientKind.cashier,
      query: const CashierReportQuery(
        title: '业绩日报表',
        groupType: 5,
        deptId: 8,
        salesEmpId: 9,
      ),
    );
    expect(adapter.requests.last.data, {
      'type_id': 5,
      'dept_id': 8,
      'sales_emp_id': 9,
    });
    expect(kpi.valueOrNull!.rows.single['折前(含未结金额)'], '12.34');
    expect(kpi.valueOrNull!.rows.single['订台数'], '2');
  });
  test(
    'discount expands grouped details without multiplying parent totals',
    () async {
      final adapter = _Adapter([
        {
          'code': 1,
          'data': {
            'records': [
              {
                'ad': '营销部',
                'ae': '员工',
                'a': '20',
                'dtls': [
                  {'rn': '区域', 'n': '酒', 'a': '10', 'es': '功能台'},
                  {'n': '茶', 'a': '10'},
                ],
              },
            ],
          },
        },
      ]);
      final result = await _api(adapter).loadReportPage(
        ClientKind.cashier,
        query: const CashierReportQuery(
          title: '优惠明细表',
          discountType: 2,
          keyword: '酒',
        ),
      );
      expect(adapter.requests.single.data, {'yh_type': 2, 'key': '酒'});
      expect(result.valueOrNull!.rows.first['优惠总额'], '20');
      expect(result.valueOrNull!.rows.last['优惠总额'], '');
      expect(result.valueOrNull!.rows.first['优惠2关联功能台'], '功能台');
    },
  );
  test('exports use identical filters and actual XLSX bytes', () async {
    for (final (query, path, body)
        in <(CashierReportQuery, String, Map<String, Object?>)>[
          (
            const CashierReportQuery(title: '区域实时营收', regionId: 7),
            '/sel/rpt/exp_region_real_amts',
            {'id': 7},
          ),
          (
            const CashierReportQuery(
              title: '业绩日报表',
              groupType: 4,
              deptId: 8,
              salesEmpId: 9,
            ),
            '/sel/rpt/exp_yj_rpt',
            {'type_id': 4, 'dept_id': 8, 'sales_emp_id': 9},
          ),
          (
            const CashierReportQuery(
              title: '优惠明细表',
              discountType: 2,
              keyword: '酒',
            ),
            '/sel/rpt/exp_yh_list',
            {'yh_type': 2, 'key': '酒'},
          ),
        ]) {
      final adapter = _Adapter([
        <int>[80, 75, 3, 4, 1],
      ]);
      final result = await _api(adapter)
          .exportReport(ClientKind.cashier, query: query);
      expect(adapter.requests.single.uri.path, path);
      expect(adapter.requests.single.data, body);
      expect(result.failureOrNull?.code, isNull);
      expect(result.valueOrNull!.bytes, [80, 75, 3, 4, 1]);
    }
  });
  test('member search and bind/unbind preserve exact source bodies', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'name': '甲', 'phone': '13800000000', 'bal': '3.00', 'pt': 5},
      },
      {'code': 1},
      {'code': 1},
    ]);
    final api = _api(adapter);
    final found = await api.findPaymentCustomer(
      ClientKind.cashier,
      phone: '13800000000',
    );
    expect(found.valueOrNull!.name, '甲');
    expect(adapter.requests.first.uri.path, '/sel/get_cust_info_by_phonenum');
    expect(adapter.requests.first.data, {'phone_num': '13800000000'});
    await api.changePaymentCustomer(
      ClientKind.cashier,
      paymentId: '91',
      phone: '13800000000',
    );
    await api.changePaymentCustomer(
      ClientKind.cashier,
      paymentId: '91',
      phone: '',
    );
    expect(adapter.requests[1].data, {'id': 91, 'phone': '13800000000'});
    expect(adapter.requests.last.data, {'id': 91, 'phone': ''});
    expect(adapter.requests.last.uri.path, '/sel/chg_pay_cust');
  });
  test('five additional reports expose source-backed contracts', () {
    for (final title in ['支付记录', '线上支付汇总', '区域实时营收', '业绩日报表', '优惠明细表']) {
      expect(
        CashierReportCatalog.reports[title]!.supported,
        isTrue,
        reason: title,
      );
    }
  });
  test('shift uses source all filters and map sections', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'org_name': '门店A',
          'value_amt': '45.00',
          'pays': [
            {'p': '现金', 'a': '40.00'},
          ],
          'orders': [
            {'c': '酒水', 'a': '45.00'},
          ],
        },
      },
    ]);
    final result = await _api(adapter)
        .loadReportData(ClientKind.cashier, reportTitle: '班结表');
    expect(adapter.requests.single.uri.path, '/wkd/get_bj');
    expect(adapter.requests.single.data, {
      'region_ids': [-1],
      'cashier_ids': [-1],
    });
    expect(result.valueOrNull!.first['数值'], '门店A');
    expect(
      result.valueOrNull!.where((row) => row['项目'] == '支付渠道 · 现金').single['数值'],
      '40.00',
    );
  });
  test('sold daily obtains source default library and sums counts', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'prt_mk_libs': [
            {'id': 23, 'n': '出品库'},
          ],
        },
      },
      {
        'code': 1,
        'data': {
          'records': [
            {'n': '酒', 'c': 3},
          ],
        },
      },
    ]);
    final result = await _api(adapter)
        .loadReportData(ClientKind.cashier, reportTitle: '售出日报表');
    expect(adapter.requests.first.uri.path, '/sel/rpt/get_sold_out_rpt_items');
    expect(adapter.requests.first.data, isNull);
    expect(adapter.requests.last.uri.path, '/sel/rpt/get_sold_out_rpt');
    expect(adapter.requests.last.data, {
      'is_all_cate': 1,
      'is_all_mklib': 1,
      'two_cate_ids': [],
      'mklib_ids': [],
      'status': 0,
      'prt_mklib_id': 23,
      'sold_type': 0,
    });
    expect(result.valueOrNull!.last['售出数量'], '3');
  });
  test('minimum report preserves no body and exact fields', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'sn': 'A01', 'p': '20%', 'ga': '-100.00'},
          ],
        },
      },
    ]);
    final result = await _api(adapter)
        .loadReportData(ClientKind.cashier, reportTitle: '低消进度统计表');
    expect(adapter.requests.single.uri.path, '/wo/get_seat_zy_csm_list');
    expect(adapter.requests.single.data, isNull);
    expect(result.valueOrNull!.single['卡台名称'], 'A01');
    expect(result.valueOrNull!.single['低消进度'], '20%');
  });
  test(
    'detail columns use source abbreviated fields without guessing',
    () async {
      final adapter = _Adapter([
        {
          'code': 1,
          'data': {
            'records': [
              {
                'rn': '区域',
                's': 'A01',
                'o': '下单',
                'pt': '结账',
                'a': '25.00',
                'm': '备注',
              },
            ],
          },
        },
      ]);
      final result = await _api(adapter).loadReportData(
        ClientKind.cashier,
        reportTitle: '鸡尾酒明细表',
        keyword: 'A01',
      );
      expect(adapter.requests.single.uri.path, '/sel/rpt/get_hl_list');
      expect(adapter.requests.single.data, {'key': 'A01'});
      expect(result.valueOrNull!.single['下单/补交时间'], '下单');
      expect(result.valueOrNull!.single['点单金额'], '25.00');
    },
  );
  test('malformed records fail instead of reporting no records', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'records': 'invalid'},
      },
    ]);
    final result = await _api(adapter)
        .loadReportData(ClientKind.cashier, reportTitle: '鸡尾酒汇总表');
    expect(result.failureOrNull?.kind, FailureKind.protocol);
  });
  testWidgets('revoking access clears data and ignores pending completion', (
    tester,
  ) async {
    final access = ValueNotifier(true);
    final pending = Completer<Result<List<CashierReportRow>>>();
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '鸡尾酒汇总表',
          canRead: access,
          onLoadData: (_, _, _, _) => pending.future,
        ),
      ),
    );
    access.value = false;
    await tester.pump();
    pending.complete(
      const Success([
        CashierReportRow(id: '1', cells: {'商品名称': '不应出现'}),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('不应出现'), findsNothing);
    expect(find.text('当前无法读取报表，请检查登录和连接状态'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    access.dispose();
  });
  test('source cocktail contract uses key and data.records', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'wd': '部门', 'w': '员工', 'n': '酒', 'a': '12.30'},
          ],
        },
      },
    ]);
    final result = await _api(
      adapter,
    ).loadReportData(ClientKind.cashier, reportTitle: '鸡尾酒汇总表', keyword: '酒');
    expect(adapter.requests.single.uri.path, '/sel/rpt/get_hl_rpt_sum_list');
    expect(adapter.requests.single.data, {'key': '酒'});
    expect(result.valueOrNull!.single['点单金额'], '12.30');
    expect(result.valueOrNull!.single['点单人部门'], '部门');
  });
  test('unsupported reports fail without a request', () async {
    final adapter = _Adapter([]);
    final api = _api(adapter);
    expect(
      CashierReportCatalog.reports.values
          .where((meta) => meta.supported)
          .length,
      29,
    );
    for (final meta in CashierReportCatalog.reports.values.where(
      (meta) => !meta.supported,
    )) {
      final result = await api.loadReportData(
        ClientKind.cashier,
        reportTitle: meta.title,
      );
      expect(result.failureOrNull?.code, 'report.unavailable');
      expect(meta.apiPath, isEmpty);
    }
    expect(adapter.requests, isEmpty);
  });
  test('business errors never become empty success', () async {
    final adapter = _Adapter([
      {'code': 0, 'msg': 'private'},
    ]);
    final result = await _api(adapter)
        .loadReportData(ClientKind.cashier, reportTitle: '鸡尾酒明细表');
    expect(result.failureOrNull, isNotNull);
  });
  testWidgets('failure is visible and retry succeeds', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '鸡尾酒汇总表',
          onLoadData: (_, _, _, _) async {
            if (++attempts == 1) {
              return const FailureResult(
                AppFailure(
                  kind: FailureKind.network,
                  code: 'test',
                  safeMessage: '网络不可用',
                ),
              );
            }
            return const Success([
              CashierReportRow(id: '1', cells: {'商品名称': '测试酒'}),
            ]);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('网络不可用'), findsOneWidget);
    tester
        .widget<TextButton>(find.widgetWithText(TextButton, '重试'))
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('测试酒'), findsOneWidget);
  });
}

ProtocolCashierReportsApi _api(_Adapter adapter) {
  var now = DateTime(2026);
  return ProtocolCashierReportsApi(
    client: ProtocolClient(
      dio: Dio()..httpClientAdapter = adapter,
      config: ApiConfig(
        apiBase: Uri.parse('https://example.test'),
        onlineBase: Uri.parse('https://example.test'),
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
    if (response is List<int>)
      return ResponseBody.fromBytes(
        response,
        200,
        headers: {
          'content-type': ['application/octet-stream'],
          'content-disposition': ['attachment; filename=report.xlsx'],
        },
      );
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
