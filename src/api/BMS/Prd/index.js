import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const article = {
  // prd 商品

  // 读取erp商品
  requestprderp_prds(data) {
    return axios.post(`${base.htgl}/prd/erp_prds`, data);
  },
  // 读取商品辅助数据
  requestprdass_items(data) {
    return axios.post(`${base.htgl}/prd/ass_items`, data);
  },
  // 获取商品列表, 根据传入的二级分类
  requestprdlist(data) {
    return axios.post(`${base.htgl}/prd/list`, data);
  },
  // 新建商品
  requestprdnew(data) {
    return axios.post(`${base.htgl}/prd/new`, data);
  },
  // 获取信息 (如果id传0,代表新建商品, 会返回对应的一级分类默认出品库和出品库列表用于自定义配置)
  requestprdget(data) {
    return axios.post(`${base.htgl}/prd/get`, data);
  },
  // 保存编辑商品
  requestprdsave(data) {
    return axios.post(`${base.htgl}/prd/save`, data);
  },
  // 置为无效
  requestprddisable(data) {
    return axios.post(`${base.htgl}/prd/disable`, data);
  },
  // 置为有效
  requestprdenable(data) {
    return axios.post(`${base.htgl}/prd/enable`, data);
  },
  // 删除
  requestprddel(data) {
    return axios.post(`${base.htgl}/prd/del`, data);
  },
  // 移动位置
  requestprdmove_dsp(data) {
    return axios.post(`${base.htgl}/prd/move_dsp`, data);
  },

  // 状态一键操作
  requestprdob(data) {
    return axios.post(`${base.htgl}/prd/ob`, data);
  },


  // set 套餐
  // 获取套餐商品配置项模糊查询下拉框
  requestprdget_set_items(data) {
    return axios.post(`${base.htgl}/prd/get_set_items`, data);
  },
  // 新增
  requestprdnew_set(data) {
    return axios.post(`${base.htgl}/prd/new_set`, data);
  },
  // 获取信息 (如果id传0,代表新建商品, 会返回对应的一级分类默认出品库和出品库列表用于自定义配置)
  requestprdget_set(data) {
    return axios.post(`${base.htgl}/prd/get_set`, data);
  },
  // 保存
  requestprdsave_set(data) {
    return axios.post(`${base.htgl}/prd/save_set`, data);
  },

  // prd 商品分类树
  // 获取商品分类树,用于商品管理界面中间的树形结构
  requestprdcatetree(data) {
    return axios.post(`${base.htgl}/cate/tree`, data);
  },

  get_member_price_cfg(data) {return axios.post(`${base.htgl}/org/get_member_price_cfg`, data)},
  save_member_price_cfg(data) {return axios.post(`${base.htgl}/org/save_member_price_cfg`, data)},

  // 商品管理页面,模糊查询目录树
  requestprdcatesearch(data) {
    return axios.post(`${base.htgl}/cate/search`, data);
  },

  // 读取OSS认证信息
  requestOssPt(data) {
    return axios.post(`${base.htgl}/oss/pt`, data);
  },
  // 上传图片
  handleUploadFile(url, param, fileBlob) {
    return axios.handleUploadFile(url, param, fileBlob);
  },

  /**
   * 批量上传图片页面
   */
  // 商品批量上传图片检查
  reqCheckProImg: params => axios.post(`${base.htgl}/prd/batch_upload_pic_chk`, params),

  // 商品批量上传图片保存
  reqUploadProImg: params => axios.post(`${base.htgl}/prd/batch_upload_pic`, params),

  // 商品图片检测,返回没有图片的商品列表
  reqCheckNoProImgList: params => axios.post(`${base.htgl}/prd/get_no_pic_prds`, params),

  // 图片检测页面上传商品图片
  reqUploadSingleImg: params => axios.post(`${base.htgl}/prd/upload_pic`, params),


  // 商品管理-批量上传商品图片页面上传商品默认图片
  reqSavePrdDefPic: params => axios.post(`${base.htgl}/prd/save_prd_def_pic`, params),

  // 商品管理-获取商品默认图片
  reqGetPrdDefPic: params => axios.post(`${base.htgl}/prd/get_prd_def_pic`, params),

  /**
   * 批量导入商品（excel）
   */
  

  // 下载模板文件, 将商品一级二级分类，用于批量导入商品
  reqDownLoadProTpl: () => axios.binaryFilePost(`${base.htgl}/prd/exp_tpl`),

  // 批量导入
  reqImportProData: params => axios.post(`${base.htgl}/prd/imp`, params),


  /**
   * 批量设置区域出品库
   */
  // 读取二级分类下,商品的区域出品库(相同配置最多的展示为通用配置,否则返回为特殊配置)
  reqGetTwoCateSingleDetail: params => axios.post(`${base.htgl}/prd/get_prd_region_cfg`, params),

  //  读取二级分类下,商品(套餐)的可点区域(相同配置最多的展示为通用配置,否则返回为特殊配置)
  reqGetTwoCateGroupDetail: params => axios.post(`${base.htgl}/prd/get_set_region_cfg`, params),

  // 保存商品(单品)的区域出品库
  reqSaveSinglePrdConfig: params => axios.post(`${base.htgl}/prd/save_prd_region_cfg`, params),

  // 保存商品(套餐)的可点区域
  reqSaveGroupPrdConfig: params => axios.post(`${base.htgl}/prd/save_set_region_cfg`, params),

  /**
   * 批量设置二级分类
   */
  reqSetSecondCategory: params => axios.post(`${base.htgl}/prd/batch_upd_two_cate`, params),

  // reqSetMp: params => axios.post(`${base.htgl}/prd/batch_set_show_in_mp`, params),


  /*
    客户端传入json:
    ids        []int64      //PrdIds 待操作商品Id列表
    limit_pc   int        //LimitPc 限制pc端 1 限制 2 不限制
    limit_pad  int        //LimitPad 限制pad端 1 限制 2 不限制
    limit_xcx_emp int        //LimitXcxEmp 限制小程序-员工端 1 限制 2 不限制
    limit_xcx_cust int        //LimitXcxCust 限制小程序-客人端 1 限制 2 不限制
   */
  reqSetMp: params => axios.post(`${base.htgl}/prd/batch_set_show_limit`, params),
  // reqSetMp: params => axios.post(`${base.htgl}/prd/batch_set_show_in_mp`, params),

  get_prd_set_tpl_list: params => axios.post(`${base.htgl}/prd/get_prd_set_tpl_list`, params),
  new_prd_set_tpl: params => axios.post(`${base.htgl}/prd/new_prd_set_tpl`, params),
  save_prd_set_tpl: params => axios.post(`${base.htgl}/prd/save_prd_set_tpl`, params),
  batch_del_prd_set_tpl: params => axios.post(`${base.htgl}/prd/batch_del_prd_set_tpl`, params),
  get_prd_set_tpl: params => axios.post(`${base.htgl}/prd/get_prd_set_tpl`, params),


}
export default article;