import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/bms_api.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('upper employee picker uses source search contract', () async {
    final adapter = Adapter()
      ..data = [
        {'id': 5, 'n': '经理'},
      ];
    final result = await makeApi(adapter)
        .getUpperEmployees(ClientKind.orgManager, '经理');
    expect(adapter.requests.single.uri.path, '/emp/upper_items');
    expect(adapter.requests.single.data, {
      'name': '经理',
      'page_num': 1,
      'page_size': 9999999,
      'mod_emp_ids': [],
    });
    expect(result.valueOrNull!.single.name, '经理');
  });
  test('code rules load uses no body and original response defaults', () async {
    final adapter = Adapter()
      ..data = {'passwd_use_code': '2', 'fixed_passwd': '', 'code_length': 0};
    final result = await makeApi(adapter).getGenRule(ClientKind.orgManager);
    expect(adapter.requests.single.data, isNull);
    expect(result.valueOrNull!.toWire(), {
      'passwd_use_code': 2,
      'fixed_passwd': '666666',
      'code_length': 6,
    });
  });
  test(
    'onboarding status page and batch editing preserve Vue payloads',
    () async {
      final adapter = Adapter()
        ..data = {
          'records': [
            {
              'id': 9,
              'n': '张三',
              'p': '138',
              'sn': '经理',
              'r': '2026-09-20',
              'di': 3,
              'si': 4,
              's': 2,
              'uei': 5,
              'rn': '张小三',
            },
          ],
          'row_cnt': 31,
          'page_num': 2,
          'page_size': 20,
        };
      final api = makeApi(adapter);
      final page = await api.getOnboardingPage(
        ClientKind.orgManager,
        status: 5,
        page: 2,
      );
      expect(adapter.requests.last.data, {
        's': 5,
        'page_num': 2,
        'page_size': 20,
      });
      expect(page.valueOrNull!.total, 31);
      expect(page.valueOrNull!.items.single.name, '张三');
      expect(page.valueOrNull!.items.single.stationName, '经理');
      await api.auditOnboardingBatch(ClientKind.orgManager, ['9', '10'], true);
      expect(adapter.requests.last.data, {
        'ids': ['9', '10'],
      });
      final fields = {
        'id': '9',
        'name': '张三',
        'dept_id': 3,
        'station_id': 4,
        'sex': 2,
        'upper_emp_id': 5,
        'real_name': '张小三',
      };
      await api.saveOnboarding(ClientKind.orgManager, fields);
      expect(adapter.requests.last.uri.path, '/emp/save_emp_rz_for_approve');
      expect(adapter.requests.last.data, fields);
    },
  );
  test('business batch add and available filters use ids and emps', () async {
    final adapter = Adapter()
      ..data = {
        'emps': [
          {'id': 12, 'n': '小王', 'dn': '部门', 'cd': '000012'},
        ],
      };
    final api = makeApi(adapter);
    final result = await api.getBusinessCandidates(
      ClientKind.orgManager,
      keyword: '王',
      deptIds: ['3'],
    );
    expect(adapter.requests.last.uri.path, '/emp/list');
    expect(adapter.requests.last.data, {
      'key': '王',
      'ids': ['3'],
    });
    expect(result.valueOrNull!.single.empNo, '000012');
    expect(result.valueOrNull!.single.deptName, '部门');
    await api.addBusinessEmployees(ClientKind.orgManager, ['12', '13']);
    expect(adapter.requests.last.data, {
      'ids': ['12', '13'],
    });
    await api.getBusinessEmpList(
      ClientKind.orgManager,
      keyword: '王',
      deptIds: ['3'],
    );
    expect(adapter.requests.last.data, {
      'key': '王',
      'ids': ['3'],
    });
  });
  test('business refusal is not reported as a successful mutation', () async {
    final adapter = Adapter()
      ..code = 0
      ..msg = '不可操作';
    final result = await makeApi(adapter)
        .batchResetEmpPwd(ClientKind.orgManager, ids: ['12']);
    expect(result.failureOrNull, isNotNull);
  });
  test('code rule roundtrips only original Web fields', () {
    final fields = {
      'passwd_use_code': 2,
      'fixed_passwd': '123456',
      'code_length': 8,
    };
    expect(BmsGenRule.fromWire(fields).toWire(), fields);
  });
  test(
    'reset uses emp_ids, approvals use original routes and batch ids',
    () async {
      final adapter = Adapter();
      final api = makeApi(adapter);
      await api.batchResetEmpPwd(ClientKind.orgManager, ids: ['12']);
      expect(adapter.requests.last.data, {
        'emp_ids': ['12'],
      });
      await api.getOnboardingApprovals(ClientKind.orgManager);
      expect(adapter.requests.last.uri.path, '/emp/get_emp_rz_list');
      expect(adapter.requests.last.data, {
        's': 1,
        'page_num': 1,
        'page_size': 20,
      });
      await api.auditOnboarding(ClientKind.orgManager, id: '12', pass: true);
      expect(adapter.requests.last.uri.path, '/emp/emp_rz_approve_batch_yes');
      expect(adapter.requests.last.data, {
        'ids': ['12'],
      });
      await api.auditOnboarding(ClientKind.orgManager, id: '12', pass: false);
      expect(adapter.requests.last.uri.path, '/emp/emp_rz_approve_batch_deny');
    },
  );
  test(
    'business list reads records compact fields and add/remove contracts',
    () async {
      final adapter = Adapter()
        ..data = {
          'records': [
            {'id': 7, 'n': '小李', 'd': '商务', 'c': '000007'},
          ],
        };
      final api = makeApi(adapter);
      final result = await api.getBusinessEmpList(ClientKind.orgManager);
      expect(adapter.requests.last.uri.path, '/emp/get_bs_sales_list');
      expect(adapter.requests.last.data, {'key': ''});
      expect(result.valueOrNull!.single.name, '小李');
      expect(result.valueOrNull!.single.empNo, '000007');
      await api.setBusinessEmp(
        ClientKind.orgManager,
        id: '7',
        isBusiness: true,
      );
      expect(adapter.requests.last.uri.path, '/emp/batch_add_bs_sales');
      expect(adapter.requests.last.data, {
        'ids': ['7'],
      });
      await api.setBusinessEmp(
        ClientKind.orgManager,
        id: '7',
        isBusiness: false,
      );
      expect(adapter.requests.last.uri.path, '/emp/remove_bs_sales');
      expect(adapter.requests.last.data, {'id': '7'});
    },
  );
}

ProtocolBmsApi makeApi(Adapter adapter) => ProtocolBmsApi(
  client: ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://example.test'),
      onlineBase: Uri.parse('https://online.example.test'),
      websocketBase: Uri.parse('wss://example.test'),
    ),
    credentialStore: Credentials(),
    requestGate: RequestGate(clock: DateTime.now),
  ),
);

class Adapter implements HttpClientAdapter {
  void Function()? onFetch;
  Object? data;
  int code = 1;
  String msg = '';
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    onFetch?.call();
    if (requestStream != null) await requestStream.drain<void>();
    return ResponseBody.fromString(
      jsonEncode({'code': code, 'msg': msg, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class Credentials implements CredentialStore {
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
