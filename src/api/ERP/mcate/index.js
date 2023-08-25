import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // mcate 物料分类树
    // 获取物料分类树,用于物料管理界面中间的树形结构
    requestmcatetree(data) {     
        return axios.post(`${base.htgl}/mcate/tree`, data);    
    },
    // 物料管理页面,模糊查询目录树
    requestmcatesearch(data) {     
        return axios.post(`${base.htgl}/mcate/search`, data);    
    },


}
export default article;