import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // mklib 出品库
    // 读取出品库管理列表
    requestmkliblist(data) {     
        return axios.post(`${base.htgl}/mklib/list`, data);    
    },
    // 新建出品库
    requestmklibnew(data) {     
        return axios.post(`${base.htgl}/mklib/new`, data);    
    },  
    // 新建打印机,在出品库下拉框直接新建
    requestmklibnew_printer(data) {     
        return axios.post(`${base.htgl}/mklib/new_printer`, data);    
    },  
    // 获取出品库信息
    requestmklibget(data) {     
        return axios.post(`${base.htgl}/mklib/get`, data);    
    },  
    // 保存出品库
    requestmklibsave(data) {     
        return axios.post(`${base.htgl}/mklib/save`, data);    
    },  
    // 出品库置为有效
    requestmklibenable(data) {     
        return axios.post(`${base.htgl}/mklib/enable`, data);    
    },  
    // 出品库置为无效
    requestmklibdisable(data) {     
        return axios.post(`${base.htgl}/mklib/disable`, data);    
    },  
    // 出品库删除
    requestmklibdel(data) {     
        return axios.post(`${base.htgl}/mklib/del`, data);    
    },
    // 状态一键操作
    requestMklibOb(data) {
        return axios.post(`${base.htgl}/mklib/ob`, data);
    },
}
export default article;