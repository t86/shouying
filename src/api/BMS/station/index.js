import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {
  // Station 岗位
  // 读取岗位管理列表
  requestStationList(data) {
    return axios.post(`${base.htgl}/station/list`, data);
  },
  // 新建岗位
  requestStationNew(data) {
    return axios.post(`${base.htgl}/station/new`, data);
  },
  // 获取编辑岗位信息
  requestStationGet(data) {
    return axios.post(`${base.htgl}/station/get`, data);
  },
  // 保存编辑岗位信息
  requestStationSave(data) {
    return axios.post(`${base.htgl}/station/save`, data);
  },
  // 岗位置为无效
  requestStationDisable(data) {
    return axios.post(`${base.htgl}/station/disable`, data);
  },
  // 岗位置为有效
  requestStationEnable(data) {
    return axios.post(`${base.htgl}/station/enable`, data);
  },
  // 岗位删除
  requestStationDel(data) {
    return axios.post(`${base.htgl}/station/del`, data);
  },
  // 状态一键操作
  requestStationOb(data) {
    return axios.post(`${base.htgl}/station/ob`, data);
  },
  // 获取岗位下系统角色权限列表
  requestStationSysPrivs(data) {
    return axios.post(`${base.htgl}/station/sys_privs`, data);
  },
  // 批量设置岗位下角色权限
  requestStationSaveSysPrivs(data) {
    return axios.post(`${base.htgl}/station/save_sys_privs`, data);
  },
  // 获取岗位下服务员员可点区域列表
  requestStationWaiterRegions(data) {
    return axios.post(`${base.htgl}/station/waiter_regions`, data);
  },
  // 批量设置岗位下服务员员可点区域
  requestStationSaveWaiterRegions(data) {
    return axios.post(`${base.htgl}/station/save_waiter_regions`, data);
  },
  // 获取岗位下仓库管理员
  requestStationStoreAdmins(data) {
    return axios.post(`${base.htgl}/station/store_admins`, data);
  },
  // 批量设置岗位下仓库管理员
  requestStationSaveStoreAdmins(data) {
    return axios.post(`${base.htgl}/station/save_store_admins`, data);
  },
  // 获取服务员岗位可点商品配置
  requestStationWaiterCates(data) {
    return axios.post(`${base.htgl}/station/waiter_cates`, data);
  },
  //  批量设置服务员可点商品权限
  requestStationSaveWaitCates(data) {
    return axios.post(`${base.htgl}/station/save_wait_cates`, data);
  },

  // 获取营销优惠可授权商品配置
  reqGetGiveSaleCate: params => axios.post(`${base.htgl}/station/get_yh_priv`, params),

  // 获取营销优惠2可授权商品配置
  reqGetGive2SaleCate: params => axios.post(`${base.htgl}/station/get_yh2_priv`, params),

  //  获取服务员,花篮 小费,花篮关联商品配置
  reqGetGiveHlCate: params => axios.post(`${base.htgl}/station/get_hl_priv`, params),

  //  批量设置营销优惠商品分类权限
  reqSetGiveSaleCate: params => axios.post(`${base.htgl}/station/set_yh_priv`, params),

  // 批量设置营销优惠2商品分类权限
  reqSetGive2SaleCate: params => axios.post(`${base.htgl}/station/set_yh2_priv`, params),

  //  批量设置小费,花篮商品关联
  reqSetGiveHlCate: params => axios.post(`${base.htgl}/station/set_hl_priv`, params),

  // 获取营销优惠分类限额限量配置
  reqGetGiveCateConfig: params => axios.post(`${base.htgl}/station/get_yh_fl`, params),

  // 获取营销优惠2分类限额限量配置
  reqGetGive2CateConfig: params => axios.post(`${base.htgl}/station/get_yh2_fl`, params),
  
  // 批量设置营销优惠分类限额限量
  reqSetGiveCateConfig: params => axios.post(`${base.htgl}/station/set_yh_fl`, params),

  // 批量设置营销优惠2分类限额限量
  reqSetGive2CateConfig: params => axios.post(`${base.htgl}/station/set_yh2_fl`, params),

  // 获取选中优惠项的实际商品列表
  reqGetChoosePrdList: params => axios.post(`${base.htgl}/station/get_fl_act_prds`, params),

  /**
   * 配置岗位权限
   */
  // 获取部门岗位下权限列表
  reqGetAuthLimitConfig: params => axios.post(`${base.htgl}/station/get_auth_priv`, params),

  // 批量配置系统明细权限
  reqSetAuthLimitConfig: params => axios.post(`${base.htgl}/station/set_auth_priv`, params),

  /**
   * 配置查单权限
   */
  // 针对服务员系统角色,可以配置查单权限, 查单权限暂时不支持批量配置,因为需要配置的人不多
  reqGetLookOrderConfig: params => axios.post(`${base.htgl}/station/get_check_priv`, params),

  // 设置角色查单权限
  reqSetLookOrderConfig: params => axios.post(`${base.htgl}/station/set_check_priv`, params),
}
export default article;