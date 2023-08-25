import base from '../base.js'; // 导入接口域名列表
import axios from '../../utils/http.js'; // 导入http中创建的axios实例  
export default {
  /**
   * 营业日相关接口
   */
  // 获取营业信息,start_time为空表示未开启,否则会返还开启时间格式为 yyyy/mm/dd hh24:mi:ss 预定,点单,收银用来判断是否开启营业
  reqGetOpenStatus: params => axios.post(`${base.htgl}/wkd/get`, params),

  // 开启营业日
  reqWorkStart: params => axios.post(`${base.htgl}/wkd/start`, params),

  // 手动结束营业日并打印班结表
  reqWorkClose: params => axios.post(`${base.htgl}/wkd/close`, params),

  // 获取自动结束营业日配置
  reqGetAutoStopInfo: params => axios.post(`${base.htgl}/wkd/auto_close_cfg`, params),

  // 自动结束营业日
  reqWorkCloseAuto: params => axios.post(`${base.htgl}/wkd/save_auto_close`, params),

  // 恢复营业日
  reqWorkRestore: params => axios.post(`${base.htgl}/wkd/restore`, params),

  /**
   * 预定/预留接口
   */
  // 获取卡台列表所有相关元数据
  reqGetAllData: params => axios.post(`${base.htgl}/sync_base/all`, params),

  // 获取卡台列表websocket断开之后的增量元数据
  reqGetUpdateData: params => axios.post(`${base.htgl}/sync_base/increment`, params),

  // 获取常用客人联系方式
  reqGetCustomPhone: params => axios.post(`${base.htgl}/bk/customers`, params),

  // 空台开台
  reqNullToOpenCard: params => axios.post(`${base.htgl}/bk/direct_open`, params),

  // 预定开台
  reqReserveToOpenCard: params => axios.post(`${base.htgl}/bk/open`, params),

  // 新增预留
  reqAddReservedInfo: params => axios.post(`${base.htgl}/bk/new`, params),

  // 编辑预留
  reqUpdateReservedInfo: params => axios.post(`${base.htgl}/bk/save`, params),

  // 取消预留
  reqCancelReservedInfo: params => axios.post(`${base.htgl}/bk/cancel`, params),
  
  // 获取一条预留信息详情
  reqGetBookDetail: params => axios.post(`${base.htgl}/bk/get`, params),

  // 预定转台
  reqReserveToChangeCard: params => axios.post(`${base.htgl}/bk/chg_seat`, params),

  // 空台锁定
  reqClockCard: params => axios.post(`${base.htgl}/bk/lock`, params),

  // 空台取消锁定
  reqCancelClockCard: params => axios.post(`${base.htgl}/bk/unlock`, params),

  // 修改开台低消
  reqUpdateLowConsume: params => axios.post(`${base.htgl}/bk/chg_csm_mca`, params),

  // 修改开台订位人
  reqUpdateOpenSales: params => axios.post(`${base.htgl}/bk/chg_sales`, params),

  // 开台状态下的撤台
  reqCancelOpenCard: params => axios.post(`${base.htgl}/bk/cancel_open`, params),

  // 开台状态下的修改开台类型
  reqUpdateOpenType: params => axios.post(`${base.htgl}/bk/chg_open_type`, params),

  // 开台状态下转台
  reqOpenToChange: params => axios.post(`${base.htgl}/bk/chg_csm_seat`, params),

  // 读取修改翻台定位人,历史流水列表
  reqGetTurnOverList: params => axios.post(`${base.htgl}/bk/get_his_sales`, params),

  // 修改翻台定位人
  reqUpdateTurnOverDetail: params => axios.post(`${base.htgl}/bk/chg_his_sales`, params),

  // 当前营业日,临时在线卡台转线下
  reqTurnLineBottomCard: params => axios.post(`${base.htgl}/bk/conv_ol_seat_local`, params),

  // 读取转台记录列表
  reqTurnOverList: params => axios.post(`${base.htgl}/bk/get_chg_seat_log`, params),

  // 读取开台记录,可用的区域和订位人
  reqOpenCardListParams: params => axios.post(`${base.htgl}/bk/get_seat_open_log_params`, params),

  // 读取开台记录日志
  reqOpenCardListData: params => axios.post(`${base.htgl}/bk/get_seat_open_log`, params),

  // 下载开台记录
  reqExportOpenCardExcel: params => axios.binaryFilePost(`${base.htgl}/bk/exp_seat_open_log`, params),

  // 咨客台置顶卡台,将常用卡台置顶便于操作
  reqTopCard: params => axios.post(`${base.htgl}/bk/top_seat_dsp`, params),

  // 咨客台取消置顶卡台,将常用卡台置顶便于操作
  reqCancelTopCard: params => axios.post(`${base.htgl}/bk/cancel_top_seat_dsp`, params),

  /**
   * 修改卡台标记
   */
  // 修改卡台标记
  reqUpdateCardTips: params => axios.post(`${base.htgl}/bk/set_seat_mark`, params),
}