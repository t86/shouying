import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/vip_pages.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('loads the global point gift rule', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'type_id': 3, 'base_amt': 10},
      },
    ]);
    final rule = (await ProtocolVipPagesApi(
      client: _client(adapter),
    ).getPointRule(ClientKind.cashier)).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/card/get_pt_rule');
    expect(adapter.requests.single.data, <String, Object?>{});
    expect(rule.typeId, 3);
    expect(rule.baseAmt, 10);
  });

  test('saves consume-gift point rule as type_id and base_amt', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipPagesApi(client: _client(adapter)).savePointRule(
      ClientKind.cashier,
      typeId: 3,
      baseAmt: 10,
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/card/save_pt_rule');
    expect(adapter.requests.single.data, {'type_id': 3, 'base_amt': 10});
  });

  test('saves no-gift point rule with base_amt 0', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    await ProtocolVipPagesApi(
      client: _client(adapter),
    ).savePointRule(ClientKind.cashier, typeId: 1, baseAmt: 0);
    expect(adapter.requests.single.data, {'type_id': 1, 'base_amt': 0});
  });

  test('lists deposit gift rules for all card types', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 7, 'd': 10000, 'f': 2000, 'n': '全等级', 'fk': '券A'},
          ],
        },
      },
    ]);
    final rows = (await ProtocolVipPagesApi(
      client: _client(adapter),
    ).listDepositRules(ClientKind.cashier, cardTypeId: '0')).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/deposit_rule/list');
    expect(adapter.requests.single.data, {'card_type_id': 0});
    expect(rows.single.depositFen, 10000);
    expect(rows.single.giftFen, 2000);
    expect(rows.single.levelName, '全等级');
  });

  test('creates a deposit rule in fen', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipPagesApi(client: _client(adapter)).saveDepositRule(
      ClientKind.cashier,
      depositFen: 10000,
      giftFen: 2000,
      cardTypeId: '0',
      cardLevelId: '0',
      giftPoints: 5,
      couponId: '0',
      remark: '充100送20',
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/deposit_rule/new');
    expect(adapter.requests.single.data, {
      'deposit_amt': 10000,
      'free_amt': 2000,
      'card_level_id': 0,
      'card_type_id': 0,
      'free_pt_amt': 5,
      'free_kq_id': 0,
      'remark': '充100送20',
    });
  });

  test('updates an existing deposit rule by id', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    await ProtocolVipPagesApi(client: _client(adapter)).saveDepositRule(
      ClientKind.cashier,
      id: '7',
      depositFen: 20000,
      giftFen: 0,
      cardTypeId: '0',
      cardLevelId: '3',
    );
    expect(adapter.requests.single.uri.path, '/server/mb/deposit_rule/save');
    expect((adapter.requests.single.data as Map)['id'], 7);
  });

  test('deletes a deposit rule by fen amounts', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipPagesApi(client: _client(adapter)).deleteDepositRule(
      ClientKind.cashier,
      depositFen: 10000,
      giftFen: 2000,
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/deposit_rule/del');
    expect(adapter.requests.single.data, {
      'deposit_amt': 10000,
      'free_amt': 2000,
    });
  });

  test('loads and saves member card number rules', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'num_length': 5, 'prefix': 'VIP'},
      },
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipPagesApi(client: _client(adapter));
    final rule = (await api.getCardNoRule(ClientKind.cashier)).valueOrNull!;
    expect(adapter.requests.first.uri.path, '/server/mb/card/get_mb_card_no_rule');
    expect(rule.numLength, 5);
    expect(rule.prefix, 'VIP');
    final saved = await api.saveCardNoRule(
      ClientKind.cashier,
      numLength: 6,
      prefix: 'A',
    );
    expect(saved.failureOrNull, isNull);
    expect(adapter.requests.last.uri.path, '/server/mb/card/save_mb_card_no_rule');
    expect(adapter.requests.last.data, {'num_length': 6, 'prefix': 'A'});
  });

  test('lists wecom members with keyword paging', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'row_cnt': 1,
          'records': [
            {'id': 1, 'n': '昵称', 'p': '13800000000', 't': '2026-01-01'},
          ],
        },
      },
    ]);
    final page = (await ProtocolVipPagesApi(client: _client(adapter)).listQwMembers(
      ClientKind.cashier,
      pageNum: 1,
      pageSize: 10,
      keyword: '138',
    )).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/rpt/get_qw_mb_list');
    expect(adapter.requests.single.data, {
      'page_num': 1,
      'page_size': 10,
      'key': '138',
    });
    expect(page.total, 1);
    expect(page.records.single['n'], '昵称');
  });

  test('lists member card types', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 2, 'n': '金卡', 'ct': 3, 'u': '01-01', 'c': '01-01', 'd': 1},
          ],
        },
      },
    ]);
    final rows = (await ProtocolVipPagesApi(
      client: _client(adapter),
    ).listCardTypes(ClientKind.cashier)).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/type/list');
    expect(rows.single.name, '金卡');
    expect(rows.single.levelCount, '3');
    expect(rows.single.isDefault, isTrue);
  });

  test('creates a member card type', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipPagesApi(
      client: _client(adapter),
    ).createCardType(ClientKind.cashier, name: '银卡', isDefault: true);
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/type/new');
    expect(adapter.requests.single.data, {'name': '银卡', 'is_def': 1});
  });

  test('queries recharge log report using datas rows', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'row_cnt': 1,
          'datas': [
            {'id': 9, 'n': '张三', 'cn': 'VIP0001'},
          ],
          'online_val_amt': '10.00',
          'cnls': [
            {'n': '微信', 'a': '10.00'},
          ],
        },
      },
    ]);
    final page = (await ProtocolVipPagesApi(client: _client(adapter)).queryReport(
      ClientKind.cashier,
      kind: VipReportKind.depositLog,
      pageNum: 1,
      pageSize: 20,
      beginDay: '2026-09-14',
      endDay: '2026-09-14',
      keyword: '张三',
      typeId: 0,
    )).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/rpt/get_deposit_log');
    expect(adapter.requests.single.data, {
      'page_num': 1,
      'page_size': 20,
      'begin_day': '2026-09-14',
      'end_day': '2026-09-14',
      'type_id': 0,
      'key': '张三',
    });
    expect(page.total, 1);
    expect(page.records.single['n'], '张三');
    expect(page.summary['online_val_amt'], '10.00');
  });

  test('lists late deposits and refunds one', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {
              'id': 8,
              'c': 'VIP0001',
              'n': '张三',
              'p': '13800000000',
              'l': '微信',
              'a': 10000,
              'o': '2026-09-14',
              'r': '',
            },
          ],
        },
      },
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipPagesApi(client: _client(adapter));
    final rows = (await api.listLateDeposits(
      ClientKind.cashier,
      keyword: 'VIP',
    )).valueOrNull!;
    expect(adapter.requests.first.uri.path, '/server/sel/get_deposit_late_list');
    expect(adapter.requests.first.data, {'key': 'VIP'});
    expect(rows.single.cardNo, 'VIP0001');
    expect(rows.single.amountFen, 10000);
    final refunded = await api.refundLateDeposit(ClientKind.cashier, id: '8');
    expect(refunded.failureOrNull, isNull);
    expect(adapter.requests.last.uri.path, '/server/sel/back_deposit_late');
    expect(adapter.requests.last.data, {'id': 8});
  });

  test('lists checkout bill rules for a card type', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 4, 'l': '普通', 'n': '啤酒', 'p': '10.00', 't': '单品', 'tn': '按比例扣款'},
          ],
          'levels': [
            {'id': 3, 'n': '普通'},
          ],
        },
      },
    ]);
    final page = (await ProtocolVipPagesApi(client: _client(adapter)).listBillRules(
      ClientKind.cashier,
      cardTypeId: '2',
      cardLevelId: '0',
      init: true,
    )).valueOrNull!;
    expect(
      adapter.requests.single.uri.path,
      '/server/mb/card/get_grp_mb_csm_rule_list',
    );
    expect(page.records.single['n'], '啤酒');
  });

  test('loads card type detail with levels and auto-upgrade flag', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'name': '金卡',
          'is_def': 1,
          'pic_url_prefix': 'https://img/',
          'card_levels': [
            {
              'id': 3,
              'n': '普通',
              'd': 1,
              'p': 'a.png',
              'e': 0,
              'k': 0,
              'kn': '',
            },
            {
              'id': 4,
              'n': '白金',
              'd': 2,
              'p': 'b.png',
              'e': 100,
              'k': 9,
              'kn': '券',
            },
          ],
        },
      },
    ]);
    final detail = (await ProtocolVipPagesApi(
      client: _client(adapter),
    ).getCardTypeDetail(ClientKind.cashier, id: '2')).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/type/get');
    expect(adapter.requests.single.data, {'id': 2});
    expect(detail.name, '金卡');
    expect(detail.isDefault, isTrue);
    expect(detail.levels.length, 2);
    expect(detail.levels.last.expThreshold, 100);
    expect(detail.levels.last.couponName, '券');
  });

  test('creates, renames and deletes a card level', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'id': 11},
      },
      {'code': 1, 'data': <String, Object?>{}},
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipPagesApi(client: _client(adapter));
    final id = (await api.newLevel(
      ClientKind.cashier,
      typeId: '2',
      name: '钻石',
      picName: 'd.png',
      expThreshold: 0,
      couponId: '0',
    )).valueOrNull!;
    expect(adapter.requests[0].uri.path, '/server/mb/type/new_level');
    expect(adapter.requests[0].data, {
      'id': 2,
      'level_name': '钻石',
      'level_pic_name': 'd.png',
      'exp_threshold': 0,
      'kq_id': 0,
    });
    expect(id, '11');
    expect(
      (await api.renameLevel(
        ClientKind.cashier,
        id: '11',
        name: '黑金',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests[1].uri.path, '/server/mb/type/chg_level_name');
    expect(adapter.requests[1].data, {'id': 11, 'name': '黑金'});
    expect(
      (await api.deleteLevel(ClientKind.cashier, id: '11')).failureOrNull,
      isNull,
    );
    expect(adapter.requests[2].uri.path, '/server/mb/type/del_level');
  });

  test('saves level experience and coupon then toggles auto-upgrade', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
      {'code': 1, 'data': <String, Object?>{}},
      {'code': 1, 'data': <String, Object?>{}},
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipPagesApi(client: _client(adapter));
    await api.changeLevelExp(
      ClientKind.cashier,
      id: '4',
      expThreshold: 200,
    );
    expect(adapter.requests[0].uri.path, '/server/mb/type/chg_mb_card_level_exp_td');
    expect(adapter.requests[0].data, {'id': 4, 'exp_threshold': 200});
    await api.changeLevelCoupon(ClientKind.cashier, id: '4', couponId: '9');
    expect(adapter.requests[1].uri.path, '/server/mb/type/chg_level_kq');
    expect(adapter.requests[1].data, {'id': 4, 'kq_id': 9});
    await api.enableAutoUpgrade(
      ClientKind.cashier,
      typeId: '2',
      levelIds: const ['4'],
      expThresholds: const [200],
    );
    expect(adapter.requests[2].uri.path, '/server/mb/type/enable_autoupd');
    expect(adapter.requests[2].data, {
      'id': 2,
      'ls': [4],
      'es': [200],
    });
    await api.disableAutoUpgrade(ClientKind.cashier, typeId: '2');
    expect(adapter.requests[3].uri.path, '/server/mb/type/disable_autoupd');
    expect(adapter.requests[3].data, {'id': 2});
  });

  test('lists and deletes custom card covers', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'pic_url_prefix': 'https://img/',
          'records': [
            {'id': 5, 'pic_name': 'c.png'},
          ],
        },
      },
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipPagesApi(client: _client(adapter));
    final covers = (await api.listCovers(ClientKind.cashier)).valueOrNull!;
    expect(adapter.requests.first.uri.path, '/server/mb/type/get_cust_cover_list');
    expect(covers.single.picName, 'c.png');
    expect(covers.single.url, 'https://img/c.png');
    expect(
      (await api.deleteCover(ClientKind.cashier, id: '5')).failureOrNull,
      isNull,
    );
    expect(adapter.requests.last.uri.path, '/server/mb/type/del_cust_cover');
  });

  test('lists and saves per-type point gift rules', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 8, 'n': '全等级', 't': '消费赠送积分', 'b': 1000},
          ],
        },
      },
      {'code': 1, 'data': <String, Object?>{}},
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipPagesApi(client: _client(adapter));
    final rows = (await api.listTypePointRules(
      ClientKind.cashier,
      cardTypeId: '2',
    )).valueOrNull!;
    expect(adapter.requests[0].uri.path, '/server/mb/card/get_pt_rules');
    expect(adapter.requests[0].data, {'card_type_id': 2});
    expect(rows.single.baseAmtFen, 1000);
    await api.saveTypePointRule(
      ClientKind.cashier,
      cardTypeId: '2',
      cardLevelId: '0',
      baseAmtFen: 2000,
    );
    expect(adapter.requests[1].uri.path, '/server/mb/card/new_pt_rule');
    expect(adapter.requests[1].data, {
      'base_amt': 2000,
      'card_level_id': 0,
      'card_type_id': 2,
    });
    await api.deleteTypePointRule(
      ClientKind.cashier,
      id: '8',
      cardTypeId: '2',
    );
    expect(adapter.requests[2].uri.path, '/server/mb/card/del_pt_rule');
    expect(adapter.requests[2].data, {'id': 8, 'card_type_id': 2});
  });

  test('reprints a member bill by log id', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipPagesApi(
      client: _client(adapter),
    ).reprintBill(ClientKind.cashier, logId: '9');
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/rpt/re_print_mb_bill');
    expect(adapter.requests.single.data, {'log_id': 9});
  });

  test('changes a level cover and lists level coupons', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 9, 'n': '券A', 'tn': '满减'},
          ],
        },
      },
    ]);
    final api = ProtocolVipPagesApi(client: _client(adapter));
    expect(
      (await api.changeLevelPic(
        ClientKind.cashier,
        id: '4',
        picName: 'b.png',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.first.uri.path, '/server/mb/type/chg_level_pic');
    expect(adapter.requests.first.data, {'id': 4, 'pic_name': 'b.png'});
    final coupons = (await api.listLevelCoupons(
      ClientKind.cashier,
      typeId: 0,
      keyword: '券',
    )).valueOrNull!;
    expect(adapter.requests.last.uri.path, '/server/mb/type/get_mb_card_level_kqs');
    expect(coupons.records.single['n'], '券A');
  });
}

ProtocolClient _client(_Adapter adapter) {
  var now = DateTime.utc(2026, 9, 9);
  return ProtocolClient(
    dio: Dio()..httpClientAdapter = adapter,
    config: ApiConfig(
      apiBase: Uri.parse('https://api.example.test/server'),
      onlineBase: Uri.parse('https://online.example.test/server'),
      websocketBase: Uri.parse('wss://socket.example.test/server'),
    ),
    credentialStore: _CredentialStore(),
    requestGate: RequestGate(
      clock: () {
        now = now.add(const Duration(milliseconds: 101));
        return now;
      },
    ),
  );
}

final class _Adapter implements HttpClientAdapter {
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
    return ResponseBody.fromString(
      jsonEncode(responses.removeAt(0)),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _CredentialStore implements CredentialStore {
  @override
  Future<void> clearStk() async {}
  @override
  Future<void> clearStkIfMatches(String? expected) async {}
  @override
  Future<void> clearTk() async {}
  @override
  Future<void> clearTkIfMatches(String? expected) async {}
  @override
  Future<String?> readStk() async => null;
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      const CredentialSnapshot(tk: 'test-tk', stk: null);
  @override
  Future<String?> readTk() async => 'test-tk';
  @override
  Future<void> writeStk(String value) async {}
  @override
  Future<void> writeTk(String value) async {}
}
