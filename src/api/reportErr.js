import base from "./base.js"; // 导入接口域名列表
import axios from "../utils/http.js"; // 导入http中创建的axios实例
export default {
  reqSendErrMsg: (params) => axios.post(`${base.htgl}/yw/pce`, params),
};
