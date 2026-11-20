/// Current scheme prices for new orders only. Never reprice recorded orders.
final class FcPriceCatalog {
  const FcPriceCatalog._(this.known, this._prices, this._employees);
  static const unknown = FcPriceCatalog._(false, {}, {});

  final bool known;
  final Map<String, List<Object?>> _prices;
  final Map<String, List<Object?>> _employees;

  /// Null rows preserve unknown readiness when replaying an older snapshot.
  List<List<Object?>>? get priceRows =>
      known ? List.unmodifiable(_prices.values) : null;
  List<List<Object?>>? get employeeRows =>
      known ? List.unmodifiable(_employees.values) : null;

  FcPriceCatalog apply(Object? rawData, {bool? isFull}) {
    try {
      final full = isFull ?? rawData is List;
      final data = <int, Object?>{};
      if (rawData is List) {
        data[58] = rawData.length > 58 ? rawData[58] : null;
        data[59] = rawData.length > 59 ? rawData[59] : null;
      } else if (rawData is Map) {
        for (final entry in rawData.entries) {
          final id = int.tryParse('${entry.key}');
          if (id != 58 && id != 59) continue;
          if ('${entry.key}' != '$id' || data.containsKey(id)) {
            return unknown;
          }
          data[id!] = entry.value;
        }
      } else {
        return unknown;
      }
      if (full && (data[58] == null || data[59] == null)) return unknown;
      final prices = full ? <String, List<Object?>>{} : Map.of(_prices);
      final employees = full ? <String, List<Object?>>{} : Map.of(_employees);
      for (final id in [58, 59]) {
        if (!data.containsKey(id)) continue;
        final rows = data[id];
        if (rows is! List || rows.length > 10000) return unknown;
        final target = id == 58 ? prices : employees;
        final width = id == 58 ? 4 : 3;
        for (final row in rows) {
          if (row is! List || row.length < width || row.length > 64) {
            return unknown;
          }
          if (_id(row[0]) == null ||
              _id(row[1]) == null ||
              _integer(row[width - 1]) == null) {
            return unknown;
          }
          // Amounts may legitimately be null (no override). Invalid amounts
          // also resolve to null, never to an accidental free price.
          target['${_id(row[0])}|${_id(row[1])}'] = List<Object?>.unmodifiable(
            List<Object?>.of(row.take(width)),
          );
        }
        if (target.length > 10000) return unknown;
      }
      return FcPriceCatalog._(
        full || known,
        Map.unmodifiable(prices),
        Map.unmodifiable(employees),
      );
    } on Object {
      return unknown;
    }
  }

  double? resolve({
    required Object? productId,
    Object? authorId,
    required Object? orderEmployeeId,
  }) {
    if (!known) return null;
    final product = _id(productId);
    final authorNumber = num.tryParse('$authorId');
    final employee = authorNumber != null && authorNumber > 0
        ? _id(authorId)
        : _id(orderEmployeeId);
    if (product == null || employee == null) return null;
    for (final row in _employees.values) {
      if (_integer(row[2]) != 1 || _id(row[1]) != employee) continue;
      final price = _prices['$product|${_id(row[0])}'];
      if (price == null || _integer(price[3]) != 1) return null;
      final cents = _integer(price[2]);
      return cents == null ? null : cents / 100;
    }
    return null;
  }

  static String? _id(Object? value) {
    final number = _integer(value);
    return number != null && number > 0
        ? (value is num ? '$number' : '$value')
        : null;
  }

  static int? _integer(Object? value) {
    if (value is! num && value is! String) return null;
    if (value is String && (value.trim().isEmpty || value.length > 32)) {
      return null;
    }
    final number = value is num ? value : num.tryParse(value as String);
    if (number == null ||
        !number.isFinite ||
        number < 0 ||
        number > 9007199254740991 ||
        number != number.truncate()) {
      return null;
    }
    return number.toInt();
  }
}
