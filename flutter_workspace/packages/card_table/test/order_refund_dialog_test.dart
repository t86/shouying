import 'dart:async';

import 'package:card_table/src/order_meal.dart';
import 'package:card_table/src/order_refund.dart';
import 'package:card_table/src/order_refund_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

OrderPlacedItem order({bool online = false, int authorizationType = 0}) =>
    OrderPlacedItem(
      id: '9',
      productId: '101',
      name: '测试商品',
      count: 5,
      unitPrice: '20',
      recordedUnitPrice: '18',
      amount: '90',
      authorizationType: authorizationType,
      orderedAt: '12:00',
      waiterName: '',
      online: online,
    );
typedef Attempt = Future<Result<void>> Function(
  OrderRefundDraft,
  String,
  String,
  int,
  bool Function(),
);
Future<void> open(
  WidgetTester tester, {
  int? type = 1,
  bool cashier = false,
  bool online = false,
  int authorizationType = 0,
  required ValueNotifier<Object?> token,
  required Attempt submit,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<bool>(
              context: ctx,
              builder: (_) => OrderRefundDialog(
                draft: OrderRefundDraft.fromOrder(
                  order: order(
                    online: online,
                    authorizationType: authorizationType,
                  ),
                  productType: type,
                  isCashier: cashier,
                ),
                reasons: const ['点错'],
                contextToken: token,
                submit: submit,
              ),
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('打开'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'unpaid gift preview is zero while special refund request preserves original pa',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      OrderRefundDraft? sent;
      await open(
        tester,
        type: 3,
        authorizationType: 2,
        token: token,
        submit: (draft, _, _, _, _) async {
          sent = draft;
          return const Success(null);
        },
      );
      expect(find.text('退单金额：￥0.00'), findsOneWidget);
      await tester.tap(find.text('点错'));
      await tester.pump();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(sent!.backAmount, '90');
    },
  );
  testWidgets(
    'ordinary refund previews historical amount by count but posts empty amount',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      OrderRefundDraft? sent;
      await open(
        tester,
        token: token,
        submit: (draft, _, _, _, _) async {
          sent = draft;
          return const Success(null);
        },
      );
      await tester.enterText(find.byKey(const Key('order-refund-count')), '2');
      await tester.pumpAndSettle();
      expect(find.text('退单金额：￥36.00'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('order-refund-count')), '1');
      await tester.pumpAndSettle();
      expect(find.text('退单金额：￥18.00'), findsOneWidget);
      await tester.tap(find.text('点错'));
      await tester.pump();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(sent!.backAmount, '');
    },
  );
  for (final (type, online, count, editable, amount)
      in <(int, bool, int, bool, String)>[
        (1, false, 1, true, ''),
        (1, true, 5, false, ''),
        (4, false, 1, false, ''),
        (3, false, 5, false, '90'),
        (5, false, 5, false, '90'),
        (8, false, 5, false, '90'),
      ]) {
    testWidgets(
      'source quantity locks type $type online $online and original refund amount',
      (tester) async {
        final token = ValueNotifier<Object?>(Object());
        addTearDown(token.dispose);
        OrderRefundDraft? sent;
        await open(
          tester,
          type: type,
          online: online,
          token: token,
          submit: (draft, code, password, passType, _) async {
            sent = draft;
            expect(code, '');
            expect(password, '');
            expect(passType, 1);
            return const Success(null);
          },
        );
        final field = tester.widget<TextField>(
          find.byKey(const Key('order-refund-count')),
        );
        expect(field.controller!.text, '$count');
        expect(field.enabled, editable);
        expect(field.keyboardType, TextInputType.number);
        await tester.tap(find.text('点错'));
        await tester.pump();
        await tester.tap(find.text('确认'));
        await tester.pumpAndSettle();
        expect(sent!.count, count);
        expect(sent!.backAmount, amount);
        expect(find.text('打开'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'cashier partial special refund clears amount and rejects amount above recorded pa',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      final sent = <OrderRefundDraft>[];
      await open(
        tester,
        type: 3,
        cashier: true,
        token: token,
        submit: (draft, _, _, _, _) async {
          sent.add(draft);
          return const Success(null);
        },
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('order-refund-amount')))
            .enabled,
        isFalse,
      );
      await tester.enterText(find.byKey(const Key('order-refund-count')), '2');
      await tester.pump();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('order-refund-amount')))
            .controller!
            .text,
        '',
      );
      await tester.enterText(
        find.byKey(const Key('order-refund-amount')),
        '91',
      );
      await tester.tap(find.text('点错'));
      await tester.pump();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(sent, isEmpty);
      expect(find.textContaining('不超过原订单金额'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('order-refund-amount')),
        '35',
      );
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(sent.single.count, 2);
      expect(sent.single.backAmount, '35');
    },
  );
  testWidgets(
    'only code 2 upgrades to account/card authorization and clears credentials after retries',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      final calls = <({String code, String password, int type})>[];
      await open(
        tester,
        token: token,
        submit: (draft, code, password, type, _) async {
          calls.add((code: code, password: password, type: type));
          return calls.length < 3
              ? const FailureResult(
                  AppFailure(
                    kind: FailureKind.business,
                    code: orderRefundAuthorizationRequiredCode,
                    safeMessage: '需要授权',
                  ),
                )
              : const Success(null);
        },
      );
      await tester.tap(find.text('点错'));
      await tester.pump();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(calls.single, (code: '', password: '', type: 1));
      expect(find.text('退单授权'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('order-refund-auth-code')),
        'test-emp',
      );
      await tester.enterText(
        find.byKey(const Key('order-refund-auth-password')),
        'synthetic-only',
      );
      await tester.tap(find.text('授权退单'));
      await tester.pumpAndSettle();
      expect(calls[1], (code: 'test-emp', password: 'synthetic-only', type: 1));
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('order-refund-auth-password')),
            )
            .controller!
            .text,
        '',
      );
      await tester.tap(find.text('卡码输入'));
      await tester.pump();
      expect(find.textContaining('未接自动读卡'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('order-refund-auth-code')),
        'synthetic-card',
      );
      await tester.enterText(
        find.byKey(const Key('order-refund-auth-password')),
        'decoded-test-password',
      );
      await tester.tap(find.text('授权退单'));
      await tester.pumpAndSettle();
      expect(calls.last.type, 2);
      expect(calls.last.code, 'synthetic-card');
      expect(find.text('打开'), findsOneWidget);
    },
  );
  testWidgets(
    'ordinary failure stays on draft and cancellation closes keyboard without retry',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      var calls = 0;
      await open(
        tester,
        token: token,
        submit: (_, _, _, _, _) async {
          calls++;
          return const FailureResult(
            AppFailure(
              kind: FailureKind.network,
              code: 'network',
              safeMessage: '网络失败',
            ),
          );
        },
      );
      await tester.tap(find.text('点错'));
      await tester.pump();
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();
      expect(find.text('退单授权'), findsNothing);
      expect(find.text('网络失败'), findsOneWidget);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byKey(const Key('order-refund-count')), findsNothing);
    },
  );
  testWidgets('unknown product type never submits a guessed ordinary refund', (
    tester,
  ) async {
    final token = ValueNotifier<Object?>(Object());
    addTearDown(token.dispose);
    var calls = 0;
    await open(
      tester,
      type: null,
      token: token,
      submit: (_, _, _, _, _) async {
        calls++;
        return const Success(null);
      },
    );
    await tester.tap(find.text('点错'));
    await tester.pump();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.textContaining('商品类型未知'), findsOneWidget);
  });
  testWidgets(
    'disconnect invalidates old draft permanently even after reconnect',
    (tester) async {
      final original = Object();
      final token = ValueNotifier<Object?>(original);
      addTearDown(token.dispose);
      var calls = 0;
      await open(
        tester,
        token: token,
        submit: (_, _, _, _, _) async {
          calls++;
          return const Success(null);
        },
      );
      await tester.tap(find.text('点错'));
      await tester.pump();
      token.value = null;
      await tester.pump();
      token.value = original;
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '确认'))
            .onPressed,
        isNull,
      );
      expect(calls, 0);
      expect(find.textContaining('窗口已失效'), findsOneWidget);
    },
  );
  testWidgets(
    'identity change during pending refund cannot close a newer route as success',
    (tester) async {
      final token = ValueNotifier<Object?>(Object());
      addTearDown(token.dispose);
      final pending = Completer<Result<void>>();
      await open(
        tester,
        token: token,
        submit: (_, _, _, _, _) => pending.future,
      );
      await tester.tap(find.text('点错'));
      await tester.pump();
      await tester.tap(find.text('确认'));
      await tester.pump();
      token.value = Object();
      pending.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.textContaining('窗口已失效'), findsOneWidget);
      expect(find.text('退单'), findsOneWidget);
    },
  );
}
