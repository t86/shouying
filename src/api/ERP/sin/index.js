import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // sin 采购入库,其他入库
    // 采购入库,其他入库 读取管理列表
    requestsinlist(data) {     
        return axios.post(`${base.htgl}/sin/list`, data);    
    },
    // 模糊查询物料,只返回有效(用于手工入库)
    requestsinmat_items(data) {     
        return axios.post(`${base.htgl}/sin/mat_items`, data);    
    },
    // 选择某个物料后, 读取物料属性定义
    // requestsinmat_attrs(data) {     
    //     return axios.post(`${base.htgl}/sin/mat_attrs`, data);    
    // },
    // 添加物料商品,如果需要入库的物料商品不存在,则需要添加
    // requestsinlocate_pmat(data) {     
    //     return axios.post(`${base.htgl}/sin/locate_pmat`, data);    
    // },
    // 新建其他入库单, record_type 1 采购入库   7 其他入库
    requestsinnew(data) {     
        return axios.post(`${base.htgl}/sin/new`, data);    
    },
    // 反审核其他入库单, record_type 1 采购入库   7 其他入库
    requestsincs(data) {     
        return axios.post(`${base.htgl}/sin/cs`, data);    
    },
    // 红冲入库单(暂时只支持复合单位,先不考虑红冲转换基本单位)
    requestsinhc(data) {     
        return axios.post(`${base.htgl}/sin/hc`, data);    
    },
    // 读取新建其他入库单辅助信息用
    requestsinnew_sin_items(data) {     
        return axios.post(`${base.htgl}/sin/new_sin_items`, data);    
    },
    // 读取其他入库单详情, 用于信息展示
    requestsinget_f_view(data) {     
        return axios.post(`${base.htgl}/sin/get_f_view`, data);    
    },
    // 读取其他入库单详情, 用于红冲
    requestsinget_f_hc(data) {     
        return axios.post(`${base.htgl}/sin/get_f_hc`, data);    
    },
    // 读取其他入库单详情, 用于类似创建
    requestsinget_f_copy(data) {     
        return axios.post(`${base.htgl}/sin/get_f_copy`, data);    
    },


}
export default article;