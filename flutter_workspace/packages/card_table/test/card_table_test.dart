import 'dart:async';

import 'package:card_table/card_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';

void main() {
  testWidgets('old footer waits for server permission and revokes supervisor region live', (tester) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync:true);
    addTearDown(events.close);
    final checks = <Completer<Result<bool>>>[];
    await tester.pumpWidget(MaterialApp(home:CardTableScreen(
      system:BusinessSystem.order,stationId:'9',employeeId:'42',events:events.stream,
      connectionPhase:ConnectionPhase.online,
      onAddOrderProduct:({required String seatId,required String productId,required int count,required String price,String amount=''})async=>const Success(null),
      onCheckOrderAmounts:(seatId){ expect(seatId,'100');final check=Completer<Result<bool>>();checks.add(check);return check.future; },
    )));
    events.add(SyncEnvelope.fromValidatedReconciliation(cursor:'20260920100000',data:_fullData(roleRows:[[9,11,1]],supervisorRegions:[[9,1,1]])));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip,'全部'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
    await tester.pumpAndSettle();
    final meal=tester.widget<OrderMealScreen>(find.byType(OrderMealScreen));
    expect(checks.length,1);
    expect(meal.footerAmountsVisibility!.value,false);
    checks[0].complete(const Success(true));
    await tester.pumpAndSettle();
    expect(meal.footerAmountsVisibility!.value,true);
    events.add(SyncEnvelope.fromValidatedReconciliation(cursor:'20260920100001',data:{'41':[[9,12,1]]}));
    await tester.pumpAndSettle();
    expect(checks.length,2);
    expect(meal.footerAmountsVisibility!.value,false);
    events.add(SyncEnvelope.fromValidatedReconciliation(cursor:'20260920100002',data:{'56':[[9,1,0]]}));
    await tester.pumpAndSettle();
    checks[1].complete(const Success(true));
    await tester.pumpAndSettle();
    expect(meal.footerAmountsVisibility!.value,false);
    events.add(SyncEnvelope.fromValidatedReconciliation(cursor:'20260920100003',data:_fullData(roleRows:[[9,11,1]],supervisorRegions:[[9,0,1]])));
    await tester.pumpAndSettle();
    expect(checks.length,3);
    checks[2].complete(const Success(true));
    await tester.pumpAndSettle();
    expect(meal.footerAmountsVisibility!.value,true);
  });
  test('cashier report regions include active empty areas outside card grid', () {
    final data = _fullData();
    data[0] = [
      [1, '大厅', 1, 2], [2, '包厢', 1, 3], [3, '空区域', 1, 1], [4, '停用区域', 2, 0],
    ];
    final store = LegacyCardTableStore();
    expect(store.applyEnvelope(SyncEnvelope.fromValidatedReconciliation(cursor:'20260828010101',data:data)).failureOrNull,isNull);
    expect(store.cashierReportRegionOptions.keys.toList(),[3,1,2]);
    expect(store.cashierReportRegionOptions[3],'空区域');
    expect(store.currentSnapshot!.regions.map((region)=>region.id),isNot(contains('3')));
  });
  test('cashier report employee options preserve source code and pinyin including inactive staff', () {
    final data = _fullData();
    data[5] = [
      [42, '张三', 1, 8, 9, 1, '13800000000', 'zs', '000042'],
      [43, '李四', 2, 8, 9, 1, '13900000000', 'ls', '000043'],
    ];
    final store = LegacyCardTableStore();
    expect(store.applyEnvelope(SyncEnvelope.fromValidatedReconciliation(cursor:'20260828010101',data:data)).failureOrNull,isNull);
    expect(store.cashierReportSalesOptions,{42:'张三',43:'李四'});
    expect(store.cashierReportSalesSearchTerms[42],'zs 000042');
  });
  testWidgets(
    'order home opens real minimum report and revokes displayed rows',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            stationId: '9',
            employeeId: '42',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onLoadMinimumConsumption: () async {
              calls++;
              return Success([
                MinimumConsumptionReportRow.fromWire({
                  'rn': '大厅',
                  'sn': '报表A01',
                  'o': '20:00',
                  'sd': '测试部门',
                  'se': '测试员工',
                  'm': 1000,
                  'za': 800,
                  'ga': 200,
                  'p': '80%',
                  't': '',
                  'mk': '验证',
                }),
              ]);
            },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '大厅'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('低消进度统计表'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byType(MinimumConsumptionReportScreen), findsOneWidget);
      expect(find.text('报表A01'), findsOneWidget);
      expect(find.text('导出Excel'), findsNothing);
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010102',
          data: <String, Object?>{
            '41': <Object?>[
              <Object?>[9, 5, 3],
            ],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('报表A01'), findsNothing);
      expect(find.text('点击重试查询低消进度统计表'), findsOneWidget);
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('报表A01'), findsOneWidget);
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010102',
          data: <String, Object?>{
            '54': <Object?>[
              <Object?>[1, 1],
            ],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('报表A01'), findsNothing);
      expect(find.text('当前不可查询低消进度统计表'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '关闭'));
      await tester.pumpAndSettle();
      expect(find.byType(MinimumConsumptionReportScreen), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '大厅'))
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'order home opens cocktail detail, queries keyword, and revokes rows',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      final keywords = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            stationId: '9',
            employeeId: '42',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onLoadCocktailDetail: (keyword) async {
              keywords.add(keyword);
              return Success([
                CocktailDetailReportRow.fromWire({
                  'rn': '大厅',
                  's': 'A01',
                  'n': '报表莫吉托',
                  'a': '10',
                }),
                CocktailDetailReportRow.fromWire({'rn': '合计', 'a': '10.00'}),
              ]);
            },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(PopupMenuItem<String>, '鸡尾酒明细表'),
          matching: find.text('待接入'),
        ),
        findsNothing,
      );
      await tester.tap(find.text('鸡尾酒明细表'));
      await tester.pumpAndSettle();
      expect(keywords, ['']);
      expect(find.byType(CocktailDetailReportScreen), findsOneWidget);
      expect(find.text('报表莫吉托'), findsOneWidget);
      expect(find.text('导出Excel'), findsNothing);
      await tester.enterText(
        find.byKey(CocktailDetailReportScreen.keywordKey),
        '莫吉托',
      );
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(keywords, ['', '莫吉托']);
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010102',
          data: <String, Object?>{
            '54': <Object?>[
              <Object?>[1, 1],
            ],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('报表莫吉托'), findsNothing);
      expect(find.text('当前不可查询鸡尾酒明细表'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '关闭'));
      await tester.pumpAndSettle();
      expect(find.byType(CocktailDetailReportScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('order home opens sold-out products without a pending marker', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    var lists = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.order,
          stationId: '9',
          employeeId: '42',
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
          onListSoldOutProducts: () async {
            lists++;
            return Success([
              SoldOutItem.fromWire({'id': '101', 'n': '报表估清', 'c': 2}),
            ]);
          },
          onSetSoldOutProduct: ({
            required String productId,
            required int count,
            bool Function()? canDispatch,
          }) async => const Success(null),
          onDeleteSoldOutProduct: (id, {bool Function()? canDispatch}) async => const Success(null),
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.widgetWithText(PopupMenuItem<String>, '估清商品'),
        matching: find.text('待接入'),
      ),
      findsNothing,
    );
    await tester.tap(find.text('估清商品'));
    await tester.pumpAndSettle();
    expect(lists, 1);
    expect(find.byType(SoldOutProductsScreen), findsOneWidget);
    expect(find.text('报表估清'), findsOneWidget);
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(find.byType(SoldOutProductsScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('order home opens vip recharge without a pending dialog', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.order,
          stationId: '9',
          employeeId: '42',
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
          onSearchVipCards: (keyword) async => const Success([]),
          onLoadVipMember: (id) async => Success(
            VipMemberCard.fromWire({'id': id, 'card_no': 'C001', 'name': '张三'}),
          ),
          onLoadVipRules: (id) async => const Success([]),
          onCreateVipOrder: (body, {canDispatch}) async =>
              const Success(VipRechargeOrder(orderId: 'o', payId: 'p')),
          onCreateVipPay: ({
            required String payId,
            required int payAmtFen,
            required int payType,
            String authCode = '',
            bool Function()? canDispatch,
          }) async => const Success(VipRechargePay(scanUrl: '', payResult: 0)),
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.vipRechargeKey));
    await tester.pumpAndSettle();
    expect(find.byType(VipRechargeScreen), findsOneWidget);
    expect(find.text('输入手机号后四位或会员卡号'), findsOneWidget);
    expect(find.textContaining('该业务功能尚未接入'), findsNothing);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byType(VipRechargeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'order landscape footer keeps status counts on the vip recharge row',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 360));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            stationId: '9',
            employeeId: '42',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onSearchVipCards: (keyword) async => const Success([]),
            onLoadVipMember: (id) async => Success(
              VipMemberCard.fromWire({
                'id': id,
                'card_no': 'C001',
                'name': '张三',
              }),
            ),
            onLoadVipRules: (id) async => const Success([]),
            onCreateVipOrder: (body, {canDispatch}) async =>
                const Success(VipRechargeOrder(orderId: 'o', payId: 'p')),
            onCreateVipPay:
                ({
                  required String payId,
                  required int payAmtFen,
                  required int payType,
                  String authCode = '',
                  bool Function()? canDispatch,
                }) async =>
                    const Success(VipRechargePay(scanUrl: '', payResult: 0)),
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(),
        ),
      );
      await tester.pumpAndSettle();
      final empty = tester.getCenter(find.textContaining('空台').first);
      final vip = tester.getCenter(find.text('会员充值'));
      expect((empty.dy - vip.dy).abs(), lessThan(24));
      expect(empty.dx, lessThan(vip.dx));
    },
  );

  testWidgets(
    'order occupied card shows vue amounts person mark remark and turnover',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            stationId: '9',
            employeeId: '42',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _orderCardDisplayData(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
      await tester.pumpAndSettle();
      final occupied = find.byKey(CardTableScreen.cardKey('100'));
      expect(
        find.descendant(of: occupied, matching: find.text('点:￥4976.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: occupied, matching: find.text('惠:￥12.50')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: occupied, matching: find.text('100%')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: occupied, matching: find.text('抖')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: occupied, matching: find.text('(16:49)')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: occupied, matching: find.textContaining('大师兄')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: occupied, matching: find.textContaining('总经办')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: occupied, matching: find.text('转台测试')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: occupied, matching: find.text('翻2')),
        findsOneWidget,
      );
      final empty = find.byKey(CardTableScreen.cardKey('101'));
      expect(
        find.descendant(of: empty, matching: find.textContaining('点:￥')),
        findsNothing,
      );
      expect(
        find.descendant(of: empty, matching: find.textContaining('惠:￥')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'order home opens meal for an open table without a pending dialog',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            stationId: '9',
            employeeId: '42',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onAddOrderProduct: ({
              required String seatId,
              required String productId,
              required int count,
              required String price,
    String amount = '',
            }) async => const Success(null),
            onOrderCartCount: (seatId) async => const Success(0),
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
      await tester.pumpAndSettle();
      expect(find.byType(OrderMealScreen), findsOneWidget);
      final meal = tester.widget<OrderMealScreen>(find.byType(OrderMealScreen));
      expect(meal.fcPrices, isNotNull);
      expect(meal.fcPrices!.value.known, false);
      events.add(SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010102',
        data: [..._fullData(), [], [[101, 1, 1200, 1]], [[1, 42, 1]]],
      ));
      await tester.pumpAndSettle();
      expect(meal.fcPrices!.value.known, true);
      expect(meal.fcPrices!.value.resolve(productId:101, orderEmployeeId:42), 12);
      events.add(SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010103', data: {'58': [[101, 1, 0, 1]]},
      ));
      await tester.pumpAndSettle();
      expect(meal.fcPrices!.value.resolve(productId:101, orderEmployeeId:42), 0);
      expect(meal.orderSummaryVisibility, isNotNull);
      expect(meal.orderSummaryVisibility!.value, true);
      expect(meal.liveTableAmounts, isNotNull);
      final currentAmounts = [..._businessRow(100, status:4, orderAmount:4700.02), '1100.00'];
      events.add(SyncEnvelope.fromValidatedReconciliation(
        cursor:'20260828010104',data:{'14':[currentAmounts]},
      ));
      await tester.pumpAndSettle();
      expect(meal.table.orderAmount,120);
      expect(meal.liveTableAmounts!.value!.originalAmount(),5800.02);
      currentAmounts[38]=0;
      events.add(SyncEnvelope.fromValidatedReconciliation(
        cursor:'20260828010105',data:{'14':[currentAmounts]},
      ));
      await tester.pumpAndSettle();
      expect(meal.liveTableAmounts!.value!.originalAmount(),4700.02);
      currentAmounts[13]=2;
      currentAmounts[38]=800;
      events.add(SyncEnvelope.fromValidatedReconciliation(
        cursor:'20260828010106',data:{'14':[currentAmounts]},
      ));
      await tester.pumpAndSettle();
      expect(meal.liveTableAmounts!.value,isNull);
      expect(meal.table.orderAmount,120);
      events.add(SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010104', data: {'13': null},
      ));
      await tester.pumpAndSettle();
      expect(meal.orderSummaryVisibility!.value, false);
      expect(find.text('A01'), findsWidgets);
      expect(find.textContaining('该业务功能尚未接入'), findsNothing);
    },
  );

  testWidgets('order home opens change password without a pending dialog', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    var logoutCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.order,
          stationId: '9',
          employeeId: '42',
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
          onLogout: () async {
            logoutCalls += 1;
            return const Success(null);
          },
          onChangePassword: (oldPassword, newPassword) async =>
              const Success(null),
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.accountMenuKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('修改密码'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(find.textContaining('该业务功能尚未接入'), findsNothing);
    await tester.enterText(find.byKey(ChangePasswordScreen.oldKey), '123456');
    await tester.enterText(find.byKey(ChangePasswordScreen.newKey), '654321');
    await tester.enterText(
      find.byKey(ChangePasswordScreen.confirmKey),
      '654321',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pump();
    expect(find.text('修改密码成功，请重新登录'), findsOneWidget);
    expect(logoutCalls, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(logoutCalls, 1);
  });

  testWidgets('order home opens auth password without a pending dialog', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    var enabledCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.order,
          stationId: '9',
          employeeId: '42',
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
          onLoadAuthPasswordEnabled: () async {
            enabledCalls += 1;
            return const Success(true);
          },
          onChangeAuthPassword: ({
            required bool enabled,
            required String loginPassword,
            required String authPassword,
          }) async => const Success(null),
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.accountMenuKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('授权密码'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPasswordScreen), findsOneWidget);
    expect(find.text('开启授权密码'), findsOneWidget);
    expect(find.textContaining('该业务功能尚未接入'), findsNothing);
    expect(enabledCalls, 1);
  });

  testWidgets('booking account menu hides auth password', (tester) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.booking,
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
          onChangePassword: (oldPassword, newPassword) async =>
              const Success(null),
          onLoadAuthPasswordEnabled: () async => const Success(false),
          onChangeAuthPassword: ({
            required bool enabled,
            required String loginPassword,
            required String authPassword,
          }) async => const Success(null),
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.accountMenuKey));
    await tester.pumpAndSettle();
    expect(find.text('修改密码'), findsOneWidget);
    expect(find.text('授权密码'), findsNothing);
  });

  testWidgets('removed region closes picker and resets selection to mine', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.order,
          stationId: '9',
          employeeId: '42',
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    final expand = find.byKey(const Key('card-regions-expand'));
    final panel = find.byKey(const Key('card-regions-panel'));
    await tester.tap(expand);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: panel, matching: find.text('包厢')));
    await tester.pumpAndSettle();
    await tester.tap(expand);
    await tester.pumpAndSettle();
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010102',
        data: <String, Object?>{
          '0': <Object?>[
            <Object?>[2, '包厢', 2, 20],
          ],
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(panel, findsNothing);
    expect(
      tester.widget<ChoiceChip>(find.byKey(CardTableScreen.mineKey)).selected,
      isTrue,
    );
    expect(find.text('B01'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone region chooser reaches every region and can return to mine',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            stationId: '9',
            employeeId: '42',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
          ),
        ),
      );
      final data = _fullData();
      data[0] = [
        for (var i = 1; i <= 12; i++) [i, '区域$i', 1, i],
      ];
      data[1] = [
        for (var i = 1; i <= 12; i++) [i, 'T$i', 1, i, 1, 1, 4, i],
      ];
      data[14] = <Object?>[];
      data[39] = [
        for (var i = 1; i <= 12; i++) [1, i, 1],
      ];
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: data,
        ),
      );
      await tester.pumpAndSettle();
      final expand = find.byKey(const Key('card-regions-expand'));
      final panel = find.byKey(const Key('card-regions-panel'));
      expect(expand.hitTestable(), findsOneWidget);
      await tester.tap(expand);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: panel, matching: find.text('区域12')));
      await tester.pumpAndSettle();
      expect(panel, findsNothing);
      expect(find.text('T12'), findsOneWidget);
      expect(find.text('T1'), findsNothing);
      expect(find.text('空台 1'), findsOneWidget);
      expect(find.text('区域12').hitTestable(), findsWidgets);
      await tester.tap(expand);
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: panel, matching: find.text('我的卡台')));
      await tester.pumpAndSettle();
      expect(find.text('暂无服务过的卡台，快去点单吧！'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cashier turnover empty table exposes restore and history entries',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.cashier,
            stationId: '9',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
          ),
        ),
      );
      final data = _fullData();
      data[14] = <Object?>[_businessRow(101, status: 1, orderAmount: 0)];
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: data,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
      await tester.pumpAndSettle();
      expect(find.text('复台'), findsOneWidget);
      expect(find.text('查看卡台记录'), findsOneWidget);
      expect(find.text('预留'), findsNothing);
    },
  );

  testWidgets(
    'wine mode permits storing on turnover empty table but not withdrawing',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.order,
            stationId: '9',
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
          ),
        ),
      );
      final data = _fullData();
      data[14] = <Object?>[_businessRow(101, status: 1, orderAmount: 0)];
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: data,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.wineModeKey));
      await tester.pumpAndSettle();
      final card = find.byKey(CardTableScreen.cardKey('101'));
      expect(
        find.descendant(of: card, matching: find.text('存酒')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('取酒')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('充公')),
        findsOneWidget,
      );
    },
  );

  testWidgets('an open order menu closes when safe mode revokes it', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    final observer = BusinessRouteObserver();
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: CardTableScreen(
          businessRouteObserver: observer,
          system: BusinessSystem.order,
          stationId: '9',
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
    await tester.pumpAndSettle();
    expect(find.text('估清商品'), findsOneWidget);
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010102',
        data: <String, Object?>{
          '54': <Object?>[
            <Object?>[1, 1],
          ],
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('估清商品'), findsNothing);
    expect(find.byKey(CardTableScreen.moreFunctionsKey), findsNothing);
    expect(find.text('会员充值'), findsOneWidget);
    expect(find.text('存酒模式'), findsOneWidget);
  });

  testWidgets('order more menu never reuses booking system entries', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.order,
          stationId: '9',
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
    await tester.pumpAndSettle();
    expect(find.text('低消进度统计表'), findsOneWidget);
    expect(find.text('鸡尾酒明细表'), findsOneWidget);
    expect(find.text('估清商品'), findsOneWidget);
    expect(find.text('开台记录'), findsNothing);
    expect(find.text('预留记录'), findsNothing);
    expect(find.text('排队详情'), findsNothing);
  });

  testWidgets('order page defaults to mine without booking dates or search', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.order,
          stationId: '9',
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('我的卡台'), findsOneWidget);
    expect(
      find.widgetWithText(ChoiceChip, '我的卡台').evaluate().single.widget,
      isA<ChoiceChip>().having((c) => c.selected, 'selected', isTrue),
    );
    expect(find.text('今天'), findsNothing);
    expect(find.text('明天'), findsNothing);
    expect(find.byKey(CardTableScreen.searchKey), findsNothing);
    expect(find.text('暂无服务过的卡台，快去点单吧！'), findsOneWidget);
    expect(find.text('开台 0'), findsOneWidget);
    expect(find.text('会员充值'), findsOneWidget);
    expect(find.text('存酒模式'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
    await tester.pumpAndSettle();
    expect(find.text('A01'), findsOneWidget);
    await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
    await tester.pumpAndSettle();
    expect(find.text('空台/锁台/预定状态卡台不可点单！'), findsOneWidget);
    expect(find.text('充公'), findsNothing);
    await tester.tap(find.text('存酒模式'));
    await tester.pumpAndSettle();
    expect(find.text('点单模式'), findsOneWidget);
    expect(find.text('存酒'), findsWidgets);
  });

  testWidgets('late malformed full snapshot shows protocol failure and retry', (
    tester,
  ) async {
    final feed = (await tester.runAsync(() async => CardTableEventFeed()))!;
    addTearDown(() => tester.runAsync(feed.close));
    final data = _fullData();
    data[1] = <Object?>[
      <Object?>['invalid'],
    ];
    feed.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: data,
      ),
    );
    var refreshCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.booking,
          events: feed.events,
          connectionPhase: ConnectionPhase.online,
          onRefresh: () async {
            refreshCalls += 1;
            return const Success<void>(null);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('卡台数据格式无法识别'), findsOneWidget);
    await tester.tap(find.byKey(CardTableScreen.refreshKey));
    await tester.pumpAndSettle();
    expect(refreshCalls, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test(
    'card feed reset drops the previous session and closes cleanly',
    () async {
      final feed = CardTableEventFeed();
      feed.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(),
        ),
      );
      feed.reset();
      final replay = <SyncEnvelope>[];
      final subscription = feed.events.listen(replay.add);
      await Future<void>.delayed(Duration.zero);
      expect(replay, isEmpty);
      await subscription.cancel();
      await feed.close().timeout(const Duration(seconds: 1));
    },
  );
  testWidgets(
    'late card listener receives full state after buffered increments',
    (tester) async {
      final feed = (await tester.runAsync(() async => CardTableEventFeed()))!;
      addTearDown(() => tester.runAsync(feed.close));
      feed.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(),
        ),
      );
      feed.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010102',
          data: <String, Object?>{
            '1': <Object?>[
              <Object?>[101, 'A02更新', 1, 1, 3, 1, 4, 2],
            ],
          },
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: feed.events,
            connectionPhase: ConnectionPhase.online,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A01'), findsOneWidget);
      expect(find.text('A02更新'), findsOneWidget);
      expect(find.text('正在等待完整卡台数据'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  test('normalizes legacy full datasets 0, 1, 14, and 18', () {
    final store = LegacyCardTableStore();
    final result = store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );

    expect(result.failureOrNull, isNull);
    final snapshot = result.valueOrNull!;
    expect(snapshot.businessDayId, '9');
    expect(snapshot.businessOpen, isTrue);
    expect(snapshot.regions.map((region) => region.id), <String>['1', '2']);
    expect(snapshot.tables.map((table) => table.id), <String>[
      '100',
      '101',
      '200',
    ]);
    expect(snapshot.tables.last.businessStatus, 1);
    expect(snapshot.tables.first.name, 'A01');
    expect(snapshot.tables.first.businessStatus, 4);
    expect(snapshot.tables.first.customerName, '顾客');
    expect(snapshot.tables.first.orderAmount, 120);
    expect(snapshot.businessDates.map((date) => date.id), <String>[
      '20260828',
      '20260829',
    ]);
    expect(
      snapshot
          .tablesForDate('20260829')
          .firstWhere((table) => table.id == '101')
          .businessStatus,
      8,
    );
    expect(snapshot.statusCounts[20], 1);
    expect(snapshot.statusCountsForRegion('1')[1], 1);
    expect(snapshot.toString(), isNot(contains('顾客')));
  });

  test('applies incremental seat and business updates atomically', () {
    final store = LegacyCardTableStore();
    store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );

    final updated = store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010102',
        data: <String, Object?>{
          '1': <Object?>[
            <Object?>[101, 'A02', 3, 1, 3, 1, 4, 2],
          ],
          '14': <Object?>[_businessRow(100, status: 5, orderAmount: 200)],
        },
      ),
    );

    expect(updated.failureOrNull, isNull);
    expect(updated.valueOrNull!.tables.map((table) => table.id), <String>[
      '100',
      '200',
    ]);
    expect(updated.valueOrNull!.tables.first.businessStatus, 5);
    expect(updated.valueOrNull!.tables.first.orderAmount, 200);

    final beforeMalformed = store.currentSnapshot;
    final malformed = store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010103',
        data: <String, Object?>{
          '1': <Object?>[
            <Object?>['broken'],
          ],
        },
      ),
    );
    expect(malformed.failureOrNull?.code, 'protocol.card_table_shape');
    expect(identical(store.currentSnapshot, beforeMalformed), isTrue);
  });

  test('fails closed until a complete full snapshot arrives', () {
    final store = LegacyCardTableStore();
    final result = store.applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: <String, Object?>{
          '14': <Object?>[_businessRow(100, status: 4, orderAmount: 10)],
        },
      ),
    );
    expect(result.failureOrNull?.code, 'protocol.card_table_snapshot_required');
    expect(store.currentSnapshot, isNull);
  });

  test('applies source-aligned terminal region and card restrictions', () {
    final regionRestricted = LegacyCardTableStore(machineId: '77')
        .applyEnvelope(
          SyncEnvelope.fromValidatedReconciliation(
            cursor: '20260828010101',
            data: _fullData(
              machineAccess: <Object?>[
                <Object?>[77, 1, 1, 1],
              ],
            ),
          ),
        );
    expect(
      regionRestricted.valueOrNull!.tables.map((table) => table.id),
      <String>['100', '101'],
    );

    final cardRestricted = LegacyCardTableStore(machineId: '77').applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(
          machineAccess: <Object?>[
            <Object?>[77, 2, 1, 200],
          ],
        ),
      ),
    );
    expect(
      cardRestricted.valueOrNull!.tables.map((table) => table.id),
      <String>['200'],
    );

    final unrestricted = LegacyCardTableStore(machineId: '77').applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(
          machineAccess: <Object?>[
            <Object?>[77, 3, 1, 0],
          ],
        ),
      ),
    );
    expect(unrestricted.valueOrNull!.tables.length, 3);
  });

  test('limits supervisor card visibility to configured regions', () {
    final restricted = LegacyCardTableStore(stationId: '9').applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(
          roleRows: <Object?>[
            <Object?>[9, 11, 1],
          ],
          supervisorRegions: <Object?>[
            <Object?>[9, 2, 1],
          ],
        ),
      ),
    );
    expect(restricted.valueOrNull!.tables.map((table) => table.id), <String>[
      '200',
    ]);

    final fullAccess = LegacyCardTableStore(stationId: '9').applyEnvelope(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(
          roleRows: <Object?>[
            <Object?>[9, 11, 1],
          ],
          supervisorRegions: <Object?>[
            <Object?>[9, 0, 1],
          ],
        ),
      ),
    );
    expect(fullAccess.valueOrNull!.tables.length, 3);
  });

  testWidgets('renders source-aligned region and card filters', (tester) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    var switchCalls = 0;
    var refreshCalls = 0;
    var diagnosticsCalls = 0;
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.cashier,
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
          onSwitchSystem: () async {
            switchCalls += 1;
            return const Success<void>(null);
          },
          onRefresh: () async {
            refreshCalls += 1;
            return const Success<void>(null);
          },
          onOpenDiagnostics: () => diagnosticsCalls += 1,
          userName: '系统管理员',
        ),
      ),
    );
    expect(find.text('正在等待完整卡台数据'), findsOneWidget);

    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('收银 · 卡台列表')), findsOneWidget);
    expect(find.text('大厅'), findsWidgets);
    expect(find.text('包厢'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(CardTableScreen.gridKey),
        matching: find.text('A01'),
      ),
      findsOneWidget,
    );
    expect(find.text('A02'), findsOneWidget);
    expect(find.text('B01'), findsOneWidget);
    expect(find.text('今天'), findsNothing);
    expect(find.text('明天'), findsNothing);
    expect(find.text('空台 2'), findsOneWidget);
    expect(find.text('预订 0'), findsOneWidget);
    expect(find.text('开台 0'), findsOneWidget);
    expect(find.text('抵达数 1'), findsOneWidget);
    expect(find.text('顾客'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, '大厅'));
    await tester.pump();
    expect(find.text('空台 1'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
    await tester.pump();

    await tester.enterText(find.byKey(CardTableScreen.searchKey), 'A01');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(CardTableScreen.gridKey),
        matching: find.text('A01'),
      ),
      findsOneWidget,
    );
    expect(find.text('A02'), findsNothing);
    expect(find.text('B01'), findsNothing);

    await tester.tap(find.byKey(CardTableScreen.accountMenuKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.switchSystemKey));
    await tester.pumpAndSettle();
    expect(switchCalls, 1);
    await tester.tap(find.byKey(CardTableScreen.refreshKey));
    await tester.pumpAndSettle();
    expect(refreshCalls, 1);
    await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
    await tester.pumpAndSettle();
    expect(find.text('班结表'), findsOneWidget);
    expect(find.text('开台记录'), findsNothing);
    expect(diagnosticsCalls, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.accountMenuKey));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(CardTableScreen.openDiagnosticsKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.openDiagnosticsKey));
    await tester.pumpAndSettle();
    expect(diagnosticsCalls, 1);
  });

  testWidgets('booking empty card opens the source-aligned action menu', (
    tester,
  ) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.booking,
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byKey(CardTableScreen.cardMenuKey), findsOneWidget);
    expect(_menuText('预留'), findsOneWidget);
    expect(_menuText('开台'), findsOneWidget);
    expect(_menuText('锁定'), findsOneWidget);
    expect(_menuText('置顶'), findsOneWidget);
    expect(_menuText('取消锁定'), findsNothing);
    final cardRect = tester.getRect(find.byKey(CardTableScreen.cardKey('101')));
    final menuRect = tester.getRect(find.byKey(CardTableScreen.cardMenuKey));
    final screen = tester.getSize(find.byType(MaterialApp));
    expect((menuRect.center.dy - cardRect.center.dy).abs(), lessThan(180));
    expect(menuRect.top, lessThan(screen.height - 80));
    expect(menuRect.bottom, isNot(closeTo(screen.height, 1)));
    await tester.tap(_menuText('关闭'));
    await tester.pumpAndSettle();
    expect(find.byKey(CardTableScreen.cardMenuKey), findsNothing);
  });

  testWidgets('booking lock confirms then writes the seat id', (tester) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    final writes = <({String action, String seatId, String bookId})>[];
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.booking,
          events: events.stream,
          connectionPhase: ConnectionPhase.online,
          onBookingCardWrite:
              ({
                required BookingCardWriteAction action,
                required String seatId,
                String bookId = '',
                Map<String, Object?> fields = const <String, Object?>{},
                bool Function()? canDispatch,
              }) async {
                writes.add((
                  action: action.name,
                  seatId: seatId,
                  bookId: bookId,
                ));
                return const Success(null);
              },
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CardTableScreen.cardKey('101')));
    await tester.pumpAndSettle();
    await tester.tap(_menuText('锁定'));
    await tester.pumpAndSettle();
    expect(find.text('锁定卡台'), findsOneWidget);
    expect(find.textContaining('锁定后该卡台除取消锁定外，其他功能均不能使用'), findsOneWidget);
    expect(find.text('功能正在迁移'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(writes, [(action: 'lock', seatId: '101', bookId: '')]);
    expect(find.text('操作成功！'), findsOneWidget);
  });

  testWidgets('booking lock cancel does not write', (tester) async {
    final writes = await _openBookingMenu(tester, seatId: '101');
    await tester.tap(_menuText('锁定'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();
    expect(writes, isEmpty);
    expect(find.text('操作成功！'), findsNothing);
  });

  testWidgets('booking unlock confirms then writes the seat id', (
    tester,
  ) async {
    final writes = await _openBookingMenu(
      tester,
      seatId: '101',
      data: _bookingSeatData(101, status: 2),
    );
    expect(_menuText('取消锁定'), findsOneWidget);
    expect(_menuText('锁定'), findsNothing);
    await tester.tap(_menuText('取消锁定'));
    await tester.pumpAndSettle();
    expect(find.text('取消锁定'), findsWidgets);
    expect(find.text('是否确认取消锁定？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'unlock');
    expect(writes.single.seatId, '101');
    expect(find.text('操作成功！'), findsOneWidget);
  });

  testWidgets('booking cancel open confirms then writes the seat id', (
    tester,
  ) async {
    final writes = await _openBookingMenu(tester, seatId: '100');
    await tester.tap(_menuText('撤台'));
    await tester.pumpAndSettle();
    expect(find.text('撤台'), findsWidgets);
    expect(find.text('是否确认撤台操作？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'cancelOpen');
    expect(writes.single.seatId, '100');
    expect(find.text('操作成功！'), findsOneWidget);
  });

  testWidgets('booking cancel reserve writes the book id', (tester) async {
    final writes = await _openBookingMenu(
      tester,
      seatId: '101',
      data: _bookingSeatData(101, status: 8, bookId: 88, platformId: 0),
    );
    expect(_menuText('取消预留'), findsOneWidget);
    await tester.tap(_menuText('取消预留'));
    await tester.pumpAndSettle();
    expect(find.text('是否确认取消预留'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'cancelReserve');
    expect(writes.single.bookId, '88');
    expect(find.text('操作成功！'), findsOneWidget);
  });

  testWidgets('booking online reserved current day hides cancel reserve', (
    tester,
  ) async {
    await _openBookingMenu(
      tester,
      seatId: '101',
      data: _bookingSeatData(101, status: 8, bookId: 88, platformId: 1),
    );
    expect(_menuText('开台'), findsOneWidget);
    expect(_menuText('转台'), findsOneWidget);
    expect(_menuText('取消预留'), findsNothing);
    expect(_menuText('修改预留'), findsNothing);
  });

  testWidgets('booking pin writes without a confirm dialog', (tester) async {
    final writes = await _openBookingMenu(tester, seatId: '101');
    expect(_menuText('取消置顶'), findsNothing);
    await tester.tap(_menuText('置顶'));
    await tester.pumpAndSettle();
    expect(find.text('锁定卡台'), findsNothing);
    expect(find.text('是否确认锁定卡台，锁定后该卡台除取消锁定外，其他功能均不能使用'), findsNothing);
    expect(writes.single.action, 'pin');
    expect(writes.single.seatId, '101');
    expect(find.text('置顶成功'), findsOneWidget);
  });

  testWidgets('booking unpin writes without a confirm dialog', (tester) async {
    final data = _fullData();
    data[29] = <Object?>[
      <Object?>[101, 2, 1],
    ];
    final writes = await _openBookingMenu(tester, seatId: '101', data: data);
    await tester.tap(_menuText('取消置顶'));
    await tester.pumpAndSettle();
    expect(find.text('是否确认取消预留'), findsNothing);
    expect(writes.single.action, 'unpin');
    expect(writes.single.seatId, '101');
    expect(find.text('取消置成功'), findsOneWidget);
  });

  testWidgets(
    'booking disable must order confirms and reports Vue success copy',
    (tester) async {
      final data = _fullData();
      data[0] = <Object?>[
        <Object?>[2, '包厢', 1, 20, 0, 0, 0],
        <Object?>[1, '大厅', 1, 10, 99, 0, 0],
        <Object?>[3, '停用', 2, 30, 0, 0, 0],
      ];
      final writes = await _openBookingMenu(tester, seatId: '100', data: data);
      await tester.ensureVisible(_menuText('取消必点商品'));
      await tester.pumpAndSettle();
      await tester.tap(_menuText('取消必点商品'));
      await tester.pumpAndSettle();
      expect(find.text('取消必点商品'), findsWidgets);
      expect(find.text('是否确认取消必点商品?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '确定'));
      await tester.pumpAndSettle();
      expect(writes.single.action, 'disableMustOrder');
      expect(writes.single.seatId, '100');
      expect(find.text('取消必点商品成功'), findsOneWidget);
      expect(find.text('操作成功！'), findsNothing);
    },
  );

  testWidgets(
    'booking disable must order stays inert without region products',
    (tester) async {
      final writes = await _openBookingMenu(tester, seatId: '100');
      await tester.ensureVisible(_menuText('取消必点商品'));
      await tester.pumpAndSettle();
      await tester.tap(_menuText('取消必点商品'));
      await tester.pumpAndSettle();
      expect(find.text('是否确认取消必点商品?'), findsNothing);
      expect(writes, isEmpty);
    },
  );

  testWidgets('booking ordered card omits cancel open and disable must order', (
    tester,
  ) async {
    await _openBookingMenu(
      tester,
      seatId: '100',
      data: _bookingSeatData(100, status: 5),
    );
    expect(_menuText('撤台'), findsNothing);
    expect(_menuText('取消必点商品'), findsNothing);
    expect(_menuText('转台'), findsOneWidget);
    expect(_menuText('置顶'), findsOneWidget);
  });

  testWidgets('booking min consume form writes Vue amount payload', (
    tester,
  ) async {
    final writes = await _openBookingMenu(tester, seatId: '100');
    await tester.ensureVisible(_menuText('修改低消'));
    await tester.pumpAndSettle();
    await tester.tap(_menuText('修改低消'));
    await tester.pumpAndSettle();
    expect(find.text('修改低消'), findsWidgets);
    expect(find.text('功能正在迁移'), findsNothing);
    await tester.enterText(
      find.byKey(CardTableScreen.bookingFormFieldKey),
      '200',
    );
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'updateMinConsume');
    expect(writes.single.seatId, '100');
    expect(writes.single.fields['min_csm_amt'], '200');
    expect(find.text('修改低消金额操作成功！'), findsOneWidget);
  });

  testWidgets('booking remark form writes Vue remark payload', (tester) async {
    final writes = await _openBookingMenu(tester, seatId: '100');
    await tester.ensureVisible(_menuText('修改备注'));
    await tester.pumpAndSettle();
    await tester.tap(_menuText('修改备注'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(CardTableScreen.bookingFormFieldKey),
      '转台测试',
    );
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'updateRemark');
    expect(writes.single.fields['remark'], '转台测试');
    expect(find.text('修改卡台备注成功！'), findsOneWidget);
  });

  testWidgets('booking card detail shows source fields without writing', (
    tester,
  ) async {
    final writes = await _openBookingMenu(tester, seatId: '100');
    await tester.ensureVisible(_menuText('查看卡台详情'));
    await tester.pumpAndSettle();
    await tester.tap(_menuText('查看卡台详情'));
    await tester.pumpAndSettle();
    expect(find.text('查看卡台详情'), findsWidgets);
    expect(find.text('卡台名称：A01'), findsOneWidget);
    expect(find.textContaining('尚未接入'), findsNothing);
    expect(writes, isEmpty);
    await tester.tap(find.widgetWithText(TextButton, '关闭'));
    await tester.pumpAndSettle();
  });

  testWidgets('booking turnover sales warns when the table never turned over', (
    tester,
  ) async {
    final data = _bookingSeatData(100, status: 4);
    final row = (data[14]! as List<Object?>).cast<List<Object?>>().firstWhere(
      (item) => item[0] == 100,
    );
    row[13] = 0;
    await _openBookingMenu(tester, seatId: '100', data: data);
    await tester.ensureVisible(_menuText('修改翻台订位人'));
    await tester.pumpAndSettle();
    await tester.tap(_menuText('修改翻台订位人'));
    await tester.pumpAndSettle();
    expect(find.text('当前卡台没有翻过台！'), findsOneWidget);
    expect(find.text('功能正在迁移'), findsNothing);
  });

  testWidgets('booking clear seat confirms on settled tables with permission', (
    tester,
  ) async {
    final data = _bookingSeatData(100, status: 7);
    data[35] = <Object?>[
      <Object?>[5, 2],
    ];
    final writes = await _openBookingMenu(tester, seatId: '100', data: data);
    await tester.ensureVisible(_menuText('清台'));
    await tester.pumpAndSettle();
    await tester.tap(_menuText('清台'));
    await tester.pumpAndSettle();
    expect(find.text('是否确认清台'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'clearSeat');
    expect(find.text('操作成功！'), findsOneWidget);
  });

  testWidgets('booking convert offline confirms on online empty cards', (
    tester,
  ) async {
    final data = _fullData();
    data[26] = <Object?>[
      <Object?>[101, 1],
    ];
    final writes = await _openBookingMenu(tester, seatId: '101', data: data);
    expect(_menuText('转为线下卡台'), findsOneWidget);
    expect(_menuText('锁定'), findsNothing);
    await tester.tap(_menuText('转为线下卡台'));
    await tester.pumpAndSettle();
    expect(find.text('是否确认将此卡台临时转为线下卡台'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'convertOffline');
    expect(find.text('转线下操作中，请稍后...'), findsOneWidget);
  });

  testWidgets('booking empty open submits Vue direct open payload', (
    tester,
  ) async {
    final writes = await _openBookingMenu(tester, seatId: '101');
    await tester.tap(_menuText('开台'));
    await tester.pumpAndSettle();
    expect(find.text('开台'), findsWidgets);
    expect(find.textContaining('尚未接入'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'openEmpty');
    expect(writes.single.seatId, '101');
    expect(writes.single.fields['customer_cnt'], 4);
    expect(find.text('开台成功！'), findsOneWidget);
  });

  testWidgets('booking open rejects a phone that is not eleven digits', (
    tester,
  ) async {
    final writes = await _openBookingMenu(tester, seatId: '101');
    await tester.tap(_menuText('开台'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(CardTableScreen.bookingFormPhoneKey), '123');
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(find.text('请输入正确的手机号'), findsOneWidget);
    expect(writes, isEmpty);
  });

  testWidgets('booking reserve submits Vue batch new payload', (tester) async {
    final writes = await _openBookingMenu(tester, seatId: '101');
    await tester.tap(_menuText('预留'));
    await tester.pumpAndSettle();
    expect(find.text('新建预留'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'createReserve');
    expect(writes.single.fields['exp_seat_id'], '101');
    expect(writes.single.fields['book_day'], '2026-08-28');
    expect(writes.single.fields['is_this_wkday'], 1);
    expect(find.text('新增成功'), findsOneWidget);
  });

  testWidgets('booking reserved open posts the book id', (tester) async {
    final writes = await _openBookingMenu(
      tester,
      seatId: '101',
      data: _bookingSeatData(101, status: 8, bookId: 88, platformId: 0),
    );
    await tester.tap(_menuText('开台'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'openReserve');
    expect(writes.single.bookId, '88');
    expect(find.text('开台成功！'), findsOneWidget);
  });

  testWidgets('booking edit reserve loads detail then saves', (tester) async {
    var loaded = '';
    final writes = await _openBookingMenu(
      tester,
      seatId: '101',
      data: _bookingSeatData(101, status: 8, bookId: 88, platformId: 0),
      onLoadBookDetail: (bookId) async {
        loaded = bookId;
        return const Success(
          BookingBookDetail(customerName: '张三', customerPhone: '13800000000'),
        );
      },
    );
    await tester.tap(_menuText('修改预留'));
    await tester.pumpAndSettle();
    expect(loaded, '88');
    expect(find.text('修改预留'), findsOneWidget);
    expect(find.text('张三'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'updateReserve');
    expect(writes.single.bookId, '88');
    expect(find.text('修改成功'), findsOneWidget);
  });

  testWidgets('booking opened table transfer submits transferOpen payload', (
    tester,
  ) async {
    final writes = await _openBookingMenu(tester, seatId: '100');
    await tester.tap(_menuText('转台'));
    await tester.pumpAndSettle();
    expect(find.text('转台'), findsWidgets);
    expect(find.text('原卡台：A01'), findsOneWidget);
    expect(find.text('新卡台低消'), findsOneWidget);
    await tester.enterText(
      find.byKey(CardTableScreen.bookingTransferMinConsumeKey),
      '500',
    );
    await tester.tap(find.widgetWithText(FilledButton, '确认转台'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'transferOpen');
    expect(writes.single.seatId, '100');
    expect(writes.single.fields['dest_seat_id'], '101');
    expect(writes.single.fields['new_min_csm_amt'], 500);
    expect(find.text('转台成功'), findsOneWidget);
  });

  testWidgets('booking reserved table transfer submits transferReserve payload', (
    tester,
  ) async {
    final data = _bookingSeatData(100, status: 8, bookId: 88, platformId: 0);
    final writes = await _openBookingMenu(
      tester,
      seatId: '100',
      data: data,
    );
    await tester.tap(_menuText('转台'));
    await tester.pumpAndSettle();
    expect(find.text('转台'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, '确认转台'));
    await tester.pumpAndSettle();
    expect(writes.single.action, 'transferReserve');
    expect(writes.single.seatId, '100');
    expect(writes.single.bookId, '88');
    expect(writes.single.fields['dest_seat_id'], '101');
    expect(find.text('转台成功'), findsOneWidget);
  });

  testWidgets('booking transfer warns when no empty table is available', (
    tester,
  ) async {
    final data = _fullData();
    data[14] = <Object?>[
      _businessRow(100, status: 4, orderAmount: 120),
      _businessRow(101, status: 4, orderAmount: 120),
      _businessRow(200, status: 4, orderAmount: 50),
    ];
    final writes = await _openBookingMenu(tester, seatId: '100', data: data);
    await tester.tap(_menuText('转台'));
    await tester.pumpAndSettle();
    expect(find.text('当前暂无可转入的空卡台'), findsOneWidget);
    expect(writes, isEmpty);
  });

  testWidgets('booking open rejects customer count less than 1', (
    tester,
  ) async {
    final data = _fullData();
    data[1] = <Object?>[
      <Object?>[101, 'A02', 1, 1, 3, 1, 0, 2],
      <Object?>[100, 'A01', 1, 1, 3, 1, 6, 1],
      <Object?>[200, 'B01', 1, 2, 4, 1, 8, 1],
    ];
    final writes = await _openBookingMenu(tester, seatId: '101', data: data);
    await tester.tap(_menuText('开台'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets);
    await tester.enterText(
      find.widgetWithText(TextFormField, '到店人数'),
      '0',
    );
    await tester.tap(find.widgetWithText(FilledButton, '确认'));
    await tester.pumpAndSettle();
    expect(find.text('请输入有效的到店人数 (1-100)'), findsOneWidget);
    expect(writes, isEmpty);
  });

  testWidgets(
    'closed business day keeps cards visible and booking can open it',
    (tester) async {
      final events = StreamController<SyncEnvelope>.broadcast(sync: true);
      var openCalls = 0;
      addTearDown(events.close);
      await tester.pumpWidget(
        MaterialApp(
          home: CardTableScreen(
            system: BusinessSystem.booking,
            events: events.stream,
            connectionPhase: ConnectionPhase.online,
            onOpenBusinessDay: () async {
              openCalls += 1;
              return const Success<void>(null);
            },
          ),
        ),
      );
      events.add(
        SyncEnvelope.fromValidatedReconciliation(
          cursor: '20260828010101',
          data: _fullData(businessDayId: 0),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('营业日未开启'), findsOneWidget);
      expect(find.byKey(CardTableScreen.openBusinessDayKey), findsOneWidget);
      expect(find.text('A01'), findsOneWidget);
      expect(find.text('A02'), findsOneWidget);

      await tester.tap(find.byKey(CardTableScreen.openBusinessDayKey));
      await tester.pumpAndSettle();
      expect(find.text('是否确认开启营业日？'), findsOneWidget);
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(openCalls, 1);
      expect(find.text('开启请求已提交，等待服务端同步'), findsOneWidget);
    },
  );

  testWidgets('only online booking can start a business day', (tester) async {
    final events = StreamController<SyncEnvelope>.broadcast(sync: true);
    addTearDown(events.close);
    await tester.pumpWidget(
      MaterialApp(
        home: CardTableScreen(
          system: BusinessSystem.booking,
          events: events.stream,
          connectionPhase: ConnectionPhase.blocked,
          onOpenBusinessDay: () async => const Success<void>(null),
        ),
      ),
    );
    events.add(
      SyncEnvelope.fromValidatedReconciliation(
        cursor: '20260828010101',
        data: _fullData(businessDayId: 0),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(CardTableScreen.openBusinessDayKey))
          .onPressed,
      isNull,
    );
  });
}

Finder _menuText(String text) => find.descendant(
  of: find.byKey(CardTableScreen.cardMenuKey),
  matching: find.text(text),
);

Future<
  List<
    ({String action, String seatId, String bookId, Map<String, Object?> fields})
  >
>
_openBookingMenu(
  WidgetTester tester, {
  required String seatId,
  List<Object?>? data,
  Future<Result<BookingBookDetail>> Function(String bookId)? onLoadBookDetail,
}) async {
  final events = StreamController<SyncEnvelope>.broadcast(sync: true);
  addTearDown(events.close);
  final writes =
      <
        ({
          String action,
          String seatId,
          String bookId,
          Map<String, Object?> fields,
        })
      >[];
  await tester.pumpWidget(
    MaterialApp(
      home: CardTableScreen(
        system: BusinessSystem.booking,
        events: events.stream,
        connectionPhase: ConnectionPhase.online,
        onLoadBookDetail: onLoadBookDetail,
        onBookingCardWrite:
            ({
              required BookingCardWriteAction action,
              required String seatId,
              String bookId = '',
              Map<String, Object?> fields = const <String, Object?>{},
              bool Function()? canDispatch,
            }) async {
              writes.add((
                action: action.name,
                seatId: seatId,
                bookId: bookId,
                fields: Map<String, Object?>.from(fields),
              ));
              return const Success(null);
            },
      ),
    ),
  );
  events.add(
    SyncEnvelope.fromValidatedReconciliation(
      cursor: '20260828010101',
      data: data ?? _fullData(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(CardTableScreen.cardKey(seatId)));
  await tester.pumpAndSettle();
  return writes;
}

List<Object?> _bookingSeatData(
  int seatId, {
  required int status,
  Object? bookId,
  int platformId = 0,
}) {
  final data = _fullData();
  final row = _businessRow(seatId, status: status, orderAmount: 0);
  if (bookId != null) row[1] = bookId;
  row[22] = platformId;
  final current = List<Object?>.of(data[14]! as List<Object?>);
  current.removeWhere((item) => (item as List<Object?>)[0] == seatId);
  current.add(row);
  data[14] = current;
  return data;
}

List<Object?> _orderCardDisplayData() {
  final data = _fullData(
    roleRows: <Object?>[
      <Object?>[9, 3, 1],
    ],
  );
  data[5] = <Object?>[
    <Object?>[23, '大师兄', 1, 8, 1, 1, '', 'DSX', 'E23', 0, 0, '大师兄'],
  ];
  data[6] = <Object?>[
    <Object?>[8, '总经办', 1, 0],
  ];
  data[41] = <Object?>[
    <Object?>[9, 5, 1],
    <Object?>[9, 1, 1],
    <Object?>[9, 91, 1],
    <Object?>[9, 12, 1],
  ];
  final occupied = _businessRow(100, status: 5, orderAmount: 4976);
  occupied[5] = '20260828164900';
  occupied[10] = 4976;
  occupied[11] = 10;
  occupied[12] = 2.5;
  occupied[13] = 2;
  occupied[14] = 23;
  occupied[24] = '转台测试';
  occupied[25] = '抖';
  occupied[30] = 0;
  occupied[31] = 4976;
  data[14] = <Object?>[
    occupied,
    _businessRow(200, status: 22, orderAmount: 50),
  ];
  return data;
}

List<Object?> _fullData({
  int businessDayId = 9,
  List<Object?> machineAccess = const <Object?>[],
  List<Object?> roleRows = const <Object?>[],
  List<Object?> supervisorRegions = const <Object?>[],
}) {
  final data = List<Object?>.filled(57, const <Object?>[]);
  data[0] = <Object?>[
    <Object?>[2, '包厢', 1, 20, 0, 0, 0],
    <Object?>[1, '大厅', 1, 10, 0, 0, 0],
    <Object?>[3, '停用', 2, 30, 0, 0, 0],
  ];
  data[1] = <Object?>[
    <Object?>[101, 'A02', 1, 1, 3, 1, 4, 2],
    <Object?>[100, 'A01', 1, 1, 3, 1, 6, 1],
    <Object?>[200, 'B01', 1, 2, 4, 1, 8, 1],
    <Object?>[300, '删除台', 3, 1, 3, 1, 2, 3],
  ];
  data[14] = <Object?>[
    _businessRow(100, status: 4, orderAmount: 120),
    _businessRow(200, status: 22, orderAmount: 50),
  ];
  data[18] = <Object?>[
    <Object?>[businessDayId, '', '测试门店'],
  ];
  data[24] = <Object?>[
    <Object?>['今天', '20260828'],
    <Object?>['明天', '20260829'],
  ];
  data[25] = <Object?>[
    <Object?>[
      '20260829',
      101,
      'future-book-1',
      '20260829120000',
      '20260829123000',
      1,
      '未来顾客',
      '',
      6,
      1,
      0,
      0,
      '',
      'WLGK',
    ],
  ];
  data[39] = <Object?>[
    <Object?>[1, 0, 2],
    <Object?>[3, 0, 2],
    <Object?>[4, 0, 1],
    <Object?>[20, 0, 1],
    <Object?>[1, 1, 1],
    <Object?>[4, 1, 1],
    <Object?>[20, 1, 1],
    <Object?>[1, 2, 1],
  ];
  data[40] = machineAccess;
  data[13] = roleRows;
  data[41] = <Object?>[
    <Object?>[9, 5, 1],
    <Object?>[9, 1, 1],
    <Object?>[9, 91, 1],
  ];
  data[56] = supervisorRegions;
  return data;
}

List<Object?> _businessRow(
  int seatId, {
  required int status,
  required num orderAmount,
}) {
  final row = List<Object?>.filled(38, null);
  row[0] = seatId;
  row[2] = '20260828120000';
  row[5] = '20260828123000';
  row[6] = orderAmount;
  row[7] = 0;
  row[8] = 20;
  row[9] = 0;
  row[10] = 0;
  row[11] = 0;
  row[12] = 0;
  row[13] = 1;
  row[16] = '顾客';
  row[17] = '';
  row[18] = 4;
  row[19] = status;
  row[20] = '';
  row[24] = '';
  row[25] = '';
  return row;
}
