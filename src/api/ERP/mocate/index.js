import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // mocate 物料一级分类
    // 读取管理列表
    requestmocatelist(data) {     
        return axios.post(`${base.htgl}/mocate/list`, data);    
    },
    // 新建
    requestmocatenew(data) {     
        return axios.post(`${base.htgl}/mocate/new`, data);    
    },
    // 获取信息
    requestmocateget(data) {     
        return axios.post(`${base.htgl}/mocate/get`, data);    
    },
    // 保存
    requestmocatesave(data) {     
        return axios.post(`${base.htgl}/mocate/save`, data);    
    },
    // 置为无效
    requestmocatedisable(data) {     
        return axios.post(`${base.htgl}/mocate/disable`, data);    
    },
    // 置为有效
    requestmocateenable(data) {     
        return axios.post(`${base.htgl}/mocate/enable`, data);    
    },
    // 删除
    requestmocatedel(data) {     
        return axios.post(`${base.htgl}/mocate/del`, data);    
    },
    // 状态一键操作
    requestmocateob(data) {     
        return axios.post(`${base.htgl}/mocate/ob`, data);    
    },

    

}
export default article;