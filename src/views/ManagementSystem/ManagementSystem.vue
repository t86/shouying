<template>
  <div class="ManagementSystem">
    <div class="Thehead">
      <div class="logo">
        <img src="@/assets/img/logo.png" style="visibility:hidden" alt />
        <div class="header">{{header}}</div>
      </div>
      
      <div class="orso">
        <el-button v-if="showKeyboard" type="primary" @click.stop="changeKeyboard">{{ isKeyBoard ? '关闭系统键盘' : '开启系统键盘' }}</el-button>
        <el-dropdown trigger="click" @command="handleCommand">
          <span class="el-dropdown-link">
            <!-- {{activeNames}} -->
            {{name}}
            <i class="el-icon-arrow-down el-icon--right"></i>
          </span>
          <el-dropdown-menu slot="dropdown">
            <el-dropdown-item command="修改密码">修改密码</el-dropdown-item>
            <el-dropdown-item command="退出">退出</el-dropdown-item>
          </el-dropdown-menu>
        </el-dropdown>
        <!-- 修改密码框 -->
        <div v-show="dialogFormVisible" class="Thepassword">
          <el-dialog
            title="修改密码"
            :visible.sync="dialogFormVisible"
            @close="dialogFormVisible = false"
            :close-on-click-modal="false"
          >
            <el-form label-position="left">
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>旧密码：
                </div>
                <el-input
                  v-model="Theoldpassword"
                  ref="selectsse"
                  placeholder="请输入旧密码"
                  class="controlling"
                  clearable
                  show-password
                />
              </div>
              <div class="compatibility">
                <div class="mandatory">
                  <span class="reqfieldsd">*</span>新密码：
                </div>
                <el-input
                  v-model="Thenewpassword"
                  ref="selectsse"
                  placeholder="请输入新密码"
                  class="controlling"
                  clearable
                  show-password
                />
              </div>
            </el-form>
            <span slot="footer" class="dialog-footer">
              <el-button @click="dialogFormVisible = false">取 消</el-button>
              <el-button type="primary" v-show="!op" @click="changepassword ">用户 确认修改</el-button>
              <el-button type="primary" v-show="op" @click="changepasswords ">管理员 确认修改</el-button>
            </span>
          </el-dialog>
        </div>
      </div>
    </div>
    <div class="frame">
      <div class="case">
        <div class="demo-collapse">
          <el-collapse v-model="activeNames" accordion>
            <el-collapse-item v-for="(eachof,index) in ShowThelistof" :name="index+''" :key="index">
              <span slot="title" class="collapse-title">
                <img class="icons" :src="require('@/assets/img/' + eachof.img)" alt />
                <div>{{eachof.name}}</div>
              </span>

              <div
                class="linr"
                v-for="(each,i) in eachof.content"
                :key="i"
                @click="liseg(index,i,each)"
                :style="{'background-color': nr[0]== index?(nr[1]== i?'#2170FF':''):'',
              'margin': nr[0]== index?(nr[1]== i?'1px 6px 1px 6px':''):''}"
              >
                <div
                  class="qiheadan"
                  :style="{'background-color': nr[0]== index?(nr[1]== i?'#fff':''):''}"
                ></div>
                <router-link
                  :to="each.url"
                  class="yans"
                  :style="{'color': nr[0]== index?(nr[1]== i?'#fff':'#333'):'#333'}"
                >{{each.name}}</router-link>
              </div>
            </el-collapse-item>
          </el-collapse>
        </div>
      </div>
      <div class="seed">
        <router-view />
      </div>
    </div>
  </div>
</template>
<script>
import wineNavList from './wineNavList'
import storeNavList from './storeNavList'
import erpNavList from './erpNavList'
import { mapState, mapMutations } from "vuex";
import { sessionStorage, localStorage } from "@/utils/common/storage";
import md5 from "js-md5";
import xzbjt from "@/assets/img/selected_bg.png";
export default {
  name: "ManagementSystem",
  data() {
    return {
      op: localStorage.getItem("client") == "appinfo",
      wa: xzbjt, //图片控制
      header: "", //头部展示内容
      dialogFormVisible: false,
      Theoldpassword: "", // 旧密码
      Thenewpassword: "", // 新密码
      ShowThelistof: [], //显示列表
      Thelistof: [

        // 门店后台
        ...storeNavList,

        // erp
        ...erpNavList,
        

       // 存酒仓库
       ...wineNavList,


        // 超级管理员
        {
          name: "用户管理",
          sys_priv: ["-888"],
          system: ["appinfo"],
          img: "user_manage.png",
          content: [
            {
              name: "用户管理",
              url: "/appinfo/smgr"
            }
          ]
        }
      ], // 列表
      activeNames: "0", //点开了第几个
      nr: [],
      isKeyBoard: localStorage.getItem('keyboard') == '1' // 是否开启系统键盘
    };
  },
  mounted() {
    this.authority();
    this.initNavBarActive();
  },
  computed: {
     // 是否有空瓶仓权限
     hasEmptyManage(){
      return this.$store.state.userInfo.sys_modules&&this.$store.state.userInfo.sys_modules.includes(25)
    },
    showKeyboard(){ 
      return window.atool && window.atool.getTermType() == "android"
    },
    ...mapState(["name"])
  },
  methods: {
    changeKeyboard() {
      if(localStorage.getItem('keyboard') == '1') {
        if (window.atool&& window.atool.getTermType() == "android" &&
            ("hideSoftInput" in window.atool)) {
          localStorage.setItem('keyboard', "2")
          setTimeout(() => {
            atool.hideSoftInput();
            atool.restart();
            }, 10)
        } else {
          this.$message.warning("当前设备不支持系统键盘, 请找实施人员升级应用");
          return;
        }
      } else {
        if (window.atool && window.atool.getTermType() == "android" &&
          ("showSoftInput" in window.atool)) {
            atool.showSoftInput();
            localStorage.setItem('keyboard', "1")
        } else {
          this.$message.warning("当前设备不支持系统键盘, 请找实施人员升级应用");
          return;
        }
      }
      this.isKeyBoard = localStorage.getItem('keyboard') == '1';
    },

    initNavBarActive(paramsStr = "") {
      if (localStorage.getItem("navigation")) {
        var nums = localStorage.getItem("navigation").split(",");
        this.activeNames = nums[0];
        this.nr = nums;
        this.header = this.ShowThelistof[nums[0]].content[nums[1]].name;

        this.$router.push(
          {
            path: this.ShowThelistof[nums[0]].content[nums[1]].url + paramsStr
          },
          onComplete => {},
          onAbort => {}
        );
      }
    },
    // 判断退出
    handleCommand(command) {
      if (command == "修改密码") {
        this.dialogFormVisible = true;
      } else if (command == "退出") {
        if (this.op) {
          this.opens();
        } else {
          this.open();
        }
      }
    },
    // 退出登录
    open() {
      this.$api.UtilAuth.auth
        .requestauthlogout()
        .then(res => {
          console.log(res);
          if (res.code == 1) {
            if (localStorage.getItem("client") == "appinfo")
              this.$router.push({
                path: "/appinfo"
              });
            else
              this.$router.push(
                { path: "/Thelogin?client=" + localStorage.getItem("client") }
              );
            localStorage.removeItem("priv");
            localStorage.removeItem("navigation");

            this.$message({
              showClose: true,
              message: "退出成功",
              type: "success"
            });
          }
        })
        .catch(() => {
          this.$message({
            type: "info",
            message: "退出出现错误"
          });
        });
    },
    // 超级管理员退出登录
    opens() {
      this.$api.UtilAuth.appinfo.requestsauthlogout().then(res => {
        if (res.code == 1) {
          this.$router.push(
            { path: "/appinfo?super=" + localStorage.getItem("super") },
            () => {},
            () => {}
          );
          localStorage.removeItem("stk");
          localStorage.removeItem("priv");
          localStorage.removeItem("navigation");

          this.$message({
            showClose: true,
            message: "退出成功",
            type: "success"
          });
        }
      });
    },
    // 修改密码
    changepassword() {
      if (this.Theoldpassword || this.Thenewpassword) {
        this.$api.BMS.emp
          .requestempchg_pwd({
            old_password: md5(this.Theoldpassword)
              .toString()
              .toUpperCase(),
            new_password: md5(this.Thenewpassword)
              .toString()
              .toUpperCase()
          })
          .then(res => {
            if (res.code == 1) {
              this.$message({
                showClose: true,
                message: "成功修改密码",
                type: "success"
              });
              this.Theoldpassword = "";
              this.Thenewpassword = "";
              this.dialogFormVisible = false;
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message({
          message: "新旧密码不能为空",
          type: "warning"
        });
      }
    },
    // 超级管理员修改密码
    changepasswords() {
      if (this.Theoldpassword || this.Thenewpassword) {
        this.$api.UtilAuth.appinfo
          .requestsmgrchgpw({
            old_password: md5(this.Theoldpassword)
              .toString()
              .toUpperCase(),
            new_password: md5(this.Thenewpassword)
              .toString()
              .toUpperCase()
          })
          .then(res => {
            if (res.code == 1) {
              this.$message({
                showClose: true,
                message: "成功修改密码",
                type: "success"
              });
              this.Theoldpassword = "";
              this.Thenewpassword = "";
              this.dialogFormVisible = false;
            } else {
              this.$message.warning(res.msg);
            }
          });
      } else {
        this.$message({
          message: "新旧密码不能为空",
          type: "warning"
        });
      }
    },
    // 判断权限显示
    authority() {
      var s = [];
      for (let i = 0; i < this.Thelistof.length; i++) {
        for (let p = 0; p < this.Thelistof[i].system.length; p++) {
          if (this.Thelistof[i].system[p] == sessionStorage.getItem("client")) {
            // nav列表中默认的权限(erp仓库管理员/erp管理员)
            s.push(this.Thelistof[i]);
          }
        }
        
        if(this.Thelistof[i].auth && this.Thelistof[i].auth.length > 0) {
          for (let p = 0; p < this.Thelistof[i].auth.length; p++) {
              if(this.Thelistof[i].needAuth && this.Thelistof[i].auth[p] == sessionStorage.getItem("client")) {
                 // 需要授权的权限（erp管理员有权限，但是erp仓库管理员通过配置确认是否有权限）
                 if(this.hasEmptyManage) {
                   s.push(this.Thelistof[i]);
                 }
              }
          }
        }
        
      }
      this.ShowThelistof = s
    },
    liseg(index, i, each) {
      console.log(index, i, each.url, each.name);
      this.header = each.name;
      this.nr = [index, i, each.url, each.name];
      localStorage.setItem("navigation", [index, i, each.url, each.name].join(','));
    }
  }
};
</script>
<style>
.el-icon-arrow-right {
  font-size: 14px;
  color: #8c8c8c !important;
}

.ManagementSystem {
  width: 100%;
  height: 100%;
}

/* el-collapse-item__header is-active */
.ManagementSystem .case .el-collapse-item__header.focusing:focus:not(:hover) {
  color: rgb(179, 179, 179);
}

.ManagementSystem .Thehead {
  height: 48px;
  /* width: calc(100% - 80px); */
  background-color: #222653;
  display: flex;
  justify-content: space-between;
  padding: 0px 60px 0px 24px;
  line-height: 48px;
}

.ManagementSystem .logo {
  /* width: 120px;
        height: 48px; */
  display: flex;
}

.ManagementSystem .logo img {
  width: 120px;
  height: 48px;
}

.ManagementSystem .header {
  font-size: 22px;
  /* font-weight: 500; */
  margin-left: 96px;
  color: #d9d9d9;
}

.ManagementSystem .frame {
  /* width: 100vw; */
  /* height: calc(100% - 70px); */
  height: calc(100vh - 48px);
  display: flex;
  align-items: stretch;
}

.ManagementSystem .orso {
  line-height: 48px;
}

.ManagementSystem .ziti {
  margin-left: 10px;
}

.ManagementSystem .el-dropdown-link {
  cursor: pointer;
  color: #d9d9d9;
  font-size: 14px;
}

.ManagementSystem .el-icon-arrow-down {
  font-size: 12px;
  z-index: 1000000;
  /* background-color: #1A1A20 ; */
}

.ManagementSystem .seed {
  height: 100%;
  width: 86vw;
  min-width: calc(100vw - 200px);
  max-width: calc(100vw - 230px);
  background-color: #e4e4e4;
  display: inline-block;
  /* overflow-y: scroll; */
}

.ManagementSystem .case {
  /* height: calc(100% - 70px);; */
  /* height: calc(100vh - 70px);; */
  height: 100%;
  /* height: 100vh; */
  /* height: calc(100vh - 40px);; */
  overflow-y: scroll;
  overflow-y: overlay;
  /* position: relative; */
  width: 14vw;
  min-width: 199px;
  max-width: 230px;
  /* max-width: 230px; */
  background-color: #f9f9f9 !important;
  display: inline-block;
  /* border-top: 1px solid rgb(28, 28, 226); */
}

.ManagementSystem .demo-collapse {
  /* height: 100%; */
}

.ManagementSystem .case .collapse-title .icons {
  margin-right: 16px;
}

.ManagementSystem .case .collapse-title {
  display: flex;
  align-items: center;
  font-weight: 600;
}

/* 图标大小 */
.ManagementSystem .case .icons {
  width: 16px;
  height: 16px;
}

.ManagementSystem .linr {
  background-color: #f9f9f9;
  /* padding: 10px 0; */
  display: flex;
  align-items: center;
  background-repeat: no-repeat;
  background-size: 100% 100%;
  margin: 1px 6px 1px 6px;
  border-radius: 6px;
}

.ManagementSystem .case .linr:hover {
  background-color: #eee;
  border-radius: 6px;
  margin: 1px 6px 1px 6px;
}

.ManagementSystem .case .el-collapse {
  /* border-top:1px solid rgb(35, 35, 43) !important; */
  border: none;
}

.ManagementSystem .case .el-collapse-item__header {
  background-color: #f9f9f9 !important;
  border-bottom: 1px solid #f9f9f9 !important;
  color: #555;
  padding-left: 18px;
  font-size: 18px;
  margin: 0 6px;

  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.ManagementSystem .case .el-collapse-item__header:hover {
  background-color: #eeeeee !important;
  border-radius: 4px;
}

.ManagementSystem .case .el-collapse-item__arrow {
  margin: 0 6px 0 auto;
}

.el-collapse-item__arrow {
  margin: 0 2px 0 auto;
}

.ManagementSystem .case .el-collapse-item__content {
  /* background-color: #f9f9f9 !important; */
  padding: 0px 0px;
  /* border-top:1px solid #34353F ; */
  /* border-bottom: 1px solid #22232b; */
}

.ManagementSystem .case .el-collapse-item__wrap {
  background-color: #f9f9f9 !important;
  border: none;
}

/* :class="{Selectthecolor:(activeNames == index+1)}" */
/* .ManagementSystem .Selectthecolor{
        color: rgb(231, 46, 46);
    } */
.ManagementSystem .qiheadan {
  width: 3px;
  height: 16px;
  border-radius: 2px;
  margin-left: 30px;
}

.ManagementSystem .yans {
  position: relative;
  color: #6a9eff;
  /* padding-left: 40px; */
  display: inline-block;
  padding: 4px 0 6px 16px;
  font-size: 16px;
  width: calc(100% - 40px);
  height: 100%;
  color: #555;

  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.ManagementSystem .yans:before{
  content: '';
  position: absolute;
  left: 0;
  top: -1px;
  width: 80%;
  height: 1px;
  background: linear-gradient(to right, #f1f1f1 0%, #e6e6e6 50%, #f1f1f1 100%);
}

.ManagementSystem .yans:nth-last-child(1):after{
  content: '';
  position: absolute;
  left: 0;
  bottom: -1px;
  width: 80%;
  height: 1px;
  background: linear-gradient(to right, #f1f1f1 0%, #e6e6e6 50%, #f1f1f1 100%);
}

.ManagementSystem .el-dialog {
  width: 30vw;
}

/* 密码 */
.Thepassword .mandatory {
  color: #40404e;
  width: 140px;
  text-align: right;
  /* padding-top: 10px; */
}

.Thepassword .controlling {
  width: 230px !important;
}

.Thepassword .reqfieldsd {
  font-size: 16px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.Thepassword .compatibility {
  display: flex;
  /* align-items: center; */
  margin-bottom: 10px;
}

.Thepassword .el-dialog {
  width: 500px !important;
}

/* 修改密码退出下拉框 */
.el-popper[x-placement^="bottom"] {
  margin: 0;
}

.el-popper[x-placement^="bottom"] > div::after,
.el-popper[x-placement^="bottom"] div {
  border-bottom-color: #f5f5f5 !important;
}

.el-dropdown-menu {
  background-color: #f9f9f9;
  border: 1px solid #f9f9f9;
}

.el-dropdown-menu__item {
  color: #40404e;
}

.el-dropdown-menu__item:hover {
  background-color: #ddd;
}

.el-dropdown-menu__item:not(.is-disabled):hover {
  background-color: #eee;
  color: #2170ff;
}

/* 修改密码 弹窗 */
/* .ManagementSystem .el-form-item__content{
        display: flex;
        width: 80%;
    } */
.ManagementSystem .el-dialog__header {
  background-color: #eee;
  color: #1a1a21;
  height: 40px;
  padding: 10px 20px;
  display: flex;
  align-items: center;
}

.ManagementSystem .el-dialog__title,
.el-dialog__headerbtn .el-dialog__close,
.el-form-item__label {
  color: #1a1a21;
}

.ManagementSystem .el-dialog__body {
  padding-top: 0px;
  background-color: #f9f9f9;
}

.ManagementSystem .el-form {
  padding-top: 30px;
}

.ManagementSystem .el-input__inner {
  background-color: transparent;
  color: #40404e;
  outline: none;
  border: 1px solid #d9d9d9;
}

.ManagementSystem .el-dialog__footer {
  padding: 10px;
  line-height: 50px;
  background-color: #eee;
}

.ManagementSystem .el-button.el-button--default {
  background-color: #ccc;
  border: 1px solid #ccc;
  color: #40404e;
  &:hover {
    background-color: #DCDFE6;
    border: 1px solid #DCDFE6;
    color: #40404e;
  }
}

.ManagementSystem .el-button.el-button--primary {
  background-color: #2170ff;
  border: 1px solid #2170ff;
  color: #fff;
  &:hover {
    background-color: #4e87f1;
    border: 1px solid #4e87f1;
    color: #fff;
  }
}

.error .el-input__inner {
  border-color: #ce4253 !important;
}

.error .el-textarea__inner {
  border-color: #ce4253 !important;
}

.zhuixiaoi_l ::-webkit-scrollbar,
.zhuixiaoi_l ::-webkit-scrollbar-track {
  display: none;
}

.cwts {
  color: #ce4253;
  line-height: 34px;
  padding-left: 10px;
}
</style>
<style scoped>
/* 修改密码 弹窗 */
.ManagementSystem .el-form-item__content {
  display: flex;
  /* width: 80%; */
}
</style>
<style lang='less' scoped>
/deep/ .el-input__inner:focus,
/deep/ .el-textarea__inner:focus {
  border: 1px solid #6a9eff !important;
}
</style>

