import 'package:card_table/src/order_meal.dart' show OrderSetDetail;

final class OrderSetRequirementItem {
  const OrderSetRequirementItem({required this.id, required this.name});
  final String id, name;
}

final class OrderSetRequirementGroup {
  OrderSetRequirementGroup({
    required this.id,
    required this.name,
    required this.modeType,
    Iterable<OrderSetRequirementItem> items = const [],
  }) : items = List.unmodifiable(items);
  final String id, name;
  final int modeType;
  final List<OrderSetRequirementItem> items;
}

final class OrderSetConfiguration {
  OrderSetConfiguration({
    required this.known,
    Iterable<OrderSetDetail> details = const [],
    Map<String, List<OrderSetRequirementGroup>> requirementsByProduct =
        const {},
    this.unavailableReason,
  }) : details = List.unmodifiable(details),
       requirementsByProduct = Map.unmodifiable({
         for (final entry in requirementsByProduct.entries)
           entry.key: List<OrderSetRequirementGroup>.unmodifiable(entry.value),
       });
  final bool known;
  final List<OrderSetDetail> details;
  final Map<String, List<OrderSetRequirementGroup>> requirementsByProduct;
  final String? unavailableReason;
}

/// Metadata-only package catalog. A template id is never a product fallback.
final class OrderSetCatalog {
  const OrderSetCatalog._(this._tables, this._known);
  static const unknown = OrderSetCatalog._({}, {});
  static const _configurationDatasets = {4, 9, 19, 20, 21, 52};
  static const _widths = {4: 10, 8: 3, 9: 8, 19: 5, 20: 5, 21: 3, 52: 7};
  final Map<int, Map<String, List<Object?>>> _tables;
  final Set<int> _known;
  bool get known => _known.containsAll(_configurationDatasets);

  /// Dataset 8 is independent of configuration readiness. Null is unknown;
  /// an empty, validated map means there are no active sale-count limits.
  Map<String, int>? get saleLimits => !_known.contains(8)
      ? null
      : Map.unmodifiable({
          for (final row in _tables[8]!.values)
            if (_int(row[2]) == 1) _id(row[0]): _int(row[1]),
        });
  List<List<Object?>>? rowsForReplay(int dataset) => _known.contains(dataset)
      ? List.unmodifiable(_tables[dataset]!.values)
      : null;

  OrderSetCatalog apply(Object? raw, {bool? isFull}) {
    final full = isFull ?? raw is List;
    if (raw is! List && raw is! Map) return unknown;
    final ambiguous = <int>{};
    if (raw is Map) {
      final seen = <int>{};
      for (final key in raw.keys) {
        final id = int.tryParse('$key');
        if (!_widths.containsKey(id)) continue;
        if ('$key' != '$id' || !seen.add(id!)) ambiguous.add(id!);
      }
    }
    final tables = full ? <int, Map<String, List<Object?>>>{} : Map.of(_tables);
    final known = full ? <int>{} : Set<int>.of(_known);
    for (final id in _widths.keys) {
      final present = raw is List
          ? raw.length > id
          : (raw as Map).containsKey(id) || raw.containsKey('$id');
      if (!present && !full && !ambiguous.contains(id)) continue;
      final Object? rows = raw is List
          ? (present ? raw[id] : null)
          : (raw as Map)[id] ?? raw['$id'];
      try {
        if (ambiguous.contains(id)) throw const FormatException();
        if (rows is! List || rows.length > 10000) throw const FormatException();
        final next = full
            ? <String, List<Object?>>{}
            : Map<String, List<Object?>>.of(tables[id] ?? {});
        for (final rawRow in rows) {
          if (rawRow is! List ||
              rawRow.length < _widths[id]! ||
              rawRow.length > 64) {
            throw const FormatException();
          }
          final row = List<Object?>.unmodifiable(rawRow);
          final statusIndex = id == 9
              ? 1
              : id == 52
              ? 5
              : 2;
          final status = _int(row[statusIndex]);
          if (id == 8 && status == 1) _int(row[1]);
          final key = switch (id) {
            9 => '${_id(row[0])}|${_id(row[2])}|${_int(row[3])}',
            21 => '${_id(row[0])}|${_id(row[1])}',
            52 => '${_id(row[0])}|${_int(row[1])}',
            _ => _id(row[0]),
          };
          if (status == 3 || (id == 52 && status != 1)) {
            next.remove(key);
          } else {
            next[key] = row;
          }
        }
        if (next.length > 10000) throw const FormatException();
        tables[id] = Map.unmodifiable(next);
        if (full) known.add(id);
      } on Object {
        known.remove(id);
        tables[id] = const {};
      }
    }
    return OrderSetCatalog._(Map.unmodifiable(tables), Set.unmodifiable(known));
  }

  OrderSetConfiguration configurationFor(String productId) {
    if (!known) return _unavailable('套餐配置尚未完整同步，请稍后重试');
    try {
      final parent = _product(productId);
      if (_int(parent[9]) != 2) return _unavailable('该商品不是套餐');
      final rows =
          _tables[9]!.values.indexed
              .where(
                (entry) =>
                    _id(entry.$2[0]) == productId && _int(entry.$2[1]) == 1,
              )
              .toList()
            ..sort((a, b) {
              final order = _int(a.$2[3]).compareTo(_int(b.$2[3]));
              return order != 0 ? order : a.$1.compareTo(b.$1);
            });
      final groups = <String, List<List<Object?>>>{};
      for (final entry in rows) {
        groups.putIfAbsent(_id(entry.$2[2]), () => []).add(entry.$2);
      }
      final details = <OrderSetDetail>[];
      for (final entry in groups.entries) {
        final group = entry.key, configs = entry.value, first = configs.first;
        final fixed = group == '1';
        final type = _int(first[7]);
        if (type != 1 && type != 2) throw const FormatException();
        if (fixed && type == 2) return _unavailable('固定组包含模板引用，配置结构无效');
        final quota = fixed ? 0 : _int(first[6], positive: true);
        for (final row in configs) {
          if (_int(row[7]) != type || (!fixed && _int(row[6]) != quota)) {
            throw const FormatException();
          }
        }
        if (type == 1) {
          for (final row in configs) {
            final id = _id(row[4]);
            final product = _product(id);
            if (details.length >= 10000) throw const FormatException();
            details.add(
              OrderSetDetail(
                productId: productId,
                groupId: group,
                detailProductId: id,
                detailCount: _int(row[5], positive: true),
                groupSelectCount: quota,
                name: _name(product[1]),
                typeId: '1',
                seqId: _int(row[3]),
              ),
            );
          }
        } else {
          final templateId = _id(first[4]);
          if (configs.any((row) => _id(row[4]) != templateId)) {
            throw const FormatException();
          }
          // Vue uses the first configured template for this optional group.
          // Preserve template row order; sel_cnt is not the group's quota.
          final candidates = _tables[52]!.values
              .where((row) => _id(row[0]) == templateId && _int(row[5]) == 1)
              .toList();
          if (candidates.isEmpty) throw const FormatException();
          for (final row in candidates) {
            final id = _id(row[2]);
            final product = _product(id);
            // Bound template fan-out as well as individual metadata datasets.
            if (details.length >= 10000) throw const FormatException();
            details.add(
              OrderSetDetail(
                productId: productId,
                groupId: group,
                detailProductId: id,
                detailCount: _int(row[3], positive: true),
                groupSelectCount: quota,
                name: _name(product[1]),
                typeId: '2',
                seqId: _int(first[3]),
                templateResolved: true,
              ),
            );
          }
        }
      }
      final requirements = <String, List<OrderSetRequirementGroup>>{};
      for (final detail in details) {
        requirements.putIfAbsent(
          detail.detailProductId,
          () => _requirements(_product(detail.detailProductId)),
        );
      }
      return OrderSetConfiguration(
        known: true,
        details: details,
        requirementsByProduct: requirements,
      );
    } on Object {
      return _unavailable('套餐引用的商品、模板或定制要求不完整，请刷新后重试');
    }
  }

  List<Object?> _product(String id) {
    final product = _tables[4]![id];
    // getProductInfoFromGroup uses configured products, including inactive
    // standalone goods; deletion removes the reference, never substitutes ids.
    if (product == null || !const {1, 2}.contains(_int(product[2]))) {
      throw const FormatException();
    }
    return product;
  }

  List<OrderSetRequirementGroup> _requirements(List<Object?> product) {
    final category = _id(product[7]);
    final types = <List<Object?>>[];
    for (final link in _tables[21]!.values) {
      if (_id(link[0]) != category || _int(link[2]) != 1) continue;
      final type = _tables[19]![_id(link[1])];
      if (type == null) throw const FormatException();
      if (_int(type[2]) == 1) types.add(type);
    }
    types.sort((a, b) => _int(a[3]).compareTo(_int(b[3])));
    return [for (final type in types) _requirementGroup(type)];
  }

  OrderSetRequirementGroup _requirementGroup(List<Object?> type) {
    final id = _id(type[0]), mode = _int(type[4]);
    if (mode != 1 && mode != 2) throw const FormatException();
    final items =
        _tables[20]!.values
            .where((row) => _id(row[3]) == id && _int(row[2]) == 1)
            .toList()
          ..sort((a, b) => _int(a[4]).compareTo(_int(b[4])));
    return OrderSetRequirementGroup(
      id: id,
      name: _name(type[1]),
      modeType: mode,
      items: [
        for (final item in items)
          OrderSetRequirementItem(id: _id(item[0]), name: _name(item[1])),
      ],
    );
  }

  static OrderSetConfiguration _unavailable(String reason) =>
      OrderSetConfiguration(known: false, unavailableReason: reason);
  static String _name(Object? value) {
    if (value is! String || value.isEmpty || value.length > 256) {
      throw const FormatException();
    }
    return value;
  }

  static String _id(Object? value) => _int(value, positive: true).toString();
  static int _int(Object? value, {bool positive = false}) {
    if (value is! num && value is! String) throw const FormatException();
    final number = num.tryParse('$value');
    if (number == null ||
        !number.isFinite ||
        number != number.truncate() ||
        number > 9007199254740991 ||
        number < (positive ? 1 : 0)) {
      throw const FormatException();
    }
    return number.toInt();
  }
}
