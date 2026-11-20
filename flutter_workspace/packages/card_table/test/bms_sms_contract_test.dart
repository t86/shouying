import 'package:card_table/src/bms_models.dart';
import 'package:card_table/src/bms_loader.dart';
import 'package:session/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi, Credentials;

void main() {
  test('self check uses original mobile body and rejects invalid mobile before network', () async {
    final adapter = Adapter();
    final api = makeApi(adapter);
    expect(
      (await api.sendSmsSelfCheck(
        ClientKind.orgManager,
        mobile: '123',
      )).failureOrNull?.code,
      'bms.sms_mobile_invalid',
    );
    expect(adapter.requests, isEmpty);
    expect(
      (await api.sendSmsSelfCheck(
        ClientKind.orgManager,
        mobile: '13800000000',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.single.uri.path, '/sms_mgr/self_check');
    expect(adapter.requests.single.data, {'mobile': '13800000000'});
    adapter.code = 0;
    expect(
      (await api.sendSmsSelfCheck(
        ClientKind.orgManager,
        mobile: '13800000000',
      )).failureOrNull?.code,
      'bms.rejected',
    );
  });
  test(
    'all SMS reads keep the session guard before any network request',
    () async {
      final adapter = Adapter();
      final api = makeApi(adapter);
      final session = SessionRepository(
        api: SessionApi(client: api.client),
        credentialStore: Credentials(),
      );
      final loader = ProtocolBmsLoader(api: api, sessionRepository: session);
      expect(
        (await loader.loadSmsAccount()).failureOrNull?.code,
        'bms.session_required',
      );
      expect(
        (await loader.loadSmsBills(
          startDay: '',
          endDay: '',
        )).failureOrNull?.code,
        'bms.session_required',
      );
      expect(
        (await loader.loadSmsRecordDetails(recordId: '7')).failureOrNull?.code,
        'bms.session_required',
      );
      expect(
        (await loader.loadSmsMobileResults(mobile: '138')).failureOrNull?.code,
        'bms.session_required',
      );
      expect(adapter.requests, isEmpty);
      await session.close();
    },
  );
  test(
    'malformed SMS payload is a safe error rather than fake empty success',
    () async {
      final adapter = Adapter()..data = 'not-an-account';
      expect(
        (await makeApi(adapter).getSmsAccountInfo(ClientKind.orgManager))
            .failureOrNull
            ?.code,
        'bms.sms_invalid_response',
      );
    },
  );
  test('daily bills preserve date/type pagination and decimal money', () async {
    final adapter = Adapter()
      ..data = {
        'row_cnt': 42,
        'records': [
          {
            'id': 7,
            'd': '2026-09-20',
            't': '消费',
            'a': '0.15',
            'sc': 3,
            'fc': 1,
            'b': '12.35',
            'bc': 247,
          },
        ],
      };
    final result = await makeApi(adapter).getSmsBills(
      ClientKind.orgManager,
      startDay: '2026-09-01',
      endDay: '2026-09-20',
      type: 2,
      page: 2,
      pageSize: 20,
    );
    expect(adapter.requests.single.uri.path, '/sms_mgr/get_sms_records');
    expect(adapter.requests.single.data, {
      'page_num': 2,
      'page_size': 20,
      'start_biz_day': '2026-09-01',
      'end_biz_day': '2026-09-20',
      'type_id': 2,
    });
    expect(result.valueOrNull!.total, 42);
    expect(result.valueOrNull!.records.single.amount, '0.15');
    expect(result.valueOrNull!.records.single.failed, '1');
  });
  test('record details substitute all parameters and reuse initial templates on page two', () async {
    final adapter = Adapter()
      ..data = {
        'row_cnt': 21,
        'sms_types': [
          {'id': 4, 'n': '通知', 't': '{1}/{2}/{3}/{4}/{5}/{6}'},
        ],
        'records': [
          {
            'm': '138',
            't': 4,
            's': '成功',
            'p1': '甲',
            'p2': '乙',
            'p3': '丙',
            'p4': '丁',
            'p5': '戊',
            'p6': '己',
            'c': 2,
          },
        ],
      };
    final api = makeApi(adapter);
    final first = await api.getSmsRecordDetails(
      ClientKind.orgManager,
      recordId: '7',
      status: 1,
      mobile: '138',
    );
    expect(adapter.requests.single.uri.path, '/sms_mgr/get_sms_record_dtls');
    expect(adapter.requests.single.data, {
      'page_num': 1,
      'page_size': 20,
      'is_init': 1,
      'record_id': 7,
      'status': 1,
      'mobile': '138',
    });
    expect(first.valueOrNull!.records.single.content, '甲/乙/丙/丁/戊/己');
    adapter.data = {
      'row_cnt': 21,
      'records': [
        {'t': 4, 's': '失败', 'e': '拒收', 'p1': '第二页'},
      ],
    };
    final second = await api.getSmsRecordDetails(
      ClientKind.orgManager,
      recordId: '7',
      page: 2,
      initialize: false,
      templates: first.valueOrNull!.templates,
    );
    expect(adapter.requests.last.data, {
      'page_num': 2,
      'page_size': 20,
      'is_init': 2,
      'record_id': 7,
      'status': 0,
      'mobile': '',
    });
    expect(second.valueOrNull!.records.single.content, '第二页/////');
    expect(second.valueOrNull!.records.single.failReason, '拒收');
  });
  test(
    'service failure does not become an empty successful SMS report',
    () async {
      final adapter = Adapter()
        ..code = 0
        ..msg = 'internal secret';
      final api = makeApi(adapter);
      expect(
        (await api.getSmsAccountInfo(ClientKind.orgManager))
            .failureOrNull
            ?.code,
        'bms.rejected',
      );
      expect(
        (await api.getSmsBills(
          ClientKind.orgManager,
          startDay: '',
          endDay: '',
        )).failureOrNull?.code,
        'bms.rejected',
      );
      expect(
        (await api.getSmsMobileResults(
          ClientKind.orgManager,
          mobile: '138',
        )).failureOrNull?.safeMessage,
        isNot(contains('secret')),
      );
    },
  );
  test(
    'SMS account uses original no-body endpoint and compact account fields',
    () async {
      final adapter = Adapter()
        ..data = {
          'n': '测试门店',
          'b': '12.50',
          'c': 250,
          'ld': '100.00',
          'lt': '2026-09-01',
          's': '正常',
          'o': '已开通',
        };
      final result = await makeApi(adapter)
          .getSmsAccountInfo(ClientKind.orgManager);
      expect(adapter.requests.single.uri.path, '/sms_mgr/get_acct_info');
      expect(adapter.requests.single.data, isNull);
      expect(result.valueOrNull!.balance, 250);
    },
  );
  test(
    'legacy mobile-record facade also uses real read-only endpoint',
    () async {
      final adapter = Adapter()
        ..data = {
          'records': [
            {'m': '13800000000', 's': '成功', 'r': '2026-09-20', 't': 4, 'c': 1},
          ],
          'sms_template': [
            {'id': 4, 'n': '通知', 't': '欢迎'},
          ],
        };
      final result = await makeApi(adapter)
          .getSmsRecords(ClientKind.orgManager, phone: '13800000000');
      expect(adapter.requests.single.uri.path, '/sms_mgr/get_mobile_send_rst');
      expect(adapter.requests.single.data, {'mobile': '13800000000'});
      expect(result.valueOrNull!.single.phone, '13800000000');
      expect(result.valueOrNull!.single.content, '欢迎');
    },
  );
  test('SMS compact record status must not silently default to success', () {
    final result = BmsSmsRecord.fromWire({
      'm': '138',
      's': '失败',
      'r': '10:20',
      'd': '10:21',
      'e': '号码错误',
    });
    expect(result.status, 2);
    expect(result.phone, '138');
    expect(result.failReason, '号码错误');
  });
}
