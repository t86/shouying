import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {


  // 修改密码
  requestempchg_pwd(data) {
      return axios.post(`${base.htgl}/emp/chg_pwd`, data);
  },
  // 批量重置密码
  requestempbatch_reset_pwd(data) {
    return axios.post(`${base.htgl}/emp/batch_reset_pwd`, data);
  },

  // 获取员工列表
  requestEmpList(data) {
    return axios.post(`${base.htgl}/emp/list`, data);
  },
  // 新建员工
  requestEmpNew(data) {
    return axios.post(`${base.htgl}/emp/new`, data);
  },
  // 获取信息
  requestEmpGet(data) {
    return axios.post(`${base.htgl}/emp/get`, data);
  },
  // 保存员工
  requestEmpSave(data) {
    return axios.post(`${base.htgl}/emp/save`, data);
  },
  // 批量设置员工为无效
  requestEmpDisable(data) {
    return axios.post(`${base.htgl}/emp/disable`, data);
  },
  // 批量设置员工为有效
  requestEmpEnable(data) {
    return axios.post(`${base.htgl}/emp/enable`, data);
  },
  // 批量删除员工
  requestEmpDel(data) {
    return axios.post(`${base.htgl}/emp/del`, data);
  },
  // 状态一键操作
  requestEmpOb(data) {
    return axios.post(`${base.htgl}/emp/ob`, data);
  },
  // 批量重置密码
  requestEmpBatchResetPwd(data) {
    return axios.post(`${base.htgl}/emp/batch_reset_pwd`, data);
  },
  // 获取岗位管理列表
  requestStationList(data) {
    return axios.post(`${base.htgl}/station/list`, data);
  },
  // 获取岗位列表
  requestEmpStationList(data) {
    return axios.post(`${base.htgl}/emp/get_emp_station_items`, data);
  },
  // 批量修改岗位
  requestBatchUpdateStationList(data) {
    return axios.post(`${base.htgl}/emp/batch_upd_station`, data);
  },

  // 生成新的员工编号并返回
  requestEmpGencode(data) {
    return axios.post(`${base.htgl}/emp/gen_code`, data);
  },
  // 读取直属上级信息,模糊查询,下拉动态加载分页
  requestEmpUpperItems(data) {
    return axios.post(`${base.htgl}/emp/upper_items`, data);
  },
  // 批量修改员工的部门
  requestEmpUpdDept(data) {
    return axios.post(`${base.htgl}/emp/upd_dept`, data);
  },
  // 批量修改员工的直属上级
  requestEmpBatchUpdUpper(data) {
    return axios.post(`${base.htgl}/emp/batch_upd_upper`, data);
  },
// 下载批量导入模板
  requestEmpTpl() {
    return axios.binaryFilePost(`${base.htgl}/emp/exp_tpl`);
  },
  // 批量导入
  requestEmpImp(data) {
    return axios.post(`${base.htgl}/emp/imp`, data);
  },

  // 获取绑定员工二维码
  reqGetEmpQrCode: params => axios.binaryFilePost(`${base.htgl}/emp/bind_qrcode`, params),

  // 解绑员工
  reqUnbindEmp: params =>  axios.post(`${base.htgl}/emp/unbind_wx`, params),

  // 开始制卡
  reqBeginMakeCard: params =>  axios.post(`${base.htgl}/emp/mk_card_begin`, params),

  // 结束制卡
  reqEndMakeCard: params =>  axios.post(`${base.htgl}/emp/mk_card_end`, params),

  // 开始解绑卡,返回对应用户的卡号,卡密
  reqBeginClearCard: params =>  axios.post(`${base.htgl}/emp/empty_card_begin`, params),

  // 完成解绑卡,设置为白卡
  reqEndClearCard: params =>  axios.post(`${base.htgl}/emp/empty_card_end`, params),

  // 作废卡
  reqDestoryCard: params =>  axios.post(`${base.htgl}/emp/destory_card`, params),


  // 获取我的下级
  reqGetMySubList: params => axios.post(`${base.htgl}/emp/get_my_sub_list`, params),


  // 获取我的替身
  reqGetMyCloneList: params => axios.post(`${base.htgl}/emp/get_my_clone_list`, params),


  // 获取我的同组
  reqGetMyEqList: params => axios.post(`${base.htgl}/emp/get_my_eq_list`, params),

}
export default article;