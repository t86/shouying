

import store from '../store/index' 
export const canRequest = url => {
  const requestPath = url.split('?')[0].split('#')[0]
  const cardDetailPaths = ['sel/csm_orders', 'wo/list']
  if (cardDetailPaths.some(path => requestPath === path || requestPath.endsWith('/' + path))) {
    // 卡台明细是只读查询：首页限制并发，详情页按请求序号丢弃过期响应。
    // URL 级节流会误拦截不同卡台查询，以及从首页立即进入详情的查询。
    return true
  }
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
