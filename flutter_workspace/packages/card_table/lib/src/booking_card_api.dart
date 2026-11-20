import 'package:card_table/src/booking_detail_access.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

enum BookingCardWriteAction {
  lock,
  unlock,
  cancelOpen,
  cancelReserve,
  pin,
  unpin,
  disableMustOrder,
  updateMinConsume,
  updateSales,
  updateMark,
  updateRemark,
  updateWaiter,
  clearSeat,
  convertOffline,
  openEmpty,
  openReserve,
  createReserve,
  updateReserve,
  transferOpen,
  transferReserve,
}

final class BookingBookDetail {
  const BookingBookDetail({
    this.customerName = '',
    this.customerPhone = '',
    this.autoSendMsg = 2,
    this.expArriveTime = '',
    this.salesEmpId = '',
    this.secondSalesEmpId = '',
    this.customerExpCnt = 0,
    this.expMinCsmAmt = 0,
    this.remark = '',
    this.mark = '',
    this.reservationFields,
  });

  final String customerName;
  final String customerPhone;
  final int autoSendMsg;
  final String expArriveTime;
  final String salesEmpId;
  final String secondSalesEmpId;
  final int customerExpCnt;
  final num expMinCsmAmt;
  final String remark;
  final String mark;

  /// Complete server values required to edit without resetting hidden fields.
  final Map<String, Object?>? reservationFields;

  factory BookingBookDetail.fromWire(Map<Object?, Object?> data) {
    return BookingBookDetail(
      reservationFields: _reservationFields(data),
      customerName: '${data['customer_name'] ?? ''}',
      customerPhone: '${data['customer_phone'] ?? ''}',
      autoSendMsg: _fieldNumber(data['auto_send_msg']).toInt() == 0
          ? 2
          : _fieldNumber(data['auto_send_msg']).toInt(),
      expArriveTime: '${data['exp_arrive_time'] ?? ''}',
      salesEmpId: _optionalWireId(data['sales_emp_id']),
      secondSalesEmpId: _optionalWireId(data['second_sales_emp_id']),
      customerExpCnt: _fieldNumber(data['customer_exp_cnt']).toInt(),
      expMinCsmAmt: _fieldNumber(data['exp_min_csm_amt']),
      remark: '${data['remark'] ?? ''}',
      mark: '${data['mark'] ?? ''}',
    );
  }
}

Map<String, Object?>? _reservationFields(Map<Object?, Object?> data) {
  const textFields = [
    'customer_name', 'customer_phone', 'book_day', 'exp_arrive_time',
    'remark', 'mark',
  ];
  const idFields = [
    'sales_emp_id', 'second_sales_emp_id', 'exp_region_id', 'exp_seat_id',
  ];
  bool validId(Object? value) =>
      value != null && RegExp(r'^\d+$').hasMatch('$value');
  bool validNumber(Object? value) =>
      value != null && (num.tryParse('$value')?.isFinite ?? false);
  if (textFields.any((key) => data[key] is! String) ||
      idFields.any((key) => !validId(data[key])) ||
      ![1, 2].contains(_wireCode(data['is_this_wkday'])) ||
      ![1, 2].contains(_wireCode(data['auto_send_msg'])) ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch('${data['book_day']}') ||
      !validNumber(data['customer_exp_cnt']) ||
      !validNumber(data['exp_min_csm_amt'])) {
    return null;
  }
  final seatIds = data['exp_seat_ids'];
  if (seatIds is! List || seatIds.any((id) => !validId(id))) return null;
  return Map<String, Object?>.unmodifiable({
    for (final key in [...textFields, ...idFields, 'is_this_wkday',
      'auto_send_msg', 'customer_exp_cnt', 'exp_min_csm_amt']) key: data[key],
    'exp_seat_ids': List<Object?>.unmodifiable(seatIds),
  });
}

final class TurnoverSaleHistoryItem {
  const TurnoverSaleHistoryItem({
    required this.id,
    required this.salesEmpId,
    required this.secondSalesEmpId,
    required this.bookTime,
    required this.openTime,
  });

  final String id;
  final String salesEmpId;
  final String secondSalesEmpId;
  final String bookTime;
  final String openTime;

  factory TurnoverSaleHistoryItem.fromWire(Map<Object?, Object?> data) {
    return TurnoverSaleHistoryItem(
      id: '${data['id'] ?? ''}',
      salesEmpId: '${data['si'] ?? ''}',
      secondSalesEmpId: '${data['ssi'] ?? ''}',
      bookTime: '${data['bt'] ?? ''}',
      openTime: '${data['ot'] ?? ''}',
    );
  }
}

final class SeatTurnbackItem {
  const SeatTurnbackItem({
    required this.id,
    required this.openTime,
    required this.salesPerson,
  });

  final String id;
  final String openTime;
  final String salesPerson;

  factory SeatTurnbackItem.fromWire(Map<Object?, Object?> data) {
    return SeatTurnbackItem(
      id: '${data['id'] ?? ''}',
      openTime: '${data['o'] ?? ''}',
      salesPerson: '${data['s'] ?? ''}',
    );
  }
}

final class BookingOrderDetailData {
  const BookingOrderDetailData({
    this.totalAmount = '0.00',
    this.discountAmount = '0.00',
    this.unpaidAmount = '0.00',
    this.consumptionRows = const <BookingConsumptionRow>[],
    this.wineRows = const <BookingWineRow>[],
  });

  final String totalAmount;
  final String discountAmount;
  final String unpaidAmount;
  final List<BookingConsumptionRow> consumptionRows;
  final List<BookingWineRow> wineRows;

  factory BookingOrderDetailData.fromWire(Map<Object?, Object?> data) {
    final payInfo = data['pay_info'] is Map
        ? data['pay_info'] as Map
        : const {};
    final rawOrderAmt = num.tryParse('${payInfo['order_amt'] ?? 0}') ?? 0;
    final rawPayedAmt = num.tryParse('${payInfo['payed_amt'] ?? 0}') ?? 0;
    final rawYhAmt = num.tryParse('${payInfo['yh_amt'] ?? 0}') ?? 0;

    String fmt(num fen) => (fen / 100).toStringAsFixed(2);

    final records = data['records'] is List
        ? data['records'] as List
        : (data['d'] is List ? data['d'] as List : const []);
    final wineOps = data['wine_ops'] is List
        ? data['wine_ops'] as List
        : (data['w'] is List ? data['w'] as List : const []);

    return BookingOrderDetailData(
      totalAmount: fmt(rawOrderAmt),
      discountAmount: fmt(rawYhAmt),
      unpaidAmount: fmt(rawOrderAmt - rawPayedAmt),
      consumptionRows: [
        for (final item in records)
          if (item is Map)
            BookingConsumptionRow.fromWire(Map<Object?, Object?>.from(item)),
      ],
      wineRows: [
        for (final item in wineOps)
          if (item is Map)
            BookingWineRow.fromWire(Map<Object?, Object?>.from(item)),
      ],
    );
  }
}

final class BookingConsumptionRow {
  const BookingConsumptionRow({
    required this.id,
    required this.productName,
    required this.count,
    required this.price,
    required this.subtotal,
    required this.waiterName,
    required this.orderTime,
    this.isSettled = false,
    this.isReturned = false,
    this.discountType = 0,
    this.packageItems = const <String>[],
  });

  final String id;
  final String productName;
  final num count;
  final String price;
  final String subtotal;
  final String waiterName;
  final String orderTime;
  final bool isSettled;
  final bool isReturned;
  final int discountType;
  final List<String> packageItems;

  factory BookingConsumptionRow.fromWire(Map<Object?, Object?> data) {
    final status = int.tryParse('${data['s'] ?? 0}') ?? 0;
    final discount = int.tryParse('${data['at'] ?? 0}') ?? 0;
    final isBack =
        data['back'] == true ||
        (data['bs'] is List && (data['bs'] as List).isNotEmpty);
    final count = num.tryParse('${data['pc'] ?? 0}') ?? 0;
    final pp = num.tryParse('${data['pp'] ?? 0}') ?? 0;
    final p2 = num.tryParse('${data['p2'] ?? 0}') ?? pp;
    final priceStr = pp == 0 ? '时价' : (p2 / 100).toStringAsFixed(2);
    final rawPa = data['pa'] ?? (p2 * count);
    final subtotalNum = (discount == 2 || discount == 3)
        ? 0
        : (num.tryParse('$rawPa') ?? 0) / 100;
    final subtotalStr = subtotalNum.toStringAsFixed(2);

    final productInfo = data['productInfo'] is Map
        ? data['productInfo'] as Map
        : null;
    final productName =
        '${productInfo?['name'] ?? data['name'] ?? data['pn'] ?? ''}';

    final personInfo = data['personInfo'] is Map
        ? data['personInfo'] as Map
        : null;
    final waiterName =
        '${personInfo?['name'] ?? data['waiter_name'] ?? data['wn'] ?? ''}';

    final rawOt = '${data['ot'] ?? ''}';
    final orderTime = rawOt.length > 7 ? rawOt.substring(7) : rawOt;

    final subItems = <String>[];
    if (data['si'] is List) {
      for (final sub in data['si'] as List) {
        if (sub is Map) {
          final groupInfo = sub['groupInfo'] is Map
              ? sub['groupInfo'] as Map
              : null;
          final subName = '${groupInfo?['name'] ?? sub['name'] ?? ''}';
          final subCount = sub['c'] ?? sub['pc'] ?? 1;
          if (subName.isNotEmpty) {
            subItems.add('$subName x$subCount');
          }
        }
      }
    }

    return BookingConsumptionRow(
      id: '${data['id'] ?? ''}',
      productName: productName.isEmpty ? '商品' : productName,
      count: count,
      price: priceStr,
      subtotal: subtotalStr,
      waiterName: waiterName.isEmpty ? '---' : waiterName,
      orderTime: orderTime,
      isSettled: status == 5,
      isReturned: isBack,
      discountType: discount,
      packageItems: subItems,
    );
  }
}

final class BookingWineRow {
  const BookingWineRow({
    required this.type,
    required this.productName,
    required this.spec,
    required this.count,
    required this.operatorName,
    required this.operateTime,
  });

  final int type; // 1存, 2取
  final String productName;
  final String spec;
  final String count;
  final String operatorName;
  final String operateTime;

  factory BookingWineRow.fromWire(Map<Object?, Object?> data) {
    return BookingWineRow(
      type: int.tryParse('${data['t'] ?? 1}') ?? 1,
      productName: '${data['p'] ?? ''}',
      spec: '${data['u'] ?? ''}',
      count: '${data['c'] ?? ''}',
      operatorName: '${data['n'] ?? ''}',
      operateTime: '${data['o'] ?? ''}',
    );
  }
}

final class BookingReservedItem {
  const BookingReservedItem({
    required this.id,
    required this.bookId,
    required this.departmentName,
    required this.orderPersonName,
    required this.orderPersonCode,
    required this.expArriveTime,
    required this.minConsumeYuan,
    required this.customerCount,
    required this.customerName,
    required this.customerPhone,
    required this.seatName,
    required this.remark,
    this.seatId = '',
    this.regionId = '',
    this.salesEmpId = '',
    this.isToday = true,
  });

  final String id;
  final String bookId;
  final String departmentName;
  final String orderPersonName;
  final String orderPersonCode;
  final String expArriveTime;
  final String minConsumeYuan;
  final String customerCount;
  final String customerName;
  final String customerPhone;
  final String seatName;
  final String remark;
  final String seatId;
  final String regionId;
  final String salesEmpId;
  final bool isToday;

  factory BookingReservedItem.fromWire(
    Map<Object?, Object?> map, {
    bool isToday = true,
  }) {
    String str(Object? v) => v == null ? '' : '$v'.trim();
    String jsonId(Object? v) => switch (v) {
      num() => '$v',
      String() when v.isNotEmpty => v,
      _ => '',
    };
    final id = jsonId(map['id'] ?? map['b_id'] ?? map['book_id']);
    return BookingReservedItem(
      id: id,
      bookId: jsonId(map['b_id'] ?? map['book_id'] ?? id),
      departmentName: str(
        map['departmentName'] ?? map['dept_name'] ?? map['d'] ?? map['dn'],
      ),
      orderPersonName: str(
        map['orderPersonName'] ??
            map['sales_name'] ??
            map['e'] ??
            map['salesName'],
      ),
      orderPersonCode: str(map['code'] ?? map['sales_code'] ?? map['sc']),
      expArriveTime: str(
        map['exp_arrive_time'] ??
            map['arrive_time'] ??
            map['eat'] ??
            map['book_time'] ??
            map['b'],
      ),
      minConsumeYuan: str(
        map['ma'] ?? map['min_consume'] ?? map['min_consume_yuan'],
      ),
      customerCount: str(
        map['customer_exp_cnt'] ??
            map['cnt'] ??
            map['cec'] ??
            map['customer_count'],
      ),
      customerName: str(map['customer_name'] ?? map['cn'] ?? map['n']),
      customerPhone: str(
        map['customer_phone'] ?? map['cp'] ?? map['phone'] ?? map['p'],
      ),
      seatName: str(
        map['seatName'] ?? map['seat_name'] ?? map['sn'] ?? map['s_name'],
      ),
      remark: str(map['remark'] ?? map['rm'] ?? map['r']),
      seatId: jsonId(
        map['exp_seat_id'] ?? map['seat_id'] ?? map['s_id'] ?? map['s'],
      ),
      regionId: jsonId(
        map['exp_region_id'] ?? map['region_id'] ?? map['r_id'] ?? map['r'],
      ),
      salesEmpId: jsonId(map['si'] ?? map['sales_emp_id']),
      isToday: isToday,
    );
  }
}

/// 解析预留时间（兼容多种时间格式）
DateTime? parseBookingDateTime(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final normalized = trimmed.replaceAll('/', '-');
  final direct = DateTime.tryParse(normalized);
  if (direct != null) return direct;

  final compact = RegExp(r'^(\d{4})(\d{2})(\d{2})');
  final match = compact.firstMatch(trimmed);
  if (match != null) {
    final y = int.tryParse(match.group(1)!);
    final m = int.tryParse(match.group(2)!);
    final d = int.tryParse(match.group(3)!);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
  }
  return null;
}

/// 判定预留条目是否符合日期筛选条件（当日 vs 明天 / 未来7天 / 全部）
bool matchesBookingDateFilter({
  required BookingReservedItem item,
  required bool isToday,
  int futureType = 1,
  required DateTime now,
}) {
  final itemDt = parseBookingDateTime(item.expArriveTime);
  final today = DateTime(now.year, now.month, now.day);

  if (itemDt == null) {
    // 缺少日期字段时：仅在查询当日预留时作为保底保留，其它预留筛选中过滤排除
    return isToday;
  }

  final itemDay = DateTime(itemDt.year, itemDt.month, itemDt.day);
  if (isToday) {
    return itemDay == today;
  }

  final tomorrow = today.add(const Duration(days: 1));
  final sevenDaysEnd = today.add(const Duration(days: 7));

  switch (futureType) {
    case 1: // 明天
      return itemDay == tomorrow;
    case 2: // 未来7天 (明天 ~ 未来第7天)
      return (itemDay.isAtSameMomentAs(tomorrow) || itemDay.isAfter(tomorrow)) &&
          (itemDay.isAtSameMomentAs(sevenDaysEnd) || itemDay.isBefore(sevenDaysEnd));
    case 3: // 全部 (其它所有预留日期)
      return itemDay != today;
    default:
      return itemDay != today;
  }
}

typedef BookingCardWrite = Future<Result<void>> Function({
  required BookingCardWriteAction action,
  required String seatId,
  String bookId,
  Map<String, Object?> fields,
  bool Function()? canDispatch,
});

typedef BookingDetailConfigLoader =
    Future<Result<BookingDetailConfig>> Function();

final class ProtocolBookingCardApi {
  const ProtocolBookingCardApi({
    required this.client,
    this.canDispatch,
    this.nowProvider,
  });

  final ProtocolClient client;
  final bool Function()? canDispatch;
  final DateTime Function()? nowProvider;

  Future<Result<void>> lock(ClientKind client, {required String seatId}) =>
      _post(client, '/bk/lock', {'id': _jsonId(seatId)});

  Future<Result<void>> unlock(ClientKind client, {required String seatId}) =>
      _post(client, '/bk/unlock', {'id': _jsonId(seatId)});

  Future<Result<void>> cancelOpen(
    ClientKind client, {
    required String seatId,
  }) => _post(client, '/bk/cancel_open', {'id': _jsonId(seatId)});

  Future<Result<void>> cancelReserve(
    ClientKind client, {
    required String bookId,
  }) => _post(client, '/bk/cancel', {'id': _jsonId(bookId)});

  Future<Result<void>> pin(ClientKind client, {required String seatId}) =>
      _post(client, '/bk/top_seat_dsp', {'id': _jsonId(seatId)});

  Future<Result<void>> unpin(ClientKind client, {required String seatId}) =>
      _post(client, '/bk/cancel_top_seat_dsp', {'id': _jsonId(seatId)});

  Future<Result<void>> disableMustOrder(
    ClientKind client, {
    required String seatId,
  }) => _post(client, '/bk/disable_csm_must_ord', {'id': _jsonId(seatId)});

  Future<Result<void>> updateMinConsume(
    ClientKind client, {
    required String seatId,
    required num amount,
  }) => _post(client, '/bk/chg_csm_mca', {
    'id': _jsonId(seatId),
    'min_csm_amt': amount == 0 ? '0' : amount.toString(),
  });

  Future<Result<void>> updateSales(
    ClientKind client, {
    required String seatId,
    required String salesEmpId,
    required String salesName,
    String secondSalesEmpId = '',
    String secondSalesName = '',
  }) => _post(client, '/bk/chg_sales', {
    'id': _jsonId(seatId),
    'sales_emp_id': _jsonId(salesEmpId.isEmpty ? '0' : salesEmpId),
    'sales_name': salesName,
    'second_sales_emp_id': _jsonId(
      secondSalesEmpId.isEmpty ? '0' : secondSalesEmpId,
    ),
    'second_sales_name': secondSalesName,
  });

  Future<Result<void>> updateMark(
    ClientKind client, {
    required String seatId,
    required String mark,
  }) =>
      _post(client, '/bk/set_seat_mark', {'id': _jsonId(seatId), 'mark': mark});

  Future<Result<void>> updateRemark(
    ClientKind client, {
    required String seatId,
    required String remark,
  }) => _post(client, '/bk/chg_open_seat_remark', {
    'id': _jsonId(seatId),
    'remark': remark,
  });

  Future<Result<void>> updateWaiter(
    ClientKind client, {
    required String seatId,
    required String waiterEmpId,
    required int turnoverCount,
  }) => _post(client, '/sel/chg_csm_waiter', {
    'seat_id': _jsonId(seatId),
    'waiter_emp_id': _jsonId(waiterEmpId),
    'turnover_cnt': turnoverCount,
  });

  Future<Result<void>> clearSeat(ClientKind client, {required String seatId}) =>
      _post(client, '/sel/seat_clean', {'seat_id': _jsonId(seatId)});

  Future<Result<void>> convertOffline(
    ClientKind client, {
    required String seatId,
  }) => _post(client, '/bk/conv_ol_seat_local', {'id': _jsonId(seatId)});

  Future<Result<void>> openEmpty(
    ClientKind client, {
    required String seatId,
    Map<String, Object?> fields = const <String, Object?>{},
  }) => _post(
    client,
    '/bk/direct_open',
    _openBody(seatId: seatId, bookId: '', fields: fields),
  );

  Future<Result<void>> openReserve(
    ClientKind client, {
    required String bookId,
    Map<String, Object?> fields = const <String, Object?>{},
  }) => _post(
    client,
    '/bk/open',
    _openBody(
      seatId: '${fields['seat_id'] ?? ''}',
      bookId: bookId,
      fields: fields,
    ),
  );

  Future<Result<void>> createReserve(
    ClientKind client, {
    required Map<String, Object?> fields,
  }) =>
      _post(client, '/bk/batch_new', _reserveBody(bookId: '', fields: fields));

  Future<Result<void>> updateReserve(
    ClientKind client, {
    required String bookId,
    required Map<String, Object?> fields,
  }) => _post(client, '/bk/save', _reserveBody(bookId: bookId, fields: fields));

  Future<Result<void>> transferOpenSeat(
    ClientKind client, {
    required String seatId,
    required String destSeatId,
    required num newMinConsumeAmount,
  }) => _post(client, '/bk/chg_csm_seat', {
    'id': _jsonId(seatId),
    'dest_seat_id': _jsonId(destSeatId),
    'new_min_csm_amt': newMinConsumeAmount,
  });

  Future<Result<void>> transferReservedSeat(
    ClientKind client, {
    required String bookId,
    required String destSeatId,
    required num newMinConsumeAmount,
  }) => _post(client, '/bk/chg_seat', {
    'id': _jsonId(bookId),
    'dest_seat_id': _jsonId(destSeatId),
    'new_min_csm_amt': newMinConsumeAmount,
  });

  Future<Result<BookingDetailConfig>> getBookingDetailConfig(
    ClientKind client,
  ) async {
    final response = await this.client.post(
      '/org/get_org_biz_cfg',
      body: const <String, Object?>{},
      client: client,
      canDispatch: canDispatch,
    );
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
          code: 'business.booking_detail_config_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: '获取门店业务配置失败',
            disallowed: const <String>[],
          ),
        ),
      );
    }
    final data = envelope['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    return Success(
      BookingDetailConfig.fromWire(Map<Object?, Object?>.from(data)),
    );
  }

  Future<Result<BookingBookDetail>> getBookDetail(
    ClientKind client, {
    required String bookId,
  }) async {
    if (bookId.isEmpty) return const FailureResult(_shapeFailure);
    final result = await _postEnvelope(client, '/bk/get', {
      'id': _jsonId(bookId),
    });
    if (result.failureOrNull != null) {
      return FailureResult(result.failureOrNull!);
    }
    final data = result.valueOrNull!['data'];
    if (data is! Map) return const FailureResult(_shapeFailure);
    return Success(
      BookingBookDetail.fromWire(Map<Object?, Object?>.from(data)),
    );
  }

  Future<Result<List<TurnoverSaleHistoryItem>>> getHisSales(
    ClientKind client, {
    required String seatId,
  }) async {
    final res = await _postEnvelope(client, '/bk/get_his_sales', {
      'id': _jsonId(seatId),
    });
    if (res.failureOrNull case final f?) return FailureResult(f);
    final data = res.valueOrNull!['data'];
    if (data is! List) return const Success(<TurnoverSaleHistoryItem>[]);
    return Success([
      for (final item in data)
        if (item is Map)
          TurnoverSaleHistoryItem.fromWire(Map<Object?, Object?>.from(item)),
    ]);
  }

  Future<Result<void>> chgHisSales(
    ClientKind client, {
    required String seatId,
    required String csmId,
    required String salesEmpId,
    String secondSalesEmpId = '',
    required String reason,
  }) => _post(client, '/bk/chg_his_sales', {
    'id': _jsonId(seatId),
    'csm_id': _jsonId(csmId),
    'sales_emp_id': _jsonId(salesEmpId),
    'second_sales_emp_id': _jsonId(
      secondSalesEmpId.isEmpty ? '0' : secondSalesEmpId,
    ),
    'reason': reason,
  });

  Future<Result<List<SeatTurnbackItem>>> getSeatTurnbackList(
    ClientKind client, {
    required String seatId,
  }) async {
    final res = await _postEnvelope(client, '/sel/get_seat_turnback_list', {
      'id': _jsonId(seatId),
    });
    if (res.failureOrNull case final f?) return FailureResult(f);
    final data = res.valueOrNull!['data'];
    final records = data is Map && data['records'] is List
        ? data['records'] as List
        : const [];
    return Success([
      for (final item in records)
        if (item is Map)
          SeatTurnbackItem.fromWire(Map<Object?, Object?>.from(item)),
    ]);
  }

  Future<Result<void>> seatTurnBack(
    ClientKind client, {
    required String csmId,
  }) => _post(client, '/sel/seat_turn_back', {'id': _jsonId(csmId)});

  Future<Result<BookingOrderDetailData>> getOrderDetail(
    ClientKind client, {
    required String seatId,
    required int turnoverCount,
  }) async {
    final res = await _postEnvelope(client, '/wo/list', {
      'seat_id': _jsonId(seatId),
      'turnover_cnt': turnoverCount,
    });
    if (res.failureOrNull case final f?) return FailureResult(f);
    final data = res.valueOrNull!['data'];
    if (data is! Map) return const Success(BookingOrderDetailData());
    return Success(
      BookingOrderDetailData.fromWire(Map<Object?, Object?>.from(data)),
    );
  }

  Future<Result<List<BookingReservedItem>>> getReservedList(
    ClientKind client, {
    required bool isToday,
    int futureType = 1,
    DateTime? now,
  }) async {
    final currentNow = now ?? nowProvider?.call() ?? DateTime.now();

    // 1. First try /sel/rpt/get_book_list which is the standard backend report endpoint for reserved records
    final reportRes = await this.client.postWithoutBody(
      '/sel/rpt/get_book_list',
      client: client,
      canDispatch: canDispatch,
    );
    if (reportRes.failureOrNull == null) {
      final envelope = reportRes.valueOrNull!;
      final code = _wireCode(envelope['code']);
      if (code == 1) {
        final data = envelope['data'];
        final list = switch (data) {
          List() => data,
          Map() when data['records'] is List => data['records'] as List,
          Map() when data['list'] is List => data['list'] as List,
          Map() when data['data'] is List => data['data'] as List,
          _ => null,
        };
        if (list != null) {
          final items = <BookingReservedItem>[
            for (final item in list)
              if (item is Map)
                BookingReservedItem.fromWire(
                  Map<Object?, Object?>.from(item),
                  isToday: isToday,
                ),
          ];
          return Success(
            items
                .where(
                  (item) => matchesBookingDateFilter(
                    item: item,
                    isToday: isToday,
                    futureType: futureType,
                    now: currentNow,
                  ),
                )
                .toList(),
          );
        }
      }
    }

    // 2. Try day-specific endpoint if available
    final path = isToday
        ? '/bk/get_current_day_list'
        : '/bk/get_future_day_list';
    final body = isToday
        ? const <String, Object?>{}
        : <String, Object?>{'ti': futureType};
    final res = await _postEnvelope(client, path, body);
    if (res.failureOrNull == null) {
      final data = res.valueOrNull!['data'];
      if (data is List) {
        final items = <BookingReservedItem>[
          for (final item in data)
            if (item is Map)
              BookingReservedItem.fromWire(
                Map<Object?, Object?>.from(item),
                isToday: isToday,
              ),
        ];
        return Success(
          items
              .where(
                (item) => matchesBookingDateFilter(
                  item: item,
                  isToday: isToday,
                  futureType: futureType,
                  now: currentNow,
                ),
              )
              .toList(),
        );
      }
    }

    if (reportRes.failureOrNull case final f?) return FailureResult(f);
    if (res.failureOrNull case final f?) return FailureResult(f);
    return const Success(<BookingReservedItem>[]);
  }

  Future<Result<void>> cancelReservedInfo(
    ClientKind client, {
    required List<String> bookIds,
  }) {
    final ids = [
      for (final id in bookIds)
        if (id.isNotEmpty) _jsonId(id),
    ];
    return _post(client, '/bk/cancel', {
      'book_ids': ids,
      'id': ids.isNotEmpty ? ids.first : 0,
    });
  }

  Future<Result<void>> singleAllocation(
    ClientKind client, {
    required String id,
    required String seatId,
  }) => _post(client, '/bk/single_allocation', {
    'id': _jsonId(id),
    'seat_id': _jsonId(seatId),
  });

  Future<Result<void>> manyAllocation(
    ClientKind client, {
    required List<String> bookIds,
  }) {
    final ids = [
      for (final id in bookIds)
        if (id.isNotEmpty) _jsonId(id),
    ];
    return _post(client, '/bk/many_allocation', {'book_ids': ids});
  }

  Future<Result<void>> write(
    ClientKind client, {
    required BookingCardWriteAction action,
    required String seatId,
    String bookId = '',
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    return switch (action) {
      BookingCardWriteAction.lock => lock(client, seatId: seatId),
      BookingCardWriteAction.unlock => unlock(client, seatId: seatId),
      BookingCardWriteAction.cancelOpen => cancelOpen(client, seatId: seatId),
      BookingCardWriteAction.cancelReserve => cancelReserve(
        client,
        bookId: bookId,
      ),
      BookingCardWriteAction.pin => pin(client, seatId: seatId),
      BookingCardWriteAction.unpin => unpin(client, seatId: seatId),
      BookingCardWriteAction.disableMustOrder => disableMustOrder(
        client,
        seatId: seatId,
      ),
      BookingCardWriteAction.updateMinConsume => updateMinConsume(
        client,
        seatId: seatId,
        amount: _fieldNumber(fields['min_csm_amt']),
      ),
      BookingCardWriteAction.updateSales => updateSales(
        client,
        seatId: seatId,
        salesEmpId: '${fields['sales_emp_id'] ?? ''}',
        salesName: '${fields['sales_name'] ?? ''}',
        secondSalesEmpId: '${fields['second_sales_emp_id'] ?? ''}',
        secondSalesName: '${fields['second_sales_name'] ?? ''}',
      ),
      BookingCardWriteAction.updateMark => updateMark(
        client,
        seatId: seatId,
        mark: '${fields['mark'] ?? ''}',
      ),
      BookingCardWriteAction.updateRemark => updateRemark(
        client,
        seatId: seatId,
        remark: '${fields['remark'] ?? ''}',
      ),
      BookingCardWriteAction.updateWaiter => updateWaiter(
        client,
        seatId: seatId,
        waiterEmpId: '${fields['waiter_emp_id'] ?? ''}',
        turnoverCount: _fieldNumber(fields['turnover_cnt']).toInt(),
      ),
      BookingCardWriteAction.clearSeat => clearSeat(client, seatId: seatId),
      BookingCardWriteAction.convertOffline => convertOffline(
        client,
        seatId: seatId,
      ),
      BookingCardWriteAction.openEmpty => openEmpty(
        client,
        seatId: seatId,
        fields: fields,
      ),
      BookingCardWriteAction.openReserve => openReserve(
        client,
        bookId: bookId,
        fields: fields,
      ),
      BookingCardWriteAction.createReserve => createReserve(
        client,
        fields: fields,
      ),
      BookingCardWriteAction.updateReserve => updateReserve(
        client,
        bookId: bookId,
        fields: fields,
      ),
      BookingCardWriteAction.transferOpen => transferOpenSeat(
        client,
        seatId: seatId,
        destSeatId: '${fields['dest_seat_id'] ?? ''}',
        newMinConsumeAmount: _fieldNumber(fields['new_min_csm_amt']),
      ),
      BookingCardWriteAction.transferReserve => transferReservedSeat(
        client,
        bookId: bookId,
        destSeatId: '${fields['dest_seat_id'] ?? ''}',
        newMinConsumeAmount: _fieldNumber(fields['new_min_csm_amt']),
      ),
    };
  }

  Future<Result<void>> _post(
    ClientKind client,
    String path,
    Map<String, Object?> body,
  ) async {
    final envelope = await _postEnvelope(client, path, body);
    if (envelope.failureOrNull != null) {
      return FailureResult(envelope.failureOrNull!);
    }
    return const Success(null);
  }

  Future<Result<Map<String, Object?>>> _postEnvelope(
    ClientKind client,
    String path,
    Map<String, Object?> body,
  ) async {
    final disallowed = [
      for (final key in const ['seat_id', 'id', 'dest_seat_id', 'book_id'])
        if (body[key] case final value?)
          if ('$value'.length >= 2 && '$value' != '0') '$value',
    ];
    final response = body.isEmpty
        ? await this.client.postWithoutBody(
            path,
            client: client,
            canDispatch: canDispatch,
          )
        : await this.client.post(
            path,
            body: body,
            client: client,
            canDispatch: canDispatch,
          );
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
          code: 'business.booking_card_rejected',
          safeMessage: _safeMessage(
            envelope['msg'] ?? envelope['message'],
            fallback: '操作失败，请重试',
            disallowed: disallowed,
          ),
        ),
      );
    }
    return Success(envelope);
  }
}

Object _jsonId(String id) {
  final parsed = int.tryParse(id);
  return parsed ?? id;
}

String _optionalWireId(Object? value) {
  if (value == null || value == '' || value == 0) return '';
  return '$value';
}

Map<String, Object?> _openBody({
  required String seatId,
  required String bookId,
  required Map<String, Object?> fields,
}) {
  final salesEmpId = '${fields['sales_emp_id'] ?? ''}';
  final secondSalesEmpId = '${fields['second_sales_emp_id'] ?? ''}';
  final waiterEmpId = '${fields['waiter_emp_id'] ?? ''}';
  final oldSalesEmpId = '${fields['old_sales_emp_id'] ?? ''}';
  final expArriveTime = '${fields['exp_arrive_time'] ?? ''}'.trim();
  return <String, Object?>{
    'seat_id': _jsonId(seatId.isEmpty ? '0' : seatId),
    'id': _jsonId(bookId.isEmpty ? '0' : bookId),
    'customer_phone': '${fields['customer_phone'] ?? ''}',
    'customer_name': '${fields['customer_name'] ?? ''}',
    'sales_emp_id': _jsonId(salesEmpId.isEmpty ? '0' : salesEmpId),
    'sales_name': '${fields['sales_name'] ?? ''}',
    'second_sales_emp_id': _jsonId(
      secondSalesEmpId.isEmpty ? '0' : secondSalesEmpId,
    ),
    'second_sales_name': '${fields['second_sales_name'] ?? ''}',
    'customer_cnt': _fieldNumber(fields['customer_cnt']).toInt(),
    'min_csm_amt': _fieldNumber(fields['min_csm_amt']),
    'remark': '${fields['remark'] ?? ''}',
    'mark': '${fields['mark'] ?? ''}',
    'old_sales_emp_id': _jsonId(oldSalesEmpId.isEmpty ? '0' : oldSalesEmpId),
    'waiter_emp_id': _jsonId(waiterEmpId.isEmpty ? '0' : waiterEmpId),
    if (expArriveTime.isNotEmpty) 'exp_arrive_time': expArriveTime,
  };
}

Map<String, Object?> _reserveBody({
  required String bookId,
  required Map<String, Object?> fields,
}) {
  final salesEmpId = '${fields['sales_emp_id'] ?? ''}';
  final secondSalesEmpId = '${fields['second_sales_emp_id'] ?? ''}';
  final expSeatId = '${fields['exp_seat_id'] ?? ''}';
  final seatIds = fields['exp_seat_ids'];
  return <String, Object?>{
    'is_this_wkday': _fieldNumber(fields['is_this_wkday']).toInt() == 0
        ? 1
        : _fieldNumber(fields['is_this_wkday']).toInt(),
    'id': bookId.isEmpty ? '' : _jsonId(bookId),
    'customer_phone': '${fields['customer_phone'] ?? ''}',
    'customer_name': '${fields['customer_name'] ?? ''}',
    'auto_send_msg': _fieldNumber(fields['auto_send_msg']).toInt() == 0
        ? 2
        : _fieldNumber(fields['auto_send_msg']).toInt(),
    'book_day': '${fields['book_day'] ?? ''}',
    'exp_arrive_time': '${fields['exp_arrive_time'] ?? ''}',
    'sales_emp_id': _jsonId(salesEmpId.isEmpty ? '0' : salesEmpId),
    'second_sales_emp_id': _jsonId(
      secondSalesEmpId.isEmpty ? '0' : secondSalesEmpId,
    ),
    'customer_exp_cnt': _fieldNumber(fields['customer_exp_cnt']),
    'exp_min_csm_amt': _fieldNumber(fields['exp_min_csm_amt']),
    'exp_region_id': _jsonId('${fields['exp_region_id'] ?? '0'}'),
    'exp_seat_id': _jsonId(expSeatId.isEmpty ? '0' : expSeatId),
    'exp_seat_ids': seatIds is List
        ? [for (final id in seatIds) _jsonId('$id')]
        : <Object>[_jsonId(expSeatId.isEmpty ? '0' : expSeatId)],
    'remark': '${fields['remark'] ?? ''}',
    'mark': '${fields['mark'] ?? ''}',
  };
}

num _fieldNumber(Object? value) => switch (value) {
  num() => value,
  String() => num.tryParse(value) ?? 0,
  _ => 0,
};

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
  code: 'protocol.booking_card_shape',
  safeMessage: '预定卡台操作返回了无法识别的数据',
);
