import 'dart:collection';

import 'package:card_table/src/booking_queue.dart';
import 'package:permissions/permissions.dart';

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

final class CardEmployee {
  const CardEmployee({
    required this.id,
    required this.name,
    required this.deptId,
    this.upperEmpId = '',
    this.phone = '',
    this.code = '',
    this.namePy = '',
    this.status = 1,
  });

  final String id;
  final String name;
  final String deptId;
  final String upperEmpId;
  final String phone;
  final String code;
  final String namePy;
  final int status;

  @override
  String toString() => 'CardEmployee(id: $id)';
}

final class CardDepartment {
  const CardDepartment({required this.id, required this.name});

  final String id;
  final String name;

  @override
  String toString() => 'CardDepartment(id: $id)';
}

final class CardTable {
  CardTable({
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
    this.salesEmployeeId = '',
    Iterable<String> waiterEmployeeIds = const <String>{},
    this.turnoverCount = 0,
    this.giftAmount = 0,
    this.assignedMinConsumeAmount = 0,
    this.mainOrderAmount = 0,
    this.paidMainFreeAmount = 0,
    this.paidValAmount = 0,
    this.waiterEmployeeId = '',
    this.customerPhone = '',
    this.boundCustomerName = '',
    this.bookId = '',
    this.platformId = 0,
    this.secondSalesEmployeeId = '',
    this.pinned = false,
    this.pinOrder = 0,
    this.mustOrderDisabled = false,
    this.showOnlineText = false,
    this.discountAmount = 0,
    this.customerNamePy = '',
    this.bookingCustomerPhone = '',
    this.expectedArriveTime = '',
    this.groupMinConsumeAmount = 0,
    this.transferHistory = '',
  }) : waiterEmployeeIds = UnmodifiableSetView<String>(
         Set<String>.of(waiterEmployeeIds),
       );

  final String id;
  final String name;
  final String regionId;
  final int seatType;
  final int businessType;
  final int capacity;
  final int displayOrder;
  final int businessStatus;
  final num orderAmount;

  /// Dataset 14 column 38, yuan. Missing on older backends means zero.
  final num discountAmount;
  num originalAmount({bool historical = false}) =>
      ((orderAmount * 100).round() +
          (historical ? 0 : (discountAmount * 100).round())) /
      100;
  final num paidAmount;
  final String customerName;
  final int customerCount;
  final String reservationTime;
  final String openTime;
  final String remark;
  final String mark;
  final String salesEmployeeId;
  final Set<String> waiterEmployeeIds;
  final int turnoverCount;
  final num giftAmount;
  final num assignedMinConsumeAmount;
  final num mainOrderAmount;
  final num paidMainFreeAmount;
  final num paidValAmount;
  final String waiterEmployeeId;
  final String customerPhone;
  final String boundCustomerName;
  final String bookId;
  final int platformId;
  final String secondSalesEmployeeId;
  final bool pinned;

  /// Dataset 29 `seq_id` (`topNum`): higher values sort to the very front.
  final int pinOrder;
  final bool mustOrderDisabled;
  final bool showOnlineText;

  /// Dataset 14 column 23 / dataset 25 column 13: customer name pinyin.
  final String customerNamePy;

  /// Dataset 14 column 17 / dataset 25 column 7: reservation/booking customer phone.
  final String bookingCustomerPhone;

  /// Dataset 14 column 4 / dataset 25 column 4: expected arrive time.
  final String expectedArriveTime;

  /// Dataset 14 column 9 (`grpMinCsmAmt`): table default minimum spend.
  final num groupMinConsumeAmount;

  /// Dataset 14 column 32 (`chgSeatInfo`): table transfer chain e.g. A01->A03.
  final String transferHistory;

  bool get isPinned => pinned || pinOrder > 0;

  /// Booking phone prefers dataset 14 col 17 (reservation phone), falling back
  /// to col 35 (`csm_cust_phone`) when only bound guest phone is populated.
  String get effectiveBookingPhone =>
      bookingCustomerPhone.trim().isNotEmpty
          ? bookingCustomerPhone.trim()
          : customerPhone.trim();

  /// Vue `diXiaoJindu`: (order_zy_amt - payed_zy_free_amt) / assignMinCsmAmt.
  String get minConsumeProgress {
    if (assignedMinConsumeAmount <= 0) return '';
    final percent =
        ((mainOrderAmount - paidMainFreeAmount) / assignedMinConsumeAmount) *
        100;
    if (percent > 100) return '100%';
    return '${percent.toStringAsFixed(0)}%';
  }

  /// Ownership narrows an already-authorized table list; it grants no access.
  bool belongsToEmployee(String? id) =>
      id != null &&
      id.isNotEmpty &&
      (salesEmployeeId == id || waiterEmployeeIds.contains(id));

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
    this.pagePermissions,
    this.safeModeEnabled = true,
    this.bindGuestEnabled = false,
    this.canClearSeat = false,
    this.cardAmountsVisible = true,
    this.supervisorRegionRestricted = false,
    Iterable<String> supervisorAllowedRegionIds = const <String>{},
    Iterable<CardEmployee> employees = const <CardEmployee>[],
    Iterable<CardDepartment> departments = const <CardDepartment>[],
    Iterable<String> seatMarks = const <String>[],
    this.queue = const CardTableQueueSnapshot(),
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
       ),
       employees = UnmodifiableListView<CardEmployee>(
         List<CardEmployee>.of(employees),
       ),
       departments = UnmodifiableListView<CardDepartment>(
         List<CardDepartment>.of(departments),
       ),
       seatMarks = UnmodifiableListView<String>(List<String>.of(seatMarks)),
       supervisorAllowedRegionIds = UnmodifiableSetView<String>(
         Set<String>.of(supervisorAllowedRegionIds),
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
  final PermissionSnapshot? pagePermissions;
  final bool safeModeEnabled;
  final bool bindGuestEnabled;
  final bool canClearSeat;

  /// showAmt id 3: card face 惠/主 amounts. Missing row means visible;
  /// a row is visible only when param1 == 2 (cardMachine.vue:117).
  final bool cardAmountsVisible;
  final bool supervisorRegionRestricted;
  final Set<String> supervisorAllowedRegionIds;
  final List<CardEmployee> employees;
  final List<CardDepartment> departments;
  final List<String> seatMarks;
  final CardTableQueueSnapshot queue;

  bool isRegionPermittedForSupervisor(String regionId) =>
      !supervisorRegionRestricted || supervisorAllowedRegionIds.contains(regionId);

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

  /// Counts only the caller's already-authorized personal table selection.
  /// Dataset 39 uses a seat id, not a region id, for cumulative ids 30/31.
  Map<int, int> personalStatusCounts(Iterable<CardTable> personalTables) {
    final counts = <int, int>{1: 0, 8: 0, 5: 0, 6: 0, 7: 0, 10: 0, 20: 0};
    for (final table in personalTables) {
      if (const <int>{1, 8, 5, 6, 7}.contains(table.businessStatus)) {
        counts[table.businessStatus] = counts[table.businessStatus]! + 1;
      }
      final cumulative = _statusCountsByRegion[table.id];
      counts[10] = counts[10]! + (cumulative?[30] ?? 0);
      counts[20] = counts[20]! + (cumulative?[31] ?? 0);
    }
    return UnmodifiableMapView<int, int>(counts);
  }

  @override
  String toString() =>
      'CardTableSnapshot(cursor: $cursor, regions: ${regions.length}, '
      'tables: ${tables.length}, dates: ${businessDates.length}, '
      'businessOpen: $businessOpen)';
}
