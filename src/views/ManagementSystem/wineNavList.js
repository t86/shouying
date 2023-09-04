export default [{
  name: "存酒管理",
  sys_priv: [3],
  system: ["wine"],
  img: "save_wine_manage.png",
  content: [
    {
      name: "存酒待入库",
      url: "/wine/saveNeedToLib"
    },
    {
      name: "取酒待出库",
      url: "/wine/getNeedToLib"
    },
    {
      name: "存酒库",
      url: "/wine/saveLib"
    },
    {
      name: "过期待处理",
      url: "/wine/passTime"
    },
    {
      name: "存酒库库存",
      url: "/wine/saveLibAllData"
    }
  ]
},{
  name: "充公管理",
  sys_priv: [3],
  system: ["wine"],
  img: "confiscation_manage.png",
  content: [
    {
      name: "待充公",
      url: "/wine/toStore"
    },
    {
      name: "充公库",
      url: "/wine/storeLib"
    },
    {
      name: "充公出库单",
      url: "/wine/toStoreDetail"
    }
  ]
},
{
  name: "用户管理",
  sys_priv: [3],
  system: ["wine"],
  img: "user_manage1.png",
  content: [
    {
      name: "用户管理",
      url: "/wine/userConfig"
    }
  ]
},
{
  name: "客户中心存酒",
  sys_priv: [3],
  system: ["wine"],
  img: "customer_center_store_wine.png",
  content: [
    {
      name: "待入库",
      url: "/wine/customSaveLib"
    },
    {
      name: "取酒",
      url: "/wine/customGetLib"
    }
  ]
},
{
  name: "报表管理",
  sys_priv: [3],
  system: ["wine"],
  img: "report_manage1.png",
  content: [
    {
      name: "存取酒记录",
      url: "/wine/saveAndGetReport"
    },
    {
      name: "延期记录",
      url: "/wine/passTimeLongReport"
    },
    {
      name: "充公出库记录",
      url: "/wine/toStoreOutReport"
    },
    {
      name: "入库统计",
      url: "/wine/saveAllDataReport"
    },
    {
      name: "出库统计",
      url: "/wine/getAllDataReport"
    },
    {
      name: "充公统计",
      url: "/wine/toStoreAllDataReport"
    },
    {
      name: "存酒查询",
      url: "/wine/saveWineSearch"
    }
  ]
}
]