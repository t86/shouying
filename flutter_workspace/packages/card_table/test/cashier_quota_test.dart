import 'dart:async';

import 'package:dio/dio.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:card_table/src/cashier_quota.dart';
import 'package:card_table/src/cashier_reports.dart';
import 'package:card_table/src/cashier_reports_screens.dart';
import 'package:flutter/material.dart';
import 'package:foundation/foundation.dart';
import 'package:protocol/protocol.dart';

import 'bms_staff_contract_test.dart' show Adapter, makeApi, Credentials;

class PendingQuotaCredentials extends Credentials {
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<CredentialSnapshot> readSnapshot() async {
    entered.complete();
    await release.future;
    return super.readSnapshot();
  }
}

void main() {
  testWidgets(
    'back immediately blocks credential-waiting quota dispatch before transition completes',
    (tester) async {
      final credentials = PendingQuotaCredentials();
      final adapter = Adapter();
      final api = ProtocolCashierReportsApi(
        client: ProtocolClient(
          dio: Dio()..httpClientAdapter = adapter,
          config: ApiConfig(
            apiBase: Uri.parse('https://api.test'),
            onlineBase: Uri.parse('https://online.test'),
            websocketBase: Uri.parse('wss://api.test'),
          ),
          credentialStore: credentials,
          requestGate: RequestGate(clock: DateTime.now),
        ),
      );
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
            builder: (_) => CashierReportScreen(
              title: '查询优惠额度',
              onLoadPage: (query) =>
                  api.loadReportPage(ClientKind.cashier, query: query),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '001');
      await tester.enterText(find.byType(TextField).at(1), 'test');
      await tester.tap(find.text('授权查询'));
      await tester.pump();
      expect(credentials.entered.isCompleted, true);
      nav.currentState!.pop();
      await tester.pump();
      credentials.release.complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(adapter.requests, isEmpty);
    },
  );
  for (final type in [1, 2]) {
    test(
      'quota account/card $type preserves exact auth and raw units',
      () async {
        final adapter = Adapter()
          ..data = {
            'name': '张三',
            'code': '001',
            'records': [
              {
                'id': 8,
                'n': '酒水优惠',
                't': '限量',
                'udc': 2,
                'ldc': 3,
                'uda': '123.45',
                'lda': 678,
                'umc': 8,
                'lmc': 10,
                'uma': '987.65',
                'lma': -1,
              },
            ],
          };
        final api = ProtocolCashierReportsApi(client: makeApi(adapter).client);
        final auth = CashierQuotaAuthorization(
          code: '001',
          password: 'test',
          passType: type,
        );
        final query = CashierReportQuery(
          title: '查询优惠额度',
          quotaAuthorization: auth,
        );
        final result = await api.loadReportPage(
          ClientKind.cashier,
          query: query,
        );
        expect(result.failureOrNull, isNull);
        expect(
          adapter.requests.single.uri.path,
          '/sel/get_auth_emp_free_limit',
        );
        expect(adapter.requests.single.data, {
          'auth_emp_code': '001',
          'auth_emp_passwd': '098F6BCD4621D373CADE4E832627B4F6',
          'pass_type': type,
        });
        expect(result.valueOrNull!.quota!.name, '张三');
        expect(result.valueOrNull!.rows.single['uda'], '123.45');
        expect(result.valueOrNull!.rows.single['lda'], '678');
        expect(auth.toString(), isNot(contains(auth.passwordDigest)));
        expect(
          (await api.exportReport(
            ClientKind.cashier,
            query: query,
          )).failureOrNull,
          isNotNull,
        );
        expect(
          (await api.loadReportPage(
            ClientKind.order,
            query: query,
          )).failureOrNull,
          isNotNull,
        );
        expect(adapter.requests.length, 1);
      },
    );
  }
  test(
    'quota products use source limit id without retained credentials',
    () async {
      final adapter = Adapter()
        ..data = {
          'records': [
            {'p': '酒水'},
          ],
        };
      final result =
          await ProtocolCashierReportsApi(
            client: makeApi(adapter).client,
          ).loadReportPage(
            ClientKind.cashier,
            query: const CashierReportQuery(title: '查询优惠额度', quotaLimitId: 8),
          );
      expect(result.valueOrNull!.rows.single['p'], '酒水');
      expect(adapter.requests.single.uri.path, '/station/get_fl_act_prds');
      expect(adapter.requests.single.data, {
        'free_limit_ids': [8],
      });
    },
  );
  testWidgets(
    'revocation clears credentials and ignores late authorization result',
    (tester) async {
      final access = ValueNotifier(true);
      final pending = Completer<Result<CashierReportPage>>();
      CashierReportQuery? requested;
      await tester.pumpWidget(
        MaterialApp(
          home: CashierReportScreen(
            title: '查询优惠额度',
            canRead: access,
            onLoadPage: (query) {
              requested = query;
              return pending.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '001');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.text('授权查询'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
        isEmpty,
      );
      expect(requested!.canDispatch!(), true);
      access.value = false;
      access.value = true;
      expect(requested!.canDispatch!(), false);
      pending.complete(
        const Success(
          CashierReportPage(
            quota: CashierQuotaResult(name: '旧用户', code: '001'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('旧用户'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller!.text,
        isEmpty,
      );
    },
  );
  testWidgets('authorized quota expands products without reusing password', (
    tester,
  ) async {
    final queries = <CashierReportQuery>[];
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '查询优惠额度',
          onLoadPage: (q) async {
            queries.add(q);
            return Success(
              q.quotaLimitId == null
                  ? const CashierReportPage(
                      quota: CashierQuotaResult(name: '张三', code: '001'),
                      rows: [
                        CashierReportRow(
                          id: '8',
                          cells: {'n': '酒水优惠', 'uda': '123.45'},
                        ),
                      ],
                    )
                  : const CashierReportPage(
                      rows: [
                        CashierReportRow(id: '', cells: {'p': '啤酒'}),
                      ],
                    ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '001');
    await tester.enterText(find.byType(TextField).at(1), 'test');
    await tester.tap(find.text('授权查询'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('酒水优惠'));
    await tester.pumpAndSettle();
    expect(queries.last.quotaLimitId, 8);
    expect(queries.last.quotaAuthorization, isNull);
    expect(find.text('1. 啤酒'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('quota opens authorization without any report request', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CashierReportScreen(
          title: '查询优惠额度',
          onLoadPage: (query) async {
            calls++;
            return const Success(CashierReportPage());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('授权人工号'), findsOneWidget);
    expect(find.text('手工卡号/卡密'), findsOneWidget);
  });
  test('quota never auto queries without explicit authorization', () async {
    final adapter = Adapter();
    final result =
        await ProtocolCashierReportsApi(client: makeApi(adapter).client)
            .loadReportPage(
              ClientKind.cashier,
              query: const CashierReportQuery(title: '查询优惠额度'),
            );
    expect(result.failureOrNull, isNotNull);
    expect(adapter.requests, isEmpty);
  });
}
