import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // soutd 调拨出库
    // 调拨出库 读取管理列表
    requestsoutdlist(data) {     
        return axios.post(`${base.htgl}/soutd/list`, data);    
    },
    // 模糊查询物料,只返回有效(用于手工出库)
    requestsoutdmat_items(data) {     
        return axios.post(`${base.htgl}/soutd/mat_items`, data);    
    },

    // 读取指定物料清单,对应全部可操作仓库的, 可用数量及成本金额
    reqGetMatLibCount: params => axios.post(`${base.htgl}/rpt_erp/get_mat_store_invts`, params),

    // 新建调拨出库单, record_type 3 调拨
    requestsoutdnew(data) {     
        return axios.post(`${base.htgl}/soutd/new`, data);    
    },
    // 反审核调拨出库单, record_type 3 调拨
    requestsoutdcs(data) {     
        return axios.post(`${base.htgl}/soutd/cs`, data);    
    },
    // 读取调拨出库单详情, 用于信息展示
    requestsoutdget_f_view(data) {     
        return axios.post(`${base.htgl}/soutd/get_f_view`, data);    
    },
    // 读取调拨出库单详情, 用于红冲
    requestsoutdget_f_hc(data) {     
        return axios.post(`${base.htgl}/soutd/get_f_hc`, data);    
    },
    // 读取调拨出库单详情, 用于类似创建
    requestsoutdget_f_copy(data) {     
        return axios.post(`${base.htgl}/soutd/get_f_copy`, data);    
    },
    // 红冲调拨出库单(只支持基本单位)
    requestsoutdhc(data) {     
        return axios.post(`${base.htgl}/soutd/hc`, data);    
    },
    // 读取出库仓库及入库仓库列表(入库仓库不需要管权限)
    requestsoutdstore_items(data) {     
        return axios.post(`${base.htgl}/soutd/store_items`, data);    
    },
}
export default article;