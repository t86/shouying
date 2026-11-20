import 'dart:async';

import 'package:card_table/src/order_late_deposit.dart';
import 'package:card_table/src/order_late_deposit_screen.dart';
import 'package:card_table/src/qr_code_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

Future<void> _open(
  WidgetTester tester,
  _Loader loader,
  ValueNotifier<bool> access, {
  Future<String?> Function()? scanner,
  VoidCallback? paid,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => OrderLateDepositScreen(
                  seatId: '101',
                  loader: loader,
                  canOperate: access,
                  scanCode: scanner,
                  onPaid: paid,
                ),
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

Future<void> _create(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('order-late-amount')), '12.50');
  await tester.tap(find.text('客人扫我-微信'));
  await tester.pump();
  await tester.tap(find.text('确认收取'));
  await tester.pump();
}

void main() {
  testWidgets(
    'paid status during close confirmation removes only its own two routes',
    (tester) async {
      final loader = _Loader();
      final access = ValueNotifier(true);
      addTearDown(access.dispose);
      var paid = 0;
      await _open(tester, loader, access, paid: () => paid++);
      await _create(tester);
      await tester.pump();
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      loader.nextStatus = 5;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(paid, 1);
      expect(find.text('打开'), findsOneWidget);
      expect(find.text('确认关闭'), findsNothing);
    },
  );
  testWidgets(
    'only QR channels without scanner; displays actual QR and status5 completes',
    (tester) async {
      final loader = _Loader();
      final access = ValueNotifier(true);
      addTearDown(access.dispose);
      var paid = 0;
      await _open(tester, loader, access, paid: () => paid++);
      expect(find.text('扫客人-微信'), findsNothing);
      await _create(tester);
      await tester.pump();
      expect(loader.amounts, ['12.50']);
      expect(find.byType(QrCodePane), findsOneWidget);
      loader.nextStatus = 5;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(loader.queried, ['81']);
      expect(paid, 1);
      expect(find.text('打开'), findsOneWidget);
    },
  );
  testWidgets(
    'scanner channels are injected and creation waits for scan result',
    (tester) async {
      final loader = _Loader();
      final access = ValueNotifier(true);
      addTearDown(access.dispose);
      final scan = Completer<String?>();
      await _open(tester, loader, access, scanner: () => scan.future);
      await tester.enterText(
        find.byKey(const Key('order-late-amount')),
        '9.90',
      );
      await tester.tap(find.text('扫客人-微信'));
      await tester.pump();
      await tester.tap(find.text('确认收取'));
      await tester.pump();
      await tester.tap(find.text('确认收取'));
      await tester.pump();
      expect(loader.amounts, isEmpty);
      scan.complete('synthetic-code');
      await tester.pump();
      expect(loader.types, [6]);
      expect(loader.codes, ['synthetic-code']);
      await tester.pumpWidget(const MaterialApp(home: Text('done')));
    },
  );
  testWidgets('unknown creation locks retry and never displays success', (
    tester,
  ) async {
    final loader = _Loader()..createFailure = true;
    final access = ValueNotifier(true);
    addTearDown(access.dispose);
    await _open(tester, loader, access);
    await _create(tester);
    await tester.pump();
    expect(find.textContaining('请勿重复创建'), findsOneWidget);
    expect(find.text('支付成功'), findsNothing);
    final button = find.widgetWithText(FilledButton, '确认收取');
    if (button.evaluate().isNotEmpty) {
      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    }
    expect(loader.amounts.length, 1);
  });
  testWidgets(
    'closing pending payment warns, stops polling, and does not cancel it',
    (tester) async {
      final loader = _Loader();
      final access = ValueNotifier(true);
      addTearDown(access.dispose);
      await _open(tester, loader, access);
      await _create(tester);
      await tester.pump();
      await tester.tap(find.byTooltip('关闭'));
      await tester.pumpAndSettle();
      expect(find.textContaining('不会撤销付款'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '确认关闭'));
      await tester.pumpAndSettle();
      final count = loader.queried.length;
      await tester.pump(const Duration(seconds: 3));
      expect(loader.queried.length, count);
      expect(find.text('打开'), findsOneWidget);
    },
  );
  testWidgets(
    'permission loss during creation hides QR and rejects late success',
    (tester) async {
      final loader = _Loader()
        ..pending = Completer<Result<OrderLateDepositPayment>>();
      final access = ValueNotifier(true);
      addTearDown(access.dispose);
      var paid = 0;
      await _open(tester, loader, access, paid: () => paid++);
      await _create(tester);
      access.value = false;
      await tester.pump();
      expect(loader.guard!(), false);
      loader.pending!.complete(
        const Success(
          OrderLateDepositPayment(
            payDetailId: '81',
            payUrl: 'https://example.invalid',
            result: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(paid, 0);
      expect(find.byType(QrCodePane), findsNothing);
    },
  );
  testWidgets(
    'poll error keeps the original detail id and never recreates payment',
    (tester) async {
      final loader = _Loader()..pollFailure = true;
      final access = ValueNotifier(true);
      addTearDown(access.dispose);
      await _open(tester, loader, access);
      await _create(tester);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(loader.amounts.length, 1);
      expect(loader.queried, ['81']);
      expect(find.textContaining('查询未确认'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: Text('done')));
    },
  );
}

class _Loader implements OrderLateDepositLoader {
  @override
  bool needsVerification = false;
  bool createFailure = false, pollFailure = false;
  int nextStatus = 0;
  final amounts = <String>[],
      types = <int>[],
      codes = <String?>[],
      queried = <String>[];
  bool Function()? guard;
  Completer<Result<OrderLateDepositPayment>>? pending;
  @override
  Future<Result<OrderLateDepositPayment>> create({
    required String seatId,
    required int payType,
    required String amountYuan,
    String? authCode,
    required bool Function() canDispatch,
  }) async {
    amounts.add(amountYuan);
    types.add(payType);
    codes.add(authCode);
    guard = canDispatch;
    if (createFailure) {
      needsVerification = true;
      return const FailureResult(
        AppFailure(
          kind: FailureKind.network,
          code: 'order_late.result_unknown',
          safeMessage: '付款结果不确定，请勿重复创建',
        ),
      );
    }
    return pending?.future ??
        const Success(
          OrderLateDepositPayment(
            payDetailId: '81',
            payUrl: 'https://pay.example.invalid/qr',
            result: 0,
          ),
        );
  }

  @override
  Future<Result<int>> status(
    String payDetailId, {
    required bool Function() canDispatch,
  }) async {
    queried.add(payDetailId);
    return pollFailure
        ? const FailureResult(
            AppFailure(
              kind: FailureKind.network,
              code: 'poll',
              safeMessage: '查询未确认',
            ),
          )
        : Success(nextStatus);
  }
}
