import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // paycnl 支付渠道
    // 读取支付渠道管理列表
    requestpaycnllist(data) {     
        return axios.post(`${base.htgl}/paycnl/list`, data);    
    },

    // 勾选
    reqSelectItem: params =>axios.post(`${base.htgl}/paycnl/add_used`, params),

    // 反勾选
    reqNotSelectItem: params =>axios.post(`${base.htgl}/paycnl/del_used`, params),

    // 获取待添加支付渠道管理列表
    requestpaycnlitems(data) {     
        return axios.post(`${base.htgl}/paycnl/items`, data);    
    },
    // 保存新支付渠道
    requestpaycnlnew(data) {     
        return axios.post(`${base.htgl}/paycnl/new`, data);    
    },
    // 删除支付渠道
    requestpaycnldel(data) {     
        return axios.post(`${base.htgl}/paycnl/del`, data);    
    },
    // 移动位置
    requestpaycnlmove_dsp(data) {     
        return axios.post(`${base.htgl}/paycnl/move_dsp`, data);    
    },
    // 移动位置
    requestpaycnlmove(data) {     
        return axios.post(`${base.htgl}/paycnl/move`, data);    
    },
}
export default article;