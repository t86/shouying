import base from "../base.js"; // 导入接口域名列表
import axios from "../../utils/http.js"; // 导入http中创建的axios实例
export default {
  /**
   * 会员卡类型
   */
  // 读取会员卡类型列表
  reqGetVipTypeList: (params) =>
    axios.post(`${base.htgl}/mb/type/list`, params),

  // 读取会员卡类型详情
  reqGetVipTypeDetail: (params) =>
    axios.post(`${base.htgl}/mb/type/get`, params),

  // 新增会员卡类型
  reqAddVipType: (params) => axios.post(`${base.htgl}/mb/type/new`, params),

  // 修改会员卡类型名称
  reqUpdateVipType: (params) =>
    axios.post(`${base.htgl}/mb/type/chg_name`, params),

  // 修改会员卡类型默认项
  reqUpdateDefaultVipType: (params) =>
    axios.post(`${base.htgl}/mb/type/chg_def`, params),

  // 添加会员卡等级
  reqAddVipTypeDeep: (params) =>
    axios.post(`${base.htgl}/mb/type/new_level`, params),

  // 修改会员卡等级名称
  reqUpdateVipDeepName: (params) =>
    axios.post(`${base.htgl}/mb/type/chg_level_name`, params),

  // 修改会员卡等级卡面图片
  reqUpdateVipDeepPic: (params) =>
    axios.post(`${base.htgl}/mb/type/chg_level_pic`, params),

  // 删除会员卡等级
  reqDelVipDeep: (params) =>
    axios.post(`${base.htgl}/mb/type/del_level`, params),

  // 删除会员卡类型
  reqDelVipType: (params) => axios.post(`${base.htgl}/mb/type/del`, params),

  // 添加自定义卡面
  reqAddUploadBgiImg: (params) =>
    axios.post(`${base.htgl}/mb/type/new_cust_cover`, params),

  // 删除自定义卡面
  reqDelUploadBgiImg: (params) =>
    axios.post(`${base.htgl}/mb/type/del_cust_cover`, params),

  // 读取自定义卡面列表
  reqGetUploadBgiImg: (params) =>
    axios.post(`${base.htgl}/mb/type/get_cust_cover_list`, params),

  // 读取图片服务的前缀地址
  reqOssImgBaseUrl: (params) =>
    axios.post(`${base.htgl}/oss/get_pic_prefix`, params),

  /**
   * 会员管理
   */
  // 发送手机验证码
  reqSendPhoneMsg: (params) =>
    axios.post(`${base.htgl}/sms/valid_send`, params),

  // 验证手机验证码,验证通过返回授权串
  reqValidatePhoneMsg: (params) =>
    axios.post(`${base.htgl}/sms/valid_chk`, params),

  // 读取新建会员参数
  reqGetAddVipCardParams: (params) =>
    axios.post(`${base.htgl}/mb/card/get_params_f_new`, params),

  // 新增会员卡
  reqAddVipCard: (params) => axios.post(`${base.htgl}/mb/card/new`, params),

  // 读取会员卡列表
  reqGetVipCardList: (params) =>
    axios.post(`${base.htgl}/mb/card/list`, params),

  // 获取绑定手机名下已有会员卡
  reqGetVipOfBindThisPhoneNum: (params) =>
    axios.post(`${base.htgl}/mb/card/phone_mb_list`, params),

  // 制卡开始
  reqMakeVipCardBegin: (params) =>
    axios.post(`${base.htgl}/mb/card/mk_card_begin`, params),

  // 制卡结束
  reqMakeVipCardEnd: (params) =>
    axios.post(`${base.htgl}/mb/card/mk_card_end`, params),

  /**
   * 线上充值设置
   */
  // 读取会员充送规则列表
  reqGetVipCardMakeMoneyListRule: (params) =>
    axios.post(`${base.htgl}/mb/deposit_rule/list`, params),

  // 新建会员充送规则
  reqAddVipCardMakeMoneyRule: (params) =>
    axios.post(`${base.htgl}/mb/deposit_rule/new`, params),

  // 修改会员充送规则
  reqUpdateVipCardMakeMoneyRule: (params) =>
    axios.post(`${base.htgl}/mb/deposit_rule/save`, params),

  // 删除会员充送规则
  reqDelVipCardMakeMoneyRule: (params) =>
    axios.post(`${base.htgl}/mb/deposit_rule/del`, params),

  /**
   *
   * 会员卡结账规则
   */
  // 读取会员卡消费规则配置列表
  reqGetVipBillRuleList: (params) =>
    axios.post(`${base.htgl}/mb/card/get_grp_mb_csm_rule_list`, params),

  // 获取会员卡消费规则,待配置候选商品
  reqGetVipBillRuleProductsList: (params) =>
    axios.post(`${base.htgl}/mb/card/get_grp_mb_csm_rule_items`, params),

  // 添加会员卡消费规则
  reqAddVipBillRule: (params) =>
    axios.post(`${base.htgl}/mb/card/add_grp_mb_csm_rule`, params),

  // 修改会员卡消费规则
  reqUpdateVipBillRule: (params) =>
    axios.post(`${base.htgl}/mb/card/chg_grp_mb_csm_rule`, params),

  // 删除会员卡消费规则
  reqDelVipBillRule: (params) =>
    axios.post(`${base.htgl}/mb/card/del_grp_mb_csm_rule`, params),

    
  // 复制结账配置
  reqCopyVipBillRule: (params) =>
  axios.post(`${base.htgl}/mb/card/clone_grp_mb_csm_rule`, params),


  /**
   * 会员充值
   */

  // 通过手机号后四位模糊查询待充值会员卡列表
  reqGetMakeMoneyListOfPhoneNum: (params) =>
    axios.post(`${base.htgl}/mb/card/get_f_deposits`, params),

  // 读取会员卡密
  reqGetVipCardPwdMsg: (params) =>
    axios.post(`${base.htgl}/mb/card/get_card_p`, params),

  // 读取虚拟会员卡Id
  reqGetVipCardId: (params) =>
    axios.post(`${base.htgl}/mb/card/get_mb_card_f_real`, params),

  // 读取虚拟会员卡详情for充值
  reqGetVipCardDetailForMakeMoney: (params) =>
    axios.post(`${base.htgl}/mb/card/get_mb_card_f_deposit`, params),

  // 充值会员卡
  reqMakeMoneyToCard: (params) =>
    axios.post(`${base.htgl}/mb/card/deposit`, params),

  // 充值积分接口
  reqAddMemberPoint: (params) =>
  axios.post(`${base.htgl}/mb/card/deposit_pt`, params),

  /**
   *  option
   */

  // 编辑会员卡
  reqUpdateVipCard: (params) => axios.post(`${base.htgl}/mb/card/save`, params),

  // 读取会员卡信息for修改卡信息
  reqGetVipInfoFormEditVipInfo: (params) =>
    axios.post(`${base.htgl}/mb/card/get_f_edit`, params),

  // 读取会员卡信息for更改等级
  reqGetVipCardDeep: (params) =>
    axios.post(`${base.htgl}/mb/card/get_f_chg_level`, params),

  // 更改会员卡等级
  reqUpdateVipCardDeep: (params) =>
    axios.post(`${base.htgl}/mb/card/chg_level`, params),

  // 读取会员卡信息for绑定手机
  reqUGetVipCardInfoFromBindPhoneNum: (params) =>
    axios.post(`${base.htgl}/mb/card/get_f_bind_phone`, params),

  // 更改会员卡绑定手机
  reqUpdateVipCardBindPhoneNum: (params) =>
    axios.post(`${base.htgl}/mb/card/chg_bind_phone`, params),

  // 绑定会员卡认证手机
  reqBindVipCardPhoneNum: (params) =>
    axios.post(`${base.htgl}/mb/card/bind_bind_phone`, params),

  // 会员卡扣款
  reqSubMoneyFromCard: (params) =>
    axios.post(`${base.htgl}/mb/card/subtract`, params),

  // 会员卡 扣除积分
  reqSubPointFromCard: (params) =>
    axios.post(`${base.htgl}/mb/card/subtract_pt`, params),

  // 会员卡读取虚拟会员卡详情for扣款/修改手机/挂失/解除挂失/退卡/注销扣款
  reqVipCardGetVNodeCard: (params) =>
    axios.post(`${base.htgl}/mb/card/get_mb_card_f_oper`, params),

  // 挂失会员卡
  reqAbleVipCard: (params) =>
    axios.post(`${base.htgl}/mb/card/loss_card`, params),

  // 取消挂失会员卡
  reqEnableVipCard: (params) =>
    axios.post(`${base.htgl}/mb/card/enable_card`, params),

  // 换卡制卡开始
  reqChangeVipCardBegin: (params) =>
    axios.post(`${base.htgl}/mb/card/mk_card_f_chg_begin`, params),

  // 换卡制卡结束
  reqChangeVipCardEnd: (params) =>
    axios.post(`${base.htgl}/mb/card/mk_card_f_chg_end`, params),

  // 退卡
  reqBackVipCard: (params) => axios.post(`${base.htgl}/mb/card/return`, params),

  // 注销会员卡
  reqDestroyVipCard: (params) =>
    axios.post(`${base.htgl}/mb/card/close`, params),

  /**
   * 会员卡详情
   */
  // 查看会员详情
  reqGetVipCardDetail: (params) =>
    axios.post(`${base.htgl}/mb/info/get`, params),

  // 读取会员下的卡片列表
  reqGetVipCardListOfOnePhoneNum: (params) =>
    axios.post(`${base.htgl}/mb/info/get_cards`, params),

  //  读取会员下的卡片交易明细
  reqGetVipCarPayMoneyListDetail: (params) =>
    axios.post(`${base.htgl}/mb/info/get_bal_logs`, params),

  /**
   * 报表管理
   */
  // 读取充值记录
  reqGetVipCardMakeMoneyListReport: (params) =>
    axios.post(`${base.htgl}/mb/rpt/get_deposit_log`, params),

  // 下载充值记录excel
  reqExportExcelForMakeMoney: (params) =>
    axios.binaryFilePost(`${base.htgl}/mb/rpt/exp_deposit_log`, params),

  // 读取扣款记录
  reqGetVipCarSubMoneyListReport: (params) =>
    axios.post(`${base.htgl}/mb/rpt/get_subtract_log`, params),

  // 下载扣款记录excel
  reqExportExcelForSubMoney: (params) =>
    axios.binaryFilePost(`${base.htgl}/mb/rpt/exp_subtract_log`, params),

  // 下载消费记录excel
  reqExportExcelForPayMoney: (params) =>
    axios.binaryFilePost(`${base.htgl}/mb/rpt/exp_consume_log`, params),

  // 充值/扣款小票重打( 旧
  reqPrintTicket: (params) =>
    axios.post(`${base.htgl}/mb/rpt/re_print_dep_sub_bill`, params),

  // 充值/扣款小票重打( 新
  reqPrintTicketNew: (params) =>
    axios.post(`${base.htgl}/mb/rpt/re_print_mb_bill`, params),
  /**
   * 会员卡生成规则
   */
  // 获取会员卡号生成规则
  reqGetVipCardNoRule: (params) =>
    axios.post(`${base.htgl}/mb/card/get_mb_card_no_rule`, params),

  // 保存会员卡号生成规则
  reqSetVipCardNoRule: (params) =>
    axios.post(`${base.htgl}/mb/card/save_mb_card_no_rule`, params),

  // 读取可用会员卡号,用于创建卡
  reqCreateVipCardNo: (params) =>
    axios.post(`${base.htgl}/mb/card/get_next_no`, params),

  // 开卡推荐人列表
  reqGetRecommnedList: (params) =>
    axios.post(`${base.htgl}/mb/card/list`, params),

  // 充值积分 保存规则
  reqSavePointRule: (params) =>
    axios.post(`${base.htgl}/mb/card/save_pt_rule`, params),

  // 充值积分 获取规则
  reqGetPointRule: (params) =>
    axios.post(`${base.htgl}/mb/card/get_pt_rule`, params),

  // 下载会员信息excel
  reqExportExcelForVipManager: (params) =>
  axios.binaryFilePost(`${base.htgl}/mb/card/exp_mb_card_list`, params),

  // 读取消费记录
  reqGetVipCarXFListReport: (params) =>
    axios.post(`${base.htgl}/mb/rpt/get_consume_log`, params),

  // 读取积分记录
  reqGetDeductionPointListReport: (params) =>
    axios.post(`${base.htgl}/mb/rpt/get_pt_log`, params),
  // 下载积分记录excel
  reqExportExcelForDeductionPoint: (params) =>
    axios.binaryFilePost(`${base.htgl}/mb/rpt/exp_pt_log`, params),
  // 读取会员卡余额汇总表
  reqGetVipBalanceListReport: (params) =>
    axios.post(`${base.htgl}/mb/rpt/get_mb_card_bal_list`, params),
  // 下载会员卡余额汇总表excel
  reqExportExcelForVipBalance: (params) =>
    axios.binaryFilePost(`${base.htgl}/mb/rpt/exp_mb_card_bal_list`, params),

  // 读取会员消费排名
  reqGetMbCardTopConsume: (params) =>
    axios.post(`${base.htgl}/mb/rpt/get_mb_card_top_consume`, params),
  // 导出会员消费排名
  reqExportMbCardTopConsume: (params) =>
    axios.binaryFilePost(`${base.htgl}/mb/rpt/exp_mb_card_top_consume`, params),

  // 读取客户关系维护
  reqGetMbCardConsumeList: (params) =>
    axios.post(`${base.htgl}/mb/rpt/get_mb_card_consume_list`, params),
  // 导出客户关系维护
  reqExportMbCardConsumeList: (params) =>
    axios.binaryFilePost(`${base.htgl}/mb/rpt/exp_mb_card_consume_list`, params),
};
