import 'package:card_table/src/wine_models.dart';
import 'package:card_table/src/wine_pending_get.dart';
import 'package:card_table/src/wine_save_edit.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

final class ProtocolWineApi {
  const ProtocolWineApi({required this.client});
  final ProtocolClient client;

  // ---------------------------------------------------------------------------
  // S5.P1 存酒待入库
  // ---------------------------------------------------------------------------

  Future<Result<List<WineSaveRecord>>> getSaveNeedToLib(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_cj_bef_in',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseList(response, WineSaveRecord.fromWire);
  }

  Future<Result<WineSaveEditContext>> getSaveEditContext(ClientKind client) async {
    final result = _parseMap(await this.client.post('/wine/get_cj_bef_in', body: {'key':''}, client:client));
    if (result.failureOrNull case final f?) return FailureResult(f);
    try {
      final map = result.valueOrNull!;
      final rows = map['records'] as List? ?? [];
      return Success(WineSaveEditContext([for(final row in rows) WineSaveEditRecord.fromWire(row as Map)],
        switch('${map['need_waiter_auth']}') { '1'=>true, '2'=>false, _=>null }));
    } on Object { return _shapeFail(); }
  }

  Future<Result<List<Map<String,Object?>>>> getSaveEditSeats(ClientKind client,{String? day}) async {
    final result = _parseMap(await this.client.post(day==null?'/wine/get_kf_seat_items':'/wo/get_relate_seat_items',
      body:day==null?<String,Object?>{}:{'biz_day':day},client:client));
    if(result.failureOrNull case final f?) return FailureResult(f);
    try {
      final map=result.valueOrNull!;
      final seats=<Map<String,Object?>>[];
      if(day==null) {
        for(final item in (map['seats'] as List? ?? [])) {
          final row=Map<String,Object?>.from(item as Map);
          seats.add({...row,'n':row['s']});
        }
      } else {
        for(final region in (map['regions'] as List? ?? [])) {
          for(final item in ((region as Map)['ss'] as List? ?? [])) {
            final row=Map<String,Object?>.from(item as Map);
            if('${row['b']}'!='2') seats.add(row);
          }
        }
      }
      if(seats.any((r)=>(int.tryParse('${r['id']}')??0)<=0 || r['n'] is! String)) return _shapeFail();
      return Success(seats);
    } on Object { return _shapeFail(); }
  }

  Future<Result<List<Map<String,Object?>>>> getSaveEditOrders(ClientKind client,String day,int seatId) async =>
    _parseRawList(await this.client.post('/wo/get_relate_seat_csm_items',
      body:{'biz_day':day,'seat_id':seatId},client:client));

  Future<Result<void>> confirmSaveNeedToLib(
    ClientKind client, {
    required List<String> ids,
  }) async {
    final response = await this.client.post(
      '/wine/confirm_cj_bef_in',
      body: <String, Object?>{'ids': ids.map(_jsonId).toList()},
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> backSaveNeedToLib(
    ClientKind client, {
    required List<String> ids,
    String reason = '',
  }) async {
    final response = await this.client.post(
      '/wine/back_cj_bef_in',
      body: <String, Object?>{
        'ids': ids.map(_jsonId).toList(),
        if (reason.isNotEmpty) 'reason': reason,
      },
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> chgSaveNeedToLib(
    ClientKind client, {
    required Map<String, Object?> fields,
  }) async {
    if (!validWineSaveEditBody(fields)) return const FailureResult(AppFailure(kind:FailureKind.business,code:'wine.invalid_save_edit',safeMessage:'存酒改单信息不完整，请重新编辑'));
    final response = await this.client.post(
      '/wine/chg_cj_bef_in',
      body: fields,
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<List<Map<String, Object?>>>> getChgSalesEmpList(
    ClientKind client,
  ) async {
    final response = await this.client.post(
      '/wine/get_chg_sales_emp_list',
      body: const <String, Object?>{},
      client: client,
    );
    return _parseRawList(response);
  }

  // ---------------------------------------------------------------------------
  // S5.P2 取酒待出库
  // ---------------------------------------------------------------------------

  Future<Result<List<WineGetRecord>>> getNeedToLib(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_qj_bef_out',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseList(response, WineGetRecord.fromWire);
  }

  Future<Result<WinePendingGetContext>> getPendingGetContext(
    ClientKind client, {String keyword = ''}
  ) async {
    final response = _parseMap(await this.client.post('/wine/get_qj_bef_out',
      body: {'key': keyword}, client: client));
    if (response.failureOrNull case final failure?) return FailureResult(failure);
    try {
      return Success(WinePendingGetContext.fromWire(response.valueOrNull!));
    } on FormatException {
      return _shapeFail();
    }
  }

  Future<Result<List<WineGetSubItem>>> getPendingGetInventory(
    ClientKind client, {required String phone}
  ) async {
    final response = _parseMap(await this.client.post('/wine/get_qj_invt',
      body: {'phone_num': phone, 'key': ''}, client: client));
    if (response.failureOrNull case final failure?) return FailureResult(failure);
    final records = response.valueOrNull!['records'];
    if (records != null && (records is! List || records.any((row) => row is! Map))) return _shapeFail();
    final items = <WineGetSubItem>[];
    for (final row in (records as List? ?? [])) {
      final map = Map<Object?, Object?>.from(row as Map);
      final id = int.tryParse('${map['id']}');
      final count = int.tryParse('${map['c']}');
      if (id == null || id <= 0 || count == null || count < 0) return _shapeFail();
      items.add(WineGetSubItem(id: '$id', name: '${map['n'] ?? ''}', unit: '${map['u'] ?? ''}',
        count: count, gram: '${map['g'] ?? ''}', expireTime: '${map['e'] ?? ''}'));
    }
    if (items.map((e) => e.id).toSet().length != items.length) return _shapeFail();
    return Success(items);
  }

  Future<Result<void>> confirmGetNeedToLib(
    ClientKind client, {
    required List<String> ids,
  }) async {
    final response = await this.client.post(
      '/wine/confirm_qj_bef_out',
      body: <String, Object?>{'ids': ids.map(_jsonId).toList()},
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> backGetNeedToLib(
    ClientKind client, {
    required List<String> ids,
    String reason = '',
  }) async {
    final response = await this.client.post(
      '/wine/back_qj_bef_out',
      body: <String, Object?>{
        'bef_out_ids': ids.map(_jsonId).toList(),
      },
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> confirmAuthGetNeedToLib(
    ClientKind client, {
    required Map<String, Object?> fields,
  }) async {
    final response = await this.client.post(
      '/wine/confirm_auth_qj_bef_out',
      body: fields,
      client: client,
    );
    return _parseVoid(response);
  }

  // ---------------------------------------------------------------------------
  // S5.P3 存酒库 & S5.P4 存酒库子订单
  // ---------------------------------------------------------------------------

  Future<Result<List<WineInventoryItem>>> getSaveLibList(
    ClientKind client, {
    String startDate = '',
    String endDate = '',
    int daysLeft = 0,
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_wine_invt',
      body: <String, Object?>{
        if (startDate.isNotEmpty) 'start_day': startDate,
        if (endDate.isNotEmpty) 'end_day': endDate,
        if (daysLeft > 0) 'day_val': daysLeft,
        'key': keyword,
      },
      client: client,
    );
    return _parseList(response, WineInventoryItem.fromWire);
  }

  Future<Result<void>> delayWineInvt(
    ClientKind client, {
    required String id,
    required int days,
    String reason = '',
  }) async {
    final response = await this.client.post(
      '/wine/delay_wine_invt2',
      body: <String, Object?>{
        'id': _jsonId(id),
        'day': days,
        if (reason.isNotEmpty) 'reason': reason,
      },
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> cgWineInvt(
    ClientKind client, {
    required List<String> ids,
  }) async {
    final response = await this.client.post(
      '/wine/cg_wine_invt',
      body: <String, Object?>{'ids': ids.map(_jsonId).toList()},
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<List<WineInventoryItem>>> getSaveLibChildList(
    ClientKind client, {
    String startDate = '',
    String endDate = '',
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/rpt/get_wine_invt_sub_order',
      body: <String, Object?>{
        if (startDate.isNotEmpty) 'start_day': startDate,
        if (endDate.isNotEmpty) 'end_day': endDate,
        'key': keyword,
      },
      client: client,
    );
    return _parseList(response, WineInventoryItem.fromWire);
  }

  // ---------------------------------------------------------------------------
  // S5.P5 过期待处理 & S5.P6 存酒库库存
  // ---------------------------------------------------------------------------

  Future<Result<List<WineInventoryItem>>> getPassTimeNeedToLib(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_wine_invt_expired',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseList(response, WineInventoryItem.fromWire);
  }

  Future<Result<void>> cgExpiredWineInvt(
    ClientKind client, {
    required List<String> ids,
  }) async {
    final response = await this.client.post(
      '/wine/cg_expired_wine_invt',
      body: <String, Object?>{'ids': ids.map(_jsonId).toList()},
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> delayExpiredWineInvt(
    ClientKind client, {
    required String id,
    required int days,
    String reason = '',
  }) async {
    final response = await this.client.post(
      '/wine/delay_wine_invt',
      body: <String, Object?>{
        'id': _jsonId(id),
        'day': days,
        if (reason.isNotEmpty) 'reason': reason,
      },
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<List<WineGridItem>>> getSaveLibGrid(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_wine_invt_grid',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseList(response, WineGridItem.fromWire);
  }

  Future<Result<List<WineInventoryItem>>> getSaveLibGridDetail(
    ClientKind client, {
    required String prdId,
  }) async {
    final response = await this.client.post(
      '/wine/get_wine_invt_grid_dtl',
      body: <String, Object?>{'prd_id': _jsonId(prdId)},
      client: client,
    );
    return _parseList(response, WineInventoryItem.fromWire);
  }

  Future<Result<ProtocolBinaryFile>> exportWineInvtExpired(
    ClientKind client, {
    String keyword = '',
    int ordType = 1,
    bool Function()? canDispatch,
  }) async {
    return this.client.postBinary(
      '/wine/rpt/exp_wine_invt_expired',
      fallbackFileName: '过期存酒.xlsx',
      canDispatch: canDispatch,
      body: <String, Object?>{'key': keyword, 'ord_type': ordType},
      client: client,
    );
  }

  Future<Result<ProtocolBinaryFile>> exportExcelOfGridReport(
    ClientKind client, {
    String keyword = '',
    bool Function()? canDispatch,
  }) async {
    return this.client.postBinary(
      '/wine/exp_wine_invt_grid',
      fallbackFileName: '存酒库存.xlsx',
      canDispatch: canDispatch,
      body: <String, Object?>{'key': ''},
      client: client,
    );
  }

  Future<Result<ProtocolBinaryFile>> exportUnreturnedWineList(
    ClientKind client, {
    String keyword = '',
    bool Function()? canDispatch,
  }) async {
    return this.client.postBinary(
      '/wine/rpt/exp_unreturned_wine_list',
      fallbackFileName: '未还酒水报表.xlsx',
      canDispatch: canDispatch,
      body: <String, Object?>{'key': keyword},
      client: client,
    );
  }

  Future<Result<ProtocolBinaryFile>> exportWineBorrowInvtList(ClientKind client, {bool Function()? canDispatch}) =>
      this.client.postBinary('/wine/exp_wine_borrow_invt_list', client: client, fallbackFileName: '未还酒水数量列表.xlsx', canDispatch: canDispatch);

  Future<Result<ProtocolBinaryFile>> exportWineDetailList(
    ClientKind client, {
    String startTime = '',
    String endTime = '',
    String keyword = '',
    int daysLeft = 0,
    bool Function()? canDispatch,
  }) async {
    return this.client.postBinary(
      '/wine/rpt/exp_wine_invt',
      fallbackFileName: '存酒明细.xlsx',
      canDispatch: canDispatch,
      body: <String, Object?>{
        'start_bef_in_day': startTime,
        'end_bef_in_day': endTime,
        'expired_day': daysLeft,
        'key': keyword,
      },
      client: client,
    );
  }

  // ---------------------------------------------------------------------------
  // S5.P7 待充公 · 充公库 · 充公出库单
  // ---------------------------------------------------------------------------

  Future<Result<List<WineConfiscateItem>>> getNeedToStoreList(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_csm_cg_bef_in',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseList(response, WineConfiscateItem.fromWire);
  }

  Future<Result<void>> backToStoreList(
    ClientKind client, {
    required List<String> ids,
  }) async {
    final response = await this.client.post(
      '/wine/back_csm_cg_bef_in',
      body: <String, Object?>{'ids': ids.map(_jsonId).toList()},
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> confirmToStoreList(
    ClientKind client, {
    required List<String> ids,
  }) async {
    final response = await this.client.post(
      '/wine/confirm_csm_cg_bef_in',
      body: <String, Object?>{'ids': ids.map(_jsonId).toList()},
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> confirmAuthToStoreList(
    ClientKind client, {
    required Map<String, Object?> fields,
  }) async {
    final response = await this.client.post(
      '/wine/confirm_auth_csm_cg_bef_in',
      body: fields,
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> chgCsmCgBefIn(
    ClientKind client, {
    required Map<String, Object?> fields,
  }) async {
    final response = await this.client.post(
      '/wine/chg_csm_cg_bef_in',
      body: fields,
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<List<WineConfiscateItem>>> getStoreLibList(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_cg_wine_invt',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseList(response, WineConfiscateItem.fromWire);
  }

  Future<Result<void>> newCgOut(
    ClientKind client, {
    required Map<String, Object?> fields,
  }) async {
    final response = await this.client.post(
      '/wine/new_cg_out',
      body: fields,
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<List<WineConfiscateItem>>> getToStoreDetailList(
    ClientKind client, {
    int page = 1,
    int pageSize = 20,
    String keyword = '',
    String startDate = '',
    String endDate = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_cg_out_list',
      body: <String, Object?>{
        'page': page,
        'page_size': pageSize,
        'key': keyword,
        if (startDate.isNotEmpty) 'start_day': startDate,
        if (endDate.isNotEmpty) 'end_day': endDate,
      },
      client: client,
    );
    return _parseList(response, WineConfiscateItem.fromWire);
  }

  Future<Result<Map<String, Object?>>> getToStoreOrderDetail(
    ClientKind client, {
    required String orderId,
  }) async {
    final response = await this.client.post(
      '/wine/get_cg_out_order',
      body: <String, Object?>{'id': _jsonId(orderId)},
      client: client,
    );
    return _parseMap(response);
  }

  Future<Result<Map<String, Object?>>> getToStoreOfHc(
    ClientKind client, {
    required String orderId,
  }) async {
    final response = await this.client.post(
      '/wine/get_cg_out_order_hc',
      body: <String, Object?>{'id': _jsonId(orderId)},
      client: client,
    );
    return _parseMap(response);
  }

  Future<Result<void>> toStoreToHc(
    ClientKind client, {
    required String orderId,
  }) async {
    final response = await this.client.post(
      '/wine/hc_cg_out',
      body: <String, Object?>{'id': _jsonId(orderId)},
      client: client,
    );
    return _parseVoid(response);
  }

  // ---------------------------------------------------------------------------
  // S5.P8 用户管理
  // ---------------------------------------------------------------------------

  Future<Result<List<WineCustomerItem>>> getCustomList(
    ClientKind client, {
    int page = 1,
    int pageSize = 20,
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_wine_cust_list',
      body: <String, Object?>{
        'page': page,
        'page_size': pageSize,
        'key': keyword,
      },
      client: client,
    );
    return _parseList(response, WineCustomerItem.fromWire);
  }

  Future<Result<void>> openOrCloseMsg(
    ClientKind client, {
    required List<String> custIds,
    required bool enable,
  }) async {
    final response = await this.client.post(
      '/wine/batch_set_enable_sms',
      body: <String, Object?>{
        'cust_ids': custIds.map(_jsonId).toList(),
        'enable_sms': enable ? 1 : 0,
      },
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> updateCustomName(
    ClientKind client, {
    required String custId,
    required String name,
  }) async {
    final response = await this.client.post(
      '/wine/save_wine_cust_name',
      body: <String, Object?>{
        'cust_id': _jsonId(custId),
        'name': name,
      },
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<bool>> validatePhoneNum(
    ClientKind client, {
    required String phone,
  }) async {
    final response = await this.client.post(
      '/wine/wine_chk_phone_usable',
      body: <String, Object?>{'phone': phone},
      client: client,
    );
    if (response.failureOrNull case final f?) return FailureResult(f);
    final map = response.valueOrNull ?? const {};
    return Success(map['usable'] == 1 || '${map['usable'] ?? ''}' == '1' || map['code'] == 1);
  }

  Future<Result<void>> updateCustomPhoneNum(
    ClientKind client, {
    required String custId,
    required String phone,
  }) async {
    final response = await this.client.post(
      '/wine/chg_wine_cust_phone',
      body: <String, Object?>{
        'cust_id': _jsonId(custId),
        'phone': phone,
      },
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<List<WineBlacklistItem>>> getBlackList(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_wine_blacklist',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseList(response, WineBlacklistItem.fromWire);
  }

  Future<Result<void>> addBlackList(
    ClientKind client, {
    required List<String> phones,
    String remark = '',
  }) async {
    final response = await this.client.post(
      '/wine/batch_add_wine_blacklist',
      body: <String, Object?>{
        'phones': phones,
        if (remark.isNotEmpty) 'remark': remark,
      },
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> deleteBlackList(
    ClientKind client, {
    required List<String> ids,
  }) async {
    final response = await this.client.post(
      '/wine/batch_del_wine_blacklist',
      body: <String, Object?>{'ids': ids.map(_jsonId).toList()},
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> importBlackList(
    ClientKind client, {
    required List<Map<String, Object?>> rows,
  }) async {
    final response = await this.client.post(
      '/wine/imp_wine_blacklist',
      body: <String, Object?>{'rows': rows},
      client: client,
    );
    return _parseVoid(response);
  }

  // ---------------------------------------------------------------------------
  // S5.P9 客户中心存酒
  // ---------------------------------------------------------------------------

  Future<Result<List<WineSaveRecord>>> getCustomCenterSaveWineList(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_kf_cj_bef_in',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseList(response, WineSaveRecord.fromWire);
  }

  Future<Result<List<WineInventoryItem>>> getCustomCenterGetWineList(
    ClientKind client, {
    String phone = '',
    String seatId = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_kf_wine_invt',
      body: <String, Object?>{
        if (phone.isNotEmpty) 'phone': phone,
        if (seatId.isNotEmpty) 'seat_id': _jsonId(seatId),
      },
      client: client,
    );
    return _parseList(response, WineInventoryItem.fromWire);
  }

  Future<Result<List<Map<String, Object?>>>> getCustomCenterSeatList(
    ClientKind client,
  ) async {
    final response = await this.client.post(
      '/wine/get_kf_seat_items',
      body: const <String, Object?>{},
      client: client,
    );
    return _parseRawList(response);
  }

  Future<Result<void>> getCustomCenterGetWineSubmit(
    ClientKind client, {
    required Map<String, Object?> fields,
  }) async {
    final response = await this.client.post(
      '/wine/new_kf_qj_out',
      body: fields,
      client: client,
    );
    return _parseVoid(response);
  }

  // ---------------------------------------------------------------------------
  // S5.P10 报表 (8大报表)
  // ---------------------------------------------------------------------------

  Future<Result<List<WineReportRow>>> getReportData(
    ClientKind client, {
    required String path,
    Map<String, Object?> params = const {},
  }) async {
    final response = await this.client.post(
      path,
      body: params,
      client: client,
    );
    return _parseList(response, WineReportRow.fromWire);
  }

  Future<Result<void>> printSaveAndGetWineList(
    ClientKind client, {
    required String id,
  }) async {
    final response = await this.client.post(
      '/wine/rpt/reprt_wine_in_out_bill',
      body: <String, Object?>{'id': _jsonId(id)},
      client: client,
    );
    return _parseVoid(response);
  }

  // ---------------------------------------------------------------------------
  // S5.P11 存酒借还
  // ---------------------------------------------------------------------------

  Future<Result<List<Map<String, Object?>>>> getWineBorrowEmployees(ClientKind client, String query) async {
    return _parseRawList(await this.client.post('/emp/upper_items', client: client,
      body: {'name': query, 'page_num': 1, 'page_size': 50, 'mod_emp_ids': <int>[]}));
  }

  Future<Result<List<Map<String, Object?>>>> getWineReturnOptions(ClientKind client, {String keyword = ''}) async {
    return _parseRawList(await this.client.post('/wine/get_wine_borrow_invt_list', client: client, body: {'key': keyword}));
  }

  Future<Result<List<WineBorrowReturnItem>>> getWineBorrowReturnList(
    ClientKind client, {
    int page = 1,
    int pageSize = 20,
    String keyword = '',
    int type = 0, // 0 全部, 1 借, 2 还
  }) async {
    final response = await this.client.post(
      '/wine/get_wine_borrow_return_list',
      body: <String, Object?>{
        'page_num': page,
        'page_size': pageSize,
        'key': keyword,
        'op_type': type,
        'prd_id': 0,
        'begin_day': '',
        'end_day': '',
      },
      client: client,
    );
    return _parseList(response, WineBorrowReturnItem.fromWire);
  }

  Future<Result<WineBorrowReturnPage>> getWineBorrowReturnPage(ClientKind client, {
    required int type, required int page, int pageSize = 20,
    required String beginDay, required String endDay, String keyword = '',
  }) async {
    if (page < 1 || pageSize < 1 || pageSize > 100 || (type != 1 && type != 2)) return _shapeFail();
    final response = await this.client.post('/wine/get_wine_borrow_return_list', client: client, body: {
      'page_num': page, 'page_size': pageSize, 'begin_day': beginDay,
      'end_day': endDay, 'op_type': type, 'prd_id': 0, 'key': keyword,
    });
    if (response.failureOrNull case final failure?) return FailureResult(failure);
    final map = response.valueOrNull;
    if (_wireCode(map?['code']) != 1) return FailureResult(AppFailure(kind: FailureKind.business, code: 'wine.list_failure', safeMessage: _safeMessage(map?['msg'], fallback: '获取借还记录失败')));
    final data = map?['data'];
    if (data is! Map) return _shapeFail();
    final total = _wireCode(data['row_cnt']);
    final records = data['records'];
    if (total == null || total < 0 || (records != null && records is! List)) return _shapeFail();
    final rows = records == null ? <Object?>[] : records as List;
    if (rows.any((row) => row is! Map) || rows.length > pageSize || rows.length > total) return _shapeFail();
    return Success(WineBorrowReturnPage(items: [for (final row in rows) WineBorrowReturnItem.fromWire(Map<Object?,Object?>.from(row as Map))], total: total));
  }

  Future<Result<List<Map<String, Object?>>>> getWineCanBorrowList(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_wine_can_borrow_list',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseRawList(response);
  }

  Future<Result<void>> newWineBorrow(
    ClientKind client, {
    required Map<String, Object?> fields,
  }) async {
    if (!_validBorrowFields(fields)) return const FailureResult(AppFailure(kind: FailureKind.business, code: 'wine.invalid_borrow_form', safeMessage: '请选择员工和有效商品数量，备注不超过30字'));
    final response = await this.client.post(
      '/wine/new_wine_borrow',
      body: fields,
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<void>> newWineReturn(
    ClientKind client, {
    required Map<String, Object?> fields,
  }) async {
    if (!_validBorrowFields(fields)) return const FailureResult(AppFailure(kind: FailureKind.business, code: 'wine.invalid_borrow_form', safeMessage: '请选择员工和有效商品数量，备注不超过30字'));
    final response = await this.client.post(
      '/wine/new_wine_return',
      body: fields,
      client: client,
    );
    return _parseVoid(response);
  }

  Future<Result<List<WineBorrowReturnItem>>> getWineBorrowInvtList(
    ClientKind client, {
    String keyword = '',
  }) async {
    final response = await this.client.post(
      '/wine/get_wine_borrow_invt_list',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
    return _parseList(response, WineBorrowReturnItem.fromWire);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool _validBorrowFields(Map<String,Object?> fields) {
  final employee = fields['br_emp_id'];
  final ids = fields['prd_ids'], counts = fields['prd_cnts'], remarks = fields['remarks'];
  return fields.length == 4 && employee is int && employee > 0 &&
      ids is List && ids.isNotEmpty && counts is List && remarks is List &&
      ids.length == counts.length && ids.length == remarks.length &&
      ids.every((id) => id is int && id > 0) &&
      counts.every((count) => count is int && count > 0) &&
      remarks.every((remark) => remark is String && remark.runes.length <= 30);
}

Object? _jsonId(String id) {
  final parsed = int.tryParse(id);
  return parsed ?? id;
}

int? _wireCode(Object? value) => switch (value) {
  num() when value.isFinite && value % 1 == 0 => value.toInt(),
  String() => int.tryParse(value),
  _ => null,
};

String _safeMessage(Object? value, {required String fallback}) {
  if (value is! String || value.isEmpty || value.length > 160) return fallback;
  return value;
}

const AppFailure _shapeFailure = AppFailure(
  kind: FailureKind.protocol,
  code: 'protocol.wine_shape',
  safeMessage: '存酒接口返回了无法识别的数据',
);

Result<T> _shapeFail<T>() => const FailureResult(_shapeFailure);

Result<void> _parseVoid(Result<Map<String, Object?>> response) {
  if (response.failureOrNull case final f?) return FailureResult(f);
  final map = response.valueOrNull ?? const {};
  final code = _wireCode(map['code']);
  if (code != 1) {
    return FailureResult(
      AppFailure(
        kind: FailureKind.business,
        code: 'wine.business_failure',
        safeMessage: _safeMessage(map['msg'] ?? map['message'], fallback: '操作失败'),
      ),
    );
  }
  return const Success(null);
}

Result<List<T>> _parseList<T>(
  Result<Map<String, Object?>> response,
  T Function(Map<Object?, Object?>) fromWire,
) {
  if (response.failureOrNull case final f?) return FailureResult(f);
  final map = response.valueOrNull ?? const {};
  final code = _wireCode(map['code']);
  if (code != 1) {
    return FailureResult(
      AppFailure(
        kind: FailureKind.business,
        code: 'wine.list_failure',
        safeMessage: _safeMessage(map['msg'] ?? map['message'], fallback: '获取列表失败'),
      ),
    );
  }
  final rawData = map['data'];
  final list = switch (rawData) {
    List() => rawData,
    Map() when rawData['records'] is List => rawData['records'] as List,
    Map() when rawData['list'] is List => rawData['list'] as List,
    Map() when rawData['data'] is List => rawData['data'] as List,
    _ => null,
  };
  if (list == null) return Success(<T>[]);
  return Success([
    for (final item in list)
      if (item is Map) fromWire(Map<Object?, Object?>.from(item)),
  ]);
}

Result<List<Map<String, Object?>>> _parseRawList(
  Result<Map<String, Object?>> response,
) {
  if (response.failureOrNull case final f?) return FailureResult(f);
  final map = response.valueOrNull ?? const {};
  final code = _wireCode(map['code']);
  if (code != 1) {
    return FailureResult(
      AppFailure(
        kind: FailureKind.business,
        code: 'wine.list_failure',
        safeMessage: _safeMessage(map['msg'] ?? map['message'], fallback: '获取数据失败'),
      ),
    );
  }
  final rawData = map['data'];
  final list = switch (rawData) {
    List() => rawData,
    Map() when rawData['records'] is List => rawData['records'] as List,
    Map() when rawData['list'] is List => rawData['list'] as List,
    _ => null,
  };
  if (list == null) return const Success(<Map<String, Object?>>[]);
  return Success([
    for (final item in list)
      if (item is Map) item.map((k, v) => MapEntry('$k', v)),
  ]);
}

Result<Map<String, Object?>> _parseMap(
  Result<Map<String, Object?>> response,
) {
  if (response.failureOrNull case final f?) return FailureResult(f);
  final map = response.valueOrNull ?? const {};
  final code = _wireCode(map['code']);
  if (code != 1) {
    return FailureResult(
      AppFailure(
        kind: FailureKind.business,
        code: 'wine.map_failure',
        safeMessage: _safeMessage(map['msg'] ?? map['message'], fallback: '获取详情失败'),
      ),
    );
  }
  final rawData = map['data'];
  if (rawData is! Map) return _shapeFail();
  return Success(rawData.map((k, v) => MapEntry('$k', v)));
}
