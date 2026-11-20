import 'package:card_table/src/pay_money_drawer.dart';
import 'package:card_table/src/pay_order_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('failed add preserves amount and blocks settlement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var refreshed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: PayMoneyDrawer(
            seatId: 100,
            totalUnpayAmt: 20,
            cartItems: const [],
            onAddChannel: (_, _, _) async {
              throw StateError('加入失败');
            },
            onDeleteChannel: (_) async {},
            onAddZeroAuth: (_, _) async {},
            onSubmitPay: () async {},
            refreshCart: () async {
              refreshed = true;
              return [];
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('确认加入流水'));
    await tester.pumpAndSettle();
    expect(find.text('加入失败'), findsOneWidget);
    expect(refreshed, isFalse);
    final finish = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('完成收款'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(finish.onPressed, isNull);
  });
  testWidgets(
    'drawer refreshes successful additions and disables specialized channels',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var amount = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: PayMoneyDrawer(
              seatId: 100,
              totalUnpayAmt: 20,
              cartItems: const [],
              onAddChannel: (id, fen, note) async {
                amount = fen;
              },
              onDeleteChannel: (_) async {},
              onAddZeroAuth: (_, _) async {},
              onSubmitPay: () async {},
              refreshCart: () async => const [
                PayCartItem(
                  id: '1',
                  channelId: '1',
                  channelName: '现金',
                  amount: '20.00',
                ),
              ],
            ),
          ),
        ),
      );
      for (final label in ['会员卡', '挂账', '预订金', '滞留金']) {
        final tile = tester.widget<ListTile>(
          find.ancestor(of: find.text(label), matching: find.byType(ListTile)),
        );
        expect(tile.enabled, isFalse);
      }
      final wipe = tester.widget<ListTile>(
        find.ancestor(of: find.text('抹零'), matching: find.byType(ListTile)),
      );
      expect(wipe.enabled, isTrue);
      final button = find.text('确认加入流水');
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(amount, 2000);
      expect(find.text('¥20.00'), findsWidgets);
      final finish = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('完成收款'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(finish.onPressed, isNotNull);
    },
  );
}
