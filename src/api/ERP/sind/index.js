import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // sind 调拨入库
    // 调拨入库 读取管理列表
    requestsindlist(data) {     
        return axios.post(`${base.htgl}/sind/list`, data);    
    },
    // 读取调拨入库单详情, 用于信息展示
    requestsindget_f_view(data) {     
        return axios.post(`${base.htgl}/sind/get_f_view`, data);    
    },
    // 读取调拨入库单详情,部分入库用,  状态为3(未处理)的情况下
    requestsindget_f_pt(data) {     
        return axios.post(`${base.htgl}/sind/get_f_pt`, data);    
    },
    // 读取调拨入库单详情,申请售后用,  状态为1或4(已完成,或异议中)的情况下
    requestsindget_f_sh(data) {     
        return axios.post(`${base.htgl}/sind/get_f_sh`, data);    
    },
    // 批量入库 调拨入库  do_in
    requestsindbatch_in(data) {     
        return axios.post(`${base.htgl}/sind/batch_in`, data);    
    },
    // 部分确认,针对单个单子  do_one_in
    requestsindone_part_in(data) {     
        return axios.post(`${base.htgl}/sind/one_part_in`, data);    
    },
    // 申请售后, 对已完成订单, 继续生成异议单
    requestsindsh(data) {     
        return axios.post(`${base.htgl}/sind/sh`, data);    
    },
}
export default article;