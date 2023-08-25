import base from '../../base.js'; // 导入接口域名列表
import axios from '../../../utils/http.js'; // 导入http中创建的axios实例  

const cardTips = {

  //  新建卡台标签
  addCardTips: data => axios.post(`${base.htgl}/seat_mark/new`, data),

  //  获取卡台标签管理列表
  getCardTips: data => axios.post(`${base.htgl}/seat_mark/list`, data),

  //  保存卡台标签
  saveCardTips: data => axios.post(`${base.htgl}/seat_mark/save`, data),

  //  批量删除卡台标签
  delCardTips: data => axios.post(`${base.htgl}/seat_mark/del`, data)

}
export default cardTips;