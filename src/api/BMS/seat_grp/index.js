import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // seat_grp 卡台低消组
    // 读取管理列表
    requestseat_grplist(data) {     
        return axios.post(`${base.htgl}/seat_grp/list`, data);    
    },
    // 新建
    requestseat_grpnew(data) {     
        return axios.post(`${base.htgl}/seat_grp/new`, data);    
    },
    // 获取信息
    requestseat_grpget(data) {     
        return axios.post(`${base.htgl}/seat_grp/get`, data);    
    },
    // 保存信息
    requestseat_grpsave(data) {     
        return axios.post(`${base.htgl}/seat_grp/save`, data);    
    },
    // 删除
    requestseat_grpdel(data) {     
        return axios.post(`${base.htgl}/seat_grp/del`, data);    
    },
    // 获取待配置卡台列表
    requestseat_grpseat_map(data) {     
        return axios.post(`${base.htgl}/seat_grp/seat_map`, data);    
    },
}
export default article;