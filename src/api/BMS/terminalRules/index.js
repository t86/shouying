import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const terminalRules = {
  // 读取终端基础配置
  reqGetTime: params => axios.post(`${base.htgl}/org/get_org_biz_cfg`, params),

  // 保存终端基础配置
  reqSubmitTime: params => axios.post(`${base.htgl}/org/save_org_biz_cfg`, params),

/**
 * 保存会员卡结算规则
 * @param {*}   客户端传入json:
    ids        []int64      //RuleIds 选中规则Id列表
    sms_types  []int        //SmsTypes 短信默认开关列表, 值1 消费   2 充值   3 扣款  4 退款   5 退卡  6 注销  7 挂失  8 取消挂失  , 有值代表该项已勾选, 没有值代表该项没有勾选 
 * @returns 
 */
  reqSubmitVipRules: params => axios.post(`${base.htgl}/mb/card/save_stl_rules`, params),

  /**
   * 获取会员卡配置的结算规则
   * @param {*} params 
   * @returns 
   *     ids        []int64      //RuleIds 配置的规则Id列表
    sms_types  []int        //SmsTypes 短信默认开关列表, 值1 消费   2 充值   3 扣款  4 退款   5 退卡  6 注销  7 挂失  8 取消挂失  , 有值代表该项已勾选, 没有值代表该项没有勾选
   */
  reqGetVipRules: params => axios.post(`${base.htgl}/mb/card/get_stl_rules`, params),

}
export default terminalRules;