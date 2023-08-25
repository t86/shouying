import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // tcate 二级分类
    // 读取管理列表（获取二级分类列表，外部一级分类部分的加载（二级分类部分再动态加载））
    requesttcateocate_list(data) {     
        return axios.post(`${base.htgl}/ocate/list`, data);
    },
    // 读取管理列表(获取一级分类内二级分类管理列表,动态加载
    requesttcatelist(data) {     
        return axios.post(`${base.htgl}/tcate/list`, data);    
    },
    // 新建
    requesttcatenew(data) {     
        return axios.post(`${base.htgl}/tcate/new`, data);    
    },
    // 获取编辑信息
    requesttcateget(data) {     
        return axios.post(`${base.htgl}/tcate/get`, data);    
    },
    // 保存编辑信息
    requesttcatesave(data) {     
        return axios.post(`${base.htgl}/tcate/save`, data);    
    },
    // 置为无效
    requesttcatedisable(data) {     
        return axios.post(`${base.htgl}/tcate/disable`, data);    
    },
    // 置为有效
    requesttcateenable(data) {     
        return axios.post(`${base.htgl}/tcate/enable`, data);    
    },
    // 删除
    requesttcatedel(data) {     
        return axios.post(`${base.htgl}/tcate/del`, data);    
    },

    // 状态一键操作
    requesttcateob(data) {
    return axios.post(`${base.htgl}/tcate/ob`, data);
    },

    // 移动位置
    requesttcatemove_dsp(data) {     
        return axios.post(`${base.htgl}/tcate/move_dsp`, data);    
    },
}
export default article;