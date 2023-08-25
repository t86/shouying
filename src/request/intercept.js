

import store from '../store/index' 
export const canRequest = url => {
  const dateNum = +new Date()
  const prevNum = store.state.requestInfo[url] || 0

  const isMoneyOrderInterface = url.includes('sel/csm_orders')

  const result = dateNum - prevNum > (isMoneyOrderInterface ? 100 : 0)

  if (result) {
    store.commit('updateRequestInfo', {
      ...store.state.requestInfo,
      [url]: dateNum
    })
  }
  return result
}