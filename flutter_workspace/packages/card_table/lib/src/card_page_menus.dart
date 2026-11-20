import 'package:session/session.dart';

/// Visible entries from the routed Vue pages, not permission to execute writes.
/// Keep account actions and card-context actions separate from these menus.
abstract final class CardPageMenus {
  static List<String> moreFor(
    BusinessSystem system, {
    Set<int> moduleIds = const {},
    bool safeModeEnabled = false,
  }) {
    if (system != BusinessSystem.booking && safeModeEnabled) return const [];
    return switch (system) {
      BusinessSystem.booking => _booking,
      BusinessSystem.order => <String>[
        '低消进度统计表',
        '鸡尾酒明细表',
        if (moduleIds.contains(5)) '估清商品',
      ],
      BusinessSystem.cashier => _cashier,
      BusinessSystem.wine => const <String>[],
      BusinessSystem.queue => const <String>[],
      BusinessSystem.bms => const <String>[],
      BusinessSystem.erp => const <String>[],
      BusinessSystem.erpWarehouse => const <String>[],
      BusinessSystem.vip => const <String>[],
      BusinessSystem.superAdmin => const <String>[],
    };
  }

  // src/views/Book/cardMachine.vue:352
  static const _booking = <String>[
    '开台记录',
    '转台记录',
    '预留记录',
    '线上预订记录',
    '入客数据实时汇总',
    '部门实时订台/区域开台',
    '排队详情',
  ];

  // src/views/Money/moneyCard.vue:392 (excluding commented-out entries).
  static const _cashier = <String>[
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
  ];
}
