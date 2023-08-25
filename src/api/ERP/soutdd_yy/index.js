import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // d_yy 出入库异议订单  
    // 调拨 出库方读取异议订单管理列表
    requestd_yyout_list(data) {     
        return axios.post(`${base.htgl}/d_yy/out_list`, data);    
    },
    // 调拨 入库方读取异议订单管理列表(需提供header.tk)
    requestd_yyin_list(data) {     
        return axios.post(`${base.htgl}/d_yy/in_list`, data);    
    },
    // 出库方驳回调拨出库异议单
    requestd_yyout_back(data) {     
        return axios.post(`${base.htgl}/d_yy/out_back`, data);    
    },
    // 出库方异议订单异议数量直接红冲
    requestd_yyout_hc(data) {     
        return axios.post(`${base.htgl}/d_yy/out_hc`, data);    
    },
    // 出库方异议订单异议数量报损出库
    requestd_yyout_bs(data) {     
        return axios.post(`${base.htgl}/d_yy/out_bs`, data);    
    },

    // 入库方, 读取异议单流水列表, 用于展示 出库方异议单详情或入库方异议单详情
    req_in_yy_dtls(data){
      return axios.post(`${base.htgl}/d_yy/in_yy_dtls`, data);  
    },

    // 出库方, 读取异议单流水列表, 用于展示 出库方异议单详情或入库方异议单详情(主数据使用管理列表数据填充即可)
    req_out_yy_dtls(data){
      return axios.post(`${base.htgl}/d_yy/out_yy_dtls`, data);  
    },
    // 入库方驳回调拨出库异议单
    requestd_yyin_back(data) {     
        return axios.post(`${base.htgl}/d_yy/in_back`, data);    
    },
    // 入库方确认无异议
    requestd_yyin_confirm(data) {     
        return axios.post(`${base.htgl}/d_yy/in_confirm`, data);    
    },
    // 入库方撤销异议订单
    requestd_yyin_cancel(data) {     
        return axios.post(`${base.htgl}/d_yy/in_cancel`, data);    
    },
}
export default article;