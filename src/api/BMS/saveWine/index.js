import base from '../../base.js'; 
import axios from '../../../utils/http.js'; 

export default {
  // 读取存酒系统设置
  reqGetWineConfig: params => axios.post(`${base.htgl}/wine/cfg/get`, params),

  // 保存存酒系统设置
  reqUpdateWineConfig: params => axios.post(`${base.htgl}/wine/cfg/save`, params),

  // 读取可存酒水(待添加选项)
  reqGetAllWineLine: params => axios.post(`${base.htgl}/wine/cfg/prd_items`, params),

  // 批量添加可存酒水
  reqAddWine: params => axios.post(`${base.htgl}/wine/cfg/add_prds`, params),

  // 批量删除可存酒水
  reqDelWine: params => axios.post(`${base.htgl}/wine/cfg/del_prds`, params),

  // 读取可存酒水列表
  reqGetWineList: params => axios.post(`${base.htgl}/wine/cfg/get_prds`, params),

  // 批量设置过期时间
  reqSetPassTime: params => axios.post(`${base.htgl}/wine/cfg/set_prd_expired`, params),

  // 刷新存酒超级授权码
  reqReloadCode: params => axios.post(`${base.htgl}/wine/refresh_wine_super_code`, params)
}