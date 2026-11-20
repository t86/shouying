import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

/// 1. 开台记录行数据模型
final class SeatOpenLogRow {
  const SeatOpenLogRow({
    required this.regionName,
    required this.seatName,
    required this.salesDeptName,
    required this.salesEmpName,
    required this.mark,
    required this.minConsumeProgress,
    required this.orderAmountYuan,
    required this.customerPhone,
    required this.customerName,
    required this.customerCount,
    required this.salesPhone,
    required this.salesCode,
    required this.openTime,
    required this.clearTime,
    required this.jointSalesName,
    required this.jointDeptName,
    required this.remark,
    required this.operatorName,
  });

  factory SeatOpenLogRow.fromWire(Map<String, Object?> source) {
    final om = source['om'];
    final omYuan = switch (om) {
      num() => (om / 100).toStringAsFixed(2),
      String() => (num.tryParse(om) ?? 0) / 100 > 0
          ? ((num.tryParse(om) ?? 0) / 100).toStringAsFixed(2)
          : '',
      _ => '',
    };
    final mp = source['mp'];
    final mpText = switch (mp) {
      null => '',
      num() => '$mp%',
      String() => mp.endsWith('%') ? mp : '$mp%',
      _ => '',
    };

    return SeatOpenLogRow(
      regionName: _str(source['rn']),
      seatName: _str(source['sn']),
      salesDeptName: _str(source['sd']),
      salesEmpName: _str(source['sen']),
      mark: _str(source['m']),
      minConsumeProgress: mpText,
      orderAmountYuan: omYuan,
      customerPhone: _str(source['cp']),
      customerName: _str(source['cn']),
      customerCount: _str(source['cc']),
      salesPhone: _str(source['sp']),
      salesCode: _str(source['sc']),
      openTime: _str(source['ot']),
      clearTime: _str(source['tt']),
      jointSalesName: _str(source['s']),
      jointDeptName: _str(source['d']),
      remark: _str(source['r']),
      operatorName: _str(source['on']),
    );
  }

  final String regionName;
  final String seatName;
  final String salesDeptName;
  final String salesEmpName;
  final String mark;
  final String minConsumeProgress;
  final String orderAmountYuan;
  final String customerPhone;
  final String customerName;
  final String customerCount;
  final String salesPhone;
  final String salesCode;
  final String openTime;
  final String clearTime;
  final String jointSalesName;
  final String jointDeptName;
  final String remark;
  final String operatorName;
}

/// 2. 转台记录行数据模型
final class SeatChangeLogRow {
  const SeatChangeLogRow({
    required this.openTime,
    required this.detailList,
  });

  factory SeatChangeLogRow.fromWire(Map<String, Object?> source) {
    final rawInfo = _str(source['i']);
    final details = rawInfo.isEmpty
        ? const <String>[]
        : rawInfo.split('\n').where((line) => line.trim().isNotEmpty).toList();
    return SeatChangeLogRow(
      openTime: _str(source['o']),
      detailList: List<String>.unmodifiable(details),
    );
  }

  final String openTime;
  final List<String> detailList;
}

/// 3. 预留记录行数据模型
final class BookListRow {
  const BookListRow({
    required this.bookTime,
    required this.customerName,
    required this.customerPhone,
    required this.salesDeptName,
    required this.salesEmpName,
    required this.regionName,
    required this.seatName,
    required this.mark,
    required this.status,
    required this.statusChgTime,
    required this.remark,
    required this.operatorName,
  });

  factory BookListRow.fromWire(Map<String, Object?> source) {
    return BookListRow(
      bookTime: _str(source['b']),
      customerName: _str(source['n']),
      customerPhone: _str(source['p']),
      salesDeptName: _str(source['d']),
      salesEmpName: _str(source['e']),
      regionName: _str(source['r']),
      seatName: _str(source['sn']),
      mark: _str(source['m']),
      status: _str(source['s']),
      statusChgTime: _str(source['c']),
      remark: _str(source['rm']),
      operatorName: _str(source['on']),
    );
  }

  final String bookTime;
  final String customerName;
  final String customerPhone;
  final String salesDeptName;
  final String salesEmpName;
  final String regionName;
  final String seatName;
  final String mark;
  final String status;
  final String statusChgTime;
  final String remark;
  final String operatorName;
}

/// 4. 线上预订记录行数据模型
final class OnlineBookListRow {
  const OnlineBookListRow({
    required this.seatName,
    required this.regionName,
    required this.customerName,
    required this.customerPhone,
    required this.orderTime,
    required this.openTime,
    required this.prepayAmount,
    required this.usedAmount,
    required this.balanceAmount,
    required this.refundAmount,
    required this.status,
    required this.remark,
  });

  factory OnlineBookListRow.fromWire(Map<String, Object?> source) {
    return OnlineBookListRow(
      seatName: _str(source['s']),
      regionName: _str(source['rn']),
      customerName: _str(source['c']),
      customerPhone: _str(source['p']),
      orderTime: _str(source['o']),
      openTime: _str(source['ot']),
      prepayAmount: _str(source['pa']),
      usedAmount: _str(source['ua']),
      balanceAmount: _str(source['b']),
      refundAmount: _str(source['ba']),
      status: _str(source['st']),
      remark: _str(source['r']),
    );
  }

  final String seatName;
  final String regionName;
  final String customerName;
  final String customerPhone;
  final String orderTime;
  final String openTime;
  final String prepayAmount;
  final String usedAmount;
  final String balanceAmount;
  final String refundAmount;
  final String status;
  final String remark;
}

/// 5. 入客数据实时汇总行数据模型
final class SeatOpeningRow {
  const SeatOpeningRow({
    required this.name,
    required this.c20,
    required this.c21,
    required this.c22,
    required this.c23,
    required this.c00,
    required this.c01,
    required this.c02,
    required this.c03,
    required this.c04,
    required this.c05,
    required this.c06,
  });

  factory SeatOpeningRow.fromWire(Map<String, Object?> source) {
    return SeatOpeningRow(
      name: _str(source['n']),
      c20: _numStr(source['c20']),
      c21: _numStr(source['c21']),
      c22: _numStr(source['c22']),
      c23: _numStr(source['c23']),
      c00: _numStr(source['c00']),
      c01: _numStr(source['c01']),
      c02: _numStr(source['c02']),
      c03: _numStr(source['c03']),
      c04: _numStr(source['c04']),
      c05: _numStr(source['c05']),
      c06: _numStr(source['c06']),
    );
  }

  final String name;
  final String c20;
  final String c21;
  final String c22;
  final String c23;
  final String c00;
  final String c01;
  final String c02;
  final String c03;
  final String c04;
  final String c05;
  final String c06;
}

/// 6. 部门实时订台/区域开台项与报表数据
final class DeptRegionItem {
  const DeptRegionItem({
    required this.id,
    required this.name,
    required this.count,
    this.indent = 0,
    this.isTotal = false,
  });

  factory DeptRegionItem.fromWire(Map<String, Object?> source, {bool isDept = false}) {
    final rawId = source['id'];
    final idNum = switch (rawId) {
      num() => rawId.toInt(),
      String() => int.tryParse(rawId) ?? -1,
      _ => -1,
    };
    final isTotal = idNum == 0;
    final rawName = _str(source['n']);

    if (isTotal) {
      return DeptRegionItem(
        id: idNum,
        name: '合计',
        count: _numStr(source['c']),
        indent: 0,
        isTotal: true,
      );
    }

    var indent = 0;
    var nameStart = 0;
    if (isDept) {
      while (nameStart < rawName.length && RegExp(r'\s').hasMatch(rawName[nameStart])) {
        indent += rawName[nameStart] == '\u3000' ? 2 : 1;
        nameStart += 1;
      }
    }
    final displayName = nameStart > 0 ? rawName.substring(nameStart) : rawName;

    return DeptRegionItem(
      id: idNum,
      name: displayName,
      count: _numStr(source['c']),
      indent: indent,
      isTotal: false,
    );
  }

  final int id;
  final String name;
  final String count;
  final int indent;
  final bool isTotal;
}

final class DeptRegionSeatOpenData {
  const DeptRegionSeatOpenData({
    required this.nowTime,
    required this.deptList,
    required this.regionList,
  });

  final String nowTime;
  final List<DeptRegionItem> deptList;
  final List<DeptRegionItem> regionList;
}

/// 辅助工具方法
String _str(Object? val) => val == null ? '' : val.toString().trim();
String _numStr(Object? val) => val == null ? '0' : val.toString().trim();

/// API 实现类
final class ProtocolBookingReportsApi {
  const ProtocolBookingReportsApi({required this.client});
  final ProtocolClient client;

  /// 1. 开台记录
  Future<Result<List<SeatOpenLogRow>>> getSeatOpenLog({
    ClientKind client = ClientKind.booking,
    String key = '',
    int deptId = 0,
    int typeId = 1,
  }) async {
    final response = await this.client.post(
      '/sel/rpt/get_seat_open_log',
      body: <String, Object?>{
        'key': key,
        'dept_id': deptId,
        'type_id': typeId,
      },
      client: client,
    );
    return _parseList(response, '开台记录', (m) => SeatOpenLogRow.fromWire(m));
  }

  /// 2. 转台记录
  Future<Result<List<SeatChangeLogRow>>> getSeatChangeLog({
    ClientKind client = ClientKind.booking,
  }) async {
    final response = await this.client.postWithoutBody(
      '/bk/get_chg_seat_log',
      client: client,
    );
    return _parseList(response, '转台记录', (m) => SeatChangeLogRow.fromWire(m));
  }

  /// 3. 预留记录
  Future<Result<List<BookListRow>>> getBookList({
    ClientKind client = ClientKind.booking,
  }) async {
    final response = await this.client.postWithoutBody(
      '/sel/rpt/get_book_list',
      client: client,
    );
    return _parseList(response, '预留记录', (m) => BookListRow.fromWire(m));
  }

  /// 4. 线上预订记录
  Future<Result<List<OnlineBookListRow>>> getOnlineBookList({
    ClientKind client = ClientKind.booking,
  }) async {
    final response = await this.client.postWithoutBody(
      '/sel/rpt/get_ol_book_list',
      client: client,
    );
    return _parseList(response, '线上预订记录', (m) => OnlineBookListRow.fromWire(m));
  }

  /// 5. 入客数据实时汇总
  Future<Result<List<SeatOpeningRow>>> getSeatOpeningList({
    ClientKind client = ClientKind.booking,
  }) async {
    final response = await this.client.post(
      '/sel/rpt/get_seat_opening_list',
      body: const <String, Object?>{},
      client: client,
    );
    return _parseList(response, '入客数据实时汇总', (m) => SeatOpeningRow.fromWire(m));
  }

  /// 6. 部门实时订台/区域开台
  Future<Result<DeptRegionSeatOpenData>> getDeptRegionSeatOpenList({
    ClientKind client = ClientKind.booking,
  }) async {
    final response = await this.client.post(
      '/sel/rpt/get_dept_region_seat_open_list',
      body: const <String, Object?>{},
      client: client,
    );
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null || code != 1) {
      final msg = envelope['msg'];
      return FailureResult(AppFailure(
        kind: FailureKind.business,
        code: 'business.dept_region_report_rejected',
        safeMessage: msg is String && msg.isNotEmpty ? msg : '服务端拒绝查询部门/区域开台表',
      ));
    }
    final data = envelope['data'];
    if (data is! Map<String, Object?>) {
      return const FailureResult(AppFailure(
        kind: FailureKind.protocol,
        code: 'protocol.dept_region_shape',
        safeMessage: '数据格式错误',
      ));
    }

    final rawDeptList = data['dept_list'];
    final rawRegionList = data['region_list'];
    final nowTime = _str(data['now_time'] ?? envelope['now_time']);

    final deptList = <DeptRegionItem>[];
    if (rawDeptList is List) {
      for (final item in rawDeptList) {
        if (item is Map<String, Object?>) {
          deptList.add(DeptRegionItem.fromWire(item, isDept: true));
        }
      }
    }

    final regionList = <DeptRegionItem>[];
    if (rawRegionList is List) {
      for (final item in rawRegionList) {
        if (item is Map<String, Object?>) {
          regionList.add(DeptRegionItem.fromWire(item, isDept: false));
        }
      }
    }

    return Success(DeptRegionSeatOpenData(
      nowTime: nowTime,
      deptList: List.unmodifiable(deptList),
      regionList: List.unmodifiable(regionList),
    ));
  }

  /// 导出 1. 开台记录 Excel
  Future<Result<ProtocolBinaryFile>> exportSeatOpenLog({
    ClientKind client = ClientKind.booking,
    String key = '',
    int typeId = 1,
    bool Function()? canDispatch,
  }) => this.client.postBinary(
    '/sel/rpt/exp_seat_open_log',
    body: <String, Object?>{'key': key, 'type_id': typeId},
    client: client,
    fallbackFileName: '开台记录.xlsx',
    canDispatch: canDispatch,
  );

  /// 导出 2. 预留记录 Excel
  Future<Result<ProtocolBinaryFile>> exportBookList({
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => this.client.postBinary(
    '/sel/rpt/exp_book_list',
    body: null,
    client: client,
    fallbackFileName: '预留记录.xlsx',
    canDispatch: canDispatch,
  );

  /// 导出 3. 线上预订记录 Excel
  Future<Result<ProtocolBinaryFile>> exportOnlineBookList({
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => this.client.postBinary(
    '/sel/rpt/exp_ol_book_list',
    body: null,
    client: client,
    fallbackFileName: '线上预订记录.xlsx',
    canDispatch: canDispatch,
  );

  /// 导出 4. 入客数据实时汇总 Excel
  Future<Result<ProtocolBinaryFile>> exportSeatOpeningList({
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => this.client.postBinary(
    '/sel/rpt/exp_seat_opening_list',
    body: const <String, Object?>{},
    client: client,
    fallbackFileName: '入客数据实时汇总.xlsx',
    canDispatch: canDispatch,
  );

  /// 导出 5. 部门实时订台/区域开台 Excel
  Future<Result<ProtocolBinaryFile>> exportDeptRegionSeatOpenList({
    ClientKind client = ClientKind.booking,
    bool Function()? canDispatch,
  }) => this.client.postBinary(
    '/sel/rpt/exp_dept_region_seat_open_list',
    body: const <String, Object?>{},
    client: client,
    fallbackFileName: '部门实时订台区域开台.xlsx',
    canDispatch: canDispatch,
  );

  static Result<List<T>> _parseList<T>(
    Result<Map<String, Object?>> response,
    String reportName,
    T Function(Map<String, Object?>) mapper,
  ) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null || code != 1) {
      final msg = envelope['msg'];
      return FailureResult(AppFailure(
        kind: FailureKind.business,
        code: 'business.${reportName}_rejected',
        safeMessage: msg is String && msg.isNotEmpty ? msg : '服务端拒绝查询$reportName',
      ));
    }
    final data = envelope['data'];
    if (data is! Map<String, Object?>) {
      return FailureResult(AppFailure(
        kind: FailureKind.protocol,
        code: 'protocol.${reportName}_shape',
        safeMessage: '$reportName返回数据格式错误',
      ));
    }
    final records = data['records'];
    if (records == null) return const Success([]);
    if (records is! List) {
      return FailureResult(AppFailure(
        kind: FailureKind.protocol,
        code: 'protocol.${reportName}_shape',
        safeMessage: '$reportName返回记录格式错误',
      ));
    }
    final list = <T>[];
    for (final r in records) {
      if (r is Map<String, Object?>) {
        list.add(mapper(r));
      }
    }
    return Success(List<T>.unmodifiable(list));
  }

  static int? _wireCode(Object? value) => switch (value) {
    num() when value.isFinite && value % 1 == 0 => value.toInt(),
    String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(value),
    _ => null,
  };
}
