import 'package:card_table/src/card_table_models.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';

final class LegacyCardTableStore {
  factory LegacyCardTableStore({String? machineId}) =>
      LegacyCardTableStore._(machineId);

  LegacyCardTableStore._(this._machineId);

  static const Set<int> _requiredDatasets = <int>{0, 1, 14, 18};

  final String? _machineId;
  Map<String, List<Object?>> _regions = <String, List<Object?>>{};
  Map<String, List<Object?>> _seats = <String, List<Object?>>{};
  Map<String, List<Object?>> _business = <String, List<Object?>>{};
  Map<String, List<Object?>> _businessDates = <String, List<Object?>>{};
  Map<String, List<Object?>> _futureBookings = <String, List<Object?>>{};
  Map<String, List<Object?>> _statusCounts = <String, List<Object?>>{};
  Map<String, List<Object?>> _machineAccess = <String, List<Object?>>{};
  List<Object?>? _businessDay;
  CardTableSnapshot? _currentSnapshot;

  CardTableSnapshot? get currentSnapshot => _currentSnapshot;

  Result<CardTableSnapshot> applyEnvelope(SyncEnvelope envelope) {
    if (envelope.type != SyncEventType.data) {
      final current = _currentSnapshot;
      return current == null
          ? const FailureResult(_snapshotRequiredFailure)
          : Success(current);
    }

    final datasets = _datasets(envelope.data);
    if (datasets == null) return const FailureResult(_shapeFailure);
    final isFull = envelope.data is List || _currentSnapshot == null;
    if (isFull && !_requiredDatasets.every(datasets.containsKey)) {
      return const FailureResult(_snapshotRequiredFailure);
    }

    final nextRegions = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_regions);
    final nextSeats = isFull ? <String, List<Object?>>{} : _copyRows(_seats);
    final nextBusiness = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_business);
    final nextBusinessDates = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_businessDates);
    final nextFutureBookings = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_futureBookings);
    final nextStatusCounts = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_statusCounts);
    final nextMachineAccess = isFull
        ? <String, List<Object?>>{}
        : _copyRows(_machineAccess);
    var nextBusinessDay = isFull
        ? null
        : _businessDay == null
        ? null
        : List<Object?>.of(_businessDay!);

    try {
      if (datasets.containsKey(0)) {
        _mergeRows(nextRegions, _rows(datasets[0], minimumLength: 4), 2);
      }
      if (datasets.containsKey(1)) {
        _mergeRows(nextSeats, _rows(datasets[1], minimumLength: 8), 2);
      }
      if (datasets.containsKey(14)) {
        _mergeRows(
          nextBusiness,
          _rows(datasets[14], minimumLength: 38),
          19,
          deletedStatuses: const <int>{22, 33},
        );
      }
      if (datasets.containsKey(18)) {
        final rows = _rows(datasets[18], minimumLength: 3);
        if (rows.isEmpty) throw const FormatException();
        nextBusinessDay = List<Object?>.unmodifiable(rows.first);
      }
      if (datasets.containsKey(24)) {
        _mergeRowsByKey(
          nextBusinessDates,
          _rows(datasets[24], minimumLength: 2),
          (row) => _id(row[1]),
        );
      }
      if (datasets.containsKey(25)) {
        _mergeRowsByKey(
          nextFutureBookings,
          _rows(datasets[25], minimumLength: 14),
          (row) => '${_id(row[0])}|${_id(row[1])}',
        );
      }
      if (datasets.containsKey(39)) {
        _mergeRowsByKey(
          nextStatusCounts,
          _rows(datasets[39], minimumLength: 3),
          (row) => '${_integer(row[0])}|${_id(row[1])}',
        );
      }
      if (datasets.containsKey(40)) {
        _mergeRowsByKey(
          nextMachineAccess,
          _rows(datasets[40], minimumLength: 4),
          (row) => '${_id(row[0])}|${_integer(row[1])}|${_id(row[3])}',
        );
      }
      if (nextBusinessDay == null) throw const FormatException();
      final snapshot = _buildSnapshot(
        cursor: envelope.cursor!,
        regions: nextRegions,
        seats: nextSeats,
        business: nextBusiness,
        businessDay: nextBusinessDay,
        businessDates: nextBusinessDates,
        futureBookings: nextFutureBookings,
        statusCountRows: nextStatusCounts,
        machineId: _machineId,
        machineAccess: nextMachineAccess,
      );
      _regions = nextRegions;
      _seats = nextSeats;
      _business = nextBusiness;
      _businessDates = nextBusinessDates;
      _futureBookings = nextFutureBookings;
      _statusCounts = nextStatusCounts;
      _machineAccess = nextMachineAccess;
      _businessDay = nextBusinessDay;
      _currentSnapshot = snapshot;
      return Success(snapshot);
    } on Object {
      return const FailureResult(_shapeFailure);
    }
  }

  static Map<int, Object?>? _datasets(Object? value) {
    if (value is List) {
      return <int, Object?>{
        for (var index = 0; index < value.length; index += 1)
          index: value[index],
      };
    }
    if (value is Map) {
      final result = <int, Object?>{};
      for (final entry in value.entries) {
        final index = switch (entry.key) {
          int() => entry.key as int,
          String() => int.tryParse(entry.key as String),
          _ => null,
        };
        if (index == null || index < 0 || index > 1024) return null;
        result[index] = entry.value;
      }
      return result;
    }
    return null;
  }

  static List<List<Object?>> _rows(
    Object? value, {
    required int minimumLength,
  }) {
    if (value is! List) throw const FormatException();
    return <List<Object?>>[
      for (final row in value)
        if (row is List && row.length >= minimumLength)
          List<Object?>.of(row)
        else
          throw const FormatException(),
    ];
  }

  static void _mergeRows(
    Map<String, List<Object?>> target,
    List<List<Object?>> rows,
    int statusIndex, {
    Set<int> deletedStatuses = const <int>{3},
  }) {
    for (final row in rows) {
      final id = _id(row[0]);
      final status = _integer(row[statusIndex]);
      if (deletedStatuses.contains(status)) {
        target.remove(id);
      } else {
        target[id] = List<Object?>.unmodifiable(row);
      }
    }
  }

  static void _mergeRowsByKey(
    Map<String, List<Object?>> target,
    List<List<Object?>> rows,
    String Function(List<Object?> row) keyOf,
  ) {
    for (final row in rows) {
      target[keyOf(row)] = List<Object?>.unmodifiable(row);
    }
  }

  static CardTableSnapshot _buildSnapshot({
    required String cursor,
    required Map<String, List<Object?>> regions,
    required Map<String, List<Object?>> seats,
    required Map<String, List<Object?>> business,
    required List<Object?> businessDay,
    required Map<String, List<Object?>> businessDates,
    required Map<String, List<Object?>> futureBookings,
    required Map<String, List<Object?>> statusCountRows,
    required String? machineId,
    required Map<String, List<Object?>> machineAccess,
  }) {
    final normalizedRegions =
        <CardRegion>[
          for (final row in regions.values)
            if (_integer(row[2]) == 1)
              CardRegion(
                id: _id(row[0]),
                name: _text(row[1]),
                displayOrder: _integer(row[3]),
              ),
        ]..sort((left, right) {
          final order = left.displayOrder.compareTo(right.displayOrder);
          return order != 0 ? order : left.id.compareTo(right.id);
        });
    final activeRegionIds = normalizedRegions
        .map((region) => region.id)
        .toSet();
    final normalizedTables =
        <CardTable>[
          for (final row in seats.values)
            if (_integer(row[2]) == 1 &&
                activeRegionIds.contains(_id(row[3])) &&
                _isSeatPermitted(row, machineId, machineAccess))
              _table(row, business[_id(row[0])]),
        ]..sort((left, right) {
          final region = normalizedRegions
              .indexWhere((value) => value.id == left.regionId)
              .compareTo(
                normalizedRegions.indexWhere(
                  (value) => value.id == right.regionId,
                ),
              );
          if (region != 0) return region;
          final order = left.displayOrder.compareTo(right.displayOrder);
          return order != 0 ? order : left.name.compareTo(right.name);
        });
    final normalizedDates = <CardBusinessDate>[
      for (final row in businessDates.values)
        CardBusinessDate(id: _id(row[1]), label: _text(row[0])),
    ];
    final tablesByDate = <String, Iterable<CardTable>>{};
    for (final date in normalizedDates.skip(1)) {
      tablesByDate[date.id] =
          <CardTable>[
            for (final seat in seats.values)
              if (_integer(seat[2]) == 1 &&
                  activeRegionIds.contains(_id(seat[3])) &&
                  _isSeatPermitted(seat, machineId, machineAccess))
                _futureTable(
                  seat,
                  business[_id(seat[0])],
                  futureBookings['${date.id}|${_id(seat[0])}'],
                ),
          ]..sort((left, right) {
            final region = normalizedRegions
                .indexWhere((value) => value.id == left.regionId)
                .compareTo(
                  normalizedRegions.indexWhere(
                    (value) => value.id == right.regionId,
                  ),
                );
            if (region != 0) return region;
            final order = left.displayOrder.compareTo(right.displayOrder);
            return order != 0 ? order : left.name.compareTo(right.name);
          });
    }
    final visibleRegionIds = normalizedTables
        .map((table) => table.regionId)
        .toSet();
    normalizedRegions.removeWhere(
      (region) => !visibleRegionIds.contains(region.id),
    );
    final normalizedStatusCounts = _normalizeStatusCounts(statusCountRows);
    return CardTableSnapshot(
      cursor: cursor,
      businessDayId: _id(businessDay[0]),
      storeName: _text(businessDay[2]),
      regions: normalizedRegions,
      tables: normalizedTables,
      businessDates: normalizedDates,
      tablesByDate: tablesByDate,
      statusCounts: normalizedStatusCounts.totals,
      statusCountsByRegion: normalizedStatusCounts.byRegion,
    );
  }

  static CardTable _table(List<Object?> seat, List<Object?>? business) =>
      CardTable(
        id: _id(seat[0]),
        name: _text(seat[1]),
        regionId: _id(seat[3]),
        seatType: _integer(seat[4]),
        businessType: _integer(seat[5]),
        capacity: _integer(seat[6]),
        displayOrder: _integer(seat[7]),
        businessStatus: business == null ? 1 : _integer(business[19]),
        orderAmount: business == null ? 0 : _number(business[6]),
        paidAmount: business == null ? 0 : _number(business[8]),
        customerName: business == null ? '' : _optionalText(business[16]),
        customerCount: business == null ? 0 : _integer(business[18]),
        reservationTime: business == null ? '' : _optionalText(business[2]),
        openTime: business == null ? '' : _optionalText(business[5]),
        remark: business == null ? '' : _optionalText(business[24]),
        mark: business == null ? '' : _optionalText(business[25]),
      );

  static CardTable _futureTable(
    List<Object?> seat,
    List<Object?>? currentBusiness,
    List<Object?>? booking,
  ) {
    final currentStatus = currentBusiness == null
        ? 1
        : _integer(currentBusiness[19]);
    final activeBooking = booking != null && _integer(booking[9]) == 1;
    return CardTable(
      id: _id(seat[0]),
      name: _text(seat[1]),
      regionId: _id(seat[3]),
      seatType: _integer(seat[4]),
      businessType: _integer(seat[5]),
      capacity: _integer(seat[6]),
      displayOrder: _integer(seat[7]),
      businessStatus: activeBooking ? 8 : (currentStatus == 2 ? 2 : 1),
      orderAmount: 0,
      paidAmount: 0,
      customerName: activeBooking ? _optionalText(booking[6]) : '',
      customerCount: activeBooking ? _integer(booking[8]) : 0,
      reservationTime: activeBooking ? _optionalText(booking[3]) : '',
      openTime: '',
      remark: activeBooking ? _optionalText(booking[12]) : '',
      mark: '',
    );
  }

  static bool _isSeatPermitted(
    List<Object?> seat,
    String? machineId,
    Map<String, List<Object?>> accessRows,
  ) {
    if (machineId == null) return true;
    final normalizedMachineId = _id(machineId);
    final rows = accessRows.values.where(
      (row) => _id(row[0]) == normalizedMachineId && _integer(row[2]) == 1,
    );
    if (rows.any((row) => _integer(row[1]) == 3)) return true;
    final allowedRegions = <String>{
      for (final row in rows)
        if (_integer(row[1]) == 1) _id(row[3]),
    };
    final allowedSeats = <String>{
      for (final row in rows)
        if (_integer(row[1]) == 2) _id(row[3]),
    };
    final regionId = _id(seat[3]);
    final seatId = _id(seat[0]);
    if (allowedRegions.isNotEmpty && !allowedRegions.contains(regionId)) {
      return false;
    }
    return allowedSeats.isEmpty || allowedSeats.contains(seatId);
  }

  static ({Map<int, int> totals, Map<String, Map<int, int>> byRegion})
  _normalizeStatusCounts(Map<String, List<Object?>> rows) {
    final totals = <int, int>{};
    final regionTotals = <int, int>{};
    final byRegion = <String, Map<int, int>>{};
    for (final row in rows.values) {
      final status = _integer(row[0]);
      final regionId = _id(row[1]);
      final count = _integer(row[2]);
      if (count < 0) throw const FormatException();
      if (regionId == '0') {
        totals[status] = count;
      } else {
        byRegion.putIfAbsent(regionId, () => <int, int>{})[status] = count;
        regionTotals.update(
          status,
          (value) => value + count,
          ifAbsent: () => count,
        );
      }
    }
    for (final entry in regionTotals.entries) {
      totals.putIfAbsent(entry.key, () => entry.value);
    }
    return (totals: totals, byRegion: byRegion);
  }

  static Map<String, List<Object?>> _copyRows(
    Map<String, List<Object?>> source,
  ) => <String, List<Object?>>{
    for (final entry in source.entries)
      entry.key: List<Object?>.unmodifiable(entry.value),
  };

  static String _id(Object? value) {
    if (value is String &&
        value.isNotEmpty &&
        value.length <= 64 &&
        value.trim() == value &&
        RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value)) {
      return value;
    }
    if (value is num && value.isFinite && value % 1 == 0) {
      return value.toInt().toString();
    }
    throw const FormatException();
  }

  static int _integer(Object? value) {
    final number = _number(value);
    if (number % 1 != 0 || number.abs() > 9007199254740991) {
      throw const FormatException();
    }
    return number.toInt();
  }

  static num _number(Object? value) {
    final number = switch (value) {
      num() => value,
      String() when value.trim() == value => num.tryParse(value),
      _ => null,
    };
    if (number == null || !number.isFinite) throw const FormatException();
    return number;
  }

  static String _text(Object? value) {
    final text = _optionalText(value);
    if (text.isEmpty) throw const FormatException();
    return text;
  }

  static String _optionalText(Object? value) {
    if (value == null) return '';
    if (value is! String ||
        value.length > 256 ||
        RegExp(r'[\x00-\x1F\x7F]').hasMatch(value)) {
      throw const FormatException();
    }
    return value;
  }

  static const AppFailure _shapeFailure = AppFailure(
    kind: FailureKind.protocol,
    code: 'protocol.card_table_shape',
    safeMessage: '卡台数据格式无法识别',
  );
  static const AppFailure _snapshotRequiredFailure = AppFailure(
    kind: FailureKind.realtime,
    code: 'protocol.card_table_snapshot_required',
    safeMessage: '正在等待完整卡台数据',
  );
}
