import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:card_table/card_table.dart';
import 'package:design_system/design_system.dart';
import 'package:device_bridge_android/device_bridge_android.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol/protocol.dart';
import 'package:realtime_sync/realtime_sync.dart';
import 'package:session/session.dart';
import 'package:shouyin_android/main.dart';

void main() {
  for (final system in [BusinessSystem.cashier, BusinessSystem.order]) {
    for (final nextStation in ['2', '1']) {
      testWidgets(
        '${system.name} owned routes close on ${nextStation == '1' ? 'same-account relogin' : 'actor replacement'}',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1500, 1000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final factory = _LifecycleFactory();
          await tester.pumpWidget(
            ShouyinAndroidApp(
              environment: _validEnvironment,
              dependenciesFactory: factory,
            ),
          );
          await tester.pumpAndSettle();
          final d = factory.dependencies;
          d.adapter.stationId = '1';
          await tester.runAsync(() async {
            await d.sessionRepository.authorizeMachine(
              'loopback-development-${system.client.clientName}',
            );
            await d.sessionRepository.login(
              account: 'actor-a',
              password: 'synthetic-password',
              type: EmployeeLoginType.account,
            );
          });
          await tester.pumpAndSettle();
          final actorA = d.sessionRepository.currentUser;
          final raw = List<Object?>.filled(60, const <Object?>[]);
          raw[0] = [
            [1, '大厅', 1, 1],
          ];
          raw[1] = [
            [100, '旧卡台A01', 1, 1, 1, 1, 4, 1],
          ];
          final row = List<Object?>.filled(38, null);
          row[0] = 100;
          row[2] = '';
          row[5] = '';
          for (final i in [6, 7, 8, 9, 10, 11, 12]) {
            row[i] = 0;
          }
          row[13] = 1;
          row[16] = '';
          row[17] = '';
          row[18] = 1;
          row[19] = 4;
          row[20] = '';
          row[24] = '';
          row[25] = '';
          raw[14] = [row];
          raw[18] = [
            [9, '', '门店'],
          ];
          raw[13] = [
            [1, system == BusinessSystem.cashier ? 5 : 2, 1],
          ];
          raw[41] = [
            [1, 1, 1],
          ];
          raw[54] = [
            [1, 0],
          ];
          d.emitEvent(
            SyncEnvelope.fromValidatedReconciliation(
              cursor: '20260920100000',
              data: raw,
            ),
          );
          await tester.pumpAndSettle();
          if (system == BusinessSystem.order) {
            await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byKey(CardTableScreen.cardKey('100')));
          await tester.pumpAndSettle();
          final page = system == BusinessSystem.cashier
              ? find.byType(PayOrderScreen)
              : find.byType(OrderMealScreen);
          expect(page, findsOneWidget);
          final oldState = tester.state(page);
          if (system == BusinessSystem.cashier) {
            final pay = tester.widget<PayOrderScreen>(page);
            expect(pay.moveOrder, isNotNull);
            expect(pay.movePayedOrder, isNotNull);
            expect(pay.verifyPaidTransfer, isNotNull);
            expect(pay.paidTransfersNeedingVerification, isNotNull);
            expect(pay.batchUpdateOrderWaiter, isNotNull);
            expect(pay.batchUpdateOrderAuther, isNotNull);
            await tester.tap(find.byKey(PayOrderScreen.cleanKey));
            await tester.pumpAndSettle();
            expect(find.text('确定要对卡台 旧卡台A01 清台吗？'), findsOneWidget);
          }
          d.adapter.stationId = nextStation;
          await tester.runAsync(
            () => d.sessionRepository.login(
              account: nextStation == '1' ? 'actor-a' : 'actor-b',
              password: 'synthetic-password',
              type: EmployeeLoginType.account,
            ),
          );
          await tester.pumpAndSettle();
          expect(identical(actorA, d.sessionRepository.currentUser), false);
          expect(d.stopCalls, 1);
          expect(d.startCalls, 2);
          expect(find.byType(PayOrderScreen), findsNothing);
          expect(find.byType(OrderMealScreen), findsNothing);
          expect(find.text('确定要对卡台 旧卡台A01 清台吗？'), findsNothing);
          expect(oldState.mounted, false);
          expect(d.auditedBusinessWrites, 0);
        },
      );
    }
  }

  testWidgets(
    'management metadata reaches navigation and revokes personnel live',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final factory = _LifecycleFactory();
      await tester.pumpWidget(
        ShouyinAndroidApp(
          environment: _validEnvironment,
          dependenciesFactory: factory,
        ),
      );
      await tester.pumpAndSettle();
      factory.dependencies.adapter.stationId = '1';
      await tester.runAsync(() async {
        await factory.dependencies.sessionRepository.authorizeMachine(
          'loopback-development-org_mgr',
        );
        await factory.dependencies.sessionRepository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
      });
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BmsNavScreen>(find.byType(BmsNavScreen))
            .permissions!
            .available,
        false,
      );
      final data = List<Object?>.filled(55, null);
      data[13] = [
        [1, 6, 1],
      ];
      data[41] = <Object?>[];
      data[54] = [
        [1, 0],
      ];
      factory.dependencies.emitEvent(
        SyncEnvelope.parse({'p': 1, 't': '20260920100000', 'd': data})
            .valueOrNull!,
      );
      await tester.pumpAndSettle();
      final page = tester.widget<BmsNavScreen>(find.byType(BmsNavScreen));
      expect(page.permissions!.available, true);
      expect(page.onChangePassword, isNotNull);
      expect(page.routeObserver, isNotNull);
      expect(find.text('人员管理'), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('修改密码'));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
      factory.dependencies.adapter.stationId = '2';
      await tester.runAsync(
        () => factory.dependencies.sessionRepository.login(
          account: 'second-employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        ),
      );
      await tester.pumpAndSettle();
      expect(factory.dependencies.stopCalls, 1);
      expect(factory.dependencies.startCalls, 2);
      expect(find.byType(ChangePasswordScreen), findsNothing);
      final changedPage = tester.widget<BmsNavScreen>(
        find.byType(BmsNavScreen),
      );
      expect(changedPage.permissions!.available, false);
      expect(changedPage.key, isNot(page.key));
      data[13] = [
        [2, 6, 1],
      ];
      factory.dependencies.emitEvent(
        SyncEnvelope.parse({'p': 1, 't': '20260920100002', 'd': data})
            .valueOrNull!,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BmsNavScreen>(find.byType(BmsNavScreen))
            .permissions!
            .stationId,
        2,
      );
      factory.dependencies.emitEvent(
        SyncEnvelope.parse({
          'p': 1,
          't': '20260920100001',
          'd': {
            '54': [
              [1, 1],
            ],
          },
        }).valueOrNull!,
      );
      await tester.pumpAndSettle();
      expect(find.text('人员管理'), findsNothing);
      factory.dependencies.managementFeed.setPhase(ConnectionPhase.blocked);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BmsNavScreen>(find.byType(BmsNavScreen))
            .permissions!
            .available,
        false,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => factory.dependencies.disposed.future);
    },
  );
  for (final client in [ClientKind.erp, ClientKind.erpAdmin]) {
    testWidgets('ERP ${client.name} keeps terminal role and can visit home', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final factory = _LifecycleFactory();
      await tester.pumpWidget(
        ShouyinAndroidApp(
          environment: _validEnvironment,
          dependenciesFactory: factory,
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await factory.dependencies.sessionRepository.authorizeMachine(
          'loopback-development-${client.clientName}',
        );
        await factory.dependencies.sessionRepository.login(
          account: 'employee',
          password: 'synthetic-password',
          type: EmployeeLoginType.account,
        );
      });
      await tester.pumpAndSettle();
      expect(find.byType(ErpNavScreen), findsOneWidget);
      final screen = tester.widget<ErpNavScreen>(find.byType(ErpNavScreen));
      expect((screen.loader as ProtocolErpLoader).api.clientKind, client);
      expect(screen.onPrintDocument, isNotNull);
      var documentCalls = 0;
      final scope = tester.widget<ProviderScope>(
        find.byType(ProviderScope).last,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ErpNavScreen)),
      );
      container.updateOverrides([
        for (final override in scope.overrides)
          if (override.origin == printerServiceProvider)
            printerServiceProvider.overrideWith(
              (_) => AndroidPrinterService(
                documentPrint: (bytes, name, canDispatch) async {
                  documentCalls++;
                  expect(name, 'ERP测试单据.pdf');
                  expect(canDispatch(), isTrue);
                  return true;
                },
              ),
            )
          else
            override,
      ]);
      final printed = await screen.onPrintDocument!(
        Uint8List.fromList('%PDF-1.7 test'.codeUnits),
        'ERP测试单据.pdf',
        () => true,
      );
      expect(printed.failureOrNull, isNull);
      expect(documentCalls, 1);
      expect(
        (await screen.onPrintDocument!(
          Uint8List.fromList('%PDF-1.7 test'.codeUnits),
          'ERP测试单据.pdf',
          () => false,
        )).failureOrNull,
        isNotNull,
      );
      expect(documentCalls, 1);
      expect(
        GoRouterState.of(tester.element(find.byType(ErpNavScreen))).uri.path,
        client == ClientKind.erp ? '/ERP/anotherInLib' : '/ERP/home',
      );
      GoRouter.of(tester.element(find.byType(ErpNavScreen))).go('/ERP/home');
      await tester.pumpAndSettle();
      expect(
        GoRouterState.of(tester.element(find.byType(ErpNavScreen))).uri.path,
        '/ERP/home',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => factory.dependencies.disposed.future);
    });
  }
  testWidgets('VIP terminal login opens the real member workspace', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await factory.dependencies.sessionRepository.authorizeMachine(
        'loopback-development-vip',
      );
      await factory.dependencies.sessionRepository.login(
        account: 'employee',
        password: 'synthetic-password',
        type: EmployeeLoginType.account,
      );
    });
    await tester.pumpAndSettle();
    expect(find.byType(VipNavScreen), findsOneWidget);
    expect(find.byType(CardTableScreen), findsNothing);
    expect(find.byType(DiagnosticPanel), findsNothing);
    final page = tester.element(find.byType(VipNavScreen));
    expect(GoRouterState.of(page).uri.path, '/vipManager');
    final workspace = tester.widget<VipNavScreen>(find.byType(VipNavScreen));
    expect(workspace.newCardParams, isNotNull);
    expect(workspace.createCard, isNotNull);
    expect(workspace.makeCardBegin, isNotNull);
    expect(workspace.makeCardEnd, isNotNull);
    for (final path in ['/BMS/stationConfig', '/wine/saveLib', '/ERP/mats']) {
      GoRouter.of(tester.element(find.byType(VipNavScreen))).go(path);
      await tester.pumpAndSettle();
      expect(find.byType(VipNavScreen), findsOneWidget);
      expect(find.byType(BmsNavScreen), findsNothing);
      expect(find.byType(WineNavScreen), findsNothing);
      expect(find.byType(ErpNavScreen), findsNothing);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => factory.dependencies.disposed.future);
  });
  for (final (system, buttonKey, expectedPath, expectedTitle) in [
    (
      BusinessSystem.booking,
      BusinessSystemSelectionScreen.bookingKey,
      '/cardMachine',
      '预定 · 卡台列表',
    ),
    (
      BusinessSystem.order,
      BusinessSystemSelectionScreen.orderKey,
      '/orderCard',
      '点单 · 卡台列表',
    ),
    (
      BusinessSystem.cashier,
      BusinessSystemSelectionScreen.cashierKey,
      '/moneyCard',
      '收银 · 卡台列表',
    ),
  ]) {
    testWidgets('${system.name} employee login opens its business system', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final factory = _LifecycleFactory();
      await tester.pumpWidget(
        ShouyinAndroidApp(
          environment: AppRuntimeConfiguration.fromValues(
            apiBase: 'http://127.0.0.1:8183/dev-api/server',
            onlineBase: 'http://127.0.0.1:8183/online/server',
            websocketBase: 'ws://127.0.0.1:8183/socket/server',
            developmentSystemSelection: true,
          ),
          dependenciesFactory: factory,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(buttonKey));
      await tester.pumpAndSettle();
      expect(
        factory.dependencies.sessionRepository.currentMachine?.client,
        system.client,
      );
      expect(factory.dependencies.startCalls, 0);
      expect(find.text('${system.label}登录'), findsOneWidget);
      await tester.enterText(
        find.byKey(LoginScreen.accountFieldKey),
        'employee',
      );
      await tester.enterText(
        find.byKey(LoginScreen.passwordFieldKey),
        'synthetic-password',
      );
      await tester.tap(find.byKey(LoginScreen.loginSubmitKey));
      await tester.pumpAndSettle();
      expect(
        factory.dependencies.adapter.loginClientName,
        system.client.clientName,
      );
      expect(
        factory.dependencies.adapter.loginTermType,
        system.client.termType.toString(),
      );
      final cardPage = find.byKey(ValueKey<String>(expectedTitle));
      expect(cardPage, findsOneWidget);
      expect(find.byType(DiagnosticPanel), findsNothing);
      expect(GoRouterState.of(tester.element(cardPage)).uri.path, expectedPath);
      expect(factory.dependencies.startCalls, 1);
      factory.dependencies.emitEvent(_cardEnvelope('A01'));
      await tester.pumpAndSettle();
      if (system == BusinessSystem.order) {
        expect(
          tester
              .widget<ChoiceChip>(find.byKey(CardTableScreen.mineKey))
              .selected,
          isTrue,
        );
        expect(find.text('A01'), findsNothing);
        await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
        await tester.pumpAndSettle();
      }
      expect(find.text('A01'), findsOneWidget);
      if (system == BusinessSystem.cashier) {
        expect(
          tester
              .widget<CardTableScreen>(find.byType(CardTableScreen))
              .onLoadProfitLoss,
          isNotNull,
        );
        expect(
          tester
              .widget<CardTableScreen>(find.byType(CardTableScreen))
              .onLoadVouchers,
          isNotNull,
        );
        expect(
          tester
              .widget<CardTableScreen>(find.byType(CardTableScreen))
              .onCancelVoucher,
          isNotNull,
        );
        expect(
          tester
              .widget<CardTableScreen>(find.byType(CardTableScreen))
              .onExportVouchers,
          isNotNull,
        );
        expect(
          tester
              .widget<CardTableScreen>(find.byType(CardTableScreen))
              .onPrintCashierReportQuery,
          isNotNull,
        );
        expect(
          tester
              .widget<CardTableScreen>(find.byType(CardTableScreen))
              .onSubmitProfitLoss,
          isNotNull,
        );
        await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('售出日报表'));
        await tester.pumpAndSettle();
        expect(factory.dependencies.cashierReportCalls, 1);
        expect(find.byType(CashierReportScreen), findsOneWidget);
        factory.dependencies.emitPhase(ConnectionPhase.blocked);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CashierReportScreen>(find.byType(CashierReportScreen))
              .canRead!
              .value,
          isFalse,
        );
        factory.dependencies.emitPhase(ConnectionPhase.online);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<CashierReportScreen>(find.byType(CashierReportScreen))
              .canRead!
              .value,
          isTrue,
        );
        await tester.tap(find.text('查询'));
        await tester.pumpAndSettle();
        expect(factory.dependencies.cashierReportCalls, 3);
        Navigator.of(tester.element(find.byType(CashierReportScreen))).pop();
        await tester.pumpAndSettle();
        for (final title in ['支付记录', '线上支付汇总', '区域实时营收', '业绩日报表', '优惠明细表']) {
          await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(title));
          await tester.tap(find.text(title));
          await tester.pumpAndSettle();
          final report = tester.widget<CashierReportScreen>(
            find.byType(CashierReportScreen),
          );
          expect(report.onLoadPage, isNotNull);
          expect(report.onExportData, isNotNull);
          expect(report.onPrintData, isNotNull);
          expect(report.onFindPaymentCustomer, isNotNull);
          expect(factory.dependencies.typedCashierQueries.last.title, title);
          Navigator.of(tester.element(find.byType(CashierReportScreen))).pop();
          await tester.pumpAndSettle();
        }
      }
      if (system == BusinessSystem.order) {
        factory.dependencies.reportRows = [
          MinimumConsumptionReportRow.fromWire({'sn': '连接周期报表行'}),
        ];
        await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('低消进度统计表'));
        await tester.pumpAndSettle();
        expect(factory.dependencies.minimumReportCalls, 1);
        expect(find.byType(MinimumConsumptionReportScreen), findsOneWidget);
        expect(find.text('连接周期报表行'), findsOneWidget);
        factory.dependencies.emitPhase(ConnectionPhase.blocked);
        factory.dependencies.emitPhase(ConnectionPhase.online);
        await tester.pumpAndSettle();
        expect(find.text('连接周期报表行'), findsNothing);
        await tester.tap(find.text('重试'));
        await tester.pumpAndSettle();
        expect(factory.dependencies.minimumReportCalls, 2);
        expect(find.text('连接周期报表行'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, '关闭'));
        await tester.pumpAndSettle();
        factory.dependencies.cocktailRows = [
          CocktailDetailReportRow.fromWire({'n': '连接周期鸡尾酒'}),
        ];
        await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('鸡尾酒明细表'));
        await tester.pumpAndSettle();
        expect(factory.dependencies.cocktailReportCalls, 1);
        expect(find.byType(CocktailDetailReportScreen), findsOneWidget);
        expect(find.text('连接周期鸡尾酒'), findsOneWidget);
        factory.dependencies.emitPhase(ConnectionPhase.blocked);
        factory.dependencies.emitPhase(ConnectionPhase.online);
        await tester.pumpAndSettle();
        expect(find.text('连接周期鸡尾酒'), findsNothing);
        await tester.tap(find.text('查询'));
        await tester.pumpAndSettle();
        expect(factory.dependencies.cocktailReportCalls, 2);
        expect(find.text('连接周期鸡尾酒'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, '关闭'));
        await tester.pumpAndSettle();
        factory.dependencies.soldOutItems = [
          SoldOutItem.fromWire({'id': '101', 'n': '连接周期估清', 'c': 1}),
        ];
        await tester.tap(find.byKey(CardTableScreen.moreFunctionsKey));
        await tester.pumpAndSettle();
        await tester.tap(find.text('估清商品'));
        await tester.pumpAndSettle();
        expect(factory.dependencies.soldOutListCalls, 1);
        expect(find.byType(SoldOutProductsScreen), findsOneWidget);
        expect(find.text('连接周期估清'), findsOneWidget);
        factory.dependencies.emitPhase(ConnectionPhase.blocked);
        factory.dependencies.emitPhase(ConnectionPhase.online);
        await tester.pumpAndSettle();
        expect(find.text('连接周期估清'), findsNothing);
        await tester.tap(find.widgetWithText(FilledButton, '确定'));
        await tester.pumpAndSettle();
      }
      expect(find.text('营业日未开启'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final router = GoRouter.of(tester.element(cardPage));
      if (system == BusinessSystem.cashier) {
        unawaited(router.push<void>('/payOrder'));
        await tester.pumpAndSettle();
        final pay = tester.widget<PayOrderScreen>(find.byType(PayOrderScreen));
        expect(pay.moveOrder, isNotNull);
        expect(pay.movePayedOrder, isNotNull);
        expect(pay.verifyPaidTransfer, isNotNull);
        expect(pay.paidTransfersNeedingVerification, isNotNull);
        expect(pay.batchUpdateOrderWaiter, isNotNull);
        expect(pay.batchUpdateOrderAuther, isNotNull);
        router.pop();
        await tester.pumpAndSettle();
      }
      router.go(expectedPath == '/moneyCard' ? '/cardMachine' : '/moneyCard');
      await tester.pumpAndSettle();
      expect(GoRouterState.of(tester.element(cardPage)).uri.path, expectedPath);
      await tester.ensureVisible(find.byKey(CardTableScreen.accountMenuKey));
      await tester.tap(find.byKey(CardTableScreen.accountMenuKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CardTableScreen.switchSystemKey));
      await tester.pumpAndSettle();
      expect(find.byType(BusinessSystemSelectionScreen), findsOneWidget);
      expect(factory.dependencies.sessionRepository.currentUser, isNull);
      expect(factory.dependencies.stopCalls, 1);
      expect(find.text('A01'), findsNothing);
      router.go(expectedPath);
      await tester.pumpAndSettle();
      expect(find.byType(BusinessSystemSelectionScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => factory.dependencies.disposed.future);
    });
  }

  testWidgets('rejected employee login stays at login without realtime', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => factory.dependencies.sessionRepository.authorizeMachine('TERM-001'),
    );
    await tester.pumpAndSettle();
    factory.dependencies.adapter.rejectLogin = true;
    await tester.enterText(find.byKey(LoginScreen.accountFieldKey), 'employee');
    await tester.enterText(
      find.byKey(LoginScreen.passwordFieldKey),
      'synthetic-password',
    );
    await tester.tap(find.byKey(LoginScreen.loginSubmitKey));
    await tester.pumpAndSettle();
    expect(find.text('账号或密码错误'), findsOneWidget);
    expect(factory.dependencies.sessionRepository.currentUser, isNull);
    expect(factory.dependencies.startCalls, 0);
    expect(
      GoRouterState.of(tester.element(find.byType(LoginScreen))).uri.path,
      '/login',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => factory.dependencies.disposed.future);
  });

  testWidgets('loopback development selects a system before employee login', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    final environment = AppRuntimeConfiguration.fromValues(
      apiBase: 'http://127.0.0.1:8183/dev-api/server',
      onlineBase: 'http://127.0.0.1:8183/online/server',
      websocketBase: 'ws://127.0.0.1:8183/socket/server',
      developmentSystemSelection: true,
    );

    await tester.pumpWidget(
      ShouyinAndroidApp(environment: environment, dependenciesFactory: factory),
    );
    await tester.pumpAndSettle();

    expect(environment.developmentSystemSelection, isTrue);
    expect(find.byType(BusinessSystemSelectionScreen), findsOneWidget);
    await tester.tap(find.byKey(BusinessSystemSelectionScreen.cashierKey));
    await tester.pumpAndSettle();

    expect(factory.dependencies.sessionRepository.currentMachine, isNotNull);
    expect(
      factory.dependencies.sessionRepository.currentMachine?.client,
      ClientKind.cashier,
    );
    expect(find.byKey(LoginScreen.employeeFieldsKey), findsOneWidget);
    expect(find.byKey(LoginScreen.machineFieldsKey), findsNothing);
    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsNothing);

    await tester.tap(find.text('切换系统'));
    await tester.pumpAndSettle();
    expect(find.byType(BusinessSystemSelectionScreen), findsOneWidget);
    expect(factory.dependencies.sessionRepository.currentMachine, isNull);
    expect(factory.dependencies.startCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => factory.dependencies.disposed.future);
  });

  test('development system selection allows vue-dev nls-dev endpoints', () {
    final environment = AppRuntimeConfiguration.fromValues(
      apiBase: 'http://nls-dev.xmsjznwl.com/server',
      onlineBase: 'https://ncrmyun-dev.xmsjznwl.com/server',
      websocketBase: 'ws://nls-dev.xmsjznwl.com/server',
      developmentSystemSelection: true,
    );
    expect(environment.config, isNotNull);
    expect(environment.developmentSystemSelection, isTrue);
  });

  testWidgets(
    'nls-dev system selection authorizes with the vue register order code',
    (tester) async {
      final factory = _LifecycleFactory();
      final environment = AppRuntimeConfiguration.fromValues(
        apiBase: 'http://nls-dev.xmsjznwl.com/server',
        onlineBase: 'https://ncrmyun-dev.xmsjznwl.com/server',
        websocketBase: 'ws://nls-dev.xmsjznwl.com/server',
        developmentSystemSelection: true,
      );

      await tester.pumpWidget(
        ShouyinAndroidApp(
          environment: environment,
          dependenciesFactory: factory,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BusinessSystemSelectionScreen), findsOneWidget);
      await tester.tap(find.byKey(BusinessSystemSelectionScreen.orderKey));
      await tester.pumpAndSettle();

      expect(
        factory.dependencies.adapter.termAuthCode,
        'sfjofdjvcow3dfolwnmvowejw',
      );
      expect(
        factory.dependencies.sessionRepository.currentMachine?.client,
        ClientKind.order,
      );
      expect(find.byKey(LoginScreen.employeeFieldsKey), findsOneWidget);
      expect(find.byKey(LoginScreen.machineFieldsKey), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() => factory.dependencies.disposed.future);
    },
  );

  test('development system selection cannot escape loopback endpoints', () {
    for (final environment in <AppRuntimeConfiguration>[
      AppRuntimeConfiguration.fromValues(
        apiBase: 'https://api.example.test/server',
        onlineBase: 'https://online.example.test/server',
        websocketBase: 'wss://socket.example.test/server',
        developmentSystemSelection: true,
      ),
      AppRuntimeConfiguration.fromValues(
        apiBase: 'http://127.0.0.1:8183/api/server',
        onlineBase: 'http://127.0.0.1:8183/online/server',
        websocketBase: 'ws://127.0.0.1:8183/socket/server',
        developmentSystemSelection: true,
      ),
      AppRuntimeConfiguration.fromValues(
        apiBase: 'http://127.0.0.1:8184/dev-api/server',
        onlineBase: 'http://127.0.0.1:8183/online/server',
        websocketBase: 'ws://127.0.0.1:8183/socket/server',
        developmentSystemSelection: true,
      ),
    ]) {
      expect(environment.config, isNotNull);
      expect(environment.developmentSystemSelection, isFalse);
    }
  });

  testWidgets('invalid config creates no shell or secure/network dependency', (
    tester,
  ) async {
    final factory = _LifecycleFactory();

    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: AppRuntimeConfiguration.fromValues(
          apiBase: '',
          onlineBase: 'https://online.example.test',
          websocketBase: 'invalid',
        ),
        dependenciesFactory: factory,
      ),
    );

    expect(find.text('应用配置不可用'), findsOneWidget);
    expect(factory.createCalls, 0);
    expect(factory.routerCreateCalls, 0);
  });

  testWidgets('root owns lazy auth realtime and disposal lifecycle', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 900));
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
        initialLocation: '/diagnostics',
      ),
    );
    await tester.pumpAndSettle();
    final dependencies = factory.dependencies;

    expect(factory.createCalls, 1);
    expect(factory.routerCreateCalls, 1);
    expect(dependencies.startCalls, 0);
    expect(dependencies.realtimeCreated, isFalse);
    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      '收银 Android 客户端',
    );
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 1);
    expect(dependencies.realtimeCreated, isTrue);
    final cardPage = find.byKey(const ValueKey<String>('收银 · 卡台列表'));
    expect(cardPage, findsOneWidget);
    GoRouter.of(tester.element(cardPage)).go('/diagnostics');
    await tester.pumpAndSettle();
    expect(find.byKey(DiagnosticPanel.narrowLayoutKey), findsOneWidget);
    expect(find.text('收银 Android 客户端'), findsOneWidget);

    GoRouter.of(tester.element(find.text('收银 Android 客户端')))
        .go('/diagnostics/devices');
    await tester.pumpAndSettle();
    expect(find.byType(DeviceDiagnosticsScreen), findsOneWidget);
    final deviceContext = tester.element(find.byType(DeviceDiagnosticsScreen));
    final deviceContainer = ProviderScope.containerOf(deviceContext);
    expect(
      deviceContainer.read(scannerServiceProvider),
      isA<AndroidScannerService>(),
    );
    expect(
      deviceContainer.read(printerServiceProvider),
      isA<AndroidPrinterService>(),
    );
    GoRouter.of(deviceContext).go('/diagnostics');
    await tester.pumpAndSettle();

    await tester.pump();
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 1);

    await tester.runAsync(dependencies.logout);
    await tester.pumpAndSettle();
    expect(dependencies.stopCalls, 1);
    expect(find.byKey(LoginScreen.machineCodeFieldKey), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => dependencies.disposed.future);
    expect(dependencies.disposeCalls, 1);
    expect(dependencies.stopCalls, 1);
    expect(dependencies.dioCloseCalls, 1);
    expect(dependencies.hasOpenStreams, isFalse);
    expect(factory.routerDisposeCalls, 1);
  });

  testWidgets('authenticated unmount stops and disposes resources once', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();
    final dependencies = factory.dependencies;
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => dependencies.disposed.future);

    expect(dependencies.stopCalls, 1);
    expect(dependencies.disposeCalls, 1);
    expect(dependencies.dioCloseCalls, 1);
    expect(dependencies.hasOpenStreams, isFalse);
    expect(factory.routerDisposeCalls, 1);
  });

  testWidgets('initially authenticated root starts realtime exactly once', (
    tester,
  ) async {
    final factory = (await tester.runAsync(
      () => _LifecycleFactory.authenticated(_validEnvironment.config!),
    ))!;

    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();

    expect(factory.dependencies.startCalls, 1);
    expect(find.byKey(const ValueKey<String>('收银 · 卡台列表')), findsOneWidget);
    await tester.pump();
    expect(factory.dependencies.startCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => factory.dependencies.disposed.future);
    expect(factory.dependencies.disposeCalls, 1);
  });

  test(
    'shell phase and failure streams stay stable from construction',
    () async {
      final dependencies = _LifecycleDependencies(_validEnvironment.config!);
      final phaseStream = dependencies.connectionPhases;
      final failureStream = dependencies.realtimeFailures;
      final phases = <ConnectionPhase>[];
      final failures = <AppFailure>[];
      final phaseSubscription = phaseStream.listen(phases.add);
      final failureSubscription = failureStream.listen(failures.add);
      await Future<void>.delayed(Duration.zero);
      expect(phases, <ConnectionPhase>[ConnectionPhase.blocked]);

      dependencies.emitFailure(
        const AppFailure(
          kind: FailureKind.realtime,
          code: 'realtime.synthetic',
          safeMessage: '测试实时错误',
        ),
      );
      await dependencies.startRealtime();
      await Future<void>.delayed(Duration.zero);
      expect(identical(phaseStream, dependencies.connectionPhases), isTrue);
      expect(identical(failureStream, dependencies.realtimeFailures), isTrue);
      expect(phases, contains(ConnectionPhase.online));
      expect(failures.single.code, 'realtime.synthetic');

      await phaseSubscription.cancel();
      await failureSubscription.cancel();
      await dependencies.dispose();
      expect(dependencies.hasOpenStreams, isFalse);
    },
  );
  testWidgets('old stop completion cannot block a newer auth generation', (
    tester,
  ) async {
    final factory = _LifecycleFactory();
    await tester.pumpWidget(
      ShouyinAndroidApp(
        environment: _validEnvironment,
        dependenciesFactory: factory,
      ),
    );
    await tester.pumpAndSettle();
    final dependencies = factory.dependencies;
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    dependencies.gateNextStop();
    await tester.runAsync(dependencies.logout);
    await tester.pump();
    await tester.runAsync(() => dependencies.stopStarted.future);
    await tester.runAsync(dependencies.authenticate);
    await tester.pumpAndSettle();
    expect(dependencies.startCalls, 2);
    expect(dependencies.connectionPhase, ConnectionPhase.online);
    dependencies.releaseStoppedGeneration();
    await tester.runAsync(() => dependencies.stopFinished.future);
    await tester.pumpAndSettle();
    expect(dependencies.connectionPhase, ConnectionPhase.online);
    expect(dependencies.disposedGenerations, <int>[1]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() => dependencies.disposed.future);
    expect(dependencies.disposedGenerations, <int>[1, 2]);
  });
}

final AppRuntimeConfiguration _validEnvironment =
    AppRuntimeConfiguration.fromValues(
      apiBase: 'https://api.example.test/server',
      onlineBase: 'https://online.example.test/server',
      websocketBase: 'wss://socket.example.test',
    );

final class _LifecycleFactory implements ShellDependenciesFactory {
  _LifecycleFactory();

  static Future<_LifecycleFactory> authenticated(ApiConfig config) async {
    final factory = _LifecycleFactory();
    final dependencies = _LifecycleDependencies(config);
    await dependencies.authenticate();
    factory._prepared = dependencies;
    return factory;
  }

  _LifecycleDependencies? _prepared;
  int createCalls = 0;
  int routerCreateCalls = 0;
  int routerDisposeCalls = 0;
  late _LifecycleDependencies dependencies;

  @override
  ShellDependencies create(ApiConfig config) {
    createCalls += 1;
    dependencies = _prepared ?? _LifecycleDependencies(config);
    return dependencies;
  }

  @override
  void onRouterCreated() => routerCreateCalls += 1;

  @override
  void onRouterDisposed() => routerDisposeCalls += 1;
}

final class _StubOrderLateDepositLoader implements OrderLateDepositLoader {
  const _StubOrderLateDepositLoader();
  @override
  bool get needsVerification => false;
  @override
  Future<Result<OrderLateDepositPayment>> create({
    required String seatId,
    required int payType,
    required String amountYuan,
    String? authCode,
    required bool Function() canDispatch,
  }) async => throw UnimplementedError();
  @override
  Future<Result<int>> status(
    String payDetailId, {
    required bool Function() canDispatch,
  }) async => throw UnimplementedError();
}

final class _LifecycleDependencies implements ShellDependencies {
  @override
  CashierCreditAccountsLoader get creditAccountsLoader =>
      throw UnsupportedError(
        'Credit management is not used by this lifecycle fixture',
      );
  @override
  CashierMerchantManagementLoader get merchantManagementLoader =>
      throw UnsupportedError(
        'Merchant management is not used by this lifecycle fixture',
      );
  @override
  OrderLateDepositLoader get orderLateDepositLoader =>
      const _StubOrderLateDepositLoader();
  @override
  Future<Result<void>> printCashierReportQuery(
    CashierReportQuery query,
  ) async => const Success(null);
  @override
  Future<Result<List<CashierVoucherRecord>>> loadVouchers(
    CashierVoucherQuery query,
  ) async => const Success([]);
  @override
  Future<Result<void>> cancelVoucher(
    String recordId,
    bool Function() canDispatch,
  ) async => const Success(null);
  @override
  Future<Result<String>> exportVouchers(
    CashierVoucherQuery query,
    bool Function() canDispatch,
  ) async => const Success('test.xlsx');
  @override
  Future<Result<List<CashierProfitLossRecord>>> loadProfitLoss() async =>
      const Success([]);
  @override
  Future<Result<void>> submitProfitLoss(
    CashierProfitLossDraft draft,
    bool Function() canDispatch,
  ) async => const Success(null);
  int auditedBusinessWrites = 0;
  final typedCashierQueries = <CashierReportQuery>[];
  @override
  Future<Result<CashierReportPage>> loadCashierReportPage(
    CashierReportQuery query,
  ) async {
    typedCashierQueries.add(query);
    return const Success(CashierReportPage());
  }

  @override
  Future<Result<Map<int, String>>> loadCashierDepartments() async =>
      const Success({});
  @override
  Future<Result<String>> exportCashierReport(CashierReportQuery query) async =>
      const Success('test-export.xlsx');
  @override
  Future<Result<void>> printCashierReport(String title) async =>
      const Success(null);
  @override
  Future<Result<CashierPaymentCustomer?>> findCashierPaymentCustomer(
    String phone,
  ) async => const Success(null);
  @override
  Future<Result<void>> changeCashierPaymentCustomer(
    String paymentId,
    String phone,
  ) async => const Success(null);
  final managementFeed = ManagementPermissionFeed();
  @override
  ManagementPermissionFeed get managementAccess => managementFeed;
  late final ProtocolClient _protocolClient;
  @override
  ErpLoader get erpLoader => ProtocolErpLoader(
    session: sessionRepository,
    isOnline: () => _phase == ConnectionPhase.online,
    generation: () => currentGeneration,
    api: ProtocolErpApi(
      client: _protocolClient,
      clientKind: sessionRepository.currentMachine!.client,
    ),
  );
  _LifecycleDependencies(ApiConfig config)
    : _store = _MemoryCredentialStore(),
      _dio = Dio(),
      adapter = _AuthAdapter() {
    _dio.httpClientAdapter = adapter;
    final client = ProtocolClient(
      dio: _dio,
      config: config,
      credentialStore: _store,
      requestGate: RequestGate(clock: DateTime.now),
    );
    _protocolClient = client;
    sessionRepository = SessionRepository(
      api: SessionApi(client: client),
      credentialStore: _store,
    );
  }

  final _MemoryCredentialStore _store;
  final Dio _dio;
  final _AuthAdapter adapter;
  final StreamController<ConnectionPhase> _phases =
      StreamController<ConnectionPhase>.broadcast(sync: true);
  final StreamController<AppFailure> _failures =
      StreamController<AppFailure>.broadcast(sync: true);
  final StreamController<SyncEnvelope> _events =
      StreamController<SyncEnvelope>.broadcast(sync: true);
  final Completer<void> disposed = Completer<void>();

  @override
  late final SessionRepository sessionRepository;
  ConnectionPhase _phase = ConnectionPhase.blocked;
  bool _active = false;
  bool realtimeCreated = false;
  int startCalls = 0;
  int minimumReportCalls = 0;
  int cocktailReportCalls = 0;
  int soldOutListCalls = 0;
  List<MinimumConsumptionReportRow> reportRows = const [];
  List<CocktailDetailReportRow> cocktailRows = const [];
  List<SoldOutItem> soldOutItems = const [];

  void emitPhase(ConnectionPhase phase) {
    _phase = phase;
    _phases.add(phase);
  }

  int cashierReportCalls = 0;

  @override
  Future<Result<List<CashierReportRow>>> loadCashierReport(
    String title,
    String startDate,
    String endDate,
    String keyword,
  ) async {
    cashierReportCalls++;
    return const Success([]);
  }

  @override
  Future<Result<void>> movePayOrder({
    required String seatId,
    required String destSeatId,
    required List<String> orderIds,
    List<int> counts = const [],
    int? totalAmtFen,
    bool Function()? canDispatch,
  }) async => const Success(null);
  @override
  Future<Result<void>> batchUpdateOrderWaiter({
    required String seatId,
    required List<String> orderIds,
    required String waiterEmpId,
    bool Function()? canDispatch,
  }) async => const Success(null);
  @override
  Set<String> paidTransfersNeedingVerification(String seatId) => {};
  @override
  Future<Result<void>> verifyPaidTransfer({
    required String seatId,
    required String payId,
    required int turnoverCount,
    bool Function()? canDispatch,
  }) async => const Success(null);
  @override
  Future<Result<void>> movePaidPayOrder({
    required String seatId,
    required String destSeatId,
    required String payId,
    required int totalAmtFen,
    required int turnoverCount,
    required String receiptFingerprint,
    List<String> selectedUnpaidIds = const [],
    bool Function()? canDispatch,
  }) async => const Success(null);
  @override
  Future<Result<void>> batchUpdateOrderAuther({
    required String seatId,
    required List<String> orderIds,
    required String authEmpId,
    bool Function()? canDispatch,
  }) async => const Success(null);

  @override
  Future<Result<List<MinimumConsumptionReportRow>>>
  loadMinimumConsumptionReport() async {
    minimumReportCalls++;
    return Success(List<MinimumConsumptionReportRow>.unmodifiable(reportRows));
  }

  @override
  Future<Result<List<CocktailDetailReportRow>>> loadCocktailDetailReport(
    String keyword,
  ) async {
    cocktailReportCalls++;
    return Success(List<CocktailDetailReportRow>.unmodifiable(cocktailRows));
  }

  @override
  Future<Result<List<SoldOutItem>>> listSoldOutProducts() async {
    soldOutListCalls++;
    return Success(List<SoldOutItem>.unmodifiable(soldOutItems));
  }

  @override
  Future<Result<void>> setSoldOutProduct({
    required String productId,
    required int count,
    bool Function()? canDispatch,
  }) async => const Success(null);

  @override
  Future<Result<void>> deleteSoldOutProduct(
    String productId, {
    bool Function()? canDispatch,
  }) async => const Success(null);

  @override
  Future<Result<List<VipCardHit>>> searchVipCards(String keyword) async =>
      const Success([]);

  @override
  Future<Result<VipMemberCard>> loadVipMember(String cardId) async =>
      const FailureResult(
        AppFailure(
          kind: FailureKind.unknown,
          code: 'vip_recharge.test',
          safeMessage: '测试未提供会员详情',
        ),
      );

  @override
  Future<Result<List<VipDepositRule>>> loadVipRules(String cardId) async =>
      const Success([]);

  @override
  Future<Result<VipRechargeOrder>> createVipOrder(
    Map<String, Object?> body, {
    bool Function()? canDispatch,
  }) async => const Success(VipRechargeOrder(orderId: 'o', payId: 'p'));

  @override
  Future<Result<VipRechargePay>> createVipPay({
    required String payId,
    required int payAmtFen,
    required int payType,
    String authCode = '',
    bool Function()? canDispatch,
  }) async => const Success(VipRechargePay(scanUrl: '', payResult: 0));

  @override
  Future<Result<VipLastSales?>> loadVipLastSales(String cardId) async =>
      const Success(null);

  @override
  Future<Result<VipOrderStatus>> pollVipOrderStatus(String orderId) async =>
      const Success(VipOrderStatus(payResult: 0));

  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async => const Success(null);

  @override
  Future<Result<bool>> authPasswordEnabled() async => const Success(false);

  @override
  Future<Result<void>> changeAuthPassword({
    required bool enabled,
    required String loginPassword,
    required String authPassword,
  }) async => const Success(null);

  @override
  Future<Result<void>> addOrderProduct({
    required String seatId,
    required String productId,
    required int count,
    required String price,
    String amount = '',
  }) async => const Success(null);

  @override
  Future<Result<int>> orderCartCount(String seatId) async => const Success(0);

  @override
  Future<Result<List<OrderCartItem>>> orderCartItems(String seatId) async =>
      const Success([]);

  @override
  Future<Result<void>> setOrderCartCount({
    required String seatId,
    required String itemId,
    required int count,
  }) async => const Success(null);

  @override
  Future<Result<void>> bindOrderWaiter(String seatId) async =>
      const Success(null);

  @override
  Future<Result<List<OrderGuestHit>>> searchOrderGuests(String phone) async =>
      const Success([]);

  @override
  Future<Result<void>> bindOrderGuest({
    required String seatId,
    required String phone,
  }) async => const Success(null);

  @override
  Future<Result<List<OrderPlacedItem>>> loadOrderItems({
    required String seatId,
    required int turnoverCount,
  }) async => const Success([]);

  @override
  Future<Result<bool>> checkOrderAmounts(String seatId) async =>
      const Success(true);

  @override
  Future<Result<OrderPlacedData>> loadOrderDetails({
    required String seatId,
    required int turnoverCount,
  }) async => const Success(OrderPlacedData());

  @override
  Future<Result<void>> placeOrder({
    required String seatId,
    required List<String> cartItemIds,
  }) async => const Success(null);

  @override
  Future<Result<void>> addTimedProduct({
    required String seatId,
    required String productId,
    required int count,
    required String amount,
  }) async => const Success(null);

  @override
  Future<Result<void>> addSet({
    required String seatId,
    required String productId,
    required int count,
    required int priceFen,
    required List<String> groupIds,
    required List<String> detailProductIds,
    required List<int> detailCounts,
    required List<int> selectCounts,
    List<String> requirements = const [],
  }) async => const Success(null);

  @override
  Future<Result<void>> refundOrder({
    required String seatId,
    required String orderId,
    required int count,
    required String amount,
    required String remark,
    required bool online,
    String authEmpCode = '',
    String authEmpPasswd = '',
    int passType = 1,
  }) async => const Success(null);

  @override
  Future<Result<void>> convertCartToYh({
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String reason,
  }) async => const Success(null);

  @override
  Future<Result<void>> addYh({
    required String seatId,
    required String productId,
    required int count,
    required String amount,
    required String price,
    required String reason,
  }) async => const Success(null);

  @override
  Future<Result<void>> addYh2({
    required String seatId,
    required String productId,
    required int count,
    required String salesEmpId,
    required String yh2SeatId,
  }) async => const Success(null);

  @override
  Future<Result<void>> addRequirement({
    required String seatId,
    required String itemId,
    required String requirement,
  }) async => const Success(null);

  @override
  Future<Result<void>> changeSetDetail({
    required String seatId,
    required String itemId,
    required String groupId,
    required String detailProductId,
    required List<String> destDetailProductIds,
    required List<int> destSelectCounts,
    required String requirement,
    required List<String> destRequirements,
  }) async => const Success(null);

  @override
  Future<Result<void>> convertCartToYh2({
    required String seatId,
    required List<String> cartItemIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
  }) async => const Success(null);

  @override
  Future<Result<void>> giftOrdered({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String reason,
  }) async => const Success(null);

  @override
  Future<Result<void>> changeOrderedSet({
    required String seatId,
    required String orderId,
    required String orderDetailId,
    required List<String> destDetailProductIds,
    required List<int> destSelectCounts,
    required List<String> destRequirements,
    String authEmpCode = '',
    String authEmpPasswd = '',
    int passType = 1,
  }) async => const Success(null);

  @override
  Future<Result<void>> convertOrderToYh2({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String salesEmpId,
    required String yh2SeatId,
  }) async => const Success(null);

  @override
  Future<Result<void>> reprintKitchen(String orderId) async =>
      const Success(null);

  @override
  Future<Result<void>> printBill({
    required String seatId,
    required bool unpaid,
    required bool includeHl,
  }) async => const Success(null);

  @override
  Future<Result<void>> cleanSeat(String seatId) async => const Success(null);

  @override
  Future<Result<void>> mergeYh2({
    required String seatId,
    required List<String> orderIds,
    required String destSeatId,
  }) async => const Success(null);

  @override
  Future<Result<List<OrderPlacedItem>>> waiterTodoOrders(String seatId) async =>
      const Success([]);

  @override
  Future<Result<WaiterPayQr>> createWaiterPay({
    required String seatId,
    required int payType,
    required List<String> orderIds,
  }) async => const Success(WaiterPayQr(payId: '1', amountFen: 0, payUrl: 'x'));

  @override
  Future<Result<void>> redeemCoupon(String authCode) async =>
      const Success(null);

  @override
  Future<Result<List<WineSaveCsm>>> listWineCsms(String seatId) async =>
      const Success([]);

  @override
  Future<Result<void>> submitSaveWine({
    required List<String> cartIds,
    required String phone,
    required String name,
    required String authCode,
  }) async => const Success(null);

  @override
  Future<Result<void>> submitTakeWine({
    required String seatId,
    required List<String> inventoryIds,
    required List<int> counts,
    required String phone,
    required String authCode,
  }) async => const Success(null);

  @override
  Future<Result<void>> submitConfiscateWine({
    required String seatId,
    required String date,
    required String salesEmpId,
    required List<String> productIds,
    required List<String> unitTypes,
    required List<int> counts,
    required List<int> grams,
  }) async => const Success(null);

  @override
  Future<Result<PayOrderData>> loadPayOrders({
    required String seatId,
    required int turnoverCount,
  }) async =>
      Success(PayOrderData(seatId: seatId, turnoverCount: turnoverCount));

  @override
  Future<Result<List<PayCartItem>>> payCartItems(String seatId) async =>
      const Success([]);

  @override
  Future<Result<void>> refundPaidOrder({
    required String seatId,
    required String payId,
    required List<String> orderIds,
    required List<int> counts,
    required List<String> amounts,
    required String remark,
  }) async => const Success(null);

  @override
  Future<Result<void>> addPayChannel({
    required String seatId,
    required String channelId,
    required String amount,
  }) async => const Success(null);

  @override
  Future<Result<void>> deletePayChannel({
    required String seatId,
    required String itemId,
  }) async => const Success(null);

  @override
  Future<Result<void>> submitPayOrder({
    required String seatId,
    required List<String> orderIds,
    required List<int> counts,
    required String totalAmount,
  }) async => const Success(null);

  @override
  Future<Result<void>> payCleanSeat(String seatId) async {
    auditedBusinessWrites++;
    return const Success(null);
  }

  @override
  Future<Result<void>> paySettleMode({
    required String seatId,
    required int settleMode,
  }) async => const Success(null);

  @override
  Future<Result<void>> payPrintBill(String seatId) async => const Success(null);

  @override
  Future<Result<void>> payAuthChannel({
    required String seatId,
    required String amount,
  }) async => const Success(null);

  @override
  Future<Result<void>> payLateChannel({
    required String seatId,
    required String lateId,
  }) async => const Success(null);

  @override
  Future<Result<void>> payMemberChannel({
    required String seatId,
    required String cardId,
    required int amountFen,
    required String phone,
    required String authCode,
  }) async => const Success(null);

  @override
  Future<Result<void>> payPrepayChannel({
    required String seatId,
    required String prepayId,
    required String amount,
    required String authCode,
  }) async => const Success(null);

  @override
  Future<Result<void>> closeBusinessDay() async => const Success(null);

  @override
  Future<Result<void>> printShiftBill() async => const Success(null);

  @override
  Future<Result<AutoCloseConfig>> loadAutoClose() async =>
      const Success(AutoCloseConfig(enabled: false, hour: 0, minute: 0));

  @override
  Future<Result<void>> saveAutoClose({
    required bool enabled,
    required int hour,
    required int minute,
  }) async => const Success(null);

  @override
  Future<Result<VipCardPage>> listVipCards({
    required int pageNum,
    required int pageSize,
    String keyword = '',
    bool init = false,
  }) async => const Success(VipCardPage(total: 0));

  @override
  Future<Result<VipNewCardParams>> vipNewCardParams() async =>
      const Success(VipNewCardParams());

  @override
  Future<Result<String>> createVipCard({
    required String cardNo,
    required String typeId,
    required String levelId,
    required String name,
    String bindPhone = '',
    String bindAuthCode = '',
    String contactPhone = '',
  }) async => const Success('0');

  @override
  Future<Result<List<VipCardRow>>> vipPhoneCards(String phone) async =>
      const Success([]);

  @override
  Future<Result<VipMakeCardBegin>> vipMakeCardBegin({
    required String cardNo,
    required String memberCardId,
  }) async => const Success(VipMakeCardBegin(cardPass: '', verifyData: ''));

  @override
  Future<Result<void>> vipMakeCardEnd({
    required String cardNo,
    required String memberCardId,
  }) async => const Success(null);

  @override
  Future<Result<void>> vipSendSms({
    required String phone,
    required int typeId,
  }) async => const Success(null);

  @override
  VipPages vipPages() => const VipPages();

  @override
  Future<Result<void>> writeBookingCard({
    required BookingCardWriteAction action,
    required String seatId,
    String bookId = '',
    Map<String, Object?> fields = const <String, Object?>{},
    bool Function()? canDispatch,
  }) async => const Success(null);

  @override
  Future<Result<void>> openBusinessDay() async => const Success<void>(null);

  @override
  Future<Result<BookingBookDetail>> loadBookingBookDetail(
    String bookId,
  ) async => const Success(BookingBookDetail());

  @override
  Future<Result<BookingDetailConfig>> loadBookingDetailConfig() async =>
      const Success(BookingDetailConfig.unrestrictedAll);

  @override
  Future<Result<List<SeatOpenLogRow>>> loadSeatOpenLog({
    String key = '',
    int deptId = 0,
    int typeId = 1,
  }) async => const Success(<SeatOpenLogRow>[]);

  @override
  Future<Result<String>> exportSeatOpenLog({
    String key = '',
    int typeId = 1,
  }) async => const Success('开台记录.xlsx');

  @override
  Future<Result<List<SeatChangeLogRow>>> loadSeatChangeLog() async =>
      const Success(<SeatChangeLogRow>[]);

  @override
  Future<Result<List<BookListRow>>> loadBookList() async =>
      const Success(<BookListRow>[]);

  @override
  Future<Result<String>> exportBookList() async => const Success('预留记录.xlsx');

  @override
  Future<Result<List<OnlineBookListRow>>> loadOnlineBookList() async =>
      const Success(<OnlineBookListRow>[]);

  @override
  Future<Result<String>> exportOnlineBookList() async =>
      const Success('线上预订记录.xlsx');

  @override
  Future<Result<List<SeatOpeningRow>>> loadSeatOpeningList() async =>
      const Success(<SeatOpeningRow>[]);

  @override
  Future<Result<String>> exportSeatOpeningList() async =>
      const Success('入客数据实时汇总.xlsx');

  @override
  Future<Result<DeptRegionSeatOpenData>> loadDeptRegionSeatOpenList() async =>
      const Success(
        DeptRegionSeatOpenData(
          nowTime: '',
          deptList: <DeptRegionItem>[],
          regionList: <DeptRegionItem>[],
        ),
      );

  @override
  Future<Result<String>> exportDeptRegionSeatOpenList() async =>
      const Success('部门实时订台区域开台.xlsx');

  @override
  Future<Result<void>> queueCall({
    required int queueTypeId,
    required int queueNo,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> queueArrive({
    required int queueTypeId,
    required int queueNo,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> queueExpired({
    required int queueTypeId,
    required int queueNo,
  }) async => const Success<void>(null);

  @override
  Future<Result<String>> exportQueueList({
    int queueTypeId = 0,
    int status = 0,
  }) async => const Success('排队列表.xlsx');

  @override
  Future<Result<List<TurnoverSaleHistoryItem>>> loadTurnoverSales(
    String seatId,
  ) async => const Success(<TurnoverSaleHistoryItem>[]);

  @override
  Future<Result<void>> changeTurnoverSales({
    required String seatId,
    required String csmId,
    required String salesEmpId,
    String secondSalesEmpId = '',
    required String reason,
  }) async => const Success<void>(null);

  @override
  Future<Result<List<SeatTurnbackItem>>> loadTurnbackList(
    String seatId,
  ) async => const Success(<SeatTurnbackItem>[]);

  @override
  Future<Result<void>> confirmTurnback(String csmId) async =>
      const Success<void>(null);

  @override
  Future<Result<BookingOrderDetailData>> loadOrderDetail({
    required String seatId,
    required int turnoverCount,
  }) async => const Success(BookingOrderDetailData());

  @override
  Future<Result<List<BookingReservedItem>>> loadReservedList({
    required bool isToday,
    int futureType = 1,
  }) async => const Success(<BookingReservedItem>[]);

  @override
  Future<Result<void>> cancelReservedInfo(List<String> bookIds) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> singleAllocation({
    required String id,
    required String seatId,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> manyAllocation(List<String> bookIds) async =>
      const Success<void>(null);

  int stopCalls = 0;
  int disposeCalls = 0;
  int dioCloseCalls = 0;
  int currentGeneration = 0;
  final List<int> disposedGenerations = <int>[];
  Completer<void> stopStarted = Completer<void>();
  Completer<void> stopFinished = Completer<void>();
  Completer<void>? _stopRelease;

  bool get hasOpenStreams =>
      !_phases.isClosed || !_failures.isClosed || !_events.isClosed;

  @override
  Stream<SyncEnvelope> get cardTableEvents => _events.stream;

  void emitEvent(SyncEnvelope event) {
    managementFeed.add(event);
    _events.add(event);
  }

  @override
  Future<Result<void>> refreshRealtime() async => const Success<void>(null);

  @override
  ConnectionPhase get connectionPhase => _phase;

  @override
  late final Stream<ConnectionPhase> connectionPhases = _CurrentValueStream(
    _phases.stream,
    () => _phase,
  );

  @override
  late final Stream<AppFailure> realtimeFailures = _failures.stream;

  void emitFailure(AppFailure failure) => _failures.add(failure);

  Future<void> authenticate() async {
    await sessionRepository.authorizeMachine('TERM-001');
    await sessionRepository.login(
      account: 'employee',
      password: 'synthetic-password',
      type: EmployeeLoginType.account,
    );
  }

  Future<void> logout() async {
    await sessionRepository.logout();
  }

  void gateNextStop() {
    stopStarted = Completer<void>();
    stopFinished = Completer<void>();
    _stopRelease = Completer<void>();
  }

  void releaseStoppedGeneration() => _stopRelease?.complete();

  @override
  Future<void> startRealtime() async {
    final user = sessionRepository.currentUser;
    if (user != null) managementFeed.start(user.stationId);
    managementFeed.setPhase(ConnectionPhase.online);
    startCalls += 1;
    currentGeneration += 1;
    realtimeCreated = true;
    _active = true;
    _phase = ConnectionPhase.online;
    _phases.add(_phase);
  }

  @override
  Future<void> stopRealtime() async {
    managementFeed.reset();
    if (!_active) return;
    final stoppedGeneration = currentGeneration;
    stopCalls += 1;
    _active = false;
    if (!stopStarted.isCompleted) stopStarted.complete();
    await _stopRelease?.future;
    disposedGenerations.add(stoppedGeneration);
    if (currentGeneration == stoppedGeneration && !_active) {
      _phase = ConnectionPhase.blocked;
      _phases.add(_phase);
    }
    if (!stopFinished.isCompleted) stopFinished.complete();
    _stopRelease = null;
  }

  @override
  Future<void> dispose() async {
    if (disposeCalls != 0) return;
    disposeCalls += 1;
    await stopRealtime();
    await sessionRepository.close();
    managementFeed.dispose();
    await _phases.close();
    await _failures.close();
    await _events.close();
    _dio.close(force: true);
    dioCloseCalls += 1;
    disposed.complete();
  }
}

final class _AuthAdapter implements HttpClientAdapter {
  String stationId = '1';
  String? loginClientName;
  String? loginTermType;
  String? termAuthCode;
  bool rejectLogin = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
    }
    final payload = bytes.isEmpty
        ? <String, Object?>{}
        : jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    if (options.path.endsWith('/auth/login')) {
      loginClientName = payload['client_name'] as String?;
      loginTermType = options.headers['tt'] as String?;
    }
    if (options.path.endsWith('/term/auth')) {
      termAuthCode = payload['code'] as String?;
    }
    final mode = switch (payload['code']) {
      'loopback-development-book' || 'iwdvowefdwjvhvoepqjdjq221' => 2,
      'loopback-development-order' || 'sfjofdjvcow3dfolwnmvowejw' => 4,
      'loopback-development-vip' => 16,
      'loopback-development-erp' => 32,
      'loopback-development-erpAdmin' => 64,
      'loopback-development-org_mgr' => 1,
      'loopback-development-wine' => 256,
      'loopback-development-queuedsp' => 512,
      _ => 8,
    };
    final body = options.path.endsWith('/auth/login') && rejectLogin
        ? <String, Object?>{'code': 0, 'msg': '账号或密码错误'}
        : options.path.endsWith('/term/auth')
        ? <String, Object?>{
            'code': 1,
            'data': <String, Object?>{
              'tk': 'synthetic-tk',
              'am': mode,
              'id': 'machine-1',
              'n': 'Front Counter',
            },
          }
        : <String, Object?>{
            'code': 1,
            'data': <String, Object?>{
              'emp_id': 'employee-1',
              'name': 'Synthetic Employee',
              'station_id': stationId,
            },
          };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

SyncEnvelope _cardEnvelope(String name) =>
    SyncEnvelope.fromValidatedReconciliation(
      cursor: '20260831100000',
      data: <String, Object?>{
        '0': <Object?>[
          <Object?>[1, '大厅', 1, 1],
        ],
        '1': <Object?>[
          <Object?>[1, name, 1, 1, 3, 1, 4, 1],
        ],
        '13': <Object?>[],
        '14': <Object?>[],
        '18': <Object?>[
          <Object?>[0, '', '测试门店'],
        ],
        '41': <Object?>[
          <Object?>['1', 5, 1],
        ],
        '54': <Object?>[],
      },
    );

final class _MemoryCredentialStore implements CredentialStore {
  String? _tk;
  String? _stk;

  @override
  Future<void> clearStk() async => _stk = null;
  @override
  Future<void> clearStkIfMatches(String? expected) async {
    if (_stk == expected) _stk = null;
  }

  @override
  Future<void> clearTk() async => _tk = null;
  @override
  Future<void> clearTkIfMatches(String? expected) async {
    if (_tk == expected) _tk = null;
  }

  @override
  Future<String?> readStk() async => _stk;
  @override
  Future<CredentialSnapshot> readSnapshot() async =>
      CredentialSnapshot(tk: _tk, stk: _stk);
  @override
  Future<String?> readTk() async => _tk;
  @override
  Future<void> writeStk(String value) async => _stk = value;
  @override
  Future<void> writeTk(String value) async => _tk = value;
}

final class _CurrentValueStream<T> extends Stream<T> {
  const _CurrentValueStream(this.source, this.current);

  final Stream<T> source;
  final T Function() current;

  @override
  bool get isBroadcast => true;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    late final StreamController<T> controller;
    StreamSubscription<T>? subscription;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        subscription = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.add(current());
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () => subscription?.cancel(),
    );
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
