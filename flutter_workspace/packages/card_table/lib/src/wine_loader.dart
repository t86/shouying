import 'package:card_table/src/wine_api.dart';
import 'package:card_table/src/wine_models.dart';
import 'package:card_table/src/wine_pending_get.dart';
import 'package:card_table/src/wine_save_edit.dart';
import 'package:card_table/src/wine_export_saver.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

String wineExportSuccessMessage(WineLoader loader) {
  final location = loader is SessionBoundWineLoader ? loader.lastExportLocation : null;
  return location == null ? '导出完成' : '导出完成：$location';
}

abstract interface class WineLoader {
  Future<Result<List<Map<String, Object?>>>> loadWineBorrowEmployees(String query);
  Future<Result<List<Map<String, Object?>>>> loadWineReturnOptions({String keyword = ''});
  // S5.P1 待入库
  Future<Result<List<WineSaveRecord>>> loadSaveNeedToLib({String keyword = ''});
  Future<Result<void>> confirmSaveNeedToLib(List<String> ids);
  Future<Result<void>> backSaveNeedToLib(List<String> ids, {String reason = ''});
  Future<Result<void>> chgSaveNeedToLib(Map<String, Object?> fields);
  Future<Result<List<Map<String, Object?>>>> loadChgSalesEmpList();

  // S5.P2 待出库
  Future<Result<List<WineGetRecord>>> loadNeedToLib({String keyword = ''});
  Future<Result<void>> confirmGetNeedToLib(List<String> ids);
  Future<Result<void>> backGetNeedToLib(List<String> ids, {String reason = ''});
  Future<Result<void>> confirmAuthGetNeedToLib(Map<String, Object?> fields);

  // S5.P3 & S5.P4 存酒库
  Future<Result<List<WineInventoryItem>>> loadSaveLibList({
    String startDate = '',
    String endDate = '',
    int daysLeft = 0,
    String keyword = '',
  });
  Future<Result<void>> delayWineInvt({
    required String id,
    required int days,
    String reason = '',
  });
  Future<Result<void>> cgWineInvt(List<String> ids);
  Future<Result<List<WineInventoryItem>>> loadSaveLibChildList({
    String startDate = '',
    String endDate = '',
    String keyword = '',
  });

  // S5.P5 & S5.P6 过期与库存
  Future<Result<List<WineInventoryItem>>> loadPassTimeNeedToLib({String keyword = ''});
  Future<Result<void>> cgExpiredWineInvt(List<String> ids);
  Future<Result<void>> delayExpiredWineInvt({
    required String id,
    required int days,
    String reason = '',
  });
  Future<Result<List<WineGridItem>>> loadSaveLibGrid({String keyword = ''});
  Future<Result<List<WineInventoryItem>>> loadSaveLibGridDetail(String prdId);
  Future<Result<void>> exportWineInvtExpired({String keyword = '', int ordType = 1});
  Future<Result<void>> exportExcelOfGridReport({String keyword = ''});
  Future<Result<void>> exportUnreturnedWineList({String keyword = ''});
  Future<Result<void>> exportWineDetailList({String startTime = '', String endTime = '', String keyword = '', int daysLeft = 0});

  // S5.P7 充公
  Future<Result<List<WineConfiscateItem>>> loadNeedToStoreList({String keyword = ''});
  Future<Result<void>> backToStoreList(List<String> ids);
  Future<Result<void>> confirmToStoreList(List<String> ids);
  Future<Result<void>> confirmAuthToStoreList(Map<String, Object?> fields);
  Future<Result<void>> chgCsmCgBefIn(Map<String, Object?> fields);
  Future<Result<List<WineConfiscateItem>>> loadStoreLibList({String keyword = ''});
  Future<Result<void>> newCgOut(Map<String, Object?> fields);
  Future<Result<List<WineConfiscateItem>>> loadToStoreDetailList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
    String startDate = '',
    String endDate = '',
  });
  Future<Result<Map<String, Object?>>> loadToStoreOrderDetail(String orderId);
  Future<Result<void>> toStoreToHc(String orderId);

  // S5.P8 用户管理
  Future<Result<List<WineCustomerItem>>> loadCustomList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
  });
  Future<Result<void>> openOrCloseMsg({
    required List<String> custIds,
    required bool enable,
  });
  Future<Result<void>> updateCustomName({
    required String custId,
    required String name,
  });
  Future<Result<bool>> validatePhoneNum(String phone);
  Future<Result<void>> updateCustomPhoneNum({
    required String custId,
    required String phone,
  });
  Future<Result<List<WineBlacklistItem>>> loadBlackList({String keyword = ''});
  Future<Result<void>> addBlackList({
    required List<String> phones,
    String remark = '',
  });
  Future<Result<void>> deleteBlackList(List<String> ids);

  // S5.P9 客户中心
  Future<Result<List<WineSaveRecord>>> loadCustomCenterSaveWineList({String keyword = ''});
  Future<Result<List<WineInventoryItem>>> loadCustomCenterGetWineList({
    String phone = '',
    String seatId = '',
  });
  Future<Result<List<Map<String, Object?>>>> loadCustomCenterSeatList();
  Future<Result<void>> submitCustomCenterGetWine(Map<String, Object?> fields);

  // S5.P10 报表
  Future<Result<List<WineReportRow>>> loadReportData({
    required String path,
    Map<String, Object?> params = const {},
  });
  Future<Result<void>> printSaveAndGetWineList(String id);

  // S5.P11 借还
  Future<Result<List<WineBorrowReturnItem>>> loadWineBorrowReturnList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
    int type = 0,
  });
  Future<Result<List<Map<String, Object?>>>> loadWineCanBorrowList({String keyword = ''});
  Future<Result<void>> submitWineBorrow(Map<String, Object?> fields);
  Future<Result<void>> submitWineReturn(Map<String, Object?> fields);
  Future<Result<List<WineBorrowReturnItem>>> loadWineBorrowInvtList({String keyword = ''});
}

abstract interface class WineBorrowFormContext {
  Object? get borrowFormContext;
}

abstract interface class WineBorrowPageLoader {
  Future<Result<WineBorrowReturnPage>> loadWineBorrowReturnPage({
    required int type, required int page, int pageSize = 20,
    required String beginDay, required String endDay, String keyword = '',
  });
}

final class _WineFormSessionKey {
  const _WineFormSessionKey(this.user, this.machine, this.generation);
  final Object? user, machine;
  final int? generation;
  @override
  bool operator ==(Object other) => other is _WineFormSessionKey &&
      identical(user, other.user) && identical(machine, other.machine) &&
      generation == other.generation;
  @override
  int get hashCode => Object.hash(identityHashCode(user), identityHashCode(machine), generation);
}

final class SessionBoundWineLoader implements WineLoader, WinePendingGetLoader, WineBorrowFormContext, WineBorrowPageLoader, WineSaveEditLoader {
  SessionBoundWineLoader({
    required this.session,
    required this.api,
    this.clientKind = ClientKind.wine,
    this.saveExport = saveWineExport,
    this.isOnline,
    this.generation,
    this.saveEditMetadata,
  });

  final SessionRepository session;
  final ProtocolWineApi api;
  final ClientKind clientKind;
  final Future<Result<String>> Function(ProtocolBinaryFile, {bool Function()? canSave}) saveExport;
  final bool Function()? isOnline;
  final int Function()? generation;
  final WineSaveEditMetadataSnapshot Function()? saveEditMetadata;
  @override
  Object? get saveEditSession => borrowFormContext;
  @override
  WineSaveEditMetadataSnapshot get saveEditSnapshot => saveEditMetadata?.call() ?? const WineSaveEditMetadataSnapshot();
  @override
  Future<Result<WineSaveEditContext>> loadSaveEditContext() => _saveEditRequest(()=>api.getSaveEditContext(clientKind));
  @override
  Future<Result<List<Map<String,Object?>>>> loadSaveEditSeats({String? day}) => _saveEditRequest(()=>api.getSaveEditSeats(clientKind,day:day));
  @override
  Future<Result<List<Map<String,Object?>>>> loadSaveEditOrders(String day,int seatId) => _saveEditRequest(()=>api.getSaveEditOrders(clientKind,day,seatId));
  Future<Result<T>> _saveEditRequest<T>(Future<Result<T>> Function() request) async {
    if(_checkSession() case final f?) return FailureResult(f);
    final before=saveEditSession;
    try {
      final result=await request();
      if(before!=saveEditSession) return const FailureResult(AppFailure(kind:FailureKind.authentication,code:'wine.session_changed',safeMessage:'登录或连接已变化，请重新打开改单'));
      return result;
    } on Object { return const FailureResult(AppFailure(kind:FailureKind.network,code:'wine.save_edit_failed',safeMessage:'存酒改单请求失败，请重试')); }
  }
  String? lastExportLocation;

  @override
  Object? get borrowFormContext => _checkSession() != null ? null : _WineFormSessionKey(session.currentUser, session.currentMachine, generation?.call());

  Future<Result<T>> _borrowRequest<T>(Future<Result<T>> Function() request) async {
    if (_checkSession() case final failure?) return FailureResult(failure);
    final before = borrowFormContext;
    try {
      final result = await request();
      if (before != borrowFormContext) return const FailureResult(AppFailure(kind: FailureKind.authentication, code: 'wine.session_changed', safeMessage: '登录或连接状态已改变，请重新打开表单'));
      return result;
    } on Object {
      return const FailureResult(AppFailure(kind: FailureKind.network, code: 'wine.borrow_request_failed', safeMessage: '借还酒请求失败，请重试'));
    }
  }

  @override
  Future<Result<List<Map<String, Object?>>>> loadWineBorrowEmployees(String query) => _borrowRequest(() => api.getWineBorrowEmployees(clientKind, query));
  @override
  Future<Result<List<Map<String, Object?>>>> loadWineReturnOptions({String keyword = ''}) => _borrowRequest(() => api.getWineReturnOptions(clientKind, keyword: keyword));

  Future<Result<void>> _export(Future<Result<ProtocolBinaryFile>> Function(bool Function()) request) async {
    lastExportLocation = null;
    if (_checkSession() case final failure?) return FailureResult(failure);
    if (isOnline?.call() == false) return const FailureResult(AppFailure(kind: FailureKind.network, code: 'wine.offline', safeMessage: '网络未连接，无法导出'));
    final user = session.currentUser;
    final machine = session.currentMachine;
    final epoch = generation?.call();
    bool isCurrent() => !session.isClosed && isOnline?.call() != false && identical(user, session.currentUser) && identical(machine, session.currentMachine) && epoch == generation?.call();
    const staleFailure = AppFailure(kind: FailureKind.authentication, code: 'wine.session_changed', safeMessage: '登录或连接状态已改变，请重新导出');
    try {
      final result = await request(isCurrent);
      if (!isCurrent()) {
        return const FailureResult(staleFailure);
      }
      if (result.failureOrNull case final failure?) return FailureResult(failure);
      final saved = await saveExport(result.valueOrNull!, canSave: isCurrent);
      if (!isCurrent()) return const FailureResult(staleFailure);
      if (saved.failureOrNull case final failure?) return FailureResult(failure);
      lastExportLocation = saved.valueOrNull;
      return const Success(null);
    } on Object {
      return const FailureResult(AppFailure(kind: FailureKind.unknown, code: 'wine.export_failed', safeMessage: '导出或保存失败，请重试'));
    }
  }

  AppFailure? _checkSession() {
    final user = session.currentUser;
    final machine = session.currentMachine;
    if (session.isClosed || user == null || machine == null || machine.client != clientKind) {
      return const AppFailure(
        kind: FailureKind.authentication,
        code: 'wine.session_required',
        safeMessage: '请登录后再操作存酒系统',
      );
    }
    if (isOnline?.call() == false) {
      return const AppFailure(
        kind: FailureKind.network,
        code: 'wine.offline',
        safeMessage: '网络未连接，请恢复连接后再操作',
      );
    }
    return null;
  }

  @override
  Future<Result<List<WineSaveRecord>>> loadSaveNeedToLib({String keyword = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getSaveNeedToLib(clientKind, keyword: keyword);
  }

  @override
  Future<Result<void>> confirmSaveNeedToLib(List<String> ids) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.confirmSaveNeedToLib(clientKind, ids: ids);
  }

  @override
  Future<Result<void>> backSaveNeedToLib(List<String> ids, {String reason = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.backSaveNeedToLib(clientKind, ids: ids, reason: reason);
  }

  @override
  Future<Result<void>> chgSaveNeedToLib(Map<String, Object?> fields) async {
    return _saveEditRequest(() => api.chgSaveNeedToLib(clientKind, fields: fields));
  }

  @override
  Future<Result<List<Map<String, Object?>>>> loadChgSalesEmpList() async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getChgSalesEmpList(clientKind);
  }

  @override
  Future<Result<List<WineGetRecord>>> loadNeedToLib({String keyword = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getNeedToLib(clientKind, keyword: keyword);
  }

  @override
  Future<Result<WinePendingGetContext>> loadPendingGetContext({String keyword = ''}) async {
    return _borrowRequest(() => api.getPendingGetContext(clientKind, keyword: keyword));
  }

  @override
  Future<Result<List<WineGetSubItem>>> loadPendingGetInventory(String phone) async {
    return _borrowRequest(() => api.getPendingGetInventory(clientKind, phone: phone));
  }

  @override
  Future<Result<void>> confirmGetNeedToLib(List<String> ids) async {
    return _borrowRequest(() => api.confirmGetNeedToLib(clientKind, ids: List.unmodifiable(ids)));
  }

  @override
  Future<Result<void>> backGetNeedToLib(List<String> ids, {String reason = ''}) async {
    return _borrowRequest(() => api.backGetNeedToLib(clientKind, ids: List.unmodifiable(ids), reason: reason));
  }

  @override
  Future<Result<void>> confirmAuthGetNeedToLib(Map<String, Object?> fields) async {
    return _borrowRequest(() => api.confirmAuthGetNeedToLib(clientKind, fields: fields));
  }

  @override
  Future<Result<List<WineInventoryItem>>> loadSaveLibList({
    String startDate = '',
    String endDate = '',
    int daysLeft = 0,
    String keyword = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getSaveLibList(
      clientKind,
      startDate: startDate,
      endDate: endDate,
      daysLeft: daysLeft,
      keyword: keyword,
    );
  }

  @override
  Future<Result<void>> delayWineInvt({
    required String id,
    required int days,
    String reason = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.delayWineInvt(clientKind, id: id, days: days, reason: reason);
  }

  @override
  Future<Result<void>> cgWineInvt(List<String> ids) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.cgWineInvt(clientKind, ids: ids);
  }

  @override
  Future<Result<List<WineInventoryItem>>> loadSaveLibChildList({
    String startDate = '',
    String endDate = '',
    String keyword = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getSaveLibChildList(
      clientKind,
      startDate: startDate,
      endDate: endDate,
      keyword: keyword,
    );
  }

  @override
  Future<Result<List<WineInventoryItem>>> loadPassTimeNeedToLib({String keyword = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getPassTimeNeedToLib(clientKind, keyword: keyword);
  }

  @override
  Future<Result<void>> cgExpiredWineInvt(List<String> ids) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.cgExpiredWineInvt(clientKind, ids: ids);
  }

  @override
  Future<Result<void>> delayExpiredWineInvt({
    required String id,
    required int days,
    String reason = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.delayExpiredWineInvt(clientKind, id: id, days: days, reason: reason);
  }

  @override
  Future<Result<List<WineGridItem>>> loadSaveLibGrid({String keyword = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getSaveLibGrid(clientKind, keyword: keyword);
  }

  @override
  Future<Result<List<WineInventoryItem>>> loadSaveLibGridDetail(String prdId) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getSaveLibGridDetail(clientKind, prdId: prdId);
  }

  @override
  Future<Result<void>> exportWineInvtExpired({String keyword = '', int ordType = 1}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return _export((guard) => api.exportWineInvtExpired(clientKind, keyword: keyword, ordType: ordType, canDispatch: guard));
  }

  @override
  Future<Result<void>> exportExcelOfGridReport({String keyword = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return _export((guard) => api.exportExcelOfGridReport(clientKind, keyword: keyword, canDispatch: guard));
  }

  @override
  Future<Result<void>> exportUnreturnedWineList({String keyword = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return _export((guard) => api.exportWineBorrowInvtList(clientKind, canDispatch: guard));
  }

  @override
  Future<Result<void>> exportWineDetailList({String startTime = '', String endTime = '', String keyword = '', int daysLeft = 0}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return _export((guard) => api.exportWineDetailList(clientKind, startTime: startTime, endTime: endTime, keyword: keyword, daysLeft: daysLeft, canDispatch: guard));
  }

  @override
  Future<Result<List<WineConfiscateItem>>> loadNeedToStoreList({String keyword = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getNeedToStoreList(clientKind, keyword: keyword);
  }

  @override
  Future<Result<void>> backToStoreList(List<String> ids) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.backToStoreList(clientKind, ids: ids);
  }

  @override
  Future<Result<void>> confirmToStoreList(List<String> ids) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.confirmToStoreList(clientKind, ids: ids);
  }

  @override
  Future<Result<void>> confirmAuthToStoreList(Map<String, Object?> fields) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.confirmAuthToStoreList(clientKind, fields: fields);
  }

  @override
  Future<Result<void>> chgCsmCgBefIn(Map<String, Object?> fields) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.chgCsmCgBefIn(clientKind, fields: fields);
  }

  @override
  Future<Result<List<WineConfiscateItem>>> loadStoreLibList({String keyword = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getStoreLibList(clientKind, keyword: keyword);
  }

  @override
  Future<Result<void>> newCgOut(Map<String, Object?> fields) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.newCgOut(clientKind, fields: fields);
  }

  @override
  Future<Result<List<WineConfiscateItem>>> loadToStoreDetailList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
    String startDate = '',
    String endDate = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getToStoreDetailList(
      clientKind,
      page: page,
      pageSize: pageSize,
      keyword: keyword,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<Result<Map<String, Object?>>> loadToStoreOrderDetail(String orderId) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getToStoreOrderDetail(clientKind, orderId: orderId);
  }

  @override
  Future<Result<void>> toStoreToHc(String orderId) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.toStoreToHc(clientKind, orderId: orderId);
  }

  @override
  Future<Result<List<WineCustomerItem>>> loadCustomList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getCustomList(
      clientKind,
      page: page,
      pageSize: pageSize,
      keyword: keyword,
    );
  }

  @override
  Future<Result<void>> openOrCloseMsg({
    required List<String> custIds,
    required bool enable,
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.openOrCloseMsg(clientKind, custIds: custIds, enable: enable);
  }

  @override
  Future<Result<void>> updateCustomName({
    required String custId,
    required String name,
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.updateCustomName(clientKind, custId: custId, name: name);
  }

  @override
  Future<Result<bool>> validatePhoneNum(String phone) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.validatePhoneNum(clientKind, phone: phone);
  }

  @override
  Future<Result<void>> updateCustomPhoneNum({
    required String custId,
    required String phone,
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.updateCustomPhoneNum(clientKind, custId: custId, phone: phone);
  }

  @override
  Future<Result<List<WineBlacklistItem>>> loadBlackList({String keyword = ''}) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getBlackList(clientKind, keyword: keyword);
  }

  @override
  Future<Result<void>> addBlackList({
    required List<String> phones,
    String remark = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.addBlackList(clientKind, phones: phones, remark: remark);
  }

  @override
  Future<Result<void>> deleteBlackList(List<String> ids) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.deleteBlackList(clientKind, ids: ids);
  }

  @override
  Future<Result<List<WineSaveRecord>>> loadCustomCenterSaveWineList({
    String keyword = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getCustomCenterSaveWineList(clientKind, keyword: keyword);
  }

  @override
  Future<Result<List<WineInventoryItem>>> loadCustomCenterGetWineList({
    String phone = '',
    String seatId = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getCustomCenterGetWineList(
      clientKind,
      phone: phone,
      seatId: seatId,
    );
  }

  @override
  Future<Result<List<Map<String, Object?>>>> loadCustomCenterSeatList() async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getCustomCenterSeatList(clientKind);
  }

  @override
  Future<Result<void>> submitCustomCenterGetWine(Map<String, Object?> fields) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getCustomCenterGetWineSubmit(clientKind, fields: fields);
  }

  @override
  Future<Result<List<WineReportRow>>> loadReportData({
    required String path,
    Map<String, Object?> params = const {},
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getReportData(clientKind, path: path, params: params);
  }

  @override
  Future<Result<void>> printSaveAndGetWineList(String id) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.printSaveAndGetWineList(clientKind, id: id);
  }

  @override
  Future<Result<List<WineBorrowReturnItem>>> loadWineBorrowReturnList({
    int page = 1,
    int pageSize = 20,
    String keyword = '',
    int type = 0,
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getWineBorrowReturnList(
      clientKind,
      page: page,
      pageSize: pageSize,
      keyword: keyword,
      type: type,
    );
  }

  @override
  Future<Result<WineBorrowReturnPage>> loadWineBorrowReturnPage({required int type, required int page, int pageSize = 20, required String beginDay, required String endDay, String keyword = ''}) =>
      _borrowRequest(() => api.getWineBorrowReturnPage(clientKind, type: type, page: page, pageSize: pageSize, beginDay: beginDay, endDay: endDay, keyword: keyword));

  @override
  Future<Result<List<Map<String, Object?>>>> loadWineCanBorrowList({
    String keyword = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return _borrowRequest(() => api.getWineCanBorrowList(clientKind, keyword: keyword));
  }

  @override
  Future<Result<void>> submitWineBorrow(Map<String, Object?> fields) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return _borrowRequest(() => api.newWineBorrow(clientKind, fields: fields));
  }

  @override
  Future<Result<void>> submitWineReturn(Map<String, Object?> fields) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return _borrowRequest(() => api.newWineReturn(clientKind, fields: fields));
  }

  @override
  Future<Result<List<WineBorrowReturnItem>>> loadWineBorrowInvtList({
    String keyword = '',
  }) async {
    if (_checkSession() case final f?) return FailureResult(f);
    return api.getWineBorrowInvtList(clientKind, keyword: keyword);
  }
}
