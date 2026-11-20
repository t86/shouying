import 'package:card_table/src/cashier_profit_loss.dart';
import 'package:flutter/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';

final class CashierProfitLossMetadata
    extends ValueNotifier<CashierProfitLossCatalog> {
  CashierProfitLossMetadata() : super(const CashierProfitLossCatalog());
  static const _datasets = [2, 3, 4, 16, 30];
  final Map<int, Map<String, List<Object?>>> _tables = {};
  bool _ready = false;

  void add(SyncEnvelope event) {
    if (event.type == SyncEventType.heartbeat) return;
    if (event.type != SyncEventType.data) {
      invalidate();
      return;
    }
    final data = event.data;
    final full = data is List;
    if (!full && data is! Map) {
      invalidate();
      return;
    }
    if (!full && !_ready) return;
    try {
      if (full) {
        _tables.clear();
        _ready = false;
      }
      var changed = false;
      for (final index in _datasets) {
        if (!full &&
            !(data as Map).containsKey(index) &&
            !data.containsKey('$index')) {
          continue;
        }
        final rows = full
            ? (data.length > index ? data[index] : null)
            : (data as Map)[index] ?? data['$index'];
        if (rows is! List || rows.length > 20000) throw const FormatException();
        final table = _tables.putIfAbsent(index, () => {});
        for (final raw in rows) {
          if (raw is! List || raw.length < 3) throw const FormatException();
          final row = List<Object?>.unmodifiable(raw);
          final key = index == 16
              ? '${_id(row[0], zero: true)}:${_id(row[2])}'
              : _id(row[0]);
          table[key] = row;
        }
        if (table.length > 20000) throw const FormatException();
        changed = true;
      }
      if (!changed) return;
      final libraries = <String, String>{};
      for (final row in _tables[30]!.values) {
        if (_number(row[2]) == 1) libraries[_id(row[0])] = _text(row[1]);
      }
      String category(int dataset, Object? id) {
        final row = _tables[dataset]![_id(id, zero: true)];
        return row != null && _number(row[2]) == 1 ? _text(row[1]) : '';
      }

      final products = <String, List<CashierProfitLossProduct>>{
        for (final id in libraries.keys) id: [],
      };
      final included = <String, Set<String>>{
        for (final id in libraries.keys) id: {},
      };
      for (final relation in _tables[16]!.values) {
        if (_number(relation[1]) != 1) continue;
        if (relation.length < 4 || relation[3] == null || relation[3] == '') {
          continue;
        }
        final library = _id(relation[3], zero: true);
        if (!libraries.containsKey(library)) continue;
        final id = _id(relation[2]);
        final row = _tables[4]![id];
        if (row == null || _number(row[2]) != 1) continue;
        if (row.length < 12) throw const FormatException();
        if (_number(row[11]) == 0 || !included[library]!.add(id)) continue;
        products[library]!.add(
          CashierProfitLossProduct(
            id: id,
            name: _text(row[1]),
            firstCategory: category(2, row[6]),
            secondCategory: category(3, row[7]),
          ),
        );
      }
      _ready = true;
      value = CashierProfitLossCatalog(
        libraries: Map.unmodifiable(libraries),
        productsByLibrary: Map.unmodifiable({
          for (final entry in products.entries)
            entry.key: List<CashierProfitLossProduct>.unmodifiable(entry.value),
        }),
      );
    } on Object {
      invalidate();
    }
  }

  void invalidate() {
    _tables.clear();
    _ready = false;
    value = const CashierProfitLossCatalog();
  }

  static int _number(Object? value) {
    final parsed = value is num && value.isFinite && value % 1 == 0
        ? value.toInt()
        : value is String
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed < 0 || parsed > 9007199254740991) {
      throw const FormatException();
    }
    return parsed;
  }

  static String _id(Object? value, {bool zero = false}) {
    final id = _number(value);
    if (!zero && id == 0) throw const FormatException();
    return '$id';
  }

  static String _text(Object? value) {
    if (value == null) return '';
    if (value is! String || value.length > 4096) throw const FormatException();
    return value;
  }
}
