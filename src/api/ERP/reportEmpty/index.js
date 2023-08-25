import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

export default {  
  /**
   * 空瓶入库明细表
   */
  // 读取空瓶入库明细表,暂时不分页
  reqGetEmptyInLibDetailList : params => axios.post(`${base.htgl}/rtn_bt/get_rtn_bt_in_opers`, params),

  // 导出空瓶入库明细表,不需要分页(暂时不要考虑时间跨度,以后数据量大了,需要限制例如跨度6个月内)
  reqExportEmptyInLibDetailList : params => axios.binaryFilePost(`${base.htgl}/rtn_bt/exp_rtn_bt_in_opers`, params),

  
  /**
   * 空瓶出库明细表
   */
  // 读取空瓶出库明细表,暂时不分页
  reqGetEmptyOutLibDetailList : params => axios.post(`${base.htgl}/rtn_bt/get_rtn_bt_out_opers`, params),

  // 读导出空瓶出库明细表,不需要分页(暂时不要考虑时间跨度,以后数据量大了,需要限制例如跨度6个月内)
  reqExportEmptyOutLibDetailList : params => axios.binaryFilePost(`${base.htgl}/rtn_bt/exp_rtn_bt_out_opers`, params),
}