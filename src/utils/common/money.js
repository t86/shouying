import store from '@/store'
export default {
  // 通过选择好的支付方式id获取支付渠道信息
  getPayInfo(payId) {
    const allPayList = store.state.cardPageInfo.resResultDataObj["payList"].filter(el => el.status == 1);
    return allPayList.find(el => el.id == payId)
  },

}