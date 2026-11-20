import 'package:card_table/src/cashier_objection_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('renders objection tabs and items correctly', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final executedCmds = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CashierObjectionDrawer(
            onLoadList: () async => const Success(
              CashierObjectionData(
                todos: [
                  CashierObjectionItem(
                    id: '1001',
                    seatName: 'V01',
                    bookerName: '李经理',
                    customerName: '张先生',
                    customerPhone: '13912345678',
                    payChannelName: '微信支付',
                    amount: '500.00',
                    time: '2026-09-14 12:00',
                    businessType: '结账退款',
                    commands: [
                      CashierObjectionCommand(key: 'retry', label: '重试退款'),
                    ],
                  ),
                ],
                fails: [
                  CashierObjectionItem(
                    id: '1002',
                    seatName: 'V02',
                    failReason: '渠道余额不足',
                  ),
                ],
              ),
            ),
            onExecuteCommand: (id, cmdKey) async {
              executedCmds.add('$id:$cmdKey');
              return const Success(null);
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('异议单列表'), findsOneWidget);
    expect(find.text('待退款'), findsOneWidget);
    expect(find.text('V01'), findsOneWidget);
    expect(find.text('张先生'), findsOneWidget);
    expect(find.text('重试退款'), findsOneWidget);

    // 点击重试退款按钮并确认
    await tester.ensureVisible(find.text('重试退款'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重试退款'));
    await tester.pumpAndSettle();
    expect(find.text('确认对单号 1001 执行 [重试退款] 操作吗？'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(executedCmds, contains('1001:retry'));

    // 切换到已失败 Tab
    await tester.tap(find.text('已失败'));
    await tester.pumpAndSettle();
    expect(find.text('渠道余额不足'), findsOneWidget);
  });
}
