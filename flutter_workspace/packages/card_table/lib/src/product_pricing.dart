import 'package:card_table/src/sold_out_products.dart';

/// Caller resolves membership from dataset14's phone, business eligibility from
/// active dataset57 employees, and box eligibility from seatType == 4.
final class ProductPricingContext {
  const ProductPricingContext({
    required this.isBusiness,
    required this.isBox,
    required this.isMember,
  });
  final bool isBusiness, isBox, isMember;
}

final class ProductPriceQuote {
  const ProductPriceQuote({
    required this.actualPrice,
    required this.actualDisplayPrice,
    required this.originalPrice,
    required this.memberPrice,
    required this.hasMemberPrice,
    required this.displayPrice,
    required this.baseOriginalPrice,
  });

  /// Actual legacy charge before any higher-priority FC override. Never derive
  /// a charge from displayPrice/memberPrice: those may be unearned member hints.
  final String actualPrice, actualDisplayPrice;

  /// Mirrors getProductPriceInfo, whose original price may be a contextual tier.
  final String originalPrice, memberPrice, displayPrice;

  /// Raw dataset4 base price used by fcProductOriginalPrice, not a tier price.
  final String baseOriginalPrice;
  final bool hasMemberPrice;
}

/// Preserves priceCalculator.js branch ordering, including display/charge
/// differences. FC configuration is intentionally outside this calculation.
ProductPriceQuote quoteProductPrice(
  SoldOutProduct? product, {
  required ProductPricingContext context,
}) {
  if (product == null) {
    return const ProductPriceQuote(
      actualPrice: '0',
      actualDisplayPrice: '0',
      originalPrice: '0',
      memberPrice: '',
      hasMemberPrice: false,
      displayPrice: '0',
      baseOriginalPrice: '0',
    );
  }
  if (const {3, 4, 5}.contains(product.prdType)) {
    return ProductPriceQuote(
      actualPrice: '0',
      actualDisplayPrice: '时价',
      originalPrice: '0',
      memberPrice: '',
      hasMemberPrice: false,
      displayPrice: '时价',
      baseOriginalPrice: product.price.isEmpty ? '0' : product.price,
    );
  }
  final original = product.price.isEmpty ? '0' : product.price;
  // Tier zero means unconfigured, unlike an explicit FC price of zero.
  String? tier(String raw) {
    final value = double.tryParse(raw);
    if (value == null || !value.isFinite || value <= 0) return null;
    return value == value.truncateToDouble()
        ? value.toStringAsFixed(0)
        : value.toString();
  }

  final mb = tier(product.mbPrice),
      bs = tier(product.bsPrice),
      bsm = tier(product.bsMbPrice),
      bx = tier(product.bxPrice),
      bxm = tier(product.bxMbPrice),
      bxbs = tier(product.bxBsPrice),
      bxbsm = tier(product.bxBsMbPrice);
  final b = context.isBusiness, x = context.isBox, m = context.isMember;
  final actual =
      (b && x && m ? bxbsm : null) ??
      (b && x ? bxbs : null) ??
      (b && m ? bsm : null) ??
      (x && m ? bxm : null) ??
      (m ? mb : null) ??
      (b ? bs : null) ??
      (x ? bx : null) ??
      original;
  ProductPriceQuote result(String base, String? member, String display) =>
      ProductPriceQuote(
        actualPrice: actual,
        actualDisplayPrice: actual,
        originalPrice: base,
        memberPrice: member ?? '',
        hasMemberPrice: member != null,
        displayPrice: display,
        baseOriginalPrice: original,
      );
  // The source displays the pair even for a nonmember business-box table.
  if (b && x && bxbs != null) return result(bxbs, bxbsm, bxbsm ?? bxbs);
  if (b && m && bs != null) return result(bs, bsm, bsm ?? bs);
  if (x && m && bx != null) return result(bx, bxm, bxm ?? bx);
  if (m) {
    return result(original, tier(original) != null ? mb : null, mb ?? original);
  }
  if (b && bs != null) return result(bs, bsm, bs);
  if (x && bx != null) return result(bx, bxm, bxm ?? bx);
  return result(original, tier(original) != null ? mb : null, original);
}
