import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // freelmt 低消组   限额限量管理

    // 获取低消组管理列表
    requestfreelmtlist(data) {     
        return axios.post(`${base.htgl}/freelmt/list`, data);    
    },
    // 新建
    requestfreelmtnew(data) {     
        return axios.post(`${base.htgl}/freelmt/new`, data);    
    },
    // 读取低消组信息   id=0表示新建, 会返回商品分类结构信息
    requestfreelmtget(data) {     
        return axios.post(`${base.htgl}/freelmt/get`, data);    
    },
    // 保存低消组
    requestfreelmtsave(data) {     
        return axios.post(`${base.htgl}/freelmt/save`, data);    
    },
    // 删除
    requestfreelmtdel(data) {     
        return axios.post(`${base.htgl}/freelmt/del`, data);    
    },
}
export default article;