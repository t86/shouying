import 'package:card_table/card_table.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:session/session.dart';

void main() {
  test('order menu has source order and module-gated sold out', () {
    expect(CardPageMenus.moreFor(BusinessSystem.order), ['低消进度统计表', '鸡尾酒明细表']);
    expect(CardPageMenus.moreFor(BusinessSystem.order, moduleIds: {5}), [
      '低消进度统计表',
      '鸡尾酒明细表',
      '估清商品',
    ]);
  });
  test('safe mode hides cashier/order more but never booking more', () {
    expect(
      CardPageMenus.moreFor(BusinessSystem.order, safeModeEnabled: true),
      isEmpty,
    );
    expect(
      CardPageMenus.moreFor(BusinessSystem.cashier, safeModeEnabled: true),
      isEmpty,
    );
    expect(
      CardPageMenus.moreFor(BusinessSystem.booking, safeModeEnabled: true),
      ['开台记录', '转台记录', '预留记录', '线上预订记录', '入客数据实时汇总', '部门实时订台/区域开台', '排队详情'],
    );
  });
  test('cashier preserves all 37 entries and never booking-only entries', () {
    final entries = CardPageMenus.moreFor(BusinessSystem.cashier);
    expect(entries, [
      '班结表',
      '售出日报表',
      '商品出库表',
      '查询优惠额度',
      '线上支付汇总',
      '支付记录',
      '区域实时营收',
      '业绩日报表',
      '转台记录',
      '线上预订记录',
      '优惠明细表',
      '当日卡券核销记录表',
      '商品卡台销售表',
      '鸡尾酒明细表',
      '鸡尾酒汇总表',
      '挂账账户',
      '翻台记录',
      '点单记录',
      '历史点单记录',
      '非鸡尾酒类补交报表',
      '修改订位人记录',
      '估清商品',
      '盘盈盘亏',
      '商户号管理',
      '低消进度统计表',
      '现抽明细表',
      '现抽汇总表',
      '非主营分类渠道',
      '分类渠道汇总表',
      '部门销售明细表',
      '部门销售汇总表',
      '套餐统计表',
      '挂账还款记录表',
      '预订金流水表',
      '预订金余额表',
      '结束营业日',
      '自动结束营业日',
    ]);
  });
}
