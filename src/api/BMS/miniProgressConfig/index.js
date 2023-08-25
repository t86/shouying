import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

export default {    
  // 读取服务员销售高毛利商品配置(用于小程序报表)
  reqGetMiniConfig: params => axios.post(`${base.htgl}/rpt/cfg/get_srv_ord_high_prd_cfg`, params),
  
  // 批量添加服务员销售高毛利商品配置(用于小程序报表)
  reqAddMiniData: params => axios.post(`${base.htgl}/rpt/cfg/add_srv_ord_high_prd_cfg`, params),
  
  // 删除服务员销售高毛利商品配置(用于小程序报表)
  reqDelMiniData: params => axios.post(`${base.htgl}/rpt/cfg/del_srv_ord_high_prd_cfg`, params),
  
  // 读取用于配置现抽商品的待添加商品列表
  reqGetPrdList: params => axios.post(`${base.htgl}/rpt/cfg/get_srv_ord_high_prd_items`, params),
}