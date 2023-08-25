import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

export default {
  // 读取实时库存
  getLibList : params => axios.post(`${base.htgl}/rpt_erp/get_now_mat_invt`, params),

  // 导出实时库存
  exportExcelLibList : params => axios.binaryFilePost(`${base.htgl}/rpt_erp/exp_now_mat_invt `, params)
}