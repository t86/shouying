import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

typedef MinimumConsumptionLoader =
    Future<Result<List<MinimumConsumptionReportRow>>> Function();

final class MinimumConsumptionReportRow {
  factory MinimumConsumptionReportRow.fromWire(Map<String, Object?> source) {
    if (source.length > _maxRowFields) throw _invalidRow;
    return MinimumConsumptionReportRow._(
      List<String>.unmodifiable([
        for (final field in wireFields) _displayCell(source[field]),
      ]),
    );
  }

  const MinimumConsumptionReportRow._(this.cells);

  static const List<String> columnLabels = [
    '序号',
    '区域',
    '卡台名称',
    '开台时间',
    '订位人部门',
    '订位人',
    '最低消费',
    '主营金额',
    '差额',
    '低消进度',
    '清台时间',
    '标签',
  ];
  static const List<String> wireFields = [
    'rn',
    'sn',
    'o',
    'sd',
    'se',
    'm',
    'za',
    'ga',
    'p',
    't',
    'mk',
  ];

  // Display budgets supplement the injected protocol response limits.
  static const int _maxRowFields = 64;
  static const int _maxCellCharacters = 2048;
  static const FormatException _invalidRow = FormatException(
    'Invalid minimum consumption report row',
  );

  /// Eleven backend display values; the view supplies the row number.
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
  String toString() => 'MinimumConsumptionReportRow(<redacted>)';
}

final class ProtocolMinimumConsumptionReportApi {
  const ProtocolMinimumConsumptionReportApi({required this.client});
  final ProtocolClient client;

  Future<Result<List<MinimumConsumptionReportRow>>> load(
    ClientKind client,
  ) async {
    final response = await this.client.postWithoutBody(
      '/wo/get_seat_zy_csm_list',
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
    if (records == null) return const Success([]);
    if (records is! List || records.length > _maxRows) {
      return const FailureResult(_shapeFailure);
    }
    final rows = <MinimumConsumptionReportRow>[];
    try {
      for (final record in records) {
        if (record is! Map<String, Object?>) {
          return const FailureResult(_shapeFailure);
        }
        rows.add(MinimumConsumptionReportRow.fromWire(record));
      }
    } on FormatException {
      return const FailureResult(_shapeFailure);
    }
    return Success(List<MinimumConsumptionReportRow>.unmodifiable(rows));
  }

  static const int _maxRows = 10000;

  static int? _wireCode(Object? value) => switch (value) {
    num() when value.isFinite && value % 1 == 0 => value.toInt(),
    String() when RegExp(r'^-?\d{1,10}$').hasMatch(value) => int.tryParse(
      value,
    ),
    _ => null,
  };

  static const AppFailure _shapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.minimum_consumption_report_shape',
    safeMessage: '低消进度统计表返回了无法识别的数据',
  );
  static const AppFailure _rejectedFailure = AppFailure(
    kind: FailureKind.business,
    code: 'business.minimum_consumption_report_rejected',
    safeMessage: '服务端拒绝查询低消进度统计表，请重试',
  );
}
