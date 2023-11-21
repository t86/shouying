export default [
  // 点单首页列表
  {
    path: '/orderCard', name: 'orderCard', meta: { title: '卡台信息' }, component: () => import('@/views/Order/orderCard.vue'),
  },
  // 点单页面
  {
    path: '/orderMeal', name: 'orderMeal', meta: { title: '' }, component: () => import('@/views/Order/orderMeal/index.vue'),
    redirect: "/orderMeal/orderMealList",
    children:[
      {    
        path: 'orderMealList', name: 'orderMealList', meta: { title: '点单' }, component: () => import('@/views/Order/orderMeal/orderMealList.vue'),
      },
      {    
        path: 'shoppingCart', name: 'shoppingCart', meta: { title: '购物车' }, component: () => import('@/views/Order/orderMeal/shoppingCart.vue'),
      },
      {    
        path: 'newShoppingCart', name: 'newShoppingCart', meta: { title: '购物车' }, component: () => import('@/views/Order/orderMeal/newShoppingCart.vue'),
      },
      {    
        path: 'myOrder', name: 'myOrder', meta: { title: '我的点单' }, component: () => import('@/views/Order/orderMeal/myOrder.vue'),
      },
      {    
        path: 'newMyOrder', name: 'newMyOrder', meta: { title: '我的点单' }, component: () => import('@/views/Order/orderMeal/newMyOrder.vue'),
      },
      // 已选列表
      {    
        path: 'choosedList', name: 'choosedList', meta: { title: '已选列表' }, component: () => import('@/views/Order/orderMeal/choosedList.vue'),
      },
    ]
  },
]