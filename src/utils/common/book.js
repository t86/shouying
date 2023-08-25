import store from "../../store"
export default {
  // 通过区域id或卡台id获取区域名称
  getOrgionInfo(orgionId, sateId) {
    if (orgionId === 0) {
      if (sateId === 0) { return { name: '全部' } }
      else {
        const cardInfo = this.getCardInfo(sateId)
        return this.getOrgionInfo(cardInfo.regionId, 0)
      }
    } else {
      return store.state.cardPageInfo.resResultDataObj.areaInfo.find(el => el.id == orgionId)
    }
  },

  // 根据卡台id获取卡台信息
  getCardInfo(sateId) {
    if (sateId === 0) return { name: '全部' }
    return store.state.cardPageInfo.resResultDataObj.cardInfo.find(el => el.id == sateId)
  },

  // 根据员工id获取员工信息
  getOrderPersonInfo(orderPersonId) {
    return store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(el => el.id == orderPersonId)
  },

  // 根据订位人（员工）id获取部门名称
  getDepartmentName(orderPersonId) {
    const sealPersonInfo = store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(el => el.id == orderPersonId)
    if (sealPersonInfo) { // 非散客（有定位人）
      const result = store.state.cardPageInfo.resResultDataObj.departmentInfo.find(el => el.id == sealPersonInfo.deptId)
      return (result && result.name) || ''
    } else { // 散客
      return ''
    }
  },

  // 通过一级分类id获取对应一级分类信息
  getFirstCategoryInfo(firstCategoryId){
    const firstCategoryArr = store.state.cardPageInfo.resResultDataObj['firstCategoryInfo'];
    return firstCategoryArr.find(item => item.id == firstCategoryId)
  }

}