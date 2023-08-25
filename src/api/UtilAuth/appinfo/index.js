import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // appinfo 认证
    // 超级账号登录
    requestsauthlogin(data) {     
        return axios.post(`${base.htgl}/sauth/login`, data);    
    },
    // 超级账号退出
    requestsauthlogout(data) {     
        return axios.post(`${base.htgl}/sauth/logout`, data);    
    },
    // 超级账号修改密码
    requestsmgrchgpw(data) {     
        return axios.post(`${base.htgl}/smgr/chgpwd`, data);    
    },
    // 超级账号读取用户列表
    requestsmgremps(data) {     
        return axios.post(`${base.htgl}/smgr/emps`, data);    
    },
    
    // 设置岗位有效
    reqSetStationEffect: params => axios.post(`${base.htgl}/smgr/station_enable`, params),

    // 重置门店管理员密码
    requestsmgrresetpwd(data) {     
        return axios.post(`${base.htgl}/smgr/resetpwd`, data);    
    },
    // 赋予门店管理员权限
    requestsmgrgrant(data) {     
        return axios.post(`${base.htgl}/smgr/grant`, data);    
    },
    // 收回门店管理员权限
    requestsmgrrevoke(data) {     
        return axios.post(`${base.htgl}/smgr/revoke`, data);    
    },
    // 用户状态,设置为有效(解决管理员被无意设置为无效的情况)
    reqSetAuthEnable: params => axios.post(`${base.htgl}/smgr/emp_enable`, params),  
    
    // 用户状态,设置为无效(解决管理员被无意设置为无效的情况)
    reqSetAuthDisabled: params => axios.post(`${base.htgl}/smgr/emp_disable`, params),  
    // 其他接口…………
}
export default article;