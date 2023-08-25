import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

export default {
  // 获取部门树,用于特饮小费报表,tab页汇总部门配置
  reqGetTYTreeData: params => axios.post(`${base.htgl}/rpt/cfg/get_dept_tree`, params),
  
  // 特饮小费部门汇总tab页配置,批量添加tab
  reqAddTYTreeData: params => axios.post(`${base.htgl}/rpt/cfg/batch_add_hl_tabs`, params),
  
  // 特饮小费部门汇总tab页配置,删除tab
  reqDelTYTreeData: params => axios.post(`${base.htgl}/rpt/cfg/del_hl_tab`, params),
  
  // 获取特饮小费部门汇总tab页配置
  reqGetConfig: params => axios.post(`${base.htgl}/rpt/cfg/get_hl_tabs`, params),


  /**
   * 销售商品统计设置
   */
  
  // 获取服务员销售商品统计待配置商品列表
  reqGetSealPrdList: params => axios.post(`${base.htgl}/rpt/cfg/get_waiter_sales_prd_items`, params),
  
  // 获取服务员销售商品统计待配置商品列表
  reqGetFXYSealPrdList: params => axios.post(`${base.htgl}/rpt/cfg/get_waiter_sales_prds`, params),
  
  // 批量添加服务员销售商品统计商品
  reqAddFXYSealPrds: params => axios.post(`${base.htgl}/rpt/cfg/add_waiter_sales_prds`, params),
  
  // 删除服务员销售商品统计商品
  reqDelFXYSealPrd: params => axios.post(`${base.htgl}/rpt/cfg/del_waiter_sales_prd`, params),
}