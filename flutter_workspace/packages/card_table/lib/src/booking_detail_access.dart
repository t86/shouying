/// Terminal-rule access control for Booking consumption & wine detail options.
///
/// Exact Dart port of `src/utils/bookingDetailAccess.js` in the Vue source.
final class BookingDetailConfig {
  const BookingDetailConfig({
    this.amountsRestricted = true,
    this.consumptionEnabled = false,
    this.wineEnabled = false,
  });

  /// Fail-closed default matching `normalizeBookingDetailConfig()` in Vue.
  static const BookingDetailConfig restricted = BookingDetailConfig();

  /// Permissive config used only when no terminal-rule loader is wired in tests.
  static const BookingDetailConfig unrestrictedAll = BookingDetailConfig(
    amountsRestricted: false,
    consumptionEnabled: true,
    wineEnabled: true,
  );

  factory BookingDetailConfig.fromWire(Map<Object?, Object?>? data) {
    if (data == null) return BookingDetailConfig.restricted;
    final unrestricted = _isExact(data['limit_book_csm_amt'], 2);
    return BookingDetailConfig(
      amountsRestricted: !unrestricted,
      consumptionEnabled:
          unrestricted && _isExact(data['enable_book_csm_dtl'], 1),
      wineEnabled: unrestricted && _isExact(data['enable_book_wine_dtl'], 1),
    );
  }

  final bool amountsRestricted;
  final bool consumptionEnabled;
  final bool wineEnabled;

  static bool _isExact(Object? value, int expected) =>
      value == expected || value == '$expected';

  @override
  bool operator ==(Object other) =>
      other is BookingDetailConfig &&
      other.amountsRestricted == amountsRestricted &&
      other.consumptionEnabled == consumptionEnabled &&
      other.wineEnabled == wineEnabled;

  @override
  int get hashCode =>
      Object.hash(amountsRestricted, consumptionEnabled, wineEnabled);
}

final class BookingTurnoverTab {
  const BookingTurnoverTab({required this.turnoverCount, required this.label});

  final int turnoverCount;
  final String label;
}

abstract final class BookingDetailAccess {
  static const int consumptionOptionId = 26;
  static const int wineOptionId = 27;

  static bool isStatusVisible(int status, int turnoverCount) {
    if (status == 1 || status == 3 || status == 8) {
      return turnoverCount > 0;
    }
    return status == 4 || status == 5 || status == 6 || status == 7;
  }

  static int turnoverCountForRequest(int status, int turnoverCount) {
    final normalized = turnoverCount > 0 ? turnoverCount : 0;
    final currentTurnoverIsNotOpen =
        status == 1 || status == 3 || status == 7 || status == 8;
    if (!currentTurnoverIsNotOpen) return normalized;
    return normalized > 0 ? normalized - 1 : 0;
  }

  /// Port of `getBookingDetailOptionIds(config, status, turnoverCnt)`.
  static List<int> optionIds(
    BookingDetailConfig config, {
    required int status,
    required int turnoverCount,
  }) {
    if (config.amountsRestricted || !isStatusVisible(status, turnoverCount)) {
      return const <int>[];
    }
    return <int>[
      if (config.consumptionEnabled) consumptionOptionId,
      if (config.wineEnabled) wineOptionId,
    ];
  }

  static List<BookingTurnoverTab> buildTurnoverTabs(
    String tableNo,
    int turnoverCount, {
    int? status,
  }) {
    final latest = turnoverCount > 0 ? turnoverCount : 0;
    final currentTurnoverIsOpen = status == 4 || status == 5 || status == 6;
    final tabCount = latest + (currentTurnoverIsOpen ? 1 : 0);
    final firstRequestCount = status == null
        ? latest
        : turnoverCountForRequest(status, latest);
    final counts = tabCount > 0
        ? <int>[for (var i = 0; i < tabCount; i++) firstRequestCount - i]
        : const <int>[0];
    return <BookingTurnoverTab>[
      for (var i = 0; i < counts.length; i++)
        BookingTurnoverTab(
          turnoverCount: counts[i],
          label:
              '$tableNo-${(tabCount > 0 ? tabCount - i : 1).toString().padLeft(3, '0')}',
        ),
    ];
  }
}
