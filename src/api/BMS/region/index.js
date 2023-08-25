import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {    
    // region 区域
    // 读取区域管理列表
    requestregionlist(data) {     
        return axios.post(`${base.htgl}/region/list`, data);    
    },
    // 新建区域
    requestregionnew(data) {     
        return axios.post(`${base.htgl}/region/new`, data);    
    },
    // 获取编辑区域信息
    requestregionget(data) {     
        return axios.post(`${base.htgl}/region/get`, data);    
    },
    // 保存编辑区域信息
    requestregionsave(data) {     
        return axios.post(`${base.htgl}/region/save`, data);    
    },
    // 区域置为无效
    requestregiondisable(data) {     
        return axios.post(`${base.htgl}/region/disable`, data);    
    },
    // 区域置为有效
    requestregionenable(data) {     
        return axios.post(`${base.htgl}/region/enable`, data);    
    },
    // 区域删除
    requestregiondel(data) {     
        return axios.post(`${base.htgl}/region/del`, data);    
    },
    // 移动位置
    requestregionmove_dsp(data) {     
        return axios.post(`${base.htgl}/region/move_dsp`, data);    
    },
    // 获取区域树,用于区域,卡台管理界面中间的树形结构
    requestRegionTree(data) {
        return axios.post(`${base.htgl}/region/tree`, data);
    },
    // 区域,卡台管理页面,模糊查询目录树
    requestRegionSearch(data) {
        return axios.post(`${base.htgl}/region/search`, data);
    },
    // 状态一键操作
    requestRegionOb(data) {
        return axios.post(`${base.htgl}/region/ob`, data);
    },

    // 获取区域必点商品模糊查询下拉框
    reqGetPrdCateAndPrdList: params => axios.post(`${base.htgl}/region/prd_items`, params)
}
export default article;