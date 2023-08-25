import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const terminalRules = {
  // 读取终端基础配置
  reqGetTime: params => axios.post(`${base.htgl}/org/get_org_biz_cfg`, params),

  // 保存终端基础配置
  reqSubmitTime: params => axios.post(`${base.htgl}/org/save_org_biz_cfg`, params),

  // 保存会员卡结算规则
  reqSubmitVipRules: params => axios.post(`${base.htgl}/mb/card/save_stl_rules`, params),

  // 获取会员卡配置的结算规则
  reqGetVipRules: params => axios.post(`${base.htgl}/mb/card/get_stl_rules`, params),

}
export default terminalRules;