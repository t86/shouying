export default [
  {
    id: 0,
    name: "返回",
    icon: require("@/assets/vip-imgs/back.png"),
    hoverIcon: require("@/assets/vip-imgs/back-hover.png"),
    children: [],
  },
  {
    id: 1,
    name: "首页",
    icon: require("@/assets/vip-imgs/index.png"),
    hoverIcon: require("@/assets/vip-imgs/index-hover.png"),
    children: [],
  },
  {
    id: 2,
    name: "会员管理",
    icon: require("@/assets/vip-imgs/vip.png"),
    hoverIcon: require("@/assets/vip-imgs/vip-hover.png"),
    children: [
      {
        id: 21,
        name: "会员管理",
        routerName: "vipManager",
      },
      {
        id: 22,
        name: "会员卡类型",
        routerName: "vipType",
      },
      // {
      //   id: 23,
      //   name: "积分设置",
      //   routerName: "pointManager",
      // },
    ],
  },
  {
    id: 3,
    name: "业务配置",
    icon: require("@/assets/vip-imgs/config.png"),
    hoverIcon: require("@/assets/vip-imgs/config-hover.png"),
    children: [
      // {
      //   id: 31,
      //   name: "会员卡充值设置",
      //   routerName: "onlineMakeMoneyToVip",
      // },
      {
        id: 32,
        name: "会员卡号生成规则",
        routerName: "vipNumRules",
      },
      // {
      //   id: 33,
      //   name: "会员卡结账规则",
      //   routerName: "vipBillRules",
      // },
    ],
  },
  {
    id: 4,
    name: "报表管理",
    icon: require("@/assets/vip-imgs/report.png"),
    hoverIcon: require("@/assets/vip-imgs/report-hover.png"),
    children: [
      {
        id: 41,
        name: "充值记录",
        routerName: "makeMoneyToVip",
      },
      {
        id: 42,
        name: "消费记录",
        routerName: "payMoneyAll",
      },
      {
        id: 43,
        name: "扣款记录",
        routerName: "vipPay",
      },
      {
        id: 44,
        name: "积分记录",
        routerName: "pointRecords",
      },
      {
        id: 45,
        name: "会员卡余额汇总表",
        routerName: "memberBalanceSum",
      },
      {
        id: 46,
        name: "会员消费排名表",
        routerName: "memberConsumeRank",
      },
      {
        id: 47,
        name: "客户关系维护表",
        routerName: "customerRelationShipMaintence",
      },
      {
        id: 48,
        name: "注销记录表",
        routerName: "logoutRecordForm",
      },
      {
        id: 49,
        name: "更改等级记录表",
        routerName: "changeLevelRecordForm",
      },
    ],
  },
];
