import 'package:card_table/src/card_table_models.dart';
import 'package:permissions/permissions.dart';

/// Vue `newOrderCard.vue` card-body fields and `currentCardCanLookOrder`.
/// Marketing `get_sales_seats` is not in this slice.
final class OrderCardDisplay {
  /// newFootBar: server chk_order_can_see plus dataset56 supervisor scope.
  /// This is intentionally separate from myOrder's less restrictive summary.
  static bool canShowFooterAmounts({
    required PermissionSnapshot? permissions,
    required bool isPc,
    required bool isCashier,
    required bool? canLookOrderAmount,
    required String? regionId,
    required Object? supervisorRegions,
    required bool isWide,
    required bool safeModeEnabled,
  }) {
    if (!canShowOrderSummary(permissions: permissions, isPc: isPc) ||
        (!isCashier && canLookOrderAmount != true) ||
        (isWide && safeModeEnabled) || regionId == null || regionId.isEmpty) {
      return false;
    }
    if (!permissions!.roleIds.contains(11)) return true;
    if (supervisorRegions is! List) return false;
    final targetRegion = int.tryParse(regionId);
    if (targetRegion == null || targetRegion <= 0 || permissions.stationId == null) return false;
    var allowed = false;
    for (final row in supervisorRegions) {
      if (row is! List || row.length < 3) return false;
      final station = int.tryParse('${row[0]}');
      final region = int.tryParse('${row[1]}');
      final status = int.tryParse('${row[2]}');
      if (station == null || region == null || status == null) return false;
      if (station == permissions.stationId && status == 1 &&
          (region == 0 || region == targetRegion)) {
        allowed = true;
      }
    }
    return allowed;
  }

  /// Vue myOrder.shouldHideBottomAmounts; unknown permission data stays hidden.
  static bool canShowOrderSummary({
    required PermissionSnapshot? permissions,
    required bool isPc,
  }) => permissions != null && permissions.available &&
      !(isPc && permissions.roleIds.contains(3) &&
          permissions.moduleIds.contains(12) && permissions.moduleIds.contains(99));

  static const _hiddenAmountStatuses = {1, 2, 8};

  static bool canLookOrder({
    required CardTable table,
    required PermissionSnapshot? permissions,
    required String? employeeId,
    required Iterable<CardEmployee> employees,
  }) {
    if (permissions == null || !permissions.available) return false;
    final roles = permissions.roleIds;
    final modules = permissions.moduleIds;
    if (roles.contains(3) && modules.contains(12) && modules.contains(99)) {
      return false;
    }
    if (roles.contains(11)) return true;
    if (modules.contains(12)) return true;
    final loginId = employeeId ?? '';
    if (loginId.isEmpty) return false;
    if (table.salesEmployeeId == loginId) return true;
    if (table.waiterEmployeeIds.contains(loginId)) return true;
    CardEmployee? login;
    CardEmployee? sales;
    for (final employee in employees) {
      if (employee.id == loginId) login = employee;
      if (employee.id == table.salesEmployeeId) sales = employee;
    }
    final canLookDept = modules.contains(7) || modules.contains(11);
    if (canLookDept &&
        sales != null &&
        login != null &&
        sales.upperEmpId.isNotEmpty &&
        sales.upperEmpId == login.upperEmpId) {
      return true;
    }
    if (canLookDept && login != null && login.upperEmpId.isNotEmpty) {
      for (final waiterId in table.waiterEmployeeIds) {
        for (final employee in employees) {
          if (employee.id == waiterId &&
              employee.upperEmpId == login.upperEmpId) {
            return true;
          }
        }
      }
    }
    if (modules.contains(10)) return false;
    final subordinates = <String>{
      for (final employee in employees)
        if (employee.upperEmpId == loginId) employee.id,
    };
    if (subordinates.contains(table.salesEmployeeId)) return true;
    if (modules.contains(6)) return false;
    for (final waiterId in table.waiterEmployeeIds) {
      if (subordinates.contains(waiterId)) return true;
    }
    return false;
  }

  static bool showAmounts({
    required CardTable table,
    required bool wineMode,
    required bool safeModeEnabled,
    required bool canLook,
  }) =>
      !wineMode &&
      !safeModeEnabled &&
      canLook &&
      !_hiddenAmountStatuses.contains(table.businessStatus);

  static bool showGiftAmount({
    required bool showAmounts,
    required PermissionSnapshot? permissions,
  }) => showAmounts && (permissions?.roleIds.contains(3) ?? false);

  static bool showTurnover({
    required CardTable table,
    required PermissionSnapshot? permissions,
  }) {
    if (table.turnoverCount <= 0) return false;
    final roles = permissions?.roleIds ?? const <int>{};
    return roles.contains(2) || roles.contains(3);
  }

  static String yuan(num value) => value.toStringAsFixed(2);

  static String openTimeLabel(String openTime) {
    if (openTime.length < 12) return '';
    return '(${openTime.substring(8, 10)}:${openTime.substring(10, 12)})';
  }

  static String salesLabel({
    required CardTable table,
    required Iterable<CardEmployee> employees,
    required Iterable<CardDepartment> departments,
  }) {
    if (table.businessStatus == 1 || table.businessStatus == 2) return '';
    CardEmployee? sales;
    for (final employee in employees) {
      if (employee.id == table.salesEmployeeId) {
        sales = employee;
        break;
      }
    }
    if (sales == null) return '散客';
    var departmentName = '';
    for (final department in departments) {
      if (department.id == sales.deptId) {
        departmentName = department.name;
        break;
      }
    }
    return departmentName.isEmpty
        ? sales.name
        : '${sales.name} $departmentName';
  }

  static String lockTip(int businessStatus) =>
      businessStatus == 2 ? '锁' : '';
}
