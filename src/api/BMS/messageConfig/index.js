import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

export default {    
  //  获取短信账户信息
  reqGetAccountInfo: params => axios.post(`${base.htgl}/sms_mgr/get_acct_info`, params),
  
  //  短信自查
  reqMsgSend: params => axios.post(`${base.htgl}/sms_mgr/self_check`, params),

  //  读取短信日账单
  reqGetMsgDayData: params => axios.post(`${base.htgl}/sms_mgr/get_sms_records`, params),

  //  读取短信日账单明细
  reqGetMsgDayDataDetail: params => axios.post(`${base.htgl}/sms_mgr/get_sms_record_dtls`, params),
}