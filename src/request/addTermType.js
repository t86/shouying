import { sessionStorage } from '../utils/common/storage'

/**
 * 所有接口加入公共参数
 * term_type: 1:门店后台（mgr） 2:预定（book)  4:点单系统（order）  8：收银系统（money） 16：超级管理员（admin）  32: erp 
 */
const termTypeInfo = {
  org_mgr: 1,
  book: 2,
  order: 4,
  money: 8,
  vip: 16, 
  erp: 32,
  erpAdmin: 64,
  wine: 256,
  queuedsp: 512,
}
// 加入公共参数，需要特殊处理的接口
const urlInitArr = [
  '/term/auth',  // 登录页面获取设备授权码
  '/auth/login',  // 登录接口
  '/sauth/login'  // 管理员登录
]

const getTermType = url => {

  const matchReg = /.*[0-9]/
  url = url.replace(matchReg, "")

  let termTypeName = null

  if (urlInitArr.find(item => url.includes(item))) {
    if (location.href.includes('/Thelogin')) termTypeName = sessionStorage.getItem('client')
    else if (location.href.includes('/appinfo')) termTypeName = 'appinfo'
  } else {
    termTypeName = sessionStorage.getItem('client')
  }

  return termTypeInfo[termTypeName]
}

export default getTermType