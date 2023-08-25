import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

export default {  
  /**
   * 空瓶仓入库
   */
  // 获取空瓶入库列表
  getEmptyInLibList : params => axios.post(`${base.htgl}/rtn_bt/get_in_list`, params),
  
  // 读取待入库订单明细,用于确认入库
  getNeedInLibOrderDetail : params => axios.post(`${base.htgl}/rtn_bt/get_in_list_dtl`, params),
  
  // 空瓶确认入库
  submitEmptyInLib : params => axios.post(`${base.htgl}/rtn_bt/confirm_rtn_bt_in`, params),
  
  // 读取空瓶入库单详情,红冲使用
  getHCOrderInLib : params => axios.post(`${base.htgl}/rtn_bt/get_rtn_bt_in_f_hc`, params),
  
  // 红冲空瓶入库单
  submitHCInLib : params => axios.post(`${base.htgl}/rtn_bt/hc_rtn_bt_in`, params),
  
  // 读取空瓶仓订单详情
  getEmptyInOrderDetail : params => axios.post(`${base.htgl}/rtn_bt/get_rtn_bt_in`, params),

  /**
   * 空瓶仓
   */
  // 读取空瓶仓库存
  getEmptyLibList : params => axios.post(`${base.htgl}/rtn_bt/get_rtn_bt_invt`, params),

  // 空瓶出库
  emptyLibOut : params => axios.post(`${base.htgl}/rtn_bt/invt_rtn_bt_out`, params),

  /**
   * 空瓶仓出库
   */
  // 获取空瓶出库单列表
  getEmptyOutLibList : params => axios.post(`${base.htgl}/rtn_bt/get_rtn_bt_out_list`, params),

  // 读取空瓶入库单详情,红冲使用
  getHCOrderOutLib: params => axios.post(`${base.htgl}/rtn_bt/get_rtn_bt_out_f_hc`, params),

  // 红冲空瓶出库
  submitHCOutLib : params => axios.post(`${base.htgl}/rtn_bt/hc_rtn_bt_out`, params),

  // 读取空瓶仓出库订单详情
  getEmptyOutOrderDetail : params => axios.post(`${base.htgl}/rtn_bt/get_rtn_bt_out`, params),
}