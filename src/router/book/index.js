export default [
  // 卡台首页列表(订台)
  {
    path: '/cardMachine', name: 'cardMachine', meta: { title: '卡台信息' }, component: () => import('@/views/Book/cardMachine.vue'),
  },
  // 预留
  {
    path: '/reserved', name: 'reserved', meta: { title: '预留信息' }, component: () => import('@/views/Book/reserved.vue'),
  },
]