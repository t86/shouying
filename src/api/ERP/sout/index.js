import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // sout 销售出库,其他出库
    // 读取新建销售,其他出库单出库仓库列表
    requestsoutstore_items(data) {     
        return axios.post(`${base.htgl}/sout/store_items`, data);    
    },
    // 销售出库,其他出库 读取管理列表
    requestsoutlist(data) {     
        return axios.post(`${base.htgl}/sout/list`, data);    
    },
    // 模糊查询物料,只返回有效(用于手工出库)
    requestsoutmat_items(data) {     
        return axios.post(`${base.htgl}/sout/mat_items`, data);    
    },
    // 新建其他出库单, record_type 11 销售出库   17 其他出库
    requestsoutnew(data) {     
        return axios.post(`${base.htgl}/sout/new`, data);    
    },
    // 反审核其他出库单, record_type 11 销售出库  17 其他出库
    requestsoutcs(data) {     
        return axios.post(`${base.htgl}/sout/cs`, data);    
    },
    // 读取其他出库单详情, 用于信息展示
    requestsoutget_f_view(data) {     
        return axios.post(`${base.htgl}/sout/get_f_view`, data);    
    },
    // 读取其他出库单详情, 用于红冲
    requestsoutget_f_hc(data) {     
        return axios.post(`${base.htgl}/sout/get_f_hc`, data);    
    },
    // 读取其他出库单详情, 用于类似创建
    requestsoutget_f_copy(data) {     
        return axios.post(`${base.htgl}/sout/get_f_copy`, data);    
    },
    // 红冲出库单(暂时只支持复合单位,先不考虑红冲转换基本单位)
    requestsouthc(data) {     
        return axios.post(`${base.htgl}/sout/hc`, data);    
    },



}
export default article;