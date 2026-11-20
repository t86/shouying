import 'package:card_table/src/sold_out_products.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'isGQ catalog keeps all-region valid products and hides empty categories',
    () {
      final catalog = SoldOutProductCatalog.fromWire(
        firstCategories: [
          ['1', '酒水', '1', 2],
          ['2', '隐藏一级', '1', 1],
          ['3', '无效一级', '2', 1],
        ],
        secondCategories: [
          ['11', '鸡尾酒', '1', 5, '1'],
          ['12', '空分类', '1', 1, '2'],
          ['13', '无效二级', '2', 1, '1'],
        ],
        products: [
          [
            '101',
            '莫吉托',
            '1',
            3,
            'mjt',
            'Mojito',
            '1',
            '11',
            '38',
            1,
            1,
            0,
            1,
            '',
            '2',
            '2',
          ],
          [
            '102',
            '无效商品',
            '2',
            1,
            'wx',
            '',
            '1',
            '11',
            '1',
            1,
            1,
            0,
            1,
            '',
            '2',
            '2',
          ],
          [
            '103',
            '无区域商品',
            '1',
            1,
            'qy',
            '',
            '1',
            '11',
            '1',
            1,
            1,
            0,
            1,
            '',
            '2',
            '2',
          ],
        ],
        areaProducts: [
          ['r1', '1', '101'],
          ['r2', '1', '101'],
          ['r1', '3', '103'],
        ],
        padDevice: true,
      );

      expect(catalog.products.map((item) => item.id), ['101']);
      expect(catalog.products.single.name, '莫吉托');
      expect(catalog.products.single.namePy, 'mjt');
      expect(catalog.products.single.nameEng, 'Mojito');
      expect(catalog.products.single.price, '38');
      expect(catalog.firstCategories.map((item) => item.id), ['1']);
      expect(catalog.secondCategories.map((item) => item.id), ['11']);
      expect(
        catalog.productsIn(firstId: '1', secondId: '11').single.name,
        '莫吉托',
      );
    },
  );

  test('isGQ catalog does not apply second-category time windows', () {
    final catalog = SoldOutProductCatalog.fromWire(
      firstCategories: [
        ['1', '酒水', '1', 1],
      ],
      secondCategories: [
        ['11', '鸡尾酒', '1', 1, '1', 1, '00:00', '00:01', '00:00', '00:01'],
      ],
      products: [
        [
          '101',
          '莫吉托',
          '1',
          1,
          'mjt',
          '',
          '1',
          '11',
          '10',
          1,
          1,
          0,
          1,
          '',
          '2',
          '2',
        ],
      ],
      areaProducts: [
        ['r1', '1', '101'],
      ],
      padDevice: true,
    );
    expect(catalog.products, hasLength(1));
  });

  test('pad catalog hides only limit_pad string 1', () {
    final catalog = SoldOutProductCatalog.fromWire(
      firstCategories: [
        ['1', '酒水', '1', 1],
      ],
      secondCategories: [
        ['11', '鸡尾酒', '1', 1, '1'],
      ],
      products: [
        _product('101', '可见', limitPc: '1', limitPad: '2'),
        _product('102', '隐藏', limitPc: '2', limitPad: '1'),
        _product('103', '数字1仍可见', limitPc: '2', limitPad: 1),
      ],
      areaProducts: [
        ['r1', '1', '101'],
        ['r1', '1', '102'],
        ['r1', '1', '103'],
      ],
      padDevice: true,
    );
    expect(catalog.products.map((item) => item.name).toList(), [
      '可见',
      '隐藏',
      '数字1仍可见',
    ]);
    expect(
      catalog
          .productsIn(firstId: '1', secondId: '11')
          .map((item) => item.name)
          .toList(),
      ['可见', '数字1仍可见'],
    );
  });

  test(
    'empty keyword stays in the current category, typed keyword searches all',
    () {
      final catalog = SoldOutProductCatalog.fromWire(
        firstCategories: [
          ['1', '酒水', '1', 1],
          ['2', '小吃', '1', 2],
        ],
        secondCategories: [
          ['11', '鸡尾酒', '1', 1, '1'],
          ['21', '小食', '1', 1, '2'],
        ],
        products: [
          _product('101', '莫吉托', namePy: 'mjt', two: '11', one: '1', dsp: 2),
          _product('201', '薯条', namePy: 'st', two: '21', one: '2', dsp: 1),
        ],
        areaProducts: [
          ['r1', '1', '101'],
          ['r1', '1', '201'],
        ],
        padDevice: true,
      );
      expect(
        catalog
            .search(keyword: '', firstId: '1', secondId: '11')
            .map((item) => item.name),
        ['莫吉托'],
      );
      expect(
        catalog
            .search(keyword: '薯', firstId: '1', secondId: '11')
            .map((item) => item.name),
        ['薯条'],
      );
      expect(
        catalog
            .search(keyword: 'mjt', firstId: '2', secondId: '21')
            .map((item) => item.name),
        ['莫吉托'],
      );
    },
  );

  test('price label uses 时价 for types 3/4/5', () {
    SoldOutProductCatalog catalogFor(Object type, Object price) =>
        SoldOutProductCatalog.fromWire(
          firstCategories: [
            ['1', '酒水', '1', 1],
          ],
          secondCategories: [
            ['11', '鸡尾酒', '1', 1, '1'],
          ],
          products: [_product('101', '莫吉托', prdType: type, price: price)],
          areaProducts: [
            ['r1', '1', '101'],
          ],
          padDevice: true,
        );
    expect(catalogFor(3, '10').products.single.priceLabel, '时价');
    expect(catalogFor(4, '10').products.single.priceLabel, '时价');
    expect(catalogFor(5, '10').products.single.priceLabel, '时价');
    expect(catalogFor(1, '12').products.single.priceLabel, '￥12');
  });

  test('region catalog keeps only products listed for that region', () {
    final catalog = SoldOutProductCatalog.forRegion(
      regionId: 'r1',
      firstCategories: [
        ['1', '酒水', '1', 1],
      ],
      secondCategories: [
        ['11', '鸡尾酒', '1', 1, '1'],
      ],
      products: [
        _product('101', '莫吉托', namePy: 'mjt', price: '38'),
        _product('102', '其他区酒', namePy: 'qt'),
      ],
      areaProducts: [
        ['r1', '1', '101'],
        ['r2', '1', '102'],
      ],
      padDevice: true,
    );
    expect(catalog.products.map((item) => item.id), ['101']);
    expect(catalog.firstCategories.single.name, '酒水');
  });
}

List<Object?> _product(
  String id,
  String name, {
  String namePy = '',
  String one = '1',
  String two = '11',
  Object price = '10',
  Object prdType = 1,
  int dsp = 1,
  Object limitPc = '2',
  Object limitPad = '2',
}) => [
  id,
  name,
  '1',
  dsp,
  namePy,
  '',
  one,
  two,
  price,
  prdType,
  1,
  0,
  1,
  '',
  limitPc,
  limitPad,
];
