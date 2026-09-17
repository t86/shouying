import Vue from "vue";
import App from "./App.vue";
import ElementUI from "element-ui";
import "element-ui/lib/theme-chalk/index.css";
import "./style/common/elementDateTimePicker.less";
import "./style/common/elementDialog.less"; // 全局弹窗布局修复样式

import { projectName } from "./utils/config/projectConfig";
import VConsole from "vconsole";
import { globalError } from "./utils/globalError";
// if(projectName !== 'store') new VConsole();
import './style/autocomplete.less' // 导入 CSS 文件
import "./style/base.less";
import "./style/flex.less";
import './assets/css/main.css';

import { sessionStorage, localStorage } from "./utils/common/storage";
import WebSocketClient from "./websocket/websocket";
import Observer from "./observer";
import disableClick from './directives/v-disable-click';

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
import { debounce } from 'lodash'

// 添加防抖指令
Vue.directive('debounce', {
  bind: (el, binding) => {
    console.log('bind', el)
    let debounceTime = binding.value || 300;
    if (typeof binding.value === 'object') {
      debounceTime = binding.value.time || 300;
    }
    let fn = null;
    if (el.tagName.toLowerCase() === 'input') {
      // 如果是输入框，对input事件进行防抖
      fn = debounce((e) => {
        el.dispatchEvent(new Event('change'));
      }, debounceTime);
      el.addEventListener('input', fn);
    } else {
      // 如果是其他元素，对click事件进行防抖
      fn = debounce((e) => {
        // 如果绑定了具体的函数，则调用该函数
        if (typeof binding.value === 'object' && binding.value.fn) {
          binding.value.fn(e);
        } else {
          // 否则触发click事件
          el.click();
        }
      }, debounceTime);
      el.addEventListener('click', fn);
    }
  }
});

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

Vue.directive('disable-click', disableClick);

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

// 初始化性能监控
if (window.performance && window.performance.mark) {
  window.performance.mark('app-init');
}

router.beforeEach((to, from, next) => {
  // store.dispatch('setLoading', true); 
  const authId = store.state.userInfo.emp_id;
  /* 路由发生变化修改页面title */
  document.title = to.meta.title ? to.meta.title : "";
  // 获取门店开店状态
  if (
    (to.name === "orderCard" ||
      to.name == "cardMachine" ||
      to.name == "bigscreen" ||
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
  // store.dispatch('setLoading', false); // 结束加载，设置 loading 为 false
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
  // 开发编译会更新版本号，热更新时应保留设备授权和登录信息。
  if (process.env.NODE_ENV !== 'development') {
    localStorage.clear();
  }
  localStorage.setItem("projectVersion", version);
}

Vue.prototype.$websocket = new WebSocketClient(
  new Vue({
    router,
    store,
    render: (h) => h(App),
  }).$mount("#app")
);

if (process.env.NODE_ENV === 'development') {
  new VConsole();
}

// 在 Vue 实例创建之前添加全局性能监控
if (process.env.NODE_ENV === 'development') {
  window.addEventListener('load', () => {
    console.log(`[${new Date().toISOString()}] 页面完全加载完成`);
    
    // 输出关键性能指标
    const timing = performance.timing;
    const perfData = {
      dns: timing.domainLookupEnd - timing.domainLookupStart,
      tcp: timing.connectEnd - timing.connectStart,
      request: timing.responseEnd - timing.requestStart,
      domParse: timing.domComplete - timing.domLoading,
      domReady: timing.domContentLoadedEventEnd - timing.navigationStart,
      load: timing.loadEventEnd - timing.navigationStart,
    };
    
    console.log(`[${new Date().toISOString()}] 页面加载性能指标:`, perfData);
  });
}


