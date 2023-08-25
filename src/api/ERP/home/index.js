import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const home = {  
  getTableList : params => axios.post(`${base.htgl}/rpt_erp/get_neg_stores`, params)
}
export default home;