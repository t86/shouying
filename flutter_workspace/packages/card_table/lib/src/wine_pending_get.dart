import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:foundation/foundation.dart';

import 'package:card_table/src/wine_models.dart';

final class WinePendingGetContext {
  const WinePendingGetContext({required this.records, this.needsAuthorization});
  factory WinePendingGetContext.fromWire(Map<String, Object?> data) {
    final raw = data['records'] ?? const [];
    if (raw is! List) throw const FormatException('Invalid pending records');
    final records = <WineGetRecord>[];
    for (final record in raw) {
      if (record is! Map) throw const FormatException('Invalid pending record');
      final id = _pendingInteger(record['o'], positive: true);
      final children = record['ss'] ?? const [];
      if (children is! List) {
        throw const FormatException('Invalid pending items');
      }
      final items = <Map<Object?, Object?>>[];
      for (final child in children) {
        if (child is! Map) throw const FormatException('Invalid pending item');
        // ss.id is an order-detail id. Only ss.i identifies its inventory.
        final inventoryId = _pendingInteger(child['i'], positive: true);
        final count = _pendingInteger(child['c'], positive: false);
        items.add({...child, 'i': inventoryId, 'c': count});
      }
      records.add(WineGetRecord.fromWire({...record, 'o': id, 'ss': items}));
    }
    return WinePendingGetContext(
      records: List.unmodifiable(records),
      needsAuthorization: switch ('${data['need_waiter_auth']}') {
        '1' => true,
        '2' => false,
        _ => null,
      },
    );
  }
  final List<WineGetRecord> records;
  final bool? needsAuthorization;
}

int _pendingInteger(Object? value, {required bool positive}) {
  final n = switch (value) {
    int() => value,
    num() when value.isFinite && value == value.truncateToDouble() =>
      value.toInt(),
    String() when RegExp(r'^[0-9]{1,16}$').hasMatch(value) => int.tryParse(
      value,
    ),
    _ => null,
  };
  if (n == null || n > 9007199254740991 || n < (positive ? 1 : 0)) {
    throw const FormatException('Invalid pending integer');
  }
  return n;
}

/// Optional capability: legacy list-only loaders remain read compatible.
abstract interface class WinePendingGetLoader {
  Future<Result<WinePendingGetContext>> loadPendingGetContext({
    String keyword = '',
  });
  Future<Result<List<WineGetSubItem>>> loadPendingGetInventory(String phone);
}

Map<String, Object?> winePendingGetBody({
  required String orderId,
  required Map<String, int> counts,
  required bool? needsAuthorization,
  String account = '',
  String secret = '',
  int passType = 1,
}) {
  final id = int.tryParse(orderId);
  if (needsAuthorization == null ||
      id == null ||
      id <= 0 ||
      counts.isEmpty ||
      counts.entries.any(
        (e) => (int.tryParse(e.key) ?? 0) <= 0 || e.value <= 0,
      ) ||
      (needsAuthorization &&
          (account.trim().isEmpty ||
              secret.isEmpty ||
              ![1, 2].contains(passType)))) {
    throw ArgumentError('取酒单、数量或授权信息无效');
  }
  return {
    'bef_out_id': id,
    'invt_ids': counts.keys.map(int.parse).toList(),
    'prd_cnts': counts.values.toList(),
    'auth_emp_code': needsAuthorization ? account.trim() : '',
    'auth_emp_passwd': needsAuthorization
        ? md5.convert(utf8.encode(secret)).toString().toUpperCase()
        : '',
    'pass_type': needsAuthorization ? passType : 1,
  };
}
