import 'package:card_table/src/bms_api.dart';
import 'package:card_table/src/bms_product_image.dart';
import 'package:card_table/src/bms_product_image_uploader.dart';
import 'package:card_table/src/bms_fc_price.dart';
import 'package:card_table/src/bms_report_configuration.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';
import 'package:session/session.dart';

final class _BmsReportContext {
  const _BmsReportContext(this.user, this.machine, this.generation);
  final Object user, machine;
  final int generation;
  @override
  bool operator ==(Object other) => other is _BmsReportContext &&
      identical(user, other.user) && identical(machine, other.machine) && generation == other.generation;
  @override
  int get hashCode => Object.hash(identityHashCode(user), identityHashCode(machine), generation);
}

abstract interface class BmsLoader {
  Future<Result<Map<String,Object?>>> requestFcPrice(BmsFcPriceRequest request);
  // S7.P1 人员管理
  Future<Result<BmsGenRule>> loadGenRule();
  Future<Result<void>> saveGenRule(Map<String, Object?> fields);
  Future<Result<List<BmsStationItem>>> loadStations({String keyword = ''});
  Future<Result<void>> saveStation(Map<String, Object?> fields);
  Future<Result<void>> setStationStatus(String id, bool enable);
  Future<Result<void>> deleteStation(String id);
  Future<Result<List<BmsEmployeeItem>>> loadEmployees({
    String keyword = '',
    String stationId = '',
  });
  Future<Result<void>> saveEmployee(Map<String, Object?> fields);
  Future<Result<void>> batchResetEmpPwd(List<String> ids);
  Future<Result<List<BmsOnboardingApprovalItem>>> loadOnboardingApprovals();
  Future<Result<void>> auditOnboarding(
    String id,
    bool pass, {
    String remark = '',
  });
  Future<Result<List<BmsBusinessEmpItem>>> loadBusinessEmployees({
    String keyword = '',
    List<String> deptIds = const [],
  });
  Future<Result<void>> setBusinessEmp(String id, bool isBusiness);
  Future<Result<BmsOnboardingPage>> loadOnboardingPage({
    int status = 1,
    int page = 1,
    int pageSize = 20,
  });
  Future<Result<void>> auditOnboardingBatch(List<String> ids, bool pass);
  Future<Result<void>> saveOnboarding(Map<String, Object?> fields);
  Future<Result<List<BmsDepartmentOption>>> loadDepartments();
  Future<Result<List<BmsEmployeeItem>>> loadUpperEmployees(String name);
  Future<Result<List<BmsEmployeeItem>>> loadBusinessCandidates({
    String keyword = '',
    List<String> deptIds = const [],
  });
  Future<Result<void>> addBusinessEmployees(List<String> ids);

  // S7.P2 商品管理
  Future<Result<List<BmsOneCateItem>>> loadOneCates();
  Future<Result<void>> saveOneCate(Map<String, Object?> fields);
  Future<Result<void>> deleteOneCate(String id);
  Future<Result<List<BmsTwoCateItem>>> loadTwoCates({String oneCateId = ''});
  Future<Result<void>> saveTwoCate(Map<String, Object?> fields);
  Future<Result<void>> deleteTwoCate(String id);
  Future<Result<List<BmsProductItem>>> loadProducts({
    String oneCateId = '',
    String twoCateId = '',
    String keyword = '',
  });
  Future<Result<void>> saveProduct(Map<String, Object?> fields);
  Future<Result<void>> setProductStatus(String id, bool enable);
  Future<Result<void>> deleteProduct(String id);
  Future<Result<List<BmsPackageGroupTemplate>>> loadTaocanTemplates();

  // S7.P3 卡台管理
  Future<Result<List<BmsRegionItem>>> loadRegions();
  Future<Result<void>> saveRegion(Map<String, Object?> fields);
  Future<Result<void>> deleteRegion(String id);
  Future<Result<List<BmsCardItem>>> loadSeats({
    String regionId = '',
    String keyword = '',
  });
  Future<Result<void>> saveSeat(Map<String, Object?> fields);
  Future<Result<void>> deleteSeat(String id);
  Future<Result<List<BmsCardMinGroupItem>>> loadCardMinGroups();
  Future<Result<void>> saveCardMinGroup(Map<String, Object?> fields);
  Future<Result<List<BmsCardTipItem>>> loadCardTips();
  Future<Result<void>> saveCardTips(Map<String, Object?> fields);
  Future<Result<List<BmsArriveRuleItem>>> loadArriveRules();
  Future<Result<void>> saveArriveRules(Map<String, Object?> fields);

  // S7.P4 限额限量
  Future<Result<List<BmsProductGroupItem>>> loadProductGroups();
  Future<Result<void>> saveProductGroup(Map<String, Object?> fields);
  Future<Result<List<BmsLimitConfigItem>>> loadLimitConfigs();
  Future<Result<void>> saveLimitConfig(Map<String, Object?> fields);

  // S7.P5 门店 / 支付 / 设备
  Future<Result<BmsStoreInfo>> loadStoreInfo();
  Future<Result<void>> saveStoreInfo(Map<String, Object?> fields);
  Future<Result<void>> restoreWorkday();
  Future<Result<List<BmsPayChannelItem>>> loadPayChannels();
  Future<Result<void>> setPayChannelUsed(String id, bool used);
  Future<Result<List<BmsPrinterItem>>> loadPrinters();
  Future<Result<void>> savePrinter(Map<String, Object?> fields);
  Future<Result<List<BmsMakeLibItem>>> loadMakeLibs();
  Future<Result<void>> saveMakeLib(Map<String, Object?> fields);
  Future<Result<BmsBillConfig>> loadBillConfig();
  Future<Result<void>> saveBillConfig(Map<String, Object?> fields);
  Future<Result<List<BmsTerminalItem>>> loadTerminals();
  Future<Result<void>> clearTerminal(String id);
  Future<Result<String>> genQuickCode(String id);

  // S7.P6 报表 / 要求 / 理由 / 规则
  Future<Result<List<BmsRequireItem>>> loadRequires();
  Future<Result<void>> saveRequireItem(Map<String, Object?> fields);
  Future<Result<List<BmsReasonItem>>> loadReasons(String reasonType);
  Future<Result<void>> saveReason(Map<String, Object?> fields);
  Future<Result<void>> deleteReason(String id);
  Future<Result<BmsTerminalRuleConfig>> loadTerminalRules();
  Future<Result<void>> saveTerminalRules(Map<String, Object?> fields);
  Future<Result<BmsVipRuleConfig>> loadVipRules();
  Future<Result<void>> saveVipRules(Map<String, Object?> fields);

  // S7.P7 存酒设置 / 抽成 / 短信
  Future<Result<BmsWineConfig>> loadWineConfig();
  Future<Result<void>> saveWineConfig(Map<String, Object?> fields);
  Future<Result<List<BmsWineItem>>> loadWinePrdItems();
  Future<Result<void>> saveWinePrd(Map<String, Object?> fields);
  Future<Result<void>> deleteWinePrd(String id);
  Future<Result<List<BmsCutPrdItem>>> loadCutPrds();
  Future<Result<void>> saveCutPrd(Map<String, Object?> fields);
  Future<Result<BmsSmsAccountInfo>> loadSmsAccount();
  Future<Result<void>> sendSmsSelfCheck(String mobile);
  Future<Result<List<BmsSmsRecord>>> loadSmsRecords({String phone = ''});
  Future<Result<BmsSmsBillPage>> loadSmsBills({
    required String startDay,
    required String endDay,
    int type = 0,
    int page = 1,
    int pageSize = 20,
  });
  Future<Result<BmsSmsDeliveryPage>> loadSmsRecordDetails({
    required String recordId,
    int status = 0,
    String mobile = '',
    int page = 1,
    int pageSize = 20,
    bool initialize = true,
    List<Map<String, Object?>> templates = const [],
  });
  Future<Result<BmsSmsDeliveryPage>> loadSmsMobileResults({
    required String mobile,
  });
}

final class ProtocolBmsLoader implements BmsLoader, BmsReportConfigurationLoader, BmsProductImageLoader {
  @override
  Object? get productImageContext => configurationContext;
  @override
  Future<Result<Map<String,Object?>>> requestProductImage(BmsProductImageRequest request)=>_guard((kind)=>api.requestProductImage(kind,request));
  @override
  Future<Result<BmsUploadedImage>> uploadProductImage(BmsProductImageFile file,{required bool Function() isCurrent}) async {
    final token=productImageContext;
    bool current()=>token!=null&&token==productImageContext&&isCurrent();
    const stale=AppFailure(kind:FailureKind.authentication,code:'bms.image_context_changed',safeMessage:'上传已取消或登录连接状态已变化');
    if(!current())return const FailureResult(stale);
    try {
      final thumbnail=await file.validateAndThumbnail();
      if(!current())return const FailureResult(stale);
      final result=await requestProductImage(const BmsProductImageRequest(BmsProductImageOperation.signature));
      if(!current())return const FailureResult(stale);
      if(result.failureOrNull case final failure?)return FailureResult(failure);
      final signature=BmsImageSignature.fromWire(result.valueOrNull!);
      final name=newBmsImageFileName(file.extension);
      if(!current())return const FailureResult(stale);
      await imageUploader(signature,name,file);
      if(!current())return const FailureResult(stale);
      return Success(BmsUploadedImage(name,thumbnail));
    } on FormatException catch(error){return FailureResult(AppFailure(kind:FailureKind.business,code:'bms.image_invalid',safeMessage:error.message));}
    on Object{return const FailureResult(AppFailure(kind:FailureKind.network,code:'bms.image_upload_failed',safeMessage:'图片存储上传失败，请重试'));}
  }
  @override
  Object? get configurationContext {
    try {
      final user = sessionRepository.currentUser, machine = sessionRepository.currentMachine;
      final epoch = generation?.call();
      if (user == null || machine == null || sessionRepository.isClosed ||
          machine.client != ClientKind.orgManager || epoch == null ||
          phase?.call() != ConnectionPhase.online) {
        return null;
      }
      return _BmsReportContext(user, machine, epoch);
    } on Object { return null; }
  }

  @override
  Future<Result<Map<String,Object?>>> requestReportConfiguration(BmsReportConfigurationRequest request) =>
      _guard((kind) => api.requestReportConfiguration(kind, request));
  @override
  Future<Result<Map<String,Object?>>> requestFcPrice(BmsFcPriceRequest request) => _guard((kind)=>api.requestFcPrice(kind,request));
  const ProtocolBmsLoader({
    required this.api,
    required this.sessionRepository,
    this.phase,
    this.generation,
    this.imageUploader=uploadBmsImageToOss,
  });

  final ProtocolBmsApi api;
  final SessionRepository sessionRepository;
  final ConnectionPhase Function()? phase;
  final int Function()? generation;
  final Future<void> Function(BmsImageSignature,String,BmsProductImageFile) imageUploader;

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function(ClientKind client) run,
  ) async {
    try {
      final user = sessionRepository.currentUser;
      final machine = sessionRepository.currentMachine;
      if (user == null ||
          machine == null ||
          machine.client != ClientKind.orgManager ||
          sessionRepository.isClosed) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.authentication,
            code: 'bms.session_required',
            safeMessage: '请登录门店管理系统后操作',
          ),
        );
      }
      final epoch = generation?.call();
      if (epoch == null || phase?.call() != ConnectionPhase.online) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'bms.offline',
            safeMessage: '连接未就绪，请稍后重试',
          ),
        );
      }
      final result = await run(machine.client);
      if (!identical(user, sessionRepository.currentUser) ||
          !identical(machine, sessionRepository.currentMachine) ||
          sessionRepository.isClosed ||
          generation?.call() != epoch ||
          phase?.call() != ConnectionPhase.online) {
        return const FailureResult(
          AppFailure(
            kind: FailureKind.authentication,
            code: 'bms.context_changed',
            safeMessage: '登录或连接状态已变化，请重新打开',
          ),
        );
      }
      return result;
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'bms.failed',
          safeMessage: '操作失败，请稍后重试',
        ),
      );
    }
  }

  // S7.P1 人员管理
  @override
  Future<Result<BmsGenRule>> loadGenRule() =>
      _guard((client) => api.getGenRule(client));

  @override
  Future<Result<void>> saveGenRule(Map<String, Object?> fields) =>
      _guard((client) => api.saveGenRule(client, fields));

  @override
  Future<Result<List<BmsStationItem>>> loadStations({String keyword = ''}) =>
      _guard((client) => api.getStationList(client, keyword: keyword));

  @override
  Future<Result<void>> saveStation(Map<String, Object?> fields) =>
      _guard((client) => api.saveStation(client, fields));

  @override
  Future<Result<void>> setStationStatus(String id, bool enable) =>
      _guard((client) => api.setStationStatus(client, id: id, enable: enable));

  @override
  Future<Result<void>> deleteStation(String id) =>
      _guard((client) => api.delStation(client, id: id));

  @override
  Future<Result<List<BmsEmployeeItem>>> loadEmployees({
    String keyword = '',
    String stationId = '',
  }) => _guard(
    (client) => api.getEmpList(client, keyword: keyword, stationId: stationId),
  );

  @override
  Future<Result<void>> saveEmployee(Map<String, Object?> fields) =>
      _guard((client) => api.saveEmp(client, fields));

  @override
  Future<Result<void>> batchResetEmpPwd(List<String> ids) =>
      _guard((client) => api.batchResetEmpPwd(client, ids: ids));

  @override
  Future<Result<List<BmsOnboardingApprovalItem>>> loadOnboardingApprovals() =>
      _guard((client) => api.getOnboardingApprovals(client));

  @override
  Future<Result<void>> auditOnboarding(
    String id,
    bool pass, {
    String remark = '',
  }) => _guard(
    (client) => api.auditOnboarding(client, id: id, pass: pass, remark: remark),
  );

  @override
  Future<Result<List<BmsBusinessEmpItem>>> loadBusinessEmployees({
    String keyword = '',
    List<String> deptIds = const [],
  }) => _guard(
    (client) =>
        api.getBusinessEmpList(client, keyword: keyword, deptIds: deptIds),
  );

  @override
  Future<Result<void>> setBusinessEmp(String id, bool isBusiness) => _guard(
    (client) => api.setBusinessEmp(client, id: id, isBusiness: isBusiness),
  );

  @override
  Future<Result<BmsOnboardingPage>> loadOnboardingPage({
    int status = 1,
    int page = 1,
    int pageSize = 20,
  }) => _guard(
    (client) => api.getOnboardingPage(
      client,
      status: status,
      page: page,
      pageSize: pageSize,
    ),
  );
  @override
  Future<Result<void>> auditOnboardingBatch(List<String> ids, bool pass) =>
      _guard((client) => api.auditOnboardingBatch(client, ids, pass));
  @override
  Future<Result<void>> saveOnboarding(Map<String, Object?> fields) =>
      _guard((client) => api.saveOnboarding(client, fields));
  @override
  Future<Result<List<BmsDepartmentOption>>> loadDepartments() =>
      _guard((client) => api.getDepartments(client));
  @override
  Future<Result<List<BmsEmployeeItem>>> loadUpperEmployees(String name) =>
      _guard((client) => api.getUpperEmployees(client, name));
  @override
  Future<Result<List<BmsEmployeeItem>>> loadBusinessCandidates({
    String keyword = '',
    List<String> deptIds = const [],
  }) => _guard(
    (client) =>
        api.getBusinessCandidates(client, keyword: keyword, deptIds: deptIds),
  );
  @override
  Future<Result<void>> addBusinessEmployees(List<String> ids) =>
      _guard((client) => api.addBusinessEmployees(client, ids));

  // S7.P2 商品管理
  @override
  Future<Result<List<BmsOneCateItem>>> loadOneCates() =>
      _guard((client) => api.getOneCateList(client));

  @override
  Future<Result<void>> saveOneCate(Map<String, Object?> fields) =>
      _guard((client) => api.saveOneCate(client, fields));

  @override
  Future<Result<void>> deleteOneCate(String id) =>
      _guard((client) => api.delOneCate(client, id: id));

  @override
  Future<Result<List<BmsTwoCateItem>>> loadTwoCates({String oneCateId = ''}) =>
      _guard((client) => api.getTwoCateList(client, oneCateId: oneCateId));

  @override
  Future<Result<void>> saveTwoCate(Map<String, Object?> fields) =>
      _guard((client) => api.saveTwoCate(client, fields));

  @override
  Future<Result<void>> deleteTwoCate(String id) =>
      _guard((client) => api.delTwoCate(client, id: id));

  @override
  Future<Result<List<BmsProductItem>>> loadProducts({
    String oneCateId = '',
    String twoCateId = '',
    String keyword = '',
  }) => _guard(
    (client) => api.getPrdList(
      client,
      oneCateId: oneCateId,
      twoCateId: twoCateId,
      keyword: keyword,
    ),
  );

  @override
  Future<Result<void>> saveProduct(Map<String, Object?> fields) =>
      _guard((client) => api.savePrd(client, fields));

  @override
  Future<Result<void>> setProductStatus(String id, bool enable) =>
      _guard((client) => api.setPrdStatus(client, id: id, enable: enable));

  @override
  Future<Result<void>> deleteProduct(String id) =>
      _guard((client) => api.delPrd(client, id: id));

  @override
  Future<Result<List<BmsPackageGroupTemplate>>> loadTaocanTemplates() =>
      _guard((client) => api.getTaocanTemplates(client));

  // S7.P3 卡台管理
  @override
  Future<Result<List<BmsRegionItem>>> loadRegions() =>
      _guard((client) => api.getRegionList(client));

  @override
  Future<Result<void>> saveRegion(Map<String, Object?> fields) =>
      _guard((client) => api.saveRegion(client, fields));

  @override
  Future<Result<void>> deleteRegion(String id) =>
      _guard((client) => api.delRegion(client, id: id));

  @override
  Future<Result<List<BmsCardItem>>> loadSeats({
    String regionId = '',
    String keyword = '',
  }) => _guard(
    (client) => api.getSeatList(client, regionId: regionId, keyword: keyword),
  );

  @override
  Future<Result<void>> saveSeat(Map<String, Object?> fields) =>
      _guard((client) => api.saveSeat(client, fields));

  @override
  Future<Result<void>> deleteSeat(String id) =>
      _guard((client) => api.delSeat(client, id: id));

  @override
  Future<Result<List<BmsCardMinGroupItem>>> loadCardMinGroups() =>
      _guard((client) => api.getCardMinGroupList(client));

  @override
  Future<Result<void>> saveCardMinGroup(Map<String, Object?> fields) =>
      _guard((client) => api.saveCardMinGroup(client, fields));

  @override
  Future<Result<List<BmsCardTipItem>>> loadCardTips() =>
      _guard((client) => api.getCardTipsList(client));

  @override
  Future<Result<void>> saveCardTips(Map<String, Object?> fields) =>
      _guard((client) => api.saveCardTips(client, fields));

  @override
  Future<Result<List<BmsArriveRuleItem>>> loadArriveRules() =>
      _guard((client) => api.getArriveRulesList(client));

  @override
  Future<Result<void>> saveArriveRules(Map<String, Object?> fields) =>
      _guard((client) => api.saveArriveRules(client, fields));

  // S7.P4 限额限量
  @override
  Future<Result<List<BmsProductGroupItem>>> loadProductGroups() =>
      _guard((client) => api.getPgrpList(client));

  @override
  Future<Result<void>> saveProductGroup(Map<String, Object?> fields) =>
      _guard((client) => api.savePgrp(client, fields));

  @override
  Future<Result<List<BmsLimitConfigItem>>> loadLimitConfigs() =>
      _guard((client) => api.getFreelmtList(client));

  @override
  Future<Result<void>> saveLimitConfig(Map<String, Object?> fields) =>
      _guard((client) => api.saveFreelmt(client, fields));

  // S7.P5 门店 / 支付 / 设备
  @override
  Future<Result<BmsStoreInfo>> loadStoreInfo() =>
      _guard((client) => api.getStoreInfo(client));

  @override
  Future<Result<void>> saveStoreInfo(Map<String, Object?> fields) =>
      _guard((client) => api.saveStoreInfo(client, fields));

  @override
  Future<Result<void>> restoreWorkday() =>
      _guard((client) => api.restoreWorkday(client));

  @override
  Future<Result<List<BmsPayChannelItem>>> loadPayChannels() =>
      _guard((client) => api.getPayList(client));

  @override
  Future<Result<void>> setPayChannelUsed(String id, bool used) =>
      _guard((client) => api.setPayChannelUsed(client, id: id, used: used));

  @override
  Future<Result<List<BmsPrinterItem>>> loadPrinters() =>
      _guard((client) => api.getPrinterList(client));

  @override
  Future<Result<void>> savePrinter(Map<String, Object?> fields) =>
      _guard((client) => api.savePrinter(client, fields));

  @override
  Future<Result<List<BmsMakeLibItem>>> loadMakeLibs() =>
      _guard((client) => api.getMakeLibList(client));

  @override
  Future<Result<void>> saveMakeLib(Map<String, Object?> fields) =>
      _guard((client) => api.saveMakeLib(client, fields));

  @override
  Future<Result<BmsBillConfig>> loadBillConfig() =>
      _guard((client) => api.getBillConfig(client));

  @override
  Future<Result<void>> saveBillConfig(Map<String, Object?> fields) =>
      _guard((client) => api.saveBillConfig(client, fields));

  @override
  Future<Result<List<BmsTerminalItem>>> loadTerminals() =>
      _guard((client) => api.getTerminalList(client));

  @override
  Future<Result<void>> clearTerminal(String id) =>
      _guard((client) => api.clearTerminal(client, id: id));

  @override
  Future<Result<String>> genQuickCode(String id) =>
      _guard((client) => api.genQuickCode(client, id: id));

  // S7.P6 报表 / 要求 / 理由 / 规则
  @override
  Future<Result<List<BmsRequireItem>>> loadRequires() =>
      _guard((client) => api.getRequireList(client));

  @override
  Future<Result<void>> saveRequireItem(Map<String, Object?> fields) =>
      _guard((client) => api.saveRequireItem(client, fields));

  @override
  Future<Result<List<BmsReasonItem>>> loadReasons(String reasonType) =>
      _guard((client) => api.getReasonList(client, reasonType: reasonType));

  @override
  Future<Result<void>> saveReason(Map<String, Object?> fields) =>
      _guard((client) => api.saveReason(client, fields));

  @override
  Future<Result<void>> deleteReason(String id) =>
      _guard((client) => api.delReason(client, id: id));

  @override
  Future<Result<BmsTerminalRuleConfig>> loadTerminalRules() =>
      _guard((client) => api.getTerminalRules(client));

  @override
  Future<Result<void>> saveTerminalRules(Map<String, Object?> fields) =>
      _guard((client) => api.saveTerminalRules(client, fields));

  @override
  Future<Result<BmsVipRuleConfig>> loadVipRules() =>
      _guard((client) => api.getVipRules(client));

  @override
  Future<Result<void>> saveVipRules(Map<String, Object?> fields) =>
      _guard((client) => api.saveVipRules(client, fields));

  // S7.P7 存酒设置 / 抽成 / 短信
  @override
  Future<Result<BmsWineConfig>> loadWineConfig() =>
      _guard((client) => api.getWineConfig(client));

  @override
  Future<Result<void>> saveWineConfig(Map<String, Object?> fields) =>
      _guard((client) => api.saveWineConfig(client, fields));

  @override
  Future<Result<List<BmsWineItem>>> loadWinePrdItems() =>
      _guard((client) => api.getWinePrdItems(client));

  @override
  Future<Result<void>> saveWinePrd(Map<String, Object?> fields) =>
      _guard((client) => api.saveWinePrd(client, fields));

  @override
  Future<Result<void>> deleteWinePrd(String id) =>
      _guard((client) => api.delWinePrd(client, id: id));

  @override
  Future<Result<List<BmsCutPrdItem>>> loadCutPrds() =>
      _guard((client) => api.getCutPrdList(client));

  @override
  Future<Result<void>> saveCutPrd(Map<String, Object?> fields) =>
      _guard((client) => api.saveCutPrd(client, fields));

  @override
  Future<Result<BmsSmsAccountInfo>> loadSmsAccount() =>
      _guard((client) => api.getSmsAccountInfo(client));
  @override
  Future<Result<void>> sendSmsSelfCheck(String mobile) =>
      _guard((client) => api.sendSmsSelfCheck(client, mobile: mobile));

  @override
  Future<Result<List<BmsSmsRecord>>> loadSmsRecords({String phone = ''}) =>
      _guard((client) => api.getSmsRecords(client, phone: phone));
  @override
  Future<Result<BmsSmsBillPage>> loadSmsBills({
    required String startDay,
    required String endDay,
    int type = 0,
    int page = 1,
    int pageSize = 20,
  }) => _guard(
    (client) => api.getSmsBills(
      client,
      startDay: startDay,
      endDay: endDay,
      type: type,
      page: page,
      pageSize: pageSize,
    ),
  );
  @override
  Future<Result<BmsSmsDeliveryPage>> loadSmsRecordDetails({
    required String recordId,
    int status = 0,
    String mobile = '',
    int page = 1,
    int pageSize = 20,
    bool initialize = true,
    List<Map<String, Object?>> templates = const [],
  }) => _guard(
    (client) => api.getSmsRecordDetails(
      client,
      recordId: recordId,
      status: status,
      mobile: mobile,
      page: page,
      pageSize: pageSize,
      initialize: initialize,
      templates: templates,
    ),
  );
  @override
  Future<Result<BmsSmsDeliveryPage>> loadSmsMobileResults({
    required String mobile,
  }) => _guard((client) => api.getSmsMobileResults(client, mobile: mobile));
}
