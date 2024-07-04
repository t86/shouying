/**
 * shouyin\trunk\src\views\Thelogin\cardMachine.vue 页面用到的相关基础数据相关配置
 */
import allRight from '@/assets/card-imgs/allright.png'
// cardOptions图片

import icon1 from '@/assets/card-imgs/cardOptions/yuding.png'
import icon2 from '@/assets/card-imgs/cardOptions/kaitai.png'
import icon3 from '@/assets/card-imgs/cardOptions/chakankataixiaofei.png'
import icon4 from '@/assets/card-imgs/cardOptions/xiugaifantaidingweiren.png'
import icon5 from '@/assets/card-imgs/cardOptions/suoding.png'
import icon6 from '@/assets/card-imgs/cardOptions/quxiaosuoding.png'
import icon7 from '@/assets/card-imgs/cardOptions/zhuantai.png'
import icon8 from '@/assets/card-imgs/cardOptions/xiugaiyuding.png'
// import icon9 from '@/assets/card-imgs/cardOptions/xiugaifantaidingweiren.png'
import icon10 from '@/assets/card-imgs/cardOptions/xiugaidixiao.png'
import icon11 from '@/assets/card-imgs/cardOptions/xiugaidingweiren.png'
import icon12 from '@/assets/card-imgs/cardOptions/chetai.png'
import icon13 from '@/assets/card-imgs/cardOptions/xiugaikaitaileixing.png'
import icon14 from '@/assets/card-imgs/cardOptions/chakankataixiangqing.png'
import icon15 from '@/assets/card-imgs/cardOptions/quxiaoyuding.png'
import icon16 from '@/assets/card-imgs/cardOptions/clear.png'
import icon18 from '@/assets/card-imgs/cardOptions/top-card.png'
import icon19 from '@/assets/card-imgs/cardOptions/cancel-top-card.png'
import icon20 from '@/assets/card-imgs/cardOptions/update-card-tips.png'
import icon21 from '@/assets/card-imgs/cardOptions/remark.png'


// 后台返回数据对应key值的字段名称
export const resResultDataArr = [
  'areaInfo',            // 0-区域信息
  'cardInfo',            // 1-卡台信息
  'firstCategoryInfo',   // 2-商品一级分类
  'secondCategoryInfo',  // 3-商品二级分类
  'goodsAroundInfo',     // 4-商品/套餐
  'orderPersonInfo',     // 5-定位人（员工）信息
  'departmentInfo',      // 6-部门信息
  'jobInfo',             // 7-岗位信息
  'prdOutOfSomething',   // 8-商品估清
  'goodsDetailInfo',     // 9-套餐明细
  'inventoryWarnInfo',   // 10-库存预警
  'jobLimitInfo',        // 11-岗位不限可点商品权限
  'jobSecondLimitInfo',  // 12-岗位可点二级分类商品权限
  'sysRole',             // 13-系统角色
  'businessData',        // 14-业务数据
  'stationArea',         // 15-岗位(服务员)可点区域
  'areaProduct',         // 16-区域可点商品 
  'payList',             // 17-支付渠道
  'storeStatusInfo',     // 18-营业信息
  'requireType',         // 19-要求类型
  'requireItem',         // 20-要求项
  'secondCategoryRequireConfig',  // 21-二级分类要求配置
  'needBackOrderListCount',  // 22-退款待处理订单
  'refreshAll',          // 23-全量刷新业务数据标记
  'canDoList',           // 24-咨客可操作日期列表(只会全量读取,不需要考虑增量的问题)
  'nextDayData',         // 25-未来(当日以后的)预留业务数据
  'lineOrBookCard',      // 26-线上卡台标记
  'authFlowerPrdList',   // 27-角色关联花篮,小费商品权限
  'turnLineBottomCard',  // 28-当前营业日已转线下卡台
  'topCard',             // 29-咨客台置顶卡台
  'outputLibrary',       // 30-出品库信息
  'tipsList',            // 31-卡台标签定义
  'reasonList',          // 32-理由定义
  'accountOfGZ',         // 33-挂账账户
  'payListFilter',       // 34-支付渠道过滤
  'showAmt',             // 35-预定系统卡台是否显示金额
  'roleLimitConfig',     // 36-角色限额限量配置
  'limitPrdDetail',      // 37-限额限量实际明细商品(最终效果)
  'merchantInfo',        // 38-商户号收款金额汇总
  'cardStatusNo',        // 39-卡台状态数量统计
  'machineArea',         // 40-设备可操作区域或卡台
  'sysRoleDetail',       // 41-系统角色明细
  'orderPrdList',       // 42-可点商品配置
  'frontVersion',       // 43-前端版本号
  'funcOrderPrdConfig', // 44-功能台可点商品配置
  'shopManagerConfig', // 45-店长配置
]

// 图例列表
export const legendList = [{
  id: 1,
  name: '空台',
  allRight,
},
{
  id: 2,
  name: '锁定',
  allRight
},
{
  id: 8,
  name: '预订',
  allRight
}, {
  id: 4,
  name: '开台',
  allRight
}, {
  id: 5, // 6 半结 并入点单
  name: '点单',
  allRight
}, {
  id: 7,
  name: '已结',
  allRight
}, {
  id: 20,
  name: '抵达数',
  allRight
}]

// 点击卡片出现对应的操作选项总和
export const cardOptions = [
  {
    id: 1,
    name: '预留',
    icon: icon1
  },
  {
    id: 2,
    name: '开台',
    icon: icon2
  },
  {
    id: 3,
    name: '查看卡台消费',
    icon: icon3
  },
  {
    id: 4,
    name: '修改翻台订位人',
    icon: icon4
  },
  {
    id: 5,
    name: '锁定',
    icon: icon5
  },
  {
    id: 6,
    name: '取消锁定',
    icon: icon6
  },
  {
    id: 7,
    name: '转台',
    icon: icon7
  },
  {
    id: 8,
    name: '修改预留',
    icon: icon8
  },
  {
    id: 10,
    name: '修改低消',
    icon: icon10
  },
  {
    id: 11,
    name: '修改订位人',
    icon: icon11
  },
  {
    id: 12,
    name: '撤台',
    icon: icon12
  },
  {
    id: 13,
    name: '修改开台类型',
    icon: icon13
  },
  {
    id: 14,
    name: '查看卡台详情',
    icon: icon14
  },
  {
    id: 15,
    name: '取消预留',
    icon: icon15
  },
  {
    id: 16,
    name: '清台',
    icon: icon16
  },
  {
    id: 17,
    name: '转为线下卡台',
    icon: icon7
  },
  {
    id: 18,
    name: '置顶',
    icon: icon18
  },
  {
    id: 19,
    name: '取消置顶',
    icon: icon19
  },
  {
    id: 20,
    name: '修改卡台标记',
    icon: icon20
  },
  {
    id: 21,
    name: '修改备注',
    icon: icon21
  },
  {
    id: 22,
    name: '多台预留',
    icon: icon1
  },
  {
    id: 23,
    name: '修改服务员',
    icon: icon11
  },
]

// 开台类型
export const openTypeList = [
  {
    id: 1,
    name: '消费开台'
  },
  {
    id: 2,
    name: '内招开台'
  },
  {
    id: 3,
    name: '外招开台'
  },
  {
    id: 4,
    name: '气氛开台'
  },
  {
    id: 5,
    name: '全转'
  },
  {
    id: 6,
    name: '半转'
  },
]


// 赠送类型authType
export const authTypeListAll = [
  // 授权类型:1服务员可点商品 2经营赠送 3 内招 5 外招 6 自用 8 特饮关联
  {
    id: '1',
    name: '服务员可点商品'
  },
  {
    id: '2',
    name: '优惠'
  },
  {
    id: '3',
    name: '优惠2'
  },
  // {
  //   id: '5',
  //   name: '外部招待'
  // },
  {
    id: '6',
    name: '自用'
  },
  {
    id: '8',
    name: '特饮关联'
  },
]
// // 赠送类型authType
// export const authTypeListAll = [
//   // 授权类型:1服务员可点商品 2经营赠送 3 内招 5 外招 6 自用 8 特饮关联
//   {
//     id: '1',
//     name: '服务员可点商品'
//   },
//   {
//     id: '2',
//     name: '经营赠送'
//   },
//   {
//     id: '3',
//     name: '内部招待'
//   },
//   {
//     id: '5',
//     name: '外部招待'
//   },
//   {
//     id: '6',
//     name: '自用'
//   },
//   {
//     id: '8',
//     name: '特饮关联'
//   },
// ]


export const orderSaveWineOptions = [
  {
    icon: require('@/assets/order-img/icon-save.png'),
    id: 1,
    name: "存酒"
  },
  {
    icon: require('@/assets/order-img/icon-get.png'),
    id: 2,
    name: "取酒"
  },
  {
    icon: require('@/assets/order-img/icon-cg.png'),
    id: 3,
    name: "充公"
  },
]