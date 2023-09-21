import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const terminal = {
  // 获取终端列表
  reqGetTerminalList: params => axios.post(`${base.htgl}/lic/list`, params),

  // 获取终端可用打印机列表
  reqGetTerminalPrintList: params => axios.post(`${base.htgl}/lic/get_prts`, params),
  // 读取终端存酒打印机列表
  reqGetTerminalSaveWinePrintList: params => axios.post(`${base.htgl}/lic/get_wine_store_prts`, params),

  // 保存终端打印机配置
  reqSaveTerminalConfig: params => axios.post(`${base.htgl}/lic/save_prt`, params),

  // 批量清理设备,用于腾空注册码
  reqClearTerminal: params => axios.post(`${base.htgl}/lic/clear_term`, params),

  // 使用设备注册码换取注册快捷码
  reqGetTerminalCode: params => axios.post(`${base.htgl}/lic/gen_quick_code`, params),

  // 获取授权设备对应的区域和卡台
  reqGetTerminalAreaAndSeat: params => axios.post(`${base.htgl}/lic/get_region_seat_priv`, params),

  // 保存授权设备对应的区域和卡台
  reqSaveTerminalAreaAndSeat: params => axios.post(`${base.htgl}/lic/save_region_seat_priv`, params),

}
export default terminal;