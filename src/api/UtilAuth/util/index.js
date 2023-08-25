import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // util  常用工具
    // 中文转换为拼音
    requestutilpy(data) {     
        return axios.post(`${base.htgl}/util/py`, data);    
    },
}
export default article;