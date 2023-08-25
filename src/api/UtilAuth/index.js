/**
 * 常用工具 登录  终端设备授权
**/
// this.$api.UA.term
import util from "./util"                // util         常用工具 中文转换为拼音
import auth from "./auth"                // auth         认证登录
import appinfo from "./appinfo"          // appinfo      超级管理员登录
import term from "./term"                // term         终端设备授权

export default {
    util,
    auth,
    appinfo,
    term
};