import Vue from "vue";
import Vuex from "vuex";
import { Message } from "element-ui";
import api_order from "@/api/order";
import api_book from "@/api/Book";
import { sessionStorage, localStorage } from "@/utils/common/storage";

Vue.use(Vuex);

export default new Vuex.Store({
  state: {
    name: localStorage.getItem("name") || "",
    client: sessionStorage.getItem("client"), // 区分系统名称
    userInfo: sessionStorage.getItem("userInfo")
      ? JSON.parse(sessionStorage.getItem("userInfo"))
      : {},
    // 酒吧订台页面相关数据
    cardPageInfo: {
      storeStatusId: sessionStorage.getItem("storeStatusId") || false, // 门店是否开启营业日
      resResultDataObj: sessionStorage.getItem("resResultDataObj")
        ? JSON.parse(sessionStorage.getItem("resResultDataObj"))
        : {}, // 页面所有请求到后转化过的数据
      tabList: sessionStorage.getItem("tabList")
        ? JSON.parse(sessionStorage.getItem("tabList"))
        : [], // 区域列表
      cardList: sessionStorage.getItem("cardList")
        ? JSON.parse(sessionStorage.getItem("cardList"))
        : [], // 卡台列表
      newCardInfo: {}, // 转台选择的新卡台的相关信息
    },
    // 点单
    orderInfo: {
      // 当前正在点单的卡台信息
      currentCardInfo: sessionStorage.getItem("currentCardInfo")
        ? JSON.parse(sessionStorage.getItem("currentCardInfo"))
        : {},
      saveWineCardInfo: sessionStorage.getItem("saveWineCardInfo")
        ? JSON.parse(sessionStorage.getItem("saveWineCardInfo"))
        : {},
      productAll: sessionStorage.getItem("productAll")
        ? JSON.parse(sessionStorage.getItem("productAll"))
        : [], // 所有可点商品列表
      allProductsList: sessionStorage.getItem("allProductsList")
        ? JSON.parse(sessionStorage.getItem("allProductsList"))
        : [], // 所有有效商品
      shoppingCartInfo: {
        shoppingCount: 0,
      },
    },
    // 请求相关信息
    requestInfo: {},
  },
  mutations: {
    gaibian(state, value) {
      state.name = value;
      localStorage.setItem("name", state.name);
    },

    updateRequestInfo(state, value) {
      state.requestInfo = { ...value };
    },

    updateClient(state, value) {
      sessionStorage.setItem("client", value);
      state.client = value;
    },

    updateStoreStatusId(state, value = 0) {
      sessionStorage.setItem("storeStatusId", value.toString());
      state.cardPageInfo.storeStatusId = value;
    },
    updateUserInfo(state, info = {}) {
      if(info && info.station_id){
      const station_id = info.station_id * 1;
      //  根据岗位id匹配权限信息
      const sysRole = state.cardPageInfo.resResultDataObj['sysRole'] ||[];
      const sysRoleDetail = state.cardPageInfo.resResultDataObj['sysRoleDetail'] ||[];
      // 获取角色ids
      const roles = sysRole.filter(item => item.station_id == station_id && item.status == 1);
      const roleIds = [...new Set(roles.map(d=>d.sys_role_id * 1))];
      // 获取岗位对应的权限
      const sys_modules = sysRoleDetail.filter(item => item.station_id == station_id && item.status == 1);
      // 获取权限id
      const sys_module_ids = [...new Set(sys_modules.map(d=> d.sys_module_id * 1))];
      // 当前用户的upper_emp_id 从元数据里边获取
      const orderPersonInfo = state.cardPageInfo.resResultDataObj['orderPersonInfo'] ||[];
      const loginUser =  orderPersonInfo.find(
          (item) => item.id == info.emp_id
        );
      info["upper_emp_id"] = loginUser? loginUser.upper_emp_id : '';
      info['clone_emp_id'] = loginUser? loginUser.clone_emp_id : '';
      info["roleIds"] = roleIds;
      info['sys_modules']=sys_module_ids;
     }
      sessionStorage.setItem("userInfo", JSON.stringify(info));
      state.userInfo = info;
    },
    updateResResultDataObj(state, value) {
      sessionStorage.setItem("resResultDataObj", JSON.stringify(value));
      state.cardPageInfo.resResultDataObj = value;
      if (!value) return;
      // 获取最新当前点单卡台信息(点单后更新已消费金额)
      const currentCardId = state.orderInfo.currentCardInfo.seatId;
      if (currentCardId) {
        const updatedCardInfo = value.businessData.find(
          (el) => el.seatId == currentCardId
        );
        for (let key in updatedCardInfo) {
          // 更新当前卡台最新数据
          state.orderInfo.currentCardInfo[key] =
            updatedCardInfo[key] || state.orderInfo.currentCardInfo[key];
        }
        sessionStorage.setItem(
          "currentCardInfo",
          JSON.stringify(state.orderInfo.currentCardInfo)
        );
      }
    },
    updateTabList(state, value) {
      sessionStorage.setItem("tabList", JSON.stringify(value));
      state.cardPageInfo.tabList = value;
    },
    updateCardList(state, value) {
      sessionStorage.setItem("cardList", JSON.stringify(value));
      state.cardPageInfo.cardList = value;
    },
    updateNewCardInfo(state, value) {
      state.cardPageInfo.newCardInfo = value;
    },

    // 更新点单信息
    updateOrderInfo(state, { key, value }) {
      sessionStorage.setItem(key, JSON.stringify(value));
      state.orderInfo[key] = value;
    },

    updateMoneyCardNeedBackOrderCount(state, count) {
      state.cardPageInfo.resResultDataObj.needBackOrderListCount[0]["cnt"] =
        count;
      sessionStorage.setItem(
        "resResultDataObj",
        JSON.stringify(state.cardPageInfo.resResultDataObj)
      );
    },
  },
  actions: {
    // 获取购物车商品数目总条数
    async getShoppingCount(context, that) {
      try {
        const params = {
          id: context.state.orderInfo.currentCardInfo.seatId * 1, // int64 卡台Id
        };
        const res = await api_order.reqGetShoppingCount(params);
        res.code === 1
          ? (context.state.orderInfo.shoppingCartInfo.shoppingCount =
              res.data || 0)
          : that.$message.warning(res.msg);
      } catch (error) {
        console.log("购物车列表数量获取失败", error);
      }
    },

    // 获取门店开台开业情况
    async getStoreOpenStatus(context, next) {
      try {
        const res = await api_book.reqGetOpenStatus();
        if (res.code === 1) {
          context.commit("updateStoreStatusId", res.data);
          next();
        } else {
          Message({
            message: "门店开业情况" + res.msg,
            type: "warning",
          });
        }
      } catch (error) {
        console.log("获取营业信息失败", error);
      }
    },
 
  },
  getters: {
    vipAuth(state) {
      // 如果是vip系统登录  则没有操作数据权限
      // 此处返回true表示有操作权限
      return state.client != "vip";
    },
  },
  modules: {},
});
