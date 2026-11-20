import 'package:card_table/src/card_table_models.dart';

/// Display and search rules for the booking (预订系统) card face.
///
/// Source: src/views/Book/cardMachine.vue card template (lines 84-205),
/// keyword search (lines 1062-1089), and the diXiaoJindu calculation in getCardList.
abstract final class BookingCardDisplay {
  /// Open, ordering, partly paid and paid tables show 惠/主 amounts.
  static bool showsAmounts(int businessStatus) =>
      const <int>{4, 5, 6, 7}.contains(businessStatus);

  /// Empty and locked tables hide the sales person and guest rows.
  static bool showsGuest(int businessStatus) =>
      businessStatus != 1 && businessStatus != 2;

  /// Capacity is only meaningful on an empty table.
  static bool showsCapacity(int businessStatus) => businessStatus == 1;

  /// Status 6 (部分结账) shares the ordering count/color, differentiated by badge.
  static bool isPartialPaid(int businessStatus) => businessStatus == 6;

  static int capacity(CardTable table) =>
      table.capacity > 0 ? table.capacity : 1;

  /// 主: main-business amount still counting toward the minimum spend.
  static num mainAmount(CardTable table) =>
      ((table.mainOrderAmount * 100).round() -
          (table.paidMainFreeAmount * 100).round()) /
      100;

  /// Minimum-spend progress from 0 to 1, or null when no minimum is set.
  static double? minConsumeProgress(CardTable table) {
    final minimum = table.assignedMinConsumeAmount;
    if (minimum <= 0) return null;
    final ratio = mainAmount(table) / minimum;
    if (ratio.isNaN || ratio < 0) return 0;
    return ratio > 1 ? 1 : ratio.toDouble();
  }

  /// Same rounding as the Vue page: whole percent, capped at 100%.
  static String minConsumeLabel(CardTable table) {
    final progress = minConsumeProgress(table);
    if (progress == null) return '';
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  /// 138****5678. Short or malformed numbers are shown unchanged.
  static String maskPhone(String phone) {
    final value = phone.trim();
    if (value.length < 7) return value;
    return '${value.substring(0, 3)}****${value.substring(value.length - 4)}';
  }

  static String guestLabel(CardTable table) {
    final name = table.customerName.trim();
    final phone = maskPhone(table.effectiveBookingPhone);
    return [name, phone].where((part) => part.isNotEmpty).join(' ');
  }

  /// The Vue card shows the first six characters of the remark.
  static String shortRemark(String remark) {
    final value = remark.trim();
    final runes = value.runes.toList(growable: false);
    if (runes.length <= 6) return value;
    return '${String.fromCharCodes(runes.take(6))}…';
  }

  /// HH:mm from the yyyyMMddHHmmss open time.
  static String openTime(String raw) {
    if (raw.length < 12) return '';
    return '${raw.substring(8, 10)}:${raw.substring(10, 12)}';
  }

  /// Formats `exp_arrive_time` wire values (`2100`, `202608282100`, `2026-08-28 21:00`)
  /// into readable display text.
  static String formatArriveTime(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (RegExp(r'^\d{4}$').hasMatch(value)) {
      final hh = int.tryParse(value.substring(0, 2)) ?? 0;
      final prefix = hh < 12 ? '次日' : '';
      return '$prefix${value.substring(0, 2)}:${value.substring(2, 4)}';
    }
    if (RegExp(r'^\d{12,14}$').hasMatch(value)) {
      return '${value.substring(0, 4)}-${value.substring(4, 6)}-'
          '${value.substring(6, 8)} ${value.substring(8, 10)}:'
          '${value.substring(10, 12)}';
    }
    return value;
  }

  /// Normalizes transfer chain text (`A01-A03` or `A01->A03`) for card footer.
  static String formatTransferHistory(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    return value.replaceAll('->', '→');
  }

  /// Full Vue `cardMachine.vue:1062-1089` keyword search:
  /// matches table name, sales person (code / name / pinyin), sales department,
  /// customer name, customer name pinyin, and customer phone (any fragment).
  static bool matchesBookingSearch({
    required CardTable table,
    required String keyword,
    required bool showCustomerDetails,
    required List<CardEmployee> employees,
    required List<CardDepartment> departments,
  }) {
    final kw = keyword.trim().toLowerCase();
    if (kw.isEmpty) return true;
    if (table.name.toLowerCase().contains(kw)) return true;

    CardEmployee? sales;
    if (table.salesEmployeeId.isNotEmpty) {
      for (final emp in employees) {
        if (emp.id == table.salesEmployeeId) {
          sales = emp;
          break;
        }
      }
    }
    if (sales != null) {
      if (sales.code.toLowerCase().contains(kw) ||
          sales.name.toLowerCase().contains(kw) ||
          sales.namePy.toLowerCase().contains(kw)) {
        return true;
      }
      if (sales.deptId.isNotEmpty) {
        for (final dept in departments) {
          if (dept.id == sales.deptId &&
              dept.name.toLowerCase().contains(kw)) {
            return true;
          }
        }
      }
    }

    if (!showCustomerDetails) return false;
    if (table.customerName.toLowerCase().contains(kw)) return true;
    if (table.customerNamePy.toLowerCase().contains(kw)) return true;
    if (table.bookingCustomerPhone.toLowerCase().contains(kw)) return true;
    if (table.customerPhone.toLowerCase().contains(kw)) return true;
    return false;
  }
}
