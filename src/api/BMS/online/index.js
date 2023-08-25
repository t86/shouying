import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

export default {
  // 线上预定相关接口

  // ---------------门店座位分布------------------

  // 上传卡台分布图（地图）
  reqUpdateMap: params => axios.post(`${base.htgl}/seat/save_seat_map_pic`, params),

  // 保存卡台分布数据
  reqSaveSeatData: params => axios.post(`${base.htgl}/seat/save_seat_map_data`, params),

  // 读取卡台分布数据
  reqGetSeatData: params => axios.post(`${base.htgl}/seat/get_seat_map_data`, params),



  // -----------------线上预定设置------------------
  
  // 读取常规线上预定配置
  reqGetConfigInfo: params => axios.post(`${base.htgl}/bk/get_org_normal`, params),

  // 保存常规线上预定配置
  reqSaveConfigInfo: params => axios.post(`${base.htgl}/bk/save_org_normal`, params),


  // -----------------活动管理------------------

  // 获取活动列表
  reqGetActivityList: params => axios.post(`${base.htgl}/bk/get_org_activity_list`, params),

  // 新建活动
  reqAddActivity: params => axios.post(`${base.htgl}/bk/new_org_activity`, params),

  // 编辑活动
  reqUpdateActivity: params => axios.post(`${base.htgl}/bk/save_org_activity`, params),

  // 活动详情
  reqGetActivityDetail: params => axios.post(`${base.htgl}/bk/get_org_activity`, params),

  // 批量删除活动
  reqDeleteActivity: params => axios.post(`${base.htgl}/bk/del_org_activity`, params),

}