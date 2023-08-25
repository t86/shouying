import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const comparePrd = {
  /**
* 商品对照
*/
  // 读取待绑定存货商品列表
  reqGetNotBindPrdList: params => axios.post(`${base.htgl}/prd/get_tobind_prds`, params),

  // 读取已绑定存货商品列表
  reqGetBindedPrdList: params => axios.post(`${base.htgl}/prd/get_binded_prds`, params),

  // 读取已配置不绑定存货商品列表
  reqGetCantBindPrdList: params => axios.post(`${base.htgl}/prd/get_un_bind_prds`, params),

  // 批量关闭商品物料关联标记
  reqCloseBindPrdList: params => axios.post(`${base.htgl}/prd/batch_close_bind`, params),

  // 批量关联商品物料关系
  reqBindPrdList: params => axios.post(`${base.htgl}/prd/bind_mat`, params),
}
export default comparePrd;