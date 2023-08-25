/**
 * 点单系统中的存酒
 */
import base from '../base.js'; // 导入接口域名列表
import axios from '../../utils/http.js'; // 导入http中创建的axios实例  
export default {
  // 读取卡台可存酒流水列表
  reqGetCustomOrderList: params => axios.post(`${base.htgl}/wine/get_csms_f_cj`, params),

  // 读取当前流水剩余可存酒水
  reqGetCanSaveWineList: params => axios.post(`${base.htgl}/wine/get_csm_cj_invt`, params),

  // 读取我的存酒购物车列表
  reqGetShoppingCartWine: params => axios.post(`${base.htgl}/wine/get_sc_csm_cj`, params),

  // 添加非授权存酒,到存酒单(一个酒水,多个规格)
  reqAddNotAuthWine: params => axios.post(`${base.htgl}/wine/add_sc_csm_cj_prd`, params),

  // 添加授权存酒,到存酒单(一个酒水,多个规格)
  reqAddAuthWine: params => axios.post(`${base.htgl}/wine/add_sc_csm_auth_cj_prd`, params),

  // 读取可存酒水,商品不多不做分页
  reqGetCanAuthSaveWineList: params => axios.post(`${base.htgl}/wine/get_can_wine_prd_items`, params),

  // 修改数量,数量设置为0就是删除, 授权商品只能往小里修改,不能改大
  reqUpdateWineCount: params => axios.post(`${base.htgl}/wine/mod_sc_csm_cj_prd`, params),

  // 新建存酒待入库单
  reqCreateSaveWineOrder: params => axios.post(`${base.htgl}/wine/new_cj_bef_in`, params),
  
  // 读取可取酒库存
  reqGetCanGetFromLib: params => axios.post(`${base.htgl}/wine/get_qj_invt`, params),
  
  // 取酒,进入取酒待出库
  reqGetWineToNextLib: params => axios.post(`${base.htgl}/wine/new_qj_bef_out`, params),
  
  // 新建消费充公待入库
  reqCreateOrderOfPayToStore: params => axios.post(`${base.htgl}/wine/new_csm_cg_bef_in`, params),
}