import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

final class SoldOutItem {
  factory SoldOutItem.fromWire(Map<String, Object?> source) {
    if (source.length > ProtocolSoldOutProductsApi._maxFields) {
      throw ProtocolSoldOutProductsApi._invalid;
    }
    return SoldOutItem._(
      id: ProtocolSoldOutProductsApi._id(source['id']),
      name: ProtocolSoldOutProductsApi._display(source['n']),
      remaining: ProtocolSoldOutProductsApi._display(source['c']),
      require: ProtocolSoldOutProductsApi._display(source['require']),
    );
  }

  const SoldOutItem._({
    required this.id,
    required this.name,
    required this.remaining,
    required this.require,
  });

  final String id;
  final String name;
  final String remaining;
  final String require;

  @override
  String toString() => 'SoldOutItem(<redacted>)';
}

final class ProtocolSoldOutProductsApi {
  const ProtocolSoldOutProductsApi({required this.client});
  final ProtocolClient client;

  Future<Result<List<SoldOutItem>>> list(ClientKind client) async {
    final response = await this.client.postWithoutBody(
      '/sel/get_prd_sold_outs',
      client: client,
    );
    return _readList(response);
  }

  Future<Result<void>> set(
    ClientKind client, {
    required String productId,
    required int count,
    bool Function()? canDispatch,
  }) async {
    final id = _wireProductId(productId);
    if (id == null || !_validCount(count)) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/set_prd_sold_out',
      body: <String, Object?>{'prd_id': id, 'cnt': count},
      client: client,
      canDispatch: canDispatch,
    );
    return _readAck(response);
  }

  Future<Result<void>> delete(
    ClientKind client, {
    required String productId,
    bool Function()? canDispatch,
  }) async {
    final id = _wireProductId(productId);
    if (id == null) return const FailureResult(_shapeFailure);
    final response = await this.client.post(
      '/sel/del_prd_sold_out',
      body: <String, Object?>{'prd_id': id},
      client: client,
      canDispatch: canDispatch,
    );
    return _readAck(response);
  }

  static Result<List<SoldOutItem>> _readList(
    Result<Map<String, Object?>> response,
  ) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final envelope = response.valueOrNull!;
    final code = _wireCode(envelope['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    final data = envelope['data'];
    if (data is! Map<String, Object?>) {
      return const FailureResult(_shapeFailure);
    }
    final items = data['items'];
    if (items == null) return const Success([]);
    if (items is! List || items.length > _maxRows) {
      return const FailureResult(_shapeFailure);
    }
    final rows = <SoldOutItem>[];
    try {
      for (final item in items) {
        if (item is! Map<String, Object?>) {
          return const FailureResult(_shapeFailure);
        }
        rows.add(SoldOutItem.fromWire(item));
      }
    } on FormatException {
      return const FailureResult(_shapeFailure);
    }
    return Success(List<SoldOutItem>.unmodifiable(rows));
  }

  static Result<void> _readAck(Result<Map<String, Object?>> response) {
    if (response.failureOrNull case final failure?) {
      return FailureResult(failure);
    }
    final code = _wireCode(response.valueOrNull!['code']);
    if (code == null) return const FailureResult(_shapeFailure);
    if (code != 1) return const FailureResult(_rejectedFailure);
    return const Success(null);
  }

  static String _id(Object? value) => switch (value) {
    String() when value.isNotEmpty && value.length <= 64 => value,
    num() when value.isFinite && value % 1 == 0 => value.toInt().toString(),
    _ => throw _invalid,
  };

  static String _display(Object? value) => switch (value) {
    null => '',
    String() when value.length <= _maxCellCharacters => value,
    num() when value == 0 => '0',
    double()
        when value.isFinite &&
            value.abs() <= 9007199254740991 &&
            value % 1 == 0 =>
      value.toStringAsFixed(0),
    num() when value.isFinite => value.toString(),
    _ => throw _invalid,
  };

  static int? _wireProductId(String value) {
    if (!RegExp(r'^-?\d{1,16}$').hasMatch(value)) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed.abs() > 9007199254740991) return null;
    return parsed;
  }

  static bool _validCount(int count) => count >= 0 && count <= 9007199254740991;

  static int? _wireCode(Object? value) => switch (value) {
    num() when value.isFinite && value % 1 == 0 => value.toInt(),
    String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(
      value,
    ),
    _ => null,
  };

  static const int _maxRows = 10000;
  static const int _maxFields = 64;
  static const int _maxCellCharacters = 2048;
  static const FormatException _invalid = FormatException(
    'Invalid sold-out item',
  );
  static const AppFailure _shapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.sold_out_products_shape',
    safeMessage: '估清商品返回了无法识别的数据',
  );
  static const AppFailure _rejectedFailure = AppFailure(
    kind: FailureKind.business,
    code: 'business.sold_out_products_rejected',
    safeMessage: '服务端拒绝维护估清商品，请重试',
  );
}

final class SoldOutCategory {
  const SoldOutCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    this.parentId = '',
  });

  final String id;
  final String name;
  final int displayOrder;
  final String parentId;

  @override
  String toString() => 'SoldOutCategory(id: $id)';
}

final class SoldOutProduct {
  const SoldOutProduct({
    required this.id,
    required this.name,
    required this.namePy,
    required this.nameEng,
    required this.price,
    required this.prdType,
    required this.oneCateId,
    required this.twoCateId,
    required this.displayOrder,
    required this.limitPc,
    required this.limitPad,
    this.mbPrice = '',
    this.bsPrice = '',
    this.bsMbPrice = '',
    this.bxPrice = '',
    this.bxMbPrice = '',
    this.bxBsPrice = '',
    this.bxBsMbPrice = '',
  });

  final String id;
  final String name;
  final String namePy;
  final String nameEng;
  final String price;
  final int prdType;
  final String oneCateId;
  final String twoCateId;
  final int displayOrder;
  final Object? limitPc;
  final Object? limitPad;
  final String mbPrice,
      bsPrice,
      bsMbPrice,
      bxPrice,
      bxMbPrice,
      bxBsPrice,
      bxBsMbPrice;

  String get priceLabel =>
      prdType == 3 || prdType == 4 || prdType == 5 ? '时价' : '￥$price';

  bool get isPadRestricted => limitPad == '1';

  @override
  String toString() => 'SoldOutProduct(id: $id)';
}

final class SoldOutProductCatalog {
  factory SoldOutProductCatalog.forRegion({
    required String regionId,
    required Iterable<List<Object?>> firstCategories,
    required Iterable<List<Object?>> secondCategories,
    required Iterable<List<Object?>> products,
    required Iterable<List<Object?>> areaProducts,
    required bool padDevice,
  }) {
    final scoped = [
      for (final row in areaProducts)
        if (row.length >= 3 && _id(row[0]) == regionId) row,
    ];
    return SoldOutProductCatalog.fromWire(
      firstCategories: firstCategories,
      secondCategories: secondCategories,
      products: products,
      areaProducts: scoped,
      padDevice: padDevice,
    );
  }

  factory SoldOutProductCatalog.fromWire({
    required Iterable<List<Object?>> firstCategories,
    required Iterable<List<Object?>> secondCategories,
    required Iterable<List<Object?>> products,
    required Iterable<List<Object?>> areaProducts,
    required bool padDevice,
  }) {
    final areaIds = <String>{
      for (final row in areaProducts)
        if (row.length >= 3 && _status(row[1]) == 1) _id(row[2]),
    };
    final seconds = [
      for (final row in secondCategories)
        if (row.length >= 5 && _status(row[2]) == 1)
          SoldOutCategory(
            id: _id(row[0]),
            name: _text(row[1]),
            displayOrder: _order(row[3]),
            parentId: _id(row[4]),
          ),
    ];
    final secondIds = {for (final item in seconds) item.id};
    final items =
        [
          for (final row in products)
            if (row.length >= 10 &&
                _status(row[2]) == 1 &&
                areaIds.contains(_id(row[0])) &&
                secondIds.contains(_id(row[7])))
              SoldOutProduct(
                id: _id(row[0]),
                name: _text(row[1]),
                namePy: _optional(row[4]),
                nameEng: _optional(row[5]),
                price: ProtocolSoldOutProductsApi._display(row[8]),
                prdType: _order(row[9]),
                oneCateId: _id(row[6]),
                twoCateId: _id(row[7]),
                displayOrder: _order(row[3]),
                limitPc: row.length > 14 ? row[14] : null,
                limitPad: row.length > 15 ? row[15] : null,
                mbPrice: row.length > 18 ? _optional(row[18]) : '',
                bsPrice: row.length > 19 ? _optional(row[19]) : '',
                bsMbPrice: row.length > 20 ? _optional(row[20]) : '',
                bxPrice: row.length > 21 ? _optional(row[21]) : '',
                bxMbPrice: row.length > 22 ? _optional(row[22]) : '',
                bxBsPrice: row.length > 23 ? _optional(row[23]) : '',
                bxBsMbPrice: row.length > 24 ? _optional(row[24]) : '',
              ),
        ]..sort((left, right) {
          final order = left.displayOrder.compareTo(right.displayOrder);
          return order != 0 ? order : left.id.compareTo(right.id);
        });
    final usedSecondIds = {for (final item in items) item.twoCateId};
    final visibleSeconds =
        [
          for (final item in seconds)
            if (usedSecondIds.contains(item.id)) item,
        ]..sort((left, right) {
          final order = left.displayOrder.compareTo(right.displayOrder);
          return order != 0 ? order : left.id.compareTo(right.id);
        });
    final usedFirstIds = {for (final item in visibleSeconds) item.parentId};
    final firsts =
        [
          for (final row in firstCategories)
            if (row.length >= 4 &&
                _status(row[2]) == 1 &&
                usedFirstIds.contains(_id(row[0])))
              SoldOutCategory(
                id: _id(row[0]),
                name: _text(row[1]),
                displayOrder: _order(row[3]),
              ),
        ]..sort((left, right) {
          final order = left.displayOrder.compareTo(right.displayOrder);
          return order != 0 ? order : left.id.compareTo(right.id);
        });
    return SoldOutProductCatalog._(
      firstCategories: List<SoldOutCategory>.unmodifiable(firsts),
      secondCategories: List<SoldOutCategory>.unmodifiable(visibleSeconds),
      products: List<SoldOutProduct>.unmodifiable(items),
      padDevice: padDevice,
    );
  }

  const SoldOutProductCatalog._({
    required this.firstCategories,
    required this.secondCategories,
    required this.products,
    required this.padDevice,
  });

  static const empty = SoldOutProductCatalog._(
    firstCategories: [],
    secondCategories: [],
    products: [],
    padDevice: true,
  );

  final List<SoldOutCategory> firstCategories;
  final List<SoldOutCategory> secondCategories;
  final List<SoldOutProduct> products;
  final bool padDevice;

  List<SoldOutCategory> secondsOf(String firstId) => [
    for (final item in secondCategories)
      if (item.parentId == firstId) item,
  ];

  List<SoldOutProduct> productsIn({
    required String firstId,
    required String secondId,
  }) => [
    for (final item in products)
      if (item.twoCateId == secondId &&
          item.oneCateId == firstId &&
          _deviceVisible(item))
        item,
  ];

  List<SoldOutProduct> search({
    required String keyword,
    required String firstId,
    required String secondId,
  }) {
    final source = keyword.isEmpty
        ? productsIn(firstId: firstId, secondId: secondId)
        : products;
    return [
      for (final item in source)
        if (item.namePy.contains(keyword) || item.name.contains(keyword)) item,
    ];
  }

  bool _deviceVisible(SoldOutProduct item) =>
      padDevice ? !item.isPadRestricted : item.limitPc != '1';

  static int _status(Object? value) {
    if (value == 1 || value == '1') return 1;
    if (value is num && value.isFinite && value % 1 == 0) return value.toInt();
    if (value is String && RegExp(r'^-?\d{1,10}$').hasMatch(value)) {
      return int.parse(value);
    }
    throw const FormatException();
  }

  static String _id(Object? value) => ProtocolSoldOutProductsApi._id(value);

  static String _text(Object? value) {
    final text = ProtocolSoldOutProductsApi._display(value);
    if (text.isEmpty) throw const FormatException();
    return text;
  }

  static String _optional(Object? value) =>
      ProtocolSoldOutProductsApi._display(value);

  static int _order(Object? value) {
    final number = switch (value) {
      num() when value.isFinite => value,
      String() => num.tryParse(value),
      _ => null,
    };
    if (number == null || !number.isFinite || number % 1 != 0) {
      throw const FormatException();
    }
    return number.toInt();
  }
}
