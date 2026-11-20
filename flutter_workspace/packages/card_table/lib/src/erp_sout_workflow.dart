import 'dart:typed_data';

import 'package:foundation/foundation.dart';

typedef ErpSoutPrint = Future<Result<void>> Function(
  Uint8List bytes,
  String name,
  bool Function() canDispatch,
);

enum ErpSoutDocumentMode { view, copy, reversal }

final class ErpSoutPage {
  const ErpSoutPage(this.rows, this.total);
  final List<Map<String, Object?>> rows;
  final int total;
}

final class ErpSoutDocument {
  const ErpSoutDocument(this.data, this.mode);
  final Map<String, Object?> data;
  final ErpSoutDocumentMode mode;
  List<Map<String, Object?>> get lines => erpSoutRows(data['dtls']);
}

List<Map<String, Object?>> erpSoutRows(Object? raw) {
  if (raw == null) return [];
  if (raw is! List || raw.any((r) => r is! Map)) {
    throw const FormatException('出库明细无效');
  }
  final rows = [for (final r in raw) Map<String, Object?>.from(r as Map)];
  if (rows.any((r) => (int.tryParse('${r['id']}') ?? 0) <= 0)) {
    throw const FormatException('出库编号无效');
  }
  return rows;
}

abstract interface class ErpSoutWorkflowLoader {
  Object? get soutContext;
  Future<Result<ErpSoutPage>> loadOtherOutPage({
    required String beginDay,
    required String endDay,
    int recordType = 0,
    String remark = '',
    int page = 1,
    int pageSize = 20,
  });
  Future<Result<ErpSoutDocument>> loadOtherOutDocument(
    String id,
    ErpSoutDocumentMode mode,
  );
  Future<Result<void>> reverseOtherOutWhole(String id);
  Future<Result<void>> reverseOtherOutLines(Map<int, double> counts);
}
