import 'package:card_table/src/order_meal.dart' show OrderPlacedItem;
import 'package:foundation/foundation.dart';

export 'package:card_table/src/order_meal.dart'
    show orderRefundAuthorizationRequiredCode;

const orderRefundUnknownProductTypeCode = 'order_refund.unknown_product_type';
const orderRefundDraftInvalidCode = 'order_refund.invalid_draft';

/// A draft of the original /wo/back operation, not /sel/pay_order_back.
/// Product type and operator identity must come from trusted current metadata;
/// neither pp==0 nor an order's at value identifies the product/operator type.
final class OrderRefundDraft {
  const OrderRefundDraft._({
    required this.order,
    required this.productType,
    required this.isCashier,
    required this.count,
    required this.amount,
    required this.reason,
  });

  factory OrderRefundDraft.fromOrder({
    required OrderPlacedItem order,
    required int? productType,
    required bool isCashier,
  }) {
    final needsAmount = const [3, 5, 8].contains(productType);
    return OrderRefundDraft._(
      order: order,
      productType: productType,
      isCashier: isCashier,
      count: productType == 4
          ? 1
          : order.online || isCashier || needsAmount
          ? order.count
          : 1,
      amount: needsAmount ? order.recordedAmount : '',
      reason: '',
    );
  }

  final OrderPlacedItem order;
  final int? productType;
  final bool isCashier;
  final int count;
  final String amount, reason;

  // transformCardData + priced product editor + voucher package selectors.
  bool get _knownType =>
      const [1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 14, 15, 22].contains(productType);
  bool get requiresAmount => const [3, 5, 8].contains(productType);
  int get initialCount => productType == 4
      ? 1
      : order.online || isCashier || requiresAmount
      ? order.count
      : 1;
  bool get quantityEditable =>
      _knownType &&
      !order.online &&
      productType != 4 &&
      (!requiresAmount || isCashier);
  bool get amountEditable =>
      _knownType &&
      requiresAmount &&
      isCashier &&
      quantityEditable &&
      count >= 1 &&
      count < order.count;
  String get backAmount => !requiresAmount
      ? ''
      : amountEditable
      ? amount.trim()
      : order.recordedAmount;

  OrderRefundDraft withCount(int value) => value == count
      ? this
      : _copy(
          count: value,
          amount: requiresAmount && isCashier
              ? value == order.count
                    ? order.recordedAmount
                    : ''
              : amount,
        );
  OrderRefundDraft withAmount(String value) => _copy(amount: value);
  OrderRefundDraft withReason(String value) => _copy(reason: value);
  OrderRefundDraft _copy({int? count, String? amount, String? reason}) =>
      OrderRefundDraft._(
        order: order,
        productType: productType,
        isCashier: isCashier,
        count: count ?? this.count,
        amount: amount ?? this.amount,
        reason: reason ?? this.reason,
      );

  AppFailure? validate() {
    if (!_knownType) {
      return const AppFailure(
        kind: FailureKind.business,
        code: orderRefundUnknownProductTypeCode,
        safeMessage: '商品类型未知，请刷新商品信息后再退单',
      );
    }
    if (order.id.isEmpty ||
        order.productId.isEmpty ||
        order.count <= 0 ||
        order.refunded ||
        order.paid ||
        order.status == 6 ||
        order.status == 7) {
      return _invalid('当前订单不可退单，请刷新后重试');
    }
    if (count < 1 ||
        count > order.count ||
        (!quantityEditable && count != initialCount)) {
      return _invalid('退单数量无效，线上订单和受限类型不可拆分');
    }
    if (reason.trim().isEmpty || reason.length > 80) {
      return _invalid('请选择有效退单理由');
    }
    if (!requiresAmount) {
      return amount.isEmpty ? null : _invalid('普通商品不应提交退单金额');
    }
    final original = double.tryParse(order.recordedAmount);
    final entered = double.tryParse(amount.trim());
    if (original == null || !original.isFinite || original < 0) {
      return _invalid('订单原金额无效，请刷新后重试');
    }
    if (entered == null ||
        !entered.isFinite ||
        entered < 0 ||
        entered > original ||
        amount.length > 32) {
      return _invalid('请输入不超过原订单金额的非负退款金额');
    }
    if (!amountEditable && entered != original) {
      return _invalid('当前退单只能使用原订单金额');
    }
    return null;
  }

  static AppFailure _invalid(String message) => AppFailure(
    kind: FailureKind.business,
    code: orderRefundDraftInvalidCode,
    safeMessage: message,
  );
  @override
  String toString() => 'OrderRefundDraft(orderId: ${order.id}, count: $count)';
}
