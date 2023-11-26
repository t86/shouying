/**
 * 存酒后台
 */
import base from "../base.js"; // 导入接口域名列表
import axios from "../../utils/http.js"; // 导入http中创建的axios实例
export default {
  /**
   * 存酒待入库
   */
  // 批量驳回待入库  16  // do
  reqManyBackToLib: (params) =>
    axios.post(`${base.htgl}/wine/back_cj_bef_in`, params),

  //  批量确认待入库单  // do
  reqManySureToLib: (params) =>
    axios.post(`${base.htgl}/wine/confirm_cj_bef_in`, params),

  //  授权确认待入库单 // do 废弃
  reqAuthSureToLib: (params) =>
    axios.post(`${base.htgl}/wine/confirm_auth_cj_bef_in`, params),

  //  授权确认待入库单 新 // do 废弃
  reqAuthSureToLibNew: (params) =>
    axios.post(`${base.htgl}/wine/confirm_auth_cj_bef_in2`, params),

  //仓库修改存酒入库单
  reqChgCjBefIn: (params) =>
    axios.post(`${base.htgl}/wine/chg_cj_bef_in`, params),

  //读取待修改订位人
  reqGetChgSalesEmpList: (params) =>
    axios.post(`${base.htgl}/wine/get_chg_sales_emp_list  `, params),


  // 读取存酒待入库列表 // do
  reqGetSaveNeedToLib: (params) =>
    axios.post(`${base.htgl}/wine/get_cj_bef_in`, params),

  /**
   * 存酒库
   */

  // 读取存酒库列表
  reqGetSaveLibList: (params) =>
    axios.post(`${base.htgl}/wine/get_wine_invt`, params),
  // 存酒库导出明细表
  reqExportWineDetailList: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/rpt/exp_wine_invt`, params),
  // 过期库存延期
  reqAddLongTime: (params) =>
    axios.post(`${base.htgl}/wine/delay_wine_invt2`, params),
  //  库存充公
  reqCgWineInvt: (params) =>
    axios.post(`${base.htgl}/wine/cg_wine_invt`, params),

  /**
   * 存酒库子订单
   */
  reqGetSaveLibChildList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_invt_sub_order`, params),
  /**
   * 过期待处理
   */
  // 读取存酒库过期待处理列表
  reqGetPassTimeNeedToLib: (params) =>
    axios.post(`${base.htgl}/wine/get_wine_invt_expired`, params),

  // 导出存酒库过期待处理列表
  reqExportWineInvtExpired: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/rpt/exp_wine_invt_expired`, params),

  // 过期库存充公
  reqPassPrdToStore: (params) =>
    axios.post(`${base.htgl}/wine/cg_expired_wine_invt`, params),

  /**
   * 存酒库库存
   */
  // 读取存酒库库存网格
  reqGetSaveLibGrid: (params) =>
    axios.post(`${base.htgl}/wine/get_wine_invt_grid`, params),

  // 读取存酒库库存明细
  reqGetSaveLibGridDetail: (params) =>
    axios.post(`${base.htgl}/wine/get_wine_invt_grid_dtl`, params),

  // 导出存酒库库存网格excel
  reqExportExcelOfGridReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/exp_wine_invt_grid`, params),

  /**
   * 取酒
   */

  // 批量驳回取酒待出库  // do
  reqBackFromGetInLib: (params) =>
    axios.post(`${base.htgl}/wine/back_qj_bef_out`, params),

  // 批量确认取酒出库  // do
  reqSureFromGetInLib: (params) =>
    axios.post(`${base.htgl}/wine/confirm_qj_bef_out`, params),

  // 授权确认待出库单 // do
  reqAuthFromGetInLib: (params) =>
    axios.post(`${base.htgl}/wine/confirm_auth_qj_bef_out`, params),

  // 读取取酒待出库列表 // do
  reqGetGetFromLib: (params) =>
    axios.post(`${base.htgl}/wine/get_qj_bef_out`, params),

  // 过期库存延期
  reqPassTimeToLong: (params) =>
    axios.post(`${base.htgl}/wine/delay_wine_invt`, params),

  // 过期库存充公
  reqPassTimeToStore: (params) =>
    axios.post(`${base.htgl}/wine/cg_expired_wine_invt`, params),

  /**
   * 用户管理
   */

  // 获取客户列表(分页)
  reqGetCustomList: (params) =>
    axios.post(`${base.htgl}/wine/get_wine_cust_list`, params),

  // 批量开启,关闭存酒客户短信
  reqOpenOrCloseMsg: (params) =>
    axios.post(`${base.htgl}/wine/batch_set_enable_sms`, params),

  // 修改客户姓名
  reqUpdateCustomName: (params) =>
    axios.post(`${base.htgl}/wine/save_wine_cust_name`, params),

  // 验证手机号没有冲突,可用,在发送手机验证码之前先判断一下新手机号是否可用
  reqValidatePhoneNum: (params) =>
    axios.post(`${base.htgl}/wine/wine_chk_phone_usable`, params),

  // 修改客户手机号,暂时不考虑旧手机号的短信验证问题  33
  reqUpdateCustomPhoneNum: (params) =>
    axios.post(`${base.htgl}/wine/chg_wine_cust_phone`, params),

  // 批量加入黑名单
  reqAddBlackList: (params) =>
    axios.post(`${base.htgl}/wine/batch_add_wine_blacklist`, params),

  // 批量删除黑名单
  reqDeleteBlackList: (params) =>
    axios.post(`${base.htgl}/wine/batch_del_wine_blacklist`, params),

  // 下载模板文件, 用于批量导入存酒黑名单
  reqDownloadBlackListTemplate: () =>
    axios.binaryFilePost(`${base.htgl}/wine/exp_wine_blacklist_tpl`),

  // 黑名单批量导入检查
  reqCheckBlackListImport: (params) =>
    axios.post(`${base.htgl}/wine/imp_wine_blacklist_chk`, params),

  // 批量导入存酒黑名单
  reqImportBlackList: (params) =>
    axios.post(`${base.htgl}/wine/imp_wine_blacklist`, params),

  // 读取存酒黑名单列表
  reqGetBlackList: (params) =>
    axios.post(`${base.htgl}/wine/get_wine_blacklist`, params),

  /**
   * 客户中心存酒 --- 待入库
   */

  // 读取存酒待入库列表(客人放客户中心的酒水)
  reqGetCustomCenterSaveWineList: (params) =>
    axios.post(`${base.htgl}/wine/get_kf_cj_bef_in`, params),

  /**
   * 客户中心 --- 取酒
   */

  // 读取存酒库列表
  reqGetCustomCenterGetWineList: (params) =>
    axios.post(`${base.htgl}/wine/get_kf_wine_invt`, params),

  // 读取客户中心取酒,卡台列表
  reqGetCustomCenterSeatList: (params) =>
    axios.post(`${base.htgl}/wine/get_kf_seat_items`, params),

  // 取酒
  reqGetCustomCenterGetWineSubmit: (params) =>
    axios.post(`${base.htgl}/wine/new_kf_qj_out`, params),

  /**
   * 待充公
   */

  // 读取消费充公待入库列表
  reqGetNeedToStoreList: (params) =>
    axios.post(`${base.htgl}/wine/get_csm_cg_bef_in`, params),

  // 批量驳回消费充公待入库
  reqBackToStoreList: (params) =>
    axios.post(`${base.htgl}/wine/back_csm_cg_bef_in`, params),

  // 批量确认消费充公待入库单(不修改)
  reqPassToStoreListOfNotAuth: (params) =>
    axios.post(`${base.htgl}/wine/confirm_csm_cg_bef_in`, params),

  // 授权确认充公待入库单(修改)
  reqPassToStoreListOfAuth: (params) =>
    axios.post(`${base.htgl}/wine/confirm_auth_csm_cg_bef_in`, params),

  // 充公待入库单(修改)
  reqChgCsmCgBefIn: (params) =>
    axios.post(`${base.htgl}/wine/chg_csm_cg_bef_in`, params),


  /**
   * 充公库
   */

  // 读取充公库库存
  reqGetStoreLibList: (params) =>
    axios.post(`${base.htgl}/wine/get_cg_wine_invt`, params),

  // 充公出库
  reqToStorePrdListToLib: (params) =>
    axios.post(`${base.htgl}/wine/new_cg_out`, params),

  /**
   * 充公出库单
   */

  // 获取充公出库主订单(分页)
  reqGetToStoreDetailList: (params) =>
    axios.post(`${base.htgl}/wine/get_cg_out_list`, params),

  // 读取充公出库单详情, 用于信息展示
  reqGetToStoreOrderDetail: (params) =>
    axios.post(`${base.htgl}/wine/get_cg_out_order`, params),

  // 读取充公出库单详情, 用于红冲操作
  reqGetToStoreOfHc: (params) =>
    axios.post(`${base.htgl}/wine/get_cg_out_order_hc`, params),

  // 充公出库红冲
  reqToStoreToHc: (params) => axios.post(`${base.htgl}/wine/hc_cg_out`, params),

  /**
   * 存取酒记录
   */

  // 存取酒记录,不需要分页
  reqGetSaveAndGetWineList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_in_out_list`, params),

  // 补打存,取酒小票
  reqPrintSaveAndGetWineList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/reprt_wine_in_out_bill`, params),

  // 导出存取酒记录
  reqExportExcelOfSaveAndGetReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/rpt/exp_wine_in_out_list`, params),

  /**
   * 延期记录
   */

  // 延期记录,不需要分页(暂时不要考虑时间跨度,以后数据量大了,需要限制例如跨度6个月内)
  reqGetPassTimeLongReportList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_expired_op_list`, params),

  // 导出延期记录,不需要分页
  reqExportExcelOfPassTimeLongReport: (params) =>
    axios.binaryFilePost(
      `${base.htgl}/wine/rpt/exp_wine_expired_op_list`,
      params
    ),

  /**
   * 充公出库记录
   */

  // 读取充公出库记录,不需要分页
  reqGetToStoreOutReportList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_cg_out_list`, params),

  //  导出读取充公出库记录
  reqExportExcelOfToStoreOutReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/rpt/exp_wine_cg_out_list`, params),

  /**
   * 入库统计
   */

  // 读取入库明细,不需要分页
  reqSaveDetailReportList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_invt_in_list`, params),

  // 导出入库明细,不需要分页
  reqExportExcelOfSaveDetailReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/rpt/exp_wine_invt_in_list`, params),

  // 读取入库网格统计
  reqGridDetailOfSaveReportList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_invt_in_grid`, params),

  // 导出入库网格统计
  reqExportExcelOfSaveGridDetailReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/rpt/exp_wine_invt_in_grid`, params),

  /**
   * 出库统计
   */

  // 读取出库明细,不需要分页
  reqGetDetailReportList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_invt_out_list`, params),

  // 导出出库明细,不需要分页
  reqExportExcelOfGetDetailReport: (params) =>
    axios.binaryFilePost(
      `${base.htgl}/wine/rpt/exp_wine_invt_out_list`,
      params
    ),

  // 读取出库网格统计
  reqGridDetailOfGetReportList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_invt_out_grid`, params),

  // 导出入库网格统计
  reqExportExcelOfGetGridDetailReport: (params) =>
    axios.binaryFilePost(
      `${base.htgl}/wine/rpt/exp_wine_invt_out_grid`,
      params
    ),

  /**
   * 充公统计
   */

  // 读取充公明细,不需要分页
  reqToStoreDetailReportList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_cg_in_list`, params),

  // 导出充公明细,不需要分页
  reqExportExcelOfToStoreDetailReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/rpt/exp_wine_cg_in_list`, params),

  // 读取充公网格统计
  reqGridDetailOfToStoreReportList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_cg_in_grid`, params),

  // 导出充公网格统计
  reqExportExcelOfToStoreGridDetailReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/rpt/exp_wine_cg_in_grid`, params),

  /**
   * 存酒查询
   */

  // 读取存酒查询,过滤定位人
  reqGetEmpList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_sales_emp_items`, params),

  // 存酒查询(分页显示)
  reqSaveSearchReportList: (params) =>
    axios.post(`${base.htgl}/wine/rpt/get_wine_op_log`, params),

  // 导出存酒查询,不需要分页
  reqExportExcelOfSaveSearchReport: (params) =>
    axios.binaryFilePost(`${base.htgl}/wine/rpt/exp_wine_op_log`, params),
};
