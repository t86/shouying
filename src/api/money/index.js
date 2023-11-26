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

  // 收银读取线上预定记录
  reqGetBookingList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_ol_book_list`, params),

  //  收银导出线上预定记录
  reqExportBookingListReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_ol_book_list`, params),

  // 收银读取优惠记录
  reqGetYHList: (params) =>
    axios.post(`${base.htgl}/sel/rpt/get_yh_list`, params),

  //  收银导出优惠记录
  reqExportYHListReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_yh_list`, params),

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

  // 导出点单明细记录
  reqExportOrderDetailReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_order_prd_list`, params),

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
  reqGetMerchantConfig: (params) =>
    axios.post(`${base.htgl}/sel/get_cnl_cfg`, params),

  // 保存默认收款商户号,及商户号切换阀值配置,卡台商户号配置
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
  reqReturnMoney: (params) => axios.post(`${base.htgl}/cnlacct/return`, params),

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
  reqConfirmBillInfo: (params) =>
    axios.post(`${base.htgl}/sel/cart_begin_process`, params),

  // 获取会员卡余额和可结账金额信息
  reqGetVipCardAmountInfo: (params) =>
    axios.post(`${base.htgl}/sel/chk_mb_card_cnl`, params),

  // 将会员卡渠道更新入结账渠道购物车
  reqUpdateVipCardIntoBillChannel: (params) =>
    axios.post(`${base.htgl}/sel/cart_merge_mb_card_cnl`, params),

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
  reqExpCnlAccountRtnList: (params) =>
    axios.binaryFilePost(`${base.htgl}/sel/rpt/exp_cnl_account_rtn_list`, params),

};
