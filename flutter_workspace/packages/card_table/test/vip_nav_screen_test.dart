import 'package:card_table/src/vip_manager.dart';
import 'package:card_table/src/vip_nav_screen.dart';
import 'package:card_table/src/vip_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foundation/foundation.dart';

void main() {
  testWidgets('vip shell lists nav items and returns to cashier', (tester) async {
    var back = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: VipNavScreen(
          onBack: () => back += 1,
          listCards:
              ({
                required int pageNum,
                required int pageSize,
                String keyword = '',
                bool init = false,
              }) async => const Success(
                VipCardPage(total: 0),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('返回'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('会员管理'), findsWidgets);
    expect(find.text('企微会员'), findsOneWidget);
    expect(find.text('会员卡类型'), findsOneWidget);
    await tester.tap(find.text('业务配置'));
    await tester.pumpAndSettle();
    expect(find.text('会员卡号生成规则'), findsOneWidget);
    await tester.tap(find.text('报表管理'));
    await tester.pumpAndSettle();
    expect(find.text('充值记录'), findsWidgets);
    await tester.tap(find.text('会员管理').first);
    await tester.pumpAndSettle();
    expect(find.text('积分设置'), findsOneWidget);
    await tester.tap(find.text('业务配置'));
    await tester.pumpAndSettle();
    expect(find.text('会员卡充值设置'), findsWidgets);
    expect(find.text('会员卡结账规则'), findsWidgets);
    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(back, 1);
  });

  testWidgets('vip manager searches cards by keyword', (tester) async {
    final keys = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: VipNavScreen(
          onBack: () {},
          listCards:
              ({
                required int pageNum,
                required int pageSize,
                String keyword = '',
                bool init = false,
              }) async {
                keys.add(keyword);
                return const Success(
                  VipCardPage(
                    total: 1,
                    records: [
                      VipCardRow(
                        id: '9',
                        name: '张三',
                        statusName: '正常',
                        bindPhone: '13800000000',
                        contactPhone: '',
                        sex: '男',
                        birthday: '',
                        cardNo: 'VIP0001',
                        typeName: '金卡',
                        levelName: '普通',
                        balance: '100.00',
                        points: '10',
                        salesName: '',
                      ),
                    ],
                  ),
                );
              },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('张三'), findsOneWidget);
    expect(find.textContaining('VIP0001'), findsOneWidget);
    await tester.enterText(find.byKey(VipNavScreen.searchKey), 'VIP0001');
    await tester.tap(find.text('查询'));
    await tester.pumpAndSettle();
    expect(keys, contains('VIP0001'));
  });

  testWidgets('point settings load and save consume-gift rule', (tester) async {
    var savedType = 0;
    var savedAmt = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: VipNavScreen(
          onBack: () {},
          listCards:
              ({
                required int pageNum,
                required int pageSize,
                String keyword = '',
                bool init = false,
              }) async => const Success(VipCardPage(total: 0)),
          pages: VipPages(
            getPointRule: () async =>
                const Success(VipPointRule(typeId: 3, baseAmt: 10)),
            savePointRule: ({required int typeId, required int baseAmt}) async {
              savedType = typeId;
              savedAmt = baseAmt;
              return const Success(null);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('积分设置'));
    await tester.pumpAndSettle();
    expect(find.text('赠送积分规则：'), findsOneWidget);
    expect(find.text('消费赠送积分'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(savedType, 3);
    expect(savedAmt, 10);
  });

  testWidgets('deposit rule page lists recharge amounts', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VipNavScreen(
          onBack: () {},
          listCards:
              ({
                required int pageNum,
                required int pageSize,
                String keyword = '',
                bool init = false,
              }) async => const Success(VipCardPage(total: 0)),
          pages: VipPages(
            listDepositRules: ({String cardTypeId = '0'}) async => const Success([
              VipDepositGiftRule(
                id: '7',
                depositFen: 10000,
                giftFen: 2000,
                levelName: '全等级',
              ),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('业务配置'));
    await tester.pumpAndSettle();
    expect(find.text('会员卡充值设置'), findsWidgets);
    expect(find.textContaining('10000'), findsOneWidget);
    expect(find.textContaining('2000'), findsOneWidget);
  });

  testWidgets('card row menu exposes remaining write operations', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VipNavScreen(
          onBack: () {},
          listCards:
              ({
                required int pageNum,
                required int pageSize,
                String keyword = '',
                bool init = false,
              }) async => const Success(
                VipCardPage(
                  total: 1,
                  records: [
                    VipCardRow(
                      id: '9',
                      name: '张三',
                      statusName: '正常',
                      bindPhone: '13800000000',
                      contactPhone: '',
                      sex: '男',
                      birthday: '',
                      cardNo: 'VIP0001',
                      typeName: '金卡',
                      levelName: '普通',
                      balance: '100.00',
                      points: '10',
                      salesName: '',
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    expect(find.text('编辑会员卡信息'), findsOneWidget);
    expect(find.text('更改会员卡等级'), findsOneWidget);
    expect(find.text('更改/绑定手机号'), findsOneWidget);
    expect(find.text('换卡'), findsOneWidget);
    expect(find.text('退卡'), findsOneWidget);
    expect(find.text('扣款'), findsOneWidget);
    expect(find.text('充值积分'), findsOneWidget);
  });

  testWidgets('vip manager toolbar exposes recharge, read-card and pay-serial', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: VipNavScreen(
          onBack: () {},
          listCards:
              ({
                required int pageNum,
                required int pageSize,
                String keyword = '',
                bool init = false,
              }) async => const Success(VipCardPage(total: 0)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('充值'), findsOneWidget);
    expect(find.text('读取卡信息'), findsOneWidget);
    expect(find.text('付款序列号制卡'), findsOneWidget);
  });
}
