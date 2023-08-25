import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {
  // seat 卡台
  // 读取管理列表（获取卡台所属区域列表，上级（初始化后，每次点击后动态加载下级，并更新数量））
  requestseatregion_list(data) {
    return axios.post(`${base.htgl}/region/list`, data);
  },
  // 读取管理列表(获取区域内卡台管理列表, 下级(每次点击上级后,动态刷新))
  requestseatlist(data) {
    return axios.post(`${base.htgl}/seat/list`, data);
  },
  // 新建卡台
  requestseatnew(data) {
    return axios.post(`${base.htgl}/seat/new`, data);
  },
  // 获取卡台信息
  requestseatget(data) {
    return axios.post(`${base.htgl}/seat/get`, data);
  },
  // 保存卡台信息
  requestseatsave(data) {
    return axios.post(`${base.htgl}/seat/save`, data);
  },
  // 置为无效
  requestseatdisable(data) {
    return axios.post(`${base.htgl}/seat/disable`, data);
  },
  // 置为有效
  requestseatenable(data) {
    return axios.post(`${base.htgl}/seat/enable`, data);
  },
  // 删除
  requestseatdel(data) {
    return axios.post(`${base.htgl}/seat/del`, data);
  },
  // 卡台排序
  requestSort(data) {
    return axios.post(`${base.htgl}/seat/move_dsp`, data);
  },
  // 批量添加卡台(预览)
  requestseatbatch_new_preview(data) {
    return axios.post(`${base.htgl}/seat/batch_new_preview`, data);
  },
  // 批量添加卡台
  requestseatbatch_new(data) {
    return axios.post(`${base.htgl}/seat/batch_new`, data);
  },
  // 状态一键操作
  requestSeatOb(data) {
    return axios.post(`${base.htgl}/seat/ob`, data);
  },
  // 获取卡台二维码配置
  requestSeatGetQrCfg(data) {
    return axios.post(`${base.htgl}/seat/get_qr_cfg`, data);
  },
  // 保存卡台二维码配置
  requestSeatSaveQrCfg(data) {
    return axios.post(`${base.htgl}/seat/save_qr_cfg`, data);
  },
  // 预览卡台二维码,返回png图片
  requestSeatPreviewQr(data) {
    return axios.binaryFilePost(`${base.htgl}/seat/preview_qr`, data);
  },
  // 导出所有门店的二维码图片
  requestSeatExpQr(data) {
    return axios.post(`${base.htgl}/seat/exp_qr`, data);
  },
  // 获取导出所有门店的二维码图片任务的完成百分比
  requestSeatGetExpQrPercent(data) {
    return axios.post(`${base.htgl}/seat/get_exp_qr_percent`, data);
  },
}
export default article;