import 'package:card_table/src/vip_manager.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

enum VipReportKind {
  depositLog,
  consumeLog,
  subtractLog,
  pointLog,
  balance,
  consumeRank,
  customerRelation,
  logout,
  changeLevel,
}

final class VipPointRule {
  const VipPointRule({required this.typeId, required this.baseAmt});

  final int typeId;
  final int baseAmt;
}

final class VipDepositGiftRule {
  const VipDepositGiftRule({
    required this.id,
    required this.depositFen,
    required this.giftFen,
    this.levelName = '',
    this.couponName = '',
    this.giftPoints = 0,
    this.couponId = '',
    this.remark = '',
    this.cardTypeId = '0',
    this.cardLevelId = '0',
  });

  final String id;
  final int depositFen;
  final int giftFen;
  final String levelName;
  final String couponName;
  final int giftPoints;
  final String couponId;
  final String remark;
  final String cardTypeId;
  final String cardLevelId;
}

final class VipCardNoRule {
  const VipCardNoRule({this.numLength = 5, this.prefix = ''});

  final int numLength;
  final String prefix;
}

final class VipCardTypeRow {
  const VipCardTypeRow({
    required this.id,
    required this.name,
    this.levelCount = '',
    this.updatedAt = '',
    this.createdAt = '',
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String levelCount;
  final String updatedAt;
  final String createdAt;
  final bool isDefault;
}

final class VipReportPage {
  const VipReportPage({
    this.total = 0,
    this.records = const [],
    this.summary = const {},
  });

  final int total;
  final List<Map<String, String>> records;
  final Map<String, String> summary;
}

final class VipLateDeposit {
  const VipLateDeposit({
    required this.id,
    required this.cardNo,
    required this.name,
    required this.phone,
    required this.channel,
    required this.amountFen,
    required this.operatedAt,
    this.remark = '',
  });

  final String id;
  final String cardNo;
  final String name;
  final String phone;
  final String channel;
  final int amountFen;
  final String operatedAt;
  final String remark;
}

final class VipTypeLevel {
  const VipTypeLevel({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.picName = '',
    this.expThreshold = 0,
    this.couponId = '',
    this.couponName = '',
  });

  final String id;
  final String name;
  final bool isDefault;
  final String picName;
  final int expThreshold;
  final String couponId;
  final String couponName;
}

final class VipCardTypeDetail {
  const VipCardTypeDetail({
    required this.name,
    this.isDefault = false,
    this.picPrefix = '',
    this.levels = const [],
  });

  final String name;
  final bool isDefault;
  final String picPrefix;
  final List<VipTypeLevel> levels;
}

final class VipCover {
  const VipCover({required this.id, required this.picName, this.url = ''});

  final String id;
  final String picName;
  final String url;
}

final class VipTypePointRule {
  const VipTypePointRule({
    required this.id,
    required this.levelName,
    required this.ruleName,
    required this.baseAmtFen,
  });

  final String id;
  final String levelName;
  final String ruleName;
  final int baseAmtFen;
}

typedef VipGetPointRule = Future<Result<VipPointRule>> Function();
typedef VipSavePointRule = Future<Result<void>> Function({
  required int typeId,
  required int baseAmt,
});
typedef VipListDepositRules =
    Future<Result<List<VipDepositGiftRule>>> Function({String cardTypeId});
typedef VipSaveDepositRule = Future<Result<void>> Function({
  String id,
  required int depositFen,
  required int giftFen,
  String cardTypeId,
  String cardLevelId,
  int giftPoints,
  String couponId,
  String remark,
});
typedef VipDeleteDepositRule = Future<Result<void>> Function({
  required int depositFen,
  required int giftFen,
});
typedef VipGetCardNoRule = Future<Result<VipCardNoRule>> Function();
typedef VipSaveCardNoRule = Future<Result<void>> Function({
  required int numLength,
  required String prefix,
});
typedef VipListQwMembers = Future<Result<VipReportPage>> Function({
  required int pageNum,
  required int pageSize,
  String keyword,
});
typedef VipListCardTypes = Future<Result<List<VipCardTypeRow>>> Function();
typedef VipCreateCardType = Future<Result<void>> Function({
  required String name,
  bool isDefault,
});
typedef VipRenameCardType = Future<Result<void>> Function({
  required String id,
  required String name,
});
typedef VipDeleteCardType = Future<Result<void>> Function(String id);
typedef VipSetDefaultCardType = Future<Result<void>> Function(String id);
typedef VipQueryReport = Future<Result<VipReportPage>> Function({
  required VipReportKind kind,
  int pageNum,
  int pageSize,
  String beginDay,
  String endDay,
  String keyword,
  int typeId,
  String salesEmpId,
});
typedef VipExportReport = Future<Result<void>> Function({
  required VipReportKind kind,
  int pageNum,
  int pageSize,
  String beginDay,
  String endDay,
  String keyword,
  int typeId,
  String salesEmpId,
  bool Function()? canDispatch,
});
typedef VipReprintBill = Future<Result<void>> Function(String logId);
typedef VipListLateDeposits = Future<Result<List<VipLateDeposit>>> Function({
  String keyword,
});
typedef VipRefundLateDeposit = Future<Result<void>> Function(String id);
typedef VipListBillRules = Future<Result<VipReportPage>> Function({
  required String cardTypeId,
  String cardLevelId,
  bool init,
  String keyword,
  int typeId,
});
typedef VipAddBillRule = Future<Result<void>> Function({
  required String cardTypeId,
  required String cardLevelId,
  required int typeId,
  required List<String> productIds,
});
typedef VipUpdateBillRule = Future<Result<void>> Function({
  required String cardTypeId,
  required int typeId,
  required List<String> ids,
});
typedef VipDeleteBillRule = Future<Result<void>> Function({
  required String cardTypeId,
  required List<String> ids,
});
typedef VipCopyBillRule = Future<Result<void>> Function({
  required String srcTypeId,
  required String destTypeId,
  required String srcLevelId,
  required String destLevelId,
});
typedef VipDepositPoints = Future<Result<void>> Function({
  required String cardId,
  required int points,
  String remark,
});
typedef VipSubtractPoints = Future<Result<void>> Function({
  required String cardId,
  required int points,
  String remark,
});
typedef VipLockCard = Future<Result<void>> Function(String cardId);
typedef VipCloseCard = Future<Result<void>> Function({
  required String cardId,
  String storedBalance,
  String giftBalance,
  int points,
});
typedef VipChangeLevel = Future<Result<void>> Function({
  required String cardId,
  required String levelId,
});
typedef VipGetCardTypeDetail = Future<Result<VipCardTypeDetail>> Function(
  String id,
);
typedef VipNewLevel = Future<Result<String>> Function({
  required String typeId,
  required String name,
  String picName,
  int expThreshold,
  String couponId,
});
typedef VipRenameLevel = Future<Result<void>> Function({
  required String id,
  required String name,
});
typedef VipDeleteLevel = Future<Result<void>> Function(String id);
typedef VipChangeLevelExp = Future<Result<void>> Function({
  required String id,
  required int expThreshold,
});
typedef VipChangeLevelCoupon = Future<Result<void>> Function({
  required String id,
  required String couponId,
});
typedef VipEnableAutoUpgrade = Future<Result<void>> Function({
  required String typeId,
  required List<String> levelIds,
  required List<int> expThresholds,
});
typedef VipDisableAutoUpgrade = Future<Result<void>> Function(String typeId);
typedef VipListCovers = Future<Result<List<VipCover>>> Function();
typedef VipDeleteCover = Future<Result<void>> Function(String id);
typedef VipListTypePointRules = Future<Result<List<VipTypePointRule>>> Function(
  String cardTypeId,
);
typedef VipSaveTypePointRule = Future<Result<void>> Function({
  String id,
  required String cardTypeId,
  required String cardLevelId,
  required int baseAmtFen,
});
typedef VipDeleteTypePointRule = Future<Result<void>> Function({
  required String id,
  required String cardTypeId,
});
typedef VipSaveMemberCard = Future<Result<void>> Function({
  required String cardId,
  required String name,
  String contactPhone,
  int sex,
  String birthday,
  String mark,
  int expiredType,
  String salesEmpId,
  List<int> smsTypeIds,
});
typedef VipGetLevelChange = Future<Result<VipLevelChangeInfo>> Function(
  String cardId,
);
typedef VipReturnCard = Future<Result<void>> Function({
  required String cardId,
  required String remark,
});
typedef VipSubtractMoney = Future<Result<void>> Function({
  required String cardId,
  required String storedAmt,
  String giftAmt,
  int points,
  int typeId,
});
typedef VipChangePhysicalCard = Future<Result<void>> Function({
  required String cardNo,
  required String memberCardId,
});
typedef VipCheckSms = Future<Result<String>> Function({
  required String phone,
  required String code,
});
typedef VipBindPhone = Future<Result<void>> Function({
  required String cardId,
  required String phone,
  String authCode,
  List<int> smsTypeIds,
});
typedef VipGetOperCard = Future<Result<VipOperCard>> Function(String cardId);
typedef VipGetEditCard = Future<Result<VipEditCard>> Function(String cardId);
typedef VipGetBindPrep = Future<Result<VipBindPhonePrep>> Function(
  String cardId,
);
typedef VipDepositMoney = Future<Result<void>> Function({
  required String cardId,
  required String storedAmt,
  String giftAmt,
  int points,
  int mode,
  int channelId,
  String salesEmpId,
  String remark,
});
typedef VipGetCardSecret = Future<Result<String>> Function(String cardNo);
typedef VipGetCardIdFromReal = Future<Result<String>> Function({
  required String cardNo,
  required String digest,
});
typedef VipGetMemberDetail = Future<Result<Map<String, String>>> Function({
  String cardId,
  String phone,
});
typedef VipGetMapPage = Future<Result<VipMapPage>> Function({
  String cardId,
  String phone,
  int pageNum,
  int pageSize,
  int status,
});
typedef VipSearchDepositCards = Future<Result<VipMapPage>> Function(
  String phone,
);
typedef VipValidPaySerial = Future<Result<VipPaySerial>> Function(String code);
typedef VipListPhonePayCards = Future<Result<VipMapPage>> Function({
  required String phone,
  required String authCode,
});
typedef VipChangeLevelPic = Future<Result<void>> Function({
  required String id,
  required String picName,
});
typedef VipListLevelCoupons = Future<Result<VipReportPage>> Function({
  int typeId,
  String keyword,
});
typedef VipNewCover = Future<Result<void>> Function(String picName);
typedef VipChangeBindPhone = Future<Result<void>> Function({
  required String cardId,
  required String phone,
  String authCode,
});
typedef VipLossCard = Future<Result<void>> Function(String cardId);
typedef VipEnableCard = Future<Result<void>> Function(String cardId);

final class VipPages {
  const VipPages({
    this.employees,
    this.configurationAccess,
    this.memberEditAccess,
    this.getPointRule,
    this.savePointRule,
    this.listDepositRules,
    this.saveDepositRule,
    this.deleteDepositRule,
    this.getCardNoRule,
    this.saveCardNoRule,
    this.listQwMembers,
    this.listCardTypes,
    this.createCardType,
    this.renameCardType,
    this.deleteCardType,
    this.setDefaultCardType,
    this.queryReport,
    this.exportReport,
    this.reprintBill,
    this.listLateDeposits,
    this.refundLateDeposit,
    this.listBillRules,
    this.addBillRule,
    this.updateBillRule,
    this.deleteBillRule,
    this.copyBillRule,
    this.depositPoints,
    this.subtractPoints,
    this.lockCard,
    this.unlockCard,
    this.closeCard,
    this.changeLevel,
    this.changeBindPhone,
    this.lossCard,
    this.enableCard,
    this.getCardTypeDetail,
    this.newLevel,
    this.renameLevel,
    this.deleteLevel,
    this.changeLevelExp,
    this.changeLevelCoupon,
    this.enableAutoUpgrade,
    this.disableAutoUpgrade,
    this.listCovers,
    this.deleteCover,
    this.listTypePointRules,
    this.saveTypePointRule,
    this.deleteTypePointRule,
    this.saveMemberCard,
    this.getLevelChange,
    this.returnCard,
    this.subtractMoney,
    this.changePhysicalCard,
    this.checkSms,
    this.bindPhone,
    this.getOperCard,
    this.getForEdit,
    this.getForBindPhone,
    this.depositMoney,
    this.getCardSecret,
    this.getCardIdFromReal,
    this.getMemberDetail,
    this.getMemberCards,
    this.getBalanceLogs,
    this.getMemberCoupons,
    this.getMemberWines,
    this.getTopProducts,
    this.searchDepositCards,
    this.validPaySerial,
    this.listPhonePayCards,
    this.changeLevelPic,
    this.listLevelCoupons,
    this.newCover,
  });

  final bool Function()? configurationAccess;
  final List<CardEmployee> Function()? employees;
  List<CardEmployee> get salesEmployees => employees?.call() ?? const [];
  final bool Function()? memberEditAccess;
  bool get canConfigure => configurationAccess?.call() ?? true;
  bool get canManageMembers => memberEditAccess?.call() ?? true;

  final VipGetPointRule? getPointRule;
  final VipSavePointRule? savePointRule;
  final VipListDepositRules? listDepositRules;
  final VipSaveDepositRule? saveDepositRule;
  final VipDeleteDepositRule? deleteDepositRule;
  final VipGetCardNoRule? getCardNoRule;
  final VipSaveCardNoRule? saveCardNoRule;
  final VipListQwMembers? listQwMembers;
  final VipListCardTypes? listCardTypes;
  final VipCreateCardType? createCardType;
  final VipRenameCardType? renameCardType;
  final VipDeleteCardType? deleteCardType;
  final VipSetDefaultCardType? setDefaultCardType;
  final VipQueryReport? queryReport;
  final VipExportReport? exportReport;
  final VipReprintBill? reprintBill;
  final VipListLateDeposits? listLateDeposits;
  final VipRefundLateDeposit? refundLateDeposit;
  final VipListBillRules? listBillRules;
  final VipAddBillRule? addBillRule;
  final VipUpdateBillRule? updateBillRule;
  final VipDeleteBillRule? deleteBillRule;
  final VipCopyBillRule? copyBillRule;
  final VipDepositPoints? depositPoints;
  final VipSubtractPoints? subtractPoints;
  final VipLockCard? lockCard;
  final VipLockCard? unlockCard;
  final VipCloseCard? closeCard;
  final VipChangeLevel? changeLevel;
  final VipChangeBindPhone? changeBindPhone;
  final VipLossCard? lossCard;
  final VipEnableCard? enableCard;
  final VipGetCardTypeDetail? getCardTypeDetail;
  final VipNewLevel? newLevel;
  final VipRenameLevel? renameLevel;
  final VipDeleteLevel? deleteLevel;
  final VipChangeLevelExp? changeLevelExp;
  final VipChangeLevelCoupon? changeLevelCoupon;
  final VipEnableAutoUpgrade? enableAutoUpgrade;
  final VipDisableAutoUpgrade? disableAutoUpgrade;
  final VipListCovers? listCovers;
  final VipDeleteCover? deleteCover;
  final VipListTypePointRules? listTypePointRules;
  final VipSaveTypePointRule? saveTypePointRule;
  final VipDeleteTypePointRule? deleteTypePointRule;
  final VipSaveMemberCard? saveMemberCard;
  final VipGetLevelChange? getLevelChange;
  final VipReturnCard? returnCard;
  final VipSubtractMoney? subtractMoney;
  final VipChangePhysicalCard? changePhysicalCard;
  final VipCheckSms? checkSms;
  final VipBindPhone? bindPhone;
  final VipGetOperCard? getOperCard;
  final VipGetEditCard? getForEdit;
  final VipGetBindPrep? getForBindPhone;
  final VipDepositMoney? depositMoney;
  final VipGetCardSecret? getCardSecret;
  final VipGetCardIdFromReal? getCardIdFromReal;
  final VipGetMemberDetail? getMemberDetail;
  final VipGetMapPage? getMemberCards;
  final VipGetMapPage? getBalanceLogs;
  final VipGetMapPage? getMemberCoupons;
  final VipGetMapPage? getMemberWines;
  final VipGetMapPage? getTopProducts;
  final VipSearchDepositCards? searchDepositCards;
  final VipValidPaySerial? validPaySerial;
  final VipListPhonePayCards? listPhonePayCards;
  final VipChangeLevelPic? changeLevelPic;
  final VipListLevelCoupons? listLevelCoupons;
  final VipNewCover? newCover;
}

final class ProtocolVipPagesApi {
  const ProtocolVipPagesApi({required this.client, this.canDispatch});
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

  Future<Result<VipPointRule>> getPointRule(ClientKind client) async {
    final response = await _post(
      '/mb/card/get_pt_rule',
      body: const <String, Object?>{},
      client: client,
    );
    return _readMap(
      response,
      (data) => VipPointRule(
        typeId: _int(data['type_id']),
        baseAmt: _int(data['base_amt']),
      ),
    );
  }

  Future<Result<void>> savePointRule(
    ClientKind client, {
    required int typeId,
    required int baseAmt,
  }) {
    return _ack(
      _post(
        '/mb/card/save_pt_rule',
        body: <String, Object?>{
          'type_id': typeId,
          'base_amt': typeId == 1 ? 0 : baseAmt,
        },
        client: client,
      ),
    );
  }

  Future<Result<List<VipDepositGiftRule>>> listDepositRules(
    ClientKind client, {
    String cardTypeId = '0',
  }) {
    return _readList(
      _post(
        '/mb/deposit_rule/list',
        body: <String, Object?>{'card_type_id': _jsonId(cardTypeId)},
        client: client,
      ),
      (item) {
        final id = _asId(item['id']) ?? '';
        return VipDepositGiftRule(
          id: id,
          depositFen: _int(item['d']),
          giftFen: _int(item['f']),
          levelName: _text(item['n']),
          couponName: _text(item['fk']),
          giftPoints: _int(item['fp']),
          couponId: _asId(item['fk_id']) ?? _text(item['fk']),
          remark: _text(item['r']),
          cardTypeId: _asId(item['card_type_id']) ?? cardTypeId,
          cardLevelId: _asId(item['card_level_id']) ?? '0',
        );
      },
    );
  }

  Future<Result<void>> saveDepositRule(
    ClientKind client, {
    String id = '',
    required int depositFen,
    required int giftFen,
    String cardTypeId = '0',
    String cardLevelId = '0',
    int giftPoints = 0,
    String couponId = '0',
    String remark = '',
  }) {
    final body = <String, Object?>{
      'deposit_amt': depositFen,
      'free_amt': giftFen,
      'card_level_id': _jsonId(cardLevelId),
      'card_type_id': _jsonId(cardTypeId),
      'free_pt_amt': giftPoints,
      'free_kq_id': _jsonId(couponId.isEmpty ? '0' : couponId),
      'remark': remark,
    };
    if (id.isNotEmpty) body['id'] = _jsonId(id);
    return _ack(
      _post(
        id.isEmpty ? '/mb/deposit_rule/new' : '/mb/deposit_rule/save',
        body: body,
        client: client,
      ),
    );
  }

  Future<Result<void>> deleteDepositRule(
    ClientKind client, {
    required int depositFen,
    required int giftFen,
  }) {
    return _ack(
      _post(
        '/mb/deposit_rule/del',
        body: <String, Object?>{'deposit_amt': depositFen, 'free_amt': giftFen},
        client: client,
      ),
    );
  }

  Future<Result<VipCardNoRule>> getCardNoRule(ClientKind client) async {
    final response = await _post(
      '/mb/card/get_mb_card_no_rule',
      body: const <String, Object?>{},
      client: client,
    );
    return _readMap(
      response,
      (data) => VipCardNoRule(
        numLength: _int(data['num_length'], fallback: 5),
        prefix: _text(data['prefix']),
      ),
    );
  }

  Future<Result<void>> saveCardNoRule(
    ClientKind client, {
    required int numLength,
    required String prefix,
  }) {
    if (numLength < 1) return Future.value(const FailureResult(_shapeFailure));
    return _ack(
      _post(
        '/mb/card/save_mb_card_no_rule',
        body: <String, Object?>{'num_length': numLength, 'prefix': prefix},
        client: client,
      ),
    );
  }

  Future<Result<VipReportPage>> listQwMembers(
    ClientKind client, {
    required int pageNum,
    required int pageSize,
    String keyword = '',
  }) {
    return queryReport(
      client,
      kind: VipReportKind.depositLog,
      pageNum: pageNum,
      pageSize: pageSize,
      keyword: keyword,
      path: '/mb/rpt/get_qw_mb_list',
      body: <String, Object?>{
        'page_num': pageNum,
        'page_size': pageSize,
        'key': keyword,
      },
    );
  }

  Future<Result<List<VipCardTypeRow>>> listCardTypes(ClientKind client) {
    return _readList(
      _post('/mb/type/list', body: const <String, Object?>{}, client: client),
      (item) {
        final id = _asId(item['id']);
        if (id == null) throw _invalid;
        return VipCardTypeRow(
          id: id,
          name: _text(item['n']),
          levelCount: _text(item['ct']),
          updatedAt: _text(item['u']),
          createdAt: _text(item['c']),
          isDefault: _int(item['d']) == 1,
        );
      },
    );
  }

  Future<Result<void>> createCardType(
    ClientKind client, {
    required String name,
    bool isDefault = false,
  }) {
    if (name.isEmpty || name.length > 10) {
      return Future.value(const FailureResult(_shapeFailure));
    }
    return _ack(
      _post(
        '/mb/type/new',
        body: <String, Object?>{'name': name, 'is_def': isDefault ? 1 : 2},
        client: client,
      ),
    );
  }

  Future<Result<void>> renameCardType(
    ClientKind client, {
    required String id,
    required String name,
  }) {
    return _ack(
      _post(
        '/mb/type/chg_name',
        body: <String, Object?>{'id': _jsonId(id), 'name': name},
        client: client,
      ),
    );
  }

  Future<Result<void>> deleteCardType(ClientKind client, String id) {
    return _ack(
      _post(
        '/mb/type/del',
        body: <String, Object?>{'id': _jsonId(id)},
        client: client,
      ),
    );
  }

  Future<Result<void>> setDefaultCardType(ClientKind client, String id) {
    return _ack(
      _post(
        '/mb/type/chg_def',
        body: <String, Object?>{'id': _jsonId(id)},
        client: client,
      ),
    );
  }

  Future<Result<VipReportPage>> queryReport(
    ClientKind client, {
    required VipReportKind kind,
    int pageNum = 1,
    int pageSize = 20,
    String beginDay = '',
    String endDay = '',
    String keyword = '',
    int typeId = 0,
    String salesEmpId = '',
    String? path,
    Map<String, Object?>? body,
  }) async {
    final response = await _post(
      path ?? kind.path,
      body:
          body ??
          kind.body(
            pageNum: pageNum,
            pageSize: pageSize,
            beginDay: beginDay,
            endDay: endDay,
            keyword: keyword,
            typeId: typeId,
            salesEmpId: salesEmpId,
          ),
      client: client,
    );
    return _readReport(response);
  }

  Future<Result<ProtocolBinaryFile>> exportReport(
    ClientKind client, {
    required VipReportKind kind,
    int pageNum = 1,
    int pageSize = 20,
    String beginDay = '',
    String endDay = '',
    String keyword = '',
    int typeId = 0,
    String salesEmpId = '',
  }) {
    final body = kind.body(
      pageNum: pageNum,
      pageSize: pageSize,
      beginDay: beginDay,
      endDay: endDay,
      keyword: keyword,
      typeId: typeId,
      salesEmpId: salesEmpId,
    );
    // Only the legacy level-change export carries pagination.
    if (kind != VipReportKind.changeLevel) {
      body.remove('page_num');
      body.remove('page_size');
    }
    return this.client.postBinary(
      kind.exportPath,
      body: body,
      client: client,
      canDispatch: canDispatch,
      fallbackFileName: 'vip-${kind.name}.xlsx',
    );
  }

  Future<Result<void>> reprintBill(ClientKind client, {required String logId}) {
    return _ack(
      _post(
        '/mb/rpt/re_print_mb_bill',
        body: <String, Object?>{'log_id': _jsonId(logId)},
        client: client,
      ),
    );
  }

  Future<Result<List<VipLateDeposit>>> listLateDeposits(
    ClientKind client, {
    String keyword = '',
  }) {
    return _readList(
      _post(
        '/sel/get_deposit_late_list',
        body: <String, Object?>{'key': keyword},
        client: client,
      ),
      (item) {
        final id = _asId(item['id']);
        if (id == null) throw _invalid;
        return VipLateDeposit(
          id: id,
          cardNo: _text(item['c']),
          name: _text(item['n']),
          phone: _text(item['p']),
          channel: _text(item['l']),
          amountFen: _int(item['a']),
          operatedAt: _text(item['o']),
          remark: _text(item['r']),
        );
      },
    );
  }

  Future<Result<void>> refundLateDeposit(
    ClientKind client, {
    required String id,
  }) {
    return _ack(
      _post(
        '/sel/back_deposit_late',
        body: <String, Object?>{'id': _jsonId(id)},
        client: client,
      ),
    );
  }

  Future<Result<VipReportPage>> listBillRules(
    ClientKind client, {
    required String cardTypeId,
    String cardLevelId = '0',
    bool init = false,
    String keyword = '',
    int typeId = 0,
    int oneCateId = 0,
    int twoCateId = 0,
  }) async {
    final response = await _post(
      '/mb/card/get_grp_mb_csm_rule_list',
      body: <String, Object?>{
        'init': init ? 1 : 2,
        'one_cate_id': oneCateId,
        'two_cate_id': twoCateId,
        'name': keyword,
        'card_type_id': _jsonId(cardTypeId),
        'card_level_id': _jsonId(cardLevelId),
        'type_id': typeId,
      },
      client: client,
    );
    return _readReport(response);
  }

  Future<Result<void>> addBillRule(
    ClientKind client, {
    required String cardTypeId,
    required String cardLevelId,
    required int typeId,
    required List<String> productIds,
  }) {
    return _ack(
      _post(
        '/mb/card/add_grp_mb_csm_rule',
        body: <String, Object?>{
          'prd_ids': [for (final id in productIds) _jsonId(id)],
          'type_id': typeId,
          'card_level_id': _jsonId(cardLevelId),
          'card_type_id': _jsonId(cardTypeId),
        },
        client: client,
      ),
    );
  }

  Future<Result<void>> updateBillRule(
    ClientKind client, {
    required String cardTypeId,
    required int typeId,
    required List<String> ids,
  }) {
    return _ack(
      _post(
        '/mb/card/chg_grp_mb_csm_rule',
        body: <String, Object?>{
          'ids': [for (final id in ids) _jsonId(id)],
          'card_type_id': _jsonId(cardTypeId),
          'type_id': typeId,
        },
        client: client,
      ),
    );
  }

  Future<Result<void>> deleteBillRule(
    ClientKind client, {
    required String cardTypeId,
    required List<String> ids,
  }) {
    return _ack(
      _post(
        '/mb/card/del_grp_mb_csm_rule',
        body: <String, Object?>{
          'ids': [for (final id in ids) _jsonId(id)],
          'card_type_id': _jsonId(cardTypeId),
        },
        client: client,
      ),
    );
  }

  Future<Result<void>> copyBillRule(
    ClientKind client, {
    required String srcTypeId,
    required String destTypeId,
    required String srcLevelId,
    required String destLevelId,
  }) {
    return _ack(
      _post(
        '/mb/card/clone_grp_mb_csm_rule',
        body: <String, Object?>{
          'src_mb_card_type_id': _jsonId(srcTypeId),
          'dest_mb_card_type_id': _jsonId(destTypeId),
          'src_mb_card_level_id': _jsonId(srcLevelId),
          'dest_mb_card_level_id': _jsonId(destLevelId),
        },
        client: client,
      ),
    );
  }

  Future<Result<VipCardTypeDetail>> getCardTypeDetail(
    ClientKind client, {
    required String id,
  }) async {
    return _readMap(
      await _post(
        '/mb/type/get',
        body: <String, Object?>{'id': _jsonId(id)},
        client: client,
      ),
      (data) => VipCardTypeDetail(
        name: _text(data['name']),
        isDefault: _int(data['is_def']) == 1,
        picPrefix: _text(data['pic_url_prefix']),
        levels: [
          for (final item
              in (data['card_levels'] is List
                  ? data['card_levels'] as List
                  : const []))
            if (item is Map)
              VipTypeLevel(
                id: _asId(item['id']) ?? '',
                name: _text(item['n']),
                isDefault: _int(item['d']) == 1,
                picName: _text(item['p']),
                expThreshold: _int(item['e']),
                couponId: _asId(item['k']) ?? '',
                couponName: _text(item['kn']),
              ),
        ],
      ),
    );
  }

  Future<Result<String>> newLevel(
    ClientKind client, {
    required String typeId,
    required String name,
    String picName = '',
    int expThreshold = 0,
    String couponId = '0',
  }) {
    return _readCreatedId(
      _post(
        '/mb/type/new_level',
        body: <String, Object?>{
          'id': _jsonId(typeId),
          'level_name': name,
          'level_pic_name': picName,
          'exp_threshold': expThreshold,
          'kq_id': _jsonId(couponId.isEmpty ? '0' : couponId),
        },
        client: client,
      ),
    );
  }

  Future<Result<void>> renameLevel(
    ClientKind client, {
    required String id,
    required String name,
  }) {
    return _ack(
      _post(
        '/mb/type/chg_level_name',
        body: <String, Object?>{'id': _jsonId(id), 'name': name},
        client: client,
      ),
    );
  }

  Future<Result<void>> deleteLevel(ClientKind client, {required String id}) {
    return _ack(
      _post(
        '/mb/type/del_level',
        body: <String, Object?>{'id': _jsonId(id)},
        client: client,
      ),
    );
  }

  Future<Result<void>> changeLevelExp(
    ClientKind client, {
    required String id,
    required int expThreshold,
  }) {
    return _ack(
      _post(
        '/mb/type/chg_mb_card_level_exp_td',
        body: <String, Object?>{
          'id': _jsonId(id),
          'exp_threshold': expThreshold,
        },
        client: client,
      ),
    );
  }

  Future<Result<void>> changeLevelCoupon(
    ClientKind client, {
    required String id,
    required String couponId,
  }) {
    return _ack(
      _post(
        '/mb/type/chg_level_kq',
        body: <String, Object?>{'id': _jsonId(id), 'kq_id': _jsonId(couponId)},
        client: client,
      ),
    );
  }

  Future<Result<void>> enableAutoUpgrade(
    ClientKind client, {
    required String typeId,
    required List<String> levelIds,
    required List<int> expThresholds,
  }) {
    return _ack(
      _post(
        '/mb/type/enable_autoupd',
        body: <String, Object?>{
          'id': _jsonId(typeId),
          'ls': [for (final id in levelIds) _jsonId(id)],
          'es': expThresholds,
        },
        client: client,
      ),
    );
  }

  Future<Result<void>> disableAutoUpgrade(
    ClientKind client, {
    required String typeId,
  }) {
    return _ack(
      _post(
        '/mb/type/disable_autoupd',
        body: <String, Object?>{'id': _jsonId(typeId)},
        client: client,
      ),
    );
  }

  Future<Result<List<VipCover>>> listCovers(ClientKind client) async {
    final response = await _post(
      '/mb/type/get_cust_cover_list',
      body: const <String, Object?>{},
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
    if (data is! Map) return const Success([]);
    final prefix = _text(data['pic_url_prefix']);
    final raw = data['records'];
    if (raw is! List) return const Success([]);
    return Success([
      for (final item in raw)
        if (item is Map)
          VipCover(
            id: _asId(item['id']) ?? '',
            picName: _text(item['pic_name']),
            url: '$prefix${_text(item['pic_name'])}',
          ),
    ]);
  }

  Future<Result<void>> deleteCover(ClientKind client, {required String id}) {
    return _ack(
      _post(
        '/mb/type/del_cust_cover',
        body: <String, Object?>{'id': _jsonId(id)},
        client: client,
      ),
    );
  }

  Future<Result<void>> changeLevelPic(
    ClientKind client, {
    required String id,
    required String picName,
  }) {
    return _ack(
      _post(
        '/mb/type/chg_level_pic',
        body: <String, Object?>{'id': _jsonId(id), 'pic_name': picName},
        client: client,
      ),
    );
  }

  Future<Result<VipReportPage>> listLevelCoupons(
    ClientKind client, {
    int typeId = 0,
    String keyword = '',
  }) async {
    final response = await _post(
      '/mb/type/get_mb_card_level_kqs',
      body: <String, Object?>{'type_id': typeId, 'key': keyword},
      client: client,
    );
    return _readReport(response);
  }

  Future<Result<void>> newCover(ClientKind client, {required String picName}) {
    return _ack(
      _post(
        '/mb/type/new_cust_cover',
        body: <String, Object?>{'pic_name': picName},
        client: client,
      ),
    );
  }

  Future<Result<List<VipTypePointRule>>> listTypePointRules(
    ClientKind client, {
    required String cardTypeId,
  }) {
    return _readList(
      _post(
        '/mb/card/get_pt_rules',
        body: <String, Object?>{'card_type_id': _jsonId(cardTypeId)},
        client: client,
      ),
      (item) => VipTypePointRule(
        id: _asId(item['id']) ?? '',
        levelName: _text(item['n']),
        ruleName: _text(item['t']),
        baseAmtFen: _int(item['b']),
      ),
    );
  }

  Future<Result<void>> saveTypePointRule(
    ClientKind client, {
    String id = '',
    required String cardTypeId,
    required String cardLevelId,
    required int baseAmtFen,
  }) {
    final body = <String, Object?>{
      'base_amt': baseAmtFen,
      'card_level_id': _jsonId(cardLevelId),
      'card_type_id': _jsonId(cardTypeId),
    };
    if (id.isNotEmpty) body['id'] = _jsonId(id);
    return _ack(
      _post(
        id.isEmpty ? '/mb/card/new_pt_rule' : '/mb/card/save_pt_rule',
        body: body,
        client: client,
      ),
    );
  }

  Future<Result<void>> deleteTypePointRule(
    ClientKind client, {
    required String id,
    required String cardTypeId,
  }) {
    return _ack(
      _post(
        '/mb/card/del_pt_rule',
        body: <String, Object?>{
          'id': _jsonId(id),
          'card_type_id': _jsonId(cardTypeId),
        },
        client: client,
      ),
    );
  }

  Future<Result<VipReportPage>> listBillRuleProducts(
    ClientKind client, {
    String keyword = '',
    bool init = false,
    int oneCateId = 0,
    int twoCateId = 0,
  }) async {
    final response = await _post(
      '/mb/card/get_grp_mb_csm_rule_items',
      body: <String, Object?>{
        'name': keyword,
        'init': init ? 1 : 2,
        'one_cate_id': oneCateId,
        'two_cate_id': twoCateId,
      },
      client: client,
    );
    return _readReport(response);
  }

  Future<Result<void>> _ack(
    Future<Result<Map<String, Object?>>> pending,
  ) async {
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
          code: 'business.vip_pages_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: '服务端拒绝会员操作，请重试',
          ),
        ),
      );
    }
    return const Success(null);
  }

  Result<T> _readMap<T>(
    Result<Map<String, Object?>> response,
    T Function(Map<dynamic, dynamic>) parse,
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
    try {
      return Success(parse(data));
    } on FormatException {
      return const FailureResult(_shapeFailure);
    }
  }

  Future<Result<String>> _readCreatedId(
    Future<Result<Map<String, Object?>>> pending,
  ) async {
    final parsed = _readMap(await pending, (data) => _asId(data['id']) ?? '');
    if (parsed.failureOrNull != null)
      return FailureResult(parsed.failureOrNull!);
    final id = parsed.valueOrNull ?? '';
    if (id.isEmpty) return const FailureResult(_shapeFailure);
    return Success(id);
  }

  Future<Result<List<T>>> _readList<T>(
    Future<Result<Map<String, Object?>>> pending,
    T Function(Map<dynamic, dynamic>) parse,
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
    if (data is! Map) return const Success([]);
    final raw = data['records'];
    if (raw is! List) return const Success([]);
    try {
      return Success([
        for (final item in raw)
          if (item is Map) parse(item),
      ]);
    } on FormatException {
      return const FailureResult(_shapeFailure);
    }
  }

  Result<VipReportPage> _readReport(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map) return const Success(VipReportPage());
    final raw = data['datas'] ?? data['records'];
    final records = <Map<String, String>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        records.add({
          for (final entry in item.entries)
            entry.key.toString(): _text(entry.value),
        });
      }
    }
    final summary = <String, String>{};
    for (final entry in data.entries) {
      if (entry.key == 'datas' ||
          entry.key == 'records' ||
          entry.key == 'cates' ||
          entry.key == 'levels') {
        continue;
      }
      if (entry.value is List || entry.value is Map) {
        if (entry.key == 'cnls' && entry.value is List) {
          summary['cnls'] = (entry.value as List)
              .whereType<Map>()
              .map((item) => '${_text(item['n'])}:${_text(item['a'])}')
              .join(' ');
        }
        if (entry.key == 'total_info' && entry.value is Map) {
          final info = entry.value as Map;
          for (final field in info.entries) {
            summary[field.key.toString()] = _text(field.value);
          }
        }
        continue;
      }
      summary[entry.key.toString()] = _text(entry.value);
    }
    return Success(
      VipReportPage(
        total: _int(data['row_cnt']),
        records: records,
        summary: summary,
      ),
    );
  }
}

extension on VipReportKind {
  String get path => switch (this) {
    VipReportKind.depositLog => '/mb/rpt/get_deposit_log',
    VipReportKind.consumeLog => '/mb/rpt/get_consume_log',
    VipReportKind.subtractLog => '/mb/rpt/get_subtract_log',
    VipReportKind.pointLog => '/mb/rpt/get_pt_log',
    VipReportKind.balance => '/mb/rpt/get_mb_card_bal_list',
    VipReportKind.consumeRank => '/mb/rpt/get_mb_card_top_consume',
    VipReportKind.customerRelation => '/mb/rpt/get_mb_card_consume_list',
    VipReportKind.logout => '/mb/rpt/get_mb_card_zx_list',
    VipReportKind.changeLevel => '/mb/rpt/get_mb_card_updown_log',
  };

  String get exportPath => switch (this) {
    VipReportKind.depositLog => '/mb/rpt/exp_deposit_log',
    VipReportKind.consumeLog => '/mb/rpt/exp_consume_log',
    VipReportKind.subtractLog => '/mb/rpt/exp_subtract_log',
    VipReportKind.pointLog => '/mb/rpt/exp_pt_log',
    VipReportKind.balance => '/mb/rpt/exp_mb_card_bal_list',
    VipReportKind.consumeRank => '/mb/rpt/exp_mb_card_top_consume',
    VipReportKind.customerRelation => '/mb/rpt/exp_mb_card_consume_list',
    VipReportKind.logout => '/mb/rpt/exp_mb_card_zx_list',
    VipReportKind.changeLevel => '/mb/rpt/exp_mb_card_updown_log',
  };

  Map<String, Object?> body({
    required int pageNum,
    required int pageSize,
    required String beginDay,
    required String endDay,
    required String keyword,
    required int typeId,
    required String salesEmpId,
  }) {
    return switch (this) {
      VipReportKind.depositLog ||
      VipReportKind.subtractLog => <String, Object?>{
        'page_num': pageNum,
        'page_size': pageSize,
        'begin_day': beginDay,
        'end_day': endDay,
        'type_id': typeId,
        'key': keyword,
      },
      VipReportKind.consumeLog || VipReportKind.pointLog => <String, Object?>{
        'page_num': pageNum,
        'page_size': pageSize,
        'begin_day': beginDay,
        'end_day': endDay,
        'key': keyword,
        if (this == VipReportKind.pointLog) 'type_id': typeId,
      },
      VipReportKind.balance => <String, Object?>{
        'page_num': pageNum,
        'page_size': pageSize,
        'key': keyword,
      },
      VipReportKind.consumeRank || VipReportKind.logout => <String, Object?>{
        'key': keyword,
        'begin_day': beginDay,
        'end_day': endDay,
      },
      VipReportKind.customerRelation => <String, Object?>{
        'key': keyword,
        'begin_day': beginDay,
        'end_day': endDay,
        'sales_emp_id': _jsonId(salesEmpId),
      },
      VipReportKind.changeLevel => <String, Object?>{
        'key': keyword,
        'begin_day': beginDay,
        'end_day': endDay,
        'page_num': pageNum,
        'page_size': pageSize,
      },
    };
  }
}

Object _jsonId(String id) {
  final parsed = int.tryParse(id);
  return parsed ?? id;
}

String? _asId(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt().toString(),
  String() when value.isNotEmpty && value.length <= 64 => value,
  _ => null,
};

String _text(Object? value) => switch (value) {
  null => '',
  num() when value.isFinite => value.toString(),
  String() => value,
  _ => '',
};

int _int(Object? value, {int fallback = 0}) => switch (value) {
  num() when value.isFinite => value.toInt(),
  String() => int.tryParse(value) ?? fallback,
  _ => fallback,
};

int? _wireCode(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt(),
  String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(value),
  _ => null,
};

String _safeMessage(Object? value, {required String fallback}) {
  if (value is! String || value.isEmpty || value.length > 160) return fallback;
  if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(value)) return fallback;
  return value;
}

const FormatException _invalid = FormatException('Invalid vip pages payload');
const AppFailure _shapeFailure = AppFailure(
  kind: FailureKind.protocol,
  code: 'protocol.vip_pages_shape',
  safeMessage: '会员接口返回了无法识别的数据',
);
const AppFailure _rejectedFailure = AppFailure(
  kind: FailureKind.business,
  code: 'business.vip_pages_rejected',
  safeMessage: '服务端拒绝会员操作，请重试',
);
