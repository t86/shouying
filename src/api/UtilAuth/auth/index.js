import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  


const article = {    
    // auth 认证
    // 用户登录
    requestauthlogin(data) {
        return axios.post(`${base.htgl}/auth/login`, data);    
    },
    // 用户退出
    requestauthlogout(data) {     
        return axios.post(`${base.htgl}/auth/logout`, data);    
    },
    // 用户修改密码
    requestauthchg_pw(data) {     
        return axios.post(`${base.htgl}/emp/chg_pwd`, data);    
    },

    // 通过卡号获取卡密码
    reqGetCardPassword: params => axios.post(`${base.htgl}/auth/get_card_p`, params),

    // 注册设备
    reqRegisterTerminal: params => axios.post(`${base.htgl}/register/machine`, params),
}
export default article;