import axios from "axios";
import router from "../router";
import { Message } from "element-ui";
import { sessionStorage, localStorage } from "../utils/common/storage";
import { projectName, projectConfig } from "@/utils/config/projectConfig.js";
import getTermType from "./addTermType";
import { canRequest } from "./intercept";
import Observer, { CODE_INVALID } from "../observer";
import store from '@/store'; // 导入你的Vuex store模块
// 创建axios实例
var instance = axios.create({ timeout: 1000 * 12 });
// 设置post请求头
instance.defaults.headers.post["Content-Type"] =
  "application/x-www-form-urlencoded";

/**
 * 请求拦截器
 */
instance.interceptors.request.use(
  function (config) {
    if(config.custom && config.custom.loading) {
      store.dispatch('setLoading', true); // 在请求开始时显示loading

    }
    if (!canRequest(config.url) && !config.url.includes("/oss/pt")) return;

    if (localStorage.getItem("tk")) {
      config.headers.common["tk"] = localStorage.getItem("tk");
    }
    if (localStorage.getItem("stk")) {
      config.headers.common["stk"] = localStorage.getItem("stk");
    }

    const termType = getTermType(config.url) || "";

    if (
      termType &&
      !config.url.startsWith(projectConfig[projectName]["onlineBase"])
    )
      config.headers.common["tt"] = termType.toString();

    return config;
  },
  function (error) {
    store.dispatch('setLoading', false); // 在请求错误时隐藏loading
    if (localStorage.getItem("super") == "true") {
      router.push({ path: "/admin" });
    } else {
      router.push({ path: "/" });
    }
    return Promise.error(error);
  }
);

// 响应拦截器
instance.interceptors.response.use(
  (res) => {
    store.dispatch('setLoading', false); // 在接收到响应时隐藏loading
    if (res.data.code == 12 || res.data.code == 11) {
      if (localStorage.getItem("super") == "true") {
        router.push({ path: "/admin" });
      } else {
        router.push({ path: "/" });
      }
      localStorage.removeItem("tk");
      Observer.send(CODE_INVALID);
    } else if (res.data.code == 15 || res.data.code == 14) {
      if (localStorage.getItem("super") == "true") {
        router.push({ path: "/admin" });
      } else {
        router.push({ path: "/" });
      }
      localStorage.removeItem("stk");
    }

    // // 下载excel模板
    // if (res.config.url.endsWith('/mat/tpl') || res.config.url.endsWith('/mat/imp_with_prd_tpl') || res.config.url.endsWith('/prd/tpl') || res.config.url.endsWith('/emp/tpl')) {
    //   res.data.fileName = res.headers['content-disposition'].split('=')[1]
    // }

    return res;
  },
  (error) => {
    store.dispatch('setLoading', false); // 在响应错误时隐藏loading
    console.log("requestErr", error);
    console.log("errorMessage", error.message);
    if (!error.message.includes("(reading 'cancelToken')"))
      Message({
        message: "服务器响应失败",
        type: "error",
      });

    return Promise.reject(error);
  }
);

export default instance;
