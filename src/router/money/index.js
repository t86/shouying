export default [
  // 点单首页列表
  {
    path: '/moneyCard', name: 'moneyCard', meta: { title: '卡台信息' }, component: () => import('@/views/Money/moneyCard.vue'),
  },
  {
    path: '/payOrder', name: 'payOrder', meta: { title: '订单' }, component: () => import('@/views/Money/payOrder.vue'),
  },
]