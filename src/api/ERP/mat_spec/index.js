import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // mat_spec 物料规格
    // 读取管理列表
    requestmat_speclist(data) {     
        return axios.post(`${base.htgl}/mat_spec/list`, data);    
    },
    // 新建
    requestmat_specnew(data) {     
        return axios.post(`${base.htgl}/mat_spec/new`, data);    
    },
    // 获取信息
    requestmat_specget(data) {     
        return axios.post(`${base.htgl}/mat_spec/get`, data);    
    },
    // 保存
    requestmat_specsave(data) {     
        return axios.post(`${base.htgl}/mat_spec/save`, data);    
    },
    // 置为无效
    requestmat_specdisable(data) {     
        return axios.post(`${base.htgl}/mat_spec/disable`, data);    
    },
    // 置为有效
    requestmat_specenable(data) {     
        return axios.post(`${base.htgl}/mat_spec/enable`, data);    
    },
    // 删除
    requestmat_specdel(data) {     
        return axios.post(`${base.htgl}/mat_spec/del`, data);    
    },
    // 状态一键操作
    requestmat_specob(data) {     
        return axios.post(`${base.htgl}/mat_spec/ob`, data);    
    },

    

}
export default article;