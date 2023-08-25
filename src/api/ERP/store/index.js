import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // store 仓库
    // 读取管理列表
    requeststorelist(data) {     
        return axios.post(`${base.htgl}/store/list`, data);    
    },
    // 新建
    requeststorenew(data) {     
        return axios.post(`${base.htgl}/store/new`, data);    
    },
    // 获取信息
    requeststoreget(data) {     
        return axios.post(`${base.htgl}/store/get`, data);    
    },
    // 保存
    requeststoresave(data) {     
        return axios.post(`${base.htgl}/store/save`, data);    
    },
    // 置为无效
    requeststoredisable(data) {     
        return axios.post(`${base.htgl}/store/disable`, data);    
    },
    // 置为有效
    requeststoreenable(data) {     
        return axios.post(`${base.htgl}/store/enable`, data);    
    },
    // 删除
    requeststoredel(data) {     
        return axios.post(`${base.htgl}/store/del`, data);    
    },
    // // 获取仓库管理员模糊查询下拉框
    // requeststoreadmin_items(data) {     
    //     return axios.post(`${base.htgl}/store/admin_items`, data);    
    // },

    

}
export default article;