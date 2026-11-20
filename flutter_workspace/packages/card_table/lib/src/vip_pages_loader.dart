import 'package:card_table/src/vip_manager.dart';
import 'package:card_table/src/card_table_models.dart';
import 'package:card_table/src/vip_pages.dart';
import 'package:card_table/src/wine_export_saver.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class SessionBoundVipPagesLoader {
  const SessionBoundVipPagesLoader({
    required this.session,
    required this.pages,
    required this.cards,
    required this.phase,
    required this.generation,
    this.hasMemberEditModule,
    this.accessGeneration,
    this.workspaceScope,
    this.saveExport = saveWineExport,
    this.employees,
  });

  final SessionRepository session;
  final ProtocolVipPagesApi pages;
  final ProtocolVipManagerApi cards;
  final ConnectionPhase Function() phase;
  final int Function() generation;
  final bool Function()? hasMemberEditModule;
  final int Function()? accessGeneration;
  final bool Function()? workspaceScope;
  final List<CardEmployee> Function()? employees;
  final Future<Result<String>> Function(
    ProtocolBinaryFile, {
    bool Function()? canSave,
  })
  saveExport;
  bool get _canConfigure =>
      (workspaceScope?.call() ?? true) &&
      session.currentMachine != null &&
      session.currentMachine!.client != ClientKind.vip;
  bool get _canManageMembers =>
      (workspaceScope?.call() ?? true) &&
      (_canConfigure || (hasMemberEditModule?.call() ?? false));

  VipPages get workspace {
    final user = session.currentUser, machine = session.currentMachine;
    final epoch = generation(), accessEpoch = accessGeneration?.call();
    return SessionBoundVipPagesLoader(
      session: session,
      pages: pages,
      cards: cards,
      phase: phase,
      generation: generation,
      hasMemberEditModule: hasMemberEditModule,
      accessGeneration: accessGeneration,
      saveExport: saveExport,
      employees: employees,
      workspaceScope: () =>
          (workspaceScope?.call() ?? true) &&
          identical(user, session.currentUser) &&
          identical(machine, session.currentMachine) &&
          epoch == generation() &&
          accessEpoch == accessGeneration?.call() &&
          phase() == ConnectionPhase.online,
    )._workspace;
  }

  VipPages get _workspace => VipPages(
    employees: () => (workspaceScope?.call() ?? true)
        ? employees?.call() ?? const []
        : const [],
    configurationAccess: () => _canConfigure,
    memberEditAccess: () => _canManageMembers,
    getPointRule: getPointRule,
    savePointRule: savePointRule,
    listDepositRules: listDepositRules,
    saveDepositRule: saveDepositRule,
    deleteDepositRule: deleteDepositRule,
    getCardNoRule: getCardNoRule,
    saveCardNoRule: saveCardNoRule,
    listQwMembers: listQwMembers,
    listCardTypes: listCardTypes,
    createCardType: createCardType,
    renameCardType: renameCardType,
    deleteCardType: deleteCardType,
    setDefaultCardType: setDefaultCardType,
    queryReport: queryReport,
    exportReport: exportReport,
    reprintBill: reprintBill,
    listLateDeposits: listLateDeposits,
    refundLateDeposit: refundLateDeposit,
    listBillRules: listBillRules,
    addBillRule: addBillRule,
    updateBillRule: updateBillRule,
    deleteBillRule: deleteBillRule,
    copyBillRule: copyBillRule,
    depositPoints: depositPoints,
    subtractPoints: subtractPoints,
    lockCard: lockCard,
    unlockCard: unlockCard,
    closeCard: closeCard,
    changeLevel: changeLevel,
    changeBindPhone: changeBindPhone,
    lossCard: lossCard,
    enableCard: enableCard,
    getCardTypeDetail: getCardTypeDetail,
    newLevel: newLevel,
    renameLevel: renameLevel,
    deleteLevel: deleteLevel,
    changeLevelExp: changeLevelExp,
    changeLevelCoupon: changeLevelCoupon,
    enableAutoUpgrade: enableAutoUpgrade,
    disableAutoUpgrade: disableAutoUpgrade,
    listCovers: listCovers,
    deleteCover: deleteCover,
    listTypePointRules: listTypePointRules,
    saveTypePointRule: saveTypePointRule,
    deleteTypePointRule: deleteTypePointRule,
    saveMemberCard: saveMemberCard,
    getLevelChange: getLevelChange,
    returnCard: returnCard,
    subtractMoney: subtractMoney,
    changePhysicalCard: changePhysicalCard,
    checkSms: checkSms,
    bindPhone: bindPhone,
    getOperCard: getOperCard,
    getForEdit: getForEdit,
    getForBindPhone: getForBindPhone,
    depositMoney: depositMoney,
    getCardSecret: getCardSecret,
    getCardIdFromReal: getCardIdFromReal,
    getMemberDetail: getMemberDetail,
    getMemberCards: getMemberCards,
    getBalanceLogs: getBalanceLogs,
    getMemberCoupons: getMemberCoupons,
    getMemberWines: getMemberWines,
    getTopProducts: getTopProducts,
    searchDepositCards: searchDepositCards,
    validPaySerial: validPaySerial,
    listPhonePayCards: listPhonePayCards,
    changeLevelPic: changeLevelPic,
    listLevelCoupons: listLevelCoupons,
    newCover: newCover,
  );

  Future<Result<VipPointRule>> getPointRule() =>
      _guard((client, pages, cards) => pages.getPointRule(client));

  Future<Result<void>> savePointRule({
    required int typeId,
    required int baseAmt,
  }) => _configuration(
    (client, pages, cards) =>
        pages.savePointRule(client, typeId: typeId, baseAmt: baseAmt),
  );

  Future<Result<List<VipDepositGiftRule>>> listDepositRules({
    String cardTypeId = '0',
  }) => _guard(
    (client, pages, cards) =>
        pages.listDepositRules(client, cardTypeId: cardTypeId),
  );

  Future<Result<void>> saveDepositRule({
    String id = '',
    required int depositFen,
    required int giftFen,
    String cardTypeId = '0',
    String cardLevelId = '0',
    int giftPoints = 0,
    String couponId = '0',
    String remark = '',
  }) => _configuration(
    (client, pages, cards) => pages.saveDepositRule(
      client,
      id: id,
      depositFen: depositFen,
      giftFen: giftFen,
      cardTypeId: cardTypeId,
      cardLevelId: cardLevelId,
      giftPoints: giftPoints,
      couponId: couponId,
      remark: remark,
    ),
  );

  Future<Result<void>> deleteDepositRule({
    required int depositFen,
    required int giftFen,
  }) => _configuration(
    (client, pages, cards) => pages.deleteDepositRule(
      client,
      depositFen: depositFen,
      giftFen: giftFen,
    ),
  );

  Future<Result<VipCardNoRule>> getCardNoRule() =>
      _guard((client, pages, cards) => pages.getCardNoRule(client));

  Future<Result<void>> saveCardNoRule({
    required int numLength,
    required String prefix,
  }) => _configuration(
    (client, pages, cards) =>
        pages.saveCardNoRule(client, numLength: numLength, prefix: prefix),
  );

  Future<Result<VipReportPage>> listQwMembers({
    required int pageNum,
    required int pageSize,
    String keyword = '',
  }) => _guard(
    (client, pages, cards) => pages.listQwMembers(
      client,
      pageNum: pageNum,
      pageSize: pageSize,
      keyword: keyword,
    ),
  );

  Future<Result<List<VipCardTypeRow>>> listCardTypes() =>
      _guard((client, pages, cards) => pages.listCardTypes(client));

  Future<Result<void>> createCardType({
    required String name,
    bool isDefault = false,
  }) => _configuration(
    (client, pages, cards) =>
        pages.createCardType(client, name: name, isDefault: isDefault),
  );

  Future<Result<void>> renameCardType({
    required String id,
    required String name,
  }) => _configuration(
    (client, pages, cards) => pages.renameCardType(client, id: id, name: name),
  );

  Future<Result<void>> deleteCardType(String id) => _configuration(
    (client, pages, cards) => pages.deleteCardType(client, id),
  );

  Future<Result<void>> setDefaultCardType(String id) => _configuration(
    (client, pages, cards) => pages.setDefaultCardType(client, id),
  );

  Future<Result<VipReportPage>> queryReport({
    required VipReportKind kind,
    int pageNum = 1,
    int pageSize = 20,
    String beginDay = '',
    String endDay = '',
    String keyword = '',
    int typeId = 0,
    String salesEmpId = '',
  }) => _guard(
    (client, pages, cards) => pages.queryReport(
      client,
      kind: kind,
      pageNum: pageNum,
      pageSize: pageSize,
      beginDay: beginDay,
      endDay: endDay,
      keyword: keyword,
      typeId: typeId,
      salesEmpId: salesEmpId,
    ),
  );

  Future<Result<void>> exportReport({
    required VipReportKind kind,
    int pageNum = 1,
    int pageSize = 20,
    String beginDay = '',
    String endDay = '',
    String keyword = '',
    int typeId = 0,
    String salesEmpId = '',
    bool Function()? canDispatch,
  }) => _guard((client, pages, cards) async {
    final result = await pages.exportReport(
      client,
      kind: kind,
      pageNum: pageNum,
      pageSize: pageSize,
      beginDay: beginDay,
      endDay: endDay,
      keyword: keyword,
      typeId: typeId,
      salesEmpId: salesEmpId,
    );
    if (result.failureOrNull case final failure?) return FailureResult(failure);
    if (!(pages.canDispatch?.call() ?? false))
      return const FailureResult(_changed);
    final saved = await saveExport(
      result.valueOrNull!,
      canSave: pages.canDispatch,
    );
    if (!(pages.canDispatch?.call() ?? false))
      return const FailureResult(_changed);
    if (saved.failureOrNull case final failure?) return FailureResult(failure);
    return const Success(null);
  }, allowed: canDispatch);

  Future<Result<void>> reprintBill(String logId) => _configuration(
    (client, pages, cards) => pages.reprintBill(client, logId: logId),
  );

  Future<Result<List<VipLateDeposit>>> listLateDeposits({
    String keyword = '',
  }) => _guard(
    (client, pages, cards) => pages.listLateDeposits(client, keyword: keyword),
  );

  Future<Result<void>> refundLateDeposit(String id) =>
      _guard((client, pages, cards) => pages.refundLateDeposit(client, id: id));

  Future<Result<VipReportPage>> listBillRules({
    required String cardTypeId,
    String cardLevelId = '0',
    bool init = false,
    String keyword = '',
    int typeId = 0,
  }) => _guard(
    (client, pages, cards) => pages.listBillRules(
      client,
      cardTypeId: cardTypeId,
      cardLevelId: cardLevelId,
      init: init,
      keyword: keyword,
      typeId: typeId,
    ),
  );

  Future<Result<void>> addBillRule({
    required String cardTypeId,
    required String cardLevelId,
    required int typeId,
    required List<String> productIds,
  }) => _configuration(
    (client, pages, cards) => pages.addBillRule(
      client,
      cardTypeId: cardTypeId,
      cardLevelId: cardLevelId,
      typeId: typeId,
      productIds: productIds,
    ),
  );

  Future<Result<void>> updateBillRule({
    required String cardTypeId,
    required int typeId,
    required List<String> ids,
  }) => _configuration(
    (client, pages, cards) => pages.updateBillRule(
      client,
      cardTypeId: cardTypeId,
      typeId: typeId,
      ids: ids,
    ),
  );

  Future<Result<void>> deleteBillRule({
    required String cardTypeId,
    required List<String> ids,
  }) => _configuration(
    (client, pages, cards) =>
        pages.deleteBillRule(client, cardTypeId: cardTypeId, ids: ids),
  );

  Future<Result<void>> copyBillRule({
    required String srcTypeId,
    required String destTypeId,
    required String srcLevelId,
    required String destLevelId,
  }) => _configuration(
    (client, pages, cards) => pages.copyBillRule(
      client,
      srcTypeId: srcTypeId,
      destTypeId: destTypeId,
      srcLevelId: srcLevelId,
      destLevelId: destLevelId,
    ),
  );

  Future<Result<void>> depositPoints({
    required String cardId,
    required int points,
    String remark = '',
  }) => _configuration((client, pages, cards) {
    final empId = session.currentUser?.employeeId ?? '';
    return cards.depositPoints(
      client,
      cardId: cardId,
      operatorEmpId: empId,
      points: points,
      remark: remark,
    );
  });

  Future<Result<void>> subtractPoints({
    required String cardId,
    required int points,
    String remark = '',
  }) => _configuration((client, pages, cards) {
    final empId = session.currentUser?.employeeId ?? '';
    return cards.subtractPoints(
      client,
      cardId: cardId,
      operatorEmpId: empId,
      points: points,
      remark: remark,
    );
  });

  Future<Result<void>> lockCard(String cardId) =>
      _guard((client, pages, cards) => cards.lockCard(client, cardId: cardId));

  Future<Result<void>> unlockCard(String cardId) => _guard(
    (client, pages, cards) => cards.unlockCard(client, cardId: cardId),
  );

  Future<Result<void>> closeCard({
    required String cardId,
    String storedBalance = '',
    String giftBalance = '',
    int points = 0,
  }) => _memberEdit(
    (client, pages, cards) => cards.closeCard(
      client,
      cardId: cardId,
      storedBalance: storedBalance,
      giftBalance: giftBalance,
      points: points,
    ),
  );

  Future<Result<void>> changeLevel({
    required String cardId,
    required String levelId,
  }) => _memberEdit(
    (client, pages, cards) =>
        cards.updownLevel(client, cardId: cardId, destLevelId: levelId),
  );

  Future<Result<VipCardTypeDetail>> getCardTypeDetail(String id) =>
      _guard((client, pages, cards) => pages.getCardTypeDetail(client, id: id));

  Future<Result<String>> newLevel({
    required String typeId,
    required String name,
    String picName = '',
    int expThreshold = 0,
    String couponId = '0',
  }) => _configuration(
    (client, pages, cards) => pages.newLevel(
      client,
      typeId: typeId,
      name: name,
      picName: picName,
      expThreshold: expThreshold,
      couponId: couponId,
    ),
  );

  Future<Result<void>> renameLevel({
    required String id,
    required String name,
  }) => _configuration(
    (client, pages, cards) => pages.renameLevel(client, id: id, name: name),
  );

  Future<Result<void>> deleteLevel(String id) => _configuration(
    (client, pages, cards) => pages.deleteLevel(client, id: id),
  );

  Future<Result<void>> changeLevelExp({
    required String id,
    required int expThreshold,
  }) => _configuration(
    (client, pages, cards) =>
        pages.changeLevelExp(client, id: id, expThreshold: expThreshold),
  );

  Future<Result<void>> changeLevelCoupon({
    required String id,
    required String couponId,
  }) => _configuration(
    (client, pages, cards) =>
        pages.changeLevelCoupon(client, id: id, couponId: couponId),
  );

  Future<Result<void>> enableAutoUpgrade({
    required String typeId,
    required List<String> levelIds,
    required List<int> expThresholds,
  }) => _configuration(
    (client, pages, cards) => pages.enableAutoUpgrade(
      client,
      typeId: typeId,
      levelIds: levelIds,
      expThresholds: expThresholds,
    ),
  );

  Future<Result<void>> disableAutoUpgrade(String typeId) => _configuration(
    (client, pages, cards) => pages.disableAutoUpgrade(client, typeId: typeId),
  );

  Future<Result<List<VipCover>>> listCovers() =>
      _guard((client, pages, cards) => pages.listCovers(client));

  Future<Result<void>> deleteCover(String id) => _configuration(
    (client, pages, cards) => pages.deleteCover(client, id: id),
  );

  Future<Result<List<VipTypePointRule>>> listTypePointRules(
    String cardTypeId,
  ) => _guard(
    (client, pages, cards) =>
        pages.listTypePointRules(client, cardTypeId: cardTypeId),
  );

  Future<Result<void>> saveTypePointRule({
    String id = '',
    required String cardTypeId,
    required String cardLevelId,
    required int baseAmtFen,
  }) => _configuration(
    (client, pages, cards) => pages.saveTypePointRule(
      client,
      id: id,
      cardTypeId: cardTypeId,
      cardLevelId: cardLevelId,
      baseAmtFen: baseAmtFen,
    ),
  );

  Future<Result<void>> deleteTypePointRule({
    required String id,
    required String cardTypeId,
  }) => _configuration(
    (client, pages, cards) =>
        pages.deleteTypePointRule(client, id: id, cardTypeId: cardTypeId),
  );

  Future<Result<void>> saveMemberCard({
    required String cardId,
    required String name,
    String contactPhone = '',
    int sex = 1,
    String birthday = '',
    String mark = '',
    int expiredType = 0,
    String salesEmpId = '0',
    List<int> smsTypeIds = const [],
  }) => _memberEdit(
    (client, pages, cards) => cards.saveCard(
      client,
      cardId: cardId,
      name: name,
      contactPhone: contactPhone,
      sex: sex,
      birthday: birthday,
      mark: mark,
      expiredType: expiredType,
      salesEmpId: salesEmpId,
      smsTypeIds: smsTypeIds,
    ),
  );

  Future<Result<VipLevelChangeInfo>> getLevelChange(String cardId) => _guard(
    (client, pages, cards) => cards.getForLevelChange(client, cardId: cardId),
  );

  Future<Result<void>> returnCard({
    required String cardId,
    required String remark,
  }) => _memberEdit(
    (client, pages, cards) =>
        cards.returnCard(client, cardId: cardId, remark: remark),
  );

  Future<Result<void>> subtractMoney({
    required String cardId,
    required String storedAmt,
    String giftAmt = '0',
    int points = 0,
    int typeId = 1,
  }) => _configuration((client, pages, cards) {
    final empId = session.currentUser?.employeeId ?? '';
    return cards.subtractMoney(
      client,
      cardId: cardId,
      storedAmt: storedAmt,
      giftAmt: giftAmt,
      points: points,
      operatorEmpId: empId,
      typeId: typeId,
    );
  });

  Future<Result<void>> changePhysicalCard({
    required String cardNo,
    required String memberCardId,
  }) async {
    final begin = await _memberEdit(
      (client, pages, cards) => cards.changeCardBegin(
        client,
        cardNo: cardNo,
        memberCardId: memberCardId,
      ),
    );
    if (begin.failureOrNull != null) {
      return FailureResult(begin.failureOrNull!);
    }
    return _memberEdit(
      (client, pages, cards) => cards.changeCardEnd(
        client,
        cardNo: cardNo,
        memberCardId: memberCardId,
      ),
    );
  }

  Future<Result<String>> checkSms({
    required String phone,
    required String code,
  }) => _guard(
    (client, pages, cards) => cards.checkSms(client, phone: phone, code: code),
  );

  Future<Result<void>> bindPhone({
    required String cardId,
    required String phone,
    String authCode = '',
    List<int> smsTypeIds = const [],
  }) => _memberEdit(
    (client, pages, cards) => cards.bindPhone(
      client,
      cardId: cardId,
      phone: phone,
      authCode: authCode,
      smsTypeIds: smsTypeIds,
    ),
  );

  Future<Result<void>> changeBindPhone({
    required String cardId,
    required String phone,
    String authCode = '',
  }) => _memberEdit(
    (client, pages, cards) => cards.changeBindPhone(
      client,
      cardId: cardId,
      phone: phone,
      authCode: authCode,
    ),
  );

  Future<Result<void>> lossCard(String cardId) => _memberEdit(
    (client, pages, cards) => cards.lossCard(client, cardId: cardId),
  );

  Future<Result<void>> enableCard(String cardId) => _memberEdit(
    (client, pages, cards) => cards.enableCard(client, cardId: cardId),
  );

  Future<Result<VipOperCard>> getOperCard(String cardId) => _guard(
    (client, pages, cards) => cards.getOperCard(client, cardId: cardId),
  );

  Future<Result<VipEditCard>> getForEdit(String cardId) => _guard(
    (client, pages, cards) => cards.getForEdit(client, cardId: cardId),
  );

  Future<Result<VipBindPhonePrep>> getForBindPhone(String cardId) => _guard(
    (client, pages, cards) => cards.getForBindPhone(client, cardId: cardId),
  );

  Future<Result<void>> depositMoney({
    required String cardId,
    required String storedAmt,
    String giftAmt = '0',
    int points = 0,
    int mode = 1,
    int channelId = 0,
    String salesEmpId = '0',
    String remark = '',
  }) => _configuration((client, pages, cards) {
    final empId = session.currentUser?.employeeId ?? '';
    return cards.depositMoney(
      client,
      cardId: cardId,
      storedAmt: storedAmt,
      giftAmt: giftAmt,
      points: points,
      mode: mode,
      operatorEmpId: empId,
      channelId: channelId,
      salesEmpId: salesEmpId,
      remark: remark,
    );
  });

  Future<Result<String>> getCardSecret(String cardNo) => _guard(
    (client, pages, cards) => cards.getCardSecret(client, cardNo: cardNo),
  );

  Future<Result<String>> getCardIdFromReal({
    required String cardNo,
    required String digest,
  }) => _guard(
    (client, pages, cards) =>
        cards.getCardIdFromReal(client, cardNo: cardNo, digest: digest),
  );

  Future<Result<Map<String, String>>> getMemberDetail({
    String cardId = '',
    String phone = '',
  }) => _guard(
    (client, pages, cards) =>
        cards.getMemberDetail(client, cardId: cardId, phone: phone),
  );

  Future<Result<VipMapPage>> getMemberCards({
    String cardId = '',
    String phone = '',
    int pageNum = 1,
    int pageSize = 20,
    int status = 0,
  }) => _guard(
    (client, pages, cards) =>
        cards.getMemberCards(client, cardId: cardId, phone: phone),
  );

  Future<Result<VipMapPage>> getBalanceLogs({
    String cardId = '',
    String phone = '',
    int pageNum = 1,
    int pageSize = 20,
    int status = 0,
  }) => _guard(
    (client, pages, cards) => cards.getBalanceLogs(
      client,
      cardId: cardId,
      phone: phone,
      pageNum: pageNum,
      pageSize: pageSize,
    ),
  );

  Future<Result<VipMapPage>> getMemberCoupons({
    String cardId = '',
    String phone = '',
    int pageNum = 1,
    int pageSize = 20,
    int status = 0,
  }) => _guard(
    (client, pages, cards) => cards.getMemberCoupons(
      client,
      phone: phone,
      pageNum: pageNum,
      pageSize: pageSize,
      status: status,
    ),
  );

  Future<Result<VipMapPage>> getMemberWines({
    String cardId = '',
    String phone = '',
    int pageNum = 1,
    int pageSize = 20,
    int status = 0,
  }) => _guard(
    (client, pages, cards) => cards.getMemberWines(client, phone: phone),
  );

  Future<Result<VipMapPage>> getTopProducts({
    String cardId = '',
    String phone = '',
    int pageNum = 1,
    int pageSize = 20,
    int status = 0,
  }) => _guard(
    (client, pages, cards) =>
        cards.getTopProducts(client, cardId: cardId, phone: phone),
  );

  Future<Result<VipMapPage>> searchDepositCards(String phone) => _guard(
    (client, pages, cards) => cards.searchDepositCards(client, phone: phone),
  );

  Future<Result<VipPaySerial>> validPaySerial(String code) => _guard(
    (client, pages, cards) => cards.validPaySerial(client, code: code),
  );

  Future<Result<VipMapPage>> listPhonePayCards({
    required String phone,
    required String authCode,
  }) => _guard(
    (client, pages, cards) =>
        cards.listPhonePayCards(client, phone: phone, authCode: authCode),
  );

  Future<Result<void>> changeLevelPic({
    required String id,
    required String picName,
  }) => _configuration(
    (client, pages, cards) =>
        pages.changeLevelPic(client, id: id, picName: picName),
  );

  Future<Result<VipReportPage>> listLevelCoupons({
    int typeId = 0,
    String keyword = '',
  }) => _guard(
    (client, pages, cards) =>
        pages.listLevelCoupons(client, typeId: typeId, keyword: keyword),
  );

  Future<Result<void>> newCover(String picName) => _configuration(
    (client, pages, cards) => pages.newCover(client, picName: picName),
  );

  Future<Result<T>> _configuration<T>(
    Future<Result<T>> Function(
      ClientKind,
      ProtocolVipPagesApi,
      ProtocolVipManagerApi,
    )
    run,
  ) => _guard(run, allowed: () => _canConfigure);
  Future<Result<T>> _memberEdit<T>(
    Future<Result<T>> Function(
      ClientKind,
      ProtocolVipPagesApi,
      ProtocolVipManagerApi,
    )
    run,
  ) => _guard(run, allowed: () => _canManageMembers);

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(
      ClientKind client,
      ProtocolVipPagesApi pages,
      ProtocolVipManagerApi cards,
    )
    run, {
    bool Function()? allowed,
  }) async {
    try {
      final user = session.currentUser;
      final machine = session.currentMachine;
      if (user == null || machine == null) {
        return const FailureResult(_sessionRequired);
      }
      final epoch = generation();
      final accessEpoch = accessGeneration?.call();
      if (!(workspaceScope?.call() ?? true)) {
        return const FailureResult(_changed);
      }
      if (allowed != null && !allowed()) {
        return const FailureResult(_permissionDenied);
      }
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_unavailable);
      }
      bool current() =>
          (workspaceScope?.call() ?? true) &&
          identical(user, session.currentUser) &&
          identical(machine, session.currentMachine) &&
          generation() == epoch &&
          accessGeneration?.call() == accessEpoch &&
          phase() == ConnectionPhase.online &&
          (allowed?.call() ?? true);
      final result = await run(
        machine.client,
        ProtocolVipPagesApi(
          client: pages.client,
          canDispatch: () => current() && (pages.canDispatch?.call() ?? true),
        ),
        ProtocolVipManagerApi(
          client: cards.client,
          canDispatch: () => current() && (cards.canDispatch?.call() ?? true),
        ),
      );
      if (!current()) return const FailureResult(_changed);
      if (!identical(user, session.currentUser) ||
          !identical(machine, session.currentMachine) ||
          generation() != epoch) {
        return const FailureResult(_changed);
      }
      if (phase() != ConnectionPhase.online) {
        return const FailureResult(_unavailable);
      }
      return result;
    } on Object {
      return const FailureResult(_failed);
    }
  }

  static const AppFailure _sessionRequired = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.vip_pages_session_required',
    safeMessage: '请登录后再打开会员系统',
  );
  static const AppFailure _permissionDenied = AppFailure(
    kind: FailureKind.authentication,
    code: 'vip.permission_denied',
    safeMessage: '当前会员系统无此操作权限',
  );
  static const AppFailure _unavailable = AppFailure(
    kind: FailureKind.network,
    code: 'network.vip_pages_unavailable',
    safeMessage: '连接未就绪，暂时无法打开会员系统',
  );
  static const AppFailure _changed = AppFailure(
    kind: FailureKind.authentication,
    code: 'authentication.vip_pages_context_changed',
    safeMessage: '登录或连接状态已变化，请重新打开',
  );
  static const AppFailure _failed = AppFailure(
    kind: FailureKind.unknown,
    code: 'vip_pages.load_failed',
    safeMessage: '会员操作失败，请重试',
  );
}
