import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // rpt_erp ERP报表
    // 读取报表列表参数, 仓库及商品分类
    requestrpt_erpparam_items(data) {     
        return axios.post(`${base.htgl}/rpt_erp/param_items`, data);    
    },
    // 读取库存月报表
    requestrpt_erpmonth_invs(data) {     
        return axios.post(`${base.htgl}/rpt_erp/get_mat_invt`, data);    
    },

    // 导出物料库存表
    reqExportOutMatLib: params => axios.binaryFilePost(`${base.htgl}/rpt_erp/exp_mat_invt`, params),

    // 读取入库明细表
    requestrpt_erpin_recs(data) {     
        return axios.post(`${base.htgl}/rpt_erp/in_recs`, data);    
    },

    // 导出入库明细表
    reqExportInLibRpt: params => axios.binaryFilePost(`${base.htgl}/rpt_erp/exp_in_recs`, params),

    // 读取出库明细表
    requestrpt_erpout_recs(data) {     
        return axios.post(`${base.htgl}/rpt_erp/out_recs`, data);    
    },

    // 导出出库明细表
    reqExportOutLibRpt: params => axios.binaryFilePost(`${base.htgl}/rpt_erp/exp_out_recs`, params),

    // 读取入库汇总
    requestrpt_erpin_sum(data) {     
        return axios.post(`${base.htgl}/rpt_erp/in_sum`, data);    
    },

    // 导出入库汇总表
    reqExportInLibAllRpt: params => axios.binaryFilePost(`${base.htgl}/rpt_erp/exp_in_sum`, params),

    // 读取出库汇总
    requestrpt_erpout_sum(data) {     
        return axios.post(`${base.htgl}/rpt_erp/out_sum`, data);    
    },

    // 导出出库汇总表
    reqExportOutLibAllRpt: params => axios.binaryFilePost(`${base.htgl}/rpt_erp/exp_out_sum`, params),
    

}
export default article;