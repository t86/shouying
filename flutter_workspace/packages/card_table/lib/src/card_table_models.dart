import 'dart:collection';

final class CardRegion {
  const CardRegion({
    required this.id,
    required this.name,
    required this.displayOrder,
  });

  final String id;
  final String name;
  final int displayOrder;

  @override
  String toString() => 'CardRegion(id: $id)';
}

final class CardBusinessDate {
  const CardBusinessDate({required this.id, required this.label});

  final String id;
  final String label;

  @override
  String toString() => 'CardBusinessDate(id: $id)';
}

final class CardTable {
  const CardTable({
    required this.id,
    required this.name,
    required this.regionId,
    required this.seatType,
    required this.businessType,
    required this.capacity,
    required this.displayOrder,
    required this.businessStatus,
    required this.orderAmount,
    required this.paidAmount,
    required this.customerName,
    required this.customerCount,
    required this.reservationTime,
    required this.openTime,
    required this.remark,
    required this.mark,
  });

  final String id;
  final String name;
  final String regionId;
  final int seatType;
  final int businessType;
  final int capacity;
  final int displayOrder;
  final int businessStatus;
  final num orderAmount;
  final num paidAmount;
  final String customerName;
  final int customerCount;
  final String reservationTime;
  final String openTime;
  final String remark;
  final String mark;

  @override
  String toString() => 'CardTable(id: $id, businessStatus: $businessStatus)';
}

final class CardTableSnapshot {
  CardTableSnapshot({
    required this.cursor,
    required this.businessDayId,
    required this.storeName,
    required Iterable<CardRegion> regions,
    required Iterable<CardTable> tables,
    Iterable<CardBusinessDate> businessDates = const <CardBusinessDate>[],
    Map<String, Iterable<CardTable>> tablesByDate = const {},
    Map<int, int> statusCounts = const <int, int>{},
    Map<String, Map<int, int>> statusCountsByRegion = const {},
  }) : regions = UnmodifiableListView<CardRegion>(List<CardRegion>.of(regions)),
       tables = UnmodifiableListView<CardTable>(List<CardTable>.of(tables)),
       businessDates = UnmodifiableListView<CardBusinessDate>(
         List<CardBusinessDate>.of(businessDates),
       ),
       _tablesByDate = UnmodifiableMapView<String, List<CardTable>>(
         <String, List<CardTable>>{
           for (final entry in tablesByDate.entries)
             entry.key: UnmodifiableListView<CardTable>(
               List<CardTable>.of(entry.value),
             ),
         },
       ),
       statusCounts = UnmodifiableMapView<int, int>(
         Map<int, int>.of(statusCounts),
       ),
       _statusCountsByRegion = UnmodifiableMapView<String, Map<int, int>>(
         <String, Map<int, int>>{
           for (final entry in statusCountsByRegion.entries)
             entry.key: UnmodifiableMapView<int, int>(
               Map<int, int>.of(entry.value),
             ),
         },
       );

  final String cursor;
  final String businessDayId;
  final String storeName;
  final List<CardRegion> regions;
  final List<CardTable> tables;
  final List<CardBusinessDate> businessDates;
  final Map<String, List<CardTable>> _tablesByDate;
  final Map<int, int> statusCounts;
  final Map<String, Map<int, int>> _statusCountsByRegion;

  bool get businessOpen => businessDayId != '0';

  List<CardTable> tablesForDate(String? dateId) {
    if (dateId == null ||
        businessDates.isEmpty ||
        dateId == businessDates.first.id) {
      return tables;
    }
    return _tablesByDate[dateId] ?? tables;
  }

  Map<int, int> statusCountsForRegion(String? regionId) => regionId == null
      ? statusCounts
      : _statusCountsByRegion[regionId] ?? const {};

  @override
  String toString() =>
      'CardTableSnapshot(cursor: $cursor, regions: ${regions.length}, '
      'tables: ${tables.length}, dates: ${businessDates.length}, '
      'businessOpen: $businessOpen)';
}
