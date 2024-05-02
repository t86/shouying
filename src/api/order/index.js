import base from "../base.js"; // 导入接口域名列表
import axios from "../../utils/http.js"; // 导入http中创建的axios实例
export default {
  //  获取点单人自己的卡台点单金额
  reqGetOwnPayAmt: (params) =>
    axios.post(`${base.htgl}/wo/get_self_order_amts`, params),
  /**
   * 购物车相关
   */
  // 获取购物车数量
  reqGetShoppingCount: (params) =>
    axios.post(`${base.htgl}/wsc/get_item_cnt`, params),

  // 单品加入购物车
  reqAddProductToShopping: (params) =>
    axios.post(`${base.htgl}/wsc/add_prd`, params),

  // 套餐加入购物车
  reqAddGroupToShopping: (params) =>
    axios.post(`${base.htgl}/wsc/add_set`, params),

  //  添加优惠到购物车
  reqAddYhToShopping: (params) => axios.post(`${base.htgl}/wsc/add_yh`, params),

  // 添加特饮,小费到购物车
  reqAddAmtToShopping: (params) =>
    axios.post(`${base.htgl}/wsc/add_hl`, params),

  // 获取购物车列表
  reqGetShoppingList: (params) =>
    axios.post(`${base.htgl}/wsc/get_items`, params),

  // 修改购物车商品数量
  reqUpdateShoppingCount: (params) =>
    axios.post(`${base.htgl}/wsc/set_cnt`, params),

  // 加/修改单品要求
  reqUpdateSingleProductRequire: (params) =>
    axios.post(`${base.htgl}/wsc/add_requirement`, params),

  // 加/修改套餐明细项要求
  reqUpdateGroupProductRequire: (params) =>
    axios.post(`${base.htgl}/wsc/add_set_requirement`, params),

  // 更改套餐明细项
  reqUpdateGroupDetail: (params) =>
    axios.post(`${base.htgl}/wsc/chg_set_dtl`, params),

  // 购物车商品转优惠(单项)
  reqAuthorizationShopping: (params) =>
    axios.post(`${base.htgl}/wsc/to_yh`, params),

  // 购物车下单
  reqPlaceAnOrder: (params) => axios.post(`${base.htgl}/wsc/order`, params),

  // 点单系统,点进去某个卡台的时候,用于判断,是否可以查看该卡台的金额数据
  reqCanLookMyOrderData: (params) =>
    axios.post(`${base.htgl}/wo/chk_order_can_see`, params),


  /**
   * 订单相关
   */

  // 获取订单列表
  reqGetOrderList: (params) => axios.post(`${base.htgl}/wo/list`, params),

  // 退单,服务员操作,已付款的不支持退单
  reqBackOrder: (params) => axios.post(`${base.htgl}/wo/back`, params),

  // 退单,云端订单退单,服务员操作,已付款的不支持退单,只之前单笔全退不支持部分退
  reqBackOnlineOrder: (params) =>
    axios.post(`${base.htgl}/wo/ol_unpay_back`, params),

  // 下单后赠送(支持批量)
  reqGiveSomeWhenHadOrdered: (params) =>
    axios.post(`${base.htgl}/wo/yh_prd`, params),

  // 下单后(未结账)更换套餐明细项赠送
  reqChangeOrderDetailWhenNotOrdered: (params) =>
    axios.post(`${base.htgl}/wo/set_chg`, params),

  // 补打出品小票
  reqReprtCp: (params) =>
    axios.post(`${base.htgl}/wo/reprt_cp`, params),

  // 设置当台服务员
  reqSetCsmWaiter: (params) =>
    axios.post(`${base.htgl}/wo/set_csm_waiter`, params),

  // 修改流水服务员
  reqChgCsmWaiter: (params) =>
    axios.post(`${base.htgl}/sel/chg_csm_waiter`, params),

  // 手工打印消费单
  reqPrintOrder: (params) => axios.post(`${base.htgl}/wo/prt_csm_bill`, params),
  // 手工补打消费单
  reqAnewPrintOrder: (params) =>
    axios.post(`${base.htgl}/sel/sy_prt_csm_bill`, params),
  /**
   * 服务员生成二维码
   */
  //  获取服务员服务卡台的待付款订单(用于买单选择订单)
  reqGetPayOrderList: (params) =>
    axios.post(`${base.htgl}/wo/get_waiter_olpay_todo_orders`, params),

  // 服务员结账,生成付款二维码,锁定订单
  reqGetPayQRcode: (params) =>
    axios.post(`${base.htgl}/wo/do_waiter_olpay_with_orders`, params),

  // 用于扫客人支付码, 提前判断,是否要给解除锁定的提示(需提供header.tk)
  reqCheckPayOrder: (params) =>
    axios.post(`${base.htgl}/wo/chk_waiter_olpay_with_orders`, params),

  // 取消服务员买单,解锁订单
  reqCancelPayOrder: (params) =>
    axios.post(`${base.htgl}/wo/cancel_waiter_olpay`, params),

  // 询问订单支付状态
  reqGetOrderOnlinePayStatus: (params) =>
    axios.post(`${base.htgl}/wo/get_waiter_olpay_status`, params),

  // 服务员收取支付宝,微信扫码滞留金
  reqGetMerchantPayQRcode: (params) =>
    axios.post(`${base.htgl}/wo/do_waiter_late_olpay`, params),

  // 读取服务员添加 支付宝,微信扫码 滞留金,订单状态
  reqGetMerchantPayQRcodeStatus: (params) =>
    axios.post(`${base.htgl}/wo/get_waiter_late_olpay_status`, params),

  /**
   * 优惠2点单Status
   */
  // 购物车商品转优惠2(批量)
  reqSetYhMany2Order: (params) => axios.post(`${base.htgl}/wsc/to_yh2`, params),

  // 已下单商品转优惠2(批量)
  reqSetYhMany2OrderAtOrdered: (params) =>
    axios.post(`${base.htgl}/wo/yh2_prd`, params),

  // 添加优惠2到购物车(该接口也支持赠送和自用)(需提供header.tk)
  reqAddYh2ToShoppingCart: (params) =>
    axios.post(`${base.htgl}/wsc/add_yh2`, params),

  /**
   *
   */
  // 添加估清
  reqAddGQOrder: (params) =>
    axios.post(`${base.htgl}/sel/add_prd_sold_out`, params),

  // 设置估清
  reqSetGQOrder: (params) =>
    axios.post(`${base.htgl}/sel/set_prd_sold_out`, params),
  
  // 删除估清
  reqDelGQOrder: (params) =>
    axios.post(`${base.htgl}/sel/del_prd_sold_out`, params),

  // 获取商品估清列表
  reqGetGQOrderList: (params) =>
    axios.post(`${base.htgl}/sel/get_prd_sold_outs`, params),

  /**
   * 授权密码相关
   */
  // 读取授权密码是否已开启
  reqGetAuthStatus: (params) =>
    axios.post(`${base.htgl}/emp/get_auth_pwd_enabled`, params),

  // 修改授权密码,需提供登录密码
  reqUpdateAuthPwd: (params) =>
    axios.post(`${base.htgl}/emp/chg_auth_pwd`, params),

  // 补交
  // 关联功能台,选择好日期后,返回可补交的卡台列表(有有效流水的卡台列表)
  reqGetCanBJSeatList: (params) =>
    axios.post(`${base.htgl}/wo/get_relate_seat_items`, params),

  // 关联功能台,选择好日期和卡台后,返回可补交的流水列表
  reqGetCanBJSeatOrderList: (params) =>
    axios.post(`${base.htgl}/wo/get_relate_seat_csm_items`, params),

    
  // 修改优惠/优惠2授权人
  reqChangeYhRen: (params) =>
    axios.post(`${base.htgl}/wo/chg_yh_yu2_auth_emp`, params),


  // 点单读取特饮/小费记录
  reqGetYHListByord: (params) =>
  axios.post(`${base.htgl}/sel/rpt/get_hl_list_byord`, params),

  // 取消优惠 
  reqCancelDiscount: (params) =>
    axios.post(`${base.htgl}/sel/cancel_yh`, params),

    // 读取营销人员的可查看卡台列表
  reqGetSalesmanSeatList: (params) =>
    axios.post(`${base.htgl}/wo/get_sales_seats`, params),

    // 抖音,美团,卡券人工线下核销
  reqLocalManualKqCsm: (params) =>
    axios.post(`${base.htgl}/sel/local_manual_kq_csm`, params),

    // 验证推广卡券券码,从云端验证后,返回客户卡券Id
  reqValidCustKqCode: (params) =>
    axios.post(`${base.htgl}/sel/valid_cust_kq_code`, params, true),

  csm_dy_coupon_prepare: (params) =>
      axios.post(`${base.htgl}/wo/csm_dy_coupon_prepare`, params, true),

    // 使用券码核销卡券
  reqUseKqCode: (params) => axios.post(`${base.htgl}/sel/kq_csm_by_code`, params),
  //抖音核销卡券
  reqUseDyCode: (params) => axios.post(`${base.htgl}/wo/csm_dy_coupon`, params),
  // 修改订单服务员
  chg_wk_order_waiter_inord: (params) =>
      axios.post(`${base.htgl}/wo/chg_wk_order_waiter_inord`, params),

  // 修改订单服务员
  chg_csm_waiter_inord: (params) =>
      axios.post(`${base.htgl}/wo/chg_csm_waiter_inord`, params),

};