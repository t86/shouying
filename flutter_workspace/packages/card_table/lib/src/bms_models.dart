// =============================================================================
// S7.P1 人员管理数据模型
// =============================================================================

/// S7.P1.T01 工号生成规则
final class BmsGenRule {
  const BmsGenRule({
    this.passwdUseCode = 1,
    this.fixedPasswd = '666666',
    this.codeLength = 6,
  });

  final int passwdUseCode;
  final String fixedPasswd;
  final int codeLength;

  factory BmsGenRule.fromWire(Map<String, Object?> wire) {
    return BmsGenRule(
      passwdUseCode: int.tryParse('${wire['passwd_use_code']}') ?? 1,
      fixedPasswd: wire['fixed_passwd']?.toString().isNotEmpty == true
          ? wire['fixed_passwd'].toString()
          : '666666',
      codeLength: switch (int.tryParse('${wire['code_length']}')) {
        final int length when length != 0 => length,
        _ => 6,
      },
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'passwd_use_code': passwdUseCode,
    'fixed_passwd': fixedPasswd,
    'code_length': codeLength,
  };
}

/// S7.P1.T02 ~ T06 岗位信息
final class BmsStationItem {
  const BmsStationItem({
    required this.id,
    required this.name,
    this.desc = '',
    this.status = 1,
    this.isWaiter = false,
    this.isCashier = false,
    this.waiterRegions = const <String>[],
    this.waiterCates = const <String>[],
    this.sysPrivs = const <String>[],
  });

  final String id;
  final String name;
  final String desc;
  final int status; // 1 有效, 0 无效
  final bool isWaiter;
  final bool isCashier;
  final List<String> waiterRegions;
  final List<String> waiterCates;
  final List<String> sysPrivs;

  bool get isValid => status == 1;

  factory BmsStationItem.fromWire(Map<String, Object?> wire) {
    return BmsStationItem(
      id: wire['id']?.toString() ?? wire['station_id']?.toString() ?? '',
      name:
          wire['n']?.toString() ??
          wire['name']?.toString() ??
          wire['station_name']?.toString() ??
          '',
      desc: wire['desc']?.toString() ?? wire['remark']?.toString() ?? '',
      status: (wire['status'] as num?)?.toInt() ?? 1,
      isWaiter:
          (wire['is_waiter'] as num?)?.toInt() == 1 ||
          wire['is_waiter'] == true,
      isCashier:
          (wire['is_cashier'] as num?)?.toInt() == 1 ||
          wire['is_cashier'] == true,
      waiterRegions:
          (wire['waiter_regions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      waiterCates:
          (wire['waiter_cates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      sysPrivs:
          (wire['sys_privs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'desc': desc,
    'status': status,
    'is_waiter': isWaiter ? 1 : 0,
    'is_cashier': isCashier ? 1 : 0,
    'waiter_regions': waiterRegions,
    'waiter_cates': waiterCates,
    'sys_privs': sysPrivs,
  };
}

/// S7.P1.T07 ~ T10 员工信息
final class BmsEmployeeItem {
  const BmsEmployeeItem({
    required this.id,
    required this.name,
    this.empNo = '',
    this.phone = '',
    this.stationId = '',
    this.stationName = '',
    this.deptId = '',
    this.deptName = '',
    this.status = 1,
    this.isLeader = false,
  });

  final String id;
  final String name;
  final String empNo;
  final String phone;
  final String stationId;
  final String stationName;
  final String deptId;
  final String deptName;
  final int status;
  final bool isLeader;

  bool get isValid => status == 1;

  factory BmsEmployeeItem.fromWire(Map<String, Object?> wire) {
    return BmsEmployeeItem(
      id: wire['id']?.toString() ?? wire['emp_id']?.toString() ?? '',
      name:
          wire['n']?.toString() ??
          wire['name']?.toString() ??
          wire['emp_name']?.toString() ??
          '',
      empNo:
          wire['cd']?.toString() ??
          wire['c']?.toString() ??
          wire['emp_no']?.toString() ??
          wire['no']?.toString() ??
          '',
      phone: wire['phone']?.toString() ?? wire['mobile']?.toString() ?? '',
      stationId: wire['station_id']?.toString() ?? '',
      stationName: wire['station_name']?.toString() ?? '',
      deptId: wire['dept_id']?.toString() ?? '',
      deptName:
          wire['dn']?.toString() ??
          wire['deptName']?.toString() ??
          wire['dept_name']?.toString() ??
          '',
      status: (wire['status'] as num?)?.toInt() ?? 1,
      isLeader:
          (wire['is_leader'] as num?)?.toInt() == 1 ||
          wire['is_leader'] == true,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'emp_no': empNo,
    'phone': phone,
    'station_id': stationId,
    'station_name': stationName,
    'dept_id': deptId,
    'dept_name': deptName,
    'status': status,
    'is_leader': isLeader ? 1 : 0,
  };
}

/// S7.P1.T11 入职审批项
final class BmsOnboardingApprovalItem {
  const BmsOnboardingApprovalItem({
    required this.id,
    required this.name,
    this.phone = '',
    this.applyTime = '',
    this.status = 0, // 0 待审批, 1 已通过, 2 已驳回
    this.stationName = '',
    this.remark = '',
    this.deptId = '',
    this.stationId = '',
    this.upperEmpId = '',
    this.realName = '',
    this.sex = 1,
  });

  final String id;
  final String name;
  final String phone;
  final String applyTime;
  final int status;
  final String stationName;
  final String remark;
  final String deptId, stationId, upperEmpId, realName;
  final int sex;

  factory BmsOnboardingApprovalItem.fromWire(Map<String, Object?> wire) {
    return BmsOnboardingApprovalItem(
      id: wire['id']?.toString() ?? '',
      name: wire['n']?.toString() ?? '',
      phone: wire['p']?.toString() ?? '',
      applyTime: wire['r']?.toString() ?? '',
      status: (wire['status'] as num?)?.toInt() ?? 0,
      stationName: wire['sn']?.toString() ?? '',
      remark: wire['remark']?.toString() ?? '',
      deptId: '${wire['di'] ?? ''}',
      stationId: '${wire['si'] ?? ''}',
      upperEmpId: '${wire['uei'] ?? ''}',
      realName: '${wire['rn'] ?? ''}',
      sex: int.tryParse('${wire['s']}') ?? 1,
    );
  }
}

final class BmsOnboardingPage {
  const BmsOnboardingPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
  });
  final List<BmsOnboardingApprovalItem> items;
  final int total, page, pageSize;
  factory BmsOnboardingPage.fromWire(Map<String, Object?> wire) =>
      BmsOnboardingPage(
        items: (wire['records'] as List? ?? [])
            .whereType<Map<String, Object?>>()
            .map(BmsOnboardingApprovalItem.fromWire)
            .toList(),
        total: int.tryParse('${wire['row_cnt']}') ?? 0,
        page: int.tryParse('${wire['page_num']}') ?? 1,
        pageSize: int.tryParse('${wire['page_size']}') ?? 20,
      );
}

final class BmsDepartmentOption {
  const BmsDepartmentOption(this.id, this.name, {this.children = const []});
  final String id, name;
  final List<BmsDepartmentOption> children;
  factory BmsDepartmentOption.fromWire(Map<String, Object?> wire) =>
      BmsDepartmentOption(
        '${wire['id'] ?? ''}',
        '${wire['n'] ?? ''}',
        children: (wire['subs'] as List? ?? [])
            .whereType<Map<String, Object?>>()
            .map(BmsDepartmentOption.fromWire)
            .toList(),
      );
}

/// S7.P1.T12 商务组订位人
final class BmsBusinessEmpItem {
  const BmsBusinessEmpItem({
    required this.id,
    required this.name,
    this.empNo = '',
    this.phone = '',
    this.isBusiness = true,
    this.deptName = '',
  });

  final String id;
  final String name;
  final String empNo;
  final String phone;
  final bool isBusiness;
  final String deptName;

  factory BmsBusinessEmpItem.fromWire(Map<String, Object?> wire) {
    return BmsBusinessEmpItem(
      id: wire['id']?.toString() ?? wire['emp_id']?.toString() ?? '',
      name: wire['n']?.toString() ?? '',
      empNo: wire['c']?.toString() ?? '',
      phone: wire['phone']?.toString() ?? '',
      isBusiness: true,
      deptName: '${wire['d'] ?? ''}',
    );
  }
}

// =============================================================================
// S7.P2 商品管理数据模型
// =============================================================================

/// S7.P2.T01 一级分类
final class BmsOneCateItem {
  const BmsOneCateItem({
    required this.id,
    required this.name,
    this.sort = 0,
    this.status = 1,
  });

  final String id;
  final String name;
  final int sort;
  final int status;

  factory BmsOneCateItem.fromWire(Map<String, Object?> wire) {
    return BmsOneCateItem(
      id: wire['id']?.toString() ?? wire['ocate_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['ocate_name']?.toString() ?? '',
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'sort': sort,
    'status': status,
  };
}

/// S7.P2.T02 二级分类
final class BmsTwoCateItem {
  const BmsTwoCateItem({
    required this.id,
    required this.oneCateId,
    required this.name,
    this.sort = 0,
    this.status = 1,
  });

  final String id;
  final String oneCateId;
  final String name;
  final int sort;
  final int status;

  factory BmsTwoCateItem.fromWire(Map<String, Object?> wire) {
    return BmsTwoCateItem(
      id: wire['id']?.toString() ?? wire['tcate_id']?.toString() ?? '',
      oneCateId:
          wire['ocate_id']?.toString() ?? wire['one_cate_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['tcate_name']?.toString() ?? '',
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'ocate_id': oneCateId,
    'name': name,
    'sort': sort,
    'status': status,
  };
}

/// S7.P2.T03 ~ T04 商品项
final class BmsProductItem {
  const BmsProductItem({
    required this.id,
    required this.name,
    this.code = '',
    this.oneCateId = '',
    this.twoCateId = '',
    this.price = 0.0,
    this.vipPrice = 0.0,
    this.unit = '份',
    this.status = 1,
    this.isPackage = false,
    this.imgUrl = '',
    this.outLibIds = const <String>[],
    this.sort = 0,
  });

  final String id;
  final String name;
  final String code;
  final String oneCateId;
  final String twoCateId;
  final double price;
  final double vipPrice;
  final String unit;
  final int status;
  final bool isPackage;
  final String imgUrl;
  final List<String> outLibIds;
  final int sort;

  bool get isValid => status == 1;

  factory BmsProductItem.fromWire(Map<String, Object?> wire) {
    return BmsProductItem(
      id: wire['id']?.toString() ?? wire['prd_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['prd_name']?.toString() ?? '',
      code: wire['code']?.toString() ?? wire['prd_code']?.toString() ?? '',
      oneCateId: wire['ocate_id']?.toString() ?? '',
      twoCateId: wire['tcate_id']?.toString() ?? '',
      price: (wire['price'] as num?)?.toDouble() ?? 0.0,
      vipPrice: (wire['vip_price'] as num?)?.toDouble() ?? 0.0,
      unit: wire['unit']?.toString() ?? '份',
      status: (wire['status'] as num?)?.toInt() ?? 1,
      isPackage:
          (wire['is_package'] as num?)?.toInt() == 1 ||
          wire['is_package'] == true,
      imgUrl: wire['img_url']?.toString() ?? '',
      outLibIds:
          (wire['out_lib_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'code': code,
    'ocate_id': oneCateId,
    'tcate_id': twoCateId,
    'price': price,
    'vip_price': vipPrice,
    'unit': unit,
    'status': status,
    'is_package': isPackage ? 1 : 0,
    'img_url': imgUrl,
    'out_lib_ids': outLibIds,
    'sort': sort,
  };
}

/// S7.P2.T06 套餐可选组模板
final class BmsPackageGroupTemplate {
  const BmsPackageGroupTemplate({
    required this.id,
    required this.name,
    this.minSelect = 1,
    this.maxSelect = 1,
    this.items = const <Map<String, Object?>>[],
  });

  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<Map<String, Object?>> items;

  factory BmsPackageGroupTemplate.fromWire(Map<String, Object?> wire) {
    return BmsPackageGroupTemplate(
      id: wire['id']?.toString() ?? '',
      name: wire['name']?.toString() ?? '',
      minSelect: (wire['min_select'] as num?)?.toInt() ?? 1,
      maxSelect: (wire['max_select'] as num?)?.toInt() ?? 1,
      items:
          (wire['items'] as List<dynamic>?)
              ?.whereType<Map<String, Object?>>()
              .toList() ??
          const <Map<String, Object?>>[],
    );
  }
}

// =============================================================================
// S7.P3 卡台管理数据模型
// =============================================================================

/// S7.P3.T01 区域
final class BmsRegionItem {
  const BmsRegionItem({
    required this.id,
    required this.name,
    this.sort = 0,
    this.status = 1,
  });

  final String id;
  final String name;
  final int sort;
  final int status;

  factory BmsRegionItem.fromWire(Map<String, Object?> wire) {
    return BmsRegionItem(
      id: wire['id']?.toString() ?? wire['region_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['region_name']?.toString() ?? '',
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'sort': sort,
    'status': status,
  };
}

/// S7.P3.T02 卡台
final class BmsCardItem {
  const BmsCardItem({
    required this.id,
    required this.name,
    this.regionId = '',
    this.regionName = '',
    this.minCharge = 0.0,
    this.seatNum = 4,
    this.sort = 0,
    this.status = 1,
    this.qrCodeUrl = '',
    this.reqPrds = const <String>[],
  });

  final String id;
  final String name;
  final String regionId;
  final String regionName;
  final double minCharge;
  final int seatNum;
  final int sort;
  final int status;
  final String qrCodeUrl;
  final List<String> reqPrds;

  bool get isValid => status == 1;

  factory BmsCardItem.fromWire(Map<String, Object?> wire) {
    return BmsCardItem(
      id: wire['id']?.toString() ?? wire['seat_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['seat_name']?.toString() ?? '',
      regionId: wire['region_id']?.toString() ?? '',
      regionName: wire['region_name']?.toString() ?? '',
      minCharge: (wire['min_charge'] as num?)?.toDouble() ?? 0.0,
      seatNum: (wire['seat_num'] as num?)?.toInt() ?? 4,
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
      status: (wire['status'] as num?)?.toInt() ?? 1,
      qrCodeUrl: wire['qr_code_url']?.toString() ?? '',
      reqPrds:
          (wire['req_prds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'region_id': regionId,
    'min_charge': minCharge,
    'seat_num': seatNum,
    'sort': sort,
    'status': status,
  };
}

/// S7.P3.T03 卡台抵消组
final class BmsCardMinGroupItem {
  const BmsCardMinGroupItem({
    required this.id,
    required this.name,
    this.minCharge = 0.0,
    this.sort = 0,
    this.cardIds = const <String>[],
  });

  final String id;
  final String name;
  final double minCharge;
  final int sort;
  final List<String> cardIds;

  factory BmsCardMinGroupItem.fromWire(Map<String, Object?> wire) {
    return BmsCardMinGroupItem(
      id: wire['id']?.toString() ?? wire['group_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['group_name']?.toString() ?? '',
      minCharge: (wire['min_charge'] as num?)?.toDouble() ?? 0.0,
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
      cardIds:
          (wire['card_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }
}

/// S7.P3.T04 卡台标签
final class BmsCardTipItem {
  const BmsCardTipItem({
    required this.id,
    required this.name,
    this.color = '#409EFF',
    this.sort = 0,
  });

  final String id;
  final String name;
  final String color;
  final int sort;

  factory BmsCardTipItem.fromWire(Map<String, Object?> wire) {
    return BmsCardTipItem(
      id: wire['id']?.toString() ?? '',
      name: wire['name']?.toString() ?? '',
      color: wire['color']?.toString() ?? '#409EFF',
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
    );
  }
}

/// S7.P3.T05 计抵达规则
final class BmsArriveRuleItem {
  const BmsArriveRuleItem({
    required this.id,
    required this.name,
    this.arriveMin = 30,
    this.arriveRatio = 1.0,
    this.status = 1,
  });

  final String id;
  final String name;
  final int arriveMin;
  final double arriveRatio;
  final int status;

  factory BmsArriveRuleItem.fromWire(Map<String, Object?> wire) {
    return BmsArriveRuleItem(
      id: wire['id']?.toString() ?? '',
      name: wire['name']?.toString() ?? '',
      arriveMin: (wire['arrive_min'] as num?)?.toInt() ?? 30,
      arriveRatio: (wire['arrive_ratio'] as num?)?.toDouble() ?? 1.0,
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }
}

// =============================================================================
// S7.P4 限额限量数据模型
// =============================================================================

/// S7.P4.T01 商品组
final class BmsProductGroupItem {
  const BmsProductGroupItem({
    required this.id,
    required this.name,
    this.prdIds = const <String>[],
    this.remark = '',
  });

  final String id;
  final String name;
  final List<String> prdIds;
  final String remark;

  factory BmsProductGroupItem.fromWire(Map<String, Object?> wire) {
    return BmsProductGroupItem(
      id: wire['id']?.toString() ?? wire['pgrp_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['pgrp_name']?.toString() ?? '',
      prdIds:
          (wire['prd_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      remark: wire['remark']?.toString() ?? '',
    );
  }
}

/// S7.P4.T02 限额限量
final class BmsLimitConfigItem {
  const BmsLimitConfigItem({
    required this.id,
    required this.name,
    this.groupId = '',
    this.groupName = '',
    this.limitType = 1, // 1 限量, 2 限额
    this.maxQty = 0,
    this.maxAmount = 0.0,
    this.startDate = '',
    this.endDate = '',
    this.status = 1,
  });

  final String id;
  final String name;
  final String groupId;
  final String groupName;
  final int limitType;
  final int maxQty;
  final double maxAmount;
  final String startDate;
  final String endDate;
  final int status;

  factory BmsLimitConfigItem.fromWire(Map<String, Object?> wire) {
    return BmsLimitConfigItem(
      id: wire['id']?.toString() ?? '',
      name: wire['name']?.toString() ?? '',
      groupId: wire['group_id']?.toString() ?? '',
      groupName: wire['group_name']?.toString() ?? '',
      limitType: (wire['limit_type'] as num?)?.toInt() ?? 1,
      maxQty: (wire['max_qty'] as num?)?.toInt() ?? 0,
      maxAmount: (wire['max_amount'] as num?)?.toDouble() ?? 0.0,
      startDate: wire['start_date']?.toString() ?? '',
      endDate: wire['end_date']?.toString() ?? '',
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }
}

// =============================================================================
// S7.P5 门店 / 支付 / 设备数据模型
// =============================================================================

/// S7.P5.T01 门店信息
final class BmsStoreInfo {
  const BmsStoreInfo({
    this.id = '',
    this.name = '',
    this.phone = '',
    this.province = '',
    this.city = '',
    this.district = '',
    this.address = '',
    this.openTime = '18:00',
    this.closeTime = '06:00',
    this.logoUrl = '',
    this.status = 1,
  });

  final String id;
  final String name;
  final String phone;
  final String province;
  final String city;
  final String district;
  final String address;
  final String openTime;
  final String closeTime;
  final String logoUrl;
  final int status;

  factory BmsStoreInfo.fromWire(Map<String, Object?> wire) {
    return BmsStoreInfo(
      id: wire['id']?.toString() ?? wire['store_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['store_name']?.toString() ?? '',
      phone: wire['phone']?.toString() ?? wire['tel']?.toString() ?? '',
      province: wire['province']?.toString() ?? '',
      city: wire['city']?.toString() ?? '',
      district: wire['district']?.toString() ?? '',
      address: wire['address']?.toString() ?? '',
      openTime: wire['open_time']?.toString() ?? '18:00',
      closeTime: wire['close_time']?.toString() ?? '06:00',
      logoUrl: wire['logo_url']?.toString() ?? '',
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'phone': phone,
    'province': province,
    'city': city,
    'district': district,
    'address': address,
    'open_time': openTime,
    'close_time': closeTime,
    'logo_url': logoUrl,
    'status': status,
  };
}

/// S7.P5.T03 渠道
final class BmsPayChannelItem {
  const BmsPayChannelItem({
    required this.id,
    required this.name,
    this.code = '',
    this.isUsed = true,
    this.sort = 0,
  });

  final String id;
  final String name;
  final String code;
  final bool isUsed;
  final int sort;

  factory BmsPayChannelItem.fromWire(Map<String, Object?> wire) {
    return BmsPayChannelItem(
      id: wire['id']?.toString() ?? wire['paycnl_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['paycnl_name']?.toString() ?? '',
      code: wire['code']?.toString() ?? '',
      isUsed:
          (wire['is_used'] as num?)?.toInt() == 1 || wire['is_used'] == true,
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
    );
  }
}

/// S7.P5.T04 打印机
final class BmsPrinterItem {
  const BmsPrinterItem({
    required this.id,
    required this.name,
    this.ip = '',
    this.port = 9100,
    this.printerType = 'network',
    this.paperWidth = 80,
    this.status = 1,
  });

  final String id;
  final String name;
  final String ip;
  final int port;
  final String printerType;
  final int paperWidth;
  final int status;

  factory BmsPrinterItem.fromWire(Map<String, Object?> wire) {
    return BmsPrinterItem(
      id: wire['id']?.toString() ?? wire['printer_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['printer_name']?.toString() ?? '',
      ip: wire['ip']?.toString() ?? '',
      port: (wire['port'] as num?)?.toInt() ?? 9100,
      printerType: wire['printer_type']?.toString() ?? 'network',
      paperWidth: (wire['paper_width'] as num?)?.toInt() ?? 80,
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'ip': ip,
    'port': port,
    'printer_type': printerType,
    'paper_width': paperWidth,
    'status': status,
  };
}

/// S7.P5.T05 出品库
final class BmsMakeLibItem {
  const BmsMakeLibItem({
    required this.id,
    required this.name,
    this.printerIds = const <String>[],
    this.sort = 0,
    this.status = 1,
  });

  final String id;
  final String name;
  final List<String> printerIds;
  final int sort;
  final int status;

  factory BmsMakeLibItem.fromWire(Map<String, Object?> wire) {
    return BmsMakeLibItem(
      id: wire['id']?.toString() ?? wire['mklib_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['mklib_name']?.toString() ?? '',
      printerIds:
          (wire['printer_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'name': name,
    'printer_ids': printerIds,
    'sort': sort,
    'status': status,
  };
}

/// S7.P5.T06 小票配置
final class BmsBillConfig {
  const BmsBillConfig({
    this.id = '',
    this.title = '结账单',
    this.headerText = '',
    this.footerText = '感谢光临，欢迎再次光临！',
    this.qrCodeUrl = '',
    this.isPrintDetail = true,
    this.isPrintQr = false,
  });

  final String id;
  final String title;
  final String headerText;
  final String footerText;
  final String qrCodeUrl;
  final bool isPrintDetail;
  final bool isPrintQr;

  factory BmsBillConfig.fromWire(Map<String, Object?> wire) {
    return BmsBillConfig(
      id: wire['id']?.toString() ?? '',
      title: wire['title']?.toString() ?? '结账单',
      headerText: wire['header_text']?.toString() ?? '',
      footerText: wire['footer_text']?.toString() ?? '感谢光临，欢迎再次光临！',
      qrCodeUrl: wire['qr_code_url']?.toString() ?? '',
      isPrintDetail: wire['is_print_detail'] != false,
      isPrintQr: wire['is_print_qr'] == true,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'title': title,
    'header_text': headerText,
    'footer_text': footerText,
    'qr_code_url': qrCodeUrl,
    'is_print_detail': isPrintDetail,
    'is_print_qr': isPrintQr,
  };
}

/// S7.P5.T07 终端
final class BmsTerminalItem {
  const BmsTerminalItem({
    required this.id,
    this.termCode = '',
    this.machineId = '',
    this.stationId = '',
    this.stationName = '',
    this.printerId = '',
    this.printerName = '',
    this.ip = '',
    this.isOnline = false,
    this.quickCode = '',
  });

  final String id;
  final String termCode;
  final String machineId;
  final String stationId;
  final String stationName;
  final String printerId;
  final String printerName;
  final String ip;
  final bool isOnline;
  final String quickCode;

  factory BmsTerminalItem.fromWire(Map<String, Object?> wire) {
    return BmsTerminalItem(
      id: wire['id']?.toString() ?? wire['lic_id']?.toString() ?? '',
      termCode: wire['term_code']?.toString() ?? wire['code']?.toString() ?? '',
      machineId: wire['machine_id']?.toString() ?? '',
      stationId: wire['station_id']?.toString() ?? '',
      stationName: wire['station_name']?.toString() ?? '',
      printerId: wire['printer_id']?.toString() ?? '',
      printerName: wire['printer_name']?.toString() ?? '',
      ip: wire['ip']?.toString() ?? '',
      isOnline:
          wire['is_online'] == true || (wire['status'] as num?)?.toInt() == 1,
      quickCode: wire['quick_code']?.toString() ?? '',
    );
  }
}

// =============================================================================
// S7.P6 报表 / 小程序 / 要求 / 理由 / 规则数据模型
// =============================================================================

/// S7.P6.T06 要求类型与要求项
final class BmsRequireItem {
  const BmsRequireItem({
    required this.id,
    required this.name,
    this.typeId = '',
    this.typeName = '',
    this.price = 0.0,
    this.sort = 0,
  });

  final String id;
  final String name;
  final String typeId;
  final String typeName;
  final double price;
  final int sort;

  factory BmsRequireItem.fromWire(Map<String, Object?> wire) {
    return BmsRequireItem(
      id: wire['id']?.toString() ?? wire['rqm_id']?.toString() ?? '',
      name: wire['name']?.toString() ?? wire['rqm_name']?.toString() ?? '',
      typeId: wire['type_id']?.toString() ?? '',
      typeName: wire['type_name']?.toString() ?? '',
      price: (wire['price'] as num?)?.toDouble() ?? 0.0,
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
    );
  }
}

/// S7.P6.T07 通用理由模型（支持优惠/退单/退卡/取消优惠）
final class BmsReasonItem {
  const BmsReasonItem({
    required this.id,
    required this.reasonType, // YH, back, backVip, QXYH
    required this.reasonText,
    this.sort = 0,
    this.status = 1,
  });

  final String id;
  final String reasonType;
  final String reasonText;
  final int sort;
  final int status;

  factory BmsReasonItem.fromWire(Map<String, Object?> wire) {
    return BmsReasonItem(
      id: wire['id']?.toString() ?? wire['rsn_id']?.toString() ?? '',
      reasonType:
          wire['reason_type']?.toString() ?? wire['type']?.toString() ?? 'YH',
      reasonText:
          wire['reason_text']?.toString() ??
          wire['text']?.toString() ??
          wire['name']?.toString() ??
          '',
      sort: (wire['sort'] as num?)?.toInt() ?? 0,
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'reason_type': reasonType,
    'reason_text': reasonText,
    'sort': sort,
    'status': status,
  };
}

/// S7.P6.T08 终端规则
final class BmsTerminalRuleConfig {
  const BmsTerminalRuleConfig({
    this.id = '',
    this.autoLockMinutes = 15,
    this.scanPayTimeout = 60,
    this.printBillCopies = 1,
    this.enableAntiCheckout = true,
  });

  final String id;
  final int autoLockMinutes;
  final int scanPayTimeout;
  final int printBillCopies;
  final bool enableAntiCheckout;

  factory BmsTerminalRuleConfig.fromWire(Map<String, Object?> wire) {
    return BmsTerminalRuleConfig(
      id: wire['id']?.toString() ?? '',
      autoLockMinutes: (wire['auto_lock_minutes'] as num?)?.toInt() ?? 15,
      scanPayTimeout: (wire['scan_pay_timeout'] as num?)?.toInt() ?? 60,
      printBillCopies: (wire['print_bill_copies'] as num?)?.toInt() ?? 1,
      enableAntiCheckout: wire['enable_anti_checkout'] != false,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'auto_lock_minutes': autoLockMinutes,
    'scan_pay_timeout': scanPayTimeout,
    'print_bill_copies': printBillCopies,
    'enable_anti_checkout': enableAntiCheckout,
  };
}

/// S7.P6.T09 会员卡规则
final class BmsVipRuleConfig {
  const BmsVipRuleConfig({
    this.id = '',
    this.cardTypeId = '',
    this.rechargeMin = 100.0,
    this.discountRate = 0.9,
    this.scoreRatio = 1.0,
  });

  final String id;
  final String cardTypeId;
  final double rechargeMin;
  final double discountRate;
  final double scoreRatio;

  factory BmsVipRuleConfig.fromWire(Map<String, Object?> wire) {
    return BmsVipRuleConfig(
      id: wire['id']?.toString() ?? '',
      cardTypeId: wire['card_type_id']?.toString() ?? '',
      rechargeMin: (wire['recharge_min'] as num?)?.toDouble() ?? 100.0,
      discountRate: (wire['discount_rate'] as num?)?.toDouble() ?? 0.9,
      scoreRatio: (wire['score_ratio'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'card_type_id': cardTypeId,
    'recharge_min': rechargeMin,
    'discount_rate': discountRate,
    'score_ratio': scoreRatio,
  };
}

// =============================================================================
// S7.P7 存酒设置 / 抽成 / 短信数据模型
// =============================================================================

/// S7.P7.T01 存酒设置
final class BmsWineConfig {
  const BmsWineConfig({
    this.id = '',
    this.defaultExpiredDays = 30,
    this.maxSaveDays = 90,
    this.isAllowBorrow = true,
    this.isSmsNotify = true,
  });

  final String id;
  final int defaultExpiredDays;
  final int maxSaveDays;
  final bool isAllowBorrow;
  final bool isSmsNotify;

  factory BmsWineConfig.fromWire(Map<String, Object?> wire) {
    return BmsWineConfig(
      id: wire['id']?.toString() ?? '',
      defaultExpiredDays: (wire['default_expired_days'] as num?)?.toInt() ?? 30,
      maxSaveDays: (wire['max_save_days'] as num?)?.toInt() ?? 90,
      isAllowBorrow: wire['is_allow_borrow'] != false,
      isSmsNotify: wire['is_sms_notify'] != false,
    );
  }

  Map<String, Object?> toWire() => <String, Object?>{
    'id': id,
    'default_expired_days': defaultExpiredDays,
    'max_save_days': maxSaveDays,
    'is_allow_borrow': isAllowBorrow,
    'is_sms_notify': isSmsNotify,
  };
}

/// S7.P7.T02 可存酒水
final class BmsWineItem {
  const BmsWineItem({
    required this.id,
    required this.prdId,
    required this.prdName,
    this.expiredDays = 30,
    this.isAllowPart = false,
    this.status = 1,
  });

  final String id;
  final String prdId;
  final String prdName;
  final int expiredDays;
  final bool isAllowPart;
  final int status;

  factory BmsWineItem.fromWire(Map<String, Object?> wire) {
    return BmsWineItem(
      id: wire['id']?.toString() ?? '',
      prdId: wire['prd_id']?.toString() ?? '',
      prdName: wire['prd_name']?.toString() ?? wire['name']?.toString() ?? '',
      expiredDays: (wire['expired_days'] as num?)?.toInt() ?? 30,
      isAllowPart:
          wire['is_allow_part'] == true ||
          (wire['is_allow_part'] as num?)?.toInt() == 1,
      status: (wire['status'] as num?)?.toInt() ?? 1,
    );
  }
}

/// S7.P7.T03 抽成配置
final class BmsCutPrdItem {
  const BmsCutPrdItem({
    required this.id,
    required this.prdId,
    required this.prdName,
    this.cutType = 1, // 1 按比例, 2 按固定金额
    this.cutValue = 0.0,
    this.stationId = '',
    this.stationName = '',
  });

  final String id;
  final String prdId;
  final String prdName;
  final int cutType;
  final double cutValue;
  final String stationId;
  final String stationName;

  factory BmsCutPrdItem.fromWire(Map<String, Object?> wire) {
    return BmsCutPrdItem(
      id: wire['id']?.toString() ?? '',
      prdId: wire['prd_id']?.toString() ?? '',
      prdName: wire['prd_name']?.toString() ?? '',
      cutType: (wire['cut_type'] as num?)?.toInt() ?? 1,
      cutValue: (wire['cut_value'] as num?)?.toDouble() ?? 0.0,
      stationId: wire['station_id']?.toString() ?? '',
      stationName: wire['station_name']?.toString() ?? '',
    );
  }
}

/// S7.P7.T04 短信账户
final class BmsSmsAccountInfo {
  const BmsSmsAccountInfo({
    this.balance = 0,
    this.totalSent = 0,
    this.templateCount = 0,
    this.customerName = '',
    this.moneyBalance = '',
    this.lastRecharge = '',
    this.lastRechargeDate = '',
    this.state = '',
    this.openState = '',
  });

  final int balance;
  final int totalSent;
  final int templateCount;
  final String customerName,
      moneyBalance,
      lastRecharge,
      lastRechargeDate,
      state,
      openState;

  factory BmsSmsAccountInfo.fromWire(Map<String, Object?> wire) {
    return BmsSmsAccountInfo(
      balance: int.tryParse('${wire['c'] ?? 0}') ?? 0,
      customerName: '${wire['n'] ?? ''}',
      moneyBalance: '${wire['b'] ?? ''}',
      lastRecharge: '${wire['ld'] ?? ''}',
      lastRechargeDate: '${wire['lt'] ?? ''}',
      state: '${wire['s'] ?? ''}',
      openState: '${wire['o'] ?? ''}',
      totalSent: (wire['total_sent'] as num?)?.toInt() ?? 0,
      templateCount: (wire['template_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// S7.P7.T05 ~ T06 短信流水与结果
final class BmsSmsRecord {
  const BmsSmsRecord({
    required this.id,
    required this.phone,
    required this.content,
    this.sendTime = '',
    this.status = 1, // 1 成功, 2 失败
    this.failReason = '',
    this.typeName = '',
    this.receiveTime = '',
    this.count = '',
    this.state = '',
  });

  final String id;
  final String phone;
  final String content;
  final String sendTime;
  final int status;
  final String failReason;
  final String typeName, receiveTime, count, state;

  factory BmsSmsRecord.fromWire(Map<String, Object?> wire) {
    return BmsSmsRecord(
      id: wire['id']?.toString() ?? '',
      phone: '${wire['m'] ?? wire['phone'] ?? wire['mobile'] ?? ''}',
      content: wire['content']?.toString() ?? '',
      sendTime:
          wire['r']?.toString() ??
          wire['send_time']?.toString() ??
          wire['create_time']?.toString() ??
          '',
      status: wire['s'] == '成功'
          ? 1
          : wire['s'] == '失败'
          ? 2
          : int.tryParse('${wire['status']}') ?? 0,
      state: '${wire['s'] ?? ''}',
      typeName: '${wire['type_name'] ?? ''}',
      receiveTime: '${wire['d'] ?? ''}',
      count: '${wire['c'] ?? ''}',
      failReason: '${wire['e'] ?? wire['fail_reason'] ?? ''}',
    );
  }
}

final class BmsSmsBill {
  const BmsSmsBill({
    required this.id,
    this.date = '',
    this.type = '',
    this.amount = '',
    this.count = '',
    this.balance = '',
    this.remaining = '',
    this.failed = '',
  });
  final String id, date, type, amount, count, balance, remaining, failed;
  factory BmsSmsBill.fromWire(Map<String, Object?> wire) => BmsSmsBill(
    id: '${wire['id'] ?? ''}',
    date: '${wire['d'] ?? ''}',
    type: '${wire['t'] ?? ''}',
    amount: '${wire['a'] ?? ''}',
    count: '${wire['sc'] ?? ''}',
    balance: '${wire['b'] ?? ''}',
    remaining: '${wire['bc'] ?? ''}',
    failed: '${wire['fc'] ?? ''}',
  );
}

final class BmsSmsBillPage {
  const BmsSmsBillPage({this.records = const [], this.total = 0});
  final List<BmsSmsBill> records;
  final int total;
  factory BmsSmsBillPage.fromWire(Map<String, Object?> wire) => BmsSmsBillPage(
    records: (wire['records'] as List? ?? [])
        .whereType<Map<String, Object?>>()
        .map(BmsSmsBill.fromWire)
        .toList(),
    total: int.tryParse('${wire['row_cnt']}') ?? 0,
  );
}

final class BmsSmsDeliveryPage {
  const BmsSmsDeliveryPage({
    this.records = const [],
    this.total = 0,
    this.templates = const [],
  });
  final List<BmsSmsRecord> records;
  final int total;
  final List<Map<String, Object?>> templates;
  factory BmsSmsDeliveryPage.fromWire(
    Map<String, Object?> wire, {
    List<Map<String, Object?>> previousTemplates = const [],
    bool interpolate = false,
  }) {
    final templates = (wire['sms_types'] ?? wire['sms_template']) as List?;
    final resolved =
        templates?.whereType<Map<String, Object?>>().toList() ??
        previousTemplates;
    final records = (wire['records'] as List? ?? [])
        .whereType<Map<String, Object?>>()
        .map((row) {
          final template = resolved
              .where((t) => '${t['id']}' == '${row['t']}')
              .firstOrNull;
          var content = '${template?['t'] ?? ''}';
          if (interpolate) {
            for (var i = 1; i <= 6; i++) {
              content = content.replaceAll('{$i}', '${row['p$i'] ?? ''}');
            }
          }
          return BmsSmsRecord.fromWire({
            ...row,
            'content': content,
            'type_name': template?['n'] ?? '',
          });
        })
        .toList();
    return BmsSmsDeliveryPage(
      records: records,
      total: int.tryParse('${wire['row_cnt']}') ?? records.length,
      templates: resolved,
    );
  }
}
