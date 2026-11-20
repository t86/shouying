import 'dart:convert';

import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';

int _integer(Object? value, {int minimum = 0}) {
  final n = int.tryParse('$value');
  if (n == null || n < minimum || n > 9007199254740991) {
    throw const FormatException('整数无效');
  }
  return n;
}

String _saveUnit(Object? value) {
  if (![
    '整瓶',
    '0.1',
    '0.2',
    '0.3',
    '0.4',
    '0.5',
    '0.6',
    '0.7',
    '0.8',
    '0.9',
  ].contains(value)) {
    throw const FormatException('规格无效');
  }
  return value as String;
}

final class WineSaveEmployee {
  const WineSaveEmployee(this.id, this.name, this.code, this.namePy);
  final int id;
  final String name, code, namePy;
}

final class WineSaveEditMetadataSnapshot {
  const WineSaveEditMetadataSnapshot({
    this.known = false,
    this.employees = const [],
    this.businessDates = const [],
  });
  final bool known;
  final List<WineSaveEmployee> employees;
  final List<String> businessDates;
}

/// Source business metadata only: 5 employees and 24 canDoList. No table/role dependency.
final class WineSaveEditMetadata {
  bool _started = false,
      _online = false,
      _employeesKnown = false,
      _datesKnown = false;
  final _employees = <int, WineSaveEmployee>{};
  List<String> _dates = [];
  void start() {
    reset();
    _started = true;
  }

  void reset() {
    _started = _online = _employeesKnown = _datesKnown = false;
    _employees.clear();
    _dates = [];
  }

  void setPhase(ConnectionPhase phase) =>
      _online = phase == ConnectionPhase.online;
  WineSaveEditMetadataSnapshot get snapshot =>
      !_started || !_online || !_employeesKnown || !_datesKnown
      ? const WineSaveEditMetadataSnapshot()
      : WineSaveEditMetadataSnapshot(
          known: true,
          employees: List.unmodifiable(_employees.values),
          businessDates: List.unmodifiable(_dates),
        );
  void add(SyncEnvelope event) {
    if (!_started || event.type != SyncEventType.data) return;
    final raw = event.data;
    final full = raw is List;
    Object? dataset(int id) => raw is List
        ? (raw.length > id ? raw[id] : null)
        : raw is Map
        ? (raw[id] ?? raw['$id'])
        : null;
    bool has(int id) =>
        full || raw is Map && (raw.containsKey(id) || raw.containsKey('$id'));
    if (has(5)) {
      try {
        final rows = dataset(5);
        if (rows is! List) throw const FormatException();
        final next = full
            ? <int, WineSaveEmployee>{}
            : Map<int, WineSaveEmployee>.of(_employees);
        for (final row in rows) {
          if (row is! List || row.length < 9 || row[1] is! String) {
            throw const FormatException();
          }
          final id = _integer(row[0], minimum: 1),
              status = _integer(row[2], minimum: 1);
          if (![1, 2, 3].contains(status)) throw const FormatException();
          // Vue's orderPersonInfo picker retains all supplied 1/2/3 rows.
          next[id] = WineSaveEmployee(
            id,
            row[1] as String,
            '${row[8] ?? ''}',
            '${row[7] ?? ''}',
          );
        }
        _employees
          ..clear()
          ..addAll(next);
        if (full) _employeesKnown = true;
      } on Object {
        _employeesKnown = false;
        _employees.clear();
      }
    }
    if (has(24)) {
      try {
        final rows = dataset(24);
        if (rows is! List ||
            rows.any((row) => row is! List || row.length < 2)) {
          throw const FormatException();
        }
        DateTime date = DateTime.now();
        if (rows.isNotEmpty) {
          final value = '${(rows.first as List)[1]}';
          if (!RegExp(r'^\d{8}$').hasMatch(value)) {
            throw const FormatException();
          }
          date = DateTime(
            int.parse(value.substring(0, 4)),
            int.parse(value.substring(4, 6)),
            int.parse(value.substring(6, 8)),
          );
          if (_date(date).replaceAll('-', '') != value) {
            throw const FormatException();
          }
        }
        _dates = [
          for (var i = 0; i < 7; i++)
            _date(DateTime(date.year, date.month, date.day - i)),
        ];
        if (full) _datesKnown = true;
      } on Object {
        _datesKnown = false;
        _dates = [];
      }
    }
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final class WineSaveEditLine {
  const WineSaveEditLine({
    required this.id,
    required this.productId,
    required this.name,
    required this.unit,
    required this.count,
    required this.grams,
    required this.days,
    this.maximum,
  });
  final int id, productId, count, grams, days;
  final int? maximum;
  final String name, unit;
  factory WineSaveEditLine.fromWire(Map row) => WineSaveEditLine(
    id: _integer(row['id'], minimum: 1),
    productId: _integer(row['p'], minimum: 1),
    name: '${row['n'] ?? ''}',
    unit: _saveUnit(row['u']),
    count: _integer(row['c'], minimum: 1),
    grams: _integer(row['g'] == null || row['g'] == '' ? 0 : row['g']),
    days: _integer(
      (row['ed'] == null || '${row['ed']}' == '0' || row['ed'] == '')
          ? row['ce']
          : row['ed'],
      minimum: 1,
    ),
    maximum: row['a'] != null && row['a'] != '-'
        ? _integer(row['ac'], minimum: 1)
        : null,
  );
  WineSaveEditLine copy({String? unit, int? count, int? grams, int? days}) =>
      WineSaveEditLine(
        id: id,
        productId: productId,
        name: name,
        unit: unit ?? this.unit,
        count: count ?? this.count,
        grams: grams ?? this.grams,
        days: days ?? this.days,
        maximum: maximum,
      );
}

final class WineSaveEditRecord {
  WineSaveEditRecord.fromWire(Map row)
    : fingerprint = jsonEncode(row),
      id = _integer(row['o'], minimum: 1),
      csmId = _integer(row['m'] ?? 0),
      seatId = _integer(row['si'] ?? 0),
      seatName = '${row['s'] ?? ''}',
      businessDate = '${row['d'] ?? ''}',
      customerName =
          '${row['c'] == null || row['c'] == '' ? row['rn'] ?? '' : row['c']}',
      phone =
          '${row['p'] == null || row['p'] == '' ? row['rp'] ?? '' : row['p']}',
      remark = '${row['r'] ?? ''}',
      storeTime = '${row['t'] ?? ''}',
      lines = List.unmodifiable([
        for (final item in (row['ss'] as List? ?? []))
          WineSaveEditLine.fromWire(item as Map),
      ]);
  final int id, csmId, seatId;
  final String fingerprint;
  final String seatName, businessDate, customerName, phone, remark, storeTime;
  final List<WineSaveEditLine> lines;
  Map<String, Object?> body({
    required List<WineSaveEditLine> lines,
    required bool linked,
    required int csmId,
    required int seatId,
    required int salesEmployeeId,
    required String customerName,
    required String phone,
    required String remark,
    required String storeTime,
  }) {
    if (lines.isEmpty ||
        (linked ? csmId <= 0 : seatId <= 0 || salesEmployeeId < 0)) {
      throw const FormatException('请选择卡台及流水/订位人');
    }
    for (final line in lines) {
      if (line.id <= 0 ||
          line.productId <= 0 ||
          line.count <= 0 ||
          line.days <= 0 ||
          line.grams < 0 ||
          (line.maximum != null && line.count > line.maximum!) ||
          ![
            '整瓶',
            '0.1',
            '0.2',
            '0.3',
            '0.4',
            '0.5',
            '0.6',
            '0.7',
            '0.8',
            '0.9',
          ].contains(line.unit)) {
        throw const FormatException('商品数量、规格或有效期无效');
      }
    }
    return {
      'bef_in_id': id,
      'mode_type': linked ? 1 : 2,
      'bef_in_dtl_ids': [for (final l in lines) l.id],
      'unit_types': [for (final l in lines) l.unit == '整瓶' ? '1' : l.unit],
      'prd_cnts': [for (final l in lines) l.count],
      'expired_days': [for (final l in lines) l.days],
      'g_cnts': [for (final l in lines) l.grams],
      'prd_ids': [for (final l in lines) l.productId],
      'csm_id': linked ? csmId : 0,
      'seat_id': linked ? 0 : seatId,
      'sales_emp_id': linked ? 0 : salesEmployeeId,
      'cust_name': customerName,
      'cust_phone': phone,
      'remark': remark,
      'store_time': storeTime,
    };
  }
}

final class WineSaveEditContext {
  const WineSaveEditContext(this.records, this.needsAuthorization);
  final List<WineSaveEditRecord> records;
  final bool? needsAuthorization;
}

abstract interface class WineSaveEditLoader {
  Object? get saveEditSession;
  WineSaveEditMetadataSnapshot get saveEditSnapshot;
  Future<Result<WineSaveEditContext>> loadSaveEditContext();
  Future<Result<List<Map<String, Object?>>>> loadSaveEditSeats({String? day});
  Future<Result<List<Map<String, Object?>>>> loadSaveEditOrders(
    String day,
    int seatId,
  );
}

bool validWineSaveEditBody(Map<String, Object?> fields) {
  const keys = {
    'bef_in_id',
    'mode_type',
    'bef_in_dtl_ids',
    'unit_types',
    'prd_cnts',
    'expired_days',
    'g_cnts',
    'prd_ids',
    'csm_id',
    'seat_id',
    'sales_emp_id',
    'cust_name',
    'cust_phone',
    'remark',
    'store_time',
  };
  if (fields.length != keys.length || !fields.keys.every(keys.contains)) {
    return false;
  }
  bool integer(Object? n, int min) =>
      n is int && n >= min && n <= 9007199254740991;
  if (!integer(fields['bef_in_id'], 1) ||
      ![1, 2].contains(fields['mode_type'])) {
    return false;
  }
  for (final key in ['csm_id', 'seat_id', 'sales_emp_id']) {
    if (!integer(fields[key], 0)) return false;
  }
  if (fields['mode_type'] == 1) {
    if (!integer(fields['csm_id'], 1) ||
        fields['seat_id'] != 0 ||
        fields['sales_emp_id'] != 0) {
      return false;
    }
  } else if (fields['csm_id'] != 0 || !integer(fields['seat_id'], 1)) {
    return false;
  }
  final ids = fields['bef_in_dtl_ids'];
  if (ids is! List || ids.isEmpty) return false;
  for (final key in [
    'bef_in_dtl_ids',
    'prd_cnts',
    'expired_days',
    'g_cnts',
    'prd_ids',
  ]) {
    final values = fields[key];
    if (values is! List ||
        values.length != ids.length ||
        !values.every((v) => integer(v, key == 'g_cnts' ? 0 : 1))) {
      return false;
    }
  }
  final units = fields['unit_types'];
  if (units is! List ||
      units.length != ids.length ||
      !units.every(
        (v) => [
          '1',
          '0.1',
          '0.2',
          '0.3',
          '0.4',
          '0.5',
          '0.6',
          '0.7',
          '0.8',
          '0.9',
        ].contains(v),
      )) {
    return false;
  }
  return [
        'cust_name',
        'cust_phone',
        'remark',
        'store_time',
      ].every((k) => fields[k] is String) &&
      '${fields['store_time']}'.isNotEmpty;
}
