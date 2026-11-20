import 'package:card_table/src/sold_out_products.dart';
import 'package:card_table/src/sold_out_products_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('a permission pulse cannot revive an old quantity confirmation', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    var writes = 0;
    await _pump(
      tester,
      canRead: canRead,
      list: () async => const Success([]),
      set:
          ({
            required String productId,
            required int count,
            bool Function()? canDispatch,
          }) async {
            writes++;
            return const Success(null);
          },
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('薯条').first);
    await tester.pumpAndSettle();
    canRead.value = false;
    canRead.value = true;
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(writes, 0);
  });

  testWidgets('shows source search, catalog, list, and no pending marker', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    var lists = 0;
    await _pump(
      tester,
      canRead: canRead,
      list: () async {
        lists++;
        return Success([
          SoldOutItem.fromWire({
            'id': '101',
            'n': '莫吉托',
            'c': 3,
            'require': '少冰',
          }),
        ]);
      },
    );
    await tester.pumpAndSettle();

    expect(lists, 1);
    expect(find.text('估清商品'), findsWidgets);
    expect(find.text('请输入商品名称或简写'), findsOneWidget);
    expect(find.text('商品名称'), findsOneWidget);
    expect(find.text('剩余估清数量'), findsOneWidget);
    expect(find.text('操作'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    expect(find.text('酒水'), findsOneWidget);
    expect(find.text('鸡尾酒'), findsOneWidget);
    expect(find.text('莫吉托'), findsWidgets);
    expect(find.text('余:3'), findsOneWidget);
    expect(find.text('￥38'), findsOneWidget);
    expect(find.text('少冰'), findsOneWidget);
    expect(find.textContaining('待接入'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete and quantity set use the source actions', (tester) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final deleted = <String>[];
    final sets = <List<Object>>[];
    await _pump(
      tester,
      canRead: canRead,
      list: () async => Success([
        SoldOutItem.fromWire({'id': '101', 'n': '莫吉托', 'c': 3}),
      ]),
      set:
          ({
            required String productId,
            required int count,
            bool Function()? canDispatch,
          }) async {
            sets.add([productId, count]);
            return const Success(null);
          },
      delete: (id, {bool Function()? canDispatch}) async {
        deleted.add(id);
        return const Success(null);
      },
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(deleted, ['101']);

    await tester.tap(find.text('薯条').first);
    await tester.pumpAndSettle();
    expect(find.text('估清数量'), findsOneWidget);
    expect(find.text('解除沽清'), findsOneWidget);
    await tester.enterText(find.byKey(SoldOutProductsScreen.countKey), '2');
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(sets, [
      ['201', 2],
    ]);
  });

  testWidgets(
    'phone layout keeps every first category reachable like the web nav',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final canRead = ValueNotifier(true);
      addTearDown(canRead.dispose);
      await _pump(
        tester,
        canRead: canRead,
        catalog: _webNavCatalog(),
        list: () async => const Success([]),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(SoldOutProductsScreen.firstCategoryListKey),
        findsOneWidget,
      );
      expect(
        find.byKey(SoldOutProductsScreen.secondCategoryListKey),
        findsOneWidget,
      );
      expect(
        tester
            .widget<ListView>(
              find.byKey(SoldOutProductsScreen.firstCategoryListKey),
            )
            .scrollDirection,
        Axis.vertical,
      );
      expect(
        tester
            .widget<ListView>(
              find.byKey(SoldOutProductsScreen.secondCategoryListKey),
            )
            .scrollDirection,
        Axis.vertical,
      );
      expect(
        tester
            .getSize(find.byKey(SoldOutProductsScreen.firstCategoryListKey))
            .height,
        greaterThan(200),
      );
      final firstScrollable = find.descendant(
        of: find.byKey(SoldOutProductsScreen.firstCategoryListKey),
        matching: find.byType(Scrollable),
      );
      for (final name in [
        '洋酒',
        '啤酒',
        '香槟',
        '软饮',
        '小吃类',
        '小费类',
        '套餐组1',
        '抖音套餐',
        '预售',
        '特饮',
        '早晚场套餐',
      ]) {
        await tester.scrollUntilVisible(
          find.text(name),
          48,
          scrollable: firstScrollable,
        );
        expect(find.text(name).hitTestable(), findsOneWidget);
      }

      await tester.scrollUntilVisible(
        find.text('香槟'),
        -48,
        scrollable: firstScrollable,
      );
      await tester.tap(find.text('香槟'));
      await tester.pumpAndSettle();
      expect(find.text('香槟类'), findsOneWidget);
      expect(find.text('黑桃A紫罗兰(750ML)'), findsOneWidget);
      expect(find.text('鸡米花'), findsNothing);
    },
  );

  testWidgets('losing read access removes loaded rows', (tester) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    await _pump(
      tester,
      canRead: canRead,
      list: () async => Success([
        SoldOutItem.fromWire({'id': '101', 'n': '莫吉托', 'c': 3}),
      ]),
    );
    await tester.pumpAndSettle();
    canRead.value = false;
    await tester.pump();
    expect(find.text('莫吉托'), findsNothing);
    expect(find.text('当前不可维护估清商品'), findsOneWidget);
  });
}

SoldOutProductCatalog _webNavCatalog() {
  const first = [
    ['1', '洋酒', '1', 1],
    ['2', '啤酒', '1', 2],
    ['3', '香槟', '1', 3],
    ['4', '软饮', '1', 4],
    ['5', '小吃类', '1', 5],
    ['6', '小费类', '1', 6],
    ['7', '套餐组1', '1', 7],
    ['8', '抖音套餐', '1', 8],
    ['9', '预售', '1', 9],
    ['10', '特饮', '1', 10],
    ['11', '早晚场套餐', '1', 11],
  ];
  final second = [
    for (final row in first) ['${row[0]}1', '${row[1]}类', '1', 1, row[0]],
  ];
  second[2][1] = '香槟类';
  second[4][1] = '小吃';
  final products = [
    _productRow(
      '101',
      '莫吉托',
      one: '1',
      two: '11',
      price: '38',
      py: 'mjt',
      eng: 'Mojito',
    ),
    _productRow('201', '薯条', one: '1', two: '11', price: '12', py: 'st'),
    _productRow('301', '黑桃A紫罗兰(750ML)', one: '3', two: '31', price: '1000.00'),
    _productRow('501', '鸡米花', one: '5', two: '51', price: '18.00'),
    for (final row in first)
      _productRow(
        '9${row[0]}',
        '${row[1]}商品',
        one: '${row[0]}',
        two: '${row[0]}1',
        price: '1',
      ),
  ];
  return SoldOutProductCatalog.fromWire(
    firstCategories: first,
    secondCategories: second,
    products: products,
    areaProducts: [
      for (final product in products) ['r1', '1', product[0]],
    ],
    padDevice: true,
  );
}

List<Object?> _productRow(
  String id,
  String name, {
  required String one,
  required String two,
  required Object price,
  String py = '',
  String eng = '',
}) => [id, name, '1', 1, py, eng, one, two, price, 1, 1, 0, 1, '', '2', '2'];

Future<void> _pump(
  WidgetTester tester, {
  required ValueNotifier<bool> canRead,
  required Future<Result<List<SoldOutItem>>> Function() list,
  SoldOutProductCatalog? catalog,
  Future<Result<void>> Function({
    required String productId,
    required int count,
    bool Function()? canDispatch,
  })?
  set,
  Future<Result<void>> Function(
    String productId, {
    bool Function()? canDispatch,
  })?
  delete,
}) => tester.pumpWidget(
  MaterialApp(
    home: SoldOutProductsScreen(
      catalog:
          catalog ??
          SoldOutProductCatalog.fromWire(
            firstCategories: [
              ['1', '酒水', '1', 1],
            ],
            secondCategories: [
              ['11', '鸡尾酒', '1', 1, '1'],
              ['21', '小食', '1', 2, '1'],
            ],
            products: [
              _productRow(
                '101',
                '莫吉托',
                one: '1',
                two: '11',
                price: '38',
                py: 'mjt',
                eng: 'Mojito',
              ),
              _productRow(
                '201',
                '薯条',
                one: '1',
                two: '11',
                price: '12',
                py: 'st',
              ),
            ],
            areaProducts: [
              ['r1', '1', '101'],
              ['r1', '1', '201'],
            ],
            padDevice: true,
          ),
      list: list,
      set:
          set ??
          ({
            required String productId,
            required int count,
            bool Function()? canDispatch,
          }) async => const Success(null),
      delete:
          delete ??
          (id, {bool Function()? canDispatch}) async => const Success(null),
      canRead: canRead,
    ),
  ),
);
