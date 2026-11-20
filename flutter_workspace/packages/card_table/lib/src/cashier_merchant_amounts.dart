import 'package:realtime_sync/realtime_sync.dart';
import 'package:flutter/foundation.dart';

final class CashierMerchantAmount {
  const CashierMerchantAmount({
    required this.id,
    required this.amount,
    required this.publicAmount,
  });
  final int id;
  final num amount, publicAmount;
  String get display => (amount / 10000).toStringAsFixed(1);
}

/// Dataset 38 is a singleton total row, not merchant configuration metadata.
/// Unknown/reconnected data must await a complete snapshot before deltas apply.
final class CashierMerchantAmounts
    extends ValueNotifier<List<CashierMerchantAmount>?> {
  CashierMerchantAmounts() : super(null);
  void invalidate() => value = null;
  void add(SyncEnvelope event) {
    if (event.type == SyncEventType.heartbeat) return;
    if (event.type != SyncEventType.data) {
      invalidate();
      return;
    }
    final data = event.data;
    try {
      Object? rows;
      if (data is List) {
        invalidate();
        rows = data.length > 38 ? data[38] : null;
      } else if (data is Map) {
        if (value == null) return;
        final keys = data.keys
            .where((key) => int.tryParse('$key') == 38)
            .toList();
        if (keys.isEmpty) return;
        if (keys.length != 1 || (keys.single != 38 && keys.single != '38'))
          throw const FormatException();
        rows = data[keys.single];
        if (rows is List && rows.isEmpty) return;
      } else {
        throw const FormatException();
      }
      if (rows is! List || rows.length > 1) throw const FormatException();
      if (rows.isEmpty) {
        value = const [];
        return;
      }
      final row = rows.single;
      if (row is! List || row.length < 7 || _id(row[0]) != 1)
        throw const FormatException();
      final first = CashierMerchantAmount(
        id: _id(row[3]),
        amount: _amount(row[1]),
        publicAmount: _amount(row[2]),
      );
      final secondId = _id(row[4]);
      value = List.unmodifiable([
        first,
        if (secondId != 0)
          CashierMerchantAmount(
            id: secondId,
            amount: _amount(row[5]),
            publicAmount: _amount(row[6]),
          ),
      ]);
    } on Object {
      invalidate();
    }
  }

  static int _id(Object? raw) {
    final value = num.tryParse('$raw');
    if (value == null ||
        !value.isFinite ||
        value % 1 != 0 ||
        value < 0 ||
        value > 9007199254740991)
      throw const FormatException();
    return value.toInt();
  }

  static num _amount(Object? raw) {
    if (raw == null || raw == '') return 0;
    final value = num.tryParse('$raw');
    if (value == null || !value.isFinite) throw const FormatException();
    return value;
  }
}
