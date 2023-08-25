import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {
  // ocate 一级分类
  // 读取管理列表
  requestocatelist(data) {
    return axios.post(`${base.htgl}/ocate/list`, data);
  },
  // 获取信息(新建的时候 id=0, 会返回mklibs列表)
  requestocateget(data) {
    return axios.post(`${base.htgl}/ocate/get`, data);
  },
  // 新建一级菜单
  requestocatenew(data) {
    return axios.post(`${base.htgl}/ocate/new`, data);
  },
  // 保存
  requestocatesave(data) {
    return axios.post(`${base.htgl}/ocate/save`, data);
  },


  // 新建出品库
  requestocatenew_mklib(data) {
    return axios.post(`${base.htgl}/ocate/new_mklib`, data);
  },
  // 用于新建出品库的打印机列表读取
  requestocateprinter_items(data) {
    return axios.post(`${base.htgl}/ocate/printer_items`, data);
  },
  // 置为无效
  requestocatedisable(data) {
    return axios.post(`${base.htgl}/ocate/disable`, data);
  },
  // 置为有效
  requestocateenable(data) {
    return axios.post(`${base.htgl}/ocate/enable`, data);
  },
  // 删除
  requestocatedel(data) {
    return axios.post(`${base.htgl}/ocate/del`, data);
  },
  // 移动位置
  requestocatemove_dsp(data) {
    return axios.post(`${base.htgl}/ocate/move_dsp`, data);
  },

  // 状态一键操作
  requestocateob(data) {
    return axios.post(`${base.htgl}/ocate/ob`, data);
  },

  // 读取商品列表,仅做查看用,在全部的时候触发,需要分页,排序使用创建时间
  reqGetPrdList: data => axios.post(`${base.htgl}/prd/get_prd_all_list`, data)
}
export default article;