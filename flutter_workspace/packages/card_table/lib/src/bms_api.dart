import 'package:card_table/src/bms_models.dart';
import 'package:card_table/src/bms_product_image.dart';
import 'package:card_table/src/bms_fc_price.dart';
import 'package:card_table/src/bms_report_configuration.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

final class ProtocolBmsApi {
  const ProtocolBmsApi({required this.client});
  final ProtocolClient client;

  Future<Result<Map<String,Object?>>> requestProductImage(ClientKind kind,BmsProductImageRequest request) async {
    try {
      final response=await client.post(request.operation.path,client:kind,body:request.body);
      if(response.failureOrNull case final failure?)return FailureResult(failure);
      final map=response.valueOrNull;
      if('${map?['code']}'!='1')return const FailureResult(AppFailure(kind:FailureKind.business,code:'bms.image_rejected',safeMessage:'商品图片操作未成功，请重试'));
      if([BmsProductImageOperation.bindBatch,BmsProductImageOperation.bindSingle,BmsProductImageOperation.saveDefault].contains(request.operation))return const Success({});
      final data=map?['data'];
      if(data is! Map)return const FailureResult(AppFailure(kind:FailureKind.protocol,code:'bms.image_shape',safeMessage:'商品图片数据无法识别'));
      return Success(Map<String,Object?>.from(data));
    } on FormatException catch(error){return FailureResult(AppFailure(kind:FailureKind.business,code:'bms.image_invalid',safeMessage:error.message));}
    on Object{return const FailureResult(AppFailure(kind:FailureKind.network,code:'bms.image_failed',safeMessage:'商品图片请求失败，请重试'));}
  }
  Future<Result<Map<String,Object?>>> requestReportConfiguration(
    ClientKind kind, BmsReportConfigurationRequest request,
  ) async {
    if (kind != ClientKind.orgManager) {
      return const FailureResult(AppFailure(kind: FailureKind.authentication,
        code: 'bms.report_session_required', safeMessage: '请登录门店管理系统后操作'));
    }
    try {
      final body = request.body;
      final path = '/rpt/cfg/${request.operation.endpoint}';
      final response = request.operation.hasBody
          ? await client.post(path, client: kind, body: body)
          : await client.postWithoutBody(path, client: kind);
      if (response.failureOrNull case final failure?) return FailureResult(failure);
      final envelope = response.valueOrNull!;
      if (envelope['code'] != 1 && envelope['code'] != '1') {
        return const FailureResult(AppFailure(kind: FailureKind.business,
          code: 'bms.report_rejected', safeMessage: '报表配置操作未成功，请重试'));
      }
      if (!request.operation.reads) return const Success({});
      final data = envelope['data'];
      if (data is! Map || data.keys.any((key) => key is! String)) {
        return const FailureResult(AppFailure(kind: FailureKind.protocol,
          code: 'bms.report_shape', safeMessage: '报表配置返回了无法识别的数据'));
      }
      return Success(Map<String,Object?>.unmodifiable(Map<String,Object?>.from(data)));
    } on FormatException catch(error) {
      return FailureResult(AppFailure(kind: FailureKind.business,
        code: 'bms.report_invalid', safeMessage: error.message));
    } on Object {
      return const FailureResult(AppFailure(kind: FailureKind.unknown,
        code: 'bms.report_failed', safeMessage: '报表配置操作失败，请重试'));
    }
  }
  Future<Result<Map<String,Object?>>> requestFcPrice(ClientKind kind,BmsFcPriceRequest request) async {
    try {
      final result = await client.post('/prd/${request.operation.endpoint}',client:kind,body:request.body);
      if (result.failureOrNull case final failure?) return FailureResult(failure);
      if (result.valueOrNull?['code'] != 1 && result.valueOrNull?['code'] != '1') return const FailureResult(AppFailure(kind:FailureKind.business,code:'bms.fc_rejected',safeMessage:'价格方案操作未成功，请重试'));
      if (!request.operation.reads) return const Success({});
      final parsed = _unwrap(result);
      if (parsed.failureOrNull case final failure?) return FailureResult(failure);
      if (parsed.valueOrNull case final Map<String,Object?> data) return Success(data);
      return const FailureResult(AppFailure(kind:FailureKind.protocol,code:'bms.fc_invalid',safeMessage:'价格方案服务数据无法识别'));
    } on FormatException catch(error) { return FailureResult(AppFailure(kind:FailureKind.business,code:'bms.fc_invalid',safeMessage:error.message)); }
    on Object { return const FailureResult(AppFailure(kind:FailureKind.unknown,code:'bms.fc_failed',safeMessage:'价格方案操作失败，请重试')); }
  }

  // ---------------------------------------------------------------------------
  // S7.P1 人员管理
  // ---------------------------------------------------------------------------

  Future<Result<BmsGenRule>> getGenRule(ClientKind kind) async {
    final response = await client.postWithoutBody(
      '/emp/gen_rule',
      client: kind,
    );
    return _parseObject(
      response,
      BmsGenRule.fromWire,
      fallback: const BmsGenRule(),
    );
  }

  Future<Result<void>> saveGenRule(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/emp/save_gen_rule',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsStationItem>>> getStationList(
    ClientKind kind, {
    String keyword = '',
  }) async {
    final response = await client.post(
      '/station/list',
      body: <String, Object?>{'key': keyword},
      client: kind,
    );
    return _parseList(response, BmsStationItem.fromWire);
  }

  Future<Result<void>> saveStation(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final isNew = fields['id'] == null || fields['id'].toString().isEmpty;
    final path = isNew ? '/station/new' : '/station/save';
    final response = await client.post(path, body: fields, client: kind);
    return _parseVoid(response);
  }

  Future<Result<void>> setStationStatus(
    ClientKind kind, {
    required String id,
    required bool enable,
  }) async {
    final path = enable ? '/station/enable' : '/station/disable';
    final response = await client.post(
      path,
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> delStation(ClientKind kind, {required String id}) async {
    final response = await client.post(
      '/station/del',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsEmployeeItem>>> getEmpList(
    ClientKind kind, {
    String keyword = '',
    String stationId = '',
  }) async {
    final response = await client.post(
      '/emp/list',
      body: <String, Object?>{
        'key': keyword,
        if (stationId.isNotEmpty) 'station_id': stationId,
      },
      client: kind,
    );
    return _parseList(response, BmsEmployeeItem.fromWire);
  }

  Future<Result<void>> saveEmp(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final isNew = fields['id'] == null || fields['id'].toString().isEmpty;
    final path = isNew ? '/emp/new' : '/emp/save';
    final response = await client.post(path, body: fields, client: kind);
    return _parseVoid(response);
  }

  Future<Result<void>> batchResetEmpPwd(
    ClientKind kind, {
    required List<String> ids,
  }) async {
    final response = await client.post(
      '/emp/batch_reset_pwd',
      body: <String, Object?>{'emp_ids': ids},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsOnboardingApprovalItem>>> getOnboardingApprovals(
    ClientKind kind, {
    int status = 1,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await client.post(
      '/emp/get_emp_rz_list',
      body: {'s': status, 'page_num': page, 'page_size': pageSize},
      client: kind,
    );
    return _parseList(response, BmsOnboardingApprovalItem.fromWire);
  }

  Future<Result<void>> auditOnboarding(
    ClientKind kind, {
    required String id,
    required bool pass,
    String remark = '',
  }) async {
    final response = await client.post(
      pass ? '/emp/emp_rz_approve_batch_yes' : '/emp/emp_rz_approve_batch_deny',
      body: {
        'ids': [id],
      },
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsBusinessEmpItem>>> getBusinessEmpList(
    ClientKind kind, {
    String keyword = '',
    List<String> deptIds = const [],
  }) async {
    final response = await client.post(
      '/emp/get_bs_sales_list',
      body: {'key': keyword, if (deptIds.isNotEmpty) 'ids': deptIds},
      client: kind,
    );
    return _parseList(response, BmsBusinessEmpItem.fromWire);
  }

  Future<Result<BmsOnboardingPage>> getOnboardingPage(
    ClientKind kind, {
    int status = 1,
    int page = 1,
    int pageSize = 20,
  }) async => _parseObject(
    await client.post(
      '/emp/get_emp_rz_list',
      body: {'s': status, 'page_num': page, 'page_size': pageSize},
      client: kind,
    ),
    BmsOnboardingPage.fromWire,
    fallback: const BmsOnboardingPage(),
  );

  Future<Result<void>> auditOnboardingBatch(
    ClientKind kind,
    List<String> ids,
    bool pass,
  ) async => _parseVoid(
    await client.post(
      pass ? '/emp/emp_rz_approve_batch_yes' : '/emp/emp_rz_approve_batch_deny',
      body: {'ids': ids},
      client: kind,
    ),
  );

  Future<Result<void>> saveOnboarding(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async => _parseVoid(
    await client.post(
      '/emp/save_emp_rz_for_approve',
      body: fields,
      client: kind,
    ),
  );

  Future<Result<List<BmsDepartmentOption>>> getDepartments(
    ClientKind kind,
  ) async => _parseList(
    await client.post('/dept/tree', client: kind),
    BmsDepartmentOption.fromWire,
  );

  Future<Result<List<BmsEmployeeItem>>> getUpperEmployees(
    ClientKind kind,
    String name,
  ) async => _parseList(
    await client.post(
      '/emp/upper_items',
      body: {
        'name': name,
        'page_num': 1,
        'page_size': 9999999,
        'mod_emp_ids': [],
      },
      client: kind,
    ),
    BmsEmployeeItem.fromWire,
  );

  Future<Result<List<BmsEmployeeItem>>> getBusinessCandidates(
    ClientKind kind, {
    String keyword = '',
    List<String> deptIds = const [],
  }) async => _parseList(
    await client.post(
      '/emp/list',
      body: {'key': keyword, if (deptIds.isNotEmpty) 'ids': deptIds},
      client: kind,
    ),
    BmsEmployeeItem.fromWire,
  );

  Future<Result<void>> addBusinessEmployees(
    ClientKind kind,
    List<String> ids,
  ) async => _parseVoid(
    await client.post(
      '/emp/batch_add_bs_sales',
      body: {'ids': ids},
      client: kind,
    ),
  );

  Future<Result<void>> setBusinessEmp(
    ClientKind kind, {
    required String id,
    required bool isBusiness,
  }) async {
    final response = await client.post(
      isBusiness ? '/emp/batch_add_bs_sales' : '/emp/remove_bs_sales',
      body: isBusiness
          ? {
              'ids': [id],
            }
          : {'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  // ---------------------------------------------------------------------------
  // S7.P2 商品管理
  // ---------------------------------------------------------------------------

  Future<Result<List<BmsOneCateItem>>> getOneCateList(ClientKind kind) async {
    final response = await client.post(
      '/ocate/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsOneCateItem.fromWire);
  }

  Future<Result<void>> saveOneCate(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/ocate/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> delOneCate(ClientKind kind, {required String id}) async {
    final response = await client.post(
      '/ocate/del',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsTwoCateItem>>> getTwoCateList(
    ClientKind kind, {
    String oneCateId = '',
  }) async {
    final response = await client.post(
      '/tcate/list',
      body: <String, Object?>{if (oneCateId.isNotEmpty) 'ocate_id': oneCateId},
      client: kind,
    );
    return _parseList(response, BmsTwoCateItem.fromWire);
  }

  Future<Result<void>> saveTwoCate(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/tcate/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> delTwoCate(ClientKind kind, {required String id}) async {
    final response = await client.post(
      '/tcate/del',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsProductItem>>> getPrdList(
    ClientKind kind, {
    String oneCateId = '',
    String twoCateId = '',
    String keyword = '',
  }) async {
    final response = await client.post(
      '/prd/list',
      body: <String, Object?>{
        if (oneCateId.isNotEmpty) 'ocate_id': oneCateId,
        if (twoCateId.isNotEmpty) 'tcate_id': twoCateId,
        if (keyword.isNotEmpty) 'key': keyword,
      },
      client: kind,
    );
    return _parseList(response, BmsProductItem.fromWire);
  }

  Future<Result<void>> savePrd(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final isNew = fields['id'] == null || fields['id'].toString().isEmpty;
    final path = isNew ? '/prd/new' : '/prd/save';
    final response = await client.post(path, body: fields, client: kind);
    return _parseVoid(response);
  }

  Future<Result<void>> setPrdStatus(
    ClientKind kind, {
    required String id,
    required bool enable,
  }) async {
    final path = enable ? '/prd/enable' : '/prd/disable';
    final response = await client.post(
      path,
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> delPrd(ClientKind kind, {required String id}) async {
    final response = await client.post(
      '/prd/del',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsPackageGroupTemplate>>> getTaocanTemplates(
    ClientKind kind,
  ) async {
    final response = await client.post(
      '/prd/taocan_templates',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsPackageGroupTemplate.fromWire);
  }

  // ---------------------------------------------------------------------------
  // S7.P3 卡台管理
  // ---------------------------------------------------------------------------

  Future<Result<List<BmsRegionItem>>> getRegionList(ClientKind kind) async {
    final response = await client.post(
      '/region/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsRegionItem.fromWire);
  }

  Future<Result<void>> saveRegion(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/region/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> delRegion(ClientKind kind, {required String id}) async {
    final response = await client.post(
      '/region/del',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsCardItem>>> getSeatList(
    ClientKind kind, {
    String regionId = '',
    String keyword = '',
  }) async {
    final response = await client.post(
      '/seat/list',
      body: <String, Object?>{
        if (regionId.isNotEmpty) 'region_id': regionId,
        if (keyword.isNotEmpty) 'key': keyword,
      },
      client: kind,
    );
    return _parseList(response, BmsCardItem.fromWire);
  }

  Future<Result<void>> saveSeat(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final isNew = fields['id'] == null || fields['id'].toString().isEmpty;
    final path = isNew ? '/seat/new' : '/seat/save';
    final response = await client.post(path, body: fields, client: kind);
    return _parseVoid(response);
  }

  Future<Result<void>> delSeat(ClientKind kind, {required String id}) async {
    final response = await client.post(
      '/seat/del',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsCardMinGroupItem>>> getCardMinGroupList(
    ClientKind kind,
  ) async {
    final response = await client.post(
      '/seat_grp/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsCardMinGroupItem.fromWire);
  }

  Future<Result<void>> saveCardMinGroup(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/seat_grp/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsCardTipItem>>> getCardTipsList(ClientKind kind) async {
    final response = await client.post(
      '/cardTips/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsCardTipItem.fromWire);
  }

  Future<Result<void>> saveCardTips(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/cardTips/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsArriveRuleItem>>> getArriveRulesList(
    ClientKind kind,
  ) async {
    final response = await client.post(
      '/arriveRules/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsArriveRuleItem.fromWire);
  }

  Future<Result<void>> saveArriveRules(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/arriveRules/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  // ---------------------------------------------------------------------------
  // S7.P4 限额限量
  // ---------------------------------------------------------------------------

  Future<Result<List<BmsProductGroupItem>>> getPgrpList(ClientKind kind) async {
    final response = await client.post(
      '/pgrp/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsProductGroupItem.fromWire);
  }

  Future<Result<void>> savePgrp(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/pgrp/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsLimitConfigItem>>> getFreelmtList(
    ClientKind kind,
  ) async {
    final response = await client.post(
      '/freelmt/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsLimitConfigItem.fromWire);
  }

  Future<Result<void>> saveFreelmt(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/freelmt/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  // ---------------------------------------------------------------------------
  // S7.P5 门店 / 支付 / 设备
  // ---------------------------------------------------------------------------

  Future<Result<BmsStoreInfo>> getStoreInfo(ClientKind kind) async {
    final response = await client.post(
      '/org/get_info',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseObject(
      response,
      BmsStoreInfo.fromWire,
      fallback: const BmsStoreInfo(),
    );
  }

  Future<Result<void>> saveStoreInfo(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/org/save_info',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> restoreWorkday(ClientKind kind) async {
    final response = await client.post(
      '/wkd/restore',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsPayChannelItem>>> getPayList(ClientKind kind) async {
    final response = await client.post(
      '/paycnl/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsPayChannelItem.fromWire);
  }

  Future<Result<void>> setPayChannelUsed(
    ClientKind kind, {
    required String id,
    required bool used,
  }) async {
    final path = used ? '/paycnl/add_used' : '/paycnl/del_used';
    final response = await client.post(
      path,
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsPrinterItem>>> getPrinterList(ClientKind kind) async {
    final response = await client.post(
      '/printer/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsPrinterItem.fromWire);
  }

  Future<Result<void>> savePrinter(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final isNew = fields['id'] == null || fields['id'].toString().isEmpty;
    final path = isNew ? '/printer/new' : '/printer/save';
    final response = await client.post(path, body: fields, client: kind);
    return _parseVoid(response);
  }

  Future<Result<List<BmsMakeLibItem>>> getMakeLibList(ClientKind kind) async {
    final response = await client.post(
      '/mklib/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsMakeLibItem.fromWire);
  }

  Future<Result<void>> saveMakeLib(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final isNew = fields['id'] == null || fields['id'].toString().isEmpty;
    final path = isNew ? '/mklib/new' : '/mklib/save';
    final response = await client.post(path, body: fields, client: kind);
    return _parseVoid(response);
  }

  Future<Result<BmsBillConfig>> getBillConfig(ClientKind kind) async {
    final response = await client.post(
      '/bill/get',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseObject(
      response,
      BmsBillConfig.fromWire,
      fallback: const BmsBillConfig(),
    );
  }

  Future<Result<void>> saveBillConfig(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/bill/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsTerminalItem>>> getTerminalList(ClientKind kind) async {
    final response = await client.post(
      '/lic/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsTerminalItem.fromWire);
  }

  Future<Result<void>> clearTerminal(
    ClientKind kind, {
    required String id,
  }) async {
    final response = await client.post(
      '/lic/clear_term',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<String>> genQuickCode(
    ClientKind kind, {
    required String id,
  }) async {
    final response = await client.post(
      '/lic/gen_quick_code',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    if (response case Success(:final value)) {
      final code =
          (value as Map<String, Object?>?)?['quick_code']?.toString() ?? '8888';
      return Success(code);
    }
    return const FailureResult(
      AppFailure(
        kind: FailureKind.business,
        code: 'bms.quick_code_failure',
        safeMessage: '获取快捷码失败',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // S7.P6 报表配置 / 要求 / 理由 / 规则
  // ---------------------------------------------------------------------------

  Future<Result<List<BmsRequireItem>>> getRequireList(ClientKind kind) async {
    final response = await client.post(
      '/cfg/rqm/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsRequireItem.fromWire);
  }

  Future<Result<void>> saveRequireItem(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/cfg/rqm/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsReasonItem>>> getReasonList(
    ClientKind kind, {
    required String reasonType,
  }) async {
    final response = await client.post(
      '/rsn/list',
      body: <String, Object?>{'type': reasonType},
      client: kind,
    );
    return _parseList(response, BmsReasonItem.fromWire);
  }

  Future<Result<void>> saveReason(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final isNew = fields['id'] == null || fields['id'].toString().isEmpty;
    final path = isNew ? '/rsn/new' : '/rsn/save';
    final response = await client.post(path, body: fields, client: kind);
    return _parseVoid(response);
  }

  Future<Result<void>> delReason(ClientKind kind, {required String id}) async {
    final response = await client.post(
      '/rsn/del',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<BmsTerminalRuleConfig>> getTerminalRules(
    ClientKind kind,
  ) async {
    final response = await client.post(
      '/term/rule/get',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseObject(
      response,
      BmsTerminalRuleConfig.fromWire,
      fallback: const BmsTerminalRuleConfig(),
    );
  }

  Future<Result<void>> saveTerminalRules(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/term/rule/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<BmsVipRuleConfig>> getVipRules(ClientKind kind) async {
    final response = await client.post(
      '/vip/rule/get',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseObject(
      response,
      BmsVipRuleConfig.fromWire,
      fallback: const BmsVipRuleConfig(),
    );
  }

  Future<Result<void>> saveVipRules(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/vip/rule/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  // ---------------------------------------------------------------------------
  // S7.P7 存酒设置 / 抽成 / 短信
  // ---------------------------------------------------------------------------

  Future<Result<BmsWineConfig>> getWineConfig(ClientKind kind) async {
    final response = await client.post(
      '/wine/cfg/get',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseObject(
      response,
      BmsWineConfig.fromWire,
      fallback: const BmsWineConfig(),
    );
  }

  Future<Result<void>> saveWineConfig(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/wine/cfg/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsWineItem>>> getWinePrdItems(ClientKind kind) async {
    final response = await client.post(
      '/wine/cfg/prd_items',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsWineItem.fromWire);
  }

  Future<Result<void>> saveWinePrd(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/wine/cfg/add_prds',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> delWinePrd(ClientKind kind, {required String id}) async {
    final response = await client.post(
      '/wine/cfg/del_prds',
      body: <String, Object?>{'id': id},
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<List<BmsCutPrdItem>>> getCutPrdList(ClientKind kind) async {
    final response = await client.post(
      '/cutPrd/list',
      body: const <String, Object?>{},
      client: kind,
    );
    return _parseList(response, BmsCutPrdItem.fromWire);
  }

  Future<Result<void>> saveCutPrd(
    ClientKind kind,
    Map<String, Object?> fields,
  ) async {
    final response = await client.post(
      '/cutPrd/save',
      body: fields,
      client: kind,
    );
    return _parseVoid(response);
  }

  Future<Result<BmsSmsAccountInfo>> getSmsAccountInfo(ClientKind kind) async {
    final response = await client.postWithoutBody(
      '/sms_mgr/get_acct_info',
      client: kind,
    );
    return _parseSmsObject(response, BmsSmsAccountInfo.fromWire);
  }

  Future<Result<void>> sendSmsSelfCheck(
    ClientKind kind, {
    required String mobile,
  }) async {
    if (!RegExp(r'^\d{11}$').hasMatch(mobile)) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'bms.sms_mobile_invalid',
          safeMessage: '请输入11位手机号',
        ),
      );
    }
    return _parseVoid(
      await client.post(
        '/sms_mgr/self_check',
        client: kind,
        body: {'mobile': mobile},
      ),
    );
  }

  Future<Result<List<BmsSmsRecord>>> getSmsRecords(
    ClientKind kind, {
    String phone = '',
  }) async {
    final result = await getSmsMobileResults(kind, mobile: phone);
    if (result.failureOrNull case final failure?) return FailureResult(failure);
    return Success(result.valueOrNull!.records);
  }

  Future<Result<BmsSmsBillPage>> getSmsBills(
    ClientKind kind, {
    required String startDay,
    required String endDay,
    int type = 0,
    int page = 1,
    int pageSize = 20,
  }) async => _parseSmsObject(
    await client.post(
      '/sms_mgr/get_sms_records',
      client: kind,
      body: {
        'page_num': page,
        'page_size': pageSize,
        'start_biz_day': startDay,
        'end_biz_day': endDay,
        'type_id': type,
      },
    ),
    BmsSmsBillPage.fromWire,
  );

  Future<Result<BmsSmsDeliveryPage>> getSmsRecordDetails(
    ClientKind kind, {
    required String recordId,
    int status = 0,
    String mobile = '',
    int page = 1,
    int pageSize = 20,
    bool initialize = true,
    List<Map<String, Object?>> templates = const [],
  }) async {
    final id = int.tryParse(recordId);
    if (id == null) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.protocol,
          code: 'bms.sms_record_id',
          safeMessage: '短信账单编号无效',
        ),
      );
    }
    return _parseSmsObject(
      await client.post(
        '/sms_mgr/get_sms_record_dtls',
        client: kind,
        body: {
          'page_num': page,
          'page_size': pageSize,
          'is_init': initialize ? 1 : 2,
          'record_id': id,
          'status': status,
          'mobile': mobile,
        },
      ),
      (wire) => BmsSmsDeliveryPage.fromWire(
        wire,
        previousTemplates: templates,
        interpolate: true,
      ),
    );
  }

  Future<Result<BmsSmsDeliveryPage>> getSmsMobileResults(
    ClientKind kind, {
    required String mobile,
  }) async => _parseSmsObject(
    await client.post(
      '/sms_mgr/get_mobile_send_rst',
      client: kind,
      body: {'mobile': mobile},
    ),
    BmsSmsDeliveryPage.fromWire,
  );

  Result<T> _parseSmsObject<T>(
    Result<Object?> response,
    T Function(Map<String, Object?>) parse,
  ) {
    final data = _unwrap(response);
    if (data.failureOrNull case final failure?) return FailureResult(failure);
    if (data.valueOrNull case final Map<String, Object?> value) {
      try {
        return Success(parse(value));
      } on Object {
        /* Return a safe protocol error below. */
      }
    }
    return const FailureResult(
      AppFailure(
        kind: FailureKind.protocol,
        code: 'bms.sms_invalid_response',
        safeMessage: '短信服务返回的数据格式异常，请重试',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 辅助解析方法
  // ---------------------------------------------------------------------------

  Result<List<T>> _parseList<T>(
    Result<Object?> response,
    T Function(Map<String, Object?>) mapper,
  ) {
    response = _unwrap(response);
    if (response case Success(:final value)) {
      if (value is List) {
        return Success(
          value.whereType<Map<String, Object?>>().map(mapper).toList(),
        );
      }
      if (value is Map<String, Object?>) {
        final list =
            value['records'] ??
            value['emps'] ??
            value['list'] ??
            value['data'] ??
            value['items'] ??
            value['rows'];
        if (list is List) {
          return Success(
            list.whereType<Map<String, Object?>>().map(mapper).toList(),
          );
        }
      }
      return const Success(<Never>[]);
    }
    return FailureResult(
      response.failureOrNull ??
          const AppFailure(
            kind: FailureKind.network,
            code: 'bms.error',
            safeMessage: '网络或服务异常',
          ),
    );
  }

  Result<T> _parseObject<T>(
    Result<Object?> response,
    T Function(Map<String, Object?>) mapper, {
    required T fallback,
  }) {
    response = _unwrap(response);
    if (response case Success(:final value)) {
      if (value is Map<String, Object?>) {
        final data = value['data'] ?? value;
        if (data is Map<String, Object?>) {
          return Success(mapper(data));
        }
      }
      return Success(fallback);
    }
    return FailureResult(
      response.failureOrNull ??
          const AppFailure(
            kind: FailureKind.network,
            code: 'bms.error',
            safeMessage: '网络或服务异常',
          ),
    );
  }

  Result<void> _parseVoid(Result<Object?> response) {
    response = _unwrap(response);
    if (response case Success()) {
      return const Success(null);
    }
    return FailureResult(
      response.failureOrNull ??
          const AppFailure(
            kind: FailureKind.business,
            code: 'bms.error',
            safeMessage: '操作失败',
          ),
    );
  }

  Result<Object?> _unwrap(Result<Object?> response) {
    if (response case Success(:final value)) {
      if (value is Map<String, Object?> && value.containsKey('code')) {
        if (value['code'] != 1 && value['code'] != '1') {
          return const FailureResult(
            AppFailure(
              kind: FailureKind.business,
              code: 'bms.rejected',
              safeMessage: '服务端拒绝操作，请检查后重试',
            ),
          );
        }
        return Success(value['data']);
      }
    }
    return response;
  }
}
