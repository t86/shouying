import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

export default {
  // 添加现抽抽成商品配置
  reqAddPrdConfig: params => axios.post(`${base.htgl}/rpt/cfg/add_xc_prd_cfg`, params),

  // 删除现抽抽成商品配置
  reqDelPrdConfig: params => axios.post(`${base.htgl}/rpt/cfg/del_xc_prd_cfg `, params),

  // 保存现抽抽成商品配置
  reqSavePrdConfig: params => axios.post(`${base.htgl}/rpt/cfg/save_xc_prd_cfg`, params),

  // 读取现抽商品配置表
  reqGetPrdConfig: params => axios.post(`${base.htgl}/rpt/cfg/get_xc_prd_cfg_list`, params),

  // 读取用于配置现抽商品的商品分类列表
  reqGetPrdCateList: params => axios.post(`${base.htgl}/rpt/cfg/get_xc_prd_items`, params),

  // 读取用于配置现抽商品的待添加商品列表
  reqGetPrdCatePrdList: params => axios.post(`${base.htgl}/rpt/cfg/get_waiter_sales_prd_items`, params),

}