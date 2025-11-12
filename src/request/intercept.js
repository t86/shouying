

import store from '../store/index' 
export const canRequest = url => {
  const dateNum = +new Date()
  const prevNum = store.state.requestInfo[url]

  // 如果是第一次请求（prevNum不存在或为0），直接允许
  if (!prevNum || prevNum === 0) {
    store.commit('updateRequestInfo', {
      ...store.state.requestInfo,
      [url]: dateNum
    })
    return true
  }

  const isMoneyOrderInterface = url.includes('sel/csm_orders')
  const timeDiff = dateNum - prevNum
  const minInterval = isMoneyOrderInterface ? 100 : 0

  // 时间差大于最小间隔，允许请求
  const result = timeDiff > minInterval

  if (result) {
    store.commit('updateRequestInfo', {
      ...store.state.requestInfo,
      [url]: dateNum
    })
  }
  return result
}