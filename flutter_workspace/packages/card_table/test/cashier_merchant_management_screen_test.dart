import 'dart:async';

import 'package:card_table/src/cashier_merchant_management.dart';
import 'package:card_table/src/cashier_merchant_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

const publicA = CashierMerchant(id: 1, name: '公A', kind: 1),
    publicB = CashierMerchant(id: 4, name: '公B', kind: 1),
    privateA = CashierMerchant(id: 2, name: '私A', kind: 2),
    privateB = CashierMerchant(id: 3, name: '私B', kind: 2);

class MerchantFake implements CashierMerchantManagementLoader {
  bool verificationRequired = false;
  int verifications = 0;
  @override
  bool get needsVerification => verificationRequired;
  @override
  Future<Result<void>> verify(bool Function() canAccept) async {
    verifications++;
    if (!canAccept())
      return const FailureResult(
        AppFailure(
          kind: FailureKind.authentication,
          code: 'stale',
          safeMessage: '状态变化',
        ),
      );
    verificationRequired = false;
    return const Success(null);
  }

  int configuredMax = 0, configuredHourAmount = 0;
  bool configuredAuto = false;
  bool multi = false;
  int groupsRead = 0, configRead = 0, writes = 0;
  CashierMerchantGroupsDraft? groupDraft;
  CashierMerchantConfigDraft? configDraft;
  Completer<Result<void>>? pending;
  bool Function()? dispatch;
  bool enabled = false;
  @override
  Future<Result<CashierMerchantGroups>> groups() async {
    groupsRead++;
    return Success(
      CashierMerchantGroups(
        merchants: [publicA, if (multi) publicB, privateA, privateB],
        regions: const {11: 'A区', 12: 'B区'},
        assignments: multi
            ? const [
                CashierMerchantAssignment(
                  entityId: 1,
                  privateIds: {2},
                  regionIds: {11},
                  isDefault: true,
                ),
                CashierMerchantAssignment(
                  entityId: 4,
                  privateIds: {3},
                  regionIds: {12},
                ),
              ]
            : const [],
      ),
    );
  }

  @override
  Future<Result<CashierMerchantConfig>> config(int id) async {
    configRead++;
    return Success(
      CashierMerchantConfig(
        entityId: id,
        switchEnabled: configuredAuto,
        maxAmount: configuredMax,
        targetMerchantId: configuredAuto ? 2 : 0,
        defaultMerchantId: 2,
        merchants: const [publicA, privateA, privateB],
        hours: [
          for (var h = 0; h < 24; h++)
            CashierMerchantHourRule(
              hour: h,
              maxAmount: h == 12 ? configuredHourAmount : 0,
              merchantId: h == 12 && configuredHourAmount != 0 ? 2 : 0,
            ),
        ],
        regions: const [
          CashierMerchantRegion(
            id: 11,
            name: 'A区',
            seats: [
              CashierMerchantSeat(id: 7, name: 'A01'),
              CashierMerchantSeat(id: 8, name: 'A02', merchantId: 2),
            ],
          ),
        ],
      ),
    );
  }

  Future<Result<void>> act(bool Function() guard) {
    writes++;
    dispatch = guard;
    return pending?.future ?? Future.value(const Success(null));
  }

  @override
  Future<Result<void>> saveGroups(
    CashierMerchantGroupsDraft draft,
    bool Function() guard,
  ) {
    groupDraft = draft;
    return act(guard);
  }

  @override
  Future<Result<void>> saveConfig(
    CashierMerchantConfigDraft draft,
    bool Function() guard,
  ) {
    configDraft = draft;
    return act(guard);
  }

  @override
  Future<Result<void>> setOnline(int id, bool value, bool Function() guard) =>
      act(guard);
  @override
  Future<Result<List<CashierMerchantHourAmount>>> hours(int id) async =>
      const Success([
        CashierMerchantHourAmount(
          hour: 0,
          amount: '20000',
          publicAmount: '10000',
          total: '时段原值',
        ),
      ]);
  @override
  Future<Result<CashierMerchantSwitchState>> switchState() async => Success(
    CashierMerchantSwitchState(
      enabled: enabled,
      merchantId: enabled ? 2 : 0,
      merchants: const [privateA, privateB],
    ),
  );
  @override
  Future<Result<void>> enableSwitch(int id, bool Function() guard) {
    enabled = true;
    return act(guard);
  }

  @override
  Future<Result<void>> cancelSwitch(bool Function() guard) {
    enabled = false;
    return act(guard);
  }
}

void main() {
  testWidgets(
    'back invalidates pending live merchant write before animation completes',
    (tester) async {
      final fake = MerchantFake()..pending = Completer<Result<void>>();
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          home: const Scaffold(body: Text('首页')),
        ),
      );
      unawaited(
        nav.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => CashierMerchantManagementScreen(
              loader: fake,
              canOperate: ValueNotifier(true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('merchant-online-2')),
          )
          .onChanged!(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认生效'));
      await tester.pumpAndSettle();
      nav.currentState!.pop();
      await tester.pump();
      expect(fake.dispatch!(), false);
      fake.pending!.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.text('首页'), findsOneWidget);
      expect(fake.writes, 1);
    },
  );
  testWidgets('build-phase permission pulse prevents old confirmation write', (
    tester,
  ) async {
    final fake = MerchantFake(),
        access = ValueNotifier(true),
        trigger = ValueNotifier(false);
    var pulsed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: trigger,
          builder: (context, value, child) {
            if (value && !pulsed) {
              pulsed = true;
              access.value = false;
              access.value = true;
            }
            return CashierMerchantManagementScreen(
              loader: fake,
              canOperate: access,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<SwitchListTile>(find.byKey(const ValueKey('merchant-online-2')))
        .onChanged!(false);
    await tester.pumpAndSettle();
    trigger.value = true;
    await tester.pump();
    await tester.tap(find.text('确认生效'));
    await tester.pumpAndSettle();
    expect(fake.writes, 0);
    expect(tester.takeException(), isNull);
  });
  Future<void> open(
    WidgetTester tester,
    MerchantFake loader, {
    ValueNotifier<bool>? access,
  }) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CashierMerchantManagementScreen(
          loader: loader,
          canOperate: access ?? ValueNotifier(true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'loaded signed thresholds remain editable and save without losing signs',
    (tester) async {
      final fake = MerchantFake()
        ..configuredAuto = true
        ..configuredMax = -123
        ..configuredHourAmount = -45;
      await open(tester, fake);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        '-123',
      );
      await tester.ensureVisible(find.text('保存修改'));
      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle();
      expect(find.text('确认生效'), findsOneWidget);
      await tester.tap(find.text('确认生效'));
      await tester.pumpAndSettle();
      expect(fake.configDraft!.maxAmount, -123);
      expect(
        fake.configDraft!.hours.singleWhere((h) => h.hour == 12).maxAmount,
        -45,
      );
      expect(fake.writes, 1);
    },
  );
  testWidgets(
    'two subjects enforce exclusive private merchants and regions before global save',
    (tester) async {
      final fake = MerchantFake()..multi = true;
      await open(tester, fake);
      expect(fake.configRead, 0);
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const ValueKey('默认主体-null-1')),
          )
          .onChanged!(4);
      await tester.pump();
      void check(String key) => tester
          .widget<CheckboxListTile>(find.byKey(ValueKey(key)))
          .onChanged!(true);
      check('merchant-private-1-3');
      await tester.pump();
      check('merchant-private-4-2');
      await tester.pump();
      check('merchant-region-1-12');
      await tester.pump();
      check('merchant-region-4-11');
      await tester.pump();
      await tester.ensureVisible(find.text('保存全局配置'));
      await tester.tap(find.text('保存全局配置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认生效'));
      await tester.pumpAndSettle();
      expect(fake.groupDraft!.privateIdsByEntity, {
        1: [3],
        4: [2],
      });
      expect(fake.groupDraft!.regionIdsByEntity, {
        1: [12],
        4: [11],
      });
      expect(fake.writes, 1);
      expect(fake.groupDraft!.defaultEntityId, 4);
    },
  );
  testWidgets(
    'access revoked hides old merchant configuration until successful reload',
    (tester) async {
      final access = ValueNotifier(true);
      await open(tester, MerchantFake(), access: access);
      expect(find.byKey(const ValueKey('merchant-online-2')), findsOneWidget);
      access.value = false;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('merchant-online-2')), findsNothing);
      expect(find.text('默认商户号'), findsNothing);
      access.value = true;
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('merchant-online-2')), findsNothing);
      await tester.tap(find.text('重新读取配置'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('merchant-online-2')), findsOneWidget);
    },
  );
  testWidgets(
    'access revoked hides historical merchant amounts hours and switch state',
    (tester) async {
      final access = ValueNotifier(true);
      await tester.pumpWidget(
        MaterialApp(
          home: CashierMerchantInformationScreen(
            loader: MerchantFake(),
            canOperate: access,
            merchantId: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('G 1.00'), findsOneWidget);
      expect(find.textContaining('时段原值'), findsOneWidget);
      access.value = false;
      await tester.pumpAndSettle();
      expect(find.text('G 1.00'), findsNothing);
      expect(find.textContaining('时段原值'), findsNothing);
      expect(find.text('商户号一键切换'), findsNothing);
    },
  );
  testWidgets(
    'reopened management page cannot unlock loader by automatic reads',
    (tester) async {
      final fake = MerchantFake()..verificationRequired = true;
      await open(tester, fake);
      expect(fake.verifications, 0);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('merchant-online-2')),
            )
            .onChanged,
        isNull,
      );
      await tester.tap(find.text('重新读取配置'));
      await tester.pumpAndSettle();
      expect(fake.verifications, 1);
      expect(fake.verificationRequired, false);
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('merchant-online-2')),
            )
            .onChanged,
        isNotNull,
      );
    },
  );
  testWidgets(
    'mobile configuration rejects fractional threshold without truncating or writing',
    (tester) async {
      final fake = MerchantFake();
      await open(tester, fake);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('merchant-auto-switch')),
          )
          .onChanged!(true);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '12.5');
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byKey(const ValueKey('阈值切换目标商户-0-0')),
          )
          .onChanged!(2);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('保存修改'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle();
      expect(fake.writes, 0);
      expect(find.textContaining('整数元阈值'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'hour amount change selects first private merchant and serializes all 24 hours',
    (tester) async {
      final fake = MerchantFake();
      await open(tester, fake);
      expect(fake.configRead, 1);
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).onChanged!(
        true,
      );
      await tester.pump();
      await tester.tap(find.text('时段额度控制（24小时）'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('merchant-hour-amount-12')),
        '120',
      );
      await tester.pump();
      await tester.tap(find.text('时段额度控制（24小时）'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('保存修改'));
      await tester.tap(find.text('保存修改'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认生效'));
      await tester.pumpAndSettle();
      expect(fake.configDraft!.hours.length, 24);
      expect(fake.configDraft!.seatMerchants, {7: 2, 8: 2});
      expect(
        fake.configDraft!.hours.singleWhere((h) => h.hour == 12).merchantId,
        2,
      );
      expect(
        fake.configDraft!.hours.singleWhere((h) => h.hour == 12).maxAmount,
        120,
      );
    },
  );
  testWidgets(
    'online switch pending across access pulse remains blocked until explicit reload',
    (tester) async {
      final fake = MerchantFake()..pending = Completer<Result<void>>();
      final access = ValueNotifier(true);
      await open(tester, fake, access: access);
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey('merchant-online-2')),
          )
          .onChanged!(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认生效'));
      await tester.pumpAndSettle();
      expect(fake.dispatch!(), true);
      access.value = false;
      access.value = true;
      await tester.pump();
      expect(fake.dispatch!(), false);
      fake.pending!.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('merchant-online-2')), findsNothing);
      await tester.tap(find.text('重新读取配置'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('merchant-online-2')),
            )
            .onChanged,
        isNotNull,
      );
      expect(fake.writes, 1);
    },
  );
  testWidgets(
    'merchant information displays source scaled totals and live manual enable cancel actions',
    (tester) async {
      final fake = MerchantFake();
      await tester.pumpWidget(
        MaterialApp(
          home: CashierMerchantInformationScreen(
            loader: fake,
            canOperate: ValueNotifier(true),
            merchantId: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1.00'), findsOneWidget);
      expect(find.text('G 1.00'), findsOneWidget);
      expect(find.textContaining('时段原值'), findsOneWidget);
      await tester.tap(find.text('商户号一键切换'));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>),
          )
          .onChanged!(2);
      await tester.pump();
      await tester.tap(find.text('确定切换'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认生效'));
      await tester.pumpAndSettle();
      expect(fake.enabled, true);
      await tester.tap(find.text('取消切换'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认生效'));
      await tester.pumpAndSettle();
      expect(fake.enabled, false);
      expect(fake.writes, 2);
    },
  );
}
