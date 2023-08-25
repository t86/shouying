import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const reason = {
  // 获取理由管理列表
  reqGetReasonList: params => axios.post(`${base.htgl}/rsn/list`, params),
  
  // 新建理由
  reqAddReason: params => axios.post(`${base.htgl}/rsn/new`, params),

  // 保存理由
  reqSaveReason: params => axios.post(`${base.htgl}/rsn/save`, params),

  // 批量删除理由
  reqDelReason: params => axios.post(`${base.htgl}/rsn/del`, params),

}
export default reason;