import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/src/not_pay_order_view.dart';
import 'package:card_table/src/pay_order_api.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:card_table/src/pay_order_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

import 'pay_order_stale_context_audit_test.dart' as fixture;

void main() {
  testWidgets(
    'paid refund dialog resolves row and package names from the screen',
    (tester) async {
      await _pumpScreen(
        tester,
        PayOrderData(
          seatId: '100',
          payedOrders: [
            PayedOrderRecord(
              id: '80',
              items: [
                _row(
                  '90',
                  name: '历史套餐',
                  details: const [
                    PayOrderPackageDetail(id: '101', name: '历史啤酒', count: 1),
                    PayOrderPackageDetail(id: '102', name: '', count: 1),
                    PayOrderPackageDetail(id: '404', name: ' ', count: 1),
                  ],
                ),
                _row('92'),
                _row('405'),
              ],
            ),
          ],
        ),
        productNameFor: (id) => id == '102' ? '资料小吃' : _catalogName(id),
      );
      await tester.tap(find.text('已结支付单 80'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pay-order-refund-payed')));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('历史套餐')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('已付果盘')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('未知商品（405）')),
        findsOneWidget,
      );
      expect(find.text('套餐明细：历史啤酒 × 1'), findsOneWidget);
      expect(find.text('套餐明细：资料小吃 × 1'), findsOneWidget);
      expect(find.text('套餐明细：未知商品（404） × 1'), findsOneWidget);
    },
  );

  testWidgets(
    'pid-only wire rows resolve names in unpaid, all and paid views',
    (tester) async {
      final data = (await tester.runAsync(_pidOnlyData))!;
      expect(data.unpayItems.single.name, isEmpty);
      expect(data.payedOrders.single.items.single.name, isEmpty);
      await _pumpScreen(tester, data, productNameFor: _catalogName);
      expect(find.text('饮料套餐'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(NotPayOrderView),
          matching: find.byIcon(Icons.arrow_drop_down),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('    套餐啤酒'), findsOneWidget);

      await tester.tap(find.text('全部消费'));
      await tester.pumpAndSettle();
      expect(find.text('饮料套餐'), findsOneWidget);
      expect(find.text('已付果盘'), findsOneWidget);
      expect(find.text('    套餐啤酒'), findsOneWidget);

      await tester.tap(find.text('已结支付单 80'));
      await tester.pumpAndSettle();
      expect(find.text('已付果盘'), findsOneWidget);
    },
  );

  testWidgets(
    'recorded names win and missing catalog names remain identifiable',
    (tester) async {
      await _pumpScreen(
        tester,
        PayOrderData(
          seatId: '100',
          unpayItems: [
            _row('1', name: '历史名称'),
            _row('2', name: '  '),
            _row('3'),
            _row('4'),
          ],
        ),
        productNameFor: (id) => switch (id) {
          '1' => '现商品名',
          '2' => '资料名称',
          '4' => ' \t ',
          _ => null,
        },
      );
      expect(find.text('历史名称'), findsOneWidget);
      expect(find.text('现商品名'), findsNothing);
      expect(find.text('资料名称'), findsOneWidget);
      expect(find.text('未知商品（3）'), findsOneWidget);
      expect(find.text('未知商品（4）'), findsOneWidget);
    },
  );

  testWidgets('views without product lookup show unknown product IDs', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      PayOrderData(
        seatId: '100',
        unpayItems: [_row('404')],
        payedOrders: [
          PayedOrderRecord(id: '80', items: [_row('405')]),
        ],
      ),
    );
    expect(find.text('未知商品（404）'), findsOneWidget);
    await tester.tap(find.text('已结支付单 80'));
    await tester.pumpAndSettle();
    expect(find.text('未知商品（405）'), findsOneWidget);
  });

  testWidgets('refund, move and package actions show resolved row names', (
    tester,
  ) async {
    final data = (await tester.runAsync(_pidOnlyData))!;
    await _pumpScreen(tester, data, productNameFor: _catalogName);
    final view = tester.widget<NotPayOrderView>(find.byType(NotPayOrderView));
    view.onRefundItem!(data.unpayItems.single);
    await tester.pumpAndSettle();
    expect(find.text('退单 - 饮料套餐'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    view.onMoveItem!(data.unpayItems.single);
    await tester.pumpAndSettle();
    expect(find.text('转单 - 饮料套餐'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    view.onEditPackageItem!(data.unpayItems.single);
    await tester.pumpAndSettle();
    expect(find.text('改套餐明细：饮料套餐'), findsOneWidget);
  });

  testWidgets(
    'batch dialog preserves row and package names with catalog fallbacks',
    (tester) async {
      await _pumpScreen(
        tester,
        PayOrderData(
          seatId: '100',
          unpayItems: [
            _row(
              '90',
              name: '历史套餐',
              details: const [
                PayOrderPackageDetail(id: '101', name: '历史啤酒', count: 1),
                PayOrderPackageDetail(id: '102', name: '', count: 1),
                PayOrderPackageDetail(id: '404', name: ' ', count: 1),
              ],
            ),
            _row('92'),
            _row('405'),
          ],
        ),
        productNameFor: (id) => id == '102' ? '资料小吃' : _catalogName(id),
      );
      await tester.tap(find.text('全部消费'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('改服务员'));
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('历史套餐')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('已付果盘')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('未知商品（405）')),
        findsOneWidget,
      );
      expect(find.textContaining('历史啤酒 × 1'), findsOneWidget);
      expect(find.textContaining('资料小吃 × 1'), findsOneWidget);
      expect(find.textContaining('未知商品（404） × 1'), findsOneWidget);
    },
  );
}

String? _catalogName(String id) => switch (id) {
  '90' => '饮料套餐',
  '92' => '已付果盘',
  '101' => '套餐啤酒',
  _ => null,
};

PayOrderItem _row(
  String id, {
  String name = '',
  List<PayOrderPackageDetail> details = const [],
}) => PayOrderItem(
  id: id,
  productId: id,
  name: name,
  count: 1,
  unitPrice: '10',
  amount: '10',
  packageDetails: details,
);

Future<void> _pumpScreen(
  WidgetTester tester,
  PayOrderData data, {
  String? Function(String)? productNameFor,
}) async {
  tester.view.physicalSize = const Size(2400, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: PayOrderScreen(
        table: fixture.table(),
        operationContext: const AlwaysStoppedAnimation<Object?>(true),
        refundContext: const AlwaysStoppedAnimation<Object?>(true),
        productTypeFor: (_) => 1,
        refundPayed: ({
          required seatId,
          required payId,
          required orderIds,
          required counts,
          required amounts,
          required remark,
        }) async => const Success(null),
        productNameFor: productNameFor,
        loadOrders: ({required seatId, required turnoverCount}) async =>
            Success(data),
        refundItem: ({
          required seatId,
          required orderId,
          required count,
          required amount,
          required remark,
          required online,
        }) async => const Success(null),
        moveOrder: ({
          required seatId,
          required destSeatId,
          required orderIds,
          counts = const [],
          totalAmtFen,
          canDispatch,
        }) async => const Success(null),
        batchUpdateOrderWaiter: ({
          required seatId,
          required orderIds,
          required waiterEmpId,
          canDispatch,
        }) async => const Success(null),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<PayOrderData> _pidOnlyData() async {
  final responses = [
    {
      'code': 1,
      'data': {
        'unpay_order': {
          'os': [
            {
              'id': 9,
              'pid': 90,
              'pc': 1,
              'pp': '10',
              'pa': '10',
              'is': 1,
              'si': [
                {'dpi': 101, 'sc': 1, 'dpc': 1},
              ],
            },
          ],
        },
        'payed_order': [
          {
            'id': 80,
            'os': [
              {'id': 10, 'pid': 92, 'pc': 1, 'pp': '10', 'pa': '10', 's': 5},
            ],
          },
        ],
      },
    },
    {'code': 1, 'data': <String, Object?>{}},
  ];
  var now = DateTime.utc(2026, 10, 19);
  final result = await ProtocolPayOrderApi(
    client: ProtocolClient(
      dio: Dio()..httpClientAdapter = _Adapter(responses),
      config: ApiConfig(
        apiBase: Uri.parse('https://api.example.test/server'),
        onlineBase: Uri.parse('https://online.example.test/server'),
        websocketBase: Uri.parse('wss://socket.example.test/server'),
      ),
      credentialStore: _Credentials(),
      requestGate: RequestGate(
        clock: () => now = now.add(const Duration(milliseconds: 101)),
      ),
    ),
  ).getCsmOrders(ClientKind.cashier, seatId: '100', turnoverCount: 2);
  expect(result.failureOrNull, isNull);
  return result.valueOrNull!;
}

final class _Adapter implements HttpClientAdapter {
  _Adapter(this.responses);
  final List<Object?> responses;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode(responses.removeAt(0)),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
  @override
  void close({bool force = false}) {}
}

final class _Credentials implements CredentialStore {
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      const CredentialSnapshot(tk: 'test-tk', stk: null);
  @override
  Future<String?> readTk() async => 'test-tk';
  @override
  Future<String?> readStk() async => null;
  @override
  Future<void> writeTk(String value) async {}
  @override
  Future<void> writeStk(String value) async {}
  @override
  Future<void> clearTk() async {}
  @override
  Future<void> clearStk() async {}
  @override
  Future<void> clearTkIfMatches(String? expected) async {}
  @override
  Future<void> clearStkIfMatches(String? expected) async {}
}
