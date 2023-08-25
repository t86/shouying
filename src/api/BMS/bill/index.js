import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {
  // 获取小票配置
  requestBillGet(data) {
    return axios.post(`${base.htgl}/bill/get`, data);
  },
  // 保存小票配置
  requestBillSave(data) {
    return axios.post(`${base.htgl}/bill/save`, data);
  },
}
export default article;