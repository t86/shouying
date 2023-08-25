import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例   

const article = {    
    // supplier erp供应商
    // 读取管理列表
    requestsupplierlist(data) {     
        return axios.post(`${base.htgl}/supplier/list`, data);    
    },
    // 新建
    requestsuppliernew(data) {     
        return axios.post(`${base.htgl}/supplier/new`, data);    
    },
    // 获取信息
    requestsupplierget(data) {     
        return axios.post(`${base.htgl}/supplier/get`, data);    
    },    
    // 保存
    requestsuppliersave(data) {     
        return axios.post(`${base.htgl}/supplier/save`, data);    
    },
    // 置为无效
    requestsupplierdisable(data) {     
        return axios.post(`${base.htgl}/supplier/disable`, data);    
    },
    // 置为有效
    requestsupplierenable(data) {     
        return axios.post(`${base.htgl}/supplier/enable`, data);    
    },
    // 删除
    requestsupplierdel(data) {     
        return axios.post(`${base.htgl}/supplier/del`, data);    
    },
}
export default article;