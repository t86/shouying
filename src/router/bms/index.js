export default [
  /**
   * 人员管理
   */
  // 工号生成规则
  {
    path: '/BMS/codeRules', name: "codeRules", meta: { title: '工号生成规则' },
    component: () => import('@/views/ManagementSystem/BMS/codeRules/codeRules.vue')
  },
  // 岗位管理
  {
    path: '/BMS/stationConfig', name: "stationConfig", meta: { title: '岗位管理' },
    component: () => import('@/views/ManagementSystem/BMS/stationConfig/stationConfig.vue')
  },
  // 员工管理
  {
    path: '/BMS/employeeList', name: "employeeList", meta: { title: '员工管理' },
    component: () => import('@/views/ManagementSystem/BMS/employeeList/employeeList.vue')
  },

  /**
   * 商品管理
   */
  // 商品管理
  {
    path: '/BMS/prdConfig', name: "prdConfig", meta: { title: '商品管理' },
    component: () => import('@/views/ManagementSystem/BMS/prdConfig/prdConfig.vue')
  },
  // 批量上传商品图片
  {
    path: '/BMS/uploadProImg', name: "uploadProImg", meta: { title: '批量上传商品图片' },
    component: () => import('@/views/ManagementSystem/BMS/uploadProImg/uploadProImg.vue'),
  },

  /**
   * 卡台管理
   */
  // 卡台管理
  {
    path: '/BMS/cardConfig', name: "cardConfig", meta: { title: '卡台管理' },
    component: () => import('@/views/ManagementSystem/BMS/cardConfig/cardConfig.vue')
  },
  // 卡台抵消组
  {
    path: '/BMS/cardMinGroup', name: "cardMinGroup", meta: { title: '卡台抵消组' },
    component: () => import('@/views/ManagementSystem/BMS/cardMinGroup/cardMinGroup.vue')
  },
  // 卡台标签
  {
    path: '/BMS/cardTips', name: "cardTips", meta: { title: '卡台标签' },
    component: () => import('@/views/ManagementSystem/BMS/cardTips/cardTips.vue'),
  },
  // 计抵达规则
  {
    path: '/BMS/arriveRules', name: "arriveRules", meta: { title: '计抵达规则' },
    component: () => import('@/views/ManagementSystem/BMS/arriveRules/arriveRules.vue'),
  },

  /**
   * 限额限量管理
   */
  // 商品组管理
  {
    path: '/BMS/prdGroupConfig', name: "prdGroupConfig", meta: { title: '商品组管理' },
    component: () => import('@/views/ManagementSystem/BMS/prdGroupConfig/prdGroupConfig.vue')
  },
  // 限额限量管理
  {
    path: '/BMS/limitConfig', name: "limitConfig", meta: { title: '限额限量管理' },
    component: () => import('@/views/ManagementSystem/BMS/limitConfig/limitConfig.vue')
  },

  /**
   * 门店信息
   */
  // 门店信息
  {
    path: '/BMS/store', name: "store", meta: { title: '门店信息' },
    component: () => import('@/views/ManagementSystem/BMS/store/store.vue')
  },

  // 门店信息
  {
    path: '/BMS/restore', name: "store", meta: { title: '营业日管理' },
    component: () => import('@/views/ManagementSystem/BMS/store/restore.vue')
  },
 
  /**
   * 支付管理
   */
  // 支付渠道管理
  {
    path: '/BMS/payList', name: "payList", meta: { title: '渠道管理' },
    component: () => import('@/views/ManagementSystem/BMS/payList/payList.vue')
  },

  /**
   * 设备管理
   */
  // 打印机管理
  {
    path: '/BMS/printers', name: "printers", meta: { title: '打印机管理' },
    component: () => import('@/views/ManagementSystem/BMS/printers/printers.vue')
  },
  // 出品库管理
  {
    path: '/BMS/outLibConfig', name: "outLibConfig", meta: { title: '出品库管理' },
    component: () => import('@/views/ManagementSystem/BMS/outLibConfig/outLibConfig.vue')
  },
  // 小票管理
  {
    path: '/BMS/bills', name: "bills", meta: { title: '小票管理' },
    component: () => import('@/views/ManagementSystem/BMS/bills/bills.vue')
  },
  // 终端管理
  {
    path: '/BMS/terminalBms', name: "terminalBms", meta: { title: '终端管理' },
    component: () => import('@/views/ManagementSystem/BMS/terminalBms/terminalBms.vue')
  },

  /**
   * 收银报表配置
   */
  // 鸡尾酒导出配置
  {
    path: '/BMS/reportTYConfig', name: "reportTYConfig", meta: { title: '鸡尾酒导出配置' },
    component: () => import('@/views/ManagementSystem/BMS/reportTYConfig/reportTYConfig.vue')
  },
  // 销售商品统计设置
  {
    path: '/BMS/sealPrdConfig', name: "sealPrdConfig", meta: { title: '分类渠道统计设置' },
    component: () => import('@/views/ManagementSystem/BMS/sealPrdConfig/sealPrdConfig.vue')
  },
  // 统计类别配置
  {
    path: '/BMS/statisticalGroupConfig', name: "statisticalGroupConfig", meta: { title: '统计类别配置' },
    component: () => import('@/views/ManagementSystem/BMS/statisticalGroupConfig/statisticalGroupConfig.vue')
  },
  // 渠道类别配置
  {
    path: '/BMS/channelGroupConfig', name: "channelGroupConfig", meta: { title: '渠道类别配置' },
    component: () => import('@/views/ManagementSystem/BMS/channelGroupConfig/channelGroupConfig.vue')
  },

  /**
   * 小程序报表配置
   */
  // 高毛利商品配置
  {
    path: '/BMS/miniProgressConfig', name: "miniProgressConfig", meta: { title: '高毛利商品配置' },
    component: () => import('@/views/ManagementSystem/BMS/miniProgressConfig/miniProgressConfig.vue')
  },

  /**
   * 要求管理
   */
  // 要求管理
  {
    path: '/BMS/requireConfig', name: "requireConfig", meta: { title: '要求类型' },
    component: () => import('@/views/ManagementSystem/BMS/requireConfig/requireConfig.vue')
  },

  /**
   * 理由管理
   */
  // 优惠理由
  {
    path: '/BMS/YHReason', name: "YHReason", meta: { title: '优惠理由' },
    component: () => import('@/views/ManagementSystem/BMS/reason/reason.vue'),
  },
  // 退单理由
  {
    path: '/BMS/backReason', name: "backReason", meta: { title: '退单理由' },
    component: () => import('@/views/ManagementSystem/BMS/reason/reason.vue'),
  },
  // 退卡理由
  {
    path: '/BMS/backVipCard', name: "backVipCard", meta: { title: '退卡理由' },
    component: () => import('@/views/ManagementSystem/BMS/reason/reason.vue'),
  },
  {
    path: '/BMS/QXYHReason', name: "QXYHReason", meta: { title: '取消优惠理由' },
    component: () => import('@/views/ManagementSystem/BMS/reason/reason.vue'),
  },
  /**
   * 业务配置
   */
  // 规则配置 
  {
    path: '/BMS/terminalRules', name: "terminalRules", meta: { title: '规则配置' },
    component: () => import('@/views/ManagementSystem/BMS/terminalRules/terminalRules.vue')
  },
  // 会员卡规则
  {
    path: '/BMS/vipRules', name: "vipRules", meta: { title: '会员卡规则' },
    component: () => import('@/views/ManagementSystem/BMS/terminalRules/vipRules.vue')
  },

  /**
   * 存酒管理
   */
  // 存酒设置
  {
    path: '/BMS/saveConfig', name: "saveConfig", meta: { title: '存酒设置' },
    component: () => import('@/views/ManagementSystem/BMS/saveWine/saveConfig/saveConfig.vue')
  },
  // 可存酒水
  {
    path: '/BMS/wineInfo', name: "wineInfo", meta: { title: '可存酒水' },
    component: () => import('@/views/ManagementSystem/BMS/saveWine/wineInfo/wineInfo.vue')
  },

  /**
   * 抽成管理
   */
  // 抽成管理
  {
    path: '/BMS/cutPrd', name: 'cutPrd', meta: { title: '抽成管理' }, 
    component: () => import('@/views/ManagementSystem/BMS/cutPrd/cutPrd.vue'),
  },

  /**
   * 短信管理
   */
  // 账户信息
  {
    path: '/BMS/accountInfo', name: 'accountInfo', meta: { title: '账户信息' }, 
    component: () => import('@/views/ManagementSystem/BMS/messageConfig/accountInfo/accountInfo.vue'),
  },
  // 短信明细
  {
    path: '/BMS/messageDetail', name: 'messageDetail', meta: { title: '短信明细' }, 
    component: () => import('@/views/ManagementSystem/BMS/messageConfig/messageDetail/messageDetail.vue'),
  },

  {
    path: '/BMS/messageResult', name: 'messageResult', meta: { title: '短信结果查询' },
    component: () => import('@/views/ManagementSystem/BMS/messageConfig/messageResult.vue'),
  },



  /* =========================================== 以下为重构之前代码 ================================================== */



  // 后台管理系统 >>>> 打印机管理
  {
    path: '/BMS/printer', name: "printer", meta: { title: '打印机' },
    component: () => import('@/views/ManagementSystem/BMS/printer/printer.vue')
  },
  // 后台管理系统 >>>> 出品库管理
  {
    path: '/BMS/mklib', name: "mklib", meta: { title: '出品库' },
    component: () => import('@/views/ManagementSystem/BMS/mklib/mklib.vue')
  },
  // 后台管理系统 >>>> 小票管理
  {
    path: '/BMS/bill', name: "bill", meta: { title: '小票' },
    component: () => import('@/views/ManagementSystem/BMS/bill/bill.vue')
  },
  // 后台管理系统 >>>> 渠道管理
  {
    path: '/BMS/Paycnl', name: "Paycnl", meta: { title: '渠道' },
    component: () => import('@/views/ManagementSystem/BMS/Paycnl/Paycnl.vue')
  },
  // 后台管理系统 >>>> 区域管理
  {
    path: '/BMS/region', name: "region", meta: { title: '区域' },
    component: () => import('@/views/ManagementSystem/BMS/region/region.vue')
  },
  // 后台管理系统 >>>> 卡台
  {
    path: '/BMS/Seat', name: "Seat", meta: { title: '卡台' },
    component: () => import('@/views/ManagementSystem/BMS/Seat/Seat.vue')
  },
  // 后台管理系统 >>>> 卡台管理(新)
  {
    path: '/BMS/seats', name: "seats", meta: { title: '卡台管理(新)' },
    component: () => import('@/views/ManagementSystem/BMS/seats/seats.vue'),
    redirect: "/BMS/seats/region",
    children: [
      // 后台管理系统 >>>> 区域管理
      {
        path: '/BMS/seats/region', name: "region", meta: { title: '区域管理' },
        component: () => import('@/views/ManagementSystem/BMS/seats/region/region.vue')
      },
      // 后台管理系统 >>>> 商品管理
      {
        path: '/BMS/seats/seat/:id', name: "seat", meta: { title: '卡台管理(新)' },
        component: () => import('@/views/ManagementSystem/BMS/seats/seat/seat.vue')
      },
    ]
  },
  // 后台管理系统 >>>> 一级分类
  {
    path: '/BMS/Ocate', name: "Ocate", meta: { title: '一级分类' },
    component: () => import('@/views/ManagementSystem/BMS/Ocate/Ocate.vue')
  },
  // 后台管理系统 >>>> 二级分类
  {
    path: '/BMS/tcate', name: "tcate", meta: { title: '二级分类' },
    component: () => import('@/views/ManagementSystem/BMS/tcate/tcate.vue')
  },
  // 后台管理系统 >>>> 商品管理
  {
    path: '/BMS/Prd', name: "Prd", meta: { title: '商品管理' },
    component: () => import('@/views/ManagementSystem/BMS/Prd/Prd.vue')
  },
  // 后台管理系统 >>>> 商品管理(新)
  {
    path: '/BMS/Prds', name: "Prds", meta: { title: '商品管理' },
    component: () => import('@/views/ManagementSystem/BMS/Prds/prds.vue'),
    redirect: "/BMS/Prds/Ocate",
    children: [
      // 后台管理系统 >>>> 商品一级分类
      {
        path: '/BMS/Prds/Ocate', name: "Ocate", meta: { title: '一级分类' },
        component: () => import('@/views/ManagementSystem/BMS/Prds/Ocate/Ocate.vue')
      },
      // 后台管理系统 >>>> 商品二级分类
      {
        path: '/BMS/Prds/tcate/:id', name: "tcate", meta: { title: '二级分类' },
        component: () => import('@/views/ManagementSystem/BMS/Prds/tcate/tcate.vue')
      },
      // 后台管理系统 >>>> 商品管理
      {
        path: '/BMS/Prds/Prd/:id', name: "Prd", meta: { title: '商品管理' },
        component: () => import('@/views/ManagementSystem/BMS/Prds/Prd/Prd.vue')
      },
    ]
  },

  // 后台管理系统 >>>> 工号生成规则
  {
    path: '/BMS/genRule', name: "genRule", meta: { title: '工号生成规则' },
    component: () => import('@/views/ManagementSystem/BMS/genRule/genRule.vue')
  },
  // 后台管理系统 >>>> 岗位管理
  {
    path: '/BMS/station', name: "station", meta: { title: '岗位管理' },
    component: () => import('@/views/ManagementSystem/BMS/station/station.vue')
  },
  // 后台管理系统 >>>> 部门员工管理
  {
    path: '/BMS/dept', name: "dept", meta: { title: '部门员工管理' },
    component: () => import('@/views/ManagementSystem/BMS/dept/dept.vue'),
    redirect: "/BMS/dept/emp/0",
    children: [
      // 后台管理系统 >>>> 部门员工管理
      {
        path: '/BMS/dept/emp/:id', name: "emp", meta: { title: '部门员工管理' },
        component: () => import('@/views/ManagementSystem/BMS/dept/emp/emp.vue')
      }
    ]
  },

  // 后台管理系统 >>>> 要求管理
  {
    path: '/BMS/requires', name: "requires", meta: { title: '要求管理' },
    component: () => import('@/views/ManagementSystem/BMS/requires/requires.vue'),
    redirect: "/BMS/requires/requireType",
    children: [
      // 后台管理系统 >>>> 要求类型
      {
        path: '/BMS/requires/requireType', name: "requireType", meta: { title: '要求类型' },
        component: () => import('@/views/ManagementSystem/BMS/requires/requireType/requireType.vue')
      },
      // 后台管理系统 >>>> 要求管理
      {
        path: '/BMS/requires/require/:id', name: "require", meta: { title: '要求管理' },
        component: () => import('@/views/ManagementSystem/BMS/requires/require/require.vue')
      },
    ]
  },
  // 后台管理系统 >>>> 卡台低消组
  {
    path: '/BMS/seat_grp', name: "seat_grp", meta: { title: '卡台低消组' },
    component: () => import('@/views/ManagementSystem/BMS/seat_grp/seat_grp.vue')
  },
  // 后台管理系统 >>>> 商品组管理
  {
    path: '/BMS/pgrp', name: "pgrp", meta: { title: '商品组管理' },
    component: () => import('@/views/ManagementSystem/BMS/pgrp/pgrp.vue')
  },
  // 后台管理系统 >>>> 限额限量管理
  {
    path: '/BMS/freelmt', name: "freelmt", meta: { title: '限额限量管理' },
    component: () => import('@/views/ManagementSystem/BMS/freelmt/freelmt.vue')
  },
]