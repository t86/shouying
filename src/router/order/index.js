export default [
  // 点单首页列表
  {
    path: '/orderCard', 
    name: 'orderCard', 
    meta: { title: '卡台信息' }, 
    component: () => import(/* webpackChunkName: "orderCard" */ '@/views/Order/newOrderCard.vue'),
  },
  // 点单页面
  {
    path: '/orderMeal', 
    name: 'orderMeal', 
    meta: { title: '' }, 
    component: () => import(/* webpackChunkName: "orderMeal" */ '@/views/Order/orderMeal/index.vue'),
    redirect: "/orderMeal/orderMealList",
    children:[
      {    
        path: 'orderMealList', 
        name: 'orderMealList', 
        meta: { title: '点单' }, 
        component: () => import(/* webpackChunkName: "orderMealList" */ '@/views/Order/orderMeal/orderMealList.vue'),
        beforeEnter: (to, from, next) => {
          // 预加载关键组件
          import(/* webpackPrefetch: true */ '@/components/order/productList.vue')
          import(/* webpackPrefetch: true */ '@/components/order/orderMealNav.vue')
          next()
        }
      },
      {    
        path: 'oldShoppingCart', 
        name: 'oldShoppingCart', 
        meta: { title: '购物车' }, 
        component: () => import(/* webpackChunkName: "oldShoppingCart" */ '@/views/Order/orderMeal/shoppingCart.vue'),
      },
      {    
        path: 'shoppingCart', 
        name: 'shoppingCart', 
        meta: { title: '购物车' }, 
        component: () => import(/* webpackChunkName: "shoppingCart" */ '@/views/Order/orderMeal/newShoppingCart.vue'),
      },
      {    
        path: 'oldMyOrder', 
        name: 'oldMyOrder', 
        meta: { title: '我的点单' }, 
        component: () => import(/* webpackChunkName: "oldMyOrder" */ '@/views/Order/orderMeal/myOrder.vue'),
      },
      {    
        path: 'myOrder', 
        name: 'myOrder', 
        meta: { title: '我的点单' }, 
        component: () => import(/* webpackChunkName: "myOrder" */ '@/views/Order/orderMeal/newMyOrder.vue'),
      },
      // 已选列表
      {    
        path: 'choosedList', 
        name: 'choosedList', 
        meta: { title: '已选列表' }, 
        component: () => import(/* webpackChunkName: "choosedList" */ '@/views/Order/orderMeal/choosedList.vue'),
      },
    ]
  },
]