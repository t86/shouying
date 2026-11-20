import 'package:card_table/src/vip_recharge.dart';
import 'package:card_table/src/vip_recharge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('shows source search and keeps confirm disabled', (tester) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    await _pump(tester, canRead: canRead);
    await tester.pumpAndSettle();
    expect(find.text('会员充值'), findsOneWidget);
    expect(find.text('注册开卡'), findsOneWidget);
    expect(find.text('输入手机号后四位或会员卡号'), findsOneWidget);
    expect(find.textContaining('选择充值账户'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确认充值'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认充值'))
          .onPressed,
      isNull,
    );
    expect(find.textContaining('待接入'), findsNothing);
  });

  testWidgets('search at four characters lists cards then loads member rules', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final keywords = <String>[];
    await _pump(
      tester,
      canRead: canRead,
      search: (keyword) async {
        keywords.add(keyword);
        return Success([
          VipCardHit.fromWire({'id': '88', 'n': '张三 1234'}),
        ]);
      },
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(VipRechargeScreen.searchKey), '123');
    await tester.pumpAndSettle();
    expect(keywords, isEmpty);
    await tester.enterText(find.byKey(VipRechargeScreen.searchKey), '1234');
    await tester.pumpAndSettle();
    expect(keywords, ['1234']);
    expect(find.text('张三 1234'), findsOneWidget);
    await tester.tap(find.text('张三 1234'));
    await tester.pumpAndSettle();
    expect(find.text('C001'), findsOneWidget);
    expect(find.text('张三'), findsWidgets);
    expect(find.text('¥100.00'), findsOneWidget);
    expect(find.text('赠：¥20.00'), findsOneWidget);
    expect(find.text('自定义'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认充值'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('确认充值'));
    await tester.pumpAndSettle();
    expect(find.text('选择支付方式'), findsOneWidget);
    expect(find.text('客人扫我-支付宝'), findsOneWidget);
    expect(find.text('客人扫我-微信'), findsOneWidget);
    expect(find.text('扫客人-支付宝'), findsNothing);
    expect(find.text('扫客人-微信'), findsNothing);
  });

  testWidgets('applies last sales recommender after selecting a card', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    final cards = <String>[];
    await _pump(
      tester,
      canRead: canRead,
      search: (keyword) async => Success([
        VipCardHit.fromWire({'id': '88', 'n': '张三 1234'}),
      ]),
      lastSales: (id) async {
        cards.add(id);
        return Success(const VipLastSales(id: '9', name: '李四'));
      },
      employees: const [
        VipRechargeEmployee(id: '1', name: '王五', code: 'E1'),
        VipRechargeEmployee(id: '9', name: '李四', code: 'E9'),
      ],
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(VipRechargeScreen.searchKey), '1234');
    await tester.pumpAndSettle();
    await tester.tap(find.text('张三 1234'));
    await tester.pumpAndSettle();
    expect(cards, ['88']);
    await tester.ensureVisible(find.byKey(VipRechargeScreen.recommenderKey));
    await tester.pumpAndSettle();
    expect(find.text('李四 (E9)'), findsWidgets);
    expect(find.text('已自动设置推荐人，允许修改'), findsOneWidget);
  });

  testWidgets('selecting a card still loads member if last sales is empty', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    await _pump(
      tester,
      canRead: canRead,
      search: (keyword) async => Success([
        VipCardHit.fromWire({'id': '88', 'n': '张三 1234'}),
      ]),
      lastSales: (id) async => const FailureResult(
        AppFailure(
          kind: FailureKind.business,
          code: 'business.vip_recharge_rejected',
          safeMessage: '服务端拒绝会员充值操作，请重试',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(VipRechargeScreen.searchKey), '1234');
    await tester.pumpAndSettle();
    await tester.tap(find.text('张三 1234'));
    await tester.pumpAndSettle();
    expect(find.text('C001'), findsOneWidget);
    expect(find.text('服务端拒绝会员充值操作，请重试'), findsNothing);
  });

  testWidgets('guest-scan-me pay shows qr and succeeds after status poll', (
    tester,
  ) async {
    final canRead = ValueNotifier(true);
    addTearDown(canRead.dispose);
    var polls = 0;
    await _pump(
      tester,
      canRead: canRead,
      search: (keyword) async => Success([
        VipCardHit.fromWire({'id': '88', 'n': '张三 1234'}),
      ]),
      pollStatus: (orderId) async {
        polls++;
        expect(orderId, 'o1');
        return const Success(VipOrderStatus(payResult: 1));
      },
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(VipRechargeScreen.searchKey), '1234');
    await tester.pumpAndSettle();
    await tester.tap(find.text('张三 1234'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认充值'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('客人扫我-支付宝'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认支付'));
    await tester.pumpAndSettle();
    expect(find.text('请扫码支付'), findsOneWidget);
    expect(find.textContaining('请使用支付宝扫码支付'), findsOneWidget);
    expect(find.byKey(VipRechargeScreen.qrKey), findsOneWidget);
    expect(polls, 0);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(polls, 1);
    expect(find.text('支付成功！'), findsOneWidget);
    expect(find.text('返回充值页面'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ValueNotifier<bool> canRead,
  Future<Result<List<VipCardHit>>> Function(String keyword)? search,
  Future<Result<VipLastSales?>> Function(String cardId)? lastSales,
  Future<Result<VipOrderStatus>> Function(String orderId)? pollStatus,
  List<VipRechargeEmployee> employees = const [],
}) => tester.pumpWidget(
  MaterialApp(
    home: VipRechargeScreen(
      canRead: canRead,
      employees: employees,
      search: search ?? (keyword) async => const Success([]),
      lastSales: lastSales,
      pollStatus: pollStatus,
      detail: (id) async => Success(
        VipMemberCard.fromWire({
          'id': id,
          'card_no': 'C001',
          'name': '张三',
          'bind_phone': '13800138000',
          'val_bal': '10.00',
          'free_bal': '2.00',
          'bal': '12.00',
          'sales_emp_id': '1',
        }),
      ),
      rules: (id) async => Success([
        VipDepositRule.fromWire({
          'd': 10000,
          'f': 2000,
          'fp': 10,
          'fkn': '',
          'fk': 0,
        }),
      ]),
      createOrder: (body, {canDispatch}) async =>
          const Success(VipRechargeOrder(orderId: 'o1', payId: 'p1')),
      createPay:
          ({
            required String payId,
            required int payAmtFen,
            required int payType,
            String authCode = '',
            bool Function()? canDispatch,
          }) async => const Success(
            VipRechargePay(scanUrl: 'https://pay.example/qr', payResult: 0),
          ),
    ),
  ),
);
