import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {
  // 读取要求管理树
  requestRqmTree(data) {
    return axios.post(`${base.htgl}/cfg/rqm/tree`, data);
  },
  // 各种要求,模糊查询目录树
  requestRqmSearch(data) {
    return axios.post(`${base.htgl}/cfg/rqm/search`, data);
  },
  // 获取各种要求类型列表
  requestRqmTypelist(data) {
    return axios.post(`${base.htgl}/cfg/rqm/type_list`, data);
  },
  // 获取指定类型的要求列表
  requestRqmlist(data) {
    return axios.post(`${base.htgl}/cfg/rqm/list`, data);
  },
}
export default article;