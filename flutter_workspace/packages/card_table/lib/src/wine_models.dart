/// 存酒待入库记录 (S5.P1)
final class WineSaveRecord {
  const WineSaveRecord({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.seatName,
    required this.salesName,
    required this.waiterName,
    required this.saveTime,
    this.remark = '',
    this.items = const <WineSaveSubItem>[],
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final String seatName;
  final String salesName;
  final String waiterName;
  final String saveTime;
  final String remark;
  final List<WineSaveSubItem> items;

  factory WineSaveRecord.fromWire(Map<Object?, Object?> map) {
    final subList = map['ss'];
    return WineSaveRecord(
      id: '${map['o'] ?? map['id'] ?? ''}',
      customerName: '${map['c'] ?? map['customer_name'] ?? ''}',
      customerPhone: '${map['p'] ?? map['customer_phone'] ?? ''}',
      seatName: '${map['s'] ?? map['seat_name'] ?? ''}',
      salesName: '${map['e'] ?? map['sales_name'] ?? ''}',
      waiterName: '${map['w'] ?? map['waiter_name'] ?? ''}',
      saveTime: '${map['t'] ?? map['time'] ?? ''}',
      remark: '${map['r'] ?? map['remark'] ?? ''}',
      items: [
        if (subList is List)
          for (final item in subList)
            if (item is Map)
              WineSaveSubItem.fromWire(Map<Object?, Object?>.from(item)),
      ],
    );
  }
}

/// 存酒待入库子明细
final class WineSaveSubItem {
  const WineSaveSubItem({
    required this.name,
    required this.unit,
    required this.count,
    this.gram = '',
    this.expireTime = '',
    this.auther = '',
  });

  final String name;
  final String unit;
  final int count;
  final String gram;
  final String expireTime;
  final String auther;

  factory WineSaveSubItem.fromWire(Map<Object?, Object?> map) {
    return WineSaveSubItem(
      name: '${map['n'] ?? map['prd_name'] ?? ''}',
      unit: '${map['u'] ?? map['unit_name'] ?? ''}',
      count: (map['c'] is num) ? (map['c'] as num).toInt() : (int.tryParse('${map['c'] ?? 1}') ?? 1),
      gram: '${map['g'] ?? ''}',
      expireTime: '${map['e'] ?? map['expired_time'] ?? ''}',
      auther: '${map['a'] ?? map['auther_name'] ?? ''}',
    );
  }
}

/// 取酒待出库记录 (S5.P2)
final class WineGetRecord {
  const WineGetRecord({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.seatName,
    required this.salesName,
    required this.waiterName,
    required this.getTime,
    this.superCode = '',
    this.isBlack = false,
    this.items = const <WineGetSubItem>[],
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final String seatName;
  final String salesName;
  final String waiterName;
  final String getTime;
  final String superCode;
  final bool isBlack;
  final List<WineGetSubItem> items;

  factory WineGetRecord.fromWire(Map<Object?, Object?> map) {
    final subList = map['ss'];
    return WineGetRecord(
      id: '${map['o'] ?? map['id'] ?? ''}',
      customerName: '${map['c'] ?? map['customer_name'] ?? ''}',
      customerPhone: '${map['p'] ?? map['customer_phone'] ?? ''}',
      seatName: '${map['s'] ?? map['seat_name'] ?? ''}',
      salesName: '${map['e'] ?? map['sales_name'] ?? ''}',
      waiterName: '${map['w'] ?? map['waiter_name'] ?? ''}',
      getTime: '${map['t'] ?? map['time'] ?? ''}',
      superCode: '${map['us'] ?? ''}',
      isBlack: map['b'] == 1 || '${map['b'] ?? ''}' == '1',
      items: [
        if (subList is List)
          for (final item in subList)
            if (item is Map)
              WineGetSubItem.fromWire(Map<Object?, Object?>.from(item)),
      ],
    );
  }
}

/// 取酒待出库子明细
final class WineGetSubItem {
  const WineGetSubItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.count,
    this.gram = '',
    this.saveSeat = '',
    this.saveSales = '',
    this.expireTime = '',
    this.auther = '',
    this.remark = '',
  });

  final String id;
  final String name;
  final String unit;
  final int count;
  final String gram;
  final String saveSeat;
  final String saveSales;
  final String expireTime;
  final String auther;
  final String remark;

  factory WineGetSubItem.fromWire(Map<Object?, Object?> map) {
    return WineGetSubItem(
      id: '${map['i'] ?? map['invt_id'] ?? map['id'] ?? ''}',
      name: '${map['n'] ?? map['prd_name'] ?? ''}',
      unit: '${map['u'] ?? map['unit_name'] ?? ''}',
      count: (map['c'] is num) ? (map['c'] as num).toInt() : (int.tryParse('${map['c'] ?? 1}') ?? 1),
      gram: '${map['g'] ?? ''}',
      saveSeat: '${map['ss'] ?? ''}',
      saveSales: '${map['s'] ?? ''}',
      expireTime: '${map['e'] ?? map['expired_time'] ?? ''}',
      auther: '${map['a'] ?? map['auther_name'] ?? ''}',
      remark: '${map['w'] ?? map['remark'] ?? ''}',
    );
  }
}

/// 存酒库存项 (S5.P3, S5.P4, S5.P5)
final class WineInventoryItem {
  const WineInventoryItem({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.seatName,
    required this.salesName,
    this.salesDept = '',
    this.waiterName = '',
    this.saveTime = '',
    this.inLibTime = '',
    this.inLibUser = '',
    this.remark = '',
    this.expireTime = '',
    this.daysLeft = 0,
    this.wineName = '',
    this.unit = '',
    this.count = 0,
    this.gram = '',
    this.subOrderNo = '',
    this.items = const <WineInventorySubItem>[],
  });

  final String id;
  final String customerName;
  final String customerPhone;
  final String seatName;
  final String salesName;
  final String salesDept;
  final String waiterName;
  final String saveTime;
  final String inLibTime;
  final String inLibUser;
  final String remark;
  final String expireTime;
  final int daysLeft;
  final String wineName;
  final String unit;
  final int count;
  final String gram;
  final String subOrderNo;
  final List<WineInventorySubItem> items;

  factory WineInventoryItem.fromWire(Map<Object?, Object?> map) {
    final subList = map['ss'];
    return WineInventoryItem(
      id: '${map['id'] ?? map['i'] ?? ''}',
      customerName: '${map['c'] ?? map['cn'] ?? map['customer_name'] ?? ''}',
      customerPhone: '${map['p'] ?? map['customer_phone'] ?? ''}',
      seatName: '${map['s'] ?? map['seat_name'] ?? ''}',
      salesName: '${map['e'] ?? map['se'] ?? map['sales_name'] ?? ''}',
      salesDept: '${map['sd'] ?? map['dept_name'] ?? ''}',
      waiterName: '${map['w'] ?? map['waiter_name'] ?? ''}',
      saveTime: '${map['t'] ?? map['time'] ?? ''}',
      inLibTime: '${map['it'] ?? map['in_time'] ?? ''}',
      inLibUser: '${map['we'] ?? map['in_user'] ?? ''}',
      remark: '${map['r'] ?? map['remark'] ?? ''}',
      expireTime: '${map['e'] ?? map['expired_time'] ?? ''}',
      daysLeft: (map['dl'] is num) ? (map['dl'] as num).toInt() : (int.tryParse('${map['dl'] ?? 0}') ?? 0),
      wineName: '${map['n'] ?? map['prd_name'] ?? ''}',
      unit: '${map['u'] ?? map['unit_name'] ?? ''}',
      count: (map['c'] is num) ? (map['c'] as num).toInt() : (int.tryParse('${map['c'] ?? 0}') ?? 0),
      gram: '${map['g'] ?? ''}',
      subOrderNo: '${map['i'] ?? map['sub_order_no'] ?? ''}',
      items: [
        if (subList is List)
          for (final item in subList)
            if (item is Map)
              WineInventorySubItem.fromWire(Map<Object?, Object?>.from(item)),
      ],
    );
  }
}

/// 存酒库子明细
final class WineInventorySubItem {
  const WineInventorySubItem({
    required this.id,
    required this.wineName,
    required this.unit,
    required this.count,
    this.gram = '',
    this.expireTime = '',
    this.auther = '',
    this.daysLeft = 0,
  });

  final String id;
  final String wineName;
  final String unit;
  final int count;
  final String gram;
  final String expireTime;
  final String auther;
  final int daysLeft;

  factory WineInventorySubItem.fromWire(Map<Object?, Object?> map) {
    return WineInventorySubItem(
      id: '${map['id'] ?? map['i'] ?? ''}',
      wineName: '${map['n'] ?? map['prd_name'] ?? ''}',
      unit: '${map['u'] ?? map['unit_name'] ?? ''}',
      count: (map['c'] is num) ? (map['c'] as num).toInt() : (int.tryParse('${map['c'] ?? 1}') ?? 1),
      gram: '${map['g'] ?? ''}',
      expireTime: '${map['e'] ?? map['expired_time'] ?? ''}',
      auther: '${map['a'] ?? map['auther_name'] ?? ''}',
      daysLeft: (map['dl'] is num) ? (map['dl'] as num).toInt() : (int.tryParse('${map['dl'] ?? 0}') ?? 0),
    );
  }
}

/// 存酒库存网格明细 (S5.P6)
final class WineGridItem {
  const WineGridItem({
    this.id = '',
    this.wineName = '',
    this.unit = '',
    this.totalCount = 0,
    this.normalCount = 0,
    this.expiredCount = 0,
    this.productName = '',
    this.wholeBottle = '',
    this.partials = const <String, String>{},
  });

  final String id;
  final String wineName;
  final String unit;
  final int totalCount;
  final int normalCount;
  final int expiredCount;
  final String productName;
  final String wholeBottle;
  final Map<String, String> partials;

  factory WineGridItem.fromWire(Map<Object?, Object?> map) {
    final prdName = '${map['p'] ?? map['prd_name'] ?? map['n'] ?? ''}';
    return WineGridItem(
      id: '${map['id'] ?? map['prd_id'] ?? ''}',
      wineName: prdName,
      productName: prdName,
      unit: '${map['unit_name'] ?? map['u'] ?? ''}',
      totalCount: (map['total_cnt'] is num) ? (map['total_cnt'] as num).toInt() : (int.tryParse('${map['total_cnt'] ?? 0}') ?? 0),
      normalCount: (map['normal_cnt'] is num) ? (map['normal_cnt'] as num).toInt() : (int.tryParse('${map['normal_cnt'] ?? 0}') ?? 0),
      expiredCount: (map['expired_cnt'] is num) ? (map['expired_cnt'] as num).toInt() : (int.tryParse('${map['expired_cnt'] ?? 0}') ?? 0),
      wholeBottle: '${map['p10'] ?? map['whole_bottle'] ?? map['wholeBottle'] ?? ''}',
      partials: {
        for (var i = 1; i <= 9; i++)
          '0.$i': '${map['p$i'] ?? ''}',
      },
    );
  }
}

/// 充公流转记录 (S5.P7)
final class WineConfiscateItem {
  const WineConfiscateItem({
    required this.id,
    required this.seatName,
    required this.customerName,
    required this.customerPhone,
    required this.salesName,
    required this.wineName,
    required this.unit,
    required this.count,
    this.expireTime = '',
    this.reason = '',
    this.orderNo = '',
    this.status = 0,
  });

  final String id;
  final String seatName;
  final String customerName;
  final String customerPhone;
  final String salesName;
  final String wineName;
  final String unit;
  final int count;
  final String expireTime;
  final String reason;
  final String orderNo;
  final int status;

  factory WineConfiscateItem.fromWire(Map<Object?, Object?> map) {
    return WineConfiscateItem(
      id: '${map['id'] ?? ''}',
      seatName: '${map['s'] ?? map['seat_name'] ?? ''}',
      customerName: '${map['c'] ?? map['customer_name'] ?? ''}',
      customerPhone: '${map['p'] ?? map['customer_phone'] ?? ''}',
      salesName: '${map['e'] ?? map['sales_name'] ?? ''}',
      wineName: '${map['n'] ?? map['prd_name'] ?? ''}',
      unit: '${map['u'] ?? map['unit_name'] ?? ''}',
      count: (map['c'] is num) ? (map['c'] as num).toInt() : (int.tryParse('${map['c'] ?? 1}') ?? 1),
      expireTime: '${map['e'] ?? map['expired_time'] ?? ''}',
      reason: '${map['r'] ?? map['reason'] ?? ''}',
      orderNo: '${map['order_no'] ?? ''}',
      status: (map['status'] is num) ? (map['status'] as num).toInt() : (int.tryParse('${map['status'] ?? 0}') ?? 0),
    );
  }
}

/// 存酒客户配置项 (S5.P8)
final class WineCustomerItem {
  const WineCustomerItem({
    required this.id,
    required this.name,
    required this.phone,
    this.enableSms = true,
    this.saveCount = 0,
    this.wineCount = 0,
    this.isBlacklist = false,
  });

  final String id;
  final String name;
  final String phone;
  final bool enableSms;
  final int saveCount;
  final int wineCount;
  final bool isBlacklist;

  bool get isSmsOpen => enableSms;

  factory WineCustomerItem.fromWire(Map<Object?, Object?> map) {
    return WineCustomerItem(
      id: '${map['id'] ?? map['cust_id'] ?? ''}',
      name: '${map['name'] ?? map['cust_name'] ?? ''}',
      phone: '${map['phone'] ?? map['cust_phone'] ?? ''}',
      enableSms: map['enable_sms'] != 0 && '${map['enable_sms'] ?? ''}' != '0',
      saveCount: (map['save_cnt'] is num) ? (map['save_cnt'] as num).toInt() : (int.tryParse('${map['save_cnt'] ?? 0}') ?? 0),
      wineCount: (map['wine_cnt'] is num) ? (map['wine_cnt'] as num).toInt() : (int.tryParse('${map['wine_cnt'] ?? 0}') ?? 0),
      isBlacklist: map['is_black'] == 1 || '${map['is_black'] ?? ''}' == '1',
    );
  }
}

/// 黑名单项 (S5.P8)
final class WineBlacklistItem {
  const WineBlacklistItem({
    required this.id,
    required this.phone,
    this.remark = '',
    this.createTime = '',
  });

  final String id;
  final String phone;
  final String remark;
  final String createTime;

  factory WineBlacklistItem.fromWire(Map<Object?, Object?> map) {
    return WineBlacklistItem(
      id: '${map['id'] ?? ''}',
      phone: '${map['phone'] ?? ''}',
      remark: '${map['remark'] ?? ''}',
      createTime: '${map['create_time'] ?? ''}',
    );
  }
}

/// 借还酒水项 (S5.P11)
final class WineBorrowReturnPage {
  WineBorrowReturnPage({required Iterable<WineBorrowReturnItem> items, required this.total}) : items = List.unmodifiable(items);
  final List<WineBorrowReturnItem> items;
  final int total;
}

final class WineBorrowReturnItem {
  const WineBorrowReturnItem({
    required this.id,
    required this.type, // 1: 借酒, 2: 还酒
    required this.wineName,
    required this.unit,
    required this.count,
    required this.personName,
    required this.opTime,
    this.status = 0, // 0: 未还, 1: 已还
    this.remark = '',
    this.orderNo = '',
    this.borrower = '',
    this.operator = '',
  });

  final String id;
  final int type;
  final String wineName;
  final String unit;
  final int count;
  final String personName;
  final String opTime;
  final int status;
  final String remark;
  final String orderNo;
  final String borrower;
  final String operator;

  String get borrowerName => borrower.isNotEmpty ? borrower : personName;
  String get operatorName => operator.isNotEmpty ? operator : personName;
  String get operateTime => opTime;

  factory WineBorrowReturnItem.fromWire(Map<Object?, Object?> map) {
    final person = '${map['bre'] ?? map['person_name'] ?? map['borrower'] ?? map['operator'] ?? map['p'] ?? ''}';
    return WineBorrowReturnItem(
      id: '${map['id'] ?? ''}',
      type: int.tryParse('${map['t'] ?? map['op_type'] ?? 1}') ?? 1,
      wineName: '${map['prd_name'] ?? map['wine_name'] ?? map['n'] ?? ''}',
      unit: '${map['unit_name'] ?? ''}',
      count: int.tryParse('${map['c'] ?? map['count'] ?? map['cnt'] ?? 0}') ?? 0,
      personName: person,
      opTime: '${map['u'] ?? map['op_time'] ?? ''}',
      status: (map['status'] is num) ? (map['status'] as num).toInt() : (int.tryParse('${map['status'] ?? 0}') ?? 0),
      remark: '${map['r'] ?? map['remark'] ?? ''}',
      orderNo: '${map['order_no'] ?? map['orderNo'] ?? map['id'] ?? ''}',
      borrower: '${map['bre'] ?? map['borrower'] ?? ''}',
      operator: '${map['oe'] ?? map['operator'] ?? ''}',
    );
  }
}

/// 通用报表数据行 (S5.P10)
final class WineReportRow {
  const WineReportRow({required this.data});

  final Map<String, Object?> data;

  String get(String key, [String fallback = '']) => '${data[key] ?? fallback}';

  factory WineReportRow.fromWire(Map<Object?, Object?> map) {
    return WineReportRow(
      data: map.map((k, v) => MapEntry('$k', v)),
    );
  }
}
