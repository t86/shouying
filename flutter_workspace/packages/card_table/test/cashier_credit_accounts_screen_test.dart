import 'dart:async';

import 'package:card_table/src/cashier_credit_accounts.dart';
import 'package:card_table/src/cashier_credit_accounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

class CreditLoader implements CashierCreditAccountsLoader {
  @override
  bool needsVerification = false;
  final saved = <CashierCreditAccountDraft>[],
      repayments = <CashierCreditRepayment>[];
  final deleted = <String>[], logTypes = <int>[], verified = <bool>[];
  Completer<Result<void>>? pending;
  bool Function()? current;
  final accounts = const [
    CashierCreditAccount(
      id: '7',
      name: '欠款账户',
      amountYuan: '30.00',
      contactName: '张三',
      contactPhone: '13800000000',
    ),
    CashierCreditAccount(id: '8', name: '零额账户', amountYuan: '0.00'),
  ];
  @override
  Future<Result<List<CashierCreditAccount>>> list(
    String keyword, {
    bool verify = false,
  }) async {
    verified.add(verify);
    if (verify) needsVerification = false;
    return Success(accounts);
  }

  @override
  Future<Result<List<CashierCreditLog>>> logs(String id, int type) async {
    logTypes.add(type);
    return const Success([
      CashierCreditLog(
        time: '昨日',
        type: '挂账',
        amountYuan: '30.00',
        channel: '挂账',
        operatorName: '操作员',
      ),
    ]);
  }

  @override
  Future<Result<List<CashierCreditOrder>>> orders(String id) async =>
      const Success([
        CashierCreditOrder(
          id: '11',
          amountFen: 1000,
          time: '21:00',
          seat: 'A01',
          salesName: '销售甲',
        ),
        CashierCreditOrder(
          id: '12',
          amountFen: 2000,
          time: '22:00',
          seat: 'A02',
          salesName: '销售乙',
        ),
      ]);
  Future<Result<void>> _write(bool Function() guard) {
    current = guard;
    if (pending != null) {
      needsVerification = true;
      return pending!.future;
    }
    return Future.value(const Success(null));
  }

  @override
  Future<Result<void>> save(
    CashierCreditAccountDraft draft,
    bool Function() guard,
  ) {
    saved.add(draft);
    return _write(guard);
  }

  @override
  Future<Result<void>> delete(
    CashierCreditAccount account,
    bool Function() guard,
  ) {
    deleted.add(account.id);
    return _write(guard);
  }

  @override
  Future<Result<void>> repay(
    CashierCreditRepayment draft,
    bool Function() guard,
  ) {
    repayments.add(draft);
    return _write(guard);
  }
}

Future<void> open(
  WidgetTester tester,
  CreditLoader loader, {
  ValueNotifier<bool>? access,
}) async {
  tester.view.physicalSize = const Size(390, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: CashierCreditAccountsScreen(
        loader: loader,
        canOperate: access ?? ValueNotifier(true),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> visible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
  } else {
    await tester.scrollUntilVisible(
      finder,
      150,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('account CRUD respects selection debt and phone validation', (
    tester,
  ) async {
    final loader = CreditLoader();
    await open(tester, loader);
    await tester.tap(find.byKey(const ValueKey('credit-account-7')));
    await tester.pump();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(loader.deleted, isEmpty);
    expect(find.text('当前账户挂账金额大于0，不可删除'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('credit-account-7')));
    await tester.tap(find.byKey(const ValueKey('credit-account-8')));
    await tester.pump();
    await tester.tap(find.text('编辑'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('credit-name')), '修改后');
    await tester.enterText(find.byKey(const Key('credit-phone')), '123');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(loader.saved, isEmpty);
    await tester.enterText(
      find.byKey(const Key('credit-phone')),
      '13800000000',
    );
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(loader.saved.single.id, '8');
    expect(loader.saved.single.name, '修改后');
    await tester.tap(find.byKey(const ValueKey('credit-account-8')));
    await tester.pump();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();
    expect(loader.deleted, ['8']);
    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('credit-name')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(find.byKey(const Key('credit-name')), '新账户');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(loader.saved.last.id, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'repayment selects orders channels autofills and sends exact source allocations',
    (tester) async {
      final loader = CreditLoader();
      await open(tester, loader);
      await tester.tap(find.text('挂账还款').first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, '全选订单'));
      await tester.pumpAndSettle();
      for (final id in [1, 2]) {
        final chip = find.byKey(ValueKey('credit-channel-$id'));
        await visible(tester, chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }
      final first = find.byKey(const ValueKey('credit-channel-amount-1'));
      await visible(tester, first);
      await tester.enterText(first, '10');
      await tester.pump();
      final second = find.byKey(const ValueKey('credit-channel-amount-2'));
      await visible(tester, second);
      await tester.enterText(second, '');
      await tester.pump();
      await visible(tester, find.text('自动填入余额').last);
      await tester.tap(find.text('自动填入余额').last);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(second).controller!.text, '20.00');
      await visible(tester, find.text('确定还款'));
      await tester.tap(find.text('确定还款'));
      await tester.pumpAndSettle();
      expect(loader.repayments.single.toWire(), {
        'ids': [11, 12],
        'amts': [1000, 2000],
        'cnl_names': ['现金还款', '微信还款'],
      });
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('logs query and reset use source type values', (tester) async {
    final loader = CreditLoader();
    await open(tester, loader);
    await tester.tap(find.text('查看记录').first);
    await tester.pumpAndSettle();
    tester
        .widget<DropdownButtonFormField<int>>(
          find.byType(DropdownButtonFormField<int>),
        )
        .onChanged!(2);
    await tester.pump();
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重置'));
    await tester.pumpAndSettle();
    expect(loader.logTypes, [0, 2, 0]);
    expect(find.textContaining('30.00'), findsOneWidget);
  });
  testWidgets(
    'back while saving revokes guard and requires explicit verification',
    (tester) async {
      final loader = CreditLoader()..pending = Completer<Result<void>>();
      await open(tester, loader);
      await tester.tap(find.text('新增'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('credit-name')), '新账户');
      final submit = tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确定'))
          .onPressed!;
      submit();
      submit();
      await tester.pump();
      expect(loader.saved.length, 1);
      expect(loader.current!(), true);
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      expect(loader.current!(), false);
      loader.pending!.complete(
        const FailureResult(
          AppFailure(
            kind: FailureKind.network,
            code: 'test',
            safeMessage: '未知',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '新增'))
            .onPressed,
        isNull,
      );
      await tester.tap(find.text('查询核实'));
      await tester.pumpAndSettle();
      expect(loader.verified.last, true);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '新增'))
            .onPressed,
        isNotNull,
      );
    },
  );
  testWidgets(
    'build-frame permission pulse revokes old form without setState error',
    (tester) async {
      final loader = CreditLoader()..pending = Completer<Result<void>>();
      final access = ValueNotifier(true), trigger = ValueNotifier(false);
      var pulsed = false;
      addTearDown(access.dispose);
      addTearDown(trigger.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: trigger,
            builder: (_, value, _) {
              if (value && !pulsed) {
                pulsed = true;
                access.value = false;
                access.value = true;
              }
              return CashierCreditAccountsScreen(
                loader: loader,
                canOperate: access,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('credit-name')), '新账户');
      await tester.tap(find.text('确定'));
      await tester.pump();
      trigger.value = true;
      await tester.pump();
      expect(loader.current!(), false);
      loader.pending!.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('credit-name')), findsNothing);
    },
  );
}
