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
  reqReloadCode: params => axios.post(`${base.htgl}/wine/refresh_wine_super_code`, params),

  // 新建存酒分类
  reqNewWineCate: params => axios.post(`${base.htgl}/wine/cfg/new_wine_cate`, params),

  // 编辑存酒分类
  reqUpdateWineCate : params => axios.post(`${base.htgl}/wine/cfg/save_wine_cate`, params),

  // 获取存酒分类列表
  reqGetWineCateList: params => axios.post(`${base.htgl}/wine/cfg/get_wine_cate_list`, params),

  // 批量删除存酒分类
  reqBatchDelWineCate: params => axios.post(`${base.htgl}/wine/cfg/batch_del_wine_cate`, params),

  // 批量设置存酒商品分类
  reqBatchSetPrdWineCate: params => axios.post(`${base.htgl}/wine/cfg/batch_set_prd_wine_cate`, params),

  // 存酒分类管理页面,模糊查询分类商品树
  reqGetWineCateFmName: params => axios.post(`${base.htgl}/wine/cfg/get_wine_cate_fm_name`, params),
}