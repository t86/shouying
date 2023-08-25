import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // mat_unit  物料单位
    // 读取管理列表
    requestmat_unitlist(data) {     
        return axios.post(`${base.htgl}/unit/list`, data);    
    },
    // 新建
    requestmat_unitnew(data) {     
        return axios.post(`${base.htgl}/unit/new`, data);    
    },
    // 获取信息
    // requestmat_unitget(data) {     
    //     return axios.post(`${base.htgl}/unit/get`, data);    
    // },
    // 保存
    requestmat_unitsave(data) {     
        return axios.post(`${base.htgl}/unit/save`, data);    
    },
    // 置为无效
    requestmat_unitdisable(data) {     
        return axios.post(`${base.htgl}/unit/disable`, data);    
    },
    // 置为有效
    requestmat_unitenable(data) {     
        return axios.post(`${base.htgl}/unit/enable`, data);    
    },
    // 删除
    requestmat_unitdel(data) {     
        return axios.post(`${base.htgl}/unit/del`, data);    
    },
    // 状态一键操作
    requestmat_unitob(data) {     
        return axios.post(`${base.htgl}/unit/ob`, data);    
    },
    

}
export default article;