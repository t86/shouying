/**
 * 后台管理系统
 **/
// this.$api.BMS.prd 
import printer from "./printer"         // printer        打印机
import mklib from "./mklib"             // mklib          出品库
import paycnl from "./paycnl"           // paycnl         支付渠道
import region from "./region"           // region         区域
import seat from "./seat"               // seat           卡台
import ocate from "./ocate"             // ocate          一级分类
import tcate from "./tcate"             // tcate          二级分类
import Prd from "./Prd"                 // Prd            商品
import emp from "./emp"                 // emp            员工
import Org from "./Org"                 // Org            门店
import seat_grp from "./seat_grp"       // seat_grp       门店低消组
import pgrp from "./pgrp"               // pgrp           商品组
import freelmt from "./freelmt"         // freelmt         低消组 限额限量管理
import dept from "./dept"               // dept            部门
import genRule from "./genRule"         // genRule         工号生成规则
import station from "./station"         // station         岗位
import reason from "./reason"           // reason          原因
import bill from "./bill"               // bill            小票
import require from "./require"         // require         要求
import terminal from "./terminal"       // terminal        终端管理  
import terminalRules from "./terminalRules" // terminalRules   终端规则管理  
import cardTips from "./cardTips"       // cardTips         卡台标签  
import saveWine from "./saveWine"       // saveWine         存酒管理
import arriveRules from "./arriveRules" // arriveRules      计抵达规则  
import cutPrd from "./cutPrd"           // cutPrd         抽成管理  
import reportConfig from "./reportConfig" // reportConfig   收银报表配置  
import miniProgressConfig from "./miniProgressConfig" // miniProgressConfig   小程序报表配置
import messageConfig from "./messageConfig" // messageConfig   短信配置
import statiscalConfig from "./statistical" // statisticalGroupConfig   统计类别配置
import channelConfig from "./channel" // channelGroupConfig   渠道类别配置
// import supplier from "./supplier"       // supplier       供应商
// import store from "./store"             // store          epr仓库
// import mocate from "./mocate"           // mocate         物料一级分类
// import mtcate from "./mtcate"           // mtcate         物料二级分类
// import mat_unit from "./mat_unit"       // mat_unit       物料单位

// 线上预定
import online from './online'


export default {
  printer,
  mklib,
  mklib,
  paycnl,
  ocate,
  region,
  seat,
  tcate,
  Prd,
  emp,
  Org,
  seat_grp,
  pgrp,
  freelmt,
  dept,
  genRule,
  station,
  reason,
  bill,
  require,
  terminal,
  terminalRules,
  cardTips,
  saveWine,
  arriveRules,
  cutPrd,
  reportConfig,
  miniProgressConfig,
  messageConfig,
  statiscalConfig,
  channelConfig,
  // supplier,
  // store,
  // mocate,
  // mtcate,
  // mat_unit,


  online,
};