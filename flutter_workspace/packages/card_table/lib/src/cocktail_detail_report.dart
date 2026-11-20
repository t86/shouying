import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

typedef CocktailDetailLoader =
    Future<Result<List<CocktailDetailReportRow>>> Function(String keyword);

/// Historical report amounts are yuan, independently rounded to cents.
/// Missing/invalid sa falls back to a; never use current product pricing.
final class CocktailReportAmounts {
  const CocktailReportAmounts(this.actualCents, this.originalCents);
  factory CocktailReportAmounts.fromWire(Map source) {
    final actual = _cents(source['a']) ?? 0;
    return CocktailReportAmounts(actual, _cents(source['sa']) ?? actual);
  }
  final int actualCents, originalCents;
  String get actual => (actualCents / 100).toStringAsFixed(2);
  String get original => (originalCents / 100).toStringAsFixed(2);
  String get display =>
      actualCents == originalCents ? actual : '原价：$original\n方案价：$actual';
  static int? _cents(Object? value) {
    if (value == null || value == '') return null;
    final number = double.tryParse('$value');
    if (number == null || !number.isFinite || !(number * 100).isFinite) {
      return null;
    }
    return (number * 100 + .5).floor();
  }
}

final class CocktailDetailReportRow {
  factory CocktailDetailReportRow.fromWire(Map<String, Object?> source) {
    if (source.length > _maxRowFields) throw _invalidRow;
    _displayCell(source['a']);
    return CocktailDetailReportRow._(
      List<String>.unmodifiable([
        for (final field in wireFields)
          field == 'a'
              ? CocktailReportAmounts.fromWire(source).display
              : _displayCell(source[field]),
      ]),
    );
  }

  const CocktailDetailReportRow._(this.cells);

  static const List<String> columnLabels = [
    '序号',
    '区域',
    '卡台名称',
    '下单/补交时间',
    '结账时间',
    '点单人',
    '点单人部门',
    '点单人岗位',
    '授权人',
    '授权人部门',
    '授权人岗位',
    '商品一级分类',
    '商品二级分类',
    '商品名称',
    '点单金额',
    '订台人',
    '订位部门',
    '订位人岗位',
    '关联功能台',
    '补交营业日',
    '支付信息描述',
  ];
  static const List<String> wireFields = [
    'rn',
    's',
    'o',
    'pt',
    'w',
    'wd',
    'ws',
    'ae',
    'ad',
    'as',
    'on',
    'tn',
    'n',
    'a',
    'se',
    'sd',
    'ss',
    'bs',
    'bb',
    'p',
  ];
  static const String scrollIndicator = '>>';

  static const int _maxRowFields = 64;
  static const int _maxCellCharacters = 2048;
  static const FormatException _invalidRow = FormatException(
    'Invalid cocktail detail report row',
  );

  /// Twenty backend display values; the view supplies 序号 and the scroll mark.
  final List<String> cells;

  static String _displayCell(Object? value) => switch (value) {
    null => '',
    String() when value.length <= _maxCellCharacters => value,
    num() when value == 0 => '0',
    double()
        when value.isFinite &&
            value.abs() <= 9007199254740991 &&
            value % 1 == 0 =>
      value.toStringAsFixed(0),
    num() when value.isFinite => value.toString(),
    _ => throw _invalidRow,
  };

  @override
  String toString() => 'CocktailDetailReportRow(<redacted>)';
}

final class ProtocolCocktailDetailReportApi {
  const ProtocolCocktailDetailReportApi({required this.client});
  final ProtocolClient client;

  Future<Result<List<CocktailDetailReportRow>>> load(
    ClientKind client, {
    required String keyword,
  }) async {
    if (keyword.length > _maxKeywordCharacters) {
      return const FailureResult(_shapeFailure);
    }
    final response = await this.client.post(
      '/sel/rpt/get_hl_list_byord',
      body: <String, Object?>{'key': keyword},
      client: client,
    );
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
    final records = data['records'];
    if (records == null) return Success(_withTotal(const [], 0, 0));
    if (records is! List || records.length > _maxRows) {
      return const FailureResult(_shapeFailure);
    }
    final rows = <CocktailDetailReportRow>[];
    var sum = 0, originalSum = 0;
    try {
      for (final record in records) {
        if (record is! Map<String, Object?>) {
          return const FailureResult(_shapeFailure);
        }
        final amount = _summableAmount(record['a']);
        if (amount == null) return const FailureResult(_shapeFailure);
        final amounts = CocktailReportAmounts.fromWire(record);
        sum += amounts.actualCents;
        originalSum += amounts.originalCents;
        rows.add(CocktailDetailReportRow.fromWire(record));
      }
    } on FormatException {
      return const FailureResult(_shapeFailure);
    }
    return Success(_withTotal(rows, sum, originalSum));
  }

  static List<CocktailDetailReportRow> _withTotal(
    List<CocktailDetailReportRow> rows,
    int sum,
    int originalSum,
  ) => List<CocktailDetailReportRow>.unmodifiable([
    ...rows,
    CocktailDetailReportRow.fromWire({
      'rn': '合计',
      'a': (sum / 100).toStringAsFixed(2),
      'sa': (originalSum / 100).toStringAsFixed(2),
    }),
  ]);

  static double? _summableAmount(Object? value) {
    final parsed = switch (value) {
      null => 0.0,
      num() => value.toDouble(),
      String() when value.isEmpty => 0.0,
      String() => double.tryParse(value),
      _ => null,
    };
    if (parsed == null || !parsed.isFinite) return null;
    return parsed;
  }

  static const int _maxRows = 10000;
  static const int _maxKeywordCharacters = 2048;

  static int? _wireCode(Object? value) => switch (value) {
    num() when value.isFinite && value % 1 == 0 => value.toInt(),
    String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(
      value,
    ),
    _ => null,
  };

  static const AppFailure _shapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.cocktail_detail_report_shape',
    safeMessage: '鸡尾酒明细表返回了无法识别的数据',
  );
  static const AppFailure _rejectedFailure = AppFailure(
    kind: FailureKind.business,
    code: 'business.cocktail_detail_report_rejected',
    safeMessage: '服务端拒绝查询鸡尾酒明细表，请重试',
  );
}
