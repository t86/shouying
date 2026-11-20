import 'package:card_table/src/erp_models.dart';
import 'package:card_table/src/erp_sout_workflow.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

/// ERP 仓库系统协议调用实现
final class ProtocolErpApi {
  const ProtocolErpApi({
    required this.client,
    this.clientKind = ClientKind.erpAdmin,
  });

  final ProtocolClient client;
  final ClientKind clientKind;

  Future<Result<Map<String, Object?>>> _post(
    String path, [
    Map<String, Object?> body = const <String, Object?>{},
  ]) => client.post(path, body: body, client: clientKind);

  Result<List<T>> _parseList<T>(
    Result<Map<String, Object?>> response,
    T Function(Map<String, Object?>) mapper,
  ) {
    if (_businessFailure(response) case final failure?) {
      return FailureResult(failure);
    }
    if (response case Success(:final value)) {
      Object? target = value;
      if (value['data'] is Map) {
        target = value['data'];
      }
      Object? items;
      if (target is Map) {
        items =
            target['records'] ??
            target['datas'] ??
            target['items'] ??
            target['list'] ??
            target['rows'] ??
            target['data'];
      }
      items ??= target;
      if (items is List) {
        return Success(
          items
              .whereType<Map>()
              .map((it) => mapper(Map<String, Object?>.from(it)))
              .toList(),
        );
      }
      return const Success(<Never>[]);
    }
    return FailureResult(
      response.failureOrNull ??
          const AppFailure(
            kind: FailureKind.network,
            code: 'erp.error',
            safeMessage: '网络或服务异常',
          ),
    );
  }

  Result<bool> _parseSuccess(Result<Map<String, Object?>> response) {
    if (_businessFailure(response) case final failure?) {
      return FailureResult(failure);
    }
    if (response case Success()) {
      return const Success(true);
    }
    return FailureResult(
      response.failureOrNull ??
          const AppFailure(
            kind: FailureKind.business,
            code: 'erp.error',
            safeMessage: '操作失败',
          ),
    );
  }

  AppFailure? _businessFailure(Result<Map<String, Object?>> response) {
    final value = response.valueOrNull;
    if (value != null && value['code'] != 1 && value['code'] != '1') {
      return const AppFailure(
        kind: FailureKind.business,
        code: 'erp.rejected',
        safeMessage: '服务端拒绝操作，请检查输入后重试',
      );
    }
    return response.failureOrNull;
  }

  // ---------------------------------------------------------------------------
  // S8.P1 主数据 API
  // ---------------------------------------------------------------------------

  /// 首页物料负库存预警列表 (POST /rpt_erp/get_neg_stores)
  Future<Result<List<ErpNegStoreAlert>>> getNegStoreAlerts() async {
    final res = await _post('/rpt_erp/get_neg_stores');
    return _parseList(res, ErpNegStoreAlert.fromWire);
  }

  /// 首页未对照售出收银商品预警列表 (POST /prd/get_tobind_prds)
  Future<Result<List<ErpUnboundPrdAlert>>> getUnboundPrdAlerts() async {
    final res = await _post('/prd/get_tobind_prds', const <String, Object?>{
      'page_num': 1,
      'page_size': 50,
    });
    return _parseList(res, ErpUnboundPrdAlert.fromWire);
  }

  /// 仓库列表 (POST /store/list)
  Future<Result<List<ErpStoreItem>>> getStoreList() async {
    final res = await _post('/store/list');
    return _parseList(res, ErpStoreItem.fromWire);
  }

  /// 保存仓库 (POST /store/save 或 /store/new)
  Future<Result<bool>> saveStore(ErpStoreItem item) async {
    final path = item.id.isEmpty ? '/store/new' : '/store/save';
    final res = await _post(path, item.toWire());
    return _parseSuccess(res);
  }

  /// 启用/停用仓库 (POST /store/enable, /store/disable)
  Future<Result<bool>> toggleStoreStatus(String storeId, bool enable) async {
    final path = enable ? '/store/enable' : '/store/disable';
    final res = await _post(path, <String, Object?>{'id': storeId});
    return _parseSuccess(res);
  }

  /// 删除仓库 (POST /store/del)
  Future<Result<bool>> deleteStore(String storeId) async {
    final res = await _post('/store/del', <String, Object?>{'id': storeId});
    return _parseSuccess(res);
  }

  /// 物料分类树 (POST /mat/cate_list)
  Future<Result<List<ErpMatCate>>> getMatCateList() async {
    final res = await _post('/mat/cate_list');
    return _parseList(res, ErpMatCate.fromWire);
  }

  /// 物料列表 (POST /mat/list)
  Future<Result<List<ErpMatItem>>> getMatList({
    String? oneCateId,
    String? twoCateId,
    String? keyword,
  }) async {
    final res = await _post('/mat/list', <String, Object?>{
      if (oneCateId != null && oneCateId.isNotEmpty) 'one_cate_id': oneCateId,
      if (twoCateId != null && twoCateId.isNotEmpty) 'two_cate_id': twoCateId,
      if (keyword != null && keyword.isNotEmpty) 'kw': keyword,
    });
    return _parseList(res, ErpMatItem.fromWire);
  }

  /// 保存物料 (POST /mat/save 或 /mat/new)
  Future<Result<bool>> saveMat(ErpMatItem item) async {
    final path = item.id.isEmpty ? '/mat/new' : '/mat/save';
    final res = await _post(path, item.toWire());
    return _parseSuccess(res);
  }

  /// 启用/停用物料 (POST /mat/enable, /mat/disable)
  Future<Result<bool>> toggleMatStatus(String matId, bool enable) async {
    final path = enable ? '/mat/enable' : '/mat/disable';
    final res = await _post(path, <String, Object?>{'id': matId});
    return _parseSuccess(res);
  }

  /// 删除物料 (POST /mat/del)
  Future<Result<bool>> deleteMat(String matId) async {
    final res = await _post('/mat/del', <String, Object?>{'id': matId});
    return _parseSuccess(res);
  }

  /// 商品对照列表 (1: tobind, 2: binded, 3: cant_bind)
  Future<Result<List<ErpComparePrdItem>>> getComparePrdList(int type) async {
    final path = switch (type) {
      1 => '/prd/get_tobind_prds',
      2 => '/prd/get_binded_prds',
      _ => '/prd/get_un_bind_prds',
    };
    final res = await _post(path, const <String, Object?>{
      'page_num': 1,
      'page_size': 100,
    });
    return _parseList(res, ErpComparePrdItem.fromWire);
  }

  /// 绑定商品与物料 (POST /prd/bind_mat)
  Future<Result<bool>> bindMatPrd({
    required String prdId,
    required String matId,
  }) async {
    final res = await _post('/prd/bind_mat', <String, Object?>{
      'prd_id': prdId,
      'mat_id': matId,
    });
    return _parseSuccess(res);
  }

  /// 批量关闭商品关联 (POST /prd/batch_close_bind)
  Future<Result<bool>> closeBindPrds(List<String> prdIds) async {
    final res = await _post('/prd/batch_close_bind', <String, Object?>{
      'ids': prdIds,
    });
    return _parseSuccess(res);
  }

  /// 供应商列表 (POST /supplier/list)
  Future<Result<List<ErpSupplierItem>>> getSupplierList() async {
    final res = await _post('/supplier/list');
    return _parseList(res, ErpSupplierItem.fromWire);
  }

  /// 保存供应商 (POST /supplier/save 或 /supplier/new)
  Future<Result<bool>> saveSupplier(ErpSupplierItem item) async {
    final path = item.id.isEmpty ? '/supplier/new' : '/supplier/save';
    final res = await _post(path, item.toWire());
    return _parseSuccess(res);
  }

  /// 启用/停用供应商 (POST /supplier/enable, /supplier/disable)
  Future<Result<bool>> toggleSupplierStatus(
    String supplierId,
    bool enable,
  ) async {
    final path = enable ? '/supplier/enable' : '/supplier/disable';
    final res = await _post(path, <String, Object?>{'id': supplierId});
    return _parseSuccess(res);
  }

  /// 删除供应商 (POST /supplier/del)
  Future<Result<bool>> deleteSupplier(String supplierId) async {
    final res = await _post('/supplier/del', <String, Object?>{
      'id': supplierId,
    });
    return _parseSuccess(res);
  }

  // ---------------------------------------------------------------------------
  // S8.P2 入库 API
  // ---------------------------------------------------------------------------

  /// 其他入库单列表 (POST /sin/list)
  Future<Result<List<ErpSinItem>>> getSinList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async {
    final res = await _post('/sin/list', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
      if (status != null) 'status': status,
    });
    return _parseList(res, ErpSinItem.fromWire);
  }

  /// 入库物料检索 (POST /sin/mat_items)
  Future<Result<List<ErpMatItem>>> getSinMatItems(String keyword) async {
    final res = await _post('/sin/mat_items', <String, Object?>{
      'name': keyword,
      'page_num': 1,
      'page_size': 9999999,
    });
    return _parseList(res, ErpMatItem.fromWire);
  }

  /// 新建其他入库单 (POST /sin/new)
  Future<Result<ErpStockOptions>> getSinOptions() async {
    final result = await client.postWithoutBody(
      '/sin/new_sin_items',
      client: clientKind,
    );
    if (_businessFailure(result) case final failure?) {
      return FailureResult(failure);
    }
    final data = result.valueOrNull?['data'];
    if (data is! Map<String, Object?>) {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.protocol,
          code: 'erp.options_invalid',
          safeMessage: '仓库和供应商数据无法识别，请重试',
        ),
      );
    }
    return Success(ErpStockOptions.fromWire(data));
  }

  Future<Result<List<ErpStoreItem>>> getSoutStores() async => _parseList(
    await client.postWithoutBody('/sout/store_items', client: clientKind),
    ErpStoreItem.fromWire,
  );

  Future<Result<List<ErpStockMaterial>>> getStockMaterialItems({
    required bool outgoing,
    required String keyword,
    String storeId = '',
  }) async => _parseList(
    await _post(outgoing ? '/sout/mat_items' : '/sin/mat_items', {
      if (outgoing) 'store_id': int.parse(storeId),
      'name': keyword,
      'page_num': 1,
      'page_size': 9999999,
    }),
    ErpStockMaterial.fromWire,
  );

  Future<Result<bool>> createSinOrder(Map<String, Object?> payload) async {
    final res = await _post('/sin/new', payload);
    return _parseSuccess(res);
  }

  /// 其他入库反审核 (POST /sin/cs)
  Future<Result<bool>> reverseSinOrder(String billId) async {
    final res = await _post('/sin/cs', <String, Object?>{
      'id': billId,
      'record_type': 7,
    });
    return _parseSuccess(res);
  }

  /// 其他入库红冲 (POST /sin/hc)
  Future<Result<bool>> redPunchSinOrder(String billId) async {
    final res = await _post('/sin/hc', <String, Object?>{'id': billId});
    return _parseSuccess(res);
  }

  /// 调拨入库单列表 (POST /sind/list)
  Future<Result<List<ErpSindItem>>> getSindList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async {
    final res = await _post('/sind/list', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
      if (status != null) 'status': status,
    });
    return _parseList(res, ErpSindItem.fromWire);
  }

  /// 批量调拨入库 (POST /sind/batch_in)
  Future<Result<bool>> batchSindIn(List<String> billIds) async {
    final res = await _post('/sind/batch_in', <String, Object?>{
      'ids': billIds,
    });
    return _parseSuccess(res);
  }

  /// 部分调拨入库 (POST /sind/one_part_in)
  Future<Result<bool>> partSindIn(Map<String, Object?> payload) async {
    final res = await _post('/sind/one_part_in', payload);
    return _parseSuccess(res);
  }

  /// 调拨入库异议申请 (POST /sind/sh)
  Future<Result<bool>> applySindSh(Map<String, Object?> payload) async {
    final res = await _post('/sind/sh', payload);
    return _parseSuccess(res);
  }

  /// 入库异议单列表 (POST /d_yy/in_list)
  Future<Result<List<ErpDisputeItem>>> getDisputeInList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async {
    final res = await _post('/d_yy/in_list', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
      if (status != null) 'status': status,
    });
    return _parseList(res, ErpDisputeItem.fromWire);
  }

  /// 确认入库异议单 (POST /d_yy/in_confirm)
  Future<Result<bool>> confirmDisputeIn(String disputeId) async {
    final res = await _post('/d_yy/in_confirm', <String, Object?>{
      'id': disputeId,
    });
    return _parseSuccess(res);
  }

  /// 撤销入库异议单 (POST /d_yy/in_cancel)
  Future<Result<bool>> cancelDisputeIn(String disputeId) async {
    final res = await _post('/d_yy/in_cancel', <String, Object?>{
      'id': disputeId,
    });
    return _parseSuccess(res);
  }

  /// 驳回入库异议单 (POST /d_yy/in_back)
  Future<Result<bool>> rejectDisputeIn(String disputeId) async {
    final res = await _post('/d_yy/in_back', <String, Object?>{
      'id': disputeId,
    });
    return _parseSuccess(res);
  }

  // ---------------------------------------------------------------------------
  // S8.P3 出库 API
  // ---------------------------------------------------------------------------

  /// 其他出库单列表 (POST /sout/list)
  Future<Result<Map<String, Object?>>> _soutData(
    String path,
    Map<String, Object?> body,
  ) async {
    final result = await _post(path, body);
    if (_businessFailure(result) case final f?) return FailureResult(f);
    final data = result.valueOrNull?['data'];
    if (data is! Map)
      return const FailureResult(
        AppFailure(
          kind: FailureKind.protocol,
          code: 'erp.sout_shape',
          safeMessage: '出库数据无法识别',
        ),
      );
    return Success(Map<String, Object?>.from(data));
  }

  Future<Result<ErpSoutPage>> getOtherOutPage({
    required String beginDay,
    required String endDay,
    int recordType = 0,
    String remark = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _soutData('/sout/list', {
      'begin_day': beginDay,
      'end_day': endDay,
      'remark': remark,
      'record_type': recordType,
      'page_num': page,
      'page_size': pageSize,
    });
    if (result.failureOrNull case final f?) return FailureResult(f);
    try {
      final data = result.valueOrNull!,
          total = int.tryParse('${result.valueOrNull!['row_cnt'] ?? 0}');
      if (total == null || total < 0) throw const FormatException();
      return Success(ErpSoutPage(erpSoutRows(data['datas']), total));
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.protocol,
          code: 'erp.sout_shape',
          safeMessage: '出库列表无法识别',
        ),
      );
    }
  }

  Future<Result<ErpSoutDocument>> getOtherOutDocument(
    String id,
    ErpSoutDocumentMode mode,
  ) async {
    final number = int.tryParse(id);
    if (number == null || number <= 0)
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'erp.sout_id',
          safeMessage: '请选择有效出库单',
        ),
      );
    final result = await _soutData(
      '/sout/${switch (mode) {
        ErpSoutDocumentMode.copy => 'get_f_copy',
        ErpSoutDocumentMode.view => 'get_f_view',
        ErpSoutDocumentMode.reversal => 'get_f_hc',
      }}',
      {'id': number},
    );
    if (result.failureOrNull case final f?) return FailureResult(f);
    try {
      final document = ErpSoutDocument(result.valueOrNull!, mode);
      document.lines;
      return Success(document);
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.protocol,
          code: 'erp.sout_shape',
          safeMessage: '出库明细无法识别',
        ),
      );
    }
  }

  Future<Result<bool>> reverseOtherOutWhole(String id) async {
    final number = int.tryParse(id);
    if (number == null || number <= 0)
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'erp.sout_id',
          safeMessage: '请选择有效出库单',
        ),
      );
    return _parseSuccess(await _post('/sout/cs', {'id': number}));
  }

  Future<Result<bool>> reverseOtherOutLines(Map<int, double> counts) async {
    if (counts.isEmpty ||
        counts.entries.any(
          (e) => e.key <= 0 || !e.value.isFinite || e.value <= 0,
        ))
      return const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'erp.sout_counts',
          safeMessage: '请输入有效红冲数量',
        ),
      );
    return _parseSuccess(
      await _post('/sout/hc', {
        'dtl_ids': counts.keys.toList(),
        'cnts': counts.values.toList(),
      }),
    );
  }

  Future<Result<List<ErpSoutItem>>> getSoutList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async {
    final res = await _post('/sout/list', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
      if (status != null) 'status': status,
    });
    return _parseList(res, ErpSoutItem.fromWire);
  }

  /// 新建其他出库单 (POST /sout/new)
  Future<Result<bool>> createSoutOrder(Map<String, Object?> payload) async {
    final res = await _post('/sout/new', payload);
    return _parseSuccess(res);
  }

  /// 其他出库反审核 (POST /sout/cs)
  Future<Result<bool>> reverseSoutOrder(String billId) async {
    return reverseOtherOutWhole(billId);
  }

  /// 其他出库红冲 (POST /sout/hc)
  Future<Result<bool>> redPunchSoutOrder(String billId) async {
    return const FailureResult(
      AppFailure(
        kind: FailureKind.business,
        code: 'erp.sout_details_required',
        safeMessage: '请选择出库明细及红冲数量',
      ),
    );
  }

  /// 调拨出库单列表 (POST /soutd/list)
  Future<Result<List<ErpSoutdItem>>> getSoutdList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async {
    final res = await _post('/soutd/list', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
      if (status != null) 'status': status,
    });
    return _parseList(res, ErpSoutdItem.fromWire);
  }

  /// 新建调拨出库单 (POST /soutd/new)
  Future<Result<bool>> createSoutdOrder(Map<String, Object?> payload) async {
    final res = await _post('/soutd/new', payload);
    return _parseSuccess(res);
  }

  /// 调拨出库反审核 (POST /soutd/cs)
  Future<Result<bool>> reverseSoutdOrder(String billId) async {
    final res = await _post('/soutd/cs', <String, Object?>{
      'id': billId,
      'record_type': 3,
    });
    return _parseSuccess(res);
  }

  /// 调拨出库红冲 (POST /soutd/hc)
  Future<Result<bool>> redPunchSoutdOrder(String billId) async {
    final res = await _post('/soutd/hc', <String, Object?>{'id': billId});
    return _parseSuccess(res);
  }

  /// 出库异议单列表 (POST /d_yy/out_list)
  Future<Result<List<ErpDisputeItem>>> getDisputeOutList({
    String? beginDay,
    String? endDay,
    int? status,
  }) async {
    final res = await _post('/d_yy/out_list', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
      if (status != null) 'status': status,
    });
    return _parseList(res, ErpDisputeItem.fromWire);
  }

  /// 驳回出库异议单 (POST /d_yy/out_back)
  Future<Result<bool>> rejectDisputeOut(String disputeId) async {
    final res = await _post('/d_yy/out_back', <String, Object?>{
      'id': disputeId,
    });
    return _parseSuccess(res);
  }

  /// 红冲出库异议单 (POST /d_yy/out_hc)
  Future<Result<bool>> redPunchDisputeOut(String disputeId) async {
    final res = await _post('/d_yy/out_hc', <String, Object?>{'id': disputeId});
    return _parseSuccess(res);
  }

  /// 报损出库异议单 (POST /d_yy/out_bs)
  Future<Result<bool>> breakLossDisputeOut(String disputeId) async {
    final res = await _post('/d_yy/out_bs', <String, Object?>{'id': disputeId});
    return _parseSuccess(res);
  }

  // ---------------------------------------------------------------------------
  // S8.P4 空瓶 API
  // ---------------------------------------------------------------------------

  /// 空瓶入库单列表 (POST /rtn_bt/get_in_list)
  Future<Result<List<ErpEmptyInItem>>> getEmptyInList({
    String? beginDay,
    String? endDay,
  }) async {
    final res = await _post('/rtn_bt/get_in_list', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
    });
    return _parseList(res, ErpEmptyInItem.fromWire);
  }

  /// 确认空瓶入库单 (POST /rtn_bt/confirm_rtn_bt_in)
  Future<Result<bool>> confirmEmptyIn(String billId) async {
    final res = await _post('/rtn_bt/confirm_rtn_bt_in', <String, Object?>{
      'id': billId,
    });
    return _parseSuccess(res);
  }

  /// 红冲空瓶入库单 (POST /rtn_bt/hc_rtn_bt_in)
  Future<Result<bool>> redPunchEmptyIn(String billId) async {
    final res = await _post('/rtn_bt/hc_rtn_bt_in', <String, Object?>{
      'id': billId,
    });
    return _parseSuccess(res);
  }

  /// 空瓶仓库存列表 (POST /rtn_bt/get_rtn_bt_invt)
  Future<Result<List<ErpEmptyInvtItem>>> getEmptyInvtList({
    String? keyword,
  }) async {
    final res = await _post('/rtn_bt/get_rtn_bt_invt', <String, Object?>{
      if (keyword != null && keyword.isNotEmpty) 'kw': keyword,
    });
    return _parseList(res, ErpEmptyInvtItem.fromWire);
  }

  /// 空瓶出库保存 (POST /rtn_bt/invt_rtn_bt_out)
  Future<Result<bool>> submitEmptyOut(Map<String, Object?> payload) async {
    final res = await _post('/rtn_bt/invt_rtn_bt_out', payload);
    return _parseSuccess(res);
  }

  /// 空瓶出库单列表 (POST /rtn_bt/get_rtn_bt_out_list)
  Future<Result<List<ErpEmptyOutItem>>> getEmptyOutList({
    String? beginDay,
    String? endDay,
  }) async {
    final res = await _post('/rtn_bt/get_rtn_bt_out_list', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
    });
    return _parseList(res, ErpEmptyOutItem.fromWire);
  }

  /// 红冲空瓶出库单 (POST /rtn_bt/hc_rtn_bt_out)
  Future<Result<bool>> redPunchEmptyOut(String billId) async {
    final res = await _post('/rtn_bt/hc_rtn_bt_out', <String, Object?>{
      'id': billId,
    });
    return _parseSuccess(res);
  }

  // ---------------------------------------------------------------------------
  // S8.P5 报表 API
  // ---------------------------------------------------------------------------

  Future<Result<ErpReportParams>> readReportOptions({
    required bool Function() canDispatch,
  }) async {
    final result = await client.postWithoutBody(
      '/rpt_erp/param_items',
      client: clientKind,
      canDispatch: canDispatch,
    );
    if (_businessFailure(result) case final failure?)
      return FailureResult(failure);
    final data = result.valueOrNull?['data'];
    if (data is! Map)
      return const FailureResult(
        AppFailure(
          kind: FailureKind.protocol,
          code: 'erp.report_options_invalid',
          safeMessage: '报表筛选项读取失败',
        ),
      );
    return Success(ErpReportParams.fromWire(Map<String, Object?>.from(data)));
  }

  Future<Result<ErpReportPage>> readReport(
    ErpReportQuery query, {
    required bool Function() canDispatch,
  }) async {
    try {
      final result = await client.post(
        query.kind.readPath,
        body: query.toWire(),
        client: clientKind,
        canDispatch: canDispatch,
      );
      if (_businessFailure(result) case final failure?)
        return FailureResult(failure);
      final envelope = result.valueOrNull;
      if (envelope == null) return FailureResult(result.failureOrNull!);
      final data = envelope['data'];
      final summary =
          query.kind == ErpReportKind.inSummary ||
          query.kind == ErpReportKind.outSummary;
      // The two summary endpoints return data directly (Vue: res.data || []).
      // Detail endpoints instead use data.datas; other reports use records.
      if (!summary && data is! Map) throw const FormatException();
      final raw = summary
          ? data ?? const []
          : (data as Map)[query.kind.detailed ? 'datas' : 'records'];
      if (raw is! List || raw.any((row) => row is! Map)) {
        throw const FormatException();
      }
      final total = query.kind.paginated
          ? int.tryParse('${(data as Map)['row_cnt'] ?? 0}')
          : raw.length;
      if (total == null || total < 0) throw const FormatException();
      return Success(
        ErpReportPage(
          rows: [for (final row in raw) Map<String, Object?>.from(row as Map)],
          total: total,
          options: query.kind == ErpReportKind.materialNow
              ? ErpReportParams.fromWire(Map<String, Object?>.from(data as Map))
              : const ErpReportParams(),
        ),
      );
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.protocol,
          code: 'erp.report_invalid',
          safeMessage: '报表数据或筛选参数无效，请重新查询',
        ),
      );
    }
  }

  Future<Result<ProtocolBinaryFile>> exportReport(
    ErpReportQuery query, {
    required bool Function() canDispatch,
  }) async {
    try {
      return await client.postBinary(
        query.kind.exportPath,
        body: query.toWire(export: true),
        client: clientKind,
        fallbackFileName: '${query.kind.title}.xlsx',
        canDispatch: canDispatch,
      );
    } on Object {
      return const FailureResult(
        AppFailure(
          kind: FailureKind.protocol,
          code: 'erp.export_invalid',
          safeMessage: '导出筛选参数无效，请重新查询',
        ),
      );
    }
  }

  /// 报表通用下拉参数 (POST /rpt_erp/param_items)
  Future<Result<ErpReportParams>> getReportParams() async {
    final res = await _post('/rpt_erp/param_items');
    if (res case Success(:final value)) {
      final data = (value['data'] is Map) ? value['data'] as Map : value;
      return Success(ErpReportParams.fromWire(Map<String, Object?>.from(data)));
    }
    return FailureResult(
      res.failureOrNull ??
          const AppFailure(
            kind: FailureKind.network,
            code: 'erp.error',
            safeMessage: '获取报表参数失败',
          ),
    );
  }

  /// 物料实时库存表 (POST /rpt_erp/get_now_mat_invt)
  Future<Result<List<ErpMatNowInvtItem>>> getMatNowInvt({
    String? storeId,
    String? keyword,
  }) async {
    final res = await _post('/rpt_erp/get_now_mat_invt', <String, Object?>{
      if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
      if (keyword != null && keyword.isNotEmpty) 'kw': keyword,
    });
    return _parseList(res, ErpMatNowInvtItem.fromWire);
  }

  /// 物料月度库存表 (POST /rpt_erp/get_mat_invt)
  Future<Result<List<ErpMatMonthInvtItem>>> getMatMonthInvt({
    String? storeId,
    String? month,
  }) async {
    final res = await _post('/rpt_erp/get_mat_invt', <String, Object?>{
      if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
      if (month != null && month.isNotEmpty) 'month': month,
    });
    return _parseList(res, ErpMatMonthInvtItem.fromWire);
  }

  /// 出入库明细-入库记录 (POST /rpt_erp/in_recs)
  Future<Result<List<ErpInOutRecItem>>> getInRecs({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) async {
    final res = await _post('/rpt_erp/in_recs', <String, Object?>{
      if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
    });
    return _parseList(res, ErpInOutRecItem.fromWire);
  }

  /// 出入库明细-出库记录 (POST /rpt_erp/out_recs)
  Future<Result<List<ErpInOutRecItem>>> getOutRecs({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) async {
    final res = await _post('/rpt_erp/out_recs', <String, Object?>{
      if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
    });
    return _parseList(res, ErpInOutRecItem.fromWire);
  }

  /// 出入库汇总-入库汇总 (POST /rpt_erp/in_sum)
  Future<Result<List<ErpInOutSumItem>>> getInSum({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) async {
    final res = await _post('/rpt_erp/in_sum', <String, Object?>{
      if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
    });
    return _parseList(res, ErpInOutSumItem.fromWire);
  }

  /// 出入库汇总-出库汇总 (POST /rpt_erp/out_sum)
  Future<Result<List<ErpInOutSumItem>>> getOutSum({
    String? storeId,
    String? beginDay,
    String? endDay,
  }) async {
    final res = await _post('/rpt_erp/out_sum', <String, Object?>{
      if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
    });
    return _parseList(res, ErpInOutSumItem.fromWire);
  }

  /// 仓库进销存表 (POST /rpt_erp/get_store_invt_reps)
  Future<Result<List<ErpPsiItem>>> getStorePsi({
    String? storeId,
    String? date,
  }) async {
    final res = await _post('/rpt_erp/get_store_invt_reps', <String, Object?>{
      if (storeId != null && storeId.isNotEmpty) 'store_id': storeId,
      if (date != null) 'date': date,
    });
    return _parseList(res, ErpPsiItem.fromWire);
  }

  /// 空瓶出入库明细-入库记录 (POST /rtn_bt/get_rtn_bt_in_opers)
  Future<Result<List<ErpEmptyOperItem>>> getEmptyInOperList({
    String? beginDay,
    String? endDay,
  }) async {
    final res = await _post('/rtn_bt/get_rtn_bt_in_opers', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
    });
    return _parseList(res, ErpEmptyOperItem.fromWire);
  }

  /// 空瓶出入库明细-出库记录 (POST /rtn_bt/get_rtn_bt_out_opers)
  Future<Result<List<ErpEmptyOperItem>>> getEmptyOutOperList({
    String? beginDay,
    String? endDay,
  }) async {
    final res = await _post('/rtn_bt/get_rtn_bt_out_opers', <String, Object?>{
      if (beginDay != null) 'begin_day': beginDay,
      if (endDay != null) 'end_day': endDay,
    });
    return _parseList(res, ErpEmptyOperItem.fromWire);
  }
}
