import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // 获取员工密码,工号生成规则
    requestEmpGenRule(data) {
        return axios.post(`${base.htgl}/emp/gen_rule`, data);
    },
    // 保存员工生成规则
    requestEmpSaveGenRule(data) {
        return axios.post(`${base.htgl}/emp/save_gen_rule`, data);
    },
}
export default article;