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

// 修改路由性能监控函数
function logRoutePerformance(from, to) {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] 路由变化开始 - 从 ${from.path} 到 ${to.path}`);
  
  const perfData = {
    from: from.path,
    to: to.path,
    routeChangeTime: performance.now() - window.routeStartTime,
    timestamp
  };

  const routeEndTime = performance.now();
  const routeDuration = routeEndTime - window.routeStartTime;
  console.log(`[${new Date().toISOString()}] 路由跳转耗时: ${routeDuration}ms`);
  
  // 记录路由变化到首次渲染的时间
  const observer = new PerformanceObserver((list) => {
    const entries = list.getEntries();
    const lastPaint = entries[entries.length - 1];
    const currentTime = new Date().toISOString();
    
    perfData.firstPaintTime = lastPaint.startTime;
    perfData.firstPaintDuration = lastPaint.duration;
    
    console.log(`[${currentTime}] 首次渲染完成:`, {
      ...perfData,
      totalTime: lastPaint.startTime + lastPaint.duration - window.routeStartTime,
    });
    
    observer.disconnect();
  });
  
  observer.observe({ entryTypes: ['paint'] });
}

// 在router实例创建后添加导航守卫
router.beforeEach((to, from, next) => {
  window.routeStartTime = performance.now();
  console.log(`[${new Date().toISOString()}] 路由导航开始`);
  next();
});

// 修改 afterEach 钩子
router.afterEach((to, from) => {
  // 记录性能数据
  logRoutePerformance(from, to);
  
  // 给目标组件添加渲染完成时间监控
  const lastMatched = to.matched[to.matched.length - 1];
  const targetComponent = lastMatched && lastMatched.components ? lastMatched.components.default : null;
  
  if (targetComponent) {
    const originalMounted = targetComponent.mounted;
    targetComponent.mounted = function() {
      const mountedTime = performance.now();
      const renderTime = mountedTime - window.routeStartTime;
      console.log(`组件渲染完成时间: ${renderTime}ms`);
      
      // 调用原始的 mounted 钩子
      if (originalMounted) {
        originalMounted.call(this);
      }
    }
  }
});

export default router
