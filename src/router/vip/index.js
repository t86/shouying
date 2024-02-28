export default [
  {
    path: "/vipNav",
    name: "vipNav",
    meta: { title: "会员管理" },
    component: () => import("@/views/vip/vipNav.vue"),
    redirect: "/vipManager",
    children: [
      // 会员管理
      {
        path: "/vipManager",
        name: "vipManager",
        meta: { title: "会员管理" },
        component: () => import("@/views/vip/vipManager.vue"),
      },
      // 会员卡管理
      {
        path: "/vipType",
        name: "vipType",
        meta: { title: "会员卡类型" },
        component: () => import("@/views/vip/vipType.vue"),
      },
      // 积分设置
      {
        path: "/pointManager",
        name: "pointManager",
        meta: { title: "积分榜管理" },
        component: () => import("@/views/vip/pointManager.vue"),
      },
      // 会员卡充值设置
      {
        path: "/onlineMakeMoneyToVip",
        name: "onlineMakeMoneyToVip",
        meta: { title: "会员卡充值设置" },
        component: () => import("@/views/vip/onlineMakeMoneyToVip.vue"),
      },
      // 会员卡号生成规则
      {
        path: "/vipNumRules",
        name: "vipNumRules",
        meta: { title: "会员卡号生成规则" },
        component: () => import("@/views/vip/vipNumRules.vue"),
      },
      // // 会员卡结账规则
      // {
      //   path: "/vipBillRules",
      //   name: "vipBillRules",
      //   meta: { title: "会员卡号生成规则" },
      //   component: () => import("@/views/vip/vipBillRules.vue"),
      // },
      // 充值记录
      {
        path: "/makeMoneyToVip",
        name: "makeMoneyToVip",
        meta: { title: "充值记录" },
        component: () => import("@/views/vip/makeMoneyToVip.vue"),
      },
      // 消费记录
      {
        path: "/payMoneyAll",
        name: "payMoneyAll",
        meta: { title: "消费记录" },
        component: () => import("@/views/vip/payMoneyAll.vue"),
      },
      // 会员卡记录
      {
        path: "/vipPay",
        name: "vipPay",
        meta: { title: "会员卡记录" },
        component: () => import("@/views/vip/vipPay.vue"),
      },
      // 积分记录
      {
        path: "/pointRecords",
        name: "pointRecords",
        meta: { title: "积分记录" },
        component: () => import("@/views/vip/pointRecords.vue"),
      },
      // 会员卡余额汇总表
      {
        path: "/memberBalanceSum",
        name: "memberBalanceSum",
        meta: { title: "会员卡余额汇总表" },
        component: () => import("@/views/vip/memberBalanceSum.vue"),
      },
      // 会员消费排名表
      {
        path: "/memberConsumeRank",
        name: "memberConsumeRank",
        meta: { title: "会员消费排名表" },
        component: () => import("@/views/vip/memberConsumeRank.vue"),
      },
      // 客户关系维护表
      {
        path: "/customerRelationShipMaintence",
        name: "customerRelationShipMaintence",
        meta: { title: "客户关系维护表" },
        component: () => import("@/views/vip/customerRelationShipMaintence.vue"),
      },
      // 注销记录表
      {
        path: "/logoutRecordForm",
        name: "logoutRecordForm",
        meta: { title: "注销记录表" },
        component: () => import("@/views/vip/logoutRecordForm.vue"),
      },
    ],
  },
];
