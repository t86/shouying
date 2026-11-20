import 'dart:async';

import 'package:card_table/src/bms_loader.dart';
import 'package:card_table/src/bms_models.dart';
import 'package:card_table/src/bms_wine_sms_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('refresh retries failed cooldown read and restores sending', (
    tester,
  ) async {
    var reads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BmsAccountInfoView(
          loader: SmsLoader(),
          readCooldown: () async {
            if (++reads == 1) throw StateError('storage unavailable');
            return null;
          },
          writeCooldown: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('bms-sms-self-check-send')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('刷新'));
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('bms-sms-self-check-send')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.text('无法读取发送间隔，请刷新后重试'), findsNothing);
  });
  testWidgets(
    'refresh cannot replace in-memory cooldown after persistence failure',
    (tester) async {
      var reads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BmsAccountInfoView(
            loader: SmsLoader(),
            readCooldown: () async {
              reads++;
              return null;
            },
            writeCooldown: (_) async => throw StateError('write failed'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _send(tester);
      expect(find.text('60秒后发送'), findsOneWidget);
      await tester.tap(find.byTooltip('刷新'));
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(find.text('60秒后发送'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('bms-sms-self-check-send')),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    },
  );
  testWidgets(
    'self check disables duplicates, persists 60 seconds and expires after reopening',
    (tester) async {
      final loader = SmsLoader()..sendPending = Completer<Result<void>>();
      var now = DateTime(2026, 9, 20, 10);
      DateTime? persisted;
      Widget view() => MaterialApp(
        home: BmsAccountInfoView(
          loader: loader,
          clock: () => now,
          readCooldown: () async => persisted,
          writeCooldown: (time) async => persisted = time,
        ),
      );
      await tester.pumpWidget(view());
      await tester.pumpAndSettle();
      await _send(tester);
      expect(loader.sendCount, 1);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('bms-sms-self-check-send')),
            )
            .onPressed,
        isNull,
      );
      loader.sendPending!.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(persisted, now);
      expect(find.text('60秒后发送'), findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();
      now = now.add(const Duration(seconds: 20));
      await tester.pumpWidget(view());
      await tester.pumpAndSettle();
      expect(find.text('40秒后发送'), findsOneWidget);
      now = now.add(const Duration(seconds: 40));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('发送短信'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('bms-sms-self-check-send')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(const Duration(seconds: 61));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('failed self check stays retryable without saving cooldown', (
    tester,
  ) async {
    final loader = SmsLoader()..fail = true;
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BmsAccountInfoView(
          loader: loader..fail = false,
          readCooldown: () async => null,
          writeCooldown: (_) async => saved = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    loader.fail = true;
    await _send(tester);
    await tester.pumpAndSettle();
    expect(find.text('发送失败：查询失败'), findsOneWidget);
    expect(saved, isFalse);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('bms-sms-self-check-send')),
          )
          .onPressed,
      isNotNull,
    );
  });
  testWidgets(
    'pending self check completes after disposal without a state update',
    (tester) async {
      final loader = SmsLoader()..sendPending = Completer<Result<void>>();
      DateTime? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: BmsAccountInfoView(
            loader: loader,
            readCooldown: () async => null,
            writeCooldown: (time) async => saved = time,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _send(tester);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      loader.sendPending!.complete(const Success(null));
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('account exposes SMS self-check send with phone field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BmsAccountInfoView(loader: SmsLoader())),
    );
    await tester.pumpAndSettle();
    expect(find.text('发送短信'), findsOneWidget);
    expect(find.byKey(const Key('bms-sms-self-check-mobile')), findsOneWidget);
  });
  testWidgets(
    'account and mobile failures remain visible and recover on retry',
    (tester) async {
      final loader = SmsLoader()..fail = true;
      await tester.pumpWidget(
        MaterialApp(home: BmsAccountInfoView(loader: loader)),
      );
      await tester.pumpAndSettle();
      expect(find.text('查询失败'), findsOneWidget);
      expect(find.textContaining('剩余短信条数'), findsNothing);
      loader.fail = false;
      await tester.tap(find.byTooltip('刷新'));
      await tester.pumpAndSettle();
      expect(find.text('客户名称：测试门店'), findsOneWidget);
      loader.fail = true;
      await tester.pumpWidget(
        MaterialApp(home: BmsMessageResultView(loader: loader)),
      );
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(find.text('查询失败'), findsOneWidget);
      expect(find.text('暂无短信记录'), findsNothing);
    },
  );
  testWidgets(
    'account exposes real money/count and error, not invented totals',
    (tester) async {
      final loader = SmsLoader();
      await tester.pumpWidget(
        MaterialApp(home: BmsAccountInfoView(loader: loader)),
      );
      await tester.pumpAndSettle();
      expect(find.text('客户名称：测试门店'), findsOneWidget);
      expect(find.text('账户余额：12.50'), findsOneWidget);
      expect(find.textContaining('累计已发送'), findsNothing);
    },
  );
  testWidgets(
    'mobile results requires explicit query and renders template/status/error',
    (tester) async {
      final loader = SmsLoader();
      await tester.pumpWidget(
        MaterialApp(home: BmsMessageResultView(loader: loader)),
      );
      await tester.pumpAndSettle();
      expect(loader.mobile, isNull);
      await tester.enterText(find.byType(TextField), '13800000000');
      await tester.tap(find.text('查询'));
      await tester.pumpAndSettle();
      expect(loader.mobile, '13800000000');
      expect(find.textContaining('通知内容'), findsOneWidget);
      expect(find.textContaining('号码错误'), findsOneWidget);
    },
  );
  testWidgets('bill list opens record details and retains date pagination', (
    tester,
  ) async {
    final loader = SmsLoader();
    await tester.pumpWidget(
      MaterialApp(home: BmsMessageDetailView(loader: loader)),
    );
    await tester.pumpAndSettle();
    expect(find.text('2026-09-20 · 消费'), findsOneWidget);
    await tester.tap(find.text('下一页'));
    await tester.pumpAndSettle();
    expect(loader.billPage, 2);
    await tester.tap(find.byKey(const Key('bms-sms-bill-7')));
    await tester.pumpAndSettle();
    expect(loader.recordId, '7');
    expect(find.textContaining('通知内容'), findsOneWidget);
    expect(loader.initialized, isTrue);
    await tester.tap(find.text('下一页'));
    await tester.pumpAndSettle();
    expect(loader.detailPage, 2);
    expect(loader.initialized, isFalse);
  });
}

class SmsLoader implements BmsLoader {
  int sendCount = 0;
  Completer<Result<void>>? sendPending;
  @override
  Future<Result<void>> sendSmsSelfCheck(String mobile) async {
    sendCount++;
    if (sendPending != null) return sendPending!.future;
    return fail ? const FailureResult(failure) : const Success(null);
  }

  int billPage = 0, detailPage = 0;
  bool? initialized;
  bool fail = false;
  static const failure = AppFailure(
    kind: FailureKind.network,
    code: 'offline',
    safeMessage: '查询失败',
  );
  String? mobile, recordId;
  @override
  Future<Result<BmsSmsAccountInfo>> loadSmsAccount() async => fail
      ? const FailureResult(failure)
      : const Success(
          BmsSmsAccountInfo(
            customerName: '测试门店',
            moneyBalance: '12.50',
            balance: 250,
          ),
        );
  @override
  Future<Result<BmsSmsBillPage>> loadSmsBills({
    required String startDay,
    required String endDay,
    int type = 0,
    int page = 1,
    int pageSize = 20,
  }) async {
    billPage = page;
    return const Success(
      BmsSmsBillPage(
        records: [
          BmsSmsBill(
            id: '7',
            date: '2026-09-20',
            type: '消费',
            count: '2',
            amount: '0.10',
          ),
        ],
        total: 41,
      ),
    );
  }

  @override
  Future<Result<BmsSmsDeliveryPage>> loadSmsMobileResults({
    required String mobile,
  }) async {
    this.mobile = mobile;
    return _results();
  }

  @override
  Future<Result<BmsSmsDeliveryPage>> loadSmsRecordDetails({
    required String recordId,
    int status = 0,
    String mobile = '',
    int page = 1,
    int pageSize = 20,
    bool initialize = true,
    List<Map<String, Object?>> templates = const [],
  }) async {
    this.recordId = recordId;
    detailPage = page;
    initialized = initialize;
    return _results();
  }

  Result<BmsSmsDeliveryPage> _results() => fail
      ? const FailureResult(failure)
      : const Success(
          BmsSmsDeliveryPage(
            records: [
              BmsSmsRecord(
                id: '1',
                phone: '13800000000',
                content: '通知内容',
                state: '失败',
                failReason: '号码错误',
              ),
            ],
            total: 41,
          ),
        );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _send(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('bms-sms-self-check-mobile')),
    '13800000000',
  );
  await tester.ensureVisible(find.byKey(const Key('bms-sms-self-check-send')));
  await tester.tap(find.byKey(const Key('bms-sms-self-check-send')));
  await tester.pumpAndSettle();
  expect(find.textContaining('真实自查短信'), findsOneWidget);
  await tester.tap(find.text('确认发送'));
  await tester.pumpAndSettle();
}
