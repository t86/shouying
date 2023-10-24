import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  


export default {
    // 获取缴款单统计类别列表
    reqGetRptJkCatList: params => axios.post(`${base.htgl}/rpt/cfg/get_rpt_jk_cate_list`, params),
  
    // 获取缴款单统计类别(商品模式)下明细商品列表
    reqGerRptJkCatePrdList: params => axios.post(`${base.htgl}/rpt/cfg/get_rpt_jk_cate_prd_list `, params),
  
    // 移动缴款单统计类别(调整顺序),使用新的desc dsp模式,新添加的在最上面
    reqMoveRptJkCateDsp: params => axios.post(`${base.htgl}/rpt/cfg/move_rpt_jk_cate_dsp`, params),
  
    // 保存缴款单统计类别(分类模式)下的二级分类
    reqSaveRptJkCateCates: params => axios.post(`${base.htgl}/rpt/cfg/save_rpt_jk_cate_cates`, params),
  
    // 批量删除缴款单统计类别中的商品
    reqBatchDelRptJkCatePitems: params => axios.post(`${base.htgl}/rpt/cfg/batch_del_rpt_jk_cate_pitems`, params),  
    
    // 批量添加商品到缴款单统计类别中
    reqBatchAddRptJkCatePitems: params => axios.post(`${base.htgl}/rpt/cfg/batch_add_rpt_jk_cate_pitems`, params),
      
    // 修改缴款单统计类别名称
    reqSaveRptJkCateName: params => axios.post(`${base.htgl}/rpt/cfg/save_rpt_jk_cate_name`, params),

    // 修改缴款单分类营业类型
    reqSaveRptJkCateBizType: params => axios.post(`${base.htgl}/rpt/cfg/save_rpt_jk_cate_biztype`, params),


    // 读缴款单统计类别待配置商品列表
    reqGetRptJkCatePrdItems: params => axios.post(`${base.htgl}/rpt/cfg/get_rpt_jk_cate_prd_items`, params),

    // 读取缴款单统计类别候选分类列表,树形结构(数据量不大,读取配置页的时候直接使用该接口)
    reqGetRptJkCateCatesItems: params => axios.post(`${base.htgl}/rpt/cfg/get_rpt_jk_cate_cate_items`, params),

    // 新建缴款单统计类别
    reqNewRptJkCate: params => axios.post(`${base.htgl}/rpt/cfg/new_rpt_jk_cate`, params),

    // 批量删除缴款单类别
    reqBatchDelRptJkCate: params => axios.post(`${base.htgl}/rpt/cfg/batch_del_rpt_jk_cate`, params),
  }