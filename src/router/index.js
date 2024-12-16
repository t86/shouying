import Vue from 'vue'
import VueRouter from 'vue-router'
import SkeletonLogin from '@/components/skeleton/SkeletonLogin.vue'
import SkeletonRegister from '@/components/skeleton/SkeletonRegister.vue'

function preloadComponent(component) {
  try {
    component();
  } catch (e) {
    console.error('组件预加载失败:', e);
  }
}


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
    path: '/', 
    name: 'home', 
    meta: { title: '登录',      skeleton: SkeletonLogin }, 
    component: () => import(
      /* webpackChunkName: "home" */
      /* webpackPrefetch: true */
      '@/views/home.vue'
    ),
  },
  {
    path: '/register', 
    name: 'register', 
    meta: { 
      title: '注册',
      skeleton: SkeletonRegister 
    }, 
    component: () => import(/* webpackPrefetch: true */ '@/views/Register/register.vue'),
  },
  // order/book/erp/mgr 公用登录页面
  {
    path: '/Thelogin', 
    name: 'Thelogin', 
    meta: { 
      title: '登录',
      skeleton: SkeletonLogin 
    }, 
    component: () => import(/* webpackPrefetch: true */ '@/views/Thelogin/Thelogin.vue')
  },
  // 超级管理员登录
  {
    path: '/appinfo', 
    name: 'appinfo', 
    meta: { title: '登录' }, 
    component: () => import('@/views/Thelogin/appinfo.vue'),
  },

  {
    path: '/front', 
    name: 'front', 
    meta: { title: '' }, 
    component: () => import('@/views/front.vue'),
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
    path: '/ManagementSystem', 
    name: 'ManagementSystem',
    component: () => import('@/views/ManagementSystem/ManagementSystem.vue'),
    redirect: "/ManagementSystem/BMS",
    children: [
      // 门店管理后台
      {
        path: '/ManagementSystem/BMS', 
        name: 'BMS', 
        component: () => import('@/views/ManagementSystem/BMS/BMS.vue'),
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
        path: '/ManagementSystem/appinfo', 
        name: 'appinfo',
        component: () => import('@/views/ManagementSystem/appinfo/appinfo.vue'),
        redirect: "/appinfo/smgr",
        children: [
          // appinfo 超级账号 >> 用户管理
          {
            path: '/appinfo/smgr', 
            name: "smgr", 
            meta: { title: '用户管理' },
            component: () => import('@/views/ManagementSystem/appinfo/smgr/smgr.vue')
          },
        ]
      }


    ]
  },

  // 404
  {
    path: '/*', 
    name: 'notFound', 
    meta: { title: 'notFound' }, 
    component: () => import('@/views/notFound.vue'),
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
  if (window.routeStartTime) {
    const endTime = performance.now();
    const duration = endTime - window.routeStartTime;
    console.log(`[${new Date().toISOString()}] 路由切换完成: ${from.path} -> ${to.path}, 耗时: ${duration.toFixed(2)}ms`);
    window.routeStartTime = null;
  }
}

router.beforeEach(async (to, from, next) => {
  window.routeStartTime = performance.now();
  
  // 预加载目标组件
  if (to.matched[0] && to.matched[0].components && typeof to.matched[0].components.default === 'function') {
    try {
      await to.matched[0].components.default();
    } catch (error) {
      console.error('组件预加载失败:', error);
    }
  }
  
  next();
});

router.afterEach((to, from) => {
  logRoutePerformance(from, to);
});

export default router
