import 'package:card_table/src/pay_order_models.dart';
import 'package:foundation/foundation.dart';

const paidOrderRefundInvalidCode = 'paid_order_refund.invalid_draft';
const _knownProductTypes = {1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 14, 15, 22};

/// One refundable order line in a specific settled payment, never a product id
/// or an online payment-group id. Values are yuan strings, not fen.
final class PaidOrderRefundLine {
  const PaidOrderRefundLine._({
    required this.item,
    required this.productType,
    required this.count,
    required this.amount,
    required this.selected,
  });
  final PayOrderItem item;
  final int? productType;
  final int count;
  final String amount;
  final bool selected;
  String get id => item.id;
  bool get requiresAmount => const [3, 5, 8].contains(productType);
  bool get quantityEditable =>
      _knownProductTypes.contains(productType) &&
      !item.isRefunded &&
      item.count > 0;
  bool get amountEditable => requiresAmount && count > 0 && count < item.count;
  String get backAmount {
    if (!_knownProductTypes.contains(productType)) return '';
    if (requiresAmount) {
      return count == item.count ? item.recordedAmount : amount.trim();
    }
    final value = item.refundAmount(count: count);
    return value == 0
        ? '0'
        : value.toString().replaceFirst(RegExp(r'\.0$'), '');
  }

  PaidOrderRefundLine _copy({int? count, String? amount, bool? selected}) =>
      PaidOrderRefundLine._(
        item: item,
        productType: productType,
        count: count ?? this.count,
        amount: amount ?? this.amount,
        selected: selected ?? this.selected,
      );
}

/// Settled refunds have a different contract from OrderRefundDraft: all source
/// line types (including online/tips) allow 1..pc, and selection is multi-row.
final class PaidOrderRefundDraft {
  PaidOrderRefundDraft._({
    required this.record,
    required this.seatId,
    required this.turnoverCount,
    required this.isOldOrder,
    required List<PaidOrderRefundLine> lines,
    required this.reason,
    required this._productTypeFor,
  }) : lines = List.unmodifiable(lines);
  factory PaidOrderRefundDraft.fromRecord({
    required PayedOrderRecord record,
    required String seatId,
    required int turnoverCount,
    required bool isOldOrder,
    required int? Function(String) productTypeFor,
  }) => PaidOrderRefundDraft._(
    record: record,
    seatId: seatId,
    turnoverCount: turnoverCount,
    isOldOrder: isOldOrder,
    reason: '',
    productTypeFor: productTypeFor,
    lines: [
      for (final item in record.items)
        if (!item.isRefunded && item.count > 0)
          PaidOrderRefundLine._(
            item: item,
            productType: _type(productTypeFor, item.productId),
            count: item.count,
            amount: item.recordedAmount,
            selected: true,
          ),
    ],
  );
  final PayedOrderRecord record;
  final String seatId;
  final int turnoverCount;
  final bool isOldOrder;
  final String reason;
  final List<PaidOrderRefundLine> lines;
  final int? Function(String) _productTypeFor;
  String get payId => record.id;
  List<PaidOrderRefundLine> get selectedLines =>
      List.unmodifiable(lines.where((line) => line.selected));
  List<String> get orderIds => [for (final line in selectedLines) line.id];
  List<int> get counts => [for (final line in selectedLines) line.count];
  List<String> get amounts => [
    for (final line in selectedLines) line.backAmount,
  ];
  PaidOrderRefundDraft withReason(String value) => _copy(reason: value);
  PaidOrderRefundDraft withSelected(String id, bool selected) =>
      _change(id, (line) => line._copy(selected: selected));
  PaidOrderRefundDraft selectAll(bool selected) =>
      _copy(lines: [for (final line in lines) line._copy(selected: selected)]);
  PaidOrderRefundDraft withCount(String id, int count) => _change(
    id,
    (line) => line.count == count
        ? line
        : line._copy(
            count: count,
            amount: line.requiresAmount
                ? (count == line.item.count ? line.item.recordedAmount : '')
                : line.amount,
          ),
  );
  PaidOrderRefundDraft withAmount(String id, String amount) =>
      _change(id, (line) => line._copy(amount: amount));
  PaidOrderRefundDraft _change(
    String id,
    PaidOrderRefundLine Function(PaidOrderRefundLine) change,
  ) => _copy(
    lines: [for (final line in lines) line.id == id ? change(line) : line],
  );
  PaidOrderRefundDraft _copy({
    List<PaidOrderRefundLine>? lines,
    String? reason,
  }) => PaidOrderRefundDraft._(
    record: record,
    seatId: seatId,
    turnoverCount: turnoverCount,
    isOldOrder: isOldOrder,
    lines: lines ?? this.lines,
    reason: reason ?? this.reason,
    productTypeFor: _productTypeFor,
  );

  AppFailure? validate() {
    if (_id(seatId) == null ||
        _id(payId) == null ||
        turnoverCount < 0 ||
        isOldOrder) {
      return _invalid('只能退当前卡台、当前翻台的指定已结账单');
    }
    final sourceIds = lines.map((line) => _id(line.id)).toList();
    if (sourceIds.any((id) => id == null) ||
        sourceIds.toSet().length != sourceIds.length) {
      return _invalid('付款单的订单标识无效或重复，请重新加载');
    }
    if (selectedLines.isEmpty) return _invalid('请选择要退单的商品');
    if (reason.trim().isEmpty || reason.length > 160) {
      return _invalid('请选择有效退单理由');
    }
    for (final line in selectedLines) {
      if (_id(line.item.productId) == null ||
          !_knownProductTypes.contains(line.productType) ||
          _type(_productTypeFor, line.item.productId) != line.productType) {
        return _invalid('商品类型未知或已变化，请重新打开');
      }
      if (line.item.isRefunded ||
          line.item.isRefunding ||
          line.count < 1 ||
          line.count > line.item.count ||
          line.count > 9007199254740991) {
        return _invalid('退单数量或订单状态已无效');
      }
      if (line.item.paidOrderId.isNotEmpty &&
          _id(line.item.paidOrderId) != _id(payId)) {
        return _invalid('订单不属于当前付款单');
      }
      final original = RecordedOrderPrice.number(line.item.recordedAmount);
      if (line.requiresAmount) {
        // Input safety improvement over the legacy paid drawer: manual
        // amounts cannot exceed the recorded pa; the wire contract is unchanged.
        final input = double.tryParse(line.amount.trim());
        if (original == null ||
            original < 0 ||
            input == null ||
            !input.isFinite ||
            input < 0 ||
            input > original) {
          return _invalid('退款金额须为0至原订单金额之间的数值');
        }
        if (!line.amountEditable && input != original) {
          return _invalid('整行退单须保留原订单金额');
        }
      } else if ((line.item.recordedAmount.isNotEmpty && original == null) ||
          (original == null && line.item.recordedPrice.unitPrice == null)) {
        return _invalid('历史成交金额缺失，不能推算退款');
      }
      final amount = double.tryParse(line.backAmount);
      if (amount == null ||
          !amount.isFinite ||
          amount < 0 ||
          line.backAmount.length > 64) {
        return _invalid('退款金额无效');
      }
    }
    return null;
  }

  static int? _id(String text) {
    final id = int.tryParse(text);
    return id != null && id > 0 && id <= 9007199254740991 ? id : null;
  }

  static int? _type(int? Function(String) lookup, String id) {
    try {
      return lookup(id);
    } on Object {
      return null;
    }
  }

  static AppFailure _invalid(String text) => AppFailure(
    kind: FailureKind.business,
    code: paidOrderRefundInvalidCode,
    safeMessage: text,
  );
}
