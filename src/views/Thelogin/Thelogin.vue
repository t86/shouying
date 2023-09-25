<template>
  <div class="Thelogin">
    <div class="terminal-type">
      <div class="exit" @click="exit" v-if="!isWeb">
        <img
          :src="require('@/assets/card-imgs/exit.png')"
          alt
          style="width: 18px; height: 18px; margin-right: 4px"
        />
        <span>退出</span>
      </div>
      <div class="clear-cache" @click="clear">
        <img
          :src="require('@/assets/register-login/qinglihuancun.png')"
          alt
          style="width: 18px; height: 18px; margin-right: 4px"
        />
        <span>重新加载</span>
      </div>
      <div
        class="change-position"
        @click="changePosition"
        v-if="isAndroidTerminal"
      >
        <img
          style="width: 18px; height: 18px; margin-right: 4px"
          :src="require('@/assets/register-login/qiehuan.png')"
          alt
        />
        <span>切换屏幕</span>
      </div>
      <div class="terminal-type-name">
        <div>{{ typeName }}</div>
        <div class="app-version">版本号：{{ version }}</div>
      </div>
    </div>
    <div class="peak">
      <div class="left">
        <img
          :src="require('@/assets/register-login/shangdaohang_zuo.png')"
          alt=""
        />
      </div>
      <div class="center">
        <img
          :src="require('@/assets/register-login/shangdaohang_denglu.png')"
          alt=""
        />
      </div>
      <div class="right">
        <img
          :src="require('@/assets/register-login/shangdaohang_you.png')"
          alt=""
        />
      </div>
    </div>
    <div class="elasticity">
      <div class="center-type" layout="row" layout-align="center center">
        <div class="slideshow">
          <el-carousel
            style="width: 100%"
            :height="[isAndroidTerminal ? '400px' : '500px']"
          >
            <el-carousel-item v-for="item in 3" :key="item">
              <img
                src="@/assets/img/banner.png"
                style="width: 100%; height: 100%; object-fit: contain"
                alt
              />
            </el-carousel-item>
          </el-carousel>
        </div>
        <div class="keyboard-contain">
          <div class="OpenKeyboard" :class="{ android: isAndroidTerminal }">
            <div class="Keyboards">
              <div class="staff">
                <span>员工号登录</span>
                <img src="@/assets/img/b14.png" alt />
              </div>
              <div class="middle">
                <div
                  class="AccountNumber"
                  :class="{ aer: pitchon == 1 }"
                  @click="pitchon = 1"
                >
                  <img src="@/assets/img/b15.png" alt />
                  <el-input
                    placeholder="请输入员工工号"
                    v-model="account"
                  ></el-input>
                </div>
                <div
                  class="AccountNumber"
                  :class="{ aer: pitchon == 2 }"
                  @click="pitchon = 2"
                >
                  <img src="@/assets/img/b11.png" alt />
                  <el-input
                    show-password
                    placeholder="请输入密码"
                    v-model="password"
                  ></el-input>
                </div>
                <div class="keyboard">
                  <div class="table">
                    <div class="tbody">
                      <div class="tr" layout="row" layout-align="start start">
                        <div
                          class="td"
                          v-for="(eachof, index) in numList"
                          :key="index"
                          :class="{ pressdown: eachof.num == pressdowns }"
                          @mousedown="pressdowns = eachof.num"
                          @mouseup="pressdowns = Number"
                          @click="select(eachof.num)"
                        >
                          <img
                            src="@/assets/img/b13.png"
                            v-if="eachof.num == 100"
                            alt
                          />
                          <img
                            src="@/assets/img/b10.png"
                            v-if="eachof.num == 101"
                            alt
                          />
                          <img
                            src="@/assets/img/b12.png"
                            v-if="eachof.num == 102"
                            alt
                          />
                          <div>{{ eachof.title }}</div>
                        </div>
                        <div
                          class="td"
                          rowspan="2"
                          @mousedown="gaibtup = true"
                          @mouseup="gaibtup = false"
                          @click="submit"
                        >
                          <img :src="require('@/assets/img/b16.png')" alt />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <el-dialog
      title="温馨提示"
      :visible.sync="showWarning"
      :show-close="false"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
    >
      <p
        style="
          color: #fff;
          margin-bottom: 50px;
          padding: 0 20px;
          line-height: 30px;
        "
        v-html="warningText"
      ></p>
      <div class="login-choose-btn">
        <button
          class="ok"
          @click="routerGo({ authStatus: 4, authName: '收银人' })"
        >
          确定
        </button>
      </div>
    </el-dialog>
  </div>
</template>
<script>
import b3 from "@/assets/img/b3.png";
import b17 from "@/assets/img/b17.png";
import { mapActions, mapState, mapMutations } from "vuex";
import md5 from "js-md5";
import { projectConfig, projectName } from "@/utils/config/projectConfig";
import swipingCard from "@/mixin/swipingCard";
import errApi from "@/api/reportErr";

const clientInfo = {
  1: "org_mgr",
  2: "book",
  4: "order",
  8: "money",
  16: "vip",
  32: "erp",
  64: "erpAdmin",
  256: "wine",
};
export default {
  data() {
    return {
      typeName: "", // 设备名称
      wa: [b3, b17], //图片控制
      controller: true, //图片控制器
      account: projectConfig[projectName]["username"], //账号
      password: projectConfig[projectName]["password"], //密码
      clientName: "", // 系统名称

      dialogTableVisible: false, // 选择身份的弹框显示隐藏
      sysPrivList: [], // 当前登录账号的身份集合
      authRadio: 0, // 默认身份选中项

      pitchon: 1, //选中账号还是密码状态
      numList: [
        {
          title: "1",
          num: 1,
        },
        {
          title: "2",
          num: 2,
        },
        {
          title: "3",
          num: 3,
        },
        {
          title: "4",
          num: 4,
        },
        {
          title: "5",
          num: 5,
        },
        {
          title: "6",
          num: 6,
        },
        {
          title: "7",
          num: 7,
        },
        {
          title: "8",
          num: 8,
        },
        {
          title: "9",
          num: 9,
        },
        {
          title: "清空",
          num: 100,
        },
        {
          title: "0",
          num: 0,
        },
        {
          title: "回退",
          num: 101,
        },
        {
          title: "切换输入框",
          num: 102,
        },
      ],
      pressdowns: Number, //点了哪一个键盘数字
      gaibtup: false, //登录图片控制器

      // 路由跳转控制
      clients: [
        {
          name: "org_mgr",
          systemName: "门店管理后台",
          url: "/BMS/genRule",
        },
        {
          name: "erp",
          systemName: "ERP仓库管理员",
          url: "/ERP/sin",
        },
        {
          name: "erpAdmin",
          systemName: "ERP管理员",
          url: "/ERP/home",
        },
        {
          name: "book",
          systemName: "预定系统",
          url: "/cardMachine",
        },
        {
          name: "order",
          systemName: "点单系统",
          url: "/orderCard",
        },
        {
          name: "money",
          systemName: "收银系统",
          url: "/moneyCard",
        },
        {
          name: "vip",
          systemName: "会员系统",
          url: "/vipManager",
        },
        {
          name: "wine",
          systemName: "存酒仓库",
          url: "/wine/saveNeedToLib",
        },
      ],

      showWarning: false,
      warningText: "",
    };
  },
  methods: {
    // 设备终端授权
    async term() {
      let code = "";
      try {
        code = atool.getMachineCode();
        console.log("设备注册码:" + code);
      } catch (error) {
        code = this.$route.query.code;
        if (!code) return this.$router.replace("/register");
      }

      try {
        const res = await this.$api.UtilAuth.term.termauth({ code });
        if (res.code == 1) {
          // this.$store.commit('updateResResultDataObj', '')
          this.typeName = res.data.n;
          this.$localStorage.setItem("tk", res.data.tk);
          this.$localStorage.setItem("am", res.data.am.toString());
          this.$localStorage.setItem("machineId", res.data.id.toString());
          this.clientName = clientInfo[res.data.am.toString()];
          this.$store.commit("updateClient", this.clientName);
        } else {
          this.$message.warning(res.msg);
          this.$router.replace("/register");
        }
      } catch (error) {
        console.log("设备授权失败", error);
      }
    },
    // 点击输入数字
    select(i) {
      if (i <= 101) {
        var value = "";
        if (this.pitchon == 1) {
          value = this.account;
        } else if (this.pitchon == 2) {
          value = this.password;
        }
        switch (i) {
          case 101:
            value = value.substring(0, value.length - 1);
            break;
          case 100:
            value = "";
            break;
          case 0:
            value = value + "0";
            break;
          case 1:
            value = value + "1";
            break;
          case 2:
            value = value + "2";
            break;
          case 3:
            value = value + "3";
            break;
          case 4:
            value = value + "4";
            break;
          case 5:
            value = value + "5";
            break;
          case 6:
            value = value + "6";
            break;
          case 7:
            value = value + "7";
            break;
          case 8:
            value = value + "8";
            break;
          case 9:
            value = value + "9";
            break;
        }
        if (this.pitchon == 1) {
          this.account = value;
        } else if (this.pitchon == 2) {
          this.password = value;
        }
      } else if (i == 102) {
        this.pitchon = this.pitchon == 1 ? 2 : 1;
      }
    },

    routerGo(currentStatusObj = {}) {
      this.$store.commit("updateUserInfo", {
        ...this.originInfo,
        ...currentStatusObj,
      });
      this.$router.push({ path: this.url });
    },
    exit() {
      try {
        atool.exit();
      } catch (e) {}
    },
    clear() {
      try {
        // 发送错误日志到服务器
        errApi.reqSendErrMsg({
          sync: true,
          cardList: JSON.parse(localStorage.getItem("cardList")).map((item) => {
            return {
              orderAmt: item.orderAmt,
              id: item.seatId,
              name: item.name,
            };
          }),
          businessData: JSON.parse(localStorage.getItem("resResultDataObj"))[
            "businessData"
          ].map((item) => {
            return {
              orderAmt: item.orderAmt,
              id: item.seatId,
            };
          }),
          refreshAllLocalTime: localStorage.getItem("refreshAllLocalTime"),
          refreshAllTime: localStorage.getItem("refreshAllTime"),
          userInfo: localStorage.getItem("userInfo"),
          client: localStorage.getItem("client"),
          projectVersion: localStorage.getItem("projectVersion"),
          refreshAll: localStorage.getItem("refreshAll"),
        });
      } catch (e) {}

      let version = localStorage.getItem("projectVersion");
      sessionStorage.clear();
      localStorage.clear();
      localStorage.setItem("projectVersion", version);
      this.term();
      this.$websocket.reset();
      this.$message({
        message: "重新加载成功",
        type: "info",
      });
      window.location.reload();

    },
    changePosition() {
      if (window.atool && "changePosition" in window.atool) {
        window.atool.changePosition();
      } else {
        this.$message.warning("当前版本还不支持, 请联系系统运维人员升级版本");
      }
    },
    // 登录
    submit(userName = "", passWord = "", type = 1) {
      // 验证类型type 1:账号 2： 卡
      const account = type == 1 ? this.account : userName;
      const password = type == 1 ? this.password : passWord;
      if (type == 1 && (this.account == "" || this.password == "")) {
        this.$message.warning("账号或密码不能为空");
      } else {
        this.$api.UtilAuth.auth
          .requestauthlogin({
            code: account,
            passwd: md5(password).toString().toUpperCase(),
            client_name: this.clientName,
            pt: type,
          })
          .then(async (res) => {
            if (res.code == 1) {
              res.data.sys_priv = res.data.sys_priv
                ? res.data.sys_priv.toString()
                : "";
              if (res.data.sys_priv) {
                var s = [];
                for (const i in this.clients) {
                  s[i] = this.clientName == this.clients[i].name;
                  if (this.clientName == this.clients[i].name) {
                    if (
                      ((this.$localStorage.getItem("am") * 1) &
                        (res.data.sys_priv * 1)) >
                      0
                    ) {
                      // 存储
                      this.$localStorage.setItem("priv", res.data.sys_priv);
                      this.$localStorage.setItem(
                        "station_id",
                        res.data.station_id.toString()
                      ); // 用户岗位id
                      this.$localStorage.setItem(
                        "navigation",
                        [0, 0, this.clients[i].url].join(",")
                      );
                      this.$localStorage.setItem(
                        "client",
                        this.clients[i].name
                      );

                      this.$store.commit("gaibian", res.data.name);

                      // 判断登录身份
                      this.url = this.clients[i]["url"];
                      this.originInfo = res.data;
                      switch (this.clientName) {
                        case "order":
                          this.routerGo({ authStatus: 1, authName: "点单人" });
                          break;
                        case "money":
                          this.warningText = res.data.login_msg;
                          if (this.warningText) {
                            this.warningText = this.warningText
                              .replaceAll(
                                "<warn>",
                                '<span class="red-color fs18 m-l-1 m-r-1">'
                              )
                              .replaceAll("</warn>", "</span>");
                            this.showWarning = true;
                          } else {
                            this.routerGo({
                              authStatus: 4,
                              authName: "收银人",
                            });
                          }
                          break;
                        default:
                          this.routerGo();
                          break;
                      }
                    } else {
                      this.$api.UtilAuth.auth
                        .requestauthlogout()
                        .then((ress) => {
                          if (ress.code == 1) {
                            this.$message({
                              message:
                                "没有权限登录" +
                                this.clients[i].systemName +
                                ",请查看你的账号密码是否正确",
                              type: "info",
                            });
                          }
                        });
                      window.loopReadCard();
                    }
                  }
                }
              } else {
                this.$message({
                  message: "没有权限登录",
                  type: "info",
                });
                window.loopReadCard();
              }
            } else {
              if (res.code == 12 || res.code == 11) {
                this.term();
              }
              this.$message.warning(res.msg);
              window.loopReadCard();
            }
          });
      }
    },
  },
  mounted() {
    this.term();
    window.loopReadCard();
    document.onkeydown = (e) => {
      if (e.keyCode == 13) this.submit();
    };
  },

  mixins: [swipingCard],

  computed: {
    isAndroidTerminal() {
      let termType = "";
      try {
        termType = atool.getTermType();
      } catch (error) {
        console.log("获取终端类型失败", error);
      }
      return termType == "android";
    },
    isWeb() {
      let termType = "";
      try {
        termType = atool.getTermType();
      } catch (error) {
        console.log("获取终端类型失败", error);
      }
      return termType === "";
    },
    version() {
      const pv = localStorage.getItem("projectVersion");
      const av = localStorage.getItem("refreshAll");
      return pv + (av ? ` - ${av}` : "");
    },
  },

  beforeDestroy() {
    window.stopLoopReadCard();
    document.onkeydown = null;
  },
};
</script>

<style lang="less">
// 弹框样式
.Thelogin .el-dialog {
  background: linear-gradient(180deg, #08080a 0%, #11182d 100%);
  box-shadow: 0px 0px 10px 0px rgba(26, 137, 255, 0.8);
  border: 1px solid #32b9ff;
  border-radius: 8px;

  .el-dialog__header .el-dialog__title {
    color: #fff;
  }

  .el-dialog__header {
    background-color: transparent !important;
  }

  .el-dialog__footer .dialog-footer {
    button {
      color: #fff;
      &:nth-child(1) {
        background: #374368;
      }
      &:nth-child(2) {
        background: linear-gradient(180deg, #4b89ff 0%, #455eff 100%);
      }
    }
  }
}

.Thelogin .auth {
  li {
    padding: 8px 20px;
    box-sizing: border-box;
    font-size: 14px;
    color: #fff;
    input {
      margin-right: 20px;
    }
  }
}

.login-choose-btn {
  text-align: center;
  margin-top: 20px;
  button {
    padding: 6px 14px;
    margin: 0 8px;
    color: #fff;
    border: none;
    border-radius: 8px;
    &.cancel {
      background: rgba(55, 67, 104, 1);
    }
    &.ok {
      background: #09f;
    }
  }
}
</style>
<style lang="less">
/deep/ .el-carousel--horizontal {
  overflow: hidden !important;
}

.Thelogin {
  background-color: #080b16;
  width: 100vw;
  height: 100vh;
  .terminal-type {
    margin-top: 5px;
    position: fixed;
    right: 20px;
    color: #fff;
    display: flex;
    justify-content: flex-end;
    align-items: center;
    .terminal-type-name {
      text-align: center;
    }

    .exit {
      margin-right: 16px;
      display: flex;
      justify-content: center;
      align-items: center;
      color: #367bd5;
      width: 60px;
      height: 30px;
      cursor: pointer;
      opacity: 0.6;
      img {
        width: 20px;
        height: 20px;
      }
      &:hover {
        color: #fff;
        border-color: #fff;
        opacity: 1;
      }
    }

    .clear-cache {
      margin-right: 16px;
      display: flex;
      justify-content: center;
      align-items: center;
      color: #367bd5;
      width: 100px;
      height: 30px;
      cursor: pointer;
      opacity: 0.6;
      img {
        width: 20px;
        height: 20px;
      }
      &:hover {
        color: #fff;
        border-color: #fff;
        opacity: 1;
      }
    }

    .change-position {
      margin-right: 16px;
      display: flex;
      justify-content: center;
      align-items: center;
      color: #367bd5;
      width: 100px;
      height: 30px;
      cursor: pointer;
      opacity: 0.6;
      img {
        width: 20px;
        height: 20px;
      }
      &:hover {
        color: #fff;
        border-color: #fff;
        opacity: 1;
      }
    }

    .app-version {
      color: #fff;
      font-size: 12px;
      text-align: center;
    }
  }
  .peak {
    display: grid;
    grid-template-columns: 1fr 800px 1fr;
    grid-template-rows: 88px;
    img {
      width: 100%;
      height: 100%;
    }
  }

  .elasticity {
    width: 100%;
    height: calc(100vh - 88px);
    box-sizing: border-box;
    .center-type {
      width: 100%;
      height: 100%;
      max-width: 1380px;
      margin: 0 auto;
      background: url("../../assets/register-login/denglu_bg.png") center center
        no-repeat;
      background-size: contain;

      .slideshow {
        width: calc(100% - 400px);
      }

      .keyboard-contain {
        width: 400px;
        height: 600px;
        .OpenKeyboard {
          width: 400px;
          height: 580px;
          &.android {
            transform: scale(0.8);
          }
          .Keyboards {
            width: 100%;
            height: 100%;
            background-image: url("../../assets/img/b8.png");
            background-repeat: no-repeat;
            background-size: 100% 100%;
            .staff {
              position: relative;
              width: 200px;
              height: 55px;
              text-align: center;
              display: inline-block;
              span {
                width: 100px;
                font-size: 20px;
                font-weight: 500;
                color: #ffffff;
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -30%);
              }
              img {
                width: 100%;
                height: 100%;
              }
            }

            .middle {
              margin-top: 30px;
              display: flex;
              flex-direction: column;
              align-items: center;
              .AccountNumber {
                width: 300px;
                height: 44px;
                border-radius: 10px;
                display: flex;
                align-items: center;
                margin-bottom: 20px;
                border: 1px solid rgba(255, 255, 255, 0.15);
                padding-left: 10px;
                box-sizing: border-box;
                background: rgba(0, 0, 0, 0.2);
                img {
                  width: 24px;
                }
                &.aer {
                  border: 1px solid #3ab4ff;
                  box-shadow: 0 0 9px 0px #3ab4ff;
                }
              }

              .keyboard {
                width: 100%;
                .table {
                  margin: 0 auto;
                  width: 300px;
                  height: 314px;
                  background: rgba(0, 0, 0, 0.2);
                  border: 1px solid rgba(255, 255, 255, 0.15);
                  border-radius: 6px;
                  overflow: hidden;
                  .tr {
                    flex-wrap: wrap;
                    .td {
                      position: relative;
                      width: 100px;
                      height: calc(315px / 5);
                      line-height: calc(315px / 5);
                      text-align: center;
                      font-size: 30px;
                      font-weight: 600;
                      color: #ffffff;
                      cursor: pointer;
                      &:before {
                        content: "";
                        display: block;
                        position: absolute;
                        bottom: 0;
                        left: 0;
                        width: 100%;
                        height: 1px;
                        background-color: rgba(255, 255, 255, 0.15);
                      }
                      &:after {
                        content: "";
                        display: block;
                        position: absolute;
                        top: 0;
                        right: 0;
                        width: 1px;
                        height: 100%;
                        background-color: rgba(255, 255, 255, 0.15);
                      }

                      &:nth-child(3n) {
                        &:after {
                          width: 0;
                          height: 0;
                        }
                      }

                      &:nth-child(10),
                      &:nth-child(12),
                      &:nth-child(13) {
                        padding-top: 10px;
                        box-sizing: border-box;
                        line-height: 14px;
                        img {
                          width: 30px;
                        }
                        > div {
                          font-size: 12px;
                          font-weight: 400;
                        }
                      }

                      &:nth-last-child(1) {
                        width: 200px;
                        img {
                          width: 100%;
                          height: 100%;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

.Thelogin .AccountNumber input {
  width: calc(100% - 37px);
  border: none !important;
  background-color: rgba(0, 0, 0, 0);
  color: #d9d9d9;
  font-size: 16px;
  height: 44px;
  cursor: pointer;
}

.Thelogin .AccountNumber input[type="text"]:focus,
input[type="password"]:focus {
  border: 0px solid #eb7350;
  background: rgba(255, 255, 255, 0);
  outline: none;
  caret-color: rgba(0, 0, 0, 0);
}

.Thelogin .el-input__inner::placeholder {
  color: #b6b5b5;
}

/* 谷歌 */
.Thelogin .el-input__inner::-webkit-input-placeholder {
  color: #b6b5b5;
}

/* 火狐 */
.Thelogin .el-input__inner:-moz-placeholder {
  color: #b6b5b5;
}

.Thelogin .revolving {
  transform: rotate(360deg);
  animation: rotation 2s linear infinite;
}

@keyframes rotation {
  from {
    transform: rotate(0deg);
  }

  to {
    transform: rotate(360deg);
  }
}

.pressdown {
  box-shadow: 0 0px 22px 3px #32b9ff inset;
}
</style>
