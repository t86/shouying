import 'package:card_table/src/card_table_models.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';

final class LegacyCardTableStore {
  static const Set<int> _requiredDatasets = <int>{0, 1, 14, 18};

  Map<String, List<Object?>> _regions = <String, List<Object?>>{};
  Map<String, List<Object?>> _seats = <String, List<Object?>>{};
  Map<String, List<Object?>> _business = <String, List<Object?>>{};
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
      if (nextBusinessDay == null) throw const FormatException();
      final snapshot = _buildSnapshot(
        cursor: envelope.cursor!,
        regions: nextRegions,
        seats: nextSeats,
        business: nextBusiness,
        businessDay: nextBusinessDay,
      );
      _regions = nextRegions;
      _seats = nextSeats;
      _business = nextBusiness;
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

  static CardTableSnapshot _buildSnapshot({
    required String cursor,
    required Map<String, List<Object?>> regions,
    required Map<String, List<Object?>> seats,
    required Map<String, List<Object?>> business,
    required List<Object?> businessDay,
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
            if (_integer(row[2]) == 1 && activeRegionIds.contains(_id(row[3])))
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
    return CardTableSnapshot(
      cursor: cursor,
      businessDayId: _id(businessDay[0]),
      storeName: _text(businessDay[2]),
      regions: normalizedRegions,
      tables: normalizedTables,
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
