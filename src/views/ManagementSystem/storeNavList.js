export default [
  // // 门店管理后台
        // {
        //   name: "开店助手",
        //   sys_priv: [1],
        //   system: ["org_mgr"],
        //   img: "shop_assistant.png",
        //   content: [
        //     {
        //       name: "开店向导",
        //       url: "/BMS/printer"
        //     }
        //   ]
        // }, //开店助手
        
        {
          name: "人员管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "people_manage.png",
          content: [
            {
              name: "工号生成规则",
              url: "/BMS/codeRules"
            },
            // {
            //   name: "工号生成规则(old)",
            //   url: "/BMS/genRule"
            // },
            {
              name: "岗位管理",
              url: "/BMS/stationConfig"
            },
            // {
            //   name: "岗位管理(old)",
            //   url: "/BMS/station"
            // },
            {
              name: "部门员工管理",
              url: "/BMS/employeeList"
            },
            // {
            //   name: "部门员工管理(old)",
            //   url: "/BMS/dept"
            // }
          ]
        }, //商品管理
        {
          name: "商品管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "commodity_manage.png",
          content: [
            {
              name: "商品管理",
              url: "/BMS/prdConfig"
            },
            // {
            //   name: "商品管理(old)",
            //   url: "/BMS/Prds"
            // },
            {
              name: "批量上传图片",
              url: "/BMS/uploadProImg"
            },
            {
              name: "商品非会员价",
              url: "/BMS/vipPrice"
            }
          ]
        }, //商品管理
        {
          name: "卡台管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "card_manage.png",
          content: [
            //            {
            //              name:'区域管理',
            //              url:'/BMS/region'
            //            },
            //            {
            //              name:'卡台管理',
            //              url:'/BMS/Seat'
            //            },
            {
              name: "卡台管理",
              url: "/BMS/cardConfig"
            },
            // {
            //   name: "卡台管理(old)",
            //   url: "/BMS/seats"
            // },
            {
              name: "卡台低消组",
              url: "/BMS/cardMinGroup"
            },
            // {
            //   name: "卡台低消组(old)",
            //   url: "/BMS/seat_grp"
            // },
            {
              name: "卡台标签",
              url: "/BMS/cardTips"
            },
            {
              name: "计抵达规则",
              url: "/BMS/arriveRules"
            }
          ]
        },  //限额限量管理
        {
          name: "限额限量管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "commodity_group_manage.png",
          content: [
            {
              name: "商品组管理",
              url: "/BMS/prdGroupConfig"
            },
            // {
            //   name: "商品组管理(old)",
            //   url: "/BMS/pgrp"
            // },
            {
              name: "限额限量管理",
              url: "/BMS/limitConfig"
            },
            // {
            //   name: "限额限量管理(old)",
            //   url: "/BMS/freelmt"
            // },
          ]
        }, 


        {
          name: "门店信息",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "store_manage.png",
          content: [
            {
              name: "门店信息",
              url: "/BMS/store"
            },
            {
              name: "营业日管理",
              url: "/BMS/restore"
            },
          ]
        }, //门店管理
        {
          name: "支付管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "payed_manage.png",
          content: [
            {
              name: "渠道管理",
              url: "/BMS/payList"
            },
            // {
            //   name: "渠道管理(old)",
            //   url: "/BMS/Paycnl"
            // }
          ]
        }, //支付管理
        {
          name: "设备管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "device_manage.png",
          content: [
            {
              name: "打印机管理",
              url: "/BMS/printers"
            },
            // {
            //   name: "打印机管理(old)",
            //   url: "/BMS/printer"
            // },
            {
              name: "出品库管理",
              url: "/BMS/outLibConfig"
            },
            // {
            //   name: "出品库管理(old)",
            //   url: "/BMS/mklib"
            // },
            {
              name: "小票管理",
              url: "/BMS/bills"
            },
            // {
            //   name: "小票管理(old)",
            //   url: "/BMS/bill"
            // },
            {
              name: "终端管理",
              url: "/BMS/terminalBms"
            }
          ]
        },
        {
          name: "收银报表配置",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "report_manage1.png",
          content: [
            {
              name: "鸡尾酒导出配置",
              url: "/BMS/reportTYConfig"
            },
            {
              name: "销售商品统计设置",
              url: "/BMS/sealPrdConfig"
            },
            {
              name: "统计类别配置",
              url: "/BMS/statisticalGroupConfig"
            },
            {
              name: "渠道类别配置",
              url: "/BMS/channelGroupConfig"
            }
          ]
        },
        {
          name: "小程序报表",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "report_manage1.png",
          content: [
            {
              name: "高毛利商品配置",
              url: "/BMS/miniProgressConfig"
            },
          ]
        },
        {
          name: "要求管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "request_manage.png",
          content: [
            {
              name: "要求管理",
              url: "/BMS/requireConfig"
            },
            // {
            //   name: "要求管理(old)",
            //   url: "/BMS/requires"
            // }
          ]
        },
        {
          name: "理由管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "reason_manage.png",
          content: [
            {
              name: "优惠理由管理",
              url: "/BMS/YHReason"
            },
            {
              name: "退单理由管理",
              url: "/BMS/backReason"
            },
            {
              name: "退卡理由管理",
              url: "/BMS/backVipCard"
            },
            {
              name: "取消优惠理由管理",
              url: "/BMS/QXYHReason"
            }
          ]
        },
        {
          name: "业务配置",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "service_config.png",
          content: [
            {
              name: "规则配置",
              url: "/BMS/terminalRules"
            },
            {
              name: "会员卡规则",
              url: "/BMS/vipRules"
            }
          ]
        },        
        {
          name: "存酒管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "save_wine_manage.png",
          content: [
            {
              name: "存酒设置",
              url: "/BMS/saveConfig"
            },
            {
              name: "可存酒水",
              url: "/BMS/wineInfo"
            }
          ]
        },
        {
          name: "抽成管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "request_manage.png",
          content: [
            {
              name: "抽成管理",
              url: "/BMS/cutPrd"
            }
          ]
        },
        {
          name: "短信管理",
          sys_priv: [1],
          system: ["org_mgr"],
          img: "request_manage.png",
          content: [
            {
              name: "账户管理",
              url: "/BMS/accountInfo"
            },
            {
              name: "短信明细",
              url: "/BMS/messageDetail"
            },
            {
              name: "短信结果查询",
              url: "/BMS/messageResult"
            }
          ]
        },
]