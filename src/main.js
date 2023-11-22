import Vue from "vue";
import App from "./App.vue";
import ElementUI from "element-ui";
import "element-ui/lib/theme-chalk/index.css";
import "./style/common/elementDateTimePicker.less";

import { projectName } from "./utils/config/projectConfig";
import VConsole from "vconsole";
import { globalError } from "./utils/globalError";
// if(projectName !== 'store') new VConsole();
import './style/autocomplete.less' // 导入 CSS 文件
import "./style/base.less";
import "./style/flex.less";

import { sessionStorage, localStorage } from "./utils/common/storage";
import WebSocketClient from "./websocket/websocket";
import Observer from "./observer";

Vue.prototype.$observer = Observer;
Vue.prototype.$sessionStorage = sessionStorage;
Vue.prototype.$localStorage = localStorage;
Vue.prototype.$globalError = globalError;
import less from "less";
Vue.use(less);

import router from "./router"; // 导入路由文件
import store from "./store"; // 导入vuex文件
import api from "./api"; // 导入api接口

import overall from "./utils/overallMethod"; // 导入全局方法
import tool from "./utils/tool"; // 导入全局方法

// bms
import areaMenu from "@/components/bms/cardConfig/areaNav/areaNav.vue";
Vue.component("areaMenu", areaMenu);

import wineMenu from "@/components/bms/wineInfo/wineNav/wineNav.vue";
Vue.component("wineMenu", wineMenu);

import requireMenu from "@/components/bms/requireConfig/requireMenu.vue";
Vue.component("requireMenu", requireMenu);

import secondBmsMenu from "@/components/bms/secondBmsMenu/secondMenu.vue";
Vue.component("secondBmsMenu", secondBmsMenu);

import secondEmployeeListNavBarItem from "@/components/bms/secondEmployeeListNavBarItem/secondEmployeeListNavBarItem.vue";
Vue.component("secondEmployeeListNavBarItem", secondEmployeeListNavBarItem);

import treeCom from "@/components/bms/reportConfig/treeCom/treeCom.vue";
Vue.component("treeCom", treeCom);

// erp
import secondMenu from "@/components/erp/mats/secondMenu/secondMenu.vue";
Vue.component("secondMenu", secondMenu);

Vue.prototype.$overall = overall;
Vue.prototype.$tool = tool;
Vue.prototype.$api = api;
Vue.use(ElementUI);
Vue.config.productionTip = false;

import VueClipboard from "vue-clipboard2";
Vue.use(VueClipboard);


Vue.config.errorHandler = function (err, vm, info) {
  console.error(err);
  globalError.handleError(err);
}


router.beforeEach((to, from, next) => {
  store.dispatch('setLoading', true); 
  const authId = store.state.userInfo.emp_id;
  /* 路由发生变化修改页面title */
  document.title = to.meta.title ? to.meta.title : "";
  // 获取门店开店状态
  if (
    (to.name === "orderCard" ||
      to.name == "cardMachine" ||
      to.name == "moneyCard") &&
    authId
  ) {
    return store.dispatch("getStoreOpenStatus", next);
  }
  const name = "Thelogin";
  switch (to.path) {
    case "/":
      next({
        name,
      });
      return;
    case "/register":
    case "/notFound":
      next();
      return;
    case "/admin":
      next({
        name: "appinfo",
      });
      return;
    default:
      // 是否登录
      if (to.name === name || to.name === "appinfo") return next();
      authId ? next() : next({ name: "home" });
  }
});

// 全局后置钩子
router.afterEach(() => {
  store.dispatch('setLoading', false); // 结束加载，设置 loading 为 false
});

// import Print from './plugins/print/Print'
// Vue.use(Print)
import Print from "vue-print-nb";
Vue.use(Print);

// console.log(new RegExp('(?<=version\\":\\s*\\")(.*)(?=")') );
import packageJson from "../package.json";

// console.log(packageJson.version);
const version = packageJson.version;
const localVersion = localStorage.getItem("projectVersion");
if (!localVersion || version !== localVersion) {
  localStorage.clear();
  localStorage.setItem("projectVersion", version);
}

Vue.prototype.$websocket = new WebSocketClient(
  new Vue({
    router,
    store,
    render: (h) => h(App),
  }).$mount("#app")
);
