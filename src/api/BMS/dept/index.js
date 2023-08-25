import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {

  // 获取部门树,用于部门,员工管理界面中间的树形结构
  requestDeptTree(data) {
    return axios.post(`${base.htgl}/dept/tree`, data);
  },
  // 部门管理页面,模糊查询目录树
  requestDeptSearch(data) {
    return axios.post(`${base.htgl}/dept/search`, data);
  },
  // 获取部门列表, 如果是一级部门, 传id=0
  requestdeptlist(data) {
    return axios.post(`${base.htgl}/dept/list`, data);
  },
  // 新建部门
  requestdeptNew(data) {
    return axios.post(`${base.htgl}/dept/new`, data);
  },
  // 读取部门信息,上级id=0表示顶级部门
  requestdeptGet(data) {
    return axios.post(`${base.htgl}/dept/get`, data);
  },
  // 保存部门
  requestdeptSave(data) {
    return axios.post(`${base.htgl}/dept/save`, data);
  },
  // 批量设置部门为无效
  requestdeptDisable(data) {
    return axios.post(`${base.htgl}/dept/disable`, data);
  },
  // 批量设置部门为有效
  requestdeptEnable(data) {
    return axios.post(`${base.htgl}/dept/enable`, data);
  },
  //  批量删除部门
  requestdeptDel(data) {
    return axios.post(`${base.htgl}/dept/del`, data);
  },
  // 状态一键操作
  requestdeptOb(data) {
    return axios.post(`${base.htgl}/dept/ob`, data);
  },



  // 获取部门岗位下系统角色权限列表
  requestdeptsys_privs(data) {
    return axios.post(`${base.htgl}/dept/sys_privs`, data);
  },
  // 批量设置部门下角色权限
  requestdeptsave_sys_privs(data) {
    return axios.post(`${base.htgl}/dept/save_sys_privs`, data);
  },
  // 获取服务员岗位可点商品配置
  requestdeptwait_cates(data) {
    return axios.post(`${base.htgl}/dept/wait_cates`, data);
  },
  // 批量设置服务员可点商品权限
  requestdeptsave_wait_cates(data) {
    return axios.post(`${base.htgl}/dept/save_wait_cates`, data);
  },
  // 获取营销/花篮岗位可授权商品配置, authType 2 经营赠送 3 内招赠送 5 外招赠送  6 自用  8 花篮/特饮关联
  requestdeptsales_cates(data) {
    return axios.post(`${base.htgl}/dept/sales_cates`, data);
  },
  // 批量设置营销/花篮可授权商品, authType 2 经营赠送 3 内招赠送 5 外招赠送  6 自用  8 花篮/特饮关联
  requestdeptsave_sales_cates(data) {
    return axios.post(`${base.htgl}/dept/save_sales_cates`, data);
  },
  // 获取营销/花篮岗位可授权商品限额限量配置, authType 2 经营赠送 3 内招赠送 5 外招赠送  6 自用  8 花篮/特饮关联
  requestdeptsales_free_limits(data) {
    return axios.post(`${base.htgl}/dept/sales_free_limits`, data);
  },
  // 批量设置营销/花篮可授权商品限额限量, authType 2 经营赠送 3 内招赠送 5 外招赠送  6 自用  8 花篮/特饮关联
  requestdeptsave_sales_free_limits(data) {
    return axios.post(`${base.htgl}/dept/save_sales_free_limits`, data);
  },

}
export default article;