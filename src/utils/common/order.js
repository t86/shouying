import store from '@/store'
import { authTypeListAll } from '@/utils/config/card'
export default {
  // 通过商品id获取商品信息
  getProductInfo(productId) {
    const allProductsList = store.state.cardPageInfo.resResultDataObj["goodsAroundInfo"];
    const navAllProductList = store.state.orderInfo.productAll ? [...store.state.orderInfo.productAll] : []
    const addAttrAllPrdList = allProductsList.map(item => {
      const find = navAllProductList.find(items => items.id == item.id)
      return find ? {
        ...item,
        canOrderMeal: find.canOrderMeal,
        canSeal: find.canSeal,
        canHL: find.canHL
      } : {...item}
    })
    return addAttrAllPrdList.find(el => el.id == productId)
  },


  // 通过商品id匹配套餐中的商品信息
  getProductInfoFromGroup(productId) {
    return store.state.cardPageInfo.resResultDataObj.goodsAroundInfo.find(
      el => el.id == productId
    );
  },


  // 通过岗位id和二级分类id获取当前二级分类的authType（用于赠送显示经营赠送、内招、外招）
  getAuthTypeList(twoCateId) {
    const authStationId = store.state.userInfo.station_id;
    const authTypeListTemp = store.state.cardPageInfo.resResultDataObj[
      "jobSecondLimitInfo"
    ]
      .filter(
        el =>
          el.status == 1 &&
          el.stationId == authStationId &&
          (el.authType == 2 || el.authType == 3 || el.authType == 5) &&
          el.twoCateId == twoCateId
      )
      .map(el => el.authType);

    const authTypeList = []
    authTypeListTemp.forEach(el => {
      authTypeList.push(authTypeListAll.find(ele => el == ele.id))
    })
    return authTypeList
  },

  getTaocanPrdInfo(tplId) {
    return store.state.cardPageInfo.resResultDataObj.taocanTemplate.filter(item => item.tpl_id == tplId) || []
  },

  // 通过二级菜单id匹配对应的要求类型及明细
  getRequireInfo(secondCategoryId) {
    const requireInfo = store.state.cardPageInfo.resResultDataObj.secondCategoryRequireConfig.filter(item => item.two_cate_id == secondCategoryId)
    const resultRequireArr = []
    
    requireInfo.forEach(el => {
      const findInfoArr = store.state.cardPageInfo.resResultDataObj.requireType.filter(item => item.id == el.rqm_type_id)
      if (findInfoArr.length > 0) resultRequireArr.push(...findInfoArr)
    })

    resultRequireArr.forEach(el => {
      el.requireList = store.state.cardPageInfo.resResultDataObj.requireItem.filter(item => item.typeId == el.id)
    })
    return resultRequireArr
  },

  // 通过商品id获取商品一二级分类
  getPrdCategoryInfo(firstCateId, secondCateId) {
    const firstCategoryInfo = store.state.cardPageInfo.resResultDataObj.firstCategoryInfo.filter(item => item.status == 1).find(item => item.id == firstCateId) || {}
    const secondCategoryInfo = store.state.cardPageInfo.resResultDataObj.secondCategoryInfo.filter(item => item.status == 1).find(item => item.id == secondCateId) || {}
    return {
      firstCategoryInfo,
      secondCategoryInfo
    }
  }

}