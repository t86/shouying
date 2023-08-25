import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // mtcate 物料二级分类
    // 读取管理列表(获取一级分类内二级分类管理列表,动态加载)
    requestmtcatelist(data) {     
        return axios.post(`${base.htgl}/mtcate/list`, data);    
    },
    // 新建
    requestmtcatenew(data) {     
        return axios.post(`${base.htgl}/mtcate/new`, data);    
    },
    // 获取信息
    requestmtcateget(data) {     
        return axios.post(`${base.htgl}/mtcate/get`, data);    
    },
    // 保存
    requestmtcatesave(data) {     
        return axios.post(`${base.htgl}/mtcate/save`, data);    
    },
    // 置为无效
    requestmtcatedisable(data) {     
        return axios.post(`${base.htgl}/mtcate/disable`, data);    
    },
    // 置为有效
    requestmtcateenable(data) {     
        return axios.post(`${base.htgl}/mtcate/enable`, data);    
    },
    // 删除
    requestmtcatedel(data) {     
        return axios.post(`${base.htgl}/mtcate/del`, data);    
    },
    // 状态一键操作
    requestmtcateob(data) {     
        return axios.post(`${base.htgl}/mtcate/ob`, data);    
    },

    

}
export default article;