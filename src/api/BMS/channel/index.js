import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  


export default {
    // 批量删除缴款单渠道类别
    reqAddPrdConfig: params => axios.post(`${base.htgl}/rpt/cfg/batch_del_rpt_jk_cnl`, params),
  
    // 读取缴款单支付渠道类别列表
    reqDelPrdConfig: params => axios.post(`${base.htgl}/rpt/cfg/get_rpt_jk_cnl_list `, params),
  
    // 读取缴款单支付渠道类别详情, 返回所有类别对应的支付渠道的数据, 前端根据当前类别来判断默认选中,未选中和不可选等操作状态
    reqSavePrdConfig: params => axios.post(`${base.htgl}/rpt/cfg/get_rpt_jk_cnl_dtl`, params),
  
    // 新建/保存缴款单支付渠道类别,支付渠道详情,内容不多,直接全量更新,id=0表示新建
    reqGetPrdConfig: params => axios.post(`${base.htgl}/rpt/cfg/new_or_save_rpt_jk_cnl`, params),
  
    // 移动缴款单渠道类别(调整顺序),使用新的desc dsp模式,新添加的在最上面
    reqGetPrdCateList: params => axios.post(`${base.htgl}/rpt/cfg/move_rpt_jk_cnl_dsp`, params),
  
  }