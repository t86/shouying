export default [
  // ERP管理系统 >>>> erp仓库管理
  {
    path: '/ERP/home', name: "home", meta: { title: '首页' },
    component: () => import('@/views/ManagementSystem/ERP/home/home.vue')
  },
  // erp仓库管理
  {
    path: '/ERP/erpLib', name: "stoerpLibre", meta: { title: 'erp仓库管理' },
    component: () => import('@/views/ManagementSystem/ERP/erpLib/erpLib.vue')
  },
  /**
   * 物料管理
   */
  // 物料管理
  {
    path: '/ERP/mats', name: "mats", meta: { title: '物料管理' },
    component: () => import('@/views/ManagementSystem/ERP/mats/mats.vue'),
  },
  // 商品对照
  {
    path: '/ERP/comparePrd', name: "comparePrd", meta: { title: '商品对照' },
    component: () => import('@/views/ManagementSystem/ERP/comparePrd/comparePrd.vue')
  },
  /**
   * 入库管理
   */
  // 其他入库
  {
    path: '/ERP/anotherInLib', name: "mats", meta: { title: '其他入库' },
    component: () => import('@/views/ManagementSystem/ERP/inLib/anotherInLib.vue'),
  },
  // 调拨入库
  {
    path: '/ERP/changeInLib', name: "changeInLib", meta: { title: '调拨入库' },
    component: () => import('@/views/ManagementSystem/ERP/inLib/changeInLib.vue'),
  },
  // 入库异议订单
  {
    path: '/ERP/applyForInLib', name: "applyForInLib", meta: { title: '异议订单' },
    component: () => import('@/views/ManagementSystem/ERP/inLib/applyForInLib.vue'),
  },
  /**
   * 出库管理
   */
  // 其他出库
  {
    path: '/ERP/anotherOutLib', name: "anotherOutLib", meta: { title: '其他出库' },
    component: () => import('@/views/ManagementSystem/ERP/outLib/anotherOutLib.vue'),
  },
  // 调拨出库
  {
    path: '/ERP/changeOutLib', name: "changeOutLib", meta: { title: '调拨出库' },
    component: () => import('@/views/ManagementSystem/ERP/outLib/changeOutLib.vue'),
  },
  // 出库异议订单
  {
    path: '/ERP/applyForOutLib', name: "applyForOutLib", meta: { title: '异议订单' },
    component: () => import('@/views/ManagementSystem/ERP/outLib/applyForOutLib.vue'),
  },
  /**
   * 供应商管理
   */
  // 供应商管理
  {
    path: '/ERP/supplierConfig', name: "supplierConfig", meta: { title: '供应商管理' },
    component: () => import('@/views/ManagementSystem/ERP/supplierConfig/supplierConfig.vue'),
  },
  /**
   * 空瓶管理
   */
  {
    path: '/ERP/emptyInLibOrder', name: "emptyInLibOrder", meta: { title: '空瓶入库单' },
    component: () => import('@/views/ManagementSystem/ERP/emptyConfig/emptyInLibOrder.vue')
  },
  {
    path: '/ERP/emptyLib', name: "emptyLib", meta: { title: '空平仓' },
    component: () => import('@/views/ManagementSystem/ERP/emptyConfig/emptyLib.vue')
  },
  {
    path: '/ERP/emptyOutLibOrder', name: "emptyOutLibOrder", meta: { title: '空瓶出库单' },
    component: () => import('@/views/ManagementSystem/ERP/emptyConfig/emptyOutLibOrder.vue')
  },
  /**
   * 报表管理
   */
  // 物料实时库存表
  {
    path: '/ERP/matLibNow', name: "matLib", meta: { title: '物料实时库存表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/matLibNow.vue')
  },
  // 物料库存表
  {
    path: '/ERP/matLib', name: "matLib", meta: { title: '物料库存表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/matLib.vue')
  },
  // 入库明细表
  {
    path: '/ERP/inLibRep', name: "inLibRep", meta: { title: '入库明细表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/inLibRep.vue')
  },
  // 出库明细表
  {
    path: '/ERP/outLibRep', name: "outLibRep", meta: { title: '出库明细表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/outLibRep.vue')
  },
  // 入库汇总表
  {
    path: '/ERP/inLibAllRep', name: "inLibAllRep", meta: { title: '入库汇总表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/inLibAllRep.vue')
  },
  // 仓库进销存
  {
    path: '/ERP/warehousePSI', name: "warehousePSI", meta: { title: '仓库进销存' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/warehousePSI.vue')
  },
  // 出库汇总表
  {
    path: '/ERP/outLibAllRep', name: "outLibAllRep", meta: { title: '出库汇总表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/outLibAllRep.vue')
  },
  // 空瓶入库明细表
  {
    path: '/ERP/emptyInLib', name: "emptyInLib", meta: { title: '空瓶入库明细表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/emptyInLib.vue')
  },
  // 空瓶出库明细表
  {
    path: '/ERP/emptyOutLib', name: "emptyOutLib", meta: { title: '空瓶出库明细表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/emptyOutLib.vue')
  },


// ================================ 以下为重构之前代码 ============================================





  // ERP管理系统 >>>> 供应商管理
  {
    path: '/ERP/supplier', name: "supplier", meta: { title: '供应商管理' },
    component: () => import('@/views/ManagementSystem/ERP/supplier/supplier.vue')
  },
  // ERP管理系统 >>>> 物料管理
  {
    path: '/ERP/mat', name: "mat", meta: { title: '物料管理' },
    component: () => import('@/views/ManagementSystem/ERP/mat/mat.vue'),
    redirect: "/ERP/mat/mocate",
    children: [
      // ERP管理系统 >>>> 物料一级分类
      {
        path: '/ERP/mat/mocate', name: "mocate", meta: { title: '物料管理' },
        component: () => import('@/views/ManagementSystem/ERP/mat/mocate/mocate.vue')
      },
      // ERP管理系统 >>>> 物料二级分类
      {
        path: '/ERP/mat/mtcate/:id', name: "mtcate", meta: { title: '物料管理' },
        component: () => import('@/views/ManagementSystem/ERP/mat/mtcate/mtcate.vue')
      },
      // ERP管理系统 >>>> 物料管理
      {
        path: '/ERP/mat/mats/:id', name: "mats", meta: { title: '物料管理' },
        component: () => import('@/views/ManagementSystem/ERP/mat/mat/mats.vue')
      },
    ]
  },


  // ERP管理系统 >>>> 物料单位
  {
    path: '/ERP/mat_unit', name: "mat_unit", meta: { title: '物料单位' },
    component: () => import('@/views/ManagementSystem/ERP/mat_unit/mat_unit.vue')
  },
  // ERP管理系统 >>>> 
  // ERP管理系统 >>>> 物料规格
  {
    path: '/ERP/mat_spec', name: "mat_spec", meta: { title: '物料规格' },
    component: () => import('@/views/ManagementSystem/ERP/mat_spec/mat_spec.vue')
  },

  // ERP管理系统 >>>> 入库管理
  {
    path: '/ERP/sin', name: "sin", meta: { title: '入库管理' },
    component: () => import('@/views/ManagementSystem/ERP/sin/sin.vue')
  },
  // ERP管理系统 >>>> 调拨入库
  {
    path: '/ERP/sind', name: "sind", meta: { title: '调拨入库' },
    component: () => import('@/views/ManagementSystem/ERP/sind/sind.vue')
  },
  // ERP管理系统 >>>> 异议订单
  {
    path: '/ERP/sindd_yy', name: "sindd_yy", meta: { title: '异议订单' },
    component: () => import('@/views/ManagementSystem/ERP/sindd_yy/sindd_yy.vue')
  },
  // ERP管理系统 >>>> 出库管理
  {
    path: '/ERP/sout', name: "sout", meta: { title: '出库管理' },
    component: () => import('@/views/ManagementSystem/ERP/sout/sout.vue')
  },
  // ERP管理系统 >>>> 调拨出库
  {
    path: '/ERP/soutd', name: "soutd", meta: { title: '调拨出库' },
    component: () => import('@/views/ManagementSystem/ERP/soutd/soutd.vue')
  },
  // ERP管理系统 >>>> 异议订单
  {
    path: '/ERP/soutdd_yy', name: "soutdd_yy", meta: { title: '异议订单' },
    component: () => import('@/views/ManagementSystem/ERP/soutdd_yy/soutdd_yy.vue')
  },
  /**
   * 报表管理
   */
  // ERP管理系统 >>>> 物料实时库存表
  // {
  //   path: '/ERP/matLib', name: "matLib", meta: { title: '物料实时库存表' },
  //   component: () => import('@/views/ManagementSystem/ERP/rpt_erp/matLib.vue')
  // },
  // ERP管理系统 >>>> 物料库存表
  {
    path: '/ERP/month_invs', name: "month_invs", meta: { title: '物料库存表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/month_invs.vue')
  },
  // ERP管理系统 >>>> 入库明细表
  {
    path: '/ERP/in_recs', name: "in_recs", meta: { title: '入库明细表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/in_recs.vue')
  },
  // ERP管理系统 >>>> 出库明细表
  {
    path: '/ERP/out_recs', name: "out_recs", meta: { title: '出库明细表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/out_recs.vue')
  },
  // ERP管理系统 >>>> 入库汇总表
  {
    path: '/ERP/in_sum', name: "in_sum", meta: { title: '入库汇总表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/in_sum.vue')
  },
  // ERP管理系统 >>>> 出库汇总表
  {
    path: '/ERP/out_sum', name: "out_sum", meta: { title: '出库汇总表' },
    component: () => import('@/views/ManagementSystem/ERP/rpt_erp/out_sum.vue')
  },
]