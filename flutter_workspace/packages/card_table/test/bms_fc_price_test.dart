import 'package:flutter_test/flutter_test.dart';
import 'package:card_table/src/bms_nav_screen.dart';
import 'package:card_table/src/bms_fc_price.dart';
import 'package:protocol/protocol.dart';
import 'package:card_table/src/bms_loader.dart';
import 'package:session/session.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi, Credentials;

void main() {
  test(
    'all price commands keep BMS session guard before any request',
    () async {
      final adapter = Adapter();
      final api = makeApi(adapter);
      final session = SessionRepository(
        api: SessionApi(client: api.client),
        credentialStore: Credentials(),
      );
      final loader = ProtocolBmsLoader(api: api, sessionRepository: session);
      for (final operation in BmsFcPriceOperation.values) {
        expect(
          (await loader.requestFcPrice(BmsFcPriceRequest(operation)))
              .failureOrNull
              ?.code,
          'bms.session_required',
        );
      }
      expect(adapter.requests, isEmpty);
      await session.close();
    },
  );
  test(
    'all eleven original endpoints preserve their explicit bodies',
    () async {
      final cases = <(BmsFcPriceRequest, String, Map<String, Object?>)>[
        (
          const BmsFcPriceRequest(BmsFcPriceOperation.products, key: '酒'),
          '/prd/get_fc_prd_cfg_list',
          {'key': '酒'},
        ),
        (
          const BmsFcPriceRequest(
            BmsFcPriceOperation.productItems,
            key: '酒',
            oneCateId: 1,
            twoCateId: 2,
          ),
          '/prd/get_fc_prd_cfg_items',
          {'one_cate_id': 1, 'two_cate_id': 2, 'key': '酒'},
        ),
        (
          const BmsFcPriceRequest(BmsFcPriceOperation.addProducts, ids: [3]),
          '/prd/batch_add_fc_prd',
          {
            'ids': [3],
          },
        ),
        (
          const BmsFcPriceRequest(BmsFcPriceOperation.deleteProducts, ids: [3]),
          '/prd/batch_del_fc_prd',
          {
            'ids': [3],
          },
        ),
        (
          const BmsFcPriceRequest(BmsFcPriceOperation.plans),
          '/prd/get_fc_price_plan_list',
          {},
        ),
        (
          const BmsFcPriceRequest(
            BmsFcPriceOperation.employeeItems,
            planId: 7,
            deptId: 8,
            key: '员工',
          ),
          '/prd/get_fc_plan_emp_items',
          {'plan_id': 7, 'dept_id': 8, 'key': '员工'},
        ),
        (
          const BmsFcPriceRequest(
            BmsFcPriceOperation.removeEmployee,
            planId: 7,
            employeeId: 9,
          ),
          '/prd/remove_emp_from_plan',
          {'plan_id': 7, 'emp_id': 9},
        ),
        (
          const BmsFcPriceRequest(
            BmsFcPriceOperation.addPlan,
            name: ' 新方案 ',
            ids: [9],
          ),
          '/prd/new_fc_price_plan',
          {
            'name': '新方案',
            'emp_ids': [9],
          },
        ),
        (
          const BmsFcPriceRequest(BmsFcPriceOperation.deletePlans, ids: [7]),
          '/prd/batch_del_fc_price_plan',
          {
            'ids': [7],
          },
        ),
        (
          const BmsFcPriceRequest(
            BmsFcPriceOperation.savePlan,
            planId: 7,
            name: '方案',
            ids: [9],
          ),
          '/prd/save_fc_price_plan',
          {
            'id': 7,
            'name': '方案',
            'emp_ids': [9],
          },
        ),
        (
          const BmsFcPriceRequest(
            BmsFcPriceOperation.savePrice,
            productId: 3,
            planId: 7,
            amount: 0,
          ),
          '/prd/save_fc_prd_plan_price',
          {'prd_id': 3, 'plan_id': 7, 'pay_amt': 0},
        ),
      ];
      for (final (request, path, body) in cases) {
        final adapter = Adapter()..data = {};
        final result = await makeApi(adapter)
            .requestFcPrice(ClientKind.orgManager, request);
        expect(result.failureOrNull, isNull);
        expect(adapter.requests.single.uri.path, path);
        expect(adapter.requests.single.data, body);
      }
    },
  );
  test(
    'money uses exact integer cents, permits zero and rejects excess decimals',
    () {
      expect(bmsFcYuanToCents('0'), 0);
      expect(bmsFcYuanToCents('0.01'), 1);
      expect(bmsFcYuanToCents('12.30'), 1230);
      for (final text in ['-1', '1.001', 'NaN', '1e2', '90071992547410']) {
        expect(() => bmsFcYuanToCents(text), throwsFormatException);
      }
      expect(bmsFcCentsToYuan(1), '0.01');
    },
  );
  test('matrix keeps explicit zero price instead of falling back to original price', () {
    final matrix = BmsFcMatrix.fromWire({
      'prds': [
        {'id': 3, 'n': '酒', 'p': 1200},
      ],
      'plans': [
        {'id': 7, 'n': '方案'},
      ],
      'prices': [
        {'id': 3, 'p': 7, 'a': 0},
      ],
    });
    expect(matrix.priceFor(matrix.products.single, matrix.plans.single), 0);
    final absent = BmsFcMatrix.fromWire({
      'prds': [
        {'id': 3, 'n': '酒', 'p': 1200},
      ],
      'plans': [
        {'id': 7, 'n': '方案'},
      ],
    });
    expect(absent.priceFor(absent.products.single, absent.plans.single), 1200);
  });
  test('server rejection is never treated as saved', () async {
    final adapter = Adapter()..code = 0;
    expect(
      (await makeApi(adapter).requestFcPrice(
        ClientKind.orgManager,
        const BmsFcPriceRequest(
          BmsFcPriceOperation.savePrice,
          productId: 3,
          planId: 7,
        ),
      )).failureOrNull?.code,
      'bms.fc_rejected',
    );
  });
  test('price-plan configuration is reachable from product management', () {
    expect(
      BmsNavScreen.groups
          .expand((g) => g.items)
          .any((item) => item.url == 'fcPriceConfig'),
      isTrue,
    );
  });
}
