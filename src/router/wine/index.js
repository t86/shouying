export default [
  {
    path: '/wine/saveNeedToLib', name: "saveNeedToLib", meta: { title: '存酒待入库' },
    component: () => import('@/views/ManagementSystem/wine/saveNeedToLib/saveNeedToLib.vue')
  },
  {
    path: '/wine/getNeedToLib', name: "getNeedToLib", meta: { title: '取酒待入库' },
    component: () => import('@/views/ManagementSystem/wine/getNeedToLib/getNeedToLib.vue')
  },
  {
    path: '/wine/saveLib', name: "saveLib", meta: { title: '存酒库' },
    component: () => import('@/views/ManagementSystem/wine/saveLib/saveLib.vue')
  },
  {
    path: '/wine/saveLibChild', name: "saveLibChild", meta: { title: '存酒库子订单' },
    component: () => import('@/views/ManagementSystem/wine/saveLibChild/saveLibChild.vue')
  },
  {
    path: '/wine/passTime', name: "passTime", meta: { title: '过期待处理' },
    component: () => import('@/views/ManagementSystem/wine/passTime/passTime.vue')
  },
  {
    path: '/wine/saveLibAllData', name: "saveLibAllData", meta: { title: '存酒库库存' },
    component: () => import('@/views/ManagementSystem/wine/saveLibAllData/saveLibAllData.vue')
  },
  {
    path: '/wine/toStore', name: "toStore", meta: { title: '待充公' },
    component: () => import('@/views/ManagementSystem/wine/toStore/toStore.vue')
  },
  {
    path: '/wine/storeLib', name: "storeLib", meta: { title: '充公库' },
    component: () => import('@/views/ManagementSystem/wine/storeLib/storeLib.vue')
  },
  {
    path: '/wine/toStoreDetail', name: "toStoreDetail", meta: { title: '充公出库单' },
    component: () => import('@/views/ManagementSystem/wine/toStoreDetail/toStoreDetail.vue')
  },
  {
    path: '/wine/userConfig', name: "userConfig", meta: { title: '用户管理' },
    component: () => import('@/views/ManagementSystem/wine/userConfig/userConfig.vue')
  },
  // 客户中心存酒begin
  {
    path: '/wine/customSaveLib', name: "customSaveLib", meta: { title: '待入库' },
    component: () => import('@/views/ManagementSystem/wine/customSaveLib/customSaveLib.vue')
  },
  {
    path: '/wine/customGetLib', name: "customGetLib", meta: { title: '取酒' },
    component: () => import('@/views/ManagementSystem/wine/customGetLib/customGetLib.vue')
  },
  // 客户中心存酒end
  {
    path: '/wine/saveAndGetReport', name: "saveAndGetReport", meta: { title: '存取酒记录' },
    component: () => import('@/views/ManagementSystem/wine/saveAndGetReport/saveAndGetReport.vue')
  },
  {
    path: '/wine/passTimeLongReport', name: "passTimeLongReport", meta: { title: '延期记录' },
    component: () => import('@/views/ManagementSystem/wine/passTimeLongReport/passTimeLongReport.vue')
  },
  {
    path: '/wine/toStoreOutReport', name: "toStoreOutReport", meta: { title: '充公出库记录' },
    component: () => import('@/views/ManagementSystem/wine/toStoreOutReport/toStoreOutReport.vue')
  },
  {
    path: '/wine/saveAllDataReport', name: "saveAllDataReport", meta: { title: '入库统计' },
    component: () => import('@/views/ManagementSystem/wine/saveAllDataReport/saveAllDataReport.vue')
  },
  {
    path: '/wine/getAllDataReport', name: "getAllDataReport", meta: { title: '出库统计' },
    component: () => import('@/views/ManagementSystem/wine/getAllDataReport/getAllDataReport.vue')
  },
  {
    path: '/wine/toStoreAllDataReport', name: "toStoreAllDataReport", meta: { title: '充公统计' },
    component: () => import('@/views/ManagementSystem/wine/toStoreAllDataReport/toStoreAllDataReport.vue')
  },
  {
    path: '/wine/saveWineSearch', name: "saveWineSearch", meta: { title: '存酒查询' },
    component: () => import('@/views/ManagementSystem/wine/saveWineSearch/saveWineSearch.vue')
  },
  {
    path: '/wine/nowInvtReport', name: "nowInvtReport", meta: { title: '日实时库存' },
    component: () => import('@/views/ManagementSystem/wine/nowInvtReport/nowInvtReport.vue')
  },
  // 存酒借还begin
  {
    path: '/wine/borrowWine', name: "borrowWine", meta: { title: '借酒' },
    component: () => import('@/views/ManagementSystem/wine/borrowWine/borrowWine.vue')
  },
  {
    path: '/wine/returnWine', name: "returnWine", meta: { title: '还酒' },
    component: () => import('@/views/ManagementSystem/wine/returnWine/returnWine.vue')
  },
  {
    path: '/wine/unreturnedWine', name: "unreturnedWine", meta: { title: '未还酒水' },
    component: () => import('@/views/ManagementSystem/wine/unreturnedWine/unreturnedWine.vue')
  }
  // 存酒借还end
]