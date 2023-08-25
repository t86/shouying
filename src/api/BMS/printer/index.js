import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // printer 打印机
    // 读取打印机管理列表
    requestprinterlist(data) {     
        return axios.post(`${base.htgl}/printer/list`, data);    
    },
    // 新建打印机
    requestprinternew(data) {     
        return axios.post(`${base.htgl}/printer/new`, data);    
    },
    // 获取打印机信息
    requestprinterget(data) {     
        // console.log(axios.post(`${base.htgl}/printer/get`, data));
        return axios.post(`${base.htgl}/printer/get`, data);    
    },
    // 保存打印机
    requestprintersave(data) {     
        return axios.post(`${base.htgl}/printer/save`, data);    
    },
    // 打印机置为无效
    requestprinterdisable(data) {     
        return axios.post(`${base.htgl}/printer/disable`, data);    
    },
    // 打印机置为有效
    requestprinterenable(data) {     
        return axios.post(`${base.htgl}/printer/enable`, data);    
    },
    // 打印机删除
    requestprinterdel(data) {     
        return axios.post(`${base.htgl}/printer/del`, data);    
    },
    // 打印机检测
    requestprinterchk(data) {     
        return axios.post(`${base.htgl}/printer/chk`, data);    
    },
    // 打印兼容测试页
    requestprinterprt(data) {     
        return axios.post(`${base.htgl}/printer/prt`, data);    
    },
    // 状态一键操作
    requestprinterob(data) {     
        return axios.post(`${base.htgl}/printer/ob`, data);    
    } 
}
export default article;