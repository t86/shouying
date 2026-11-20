import 'package:dio/dio.dart';
import 'package:card_table/src/bms_api.dart';
import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_report_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

import 'bms_loader_guard_test.dart' show loginSession;
import 'bms_staff_contract_test.dart' show Adapter, Credentials;

void main() {
  test('report requests never send with another client kind', () async {
    final adapter = Adapter();
    for (final kind in ClientKind.values.where(
      (kind) => kind != ClientKind.orgManager,
    )) {
      expect(
        (await reportApi(adapter).requestReportConfiguration(
          kind,
          const BmsReportConfigurationRequest(
            BmsReportConfigurationOperation.channels,
          ),
        )).failureOrNull,
        isNotNull,
      );
    }
    expect(adapter.requests, isEmpty);
  });
  final filters = <String, Object?>{
    'name': '酒',
    'init': 1,
    'one_cate_id': 0,
    'two_cate_id': 0,
  };
  final cases =
      <(BmsReportConfigurationOperation, String, Map<String, Object?>?)>[
        (BmsReportConfigurationOperation.deptTree, 'get_dept_tree', null),
        (BmsReportConfigurationOperation.departmentTabs, 'get_hl_tabs', null),
        (
          BmsReportConfigurationOperation.addDepartmentTabs,
          'batch_add_hl_tabs',
          {
            'dept_ids': [7, 8],
          },
        ),
        (
          BmsReportConfigurationOperation.deleteDepartmentTab,
          'del_hl_tab',
          {'dept_id': 7},
        ),
        (
          BmsReportConfigurationOperation.waiterProducts,
          'get_waiter_sales_prds',
          null,
        ),
        (
          BmsReportConfigurationOperation.waiterProductItems,
          'get_waiter_sales_prd_items',
          {...filters, 'page_num': 2, 'page_size': 20},
        ),
        (
          BmsReportConfigurationOperation.addWaiterProducts,
          'add_waiter_sales_prds',
          {
            'prd_ids': [101],
          },
        ),
        (
          BmsReportConfigurationOperation.deleteWaiterProduct,
          'del_waiter_sales_prd',
          {'prd_id': 101},
        ),
        (
          BmsReportConfigurationOperation.statistics,
          'get_rpt_jk_cate_list',
          null,
        ),
        (
          BmsReportConfigurationOperation.createStatistic,
          'new_rpt_jk_cate',
          {'name': '分类', 'type_id': 1, 'biz_type': 3},
        ),
        (
          BmsReportConfigurationOperation.renameStatistic,
          'save_rpt_jk_cate_name',
          {'id': 7, 'name': '新分类'},
        ),
        (
          BmsReportConfigurationOperation.saveStatisticBusinessType,
          'save_rpt_jk_cate_biztype',
          {'id': 7, 'biz_type': 2},
        ),
        (
          BmsReportConfigurationOperation.deleteStatistics,
          'batch_del_rpt_jk_cate',
          {
            'ids': [7],
          },
        ),
        (
          BmsReportConfigurationOperation.moveStatistic,
          'move_rpt_jk_cate_dsp',
          {'id': 7, 'dest_id': 8, 'down_up': 2},
        ),
        (
          BmsReportConfigurationOperation.statisticCategoryItems,
          'get_rpt_jk_cate_cate_items',
          null,
        ),
        (
          BmsReportConfigurationOperation.saveStatisticCategories,
          'save_rpt_jk_cate_cates',
          {
            'id': 7,
            'cate_ids': [11, 12],
          },
        ),
        (
          BmsReportConfigurationOperation.statisticProducts,
          'get_rpt_jk_cate_prd_list',
          {'id': 7, ...filters},
        ),
        (
          BmsReportConfigurationOperation.statisticProductItems,
          'get_rpt_jk_cate_prd_items',
          filters,
        ),
        (
          BmsReportConfigurationOperation.addStatisticProducts,
          'batch_add_rpt_jk_cate_pitems',
          {
            'id': 7,
            'prd_ids': [101],
          },
        ),
        (
          BmsReportConfigurationOperation.deleteStatisticProducts,
          'batch_del_rpt_jk_cate_pitems',
          {
            'id': 7,
            'prd_ids': [101],
          },
        ),
        (BmsReportConfigurationOperation.channels, 'get_rpt_jk_cnl_list', null),
        (
          BmsReportConfigurationOperation.channelItems,
          'get_rpt_jk_cnl_dtl',
          null,
        ),
        (
          BmsReportConfigurationOperation.saveChannel,
          'new_or_save_rpt_jk_cnl',
          {
            'id': 0,
            'name': '现金组',
            'pay_cnl_ids': [1, 5],
          },
        ),
        (
          BmsReportConfigurationOperation.deleteChannels,
          'batch_del_rpt_jk_cnl',
          {
            'ids': [7],
          },
        ),
        (
          BmsReportConfigurationOperation.moveChannel,
          'move_rpt_jk_cnl_dsp',
          {'id': 7, 'dest_id': 8, 'down_up': 1},
        ),
        (
          BmsReportConfigurationOperation.highMarginProducts,
          'get_srv_ord_high_prd_cfg',
          {'key': '酒'},
        ),
        (
          BmsReportConfigurationOperation.highMarginProductItems,
          'get_srv_ord_high_prd_items',
          {...filters, 'page_num': 1, 'page_size': 20},
        ),
        (
          BmsReportConfigurationOperation.addHighMarginProducts,
          'add_srv_ord_high_prd_cfg',
          {
            'ids': [101],
          },
        ),
        (
          BmsReportConfigurationOperation.deleteHighMarginProducts,
          'del_srv_ord_high_prd_cfg',
          {
            'ids': [101],
          },
        ),
      ];
  for (final item in cases) {
    test('source contract ${item.$2}', () async {
      final adapter = Adapter()
        ..data = {'records': [], 'cates': [], 'prds': [], 'depts': []};
      final api = reportApi(adapter);
      final result = await api.requestReportConfiguration(
        ClientKind.orgManager,
        BmsReportConfigurationRequest(item.$1, parameters: item.$3 ?? {}),
      );
      expect(result.failureOrNull, isNull);
      expect(adapter.requests.single.uri.path, '/rpt/cfg/${item.$2}');
      expect(adapter.requests.single.data, item.$3);
      expect(adapter.requests.single.headers['tt'], '1');
    });
  }
  test('closed fields and invalid IDs reject before HTTP; non1 and malformed reads never succeed', () async {
    for (final parameters in [
      {'ids': <int>[]},
      {
        'ids': [0],
      },
      {
        'ids': [7, 7],
      },
      {
        'ids': [7],
        'path': '/evil',
      },
    ]) {
      final adapter = Adapter();
      final result = await reportApi(adapter).requestReportConfiguration(
        ClientKind.orgManager,
        BmsReportConfigurationRequest(
          BmsReportConfigurationOperation.deleteChannels,
          parameters: parameters,
        ),
      );
      expect(result.failureOrNull, isNotNull);
      expect(adapter.requests, isEmpty);
    }
    for (final code in [0, 2, 3]) {
      final adapter = Adapter()..code = code;
      expect(
        (await reportApi(adapter).requestReportConfiguration(
          ClientKind.orgManager,
          const BmsReportConfigurationRequest(
            BmsReportConfigurationOperation.channels,
          ),
        )).failureOrNull,
        isNotNull,
      );
    }
    final bad = Adapter()..data = [];
    expect(
      (await reportApi(bad).requestReportConfiguration(
        ClientKind.orgManager,
        const BmsReportConfigurationRequest(
          BmsReportConfigurationOperation.channels,
        ),
      )).failureOrNull,
      isNotNull,
    );
  });
  test(
    'report capability shares online session guard and identity-based context',
    () async {
      final adapter = Adapter()..data = {'records': []};
      final auth = Adapter();
      final session = SessionRepository(
        api: SessionApi(client: reportApi(auth).client),
        credentialStore: Credentials(),
      );
      var phase = ConnectionPhase.blocked, epoch = 1;
      final loader = ProtocolBmsLoader(
        api: reportApi(adapter),
        sessionRepository: session,
        phase: () => phase,
        generation: () => epoch,
      );
      expect(loader.configurationContext, isNull);
      const request = BmsReportConfigurationRequest(
        BmsReportConfigurationOperation.channels,
      );
      expect(
        (await loader.requestReportConfiguration(request)).failureOrNull,
        isNotNull,
      );
      expect(adapter.requests, isEmpty);
      await loginSession(session, auth, 1);
      phase = ConnectionPhase.online;
      final before = loader.configurationContext;
      expect(before, isNotNull);
      expect(before, loader.configurationContext);
      expect(
        (await loader.requestReportConfiguration(request)).failureOrNull,
        isNull,
      );
      adapter.onFetch = () => epoch++;
      expect(
        (await loader.requestReportConfiguration(request)).failureOrNull,
        isNotNull,
      );
      expect(before, isNot(loader.configurationContext));
      final sameEpochContext = loader.configurationContext;
      auth.data = {'emp_id': '1', 'name': '测试', 'station_id': '1'};
      expect(
        (await session.login(
          account: 'test',
          password: 'test',
          type: EmployeeLoginType.account,
        )).failureOrNull,
        isNull,
      );
      expect(sameEpochContext, isNot(loader.configurationContext));
      phase = ConnectionPhase.blocked;
      expect(loader.configurationContext, isNull);
    },
  );
}

ProtocolBmsApi reportApi(Adapter adapter) {
  var tick = DateTime(2026);
  return ProtocolBmsApi(
    client: ProtocolClient(
      dio: Dio()..httpClientAdapter = adapter,
      config: ApiConfig(
        apiBase: Uri.parse('https://example.test'),
        onlineBase: Uri.parse('https://online.example.test'),
        websocketBase: Uri.parse('wss://example.test'),
      ),
      credentialStore: Credentials(),
      requestGate: RequestGate(
        clock: () => tick = tick.add(const Duration(milliseconds: 1)),
      ),
    ),
  );
}
