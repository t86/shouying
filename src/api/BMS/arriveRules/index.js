import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

export default {
  // 读取卡台抵达规则配置
  reqGetSeatConfig: params => axios.post(`${base.htgl}/seat/get_seat_calc_rule`, params),
  
  // 保存卡台抵达规则配置
  reqSetSeatConfig: params => axios.post(`${base.htgl}/seat/save_seat_calc_rule`, params)
}