// =============================================================================
// S8 ERP 仓库系统领域模型
// =============================================================================

// -----------------------------------------------------------------------------
// S8.P1 主数据模型
// -----------------------------------------------------------------------------

/// 首页物料负库存预警子项
final class ErpNegStoreMat {
  const ErpNegStoreMat({
    this.id = '',
    this.productName = '',
    this.matName = '',
    this.oneCate = '',
    this.twoCate = '',
    this.unit = '',
    this.count = 0,
    this.blockedCount = 0,
  });

  final String id;
  final String productName;
  final String matName;
  final String oneCate;
  final String twoCate;
  final String unit;
  final double count;
  final double blockedCount;

  factory ErpNegStoreMat.fromWire(Map<String, Object?> map) {
    return ErpNegStoreMat(
      id: map['id']?.toString() ?? '',
      productName: map['sn']?.toString() ?? '',
      matName: map['mn']?.toString() ?? '',
      oneCate: map['on']?.toString() ?? '',
      twoCate: map['tn']?.toString() ?? '',
      unit: map['un']?.toString() ?? '',
      count: (map['c'] as num?)?.toDouble() ?? 0.0,
      blockedCount: (map['b'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'sn': productName,
    'mn': matName,
    'on': oneCate,
    'tn': twoCate,
    'un': unit,
    'c': count,
    'b': blockedCount,
  };
}

/// 首页负库存门店预警条目
final class ErpNegStoreAlert {
  const ErpNegStoreAlert({
    this.id = '',
    this.storeName = '',
    this.materials = const <ErpNegStoreMat>[],
  });

  final String id;
  final String storeName;
  final List<ErpNegStoreMat> materials;

  factory ErpNegStoreAlert.fromWire(Map<String, Object?> map) {
    final rawMs = map['ms'];
    final mats = <ErpNegStoreMat>[];
    if (rawMs is List) {
      for (final m in rawMs) {
        if (m is Map<String, Object?>) {
          mats.add(ErpNegStoreMat.fromWire(m));
        } else if (m is Map) {
          mats.add(ErpNegStoreMat.fromWire(Map<String, Object?>.from(m)));
        }
      }
    }
    return ErpNegStoreAlert(
      id: map['id']?.toString() ?? '',
      storeName: map['n']?.toString() ?? '',
      materials: mats,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'n': storeName,
    'ms': materials.map((m) => m.toWire()).toList(),
  };
}

/// 首页未配置对照关系的收银商品预警
final class ErpUnboundPrdAlert {
  const ErpUnboundPrdAlert({
    this.id = '',
    this.productName = '',
    this.oneCate = '',
    this.twoCate = '',
  });

  final String id;
  final String productName;
  final String oneCate;
  final String twoCate;

  factory ErpUnboundPrdAlert.fromWire(Map<String, Object?> map) {
    return ErpUnboundPrdAlert(
      id: map['id']?.toString() ?? '',
      productName: map['pn']?.toString() ?? '',
      oneCate: map['on']?.toString() ?? '',
      twoCate: map['tn']?.toString() ?? '',
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'pn': productName,
    'on': oneCate,
    'tn': twoCate,
  };
}

/// S8.P1.T02 仓库实体
final class ErpStoreItem {
  const ErpStoreItem({
    this.id = '',
    this.code = '',
    this.name = '',
    this.status = 1,
    this.memo = '',
  });

  final String id;
  final String code;
  final String name;
  final int status;
  final String memo;

  bool get isValid => status == 1;

  factory ErpStoreItem.fromWire(Map<String, Object?> map) {
    return ErpStoreItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? map['c']?.toString() ?? '',
      name: map['name']?.toString() ?? map['n']?.toString() ?? '',
      status: (map['st'] as num?)?.toInt() ?? 1,
      memo: map['memo']?.toString() ?? '',
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'name': name,
    'st': status,
    'memo': memo,
  };
}

/// 物料分类树节点
final class ErpMatCate {
  const ErpMatCate({
    this.id = '',
    this.name = '',
    this.parentId = '',
    this.children = const <ErpMatCate>[],
  });

  final String id;
  final String name;
  final String parentId;
  final List<ErpMatCate> children;

  factory ErpMatCate.fromWire(Map<String, Object?> map) {
    final rawSub = map['sub'] ?? map['children'];
    final subList = <ErpMatCate>[];
    if (rawSub is List) {
      for (final s in rawSub) {
        if (s is Map<String, Object?>) {
          subList.add(ErpMatCate.fromWire(s));
        } else if (s is Map) {
          subList.add(ErpMatCate.fromWire(Map<String, Object?>.from(s)));
        }
      }
    }
    return ErpMatCate(
      id: map['id']?.toString() ?? '',
      name: map['n']?.toString() ?? map['name']?.toString() ?? '',
      parentId: map['pid']?.toString() ?? '',
      children: subList,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'n': name,
    'pid': parentId,
    if (children.isNotEmpty) 'sub': children.map((c) => c.toWire()).toList(),
  };
}

/// S8.P1.T03/T04 物料实体
final class ErpMatItem {
  const ErpMatItem({
    this.id = '',
    this.code = '',
    this.name = '',
    this.oneCateId = '',
    this.oneCateName = '',
    this.twoCateId = '',
    this.twoCateName = '',
    this.unitId = '',
    this.unitName = '',
    this.price = 0.0,
    this.spec = '',
    this.status = 1,
  });

  final String id;
  final String code;
  final String name;
  final String oneCateId;
  final String oneCateName;
  final String twoCateId;
  final String twoCateName;
  final String unitId;
  final String unitName;
  final double price;
  final String spec;
  final int status;

  bool get isValid => status == 1;

  factory ErpMatItem.fromWire(Map<String, Object?> map) {
    return ErpMatItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? map['c']?.toString() ?? '',
      name: map['n']?.toString() ?? map['name']?.toString() ?? '',
      oneCateId: map['one_cate_id']?.toString() ?? '',
      oneCateName:
          map['on']?.toString() ?? map['one_cate_name']?.toString() ?? '',
      twoCateId: map['two_cate_id']?.toString() ?? '',
      twoCateName:
          map['tn']?.toString() ?? map['two_cate_name']?.toString() ?? '',
      unitId: map['unit_id']?.toString() ?? '',
      unitName: map['un']?.toString() ?? map['unit_name']?.toString() ?? '',
      price:
          (map['p'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0.0,
      spec: map['spec']?.toString() ?? '',
      status: (map['st'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'c': code,
    'n': name,
    'one_cate_id': oneCateId,
    'on': oneCateName,
    'two_cate_id': twoCateId,
    'tn': twoCateName,
    'unit_id': unitId,
    'un': unitName,
    'p': price,
    'spec': spec,
    'st': status,
  };
}

/// S8.P1.T05 商品对照关系
final class ErpComparePrdItem {
  const ErpComparePrdItem({
    this.id = '',
    this.productName = '',
    this.oneCate = '',
    this.twoCate = '',
    this.matId = '',
    this.matName = '',
    this.isClosed = 0,
  });

  final String id;
  final String productName;
  final String oneCate;
  final String twoCate;
  final String matId;
  final String matName;
  final int isClosed;

  factory ErpComparePrdItem.fromWire(Map<String, Object?> map) {
    return ErpComparePrdItem(
      id: map['id']?.toString() ?? '',
      productName: map['pn']?.toString() ?? map['name']?.toString() ?? '',
      oneCate: map['on']?.toString() ?? '',
      twoCate: map['tn']?.toString() ?? '',
      matId: map['mat_id']?.toString() ?? '',
      matName: map['mn']?.toString() ?? map['mat_name']?.toString() ?? '',
      isClosed: (map['is_close'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'pn': productName,
    'on': oneCate,
    'tn': twoCate,
    'mat_id': matId,
    'mn': matName,
    'is_close': isClosed,
  };
}

/// S8.P1.T06 供应商
final class ErpSupplierItem {
  const ErpSupplierItem({
    this.id = '',
    this.code = '',
    this.name = '',
    this.linkman = '',
    this.tel = '',
    this.address = '',
    this.status = 1,
    this.memo = '',
  });

  final String id;
  final String code;
  final String name;
  final String linkman;
  final String tel;
  final String address;
  final int status;
  final String memo;

  bool get isValid => status == 1;

  factory ErpSupplierItem.fromWire(Map<String, Object?> map) {
    return ErpSupplierItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? map['c']?.toString() ?? '',
      name: map['name']?.toString() ?? map['n']?.toString() ?? '',
      linkman: map['linkman']?.toString() ?? map['contact']?.toString() ?? '',
      tel: map['tel']?.toString() ?? map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      status: (map['st'] as num?)?.toInt() ?? 1,
      memo: map['memo']?.toString() ?? '',
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'name': name,
    'linkman': linkman,
    'tel': tel,
    'address': address,
    'st': status,
    'memo': memo,
  };
}

// -----------------------------------------------------------------------------
// S8.P2 / S8.P3 出入库与异议模型
// -----------------------------------------------------------------------------

/// 出入库单明细条目
final class ErpBillDetail {
  const ErpBillDetail({
    this.id = '',
    this.matId = '',
    this.matName = '',
    this.unitName = '',
    this.count = 0.0,
    this.price = 0.0,
    this.amount = 0.0,
    this.batchNo = '',
  });

  final String id;
  final String matId;
  final String matName;
  final String unitName;
  final double count;
  final double price;
  final double amount;
  final String batchNo;

  factory ErpBillDetail.fromWire(Map<String, Object?> map) {
    return ErpBillDetail(
      id: map['id']?.toString() ?? '',
      matId: map['mat_id']?.toString() ?? '',
      matName: map['mn']?.toString() ?? map['mat_name']?.toString() ?? '',
      unitName: map['un']?.toString() ?? map['unit_name']?.toString() ?? '',
      count: (map['c'] as num?)?.toDouble() ?? 0.0,
      price: (map['p'] as num?)?.toDouble() ?? 0.0,
      amount: (map['a'] as num?)?.toDouble() ?? 0.0,
      batchNo: map['batch_no']?.toString() ?? '',
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'mat_id': matId,
    'mn': matName,
    'un': unitName,
    'c': count,
    'p': price,
    'a': amount,
    'batch_no': batchNo,
  };
}

/// S8.P2.T01/T02 其他入库单
final class ErpStockOptions {
  const ErpStockOptions({this.stores = const [], this.suppliers = const []});
  final List<ErpStoreItem> stores;
  final List<ErpSupplierItem> suppliers;
  factory ErpStockOptions.fromWire(Map<String, Object?> wire) =>
      ErpStockOptions(
        stores: (wire['stores'] as List? ?? [])
            .whereType<Map<String, Object?>>()
            .map(ErpStoreItem.fromWire)
            .toList(),
        suppliers: (wire['suppliers'] as List? ?? [])
            .whereType<Map<String, Object?>>()
            .map(ErpSupplierItem.fromWire)
            .toList(),
      );
}

/// sin/mat_items and sout/mat_items use c/a for stock quantity/amount,
/// unlike the material-master response where c is the material code.
final class ErpStockMaterial {
  const ErpStockMaterial({
    required this.id,
    required this.name,
    this.oneCateName = '',
    this.twoCateName = '',
    this.unitName = '',
    this.stockCount = 0,
    this.stockAmount = 0,
  });
  final String id, name, oneCateName, twoCateName, unitName;
  final double stockCount, stockAmount;
  double get unitCost => stockCount == 0 ? 0 : stockAmount / stockCount;
  factory ErpStockMaterial.fromWire(Map<String, Object?> wire) =>
      ErpStockMaterial(
        id: '${wire['id'] ?? ''}',
        name: '${wire['n'] ?? ''}',
        oneCateName: '${wire['moc'] ?? ''}',
        twoCateName: '${wire['mtc'] ?? ''}',
        unitName: '${wire['un'] ?? ''}',
        stockCount: double.tryParse('${wire['c']}') ?? 0,
        stockAmount: double.tryParse('${wire['a']}') ?? 0,
      );
}

final class ErpSinItem {
  const ErpSinItem({
    this.id = '',
    this.code = '',
    this.recordType = 7,
    this.storeId = '',
    this.storeName = '',
    this.billDay = '',
    this.status = 1,
    this.operName = '',
    this.memo = '',
    this.items = const <ErpBillDetail>[],
  });

  final String id;
  final String code;
  final int recordType;
  final String storeId;
  final String storeName;
  final String billDay;
  final int status;
  final String operName;
  final String memo;
  final List<ErpBillDetail> items;

  factory ErpSinItem.fromWire(Map<String, Object?> map) {
    final rawItems = map['items'] ?? map['dtls'];
    final list = <ErpBillDetail>[];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, Object?>) {
          list.add(ErpBillDetail.fromWire(it));
        } else if (it is Map) {
          list.add(ErpBillDetail.fromWire(Map<String, Object?>.from(it)));
        }
      }
    }
    return ErpSinItem(
      id: map['id']?.toString() ?? '',
      code: map['cd']?.toString() ?? map['code']?.toString() ?? '',
      recordType: (map['record_type'] as num?)?.toInt() ?? 7,
      storeId: map['store_id']?.toString() ?? '',
      storeName: map['sn']?.toString() ?? map['store_name']?.toString() ?? '',
      billDay: map['st'] is String
          ? map['st'].toString()
          : map['bill_day']?.toString() ?? '',
      status: map['st'] is num ? (map['st'] as num).toInt() : 0,
      operName: map['en']?.toString() ?? map['oper_name']?.toString() ?? '',
      memo: map['r']?.toString() ?? map['memo']?.toString() ?? '',
      items: list,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'record_type': recordType,
    'store_id': storeId,
    'sn': storeName,
    'bill_day': billDay,
    'st': status,
    'oper_name': operName,
    'memo': memo,
    'items': items.map((i) => i.toWire()).toList(),
  };
}

/// S8.P2.T03 调拨入库单
final class ErpSindItem {
  const ErpSindItem({
    this.id = '',
    this.code = '',
    this.outStoreId = '',
    this.outStoreName = '',
    this.inStoreId = '',
    this.inStoreName = '',
    this.billDay = '',
    this.status = 3, // 3: 未处理, 1: 已完成, 4: 异议中
    this.operName = '',
    this.items = const <ErpBillDetail>[],
  });

  final String id;
  final String code;
  final String outStoreId;
  final String outStoreName;
  final String inStoreId;
  final String inStoreName;
  final String billDay;
  final int status;
  final String operName;
  final List<ErpBillDetail> items;

  factory ErpSindItem.fromWire(Map<String, Object?> map) {
    final rawItems = map['items'] ?? map['dtls'];
    final list = <ErpBillDetail>[];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, Object?>) {
          list.add(ErpBillDetail.fromWire(it));
        } else if (it is Map) {
          list.add(ErpBillDetail.fromWire(Map<String, Object?>.from(it)));
        }
      }
    }
    return ErpSindItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      outStoreId: map['out_store_id']?.toString() ?? '',
      outStoreName:
          map['out_store_name']?.toString() ?? map['out_sn']?.toString() ?? '',
      inStoreId: map['in_store_id']?.toString() ?? '',
      inStoreName:
          map['in_store_name']?.toString() ?? map['in_sn']?.toString() ?? '',
      billDay: map['bill_day']?.toString() ?? '',
      status: (map['st'] as num?)?.toInt() ?? 3,
      operName: map['oper_name']?.toString() ?? '',
      items: list,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'out_store_id': outStoreId,
    'out_store_name': outStoreName,
    'in_store_id': inStoreId,
    'in_store_name': inStoreName,
    'bill_day': billDay,
    'st': status,
    'oper_name': operName,
    'items': items.map((i) => i.toWire()).toList(),
  };
}

/// S8.P3.T01 其他出库单
final class ErpSoutItem {
  const ErpSoutItem({
    this.id = '',
    this.code = '',
    this.recordType = 17,
    this.storeId = '',
    this.storeName = '',
    this.billDay = '',
    this.status = 1,
    this.operName = '',
    this.memo = '',
    this.items = const <ErpBillDetail>[],
  });

  final String id;
  final String code;
  final int recordType;
  final String storeId;
  final String storeName;
  final String billDay;
  final int status;
  final String operName;
  final String memo;
  final List<ErpBillDetail> items;

  factory ErpSoutItem.fromWire(Map<String, Object?> map) {
    final rawItems = map['items'] ?? map['dtls'];
    final list = <ErpBillDetail>[];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, Object?>) {
          list.add(ErpBillDetail.fromWire(it));
        } else if (it is Map) {
          list.add(ErpBillDetail.fromWire(Map<String, Object?>.from(it)));
        }
      }
    }
    return ErpSoutItem(
      id: map['id']?.toString() ?? '',
      code: map['cd']?.toString() ?? map['code']?.toString() ?? '',
      recordType: (map['record_type'] as num?)?.toInt() ?? 17,
      storeId: map['store_id']?.toString() ?? '',
      storeName: map['sn']?.toString() ?? map['store_name']?.toString() ?? '',
      billDay: map['st'] is String
          ? map['st'].toString()
          : map['bill_day']?.toString() ?? '',
      status: map['st'] is num ? (map['st'] as num).toInt() : 0,
      operName: map['en']?.toString() ?? map['oper_name']?.toString() ?? '',
      memo: map['r']?.toString() ?? map['memo']?.toString() ?? '',
      items: list,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'record_type': recordType,
    'store_id': storeId,
    'sn': storeName,
    'bill_day': billDay,
    'st': status,
    'oper_name': operName,
    'memo': memo,
    'items': items.map((i) => i.toWire()).toList(),
  };
}

/// S8.P3.T02 调拨出库单
final class ErpSoutdItem {
  const ErpSoutdItem({
    this.id = '',
    this.code = '',
    this.outStoreId = '',
    this.outStoreName = '',
    this.inStoreId = '',
    this.inStoreName = '',
    this.billDay = '',
    this.status = 1,
    this.operName = '',
    this.items = const <ErpBillDetail>[],
  });

  final String id;
  final String code;
  final String outStoreId;
  final String outStoreName;
  final String inStoreId;
  final String inStoreName;
  final String billDay;
  final int status;
  final String operName;
  final List<ErpBillDetail> items;

  factory ErpSoutdItem.fromWire(Map<String, Object?> map) {
    final rawItems = map['items'] ?? map['dtls'];
    final list = <ErpBillDetail>[];
    if (rawItems is List) {
      for (final it in rawItems) {
        if (it is Map<String, Object?>) {
          list.add(ErpBillDetail.fromWire(it));
        } else if (it is Map) {
          list.add(ErpBillDetail.fromWire(Map<String, Object?>.from(it)));
        }
      }
    }
    return ErpSoutdItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      outStoreId: map['out_store_id']?.toString() ?? '',
      outStoreName:
          map['out_store_name']?.toString() ?? map['out_sn']?.toString() ?? '',
      inStoreId: map['in_store_id']?.toString() ?? '',
      inStoreName:
          map['in_store_name']?.toString() ?? map['in_sn']?.toString() ?? '',
      billDay: map['bill_day']?.toString() ?? '',
      status: (map['st'] as num?)?.toInt() ?? 1,
      operName: map['oper_name']?.toString() ?? '',
      items: list,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'out_store_id': outStoreId,
    'out_store_name': outStoreName,
    'in_store_id': inStoreId,
    'in_store_name': inStoreName,
    'bill_day': billDay,
    'st': status,
    'oper_name': operName,
    'items': items.map((i) => i.toWire()).toList(),
  };
}

/// S8.P2.T04 & S8.P3.T03 出入库异议订单
final class ErpDisputeItem {
  const ErpDisputeItem({
    this.id = '',
    this.code = '',
    this.subCode = '',
    this.matName = '',
    this.oneCate = '',
    this.diffCount = 0.0,
    this.status = 3, // 3: 待处理, 2: 已处理, 1: 已完成
    this.date = '',
    this.memo = '',
  });

  final String id;
  final String code;
  final String subCode;
  final String matName;
  final String oneCate;
  final double diffCount;
  final int status;
  final String date;
  final String memo;

  factory ErpDisputeItem.fromWire(Map<String, Object?> map) {
    return ErpDisputeItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      subCode: map['sub_code']?.toString() ?? map['s_code']?.toString() ?? '',
      matName: map['mn']?.toString() ?? map['mat_name']?.toString() ?? '',
      oneCate: map['on']?.toString() ?? '',
      diffCount:
          (map['diff_cnt'] as num?)?.toDouble() ??
          (map['c'] as num?)?.toDouble() ??
          0.0,
      status:
          (map['status'] as num?)?.toInt() ?? (map['st'] as num?)?.toInt() ?? 3,
      date:
          map['in_day']?.toString() ??
          map['out_day']?.toString() ??
          map['day']?.toString() ??
          '',
      memo: map['memo']?.toString() ?? '',
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'sub_code': subCode,
    'mn': matName,
    'on': oneCate,
    'diff_cnt': diffCount,
    'status': status,
    'day': date,
    'memo': memo,
  };
}

// -----------------------------------------------------------------------------
// S8.P4 空瓶管理模型
// -----------------------------------------------------------------------------

/// S8.P4.T01 空瓶入库单
final class ErpEmptyInItem {
  const ErpEmptyInItem({
    this.id = '',
    this.code = '',
    this.day = '',
    this.count = 0,
    this.status = 1,
    this.operName = '',
  });

  final String id;
  final String code;
  final String day;
  final int count;
  final int status;
  final String operName;

  factory ErpEmptyInItem.fromWire(Map<String, Object?> map) {
    return ErpEmptyInItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      day: map['day']?.toString() ?? '',
      count: (map['cnt'] as num?)?.toInt() ?? (map['c'] as num?)?.toInt() ?? 0,
      status: (map['st'] as num?)?.toInt() ?? 1,
      operName: map['oper_name']?.toString() ?? '',
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'day': day,
    'cnt': count,
    'st': status,
    'oper_name': operName,
  };
}

/// S8.P4.T02 空瓶仓库存
final class ErpEmptyInvtItem {
  const ErpEmptyInvtItem({
    this.id = '',
    this.name = '',
    this.count = 0,
    this.checked = false,
  });

  final String id;
  final String name;
  final int count;
  final bool checked;

  ErpEmptyInvtItem copyWith({bool? checked}) => ErpEmptyInvtItem(
    id: id,
    name: name,
    count: count,
    checked: checked ?? this.checked,
  );

  factory ErpEmptyInvtItem.fromWire(Map<String, Object?> map) {
    return ErpEmptyInvtItem(
      id: map['id']?.toString() ?? '',
      name: map['n']?.toString() ?? map['name']?.toString() ?? '',
      count: (map['c'] as num?)?.toInt() ?? 0,
      checked: false,
    );
  }

  Map<String, Object?> toWire() => {'id': id, 'n': name, 'c': count};
}

/// S8.P4.T03 空瓶出库单
final class ErpEmptyOutItem {
  const ErpEmptyOutItem({
    this.id = '',
    this.code = '',
    this.day = '',
    this.count = 0,
    this.status = 1,
    this.operName = '',
  });

  final String id;
  final String code;
  final String day;
  final int count;
  final int status;
  final String operName;

  factory ErpEmptyOutItem.fromWire(Map<String, Object?> map) {
    return ErpEmptyOutItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      day: map['day']?.toString() ?? '',
      count: (map['cnt'] as num?)?.toInt() ?? (map['c'] as num?)?.toInt() ?? 0,
      status: (map['st'] as num?)?.toInt() ?? 1,
      operName: map['oper_name']?.toString() ?? '',
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'day': day,
    'cnt': count,
    'st': status,
    'oper_name': operName,
  };
}

// -----------------------------------------------------------------------------
// S8.P5 报表数据模型
// -----------------------------------------------------------------------------

/// 报表通用下拉选项
final class ErpReportParams {
  const ErpReportParams({
    this.storeOptions = const <Map<String, String>>[],
    this.cateOptions = const <Map<String, String>>[],
    this.supplierOptions = const <Map<String, String>>[],
    this.twoCateOptions = const <String, List<Map<String, String>>>{},
  });

  final List<Map<String, String>> storeOptions;
  final List<Map<String, String>> cateOptions;
  final List<Map<String, String>> supplierOptions;
  final Map<String, List<Map<String, String>>> twoCateOptions;

  factory ErpReportParams.fromWire(Map<String, Object?> map) {
    final stores = <Map<String, String>>[];
    final cates = <Map<String, String>>[];

    final rawStores = map['stores'] ?? map['store_items'];
    if (rawStores is List) {
      for (final s in rawStores) {
        if (s is Map) {
          stores.add({
            'id': s['id']?.toString() ?? '',
            'n': s['n']?.toString() ?? s['name']?.toString() ?? '',
          });
        }
      }
    }

    final rawCates = map['cates'] ?? map['mat_cate_items'];
    if (rawCates is List) {
      for (final c in rawCates) {
        if (c is Map) {
          cates.add({
            'id': c['id']?.toString() ?? '',
            'n': c['n']?.toString() ?? c['name']?.toString() ?? '',
          });
        }
      }
    }

    List<Map<String, String>> options(Object? raw) => raw is List
        ? [
            for (final row in raw.whereType<Map>())
              {
                'id': '${row['id'] ?? ''}',
                'n': '${row['n'] ?? row['name'] ?? ''}',
              },
          ]
        : [];
    return ErpReportParams(
      storeOptions: stores,
      cateOptions: cates,
      supplierOptions: options(map['suppliers']),
      twoCateOptions: {
        if (rawCates is List)
          for (final row in rawCates.whereType<Map>())
            '${row['id']}': options(row['ss']),
      },
    );
  }
}

/// These are the nine Vue rpt_erp pages, not arbitrary download URLs.
enum ErpReportKind {
  materialNow(
    '物料实时库存表',
    '/rpt_erp/get_now_mat_invt',
    '/rpt_erp/exp_now_mat_invt',
  ),
  materialInventory('物料库存表', '/rpt_erp/get_mat_invt', '/rpt_erp/exp_mat_invt'),
  inRecords('入库明细表', '/rpt_erp/in_recs', '/rpt_erp/exp_in_recs'),
  outRecords('出库明细表', '/rpt_erp/out_recs', '/rpt_erp/exp_out_recs'),
  inSummary('入库汇总表', '/rpt_erp/in_sum', '/rpt_erp/exp_in_sum'),
  outSummary('出库汇总表', '/rpt_erp/out_sum', '/rpt_erp/exp_out_sum'),
  storePsi(
    '仓库进销存',
    '/rpt_erp/get_store_invt_reps',
    '/rpt_erp/exp_store_invt_reps',
  ),
  emptyIn(
    '空瓶入库明细表',
    '/rtn_bt/get_rtn_bt_in_opers',
    '/rtn_bt/exp_rtn_bt_in_opers',
  ),
  emptyOut(
    '空瓶出库明细表',
    '/rtn_bt/get_rtn_bt_out_opers',
    '/rtn_bt/exp_rtn_bt_out_opers',
  );

  const ErpReportKind(this.title, this.readPath, this.exportPath);
  final String title, readPath, exportPath;
  bool get detailed => this == inRecords || this == outRecords;
  bool get classified => detailed || this == inSummary || this == outSummary;
  bool get emptyBottle => this == emptyIn || this == emptyOut;
  bool get paginated => detailed || this == storePsi;
}

final class ErpReportQuery {
  const ErpReportQuery({
    required this.kind,
    this.startDay = '',
    this.endDay = '',
    this.storeId = 0,
    this.keyword = '',
    this.recordType = 0,
    this.oneCateId = 0,
    this.twoCateId = 0,
    this.supplierId = 0,
    this.waiterKey = '',
    this.page = 1,
    this.pageSize = 20,
  });
  final ErpReportKind kind;
  final String startDay, endDay, keyword, waiterKey;
  final int storeId,
      recordType,
      oneCateId,
      twoCateId,
      supplierId,
      page,
      pageSize;
  Map<String, Object?> toWire({bool export = false}) {
    if ([
          storeId,
          recordType,
          oneCateId,
          twoCateId,
          supplierId,
        ].any((v) => v < 0 || v > 9007199254740991) ||
        page < 1 ||
        pageSize < 1 ||
        pageSize > 1000) {
      throw const FormatException('报表筛选参数无效');
    }
    bool day(String text) {
      final parsed = DateTime.tryParse(text);
      return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) &&
          parsed != null &&
          parsed.toIso8601String().startsWith(text);
    }

    if (kind != ErpReportKind.materialNow &&
        (!day(startDay) ||
            (kind != ErpReportKind.storePsi &&
                (!day(endDay) || startDay.compareTo(endDay) > 0)))) {
      throw const FormatException('请选择有效日期范围');
    }
    if (kind == ErpReportKind.materialNow) {
      return {'store_id': storeId, 'name': keyword};
    }
    if (kind == ErpReportKind.storePsi) {
      return {
        'store_id': storeId,
        'day': startDay,
        'key': keyword,
        if (!export) ...{'page_num': page, 'page_size': pageSize},
      };
    }
    if (kind.emptyBottle) {
      return {
        'start_day': startDay,
        'end_day': endDay,
        if (kind == ErpReportKind.emptyIn) 'waiter_key': waiterKey,
        'mat_key': keyword,
      };
    }
    if (kind == ErpReportKind.materialInventory) {
      return {
        'start_day': startDay,
        'end_day': endDay,
        'store_id': storeId,
        'name': keyword,
      };
    }
    return {
      'begin_day': startDay,
      'end_day': endDay,
      (kind == ErpReportKind.inSummary
              ? 'in_store_id'
              : kind == ErpReportKind.outSummary
              ? 'out_store_id'
              : 'store_id'):
          storeId,
      'record_type': recordType,
      'mat_one_cate_id': oneCateId,
      'mat_two_cate_id': twoCateId,
      if (kind == ErpReportKind.inRecords) 'supplier_id': supplierId,
      'name': keyword,
      if (kind.detailed) ...{'page_num': page, 'page_size': pageSize},
    };
  }
}

final class ErpReportPage {
  const ErpReportPage({
    required this.rows,
    required this.total,
    this.options = const ErpReportParams(),
  });
  final List<Map<String, Object?>> rows;
  final int total;
  final ErpReportParams options;
}

/// S8.P5.T01 物料实时库存
final class ErpMatNowInvtItem {
  const ErpMatNowInvtItem({
    this.id = '',
    this.storeName = '',
    this.matName = '',
    this.unitName = '',
    this.oneCate = '',
    this.twoCate = '',
    this.count = 0.0,
    this.holdCount = 0.0,
    this.price = 0.0,
    this.amount = 0.0,
  });

  final String id;
  final String storeName;
  final String matName;
  final String unitName;
  final String oneCate;
  final String twoCate;
  final double count;
  final double holdCount;
  final double price;
  final double amount;

  factory ErpMatNowInvtItem.fromWire(Map<String, Object?> map) {
    return ErpMatNowInvtItem(
      id: map['id']?.toString() ?? '',
      storeName: map['sn']?.toString() ?? '',
      matName: map['n']?.toString() ?? '',
      unitName: map['un']?.toString() ?? '',
      oneCate: map['moc']?.toString() ?? '',
      twoCate: map['mtc']?.toString() ?? '',
      count: (map['c'] as num?)?.toDouble() ?? 0.0,
      holdCount: (map['rc'] as num?)?.toDouble() ?? 0.0,
      price: (map['p'] as num?)?.toDouble() ?? 0.0,
      amount: (map['a'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'sn': storeName,
    'n': matName,
    'un': unitName,
    'moc': oneCate,
    'mtc': twoCate,
    'c': count,
    'rc': holdCount,
    'p': price,
    'a': amount,
  };
}

/// S8.P5.T02 物料月度库存
final class ErpMatMonthInvtItem {
  const ErpMatMonthInvtItem({
    this.id = '',
    this.storeName = '',
    this.matName = '',
    this.unitName = '',
    this.oneCate = '',
    this.twoCate = '',
    this.beginCount = 0.0,
    this.inCount = 0.0,
    this.outCount = 0.0,
    this.endCount = 0.0,
    this.endAmount = 0.0,
  });

  final String id;
  final String storeName;
  final String matName;
  final String unitName;
  final String oneCate;
  final String twoCate;
  final double beginCount;
  final double inCount;
  final double outCount;
  final double endCount;
  final double endAmount;

  factory ErpMatMonthInvtItem.fromWire(Map<String, Object?> map) {
    return ErpMatMonthInvtItem(
      id: map['id']?.toString() ?? '',
      storeName: map['sn']?.toString() ?? '',
      matName: map['n']?.toString() ?? '',
      unitName: map['un']?.toString() ?? '',
      oneCate: map['moc']?.toString() ?? '',
      twoCate: map['mtc']?.toString() ?? '',
      beginCount: (map['bc'] as num?)?.toDouble() ?? 0.0,
      inCount: (map['ic'] as num?)?.toDouble() ?? 0.0,
      outCount: (map['oc'] as num?)?.toDouble() ?? 0.0,
      endCount: (map['ec'] as num?)?.toDouble() ?? 0.0,
      endAmount: (map['ea'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'sn': storeName,
    'n': matName,
    'un': unitName,
    'moc': oneCate,
    'mtc': twoCate,
    'bc': beginCount,
    'ic': inCount,
    'oc': outCount,
    'ec': endCount,
    'ea': endAmount,
  };
}

/// S8.P5.T03/T04 出入库流水记录
final class ErpInOutRecItem {
  const ErpInOutRecItem({
    this.id = '',
    this.code = '',
    this.billDay = '',
    this.storeName = '',
    this.matName = '',
    this.unitName = '',
    this.count = 0.0,
    this.price = 0.0,
    this.amount = 0.0,
    this.typeName = '',
  });

  final String id;
  final String code;
  final String billDay;
  final String storeName;
  final String matName;
  final String unitName;
  final double count;
  final double price;
  final double amount;
  final String typeName;

  factory ErpInOutRecItem.fromWire(Map<String, Object?> map) {
    return ErpInOutRecItem(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      billDay: map['bill_day']?.toString() ?? '',
      storeName: map['sn']?.toString() ?? '',
      matName: map['mn']?.toString() ?? '',
      unitName: map['un']?.toString() ?? '',
      count: (map['c'] as num?)?.toDouble() ?? 0.0,
      price: (map['p'] as num?)?.toDouble() ?? 0.0,
      amount: (map['a'] as num?)?.toDouble() ?? 0.0,
      typeName: map['type_name']?.toString() ?? '',
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'code': code,
    'bill_day': billDay,
    'sn': storeName,
    'mn': matName,
    'un': unitName,
    'c': count,
    'p': price,
    'a': amount,
    'type_name': typeName,
  };
}

/// S8.P5.T05/T06 出入库汇总条目
final class ErpInOutSumItem {
  const ErpInOutSumItem({
    this.id = '',
    this.matName = '',
    this.unitName = '',
    this.oneCate = '',
    this.twoCate = '',
    this.count = 0.0,
    this.amount = 0.0,
  });

  final String id;
  final String matName;
  final String unitName;
  final String oneCate;
  final String twoCate;
  final double count;
  final double amount;

  factory ErpInOutSumItem.fromWire(Map<String, Object?> map) {
    return ErpInOutSumItem(
      id: map['id']?.toString() ?? '',
      matName: map['mn']?.toString() ?? '',
      unitName: map['un']?.toString() ?? '',
      oneCate: map['moc']?.toString() ?? '',
      twoCate: map['mtc']?.toString() ?? '',
      count: (map['c'] as num?)?.toDouble() ?? 0.0,
      amount: (map['a'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'mn': matName,
    'un': unitName,
    'moc': oneCate,
    'mtc': twoCate,
    'c': count,
    'a': amount,
  };
}

/// S8.P5.T07 仓库进销存表
final class ErpPsiItem {
  const ErpPsiItem({
    this.id = '',
    this.storeName = '',
    this.matName = '',
    this.unitName = '',
    this.beginCount = 0.0,
    this.beginAmount = 0.0,
    this.inCount = 0.0,
    this.inAmount = 0.0,
    this.outCount = 0.0,
    this.outAmount = 0.0,
    this.endCount = 0.0,
    this.endAmount = 0.0,
  });

  final String id;
  final String storeName;
  final String matName;
  final String unitName;
  final double beginCount;
  final double beginAmount;
  final double inCount;
  final double inAmount;
  final double outCount;
  final double outAmount;
  final double endCount;
  final double endAmount;

  factory ErpPsiItem.fromWire(Map<String, Object?> map) {
    return ErpPsiItem(
      id: map['id']?.toString() ?? '',
      storeName: map['sn']?.toString() ?? '',
      matName: map['mn']?.toString() ?? '',
      unitName: map['un']?.toString() ?? '',
      beginCount: (map['begin_c'] as num?)?.toDouble() ?? 0.0,
      beginAmount: (map['begin_a'] as num?)?.toDouble() ?? 0.0,
      inCount: (map['in_c'] as num?)?.toDouble() ?? 0.0,
      inAmount: (map['in_a'] as num?)?.toDouble() ?? 0.0,
      outCount: (map['out_c'] as num?)?.toDouble() ?? 0.0,
      outAmount: (map['out_a'] as num?)?.toDouble() ?? 0.0,
      endCount: (map['end_c'] as num?)?.toDouble() ?? 0.0,
      endAmount: (map['end_a'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'sn': storeName,
    'mn': matName,
    'un': unitName,
    'begin_c': beginCount,
    'begin_a': beginAmount,
    'in_c': inCount,
    'in_a': inAmount,
    'out_c': outCount,
    'out_a': outAmount,
    'end_c': endCount,
    'end_a': endAmount,
  };
}

/// S8.P5.T08/T09 空瓶出入库明细流水
final class ErpEmptyOperItem {
  const ErpEmptyOperItem({
    this.id = '',
    this.day = '',
    this.operType = '',
    this.bottleName = '',
    this.count = 0,
    this.operName = '',
    this.memo = '',
  });

  final String id;
  final String day;
  final String operType;
  final String bottleName;
  final int count;
  final String operName;
  final String memo;

  factory ErpEmptyOperItem.fromWire(Map<String, Object?> map) {
    return ErpEmptyOperItem(
      id: map['id']?.toString() ?? '',
      day: map['day']?.toString() ?? '',
      operType: map['oper_type']?.toString() ?? '',
      bottleName: map['n']?.toString() ?? '',
      count: (map['c'] as num?)?.toInt() ?? 0,
      operName: map['oper_name']?.toString() ?? '',
      memo: map['memo']?.toString() ?? '',
    );
  }

  Map<String, Object?> toWire() => {
    'id': id,
    'day': day,
    'oper_type': operType,
    'n': bottleName,
    'c': count,
    'oper_name': operName,
    'memo': memo,
  };
}
