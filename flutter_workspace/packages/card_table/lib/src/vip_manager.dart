import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

final class VipCardLevel {
  const VipCardLevel({required this.id, required this.name});

  final String id;
  final String name;
}

final class VipCardType {
  const VipCardType({
    required this.id,
    required this.name,
    this.levels = const [],
  });

  final String id;
  final String name;
  final List<VipCardLevel> levels;
}

final class VipCardRow {
  const VipCardRow({
    required this.id,
    required this.name,
    required this.statusName,
    required this.bindPhone,
    required this.contactPhone,
    required this.sex,
    required this.birthday,
    required this.cardNo,
    required this.typeName,
    required this.levelName,
    required this.balance,
    required this.points,
    required this.salesName,
    this.hasPhysicalCard = false,
  });

  final String id;
  final String name;
  final String statusName;
  final String bindPhone;
  final String contactPhone;
  final String sex;
  final String birthday;
  final String cardNo;
  final String typeName;
  final String levelName;
  final String balance;
  final String points;
  final String salesName;
  final bool hasPhysicalCard;
}

final class VipCardPage {
  const VipCardPage({
    required this.total,
    this.records = const [],
    this.types = const [],
  });

  final int total;
  final List<VipCardRow> records;
  final List<VipCardType> types;
}

final class VipNewCardParams {
  const VipNewCardParams({
    this.cardNo = '',
    this.types = const [],
    this.marks = const [],
    this.validYears = const [],
    this.smsTypes = const [],
  });

  final String cardNo;
  final List<VipCardType> types;
  final List<VipCardLevel> marks;
  final List<VipCardLevel> validYears;
  final List<VipCardLevel> smsTypes;
}

final class VipMakeCardBegin {
  const VipMakeCardBegin({required this.cardPass, required this.verifyData});

  final String cardPass;
  final String verifyData;
}

final class VipLevelChangeInfo {
  const VipLevelChangeInfo({
    required this.currentLevelId,
    this.cardNo = '',
    this.name = '',
    this.bindPhone = '',
    this.contactPhone = '',
    this.storedBalance = '',
    this.giftBalance = '',
    this.points = '',
    this.levels = const [],
  });

  final String currentLevelId;
  final String cardNo;
  final String name;
  final String bindPhone;
  final String contactPhone;
  final String storedBalance;
  final String giftBalance;
  final String points;
  final List<VipCardLevel> levels;
}

final class VipOperCard {
  const VipOperCard({
    required this.cardNo,
    this.name = '',
    this.bindPhone = '',
    this.contactPhone = '',
    this.storedBalance = '',
    this.giftBalance = '',
    this.points = '',
    this.consumeBaseAmt = 0,
  });

  final String cardNo;
  final String name;
  final String bindPhone;
  final String contactPhone;
  final String storedBalance;
  final String giftBalance;
  final String points;
  final int consumeBaseAmt;
}

final class VipEditCard {
  const VipEditCard({
    required this.name,
    this.cardNo = '',
    this.contactPhone = '',
    this.sex = 1,
    this.birthday = '',
    this.mark = '',
    this.expiredType = 0,
    this.salesEmpId = '0',
    this.salesEmpName = '',
    this.typeName = '',
    this.levelName = '',
    this.marks = const [],
    this.validYears = const [],
    this.smsTypes = const [],
    this.registeredSmsTypeIds = const [],
  });

  final String name;
  final String cardNo;
  final String contactPhone;
  final int sex;
  final String birthday;
  final String mark;
  final int expiredType;
  final String salesEmpId;
  final String salesEmpName;
  final String typeName;
  final String levelName;
  final List<VipCardLevel> marks;
  final List<VipCardLevel> validYears;
  final List<VipCardLevel> smsTypes;
  final List<int> registeredSmsTypeIds;
}

final class VipBindPhonePrep {
  const VipBindPhonePrep({
    this.cardNo = '',
    this.name = '',
    this.smsTypes = const [],
    this.registeredSmsTypeIds = const [],
  });

  final String cardNo;
  final String name;
  final List<VipCardLevel> smsTypes;
  final List<int> registeredSmsTypeIds;
}

final class VipPaySerial {
  const VipPaySerial({required this.phone, required this.authCode});

  final String phone;
  final String authCode;
}

final class VipMapPage {
  const VipMapPage({this.total = 0, this.records = const []});

  final int total;
  final List<Map<String, String>> records;
}

final class ProtocolVipManagerApi {
  const ProtocolVipManagerApi({required this.client, this.canDispatch});
  final ProtocolClient client;
  final bool Function()? canDispatch;

  Future<Result<Map<String, Object?>>> _post(
    String path, {
    required ClientKind client,
    Map<String, Object?> body = const {},
  }) => this.client.post(
    path,
    body: body,
    client: client,
    canDispatch: canDispatch,
  );

  Future<Result<VipCardPage>> listCards(
    ClientKind client, {
    required int pageNum,
    required int pageSize,
    String keyword = '',
    bool init = false,
    String beginBirthDay = '',
    String endBirthDay = '',
    String typeId = '0',
    String levelId = '0',
    String salesEmpId = '0',
  }) async {
    if (pageNum < 1 || pageSize < 1 || pageSize > 200 || keyword.length > 64) {
      return const FailureResult(_shapeFailure);
    }
    final response = await _post(
      '/mb/card/list',
      body: <String, Object?>{
        'page_num': pageNum,
        'page_size': pageSize,
        'is_init': init ? 1 : 2,
        'begin_birth_day': beginBirthDay,
        'end_birth_day': endBirthDay,
        'card_type_id': _jsonId(typeId),
        'card_level_id': _jsonId(levelId),
        'key': keyword,
        'sales_emp_id': _jsonId(salesEmpId),
      },
      client: client,
    );
    return _readPage(response);
  }

  Future<Result<VipNewCardParams>> newCardParams(ClientKind client) async {
    final response = await _post(
      '/mb/card/get_params_f_new',
      body: const <String, Object?>{},
      client: client,
    );
    return _readParams(response);
  }

  Future<Result<String>> createCard(
    ClientKind client, {
    required String cardNo,
    required String typeId,
    required String levelId,
    required String name,
    String contactPhone = '',
    String bindPhone = '',
    String bindAuthCode = '',
    int sex = 1,
    String birthday = '',
    String mark = '',
    int expiredType = 0,
    String salesEmpId = '0',
    List<int> smsTypeIds = const [],
  }) async {
    if (cardNo.isEmpty ||
        cardNo.length > 32 ||
        typeId.isEmpty ||
        levelId.isEmpty ||
        name.length > 32) {
      return const FailureResult(_shapeFailure);
    }
    final response = await _post(
      '/mb/card/new',
      body: <String, Object?>{
        'card_no': cardNo,
        'card_type_id': _jsonId(typeId),
        'card_level_id': _jsonId(levelId),
        'contact_phone': contactPhone,
        'name': name,
        'bind_phone_auth_code': bindAuthCode,
        'bind_phone': bindPhone,
        'sex': sex,
        'birthday': birthday,
        'mark': mark,
        'expired_type': expiredType,
        'sales_emp_id': _jsonId(salesEmpId),
        'sms_type_ids': smsTypeIds,
      },
      client: client,
    );
    return _readId(response);
  }

  Future<Result<List<VipCardRow>>> phoneCards(
    ClientKind client, {
    required String phone,
  }) async {
    if (phone.isEmpty || phone.length > 11) {
      return const FailureResult(_shapeFailure);
    }
    final response = await _post(
      '/mb/card/phone_mb_list',
      body: <String, Object?>{'bind_phone': phone},
      client: client,
    );
    return _readRecords(response);
  }

  Future<Result<VipMakeCardBegin>> makeCardBegin(
    ClientKind client, {
    required String cardNo,
    required String memberCardId,
  }) async {
    if (cardNo.isEmpty || memberCardId.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    final response = await _post(
      '/mb/card/mk_card_begin',
      body: <String, Object?>{
        'card_no': cardNo,
        'mb_card_id': _jsonId(memberCardId),
      },
      client: client,
    );
    return _readBegin(response);
  }

  Future<Result<void>> makeCardEnd(
    ClientKind client, {
    required String cardNo,
    required String memberCardId,
  }) async {
    if (cardNo.isEmpty || memberCardId.isEmpty) {
      return const FailureResult(_shapeFailure);
    }
    return _ack(
      _post(
        '/mb/card/mk_card_end',
        body: <String, Object?>{
          'card_no': cardNo,
          'mb_card_id': _jsonId(memberCardId),
        },
        client: client,
      ),
      fallback: '制卡失败，请重试',
      disallowed: <String>[cardNo],
    );
  }

  Future<Result<void>> depositPoints(
    ClientKind client, {
    required String cardId,
    required String operatorEmpId,
    required int points,
    String remark = '',
  }) {
    if (cardId.isEmpty || points < 1) {
      return Future.value(const FailureResult(_shapeFailure));
    }
    return _ack(
      _post(
        '/mb/card/deposit_pt',
        body: <String, Object?>{
          'id': _jsonId(cardId),
          'oper_emp_id': _jsonId(operatorEmpId),
          'pt_amt': points,
          'remark': remark,
        },
        client: client,
      ),
      fallback: '充值积分失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> subtractPoints(
    ClientKind client, {
    required String cardId,
    required String operatorEmpId,
    required int points,
    String remark = '',
  }) {
    if (cardId.isEmpty || points < 1) {
      return Future.value(const FailureResult(_shapeFailure));
    }
    return _ack(
      _post(
        '/mb/card/subtract_pt',
        body: <String, Object?>{
          'id': _jsonId(cardId),
          'oper_emp_id': _jsonId(operatorEmpId),
          'pt_amt': points,
          'remark': remark,
        },
        client: client,
      ),
      fallback: '扣除积分失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> lockCard(ClientKind client, {required String cardId}) {
    if (cardId.isEmpty) {
      return Future.value(const FailureResult(_shapeFailure));
    }
    return _ack(
      _post(
        '/mb/card/lock',
        body: <String, Object?>{'mb_card_id': _jsonId(cardId)},
        client: client,
      ),
      fallback: '冻结失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> unlockCard(ClientKind client, {required String cardId}) {
    if (cardId.isEmpty) {
      return Future.value(const FailureResult(_shapeFailure));
    }
    return _ack(
      _post(
        '/mb/card/unlock',
        body: <String, Object?>{'mb_card_id': _jsonId(cardId)},
        client: client,
      ),
      fallback: '解冻失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> closeCard(
    ClientKind client, {
    required String cardId,
    String storedBalance = '',
    String giftBalance = '',
    int points = 0,
  }) {
    if (cardId.isEmpty) {
      return Future.value(const FailureResult(_shapeFailure));
    }
    return _ack(
      _post(
        '/mb/card/close',
        body: <String, Object?>{
          'mb_card_id': _jsonId(cardId),
          'val_balance': storedBalance,
          'free_balance': giftBalance,
          'pt_amt': points,
        },
        client: client,
      ),
      fallback: '注销失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> lossCard(ClientKind client, {required String cardId}) {
    return _ack(
      _post(
        '/mb/card/loss_card',
        body: <String, Object?>{'id': _jsonId(cardId)},
        client: client,
      ),
      fallback: '挂失失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> enableCard(ClientKind client, {required String cardId}) {
    return _ack(
      _post(
        '/mb/card/enable_card',
        body: <String, Object?>{'id': _jsonId(cardId)},
        client: client,
      ),
      fallback: '解除挂失失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> changeLevel(
    ClientKind client, {
    required String cardId,
    required String levelId,
  }) {
    return updownLevel(client, cardId: cardId, destLevelId: levelId);
  }

  Future<Result<void>> saveCard(
    ClientKind client, {
    required String cardId,
    required String name,
    String contactPhone = '',
    int sex = 1,
    String birthday = '',
    String mark = '',
    int expiredType = 0,
    String salesEmpId = '0',
    List<int> smsTypeIds = const [],
  }) {
    return _ack(
      _post(
        '/mb/card/save',
        body: <String, Object?>{
          'id': _jsonId(cardId),
          'contact_phone': contactPhone,
          'name': name,
          'sex': sex,
          'birthday': birthday,
          'mark': mark,
          'expired_type': expiredType,
          'sms_type_ids': smsTypeIds,
          'sales_emp_id': _jsonId(salesEmpId),
        },
        client: client,
      ),
      fallback: '编辑会员失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<VipLevelChangeInfo>> getForLevelChange(
    ClientKind client, {
    required String cardId,
  }) async {
    final response = await _post(
      '/mb/card/get_mb_card_f_levelupdown',
      body: <String, Object?>{'id': _jsonId(cardId)},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    final info = data['card_info'];
    final card = info is Map ? info : const <Object?, Object?>{};
    final levels = <VipCardLevel>[];
    final raw = data['card_level_dfn'];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final id = _asId(item['id']);
        if (id == null) continue;
        levels.add(VipCardLevel(id: id, name: _money(item['n'])));
      }
    }
    return Success(
      VipLevelChangeInfo(
        currentLevelId: _asId(card['card_level_id']) ?? '',
        cardNo: _money(card['card_no']),
        name: _money(card['name']),
        bindPhone: _money(card['bind_phone']),
        contactPhone: _money(card['contact_phone']),
        storedBalance: _money(card['val_balance']),
        giftBalance: _money(card['free_balance']),
        points: _money(card['pt_balance']),
        levels: levels,
      ),
    );
  }

  Future<Result<void>> updownLevel(
    ClientKind client, {
    required String cardId,
    required String destLevelId,
  }) {
    return _ack(
      _post(
        '/mb/card/updown_mb_card_level',
        body: <String, Object?>{
          'id': _jsonId(cardId),
          'dest_card_level_id': _jsonId(destLevelId),
        },
        client: client,
      ),
      fallback: '更改等级失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> returnCard(
    ClientKind client, {
    required String cardId,
    required String remark,
  }) {
    return _ack(
      _post(
        '/mb/card/return',
        body: <String, Object?>{
          'mb_card_id': _jsonId(cardId),
          'remark': remark,
        },
        client: client,
      ),
      fallback: '退卡失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<void>> subtractMoney(
    ClientKind client, {
    required String cardId,
    required String storedAmt,
    String giftAmt = '0',
    int points = 0,
    required String operatorEmpId,
    int typeId = 1,
  }) {
    return _ack(
      _post(
        '/mb/card/subtract',
        body: <String, Object?>{
          'id': _jsonId(cardId),
          'val_amt': storedAmt,
          'free_amt': giftAmt,
          'pt_amt': points,
          'pt_bal': _jsonId(operatorEmpId),
          'type_id': typeId,
        },
        client: client,
      ),
      fallback: '扣款失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<VipMakeCardBegin>> changeCardBegin(
    ClientKind client, {
    required String cardNo,
    required String memberCardId,
  }) async {
    final response = await _post(
      '/mb/card/mk_card_f_chg_begin',
      body: <String, Object?>{
        'card_no': cardNo,
        'mb_card_id': _jsonId(memberCardId),
      },
      client: client,
    );
    return _readBegin(response);
  }

  Future<Result<void>> changeCardEnd(
    ClientKind client, {
    required String cardNo,
    required String memberCardId,
  }) {
    return _ack(
      _post(
        '/mb/card/mk_card_f_chg_end',
        body: <String, Object?>{
          'card_no': cardNo,
          'mb_card_id': _jsonId(memberCardId),
        },
        client: client,
      ),
      fallback: '换卡失败，请重试',
      disallowed: <String>[cardNo],
    );
  }

  Future<Result<String>> checkSms(
    ClientKind client, {
    required String phone,
    required String code,
  }) async {
    final response = await _post(
      '/sms/valid_chk',
      body: <String, Object?>{'m': phone, 'c': code},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final wire = _wireCode(envelope['code']);
    if (wire == null) return const FailureResult(_shapeFailure);
    if (wire != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    final token = _money(data['c']);
    if (token.isEmpty) return const FailureResult(_shapeFailure);
    return Success(token);
  }

  Future<Result<void>> bindPhone(
    ClientKind client, {
    required String cardId,
    required String phone,
    String authCode = '',
    List<int> smsTypeIds = const [],
  }) {
    return _ack(
      _post(
        '/mb/card/bind_bind_phone',
        body: <String, Object?>{
          'id': _jsonId(cardId),
          'bind_phone_auth_code': authCode,
          'bind_phone': phone,
          'sms_type_ids': smsTypeIds,
        },
        client: client,
      ),
      fallback: '绑定手机失败，请重试',
      disallowed: <String>[phone],
    );
  }

  Future<Result<void>> changeBindPhone(
    ClientKind client, {
    required String cardId,
    required String phone,
    String authCode = '',
  }) {
    return _ack(
      _post(
        '/mb/card/chg_bind_phone',
        body: <String, Object?>{
          'id': _jsonId(cardId),
          'bind_phone_auth_code': authCode,
          'bind_phone': phone,
        },
        client: client,
      ),
      fallback: '改绑手机失败，请重试',
      disallowed: <String>[phone],
    );
  }

  Future<Result<VipOperCard>> getOperCard(
    ClientKind client, {
    required String cardId,
  }) async {
    final response = await _post(
      '/mb/card/get_mb_card_f_oper',
      body: <String, Object?>{'id': _jsonId(cardId)},
      client: client,
    );
    return _readOper(response);
  }

  Future<Result<VipEditCard>> getForEdit(
    ClientKind client, {
    required String cardId,
  }) async {
    final response = await _post(
      '/mb/card/get_f_edit',
      body: <String, Object?>{'id': _jsonId(cardId)},
      client: client,
    );
    return _readEdit(response);
  }

  Future<Result<VipBindPhonePrep>> getForBindPhone(
    ClientKind client, {
    required String cardId,
  }) async {
    final response = await _post(
      '/mb/card/get_f_bind_phone',
      body: <String, Object?>{'id': _jsonId(cardId)},
      client: client,
    );
    return _readBindPrep(response);
  }

  Future<Result<void>> depositMoney(
    ClientKind client, {
    required String cardId,
    required String storedAmt,
    String giftAmt = '0',
    int points = 0,
    int mode = 1,
    required String operatorEmpId,
    int channelId = 0,
    String salesEmpId = '0',
    String remark = '',
    String csmId = '',
  }) {
    final body = <String, Object?>{
      'id': _jsonId(cardId),
      'val_amt': storedAmt,
      'free_amt': giftAmt,
      'pt_amt': points,
      'm': mode,
      'oper_emp_id': _jsonId(operatorEmpId),
      'deposit_cnl': channelId,
      'sales_emp_id': _jsonId(salesEmpId),
      'remark': remark,
    };
    if (csmId.isNotEmpty) body['csm_id'] = _jsonId(csmId);
    return _ack(
      _post('/mb/card/deposit', body: body, client: client),
      fallback: '充值失败，请重试',
      disallowed: const <String>[],
    );
  }

  Future<Result<String>> getCardSecret(
    ClientKind client, {
    required String cardNo,
  }) async {
    final response = await _post(
      '/mb/card/get_card_p',
      body: <String, Object?>{'card_no': cardNo},
      client: client,
    );
    return _readField(response, 'p');
  }

  Future<Result<String>> getCardIdFromReal(
    ClientKind client, {
    required String cardNo,
    required String digest,
  }) async {
    final response = await _post(
      '/mb/card/get_mb_card_f_real',
      body: <String, Object?>{'card_no': cardNo, 'dt': digest},
      client: client,
    );
    return _readField(response, 'id');
  }

  Future<Result<Map<String, String>>> getMemberDetail(
    ClientKind client, {
    String cardId = '',
    String phone = '',
  }) async {
    final response = await _post(
      '/mb/info/get',
      body: phone.isNotEmpty
          ? <String, Object?>{'bind_phone': phone}
          : <String, Object?>{'id': _jsonId(cardId)},
      client: client,
    );
    return _readStringMap(response);
  }

  Future<Result<VipMapPage>> getMemberCards(
    ClientKind client, {
    String cardId = '',
    String phone = '',
  }) {
    return _readMapPage(
      _post(
        '/mb/info/get_cards',
        body: phone.isNotEmpty
            ? <String, Object?>{'bind_phone': phone}
            : <String, Object?>{'id': _jsonId(cardId)},
        client: client,
      ),
    );
  }

  Future<Result<VipMapPage>> getBalanceLogs(
    ClientKind client, {
    String cardId = '',
    String phone = '',
    int pageNum = 1,
    int pageSize = 20,
  }) {
    return _readMapPage(
      _post(
        '/mb/info/get_bal_logs',
        body: <String, Object?>{
          'page_num': pageNum,
          'page_size': pageSize,
          if (phone.isNotEmpty) 'bind_phone': phone,
          if (phone.isEmpty) 'id': _jsonId(cardId),
        },
        client: client,
      ),
    );
  }

  Future<Result<VipMapPage>> getMemberCoupons(
    ClientKind client, {
    required String phone,
    int pageNum = 1,
    int pageSize = 20,
    int status = 0,
  }) {
    return _readMapPage(
      _post(
        '/mb/info/get_mb_my_kq_list',
        body: <String, Object?>{
          'page_num': pageNum,
          'page_size': pageSize,
          'status': status,
          'bind_phone': phone,
        },
        client: client,
      ),
    );
  }

  Future<Result<VipMapPage>> getMemberWines(
    ClientKind client, {
    required String phone,
  }) {
    return _readMapPage(
      _post(
        '/mb/info/get_mb_my_wine_list',
        body: <String, Object?>{'bind_phone': phone},
        client: client,
      ),
    );
  }

  Future<Result<VipMapPage>> getTopProducts(
    ClientKind client, {
    String cardId = '',
    String phone = '',
  }) {
    return _readMapPage(
      _post(
        '/mb/info/get_mb_csm_top_prds',
        body: phone.isNotEmpty
            ? <String, Object?>{'bind_phone': phone}
            : <String, Object?>{'id': _jsonId(cardId)},
        client: client,
      ),
    );
  }

  Future<Result<VipMapPage>> searchDepositCards(
    ClientKind client, {
    required String phone,
  }) {
    return _readMapPage(
      _post(
        '/mb/card/get_f_deposits',
        body: <String, Object?>{'phone': phone},
        client: client,
      ),
    );
  }

  Future<Result<VipPaySerial>> validPaySerial(
    ClientKind client, {
    required String code,
  }) async {
    final response = await _post(
      '/sel/valid_cust_srv_code',
      body: <String, Object?>{'srv_code': code},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final wire = _wireCode(envelope['code']);
    if (wire == null) return const FailureResult(_shapeFailure);
    if (wire != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    return Success(
      VipPaySerial(phone: _money(data['p']), authCode: _money(data['c'])),
    );
  }

  Future<Result<VipMapPage>> listPhonePayCards(
    ClientKind client, {
    required String phone,
    required String authCode,
  }) {
    return _readMapPage(
      _post(
        '/sel/get_phone_mb_cards',
        body: <String, Object?>{'sms_auth_code': authCode, 'phone_num': phone},
        client: client,
      ),
    );
  }

  Future<Result<void>> sendSms(
    ClientKind client, {
    required String phone,
    required int typeId,
  }) async {
    if (phone.length != 11 || typeId < 1) {
      return const FailureResult(_shapeFailure);
    }
    return _ack(
      _post(
        '/sms/valid_send',
        body: <String, Object?>{'t': typeId, 'm': phone},
        client: client,
      ),
      fallback: '验证码发送失败，请重试',
      disallowed: <String>[phone],
    );
  }

  Result<VipCardPage> _readPage(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const Success(VipCardPage(total: 0));
    return Success(
      VipCardPage(
        total: _wireCode(data['row_cnt']) ?? 0,
        records: _rows(data['records']),
        types: _types(data['card_types']),
      ),
    );
  }

  Result<VipNewCardParams> _readParams(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const Success(VipNewCardParams());
    return Success(
      VipNewCardParams(
        cardNo: _money(data['card_no']),
        types: _types(data['card_types']),
        marks: _named(data['marks']),
        validYears: _named(data['valid_years']),
        smsTypes: _named(data['sms_types']),
      ),
    );
  }

  Result<String> _readId(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.vip_manager_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: '新建会员失败，请重试',
            disallowed: const <String>[],
          ),
        ),
      );
    }
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    final id = _asId(data['id']);
    if (id == null) return const FailureResult(_shapeFailure);
    return Success(id);
  }

  Result<List<VipCardRow>> _readRecords(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const Success([]);
    return Success(_rows(data['records']));
  }

  Result<VipMakeCardBegin> _readBegin(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    return Success(
      VipMakeCardBegin(
        cardPass: _money(data['card_pass']),
        verifyData: _money(data['card_verify_data']),
      ),
    );
  }

  Result<VipOperCard> _readOper(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    return Success(
      VipOperCard(
        cardNo: _money(data['card_no']),
        name: _money(data['name']),
        bindPhone: _money(data['bind_phone']),
        contactPhone: _money(data['contact_phone']),
        storedBalance: _money(data['val_bal']),
        giftBalance: _money(data['free_bal']),
        points: _money(data['pt_bal']),
        consumeBaseAmt: _wireCode(data['consume_base_amt']) ?? 0,
      ),
    );
  }

  Result<VipEditCard> _readEdit(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    final info = data['card_info'];
    final card = info is Map ? info : const <Object?, Object?>{};
    return Success(
      VipEditCard(
        name: _money(card['name']),
        cardNo: _money(card['card_no']),
        contactPhone: _money(card['contact_phone']),
        sex: _wireCode(card['sex']) ?? 1,
        birthday: _money(card['birthday']),
        mark: _money(card['mark']),
        expiredType: _wireCode(card['expired_type']) ?? 0,
        salesEmpId: _asId(card['sales_emp_id']) ?? '0',
        salesEmpName: _money(card['sales_emp_name']),
        typeName: _money(card['card_type_name']),
        levelName: _money(card['card_level_name']),
        marks: _named(data['marks']),
        validYears: _named(data['valid_years']),
        smsTypes: _named(data['sms_types']),
        registeredSmsTypeIds: _intList(data['reg_sms_types']),
      ),
    );
  }

  Result<VipBindPhonePrep> _readBindPrep(
    Result<Map<String, Object?>> response,
  ) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    final info = data['card_info'];
    final card = info is Map ? info : const <Object?, Object?>{};
    return Success(
      VipBindPhonePrep(
        cardNo: _money(card['card_no']),
        name: _money(card['name']),
        smsTypes: _named(data['sms_types']),
        registeredSmsTypeIds: _intList(data['reg_sms_types']),
      ),
    );
  }

  Result<String> _readField(Result<Map<String, Object?>> response, String key) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    final value = _asId(data[key]) ?? _money(data[key]);
    if (value.isEmpty) return const FailureResult(_shapeFailure);
    return Success(value);
  }

  Result<Map<String, String>> _readStringMap(
    Result<Map<String, Object?>> response,
  ) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    return Success(_stringMap(data));
  }

  Future<Result<VipMapPage>> _readMapPage(
    Future<Result<Map<String, Object?>>> pending,
  ) async {
    final response = await pending;
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const Success(VipMapPage());
    final raw = data['datas'] ?? data['records'];
    final records = <Map<String, String>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) records.add(_stringMap(item));
      }
    }
    return Success(
      VipMapPage(
        total: _wireCode(data['row_cnt']) ?? records.length,
        records: records,
      ),
    );
  }

  Future<Result<void>> _ack(
    Future<Result<Map<String, Object?>>> pending, {
    required String fallback,
    required List<String> disallowed,
  }) async {
    final response = await pending;
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) {
      return FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.vip_manager_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: fallback,
            disallowed: disallowed,
          ),
        ),
      );
    }
    return const Success(null);
  }

  List<VipCardRow> _rows(Object? raw) {
    if (raw is! List) return const [];
    final rows = <VipCardRow>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final id = _asId(item['id']);
      if (id == null) continue;
      rows.add(
        VipCardRow(
          id: id,
          name: _money(item['n']),
          statusName: _money(item['sn']),
          bindPhone: _money(item['bp']),
          contactPhone: _money(item['cp']),
          sex: _money(item['s']),
          birthday: _money(item['b']),
          cardNo: _money(item['cn']),
          typeName: _money(item['ct']),
          levelName: _money(item['cl']),
          balance: _money(item['ba']),
          points: _money(item['p']),
          salesName: _money(item['se']),
          hasPhysicalCard: _wireCode(item['h']) == 1,
        ),
      );
    }
    return rows;
  }

  List<VipCardType> _types(Object? raw) {
    if (raw is! List) return const [];
    final rows = <VipCardType>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final id = _asId(item['id']);
      if (id == null) continue;
      rows.add(
        VipCardType(
          id: id,
          name: _money(item['n']),
          levels: _named(item['ls']),
        ),
      );
    }
    return rows;
  }

  List<VipCardLevel> _named(Object? raw) {
    if (raw is! List) return const [];
    final rows = <VipCardLevel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final id = _asId(item['id']);
      if (id == null) continue;
      rows.add(VipCardLevel(id: id, name: _money(item['n'])));
    }
    return rows;
  }

  List<int> _intList(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (_wireCode(item) != null) _wireCode(item)!,
    ];
  }

  Map<String, String> _stringMap(Map<dynamic, dynamic> source) {
    return {
      for (final entry in source.entries)
        if (entry.value is! List && entry.value is! Map)
          entry.key.toString(): _money(entry.value),
    };
  }
}

String? _asId(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt().toString(),
  String() when value.isNotEmpty && value.length <= 64 => value,
  _ => null,
};

String _money(Object? value) => switch (value) {
  num() when value.isFinite => value.toString(),
  String() => value,
  _ => '',
};

Object _jsonId(String id) {
  final parsed = int.tryParse(id);
  return parsed ?? id;
}

int? _wireCode(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt(),
  String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(value),
  _ => null,
};

String _safeMessage(
  Object? value, {
  required String fallback,
  required List<String> disallowed,
}) {
  if (value is! String || value.isEmpty || value.length > 160) return fallback;
  for (final secret in disallowed) {
    if (secret.isNotEmpty && value.contains(secret)) return fallback;
  }
  if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(value)) return fallback;
  return value;
}

const AppFailure _shapeFailure = AppFailure(
  kind: FailureKind.protocol,
  code: 'protocol.vip_manager_shape',
  safeMessage: '会员接口返回了无法识别的数据',
);
const AppFailure _rejectedFailure = AppFailure(
  kind: FailureKind.business,
  code: 'business.vip_manager_rejected',
  safeMessage: '服务端拒绝会员操作，请重试',
);
