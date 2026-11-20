import 'package:card_table/src/product_pricing.dart';
import 'package:card_table/src/sold_out_products.dart';
import 'package:flutter_test/flutter_test.dart';

SoldOutProduct product({
  int type = 1,
  String price = '100.00',
  List<String> tiers = const ['90', '80', '70', '60', '50', '40', '30'],
}) => SoldOutProduct(
  id: '1',
  name: '商品',
  namePy: '',
  nameEng: '',
  price: price,
  prdType: type,
  oneCateId: '1',
  twoCateId: '2',
  displayOrder: 0,
  limitPc: null,
  limitPad: null,
  mbPrice: tiers[0],
  bsPrice: tiers[1],
  bsMbPrice: tiers[2],
  bxPrice: tiers[3],
  bxMbPrice: tiers[4],
  bxBsPrice: tiers[5],
  bxBsMbPrice: tiers[6],
);
void main() {
  test('all eight combinations distinguish actual charge from member hint', () {
    // Fixed expectations derived from priceCalculator.js, not minimum-price sorting.
    const actual = ['100.00', '90', '60', '50', '80', '70', '40', '30'];
    const display = ['100.00', '90', '50', '50', '80', '70', '30', '30'];
    for (var mask = 0; mask < 8; mask++) {
      final quote = quoteProductPrice(
        product(),
        context: ProductPricingContext(
          isBusiness: mask & 4 != 0,
          isBox: mask & 2 != 0,
          isMember: mask & 1 != 0,
        ),
      );
      expect(quote.actualPrice, actual[mask], reason: 'mask $mask');
      expect(quote.actualDisplayPrice, actual[mask]);
      expect(quote.displayPrice, display[mask]);
      expect(quote.hasMemberPrice, isTrue);
    }
  });
  test('actual priority falls back one tier at a time; base original string survives', () {
    final tiers = ['90', '80', '70', '60', '50', '40', '30'];
    const context = ProductPricingContext(
      isBusiness: true,
      isBox: true,
      isMember: true,
    );
    for (final entry in [
      (6, '30'),
      (5, '40'),
      (2, '70'),
      (4, '50'),
      (0, '90'),
      (1, '80'),
      (3, '60'),
    ]) {
      expect(
        quoteProductPrice(product(tiers: tiers), context: context).actualPrice,
        entry.$2,
      );
      tiers[entry.$1] = '0';
    }
    expect(
      quoteProductPrice(product(tiers: tiers), context: context).actualPrice,
      '100.00',
    );
  });
  test(
    'missing display base does not erase a configured actual member tier',
    () {
      final quote = quoteProductPrice(
        product(tiers: ['0', '0', '0', '0', '0', '0', '30']),
        context: const ProductPricingContext(
          isBusiness: true,
          isBox: true,
          isMember: true,
        ),
      );
      expect(quote.actualPrice, '30');
      expect(quote.displayPrice, '100.00');
      expect(quote.hasMemberPrice, isFalse);
    },
  );
  test(
    'time price types are only 3 4 5 and absent tiers are not free FC prices',
    () {
      const context = ProductPricingContext(
        isBusiness: true,
        isBox: true,
        isMember: true,
      );
      for (final type in [3, 4, 5]) {
        final quote = quoteProductPrice(product(type: type), context: context);
        expect(quote.actualPrice, '0');
        expect(quote.actualDisplayPrice, '时价');
        expect(quote.originalPrice, '0');
        expect(quote.memberPrice, '');
        expect(quote.hasMemberPrice, isFalse);
      }
      for (final type in [8, 13, 14, 15]) {
        expect(
          quoteProductPrice(product(type: type), context: context).actualPrice,
          '30',
        );
      }
      expect(
        quoteProductPrice(
          product(tiers: ['', '0', '-1', 'bad', '0.00', '', '']),
          context: context,
        ).actualPrice,
        '100.00',
      );
    },
  );
  test('compact metadata preserves raw original and all seven tier fields', () {
    final row = <Object?>[
      1,
      '商品',
      1,
      0,
      '',
      '',
      1,
      2,
      '100.00',
      1,
      ...List<Object?>.filled(8, null),
      '90.00',
      80,
      70,
      60,
      50,
      40,
      30,
    ];
    SoldOutProduct parse(List<Object?> item) => SoldOutProductCatalog.fromWire(
      firstCategories: [
        [1, '大类', 1, 0],
      ],
      secondCategories: [
        [2, '小类', 1, 0, 1],
      ],
      products: [item],
      areaProducts: [
        [1, 1, 1],
      ],
      padDevice: true,
    ).products.single;
    final parsed = parse(row);
    expect(parsed.price, '100.00');
    expect(
      [
        parsed.mbPrice,
        parsed.bsPrice,
        parsed.bsMbPrice,
        parsed.bxPrice,
        parsed.bxMbPrice,
        parsed.bxBsPrice,
        parsed.bxBsMbPrice,
      ],
      ['90.00', '80', '70', '60', '50', '40', '30'],
    );
    expect(parse(row.take(10).toList()).mbPrice, '');
  });
}
