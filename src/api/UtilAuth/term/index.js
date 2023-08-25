import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // term  终端设备授权
    // 设备授权
    termauth(data) {     
        return axios.post(`${base.htgl}/term/auth`, data);    
    },
}
export default article;