import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/vip_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';

void main() {
  test('lists member cards with search key and init types', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'row_cnt': 1,
          'card_types': [
            {
              'id': 2,
              'n': '金卡',
              'ls': [
                {'id': 3, 'n': '普通'},
              ],
            },
          ],
          'records': [
            {
              'id': 9,
              'n': '张三',
              'sn': '正常',
              'bp': '13800000000',
              'cp': '13800000001',
              's': '男',
              'b': '1990-01-01',
              'cn': 'VIP0001',
              'ct': '金卡',
              'cl': '普通',
              'ba': '100.00',
              'p': '10',
              'se': '李四',
              'h': 1,
            },
          ],
        },
      },
    ]);
    final page = (await ProtocolVipManagerApi(client: _client(adapter)).listCards(
      ClientKind.cashier,
      pageNum: 1,
      pageSize: 20,
      keyword: '张三',
      init: true,
    )).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/card/list');
    expect(adapter.requests.single.data, {
      'page_num': 1,
      'page_size': 20,
      'is_init': 1,
      'begin_birth_day': '',
      'end_birth_day': '',
      'card_type_id': 0,
      'card_level_id': 0,
      'key': '张三',
      'sales_emp_id': 0,
    });
    expect(page.total, 1);
    expect(page.types.single.name, '金卡');
    expect(page.records.single.name, '张三');
    expect(page.records.single.cardNo, 'VIP0001');
    expect(page.records.single.hasPhysicalCard, isTrue);
  });

  test('loads new-card params including types and default card no', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'card_no': 'VIP0009',
          'card_types': [
            {
              'id': 2,
              'n': '金卡',
              'ls': [
                {'id': 3, 'n': '普通'},
              ],
            },
          ],
          'marks': [
            {'id': 1, 'n': '熟客'},
          ],
          'valid_years': [
            {'id': 1, 'n': '1年'},
          ],
          'sms_types': [
            {'id': 1, 'n': '生日'},
          ],
        },
      },
    ]);
    final params = (await ProtocolVipManagerApi(
      client: _client(adapter),
    ).newCardParams(ClientKind.cashier)).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/card/get_params_f_new');
    expect(params.cardNo, 'VIP0009');
    expect(params.types.single.levels.single.id, '3');
  });

  test('creates a named card with bind phone auth code', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'id': 88},
      },
    ]);
    final id = (await ProtocolVipManagerApi(client: _client(adapter)).createCard(
      ClientKind.cashier,
      cardNo: 'VIP0009',
      typeId: '2',
      levelId: '3',
      name: '张三',
      bindPhone: '13800000000',
      bindAuthCode: 'AUTH',
      contactPhone: '13800000001',
      sex: 1,
      birthday: '1990-01-01',
    )).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/card/new');
    expect(adapter.requests.single.data, {
      'card_no': 'VIP0009',
      'card_type_id': 2,
      'card_level_id': 3,
      'contact_phone': '13800000001',
      'name': '张三',
      'bind_phone_auth_code': 'AUTH',
      'bind_phone': '13800000000',
      'sex': 1,
      'birthday': '1990-01-01',
      'mark': '',
      'expired_type': 0,
      'sales_emp_id': 0,
      'sms_type_ids': <int>[],
    });
    expect(id, '88');
  });

  test('rejects create without a card number before posting', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipManagerApi(client: _client(adapter)).createCard(
      ClientKind.cashier,
      cardNo: '',
      typeId: '2',
      levelId: '3',
      name: '张三',
    );
    expect(result.failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });

  test('lists cards already bound to a phone', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 9, 'n': '张三', 'cn': 'VIP0001', 'h': 0},
          ],
        },
      },
    ]);
    final rows = (await ProtocolVipManagerApi(
      client: _client(adapter),
    ).phoneCards(ClientKind.cashier, phone: '13800000000')).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/card/phone_mb_list');
    expect(adapter.requests.single.data, {'bind_phone': '13800000000'});
    expect(rows.single.id, '9');
  });

  test('starts and ends physical card making', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'card_pass': 'p', 'card_verify_data': 'v'},
      },
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    final begin = (await api.makeCardBegin(
      ClientKind.cashier,
      cardNo: 'PHYS01',
      memberCardId: '88',
    )).valueOrNull!;
    expect(adapter.requests.first.uri.path, '/server/mb/card/mk_card_begin');
    expect(adapter.requests.first.data, {
      'card_no': 'PHYS01',
      'mb_card_id': 88,
    });
    expect(begin.cardPass, 'p');
    final end = await api.makeCardEnd(
      ClientKind.cashier,
      cardNo: 'PHYS01',
      memberCardId: '88',
    );
    expect(end.failureOrNull, isNull);
    expect(adapter.requests.last.uri.path, '/server/mb/card/mk_card_end');
  });

  test('recharges member points via deposit_pt', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipManagerApi(client: _client(adapter)).depositPoints(
      ClientKind.cashier,
      cardId: '88',
      operatorEmpId: '7',
      points: 20,
      remark: '活动赠送',
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/card/deposit_pt');
    expect(adapter.requests.single.data, {
      'id': 88,
      'oper_emp_id': 7,
      'pt_amt': 20,
      'remark': '活动赠送',
    });
  });

  test('subtracts member points via subtract_pt', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipManagerApi(client: _client(adapter)).subtractPoints(
      ClientKind.cashier,
      cardId: '88',
      operatorEmpId: '7',
      points: 5,
      remark: '调整',
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/card/subtract_pt');
    expect(adapter.requests.single.data, {
      'id': 88,
      'oper_emp_id': 7,
      'pt_amt': 5,
      'remark': '调整',
    });
  });

  test('locks and unlocks a member card', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    expect(
      (await api.lockCard(ClientKind.cashier, cardId: '88')).failureOrNull,
      isNull,
    );
    expect(adapter.requests.first.uri.path, '/server/mb/card/lock');
    expect(adapter.requests.first.data, {'mb_card_id': 88});
    expect(
      (await api.unlockCard(ClientKind.cashier, cardId: '88')).failureOrNull,
      isNull,
    );
    expect(adapter.requests.last.uri.path, '/server/mb/card/unlock');
  });

  test('saves edited member card profile', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipManagerApi(client: _client(adapter)).saveCard(
      ClientKind.cashier,
      cardId: '88',
      name: '李四',
      contactPhone: '13800000001',
      sex: 1,
      birthday: '1991-02-02',
      mark: '熟客',
      expiredType: 0,
      salesEmpId: '7',
      smsTypeIds: const [1],
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/card/save');
    expect(adapter.requests.single.data, {
      'id': 88,
      'contact_phone': '13800000001',
      'name': '李四',
      'sex': 1,
      'birthday': '1991-02-02',
      'mark': '熟客',
      'expired_type': 0,
      'sms_type_ids': [1],
      'sales_emp_id': 7,
    });
  });

  test('loads level-up options and changes card level', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'card_info': {
            'card_no': 'VIP0001',
            'name': '张三',
            'card_level_id': 3,
            'val_balance': '10.00',
            'free_balance': '1.00',
            'pt_balance': '8',
          },
          'card_level_dfn': [
            {'id': 3, 'n': '普通'},
            {'id': 4, 'n': '白金'},
          ],
        },
      },
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    final info = (await api.getForLevelChange(
      ClientKind.cashier,
      cardId: '88',
    )).valueOrNull!;
    expect(
      adapter.requests.first.uri.path,
      '/server/mb/card/get_mb_card_f_levelupdown',
    );
    expect(info.currentLevelId, '3');
    expect(info.levels.last.name, '白金');
    expect(
      (await api.updownLevel(
        ClientKind.cashier,
        cardId: '88',
        destLevelId: '4',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.last.uri.path, '/server/mb/card/updown_mb_card_level');
    expect(adapter.requests.last.data, {
      'id': 88,
      'dest_card_level_id': 4,
    });
  });

  test('returns a card with remark and subtracts stored value', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    expect(
      (await api.returnCard(
        ClientKind.cashier,
        cardId: '88',
        remark: '客人要求',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.first.uri.path, '/server/mb/card/return');
    expect(adapter.requests.first.data, {
      'mb_card_id': 88,
      'remark': '客人要求',
    });
    expect(
      (await api.subtractMoney(
        ClientKind.cashier,
        cardId: '88',
        storedAmt: '10.00',
        giftAmt: '0',
        points: 0,
        operatorEmpId: '7',
        typeId: 1,
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.last.uri.path, '/server/mb/card/subtract');
    expect(adapter.requests.last.data, {
      'id': 88,
      'val_amt': '10.00',
      'free_amt': '0',
      'pt_amt': 0,
      'pt_bal': 7,
      'type_id': 1,
    });
  });

  test('closes a card with balance double-check fields', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipManagerApi(client: _client(adapter)).closeCard(
      ClientKind.cashier,
      cardId: '88',
      storedBalance: '10.00',
      giftBalance: '1.00',
      points: 8,
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/card/close');
    expect(adapter.requests.single.data, {
      'mb_card_id': 88,
      'val_balance': '10.00',
      'free_balance': '1.00',
      'pt_amt': 8,
    });
  });

  test('starts and ends physical card replacement', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'card_pass': 'p', 'card_verify_data': 'v'},
      },
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    final begin = (await api.changeCardBegin(
      ClientKind.cashier,
      cardNo: 'PHYS02',
      memberCardId: '88',
    )).valueOrNull!;
    expect(
      adapter.requests.first.uri.path,
      '/server/mb/card/mk_card_f_chg_begin',
    );
    expect(begin.cardPass, 'p');
    expect(
      (await api.changeCardEnd(
        ClientKind.cashier,
        cardNo: 'PHYS02',
        memberCardId: '88',
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.last.uri.path, '/server/mb/card/mk_card_f_chg_end');
  });

  test('binds a phone after sms check', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'c': 'AUTH'},
      },
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    final token = (await api.checkSms(
      ClientKind.cashier,
      phone: '13800000000',
      code: '12345',
    )).valueOrNull!;
    expect(adapter.requests.first.uri.path, '/server/sms/valid_chk');
    expect(adapter.requests.first.data, {'m': '13800000000', 'c': '12345'});
    expect(token, 'AUTH');
    expect(
      (await api.bindPhone(
        ClientKind.cashier,
        cardId: '88',
        phone: '13800000000',
        authCode: token,
        smsTypeIds: const [1],
      )).failureOrNull,
      isNull,
    );
    expect(adapter.requests.last.uri.path, '/server/mb/card/bind_bind_phone');
    expect(adapter.requests.last.data, {
      'id': 88,
      'bind_phone_auth_code': 'AUTH',
      'bind_phone': '13800000000',
      'sms_type_ids': [1],
    });
  });

  test('sends create-card sms with type 101', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipManagerApi(
      client: _client(adapter),
    ).sendSms(ClientKind.cashier, phone: '13800000000', typeId: 101);
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/sms/valid_send');
    expect(adapter.requests.single.data, {'t': 101, 'm': '13800000000'});
  });

  test('loads oper card snapshot for deduct/loss/close', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'card_no': 'VIP0001',
          'name': '张三',
          'bind_phone': '13800000000',
          'contact_phone': '13800000001',
          'val_bal': '10.00',
          'free_bal': '1.00',
          'pt_bal': 8,
          'consume_base_amt': 10,
        },
      },
    ]);
    final card = (await ProtocolVipManagerApi(
      client: _client(adapter),
    ).getOperCard(ClientKind.cashier, cardId: '88')).valueOrNull!;
    expect(adapter.requests.single.uri.path, '/server/mb/card/get_mb_card_f_oper');
    expect(adapter.requests.single.data, {'id': 88});
    expect(card.cardNo, 'VIP0001');
    expect(card.storedBalance, '10.00');
    expect(card.giftBalance, '1.00');
    expect(card.points, '8');
    expect(card.consumeBaseAmt, 10);
  });

  test('loads edit-card params and bind-phone options', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'card_info': {
            'card_no': 'VIP0001',
            'name': '张三',
            'contact_phone': '13800000001',
            'sex': 1,
            'birthday': '1990-01-01',
            'mark': '熟客',
            'expired_type': 99,
            'sales_emp_id': 7,
            'sales_emp_name': '李四',
            'card_type_name': '金卡',
            'card_level_name': '普通',
          },
          'marks': [
            {'id': 1, 'n': '熟客'},
          ],
          'valid_years': [
            {'id': 99, 'n': '永久'},
          ],
          'sms_types': [
            {'id': 1, 'n': '生日'},
          ],
          'reg_sms_types': [1],
        },
      },
      {
        'code': 1,
        'data': {
          'card_info': {'card_no': 'VIP0001', 'name': '张三'},
          'sms_types': [
            {'id': 1, 'n': '生日'},
          ],
          'reg_sms_types': [1],
        },
      },
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    final edit = (await api.getForEdit(
      ClientKind.cashier,
      cardId: '88',
    )).valueOrNull!;
    expect(adapter.requests.first.uri.path, '/server/mb/card/get_f_edit');
    expect(edit.name, '张三');
    expect(edit.marks.single.name, '熟客');
    final bind = (await api.getForBindPhone(
      ClientKind.cashier,
      cardId: '88',
    )).valueOrNull!;
    expect(
      adapter.requests.last.uri.path,
      '/server/mb/card/get_f_bind_phone',
    );
    expect(bind.smsTypes.single.name, '生日');
  });

  test('deposits stored value onto a member card', () async {
    final adapter = _Adapter([
      {'code': 1, 'data': <String, Object?>{}},
    ]);
    final result = await ProtocolVipManagerApi(client: _client(adapter)).depositMoney(
      ClientKind.cashier,
      cardId: '88',
      storedAmt: '100.00',
      giftAmt: '20.00',
      points: 5,
      mode: 1,
      operatorEmpId: '7',
      channelId: 1,
      salesEmpId: '7',
      remark: '活动',
    );
    expect(result.failureOrNull, isNull);
    expect(adapter.requests.single.uri.path, '/server/mb/card/deposit');
    expect(adapter.requests.single.data, {
      'id': 88,
      'val_amt': '100.00',
      'free_amt': '20.00',
      'pt_amt': 5,
      'm': 1,
      'oper_emp_id': 7,
      'deposit_cnl': 1,
      'sales_emp_id': 7,
      'remark': '活动',
    });
  });

  test('resolves a physical card to member id', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'p': 'secret'},
      },
      {
        'code': 1,
        'data': {'id': 88},
      },
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    final secret = (await api.getCardSecret(
      ClientKind.cashier,
      cardNo: 'PHYS01',
    )).valueOrNull!;
    expect(adapter.requests.first.uri.path, '/server/mb/card/get_card_p');
    expect(secret, 'secret');
    final id = (await api.getCardIdFromReal(
      ClientKind.cashier,
      cardNo: 'PHYS01',
      digest: 'ABC',
    )).valueOrNull!;
    expect(adapter.requests.last.uri.path, '/server/mb/card/get_mb_card_f_real');
    expect(adapter.requests.last.data, {'card_no': 'PHYS01', 'dt': 'ABC'});
    expect(id, '88');
  });

  test('loads member detail, cards, logs, coupons, wines and favorites', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {'bind_phone': '13800000000', 'name': '张三'},
      },
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 88, 'n': '张三', 'cn': 'VIP0001'},
          ],
        },
      },
      {
        'code': 1,
        'data': {
          'row_cnt': 1,
          'datas': [
            {'id': 1, 'n': '充值'},
          ],
        },
      },
      {
        'code': 1,
        'data': {
          'datas': [
            {'id': 2, 'n': '券'},
          ],
        },
      },
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 3, 'n': '茅台'},
          ],
        },
      },
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 4, 'n': '啤酒'},
          ],
        },
      },
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    final detail = (await api.getMemberDetail(
      ClientKind.cashier,
      cardId: '88',
    )).valueOrNull!;
    expect(adapter.requests[0].uri.path, '/server/mb/info/get');
    expect(detail['name'], '张三');
    final cards = (await api.getMemberCards(
      ClientKind.cashier,
      cardId: '88',
    )).valueOrNull!;
    expect(adapter.requests[1].uri.path, '/server/mb/info/get_cards');
    expect(cards.records.single['cn'], 'VIP0001');
    final logs = (await api.getBalanceLogs(
      ClientKind.cashier,
      cardId: '88',
    )).valueOrNull!;
    expect(adapter.requests[2].uri.path, '/server/mb/info/get_bal_logs');
    expect(logs.records.single['n'], '充值');
    final coupons = (await api.getMemberCoupons(
      ClientKind.cashier,
      phone: '13800000000',
    )).valueOrNull!;
    expect(adapter.requests[3].uri.path, '/server/mb/info/get_mb_my_kq_list');
    expect(coupons.records.single['n'], '券');
    final wines = (await api.getMemberWines(
      ClientKind.cashier,
      phone: '13800000000',
    )).valueOrNull!;
    expect(adapter.requests[4].uri.path, '/server/mb/info/get_mb_my_wine_list');
    expect(wines.records.single['n'], '茅台');
    final favs = (await api.getTopProducts(
      ClientKind.cashier,
      cardId: '88',
    )).valueOrNull!;
    expect(adapter.requests[5].uri.path, '/server/mb/info/get_mb_csm_top_prds');
    expect(favs.records.single['n'], '啤酒');
  });

  test('searches recharge cards and pay-serial cards', () async {
    final adapter = _Adapter([
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 88, 'n': '张三'},
          ],
        },
      },
      {
        'code': 1,
        'data': {'p': '13800000000', 'c': 'AUTH'},
      },
      {
        'code': 1,
        'data': {
          'records': [
            {'id': 88, 'c': 'VIP0001', 'n': '张三', 'r': 0},
          ],
        },
      },
    ]);
    final api = ProtocolVipManagerApi(client: _client(adapter));
    final hits = (await api.searchDepositCards(
      ClientKind.cashier,
      phone: '0000',
    )).valueOrNull!;
    expect(adapter.requests[0].uri.path, '/server/mb/card/get_f_deposits');
    expect(hits.records.single['n'], '张三');
    final srv = (await api.validPaySerial(
      ClientKind.cashier,
      code: '123456',
    )).valueOrNull!;
    expect(adapter.requests[1].uri.path, '/server/sel/valid_cust_srv_code');
    expect(srv.phone, '13800000000');
    expect(srv.authCode, 'AUTH');
    final cards = (await api.listPhonePayCards(
      ClientKind.cashier,
      phone: srv.phone,
      authCode: srv.authCode,
    )).valueOrNull!;
    expect(adapter.requests[2].uri.path, '/server/sel/get_phone_mb_cards');
    expect(cards.records.single['c'], 'VIP0001');
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
