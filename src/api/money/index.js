import base from "../base.js"; // 导入接口域名列表
import axios from "../../utils/http.js"; // 导入http中创建的axios实例
export default {
  /**
   * 收银系统
   */
  // 获取对应卡台的支付渠道(待结算类似购物车)列表
  reqGetCardPayList: (params) =>
    axios.post(`${base.htgl}/sel/cart_items`, params),

  // 更改套餐明细（收银端，不需要授权）
  reqUpdateGroupProductDetail: (params) =>
    axios.post(`${base.htgl}/sel/chg_prd_set_dtl`, params),

  // 支付渠道加入待结算流水购物车
  reqAddPayListToShopping: (params) =>
    axios.post(`${base.htgl}/sel/cart_add_cnl`, params),

  // 添加滞留金渠道到购物车
  reqAddBookAmtToShopping: (params) =>
    axios.post(`${base.htgl}/sel/cart_add_late_cnl`, params),

  // 删除待结算流水购物车的支付渠道(需提供header.tk)
  reqDelPayListFromShopping: (params) =>
    axios.post(`${base.htgl}/sel/cart_del_cnl`, params),

  // 授权支付渠道加入待结算流水购物车,暂时只支持抹零渠道pay_cnl_id=10
  reqAddShoppingFromZero: (params) =>
    axios.post(`${base.htgl}/sel/cart_add_auth_cnl`, params),

  // 切换先后买单
  reqTogglePayType: (params) =>
    axios.post(`${base.htgl}/sel/chg_settle_mode`, params),

  // 并台,暂时只支持操作优惠2订单
  reqMergeYh2Order: (params) =>
    axios.post(`${base.htgl}/sel/move_order`, params),

  // 转单
  reqMoveWkOrder: (params) =>
  axios.post(`${base.htgl}/sel/move_wk_order`, params),
  
  // 批量转单,针对已付款订单
  /*POST请求 http://ip_or_domain:port/sel/move_payed_wk_order
  客户端传入json:
    seat_id    int64      //SeatId 转出卡台Id
    dest_seat_id int64      //DestSeatId 转入卡台Id
    pay_id     int64      //PayId 支付订单Id
    total_amt  int64      //TotalAmt 待转涉及的总金额,单位分
  成功返回编码:1, 返回json:
    无
  普通失败, 返回编码<>1, 数据为空*/
  move_payed_wk_order: (params) => axios.post(`${base.htgl}/sel/move_payed_wk_order`, params),

  // 线上支付订单转线下
  reqOnlineOrderToOrgOrder: (params) =>
    axios.post(`${base.htgl}/sel/conv_ol_order_local`, params),

  // 线上支付订单强制转线下（将线上部分付款订单,转为线下预留金）
  reqOnlineOrderForceToOrgOrder: (params) =>
    axios.post(`${base.htgl}/sel/conv_ol_pay_local_late`, params),

  // 读取云端订单转线下结果
  reqOnlineOrderToOffIsSuccess: (params) =>
    axios.post(`${base.htgl}/sel/get_conv_ol_to_org_status`, params),

  // 收银强制取消服务员买单,解锁订单
  reqCancelClockOrder: (params) =>
    axios.post(`${base.htgl}/sel/force_cancel_waiter_olpay`, params),

  // 线上下单,线上支付订单,立即出品
  reqOnlineOrderToFirst: (params) =>
    axios.post(`${base.htgl}/sel/ol_order_do_cp`, params),

  // 结账
  reqPayOrder: (params) => axios.post(`${base.htgl}/sel/pay_order`, params),

  // 客人付款码支付
  reqCustomerPaymentCodePay: (params) => 
    axios.post(`${base.htgl}/sel/customer_payment_code_pay`, params),

  // 获取对应卡台的指定翻台的订单和支付信息
  reqGetCardPayInfo: (params) =>
    axios.post(`${base.htgl}/sel/csm_orders`, params),

  // 确认支付后退单
  reqPayedBackOrder: (params) =>
    axios.post(`${base.htgl}/sel/pay_order_back`, params),

  // 打印结算单
  reqPrintResultOrder: (params) =>
    axios.post(`${base.htgl}/sel/prt_sel_bill`, params),

  // 打印优惠2消费单
  reqPrintYH2Order: (params) =>
    axios.post(`${base.htgl}/wo/prt_csm_yh2_bill`, params),

  // 清台
  reqClearCard: (params) => axios.post(`${base.htgl}/sel/seat_clean`, params),

  // 读取待复台流水
  reqGetSeatTurnbackList: (params) =>
    axios.post(`${base.htgl}/sel/get_seat_turnback_list`, params),

  // 复台(恢复上一当翻台,当前卡台必须为空台状态)
  reqReserveCardStatus: (params) =>
    axios.post(`${base.htgl}/sel/seat_turn_back`, params),

  // 获取操作中的支付流水渠道列表(获取退单更改支付渠道列表)
  reqGetOrderPayListOfBack: (params) =>
    axios.post(`${base.htgl}/sel/get_chg_pay_cnls`, params),

  // 获取待退款支付订单列表(卡台首页待退款列表)
  reqGetBackOrderList: (params) => axios.post(`${base.htgl}/yy/list`, params),

  // 待退款订单退款重试
  reqTryBackSecond: (params) => axios.post(`${base.htgl}/yy/retry`, params),

  // 待退款订单退款
  reqBackOrder: (params) => axios.post(`${base.htgl}/yy/process`, params),

  // 打印班结表（仅仅执行打印操作）
  reqPrintAllData: (params) => axios.post(`${base.htgl}/wkd/prt_bj`, params),

  // 读取班结表
  reqGetAllData: (params) => axios.post(`${base.htgl}/wkd/get_bj`, params),

  // 读取售出汇总表参数
  reqGetDayReportPayedParams: (params) =>
    axios.post(`${base.htgl}/sel/get_sold_prd_rpt_params`, params),

  // 读取售出日报表参数(新)
  reqGetSoldOutRptItems: (params) =>
  axios.post(`${base.htgl}/sel/rpt/get_sold_out_rpt_items`, params),

  // 读取售出日报表(新)
  reqGetSoldOutRpt: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_sold_out_rpt`, params),
  // 打印售出日报表(新)
  reqPrtSoldOutRpt: (params) =>
    axios.post(`${base.htgl}/sel/rpt/prt_sold_out_rpt`, params),

  // 读取售出汇总表
  reqGetDayReportPayedList: (params) =>
    axios.post(`${base.htgl}/sel/get_sold_prd_rpt`, params),

  // 读取售出汇总表
  reqPrintDayReport: (params) =>
    axios.post(`${base.htgl}/sel/prt_sold_prd_rpt`, params),

  // 读取盘盈盘亏操作记录
  reqGetProfitData: (params) =>
    axios.post(`${base.htgl}/sel/get_prd_profit_loss`, params),

  // 盘盈盘亏操作(添加盘盈盘亏)
  reqAddProfitData: (params) =>
    axios.post(`${base.htgl}/sel/do_prd_profit_loss`, params),

  // 获取在线支付汇总单
  reqGetOnlinePayTotalInfo: (params) =>
    axios.post(`${base.htgl}/sel/get_ol_pay_bill`, params),

  // 打印在线支付汇总单
  reqPrintOnlinePayTotal: (params) =>
    axios.post(`${base.htgl}/sel/prt_ol_pay_bill`, params),

  // 获取在线支付记录
  reqGetOnlinePayDetailInfo: (params) =>
    axios.post(`${base.htgl}/sel/get_ol_pay_recs`, params),

  // 导出线上支付记录excel
  reqExportExcelOfOnlinePayDetail: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/exp_ol_pay_recs`, params),

  // 获取业绩日报
  reqGetKpiReportInfo: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_yj_rpt`, params),

  // 导出业绩日报表excel
  reqExportExcelOfKpiReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_yj_rpt`, params),

  // 收银读取线上预订记录
  reqGetBookingList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_ol_book_list`, params),

  //  收银导出线上预订记录
  reqExportBookingListReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_ol_book_list`, params),

  // 收银读取优惠记录
  reqGetYHList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_yh_list`, params),

  //  收银导出优惠记录
  reqExportYHListReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_yh_list`, params),

  // 读取卡券核销报表
  reqGetKqCsmList: (params) =>
  axios.post(`${base.htgl}/sel/rpt/get_kq_csm_list`, params),

  get_kq_csm_list_for_back: (params) => axios.post(`${base.htgl}/sel/rpt/get_kq_csm_list_for_back`, params),
  cancel_kq_csm: (params) => axios.post(`${base.htgl}/sel/cancel_kq_csm`, params),
  exp_kq_csm_list_for_back: (params) => axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_kq_csm_list_for_back`, params),

  //  收银导出卡券核销报表
  reqExpKqCsmList: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_kq_csm_list`, params),

  // 收银读取特饮/小费记录
  reqGetTYList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_hl_list`, params),

  //  收银导出优惠记录
  reqExportTYListReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_hl_list`, params),

  // 收银读取特饮/小费汇总表
  reqGetTYHZList: (params) =>
  axios.post(`${base.htgl}/sel/rpt/get_hl_rpt_sum_list`, params),

  //  收银导出特饮/小费汇总表
  reqExportTYHZListReport: (params) =>
  axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_hl_rpt_sum_list`, params),


  // 收银读取翻台记录
  reqGetTurnOverList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_turnover_csm_list`, params),

  // 收银导出翻台记录
  reqExportTurnOverListReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_turnover_cms_list`, params),

  // 读取点单明细表
  reqGetOrderDetailList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_order_prd_list`, params),

  reRptPrdOutList: (params) =>
      axios.post(`${base.htgl}/sel/rpt/get_rpt_prd_out_list`, params),

  // 导出点单明细记录
  reqExportOrderDetailReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_order_prd_list`, params),

  // 导出点单明细记录
  reqExportRptPrdOutList: (params) =>
      axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_rpt_prd_out_list`, params),

  // 读取修改订位人操作记录
  reqGetUpdateEmpList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_csm_sales_chg_list`, params),

  // 导出修改订位人操作记录
  reqExportUpdateEmpListReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_csm_sales_chg_list`, params),

  // 读取读取开台主营消费表
  reqGetMinDetail: (params) =>
    axios.post(`${base.htgl}/wo/get_seat_zy_csm_list`, params),

  // 导出开台主营消费表
  reqExportMinDetailReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/wo/exp_seat_zy_csm_list`, params),

  // 读取现抽明细表(不分页)
  reqGetXCDetail: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_xian_chou_list`, params),

  // 导出现抽明细表(不分页)
  reqExportXCDetailReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_xian_chou_list`, params),

  // 读取现抽汇总表(不分页)
  reqGetXCAllInfo: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_xian_chou_sum_list`, params),

  // 导出现抽汇总表(不分页)
  reqExportXCAllInfoReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_xian_chou_sum_list`, params),

  // 读取非主营分类渠道汇总表(不分页)
  reqGetQDInfo: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_not_zy_cate_cnls`, params),

  // 导出非主营分类渠道汇总表(不分页)
  reqExportQDAllInfoReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_not_zy_cate_cnls`, params),

  // 读取服务员指定商品销售明细表(按部门,人员,商品汇总,并排序,金额为实收金额)
  reqGetXSDetailReport: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_waiter_sales_prd_amt_list`, params),

  // 导出服务员指定商品销售明细表(按部门,人员,商品汇总,并排序,金额为实收金额)
  reqExportXSDetailReport: (params) =>
    axios.binaryFilePost(
      `${base.htgl}/sel/rpt/exp_waiter_sales_prd_amt_list`,
      params
    ),

  // 读取商品卡台销售表
  reqGePrdSetSoldCnt: (params) =>
  axios.post(`${base.htgl}/sel/rpt/get_prd_set_sold_cnt`, params),

  // 导出商品卡台销售表
  reqExportPrdSetSoldCnt: (params) =>
    axios.binaryFilePost(
    `${base.htgl}/sel/rpt/exp_prd_set_sold_cnt`,
    params
  ),


  // 读取服务员指定商品销售汇总表(按部门,商品汇总,并排序,金额为实收金额)
  reqGetXSAllInfoReport: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_waiter_sales_prd_amt_sums`, params),

  // 导出服务员指定商品销售汇总表(按部门,商品汇总,并排序,金额为实收金额)
  reqExportXSAllInfoReport: (params) =>
    axios.binaryFilePost(
      `${base.htgl}/sel/rpt/exp_waiter_sales_prd_amt_sums`,
      params
    ),

  // 收银读取非特饮/小费,普通商品关联流水明细表(当前营业日的,数据量不大,不需要分页),这里支持套餐(不需要展示套餐明细)
  reqGetNotTYOrXFReport: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_relate_prd_list`, params),

  // 导出服务员指定商品销售汇总表(按部门,商品汇总,并排序,金额为实收金额)
  reqExportNotTYOrXFReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_relate_prd_list`, params),

  // 读取商户号配置信息
  /**
   * 
POST请求 http://ip_or_domain:port/sel/get_cnl_cfg
  客户端传入json:
    cnl_cfg_id int64      //CnlCfgId 主体Id,如果该门店只有一个主体, 可以传0
  成功返回编码:1, 返回json:
    e_s        int        //EnableSwitch 阀值切换标记 1 开启, 2 未开启
    max_amt    int        //MaxAmt 阀值金额,单位元
    dest_cnl_cfg_id int64      //DestCnlCfgId 阀值切换目标商户号Id
    def_cnl_cfg_id int64      //DefCnlCfgId 默认商户号配置,=0代表未配置
    cnl_cfgs   []*ResGetCnlCfgCnlItem //CnlCfgs 商户号列表
    hour_cfgs  []*ResGetCnlCfgCnlHourItem //HourCnlCfgs 时段配置
    region_seats []*ResGetCnlCfgRSItem //RegionSeats 区域卡台配置
      --------------------------------
      引用 ResGetCnlCfgCnlItem 格式:
        id         int64      //Id 商户号Id
        n          string     //Name 商户号名称
        gs         int        //Gs 公私标记 1 公 2 私
      --------------------------------
      引用 ResGetCnlCfgCnlHourItem 格式:
        h          int        //HourId 时段Id 没有返回,代表没有配置 阀值使用默认值0,商户号使用默认值(未配置)  0 对应00:00-01:00   1 对应 01:00--02:00  以此类推
        m          int        //MaxAmt 阀值金额(单位元)
        c          int64      //CnlCfgId 指定商户号,0表示没有配置
      --------------------------------
      引用 ResGetCnlCfgRSItem 格式:
        id         int64      //Id 区域Id
        n          string     //Name 区域名称
        ss         []*ResGetCnlCfgSItem //Seats 卡台列表
      --------------------------------
      引用 ResGetCnlCfgSItem 格式:
        id         int64      //Id 卡台Id
        n          string     //Name 卡台名称
        c          int64      //CnlCfgId 配置的商户号Id,=0代表未配置
  普通失败, 返回编码<>1, 数据为空
   */
  reqGetMerchantConfig: (params) =>
    axios.post(`${base.htgl}/sel/get_cnl_cfg`, params),

    // 读取多主体商户号配置
    /*  客户端传入json:
    无
    成功返回编码:1, 返回json:
    cnl_cfg_grps []*ResGetCnlCfgGrpItem //CnlCfgGrps 主体配置列表
    cnl_cfg_def []*ResGetCnlCfgGrpCnlDfnItem //CnlCfgDfn 商户渠道定义列表,用于前端界面展示
    region_def []*ResGetCnlCfgGrpRegDfnItem //RegionDfn 区域定义列表,用于前端界面展示
      --------------------------------
      引用 ResGetCnlCfgGrpItem 格式:
        id         int64      //CnlCfgId 主体对应的商户号Id
        sids       []int64      //SCnlCfgIds 主体对应的对S商户号Id列表
        d          int        //IsDef 是否是默认主体, 1 是 2 否
        rs         []int64      //Regions 指定包含的区域Id列表
      --------------------------------
      引用 ResGetCnlCfgGrpCnlDfnItem 格式:
        id         int64      //Id 商户号Id
        n          string     //Name 商户号名称
        g          int        //Gs 属性 1 对G 2 对S
      --------------------------------
      引用 ResGetCnlCfgGrpRegDfnItem 格式:
        id         int64      //Id 区域Id
        n          string     //Name 区域名称
  普通失败, 返回编码<>1, 数据为空
     */
    get_cnl_cfg_grp: () => axios.post(`${base.htgl}/org/get_cnl_cfg_grp`),



    /*
    保存多主体商户号配置
     客户端传入json:
    cnl_cfg_id1 int64      //CnlCfgId1 主体1对应的对G商户号Id
    cnl_cfg_id2 int64      //CnlCfgId2 主体2对应的对G商户号Id
    def_cnl_cfg_id int64      //DefCnlCfgId 默认的主体对应的对G商户号Id
    s_cfg_ids_1 []int64      //SCfgIds1 主体1对应的对S商户号Id列表
    s_cfg_ids_2 []int64      //SCfgIds2 主体2对应的对S商户号Id列表
    region_ids_1 []int64      //RegionIds1 主体1对应的选中区域Id列表
    region_ids_2 []int64      //RegionIds2 主体2对应的选中区域Id列表
  成功返回编码:1, 返回json:
    无
  普通失败, 返回编码<>1, 数据为空 客户端传入json:
    cnl_cfg_id1 int64      //CnlCfgId1 主体1对应的对G商户号Id
    cnl_cfg_id2 int64      //CnlCfgId2 主体2对应的对G商户号Id
    def_cnl_cfg_id int64      //DefCnlCfgId 默认的主体对应的对G商户号Id
    s_cfg_ids_1 []int64      //SCfgIds1 主体1对应的对S商户号Id列表
    s_cfg_ids_2 []int64      //SCfgIds2 主体2对应的对S商户号Id列表
    region_ids_1 []int64      //RegionIds1 主体1对应的选中区域Id列表
    region_ids_2 []int64      //RegionIds2 主体2对应的选中区域Id列表
  成功返回编码:1, 返回json:
    无
  普通失败, 返回编码<>1, 数据为空 */
    save_cnl_cfg_grp: (params) => axios.post(`${base.htgl}/org/save_cnl_cfg_grp`, params),





  // 保存默认收款商户号,及商户号切换阀值配置,卡台商户号配置
  /**
   *  客户端传入json:
    cnl_cfg_id int64      //CnlCfgId 主体商户号Id
    def_cnl_cfg_id int64      //DefCnlCfgId 默认商户号Id
    enable_switch int        //EnableSwitch 阀值切换开关 1 开启 2 关闭
    max_amt    int        //MaxAmt 阀值金额,单位元
    dest_cnl_cfg_id int64      //DestCnlCfgId 阀值切换目标商户号Id
    seat_ids   []int64      //SeatIds 有配置商户号的卡台列表,没有配置不需要传
    seat_cnl_ids []int64      //SeatCnlCfgId 匹配上面卡台列表的商户号Id
    hour_ids   []int        //HourIds 时段标记数组(这里对应0~23), 定义 0 对应00:00-01:00   1 对应 01:00--02:00  以此类推
    hour_max_amts []int        //HourMaxAmts 对应上面时段数组的,时段阀值金额,单位元
    hour_cnl_cfg_ids []int64      //HourCnlCfgIds 对应上面时段数组的,指定对私商户号
  成功返回编码:1, 返回json:
    无
  普通失败, 返回编码<>1, 数据为空
   */
  reqSaveMerchantConfig: (params) =>
    axios.post(`${base.htgl}/sel/save_cnl_cfg`, params),

  // 手工触发一键切换,开启
  reqOpenMerchantConfig: (params) =>
    axios.post(`${base.htgl}/sel/enable_wkday_cnl_switch`, params),

  // 手工触发一键切换,取消开启
  reqCancelMerchantConfig: (params) =>
    axios.post(`${base.htgl}/sel/cancel_wkday_cnl_switch`, params),

  // 手工触发一键切换,读取状态
  reqGetMerchantList: (params) =>
    axios.post(`${base.htgl}/sel/get_wkday_cnl_switch`, params),

  // 读取商户号时段金额列表
  reqGetMerchantTimeAmtList: (params) =>
    axios.post(`${base.htgl}/sel/get_cnl_hour_amt`, params),

  /**
   * 挂账
   */

  // 新建挂账账户
  reqAddGZInfo: (params) => axios.post(`${base.htgl}/cnlacct/new`, params),

  // 保存挂账账户
  reqUpdateGZInfo: (params) => axios.post(`${base.htgl}/cnlacct/save`, params),

  // 删除挂账账户
  reqDeleteGZInfo: (params) => axios.post(`${base.htgl}/cnlacct/del`, params),

  // 获取挂账账户列表
  reqGetGZList: (params) => axios.post(`${base.htgl}/cnlacct/list`, params),

  // 获取挂账账户操作记录列表
  reqGetGZLogs: (params) =>
    axios.post(`${base.htgl}/cnlacct/get_op_logs`, params),

  // 挂账还款
  /*
  POST请求 http://ip_or_domain:port/cnlacct/return
  客户端传入json:
    ids        []int64      //Ids 挂账订单Id列表
    amts       []int64      //Amts 对应上面挂账订单Id列表的还款金额, 单位分, 需前端格式化
    cnl_names  []string     //CnlNames 对应上面挂账订单Id列表的还款渠道名称列表
  成功返回编码:1, 返回json:
    无
  普通失败, 返回编码<>1, 数据为空
  */
  reqReturnMoney: (params) => axios.post(`${base.htgl}/cnlacct/return`, params),


  // 获取指定挂账账户的待还款挂账订单列表
  /**
   * 
 客户端传入json:
    id         int64      //AccountId 挂账账户Id
  成功返回编码:1, 返回json:
    records    []*ResGetCnlAccountOrdersItem //Records 记录列表
      --------------------------------
      引用 ResGetCnlAccountOrdersItem 格式:
        id         int64      //Id 挂账订单Id
        c          string     //CreateTime 挂账时间
        a          int64      //Amt 挂账金额,单位分,需前端格式化
        s          string     //SeatName 卡台名称
        sn         string     //SalesEmpName 订位人名称
  普通失败, 返回编码<>1, 数据为空
   */
  reqGetGZOrders: (params) =>
    axios.post(`${base.htgl}/cnlacct/get_orders`, params),


  /**
   * 读卡相关
   */

  // 读取会员卡密for消费
  reqGetVipCardPwd: (params) =>
    axios.post(`${base.htgl}/sel/get_mb_card_pass_f_csm`, params),

  // 读取会员卡信息(验证会员卡),返回授权串
  reqGetVipCardInfo: (params) =>
    axios.post(`${base.htgl}/sel/get_mb_card_f_csm`, params),

  // 通过验证验证码,获取可用会员卡列表
  reqGetVipCardFormValidate: (params) =>
    axios.post(`${base.htgl}/sel/valid_cust_srv_code`, params),

  // 手机验证码(服务码)选可用预订金(通过授权信息),用于结算(
  reqGetPhonePrepaysFCsm: (params) =>
    axios.post(`${base.htgl}/sel/get_phone_prepays_f_csm`, params),  

  // 将预付金渠道加入结账渠道购物车
  reqCartAddPrepayCnl: (params) =>
    axios.post(`${base.htgl}/sel/cart_add_prepay_cnl`, params),  

    // 通过验证验证码,获取可用会员卡列表
  reqGetVipCardFormValidateOld: (params) =>
    axios.post(`${base.htgl}/sel/valid_pay_code`, params),  

  // 通过验证手机,获取可用会员卡列表
  reqGetVipCardFormPhoneNum: (params) =>
    axios.post(`${base.htgl}/sel/get_phone_mb_cards`, params),


  // 会员卡支付渠道批量加入待结算流水购物车
  reqAddVipCardFormPhoneNumInPayBefore: (params) =>
    axios.post(`${base.htgl}/sel/cart_add_mb_card_cnl`, params),

  // 结账后会员卡支付渠道批量加入待结算流水购物车
  reqAddVipCardFormPhoneNumInPayAfter: (params) =>
    axios.post(`${base.htgl}/sel/chg_pay_add_mb_card_cnl`, params),

  /**
   * 滞留金
   */

  // 滞留金管理界面用,返回滞留金列表和可添加渠道列表
  reqGetMerchantListData: (params) =>
    axios.post(`${base.htgl}/sel/get_seat_late_cnls_for_mgr`, params),

  // 收银新建落单滞留金(暂不需要支持挂账,会员卡,会员卡落单)
  reqAddMerchantMoney: (params) =>
    axios.post(`${base.htgl}/sel/new_late_cnl`, params),

  // 收银删除落单滞留金
  reqDelMerchantMoney: (params) =>
    axios.post(`${base.htgl}/sel/del_late_cnl`, params),

  // 收银发起滞留金退款申请(针对于微信、支付宝、会员卡)
  reqBackMerchantMoney: (params) =>
    axios.post(`${base.htgl}/sel/refund_late_cnl`, params),

  // 结账之前,清理收银结账渠道购物车,并确认本次待结账订单
  /**
  客户端传入json:
    seat_id    int64      //SeatId 卡台Id
    wk_order_ids []int64      //WkOrderIds 待结账订单Id组
    prd_cnts   []int        //PrdCnts 对应待结算订单的商品数量, 时价特饮(3),时价小费(4),赔偿(5)不允许拆分数量,其他都可以拆分数量结账
    total_amt  string     //TotalAmt 总待结算金额,做二次验证用
  成功返回编码:1, 返回json:
    无
  普通失败, 返回编码<>1, 数据为空
   */
  reqConfirmBillInfo: (params) =>
    axios.post(`${base.htgl}/sel/cart_begin_process`, params),

  // 获取会员卡余额和可结账金额信息
  reqGetVipCardAmountInfo: (params) =>
    axios.post(`${base.htgl}/sel/get_usable_mb_card_cnl`, params),

  // 将会员卡渠道更新入结账渠道购物车
  reqUpdateVipCardIntoBillChannel: (params) =>
    axios.post(`${base.htgl}/sel/cart_add_mb_card_cnl`, params),

  // 滞留金转台
  reqChangeMerchantMoney: (params) =>
    axios.post(`${base.htgl}/sel/chg_late_cnl_seat`, params),

  /**
   * 
   * 缴款单
   * 
   */
  // 读取缴款单
  reqGetJkList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_jk_list`, params),

  // 导出缴款单
  reqExportJkList: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_jk_list`, params,),

  // 读取导出功能台报表数据
  reqGetSpSeatRptList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_sp_seat_rpt_list`, params),

  // 导出功能台报表数据  
  reqExpSpSeatRptList: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_sp_seat_rpt_list`, params),

  /**
   * 
   * 套餐统计表
   */
  // 读取可打印二级分类和套餐项
  reqGetSetCntItems: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_set_cnt_items`, params),

  // 读取二级分类套餐数量统计报表
  reqGetSetCntRpt: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_set_cnt_rpt`, params),

  // 打印二级分类套餐数量统计报表
  reqPrtSetCntRpt: (params) =>
    axios.post(`${base.htgl}/sel/rpt/prt_set_cnt_rpt`, params),


  /**
   * 其它
   */

  // 读取对应卡台的预付金可用金额
  reqGetBookAmt: (params) =>
    axios.post(`${base.htgl}/sel/get_seat_prepay_bal`, params),

  // 获取对应卡台的滞留金列表
  reqGetBookAmtList: (params) =>
    axios.post(`${base.htgl}/sel/get_seat_late_cnls`, params),

  // 查询授权人,优惠额度详情
  reqAuthYHCount: (params) =>
    axios.post(`${base.htgl}/sel/get_auth_emp_free_limit`, params),


  // 读取功能台卡台点单金额和优惠金额
  reqGetSpSeatList: (params) =>
    axios.post(`${base.htgl}/wo/get_sp_seat_list`, params),


  // 读取挂账还款记录
  reqGetCnlAccountRtnList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_cnl_account_rtn_list`, params),

  // 导出挂账还款记录
  /**
   * 
   */
  reqExpCnlAccountRtnList: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_cnl_account_rtn_list`, params),


  // 修改订单服务员
  reqChgWkorderWaiter: (params) => axios.post(`${base.htgl}/sel/chg_wkorder_waiter`, params),

  // 修改订单授权人
  chg_wkorder_auther: (params) => axios.post(`${base.htgl}/sel/chg_wkorder_auther`, params),
  
  // 读取客人预订金流水记录
  reqGetCustPrePayLog: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_cust_prepay_log`, params),

  // 导出客人预订金流水记录
  /**
   * 
   */
  reqExpCustPrePayLog: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/get_cust_prepay_log`, params),

  // 读取客人预订金余额表
  reqGetCustPrePayBal: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_cust_prepay_bal`, params),

  // 导出客人预订金余额表
  /**
   * 
   */
  reqExpCustPrePayBal: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_cust_prepay_bal`, params),    

  // 读取指定客人的预付金流水
  reqGetOneCustPrePayLog: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_one_cust_prepay_log`, params),

  // 导出指定客人的预付金流水
  /**
   * 
   */
  reqExpOneCustPrePayLog: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_one_cust_prepay_log`, params),


  reqQueueCall: (params) => axios.post(`${base.htgl}/custq/call`, params),
  reqQueueEnter: (params) => axios.post(`${base.htgl}/custq/arrive`, params),
  reqQueueOverdue: (params) => axios.post(`${base.htgl}/custq/expired`, params),

  /**
   * 客户端传入json:
   *    o          int64      //OrderId 订单Id
   * 成功返回编码:1, 返回json:
   *   rst        int        //Rst 订单结果 1 处理中,继续轮询 2 处理失败,失败原因是下面的msg,退出轮询  5 处理成功,退出轮询
   *   msg        string     //Msg 失败原因
  普通失败, 返回编码<>1, 数据为空
   */
  get_ol_oper_rst: (params) => axios.post(`${base.htgl}/sel/get_ol_oper_rst`, params),
  /**
   * 客户端传入json:
   *   seat_id    int64      //SeatId 卡台Id
   * 成功返回编码:1, 返回json:
   *   order_id   int64      //OrderId 订单号,用于每秒轮询处理结果
  普通失败, 返回编码<>1, 数据为空
   */
  conv_ol_pay_to_late: (params) => axios.post(`${base.htgl}/sel/conv_ol_pay_to_late`, params),


  /*
   * 读取历史营业日消费数据营业日列表
   * 客户端传入json:
    无
  成功返回编码:1, 返回json:
    records    []*ResIdName  //Records 营业日下拉列表
      --------------------------------
      引用 ResIdName 格式:
        id         int64      //Id 主键id
        n          string     //Name 名称
   */
  get_csm_his_wkday_items:(params) => axios.post(`${base.htgl}/sel/rpt/get_csm_his_wkday_items`, params),

  /** 读取历史营业日消费数据
   *   客户端传入json:
    wkday_id   int64      //WkdayId 营业日Id
    key        string     //Key 过滤关键字
  成功返回编码:1, 返回json:
    records    []*ResGetCsmHisItem //Records 记录列表
      --------------------------------
      引用 ResGetCsmHisItem 格式:
        c          int64      //CmsId 流水Id
        b          string     //BizDay 营业日期
        r          string     //RegionName 区域名称
        s          string     //SeatName 卡台流水名称
        se         string     //SalesEmpName 订位人名称
        sd         string     //SalesEmpDept 订位人部门
        o          int64      //OrderAmt 流水金额,单位分,需前端格式化
        p          int64      //PayValAmt 流水金额,单位分,需前端格式化
        pi         string     //PayInfo 流水支付摘要信息
        os         []*ResGetCsmHisItemOrd //Orders 订单明细
      --------------------------------
      引用 ResGetCsmHisItemOrd 格式:
        o          string     //OrderTime 下单时间
        w          string     //WaiterEmpName 服务员名称
        d          string     //WaiterEmpDept 服务员部门
        co         string     //IsCustOrder 是否自助下单
        on         string     //OneCateName 商品一级分类名称
        tn         string     //TwoCateName 商品二级分类名称
        p          string     //PrdName 商品名称
        pt         string     //PrdType 商品类型
        bt         string     //BizType 业务类型
        c          int        //PrdCnt 商品数量
        oa         int64      //OrderAmt 订单金额,单位分,需前端格式化
        pa         int64      //PayValAmt 实付金额,单位分,需前端格式化
        pi         string     //PayInfo 支付摘要信息
   */
  get_csm_his:(params) => axios.post(`${base.htgl}/sel/rpt/get_csm_his`, params),


  /** 导出历史营业日消费数据
   *   客户端传入json:
    wkday_id   int64      //WkdayId 营业日Id
    key        string     //Key 过滤关键字
  成功返回编码:1, 返回json:
    file application/octet-stream二进制文件
  普通失败, 返回编码<>1, 数据为空
   */
  get_csm_hiexp_csm_hiss_wkday_items:(params) => axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_csm_his`, params),



};
