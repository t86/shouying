export default [
  {
    name: "首页",
    sys_priv: [2],
    system: ['erp', "erpAdmin"],
    img: "开店助手.png",
    content: [
      {
        name: "首页",
        url: "/ERP/home"
      }
    ]
  },
  {
    name: "erp仓库管理",
    sys_priv: [2],
    system: ["erpAdmin"],
    img: "erp仓库管理.png",
    content: [
      {
        name: "erp仓库管理",
        url: "/ERP/erpLib"
      }
    ]
  },
  {
    name: "物料管理",
    sys_priv: [2],
    system: ["erpAdmin"],
    img: "物料管理.png",
    content: [
      // new
      {
        name: "物料管理",
        url: "/ERP/mats"
      },
      // old
      // {
      //   name: "物料管理(old)",
      //   url: "/ERP/mat"
      // },
      {
        name: "商品对照",
        url: "/ERP/comparePrd"
      }
    ]
  },
  {
    name: "入库管理",
    sys_priv: [2],
    system: ["erp", 'erpAdmin'],
    img: "入库管理.png",
    content: [
      {
        name: "其他入库",
        url: "/ERP/anotherInLib"
      },
      // {
      //   name: "其他入库(old)",
      //   url: "/ERP/sin"
      // },
      {
        name: "调拨入库",
        url: "/ERP/changeInLib"
      },
      // {
      //   name: "调拨入库(old)",
      //   url: "/ERP/sind"
      // },
      {
        name: "异议订单",
        url: "/ERP/applyForInLib"
      },
      // {
      //   name: "异议订单(old)",
      //   url: "/ERP/sindd_yy"
      // }
    ]
  },
  {
    name: "出库管理",
    sys_priv: [2],
    system: ["erp", 'erpAdmin'],
    img: "出库管理.png",
    content: [
      {
        name: "其他出库",
        url: "/ERP/anotherOutLib"
      },
      // {
      //   name: "其他出库(old)",
      //   url: "/ERP/sout"
      // },
      {
        name: "调拨出库",
        url: "/ERP/changeOutLib"
      },
      // {
      //   name: "调拨出库(old)",
      //   url: "/ERP/soutd"
      // },
      {
        name: "异议订单",
        url: "/ERP/applyForOutLib"
      },
      // {
      //   name: "异议订单(old)",
      //   url: "/ERP/soutdd_yy"
      // }
    ]
  },
  {
    name: "供应商管理",
    sys_priv: [2],
    system: ["erpAdmin"],
    img: "供应商管理.png",
    content: [
      {
        name: "供应商管理",
        url: "/ERP/supplierConfig"
      },
      // {
      //   name: "供应商管理(old)",
      //   url: "/ERP/supplier"
      // }
    ]
  }, 
  {
    name: "空瓶管理",
    sys_priv: [2],
    system: ["erpAdmin"],
    needAuth: true,  // 需要权限配置
    auth: ['erp'],  // erp仓库管理员需要进行相应的岗位权限配置
    img: "空瓶管理.png",
    content: [
      {
        name: "空瓶入库单",
        url: "/ERP/emptyInLibOrder"
      },
      {
        name: "空瓶仓",
        url: "/ERP/emptyLib"
      },
      {
        name: "空瓶出库单",
        url: "/ERP/emptyOutLibOrder"
      },
    ]
  }, 
  {
    name: "报表管理",
    sys_priv: [2],
    system: ["erp", 'erpAdmin'],
    img: "报表管理.png",
    content: [
      {
        name: "物料实时库存表",
        url: "/ERP/matLibNow"
      },
      {
        name: "物料库存表",
        url: "/ERP/matLib"
      },
      // {
      //   name: "物料库存表(old)",
      //   url: "/ERP/month_invs"
      // },
      {
        name: "入库明细表",
        url: "/ERP/inLibRep"
      },
      // {
      //   name: "入库明细表(old)",
      //   url: "/ERP/in_recs"
      // },
      {
        name: "出库明细表",
        url: "/ERP/outLibRep"
      },
      // {
      //   name: "出库明细表(old)",
      //   url: "/ERP/out_recs"
      // },
      {
        name: "入库汇总表",
        url: "/ERP/inLibAllRep"
      },
      // {
      //   name: "入库汇总表(old)",
      //   url: "/ERP/in_sum"
      // },
      {
        name: "出库汇总表",
        url: "/ERP/outLibAllRep"
      },
      // {
      //   name: "出库汇总表(old)",
      //   url: "/ERP/out_sum"
      // },
      {
        name: "空瓶入库明细表",
        url: "/ERP/emptyInLib"
      },
      {
        name: "空瓶出库明细表",
        url: "/ERP/emptyOutLib"
      }
    ]
  }, 
]