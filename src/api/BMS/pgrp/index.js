import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // pgrp 商品组

    // 读取商品组管理列表
    requestpgrplist(data) {     
        return axios.post(`${base.htgl}/pgrp/list`, data);    
    },
    // 新建
    requestpgrpnew(data) {     
        return axios.post(`${base.htgl}/pgrp/new`, data);    
    },
    // 获取信息   id=0表示新建, 会返回商品分类结构信息
    requestpgrpget(data) {     
        return axios.post(`${base.htgl}/pgrp/get`, data);    
    },
    // 保存编辑商品
    requestpgrpsave(data) {     
        return axios.post(`${base.htgl}/pgrp/save`, data);    
    },
    // 删除
    requestpgrpdel(data) {     
        return axios.post(`${base.htgl}/pgrp/del`, data);    
    },
    // 同步删除
    requestpgrpdelOb(data) {     
        return axios.post(`${base.htgl}/pgrp/ob`, data);    
    },
    // 获取待选商品列表
    requestpgrpprd_items(data) {     
        return axios.post(`${base.htgl}/pgrp/prd_items`, data);    
    },

    // 启用/禁用
    /*
    客户端传入json:
    ids        []int64      //Ids 请求id数组
    */
    pgrd_enable(data) {     
        return axios.post(`${base.htgl}/pgrp/enable`, data);    
    },
    pgrd_disable(data) {     
        return axios.post(`${base.htgl}/pgrp/disable`, data);    
    },

}
export default article;