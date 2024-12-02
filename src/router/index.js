import Vue from 'vue'
import VueRouter from 'vue-router'

import erpRouter from './erp'
import bmsRouter from './bms'
import bookRouter from './book'
import orderRouter from './order'
import moneyRouter from './money'
import vipRouter from './vip'
import wineRouter from './wine'
import queueRouter from './queue'

const originalPush = VueRouter.prototype.push;
const originalReplace = VueRouter.prototype.replace;

// push
VueRouter.prototype.push = function push(location, onResolve, onReject) {
  if (onResolve || onReject)
    return originalPush.call(this, location, onResolve, onReject);
  return originalPush.call(this, location).catch(err => err);
};

//replace
VueRouter.prototype.replace = function push(location, onResolve, onReject) {
  if (onResolve || onReject)
    return originalReplace.call(this, location, onResolve, onReject);
  return originalReplace.call(this, location).catch(err => err);
};

Vue.use(VueRouter)

const routes = [
  // 项目根目录
  {
    path: '/', name: 'home', meta: { title: '登录' }, component: () => import('@/views/home.vue'),
  },
  {
    path: '/register', name: 'register', meta: { title: '注册' }, component: () => import('@/views/Register/register.vue'),
  },
  // order/book/erp/mgr 公用登录页面
  {
    path: '/Thelogin', name: 'Thelogin', meta: { title: '登录' }, component: () => import('@/views/Thelogin/Thelogin.vue'),
  },
  // 超级管理员登录
  {
    path: '/appinfo', name: 'appinfo', meta: { title: '登录' }, component: () => import('@/views/Thelogin/appinfo.vue'),
  },

  {
    path: '/front', name: 'front', meta: { title: '' }, component: () => import('@/views/front.vue'),
    redirect: '/money',
    children: [

      // 预定系统
      ...bookRouter,

      // 点单系统
      ...orderRouter,

      // 收银
      ...moneyRouter,

      // 会员
      ...vipRouter,
      //queue
      ...queueRouter,
    ]
  },


  // 后台管理系统
  {
    path: '/ManagementSystem', name: 'ManagementSystem',
    component: () => import('@/views/ManagementSystem/ManagementSystem.vue'),
    redirect: "/ManagementSystem/BMS",
    children: [
      // 门店管理后台
      {
        path: '/ManagementSystem/BMS', name: 'BMS', component: () => import('@/views/ManagementSystem/BMS/BMS.vue'),
        redirect: "/BMS/printer",
        children: [
          // bms
          ...bmsRouter,

          // erp
          ...erpRouter,

          // wine
          ...wineRouter,


        ]
      },
      // appinfo 超级账号  
      {
        path: '/ManagementSystem/appinfo', name: 'appinfo',
        component: () => import('@/views/ManagementSystem/appinfo/appinfo.vue'),
        redirect: "/appinfo/smgr",
        children: [
          // appinfo 超级账号 >> 用户管理
          {
            path: '/appinfo/smgr', name: "smgr", meta: { title: '用户管理' },
            component: () => import('@/views/ManagementSystem/appinfo/smgr/smgr.vue')
          },
        ]
      }


    ]
  },

  // 404
  {
    path: '/*', name: 'notFound', meta: { title: 'notFound' }, component: () => import('@/views/notFound.vue'),
  },


]

// const originalPush = VueRouter.prototype.push
// VueRouter.prototype.push = function push(location){
//   return originalPush.call(this,location).catch(err=>err)
// }
const router = new VueRouter({
  mode: 'history',
  base: 'shouyin',
  routes
})

// 添加路由性能监控函数
function logRoutePerformance(from, to) {
  // 获取路由跳转的性能数据
  const navigation = performance.getEntriesByType('navigation')[0];
  const perfData = {
    from: from.path,
    to: to.path,
    // 路由跳转总时间
    totalTime: performance.now(),
    // 页面加载时间
    loadTime: navigation.loadEventEnd - navigation.loadEventStart,
    // DNS查询时间
    dnsTime: navigation.domainLookupEnd - navigation.domainLookupStart,
    // TCP连接时间
    tcpTime: navigation.connectEnd - navigation.connectStart,
    // 首字节时间
    ttfbTime: navigation.responseStart - navigation.requestStart,
    timestamp: new Date().toISOString()
  };
  
  console.log('路由性能数据:', perfData);
  // 这里可以将数据发送到后端或分析系统
}

// 在router实例创建后添加导航守卫
router.beforeEach((to, from, next) => {
  // 记录路由开始跳转的时间
  window.routeStartTime = performance.now();
  next();
});

router.afterEach((to, from) => {
  // 计算路由跳转耗时
  const routeEndTime = performance.now();
  const routeDuration = routeEndTime - window.routeStartTime;
  
  // 记录性能数据
  logRoutePerformance(from, to);
  
  console.log(`路由跳转耗时: ${routeDuration}ms`);
});

export default router
