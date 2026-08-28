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
  }) : regions = UnmodifiableListView<CardRegion>(List<CardRegion>.of(regions)),
       tables = UnmodifiableListView<CardTable>(List<CardTable>.of(tables));

  final String cursor;
  final String businessDayId;
  final String storeName;
  final List<CardRegion> regions;
  final List<CardTable> tables;

  bool get businessOpen => businessDayId != '0';

  @override
  String toString() =>
      'CardTableSnapshot(cursor: $cursor, regions: ${regions.length}, '
      'tables: ${tables.length}, businessOpen: $businessOpen)';
}
