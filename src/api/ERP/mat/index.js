import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // mat 物料管理
    // 读取分类树(一次加载完成)
    requestmatcate_list(data) {     
        return axios.post(`${base.htgl}/mat/cate_list`, data);    
    },
    // 获取商品列表, 根据传入的二级分类
    requestmatlist(data) {     
        return axios.post(`${base.htgl}/mat/list`, data);    
    },
    // 新建
    requestmatnew(data) {     
        return axios.post(`${base.htgl}/mat/new`, data);    
    },
    // 修改物料基础信息
    requestmatchg(data) {     
        return axios.post(`${base.htgl}/mat/save`, data);    
    },
    // 修改物料单位信息
    // requestmatchg_unit(data) {     
    //     return axios.post(`${base.htgl}/mat/chg_unit`, data);    
    // },
    // 添加物料单位配置
    // requestmatadd_unit(data) {     
    //     return axios.post(`${base.htgl}/mat/add_unit`, data);    
    // },
    // 删除物料单位配置
    // requestmatrm_unit(data) {     
    //     return axios.post(`${base.htgl}/mat/rm_unit`, data);    
    // },
    // 保存物料属性配置
    // requestmatchg_attr(data) {     
    //     return axios.post(`${base.htgl}/mat/chg_attr`, data);    
    // },
    // // 添加物料属性配置
    // requestmatadd_attr(data) {     
    //     return axios.post(`${base.htgl}/mat/add_attr`, data);    
    // },
    // // 删除物料属性配置
    // requestmatrm_attr(data) {     
    //     return axios.post(`${base.htgl}/mat/rm_attr`, data);    
    // },
    // 获取信息
    requestmatget(data) {     
        return axios.post(`${base.htgl}/mat/get`, data);    
    },
    // 获取信息 - 只刷新物料单位信息
    // requestmatget_only_unit(data) {     
    //     return axios.post(`${base.htgl}/mat/get_only_unit`, data);    
    // },
    // 获取信息 - 只刷新物料属性信息
    // requestmatget_only_attr(data) {     
    //     return axios.post(`${base.htgl}/mat/get_only_attr`, data);    
    // },
    // 置为无效
    requestmatdisable(data) {     
        return axios.post(`${base.htgl}/mat/disable`, data);    
    },
    // 置为有效
    requestmatenable(data) {     
        return axios.post(`${base.htgl}/mat/enable`, data);    
    },
    // 删除
    requestmatdel(data) {     
        return axios.post(`${base.htgl}/mat/del`, data);    
    },
    // 下载批量导入物料模板
    requestmattpl() {     
        return axios.binaryFilePost(`${base.htgl}/mat/exp_tpl`);    
    },
    // 批量导入物料
    requestmatimp(data) {     
        return axios.post(`${base.htgl}/mat/imp`, data);    
    },
    // 状态一键操作
    requestmatob(data) {     
        return axios.post(`${base.htgl}/mat/ob`, data);    
    },
    
    // 下载批量导入物料及收银商品模板
    requestmatAndProTpl(data) {     
        return axios.binaryFilePost(`${base.htgl}/mat/exp_with_prd_tpl`, data);    
    },
    // 批量导入物料和收银商品
    requestmatAndMoneyimp(data) {     
      return axios.post(`${base.htgl}/mat/imp_with_prd`, data);    
    },

    /**
     * 批量设置二级分类
     */
    reqSetSecondCategory: params => axios.post(`${base.htgl}/mat/batch_upd_two_cate`, params),
}
export default article;