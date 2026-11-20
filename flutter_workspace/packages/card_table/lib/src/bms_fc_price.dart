enum BmsFcPriceOperation {
  products('get_fc_prd_cfg_list'),
  productItems('get_fc_prd_cfg_items'),
  addProducts('batch_add_fc_prd'),
  deleteProducts('batch_del_fc_prd'),
  plans('get_fc_price_plan_list'),
  employeeItems('get_fc_plan_emp_items'),
  removeEmployee('remove_emp_from_plan'),
  addPlan('new_fc_price_plan'),
  deletePlans('batch_del_fc_price_plan'),
  savePlan('save_fc_price_plan'),
  savePrice('save_fc_prd_plan_price');

  const BmsFcPriceOperation(this.endpoint);
  final String endpoint;
  bool get reads =>
      [products, productItems, plans, employeeItems].contains(this);
}

/// A closed request vocabulary: callers cannot select arbitrary backend paths.
final class BmsFcPriceRequest {
  const BmsFcPriceRequest(
    this.operation, {
    this.key = '',
    this.name = '',
    this.ids = const [],
    this.planId = 0,
    this.employeeId = 0,
    this.productId = 0,
    this.amount = 0,
    this.oneCateId = 0,
    this.twoCateId = 0,
    this.deptId = 0,
  });
  final BmsFcPriceOperation operation;
  final String key, name;
  final List<int> ids;
  final int planId, employeeId, productId, amount, oneCateId, twoCateId, deptId;
  Map<String, Object?> get body {
    if ([
      planId,
      employeeId,
      productId,
      amount,
      oneCateId,
      twoCateId,
      deptId,
      ...ids,
    ].any((id) => id < 0 || id > 9007199254740991)) {
      throw const FormatException('编号或金额无效');
    }
    if ([
          BmsFcPriceOperation.addProducts,
          BmsFcPriceOperation.deleteProducts,
          BmsFcPriceOperation.deletePlans,
        ].contains(operation) &&
        (ids.isEmpty || ids.contains(0))) {
      throw const FormatException('请选择记录');
    }
    if ([
          BmsFcPriceOperation.addPlan,
          BmsFcPriceOperation.savePlan,
        ].contains(operation) &&
        (name.trim().isEmpty || name.trim().length > 50 || ids.contains(0))) {
      throw const FormatException('请输入50字以内方案名称');
    }
    if (operation == BmsFcPriceOperation.savePlan && planId == 0 ||
        operation == BmsFcPriceOperation.removeEmployee &&
            (planId == 0 || employeeId == 0) ||
        operation == BmsFcPriceOperation.savePrice &&
            (planId == 0 || productId == 0)) {
      throw const FormatException('记录编号无效');
    }
    return switch (operation) {
      BmsFcPriceOperation.products => {'key': key},
      BmsFcPriceOperation.productItems => {
        'one_cate_id': oneCateId,
        'two_cate_id': twoCateId,
        'key': key,
      },
      BmsFcPriceOperation.addProducts ||
      BmsFcPriceOperation.deleteProducts ||
      BmsFcPriceOperation.deletePlans => {'ids': ids},
      BmsFcPriceOperation.plans => {},
      BmsFcPriceOperation.employeeItems => {
        'plan_id': planId,
        'dept_id': deptId,
        'key': key,
      },
      BmsFcPriceOperation.removeEmployee => {
        'plan_id': planId,
        'emp_id': employeeId,
      },
      BmsFcPriceOperation.addPlan => {'name': name.trim(), 'emp_ids': ids},
      BmsFcPriceOperation.savePlan => {
        'name': name.trim(),
        'emp_ids': ids,
        'id': planId,
      },
      BmsFcPriceOperation.savePrice => {
        'prd_id': productId,
        'plan_id': planId,
        'pay_amt': amount,
      },
    };
  }
}

int bmsFcYuanToCents(String value) {
  final text = value.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
    throw const FormatException('请输入非负金额，最多两位小数');
  }
  final parts = text.split('.');
  final amount =
      BigInt.parse(parts.first) * BigInt.from(100) +
      BigInt.parse((parts.length == 1 ? '' : parts.last).padRight(2, '0'));
  if (amount > BigInt.from(9007199254740991)) {
    throw const FormatException('金额过大');
  }
  return amount.toInt();
}

String bmsFcCentsToYuan(int cents) =>
    '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
int bmsFcInt(Object? value) {
  if (value is num &&
      value.isFinite &&
      value >= 0 &&
      value <= 9007199254740991 &&
      value % 1 == 0) {
    return value.toInt();
  }
  final number = int.tryParse('$value');
  if (number == null || number < 0 || number > 9007199254740991) {
    throw const FormatException('服务数据格式异常');
  }
  return number;
}

List<Map<String, Object?>> bmsFcRows(Object? value) {
  if (value == null) return const [];
  if (value is! List ||
      value.length > 10000 ||
      value.any((row) => row is! Map<String, Object?>)) {
    throw const FormatException('服务数据格式异常');
  }
  return value.cast<Map<String, Object?>>();
}

final class BmsFcPlan {
  BmsFcPlan.fromWire(Map<String, Object?> wire)
    : id = bmsFcInt(wire['id']),
      name = '${wire['n'] ?? ''}',
      employees = '${wire['e'] ?? ''}',
      created = '${wire['c'] ?? ''}',
      updated = '${wire['u'] ?? ''}';
  final int id;
  final String name, employees, created, updated;
}

final class BmsFcCandidate {
  BmsFcCandidate.fromWire(Map<String, Object?> wire, {required bool product})
    : id = bmsFcInt(wire['id']),
      name = '${wire['n'] ?? ''}',
      oneCate = '${wire['on'] ?? ''}',
      twoCate = '${wire['tn'] ?? ''}',
      price = product ? bmsFcInt(wire['p']) : 0,
      configured = product && bmsFcInt(wire['c'] ?? 0) == 1,
      department = '${wire['d'] ?? ''}',
      code = product ? '' : '${wire['c'] ?? ''}',
      status = product ? 0 : bmsFcInt(wire['s'] ?? 0),
      planId = product ? 0 : bmsFcInt(wire['p'] ?? 0),
      planName = '${wire['r'] ?? ''}';
  final int id, price;
  final String name, oneCate, twoCate, department, code;
  final bool configured;
  int status, planId;
  String planName;
  bool unavailable(bool product, Iterable<int> selected) =>
      (product ? configured : status == 2) || selected.contains(id);
}

final class BmsFcMatrix {
  BmsFcMatrix.fromWire(Map<String, Object?> wire)
    : products = bmsFcRows(wire['prds'])
          .map((row) => BmsFcCandidate.fromWire(row, product: true))
          .toList(),
      plans = bmsFcRows(wire['plans']).map(BmsFcPlan.fromWire).toList(),
      prices = {
        for (final row in bmsFcRows(wire['prices']))
          if (row['a'] != null)
            '${bmsFcInt(row['id'])}:${bmsFcInt(row['p'])}': bmsFcInt(row['a']),
      };
  final List<BmsFcCandidate> products;
  final List<BmsFcPlan> plans;
  final Map<String, int> prices;
  int priceFor(BmsFcCandidate product, BmsFcPlan plan) =>
      prices['${product.id}:${plan.id}'] ?? product.price;
}
