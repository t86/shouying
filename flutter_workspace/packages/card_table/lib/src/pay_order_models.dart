import 'dart:convert';

/// Historical pricing is solely the recorded order snapshot, never the live
/// product/member/employee price configuration. Amounts here are yuan.
final class RecordedOrderPrice {
  const RecordedOrderPrice({
    this.originalPrice,
    this.recordedPrice,
    this.recordedAmount,
    this.count,
    this.authorizationType = 0,
  });
  final double? originalPrice, recordedPrice, recordedAmount;
  final num? count;
  final int authorizationType;
  static double? number(Object? value) {
    if (value == null || value == '') return null;
    final number = double.tryParse('$value');
    return number?.isFinite == true ? number : null;
  }

  factory RecordedOrderPrice.fromWire(Map<String, Object?> wire) =>
      RecordedOrderPrice(
        originalPrice: number(wire['pp']),
        recordedPrice: number(wire['p2']),
        recordedAmount: number(wire['pa']),
        count:
            wire.containsKey('pc') && (wire['pc'] == null || wire['pc'] == '')
            ? 0
            : number(wire['pc']),
        authorizationType: int.tryParse('${wire['at']}') ?? 0,
      );
  bool get isTimePrice => originalPrice == 0;
  double? get unitPrice => isTimePrice ? null : recordedPrice ?? originalPrice;
  String get displayUnitPrice =>
      isTimePrice ? '时价' : unitPrice?.toStringAsFixed(2) ?? '--';
  double amountFor({num? changeCount, bool refund = false}) {
    if (!refund && (authorizationType == 2 || authorizationType == 3)) return 0;
    if (isTimePrice) return recordedAmount ?? 0;
    if (recordedAmount != null &&
        (changeCount == null || changeCount == count)) {
      return count == 0 ? 0 : recordedAmount!;
    }
    final price = unitPrice;
    if (price == null) return recordedAmount ?? 0;
    return price * (changeCount ?? count ?? 0);
  }
}

/// wo/list pay_info values are cents. Missing fields are zero, not line totals.
final class OrderSummary {
  const OrderSummary({
    this.allAmt = '0.00',
    this.giveAmt = '0.00',
    this.discountAmt = '0.00',
    this.notPayAmt = '0.00',
  });
  final String allAmt, giveAmt, discountAmt, notPayAmt;

  /// Current payment-tab rows, in yuan. Children are already represented by
  /// their parent; never add package details or expanded refund rows again.
  factory OrderSummary.fromRows(Iterable<PayOrderItem> rows) {
    var original = 0, actual = 0, gifts = 0, discount = 0;
    int cents(double amount) => (amount * 100 + .5).floor();
    for (final row in rows) {
      if (row.isRefunded || row.count <= 0) continue;
      final pp = RecordedOrderPrice.number(row.originalUnitPrice);
      final p2 = RecordedOrderPrice.number(row.recordedUnitPrice);
      final pa = RecordedOrderPrice.number(row.recordedAmount);
      final before = cents(pp != null && pp > 0 ? pp * row.count : pa ?? 0);
      if (row.authorizationType == 2 || row.authorizationType == 3) {
        gifts += before;
        continue;
      }
      final after = cents(pa ?? (p2 ?? pp ?? 0) * row.count);
      original += before;
      actual += after;
      if (before > after) discount += before - after;
    }
    String money(int value) => (value / 100).toStringAsFixed(2);
    return OrderSummary(
      allAmt: money(original),
      giveAmt: money(gifts),
      discountAmt: money(discount),
      notPayAmt: money(actual),
    );
  }
  factory OrderSummary.fromWire(Map<String, Object?> info) {
    double amount(String key) => RecordedOrderPrice.number(info[key]) ?? 0;
    return OrderSummary(
      allAmt: ((amount('discount_amt') + amount('order_amt')) / 100)
          .toStringAsFixed(2),
      giveAmt: (amount('yh_amt') / 100).toStringAsFixed(2),
      discountAmt: ((amount('discount_amt') + amount('payed_free_amt')) / 100)
          .toStringAsFixed(2),
      notPayAmt: ((amount('order_amt') - amount('payed_amt')) / 100)
          .toStringAsFixed(2),
    );
  }
}

final class PayOrderPackageDetail {
  const PayOrderPackageDetail({
    required this.id,
    required this.name,
    required this.count,
  });

  final String id;
  final String name;
  final num count;

  double get price => 0.0;
}

final class PayOrderItem {
  const PayOrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.count,
    required String unitPrice,
    required String amount,
    this.recordedUnitPrice,
    this.authorizationType = 0,
    this.orderedAt = '',
    this.status = 0,
    this.online = false,
    this.refunded = false,
    this.waiterName = '',
    this.autherName = '',
    this.packageDetails = const [],
    this.paidOrderId = '',
    this.locked = false,
    this.waiterEmployeeId = '',
    this.authorEmployeeId = '',
  }) : originalUnitPrice = unitPrice,
       recordedAmount = amount;

  final String id;
  final String productId;
  final String name;
  final int count;
  final String originalUnitPrice;
  final String recordedAmount;
  final String? recordedUnitPrice;
  final int authorizationType;
  RecordedOrderPrice get recordedPrice => RecordedOrderPrice(
    originalPrice: RecordedOrderPrice.number(originalUnitPrice),
    recordedPrice: RecordedOrderPrice.number(recordedUnitPrice),
    recordedAmount: RecordedOrderPrice.number(recordedAmount),
    count: count,
    authorizationType: authorizationType,
  );
  String get unitPrice => isTimePrice
      ? '时价'
      : RecordedOrderPrice.number(recordedUnitPrice) != null
      ? recordedUnitPrice!
      : originalUnitPrice;
  String get amount =>
      (authorizationType == 2 ||
          authorizationType == 3 ||
          (count == 0 && !isTimePrice))
      ? '0.0'
      : RecordedOrderPrice.number(recordedAmount) != null
      ? recordedAmount
      : subtotal.toString();
  bool get hasValidPaymentAmount =>
      (recordedAmount.isEmpty
          ? recordedPrice.unitPrice != null ||
                authorizationType == 2 ||
                authorizationType == 3
          : RecordedOrderPrice.number(recordedAmount) != null) &&
      subtotal.isFinite &&
      subtotal >= 0;
  bool get isTimePrice => recordedPrice.isTimePrice;
  bool get canSplit => !isTimePrice;
  String get displayUnitPrice => recordedPrice.displayUnitPrice;
  double amountForCount(num selectedCount) =>
      recordedPrice.amountFor(changeCount: selectedCount);
  double refundAmount({num? count}) =>
      recordedPrice.amountFor(changeCount: count, refund: true);
  final String orderedAt;
  final int status;
  final bool online;
  final bool refunded;
  final String waiterName;
  final String autherName;
  final List<PayOrderPackageDetail> packageDetails;

  /// Provenance from csm_orders.payed_order[].id, not pid (product id).
  final String paidOrderId;
  final bool locked;
  final String waiterEmployeeId, authorEmployeeId;

  bool get paid => paidOrderId.isNotEmpty || status == 5;
  bool get isRefunded => refunded || status == 6;
  bool get isRefunding => status == 7;
  bool get isOnline => online;
  int get discountType => authorizationType;
  bool get isLocked => locked;
  int get unpaidCount => count;
  bool get isPackage => packageDetails.isNotEmpty;
  String get productName => name;
  double get price => recordedPrice.unitPrice ?? 0.0;
  double get subtotal => recordedPrice.amountFor();
  String get orderTime => orderedAt;
  int get intId => int.tryParse(id) ?? 0;
}

final class PayedChannelItem {
  const PayedChannelItem({
    required this.channelName,
    required this.amount,
    this.channelId = '',
    this.cardNo,
    this.cardStoredAmt = 0.0,
    this.cardDiscountAmt = 0.0,
    this.payTime = '',
    this.cashierName = '',
  });

  final String channelName;
  final String channelId;
  final double amount;
  final String? cardNo;
  final double cardStoredAmt;
  final double cardDiscountAmt;
  final String payTime;
  final String cashierName;
}

final class PayedOrderRecord {
  const PayedOrderRecord({
    required this.id,
    this.items = const [],
    this.originalAmt = '',
    this.paidAmt = '',
    this.mainReceivedAmt = '',
    this.channels = const [],
    this.transferAmount = '',
  });

  final String id;
  final List<PayOrderItem> items;
  final String originalAmt;
  final String paidAmt;
  final String mainReceivedAmt;
  final List<PayedChannelItem> channels;

  /// Original amts.p used by move_payed_wk_order, NOT pv/pzv or row totals.
  final String transferAmount;
  int? get transferAmountFen {
    final amount = RecordedOrderPrice.number(transferAmount);
    if (amount == null || (amount * 100).abs() > 9007199254740991) return null;
    return (amount * 100 + .5)
        .floor(); // JavaScript Math.round, including negative ties.
  }

  String get transferFingerprint => jsonEncode([
    id,
    transferAmount,
    originalAmt,
    paidAmt,
    mainReceivedAmt,
    for (final item in items)
      [
        item.id,
        item.productId,
        item.count,
        item.originalUnitPrice,
        item.recordedUnitPrice,
        item.recordedAmount,
        item.authorizationType,
        item.isLocked,
        item.online,
        item.refunded,
        for (final detail in item.packageDetails) [detail.id, detail.count],
      ],
    for (final channel in channels)
      [
        channel.channelId,
        channel.amount,
        channel.cardNo,
        channel.cardStoredAmt,
        channel.cardDiscountAmt,
        channel.payTime,
      ],
  ]);

  int get pid => int.tryParse(id) ?? 0;
}

final class PayCartItem {
  const PayCartItem({
    required this.id,
    required this.channelId,
    required this.amount,
    this.channelName = '',
  });

  final String id;
  final String channelId;
  final String amount;
  final String channelName;
}

final class PayOrderData {
  const PayOrderData({
    required this.seatId,
    this.turnoverCount = 0,
    this.settleMode = 1,
    this.customerName = '',
    this.customerPhone = '',
    this.waiterEmpId = '',
    this.unpayItems = const [],
    this.payedOrders = const [],
    this.summary,
  });

  final String seatId;
  final int turnoverCount;
  final int settleMode;
  final String customerName;
  final String customerPhone;
  final String waiterEmpId;
  final List<PayOrderItem> unpayItems;
  final List<PayedOrderRecord> payedOrders;
  final OrderSummary? summary;

  double get unpayAmt =>
      unpayItems
          .where((item) => !item.isRefunded && item.count != 0)
          .fold<int>(
            0,
            (sum, item) => sum + (item.subtotal * 100 + .5).floor(),
          ) /
      100;
  String get unpayAmtText => unpayAmt.toStringAsFixed(2);
}
