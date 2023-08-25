<template>
  <div class="appinfo">
    <div class="peak">
      <div class="upleft">
        <!-- <img src="@/assets/img/b6.png" alt /> -->
      </div>
      <div class="upright"></div>
    </div>
    <div class="elasticity">
      <div class="slideshow">
        <el-carousel height="60vh" class="location">
          <el-carousel-item v-for="item in 3" :key="item">
            <img src="@/assets/img/banner_login.png" style="width:100%;height:100%;object-fit:contain" alt />
          </el-carousel-item>
        </el-carousel>
      </div>
      <div class="OpenKeyboard">
        <div v-show="sense" class="Open">
          <div
            class="buttonswitch"
            @mouseover="controller = false"
            @mouseout="controller = true"
            @click="sense = !sense"
          >
            <div
              class="buttonswitch-button"
              :style="{'background-image':`url(${controller?wa[0]:wa[1]})`}"
            >
              <img
                class="buttonswitch-button-spin"
                :class="{revolving:!controller}"
                src="@/assets/img/b4.png"
                alt
              />
            </div>
            <img class="buttonswitch-switch" src="@/assets/img/b7.png" alt />
          </div>
        </div>
        <div v-show="!sense" class="Keyboards">
          <div class="staff">
            <span>超级管理员登录</span>
            <img src="@/assets/img/b14.png" alt />
          </div>
          <div class="middle">
            <div class="AccountNumber" :class="{'aer':(pitchon == 2)}" @click="pitchon = 2">
              <img src="@/assets/img/b11.png" alt />
              <el-input show-password placeholder="请输入密码" v-model="password"></el-input>
            </div>
            <div class="keyboard">
              <table>
                <tbody>
                  <tr>
                    <td
                      class="tds"
                      v-for="(eachof,index) in numList"
                      :key="index"
                      :class="{'pressdown':(eachof.num == pressdowns)}"
                      @mousedown="pressdowns = eachof.num"
                      @mouseup="pressdowns = Number"
                      @click="select(eachof.num)"
                    >
                      <img src="@/assets/img/b13.png" v-if="eachof.num == 100" alt />
                      <img src="@/assets/img/b10.png" v-if="eachof.num == 101" alt />
                      <img src="@/assets/img/b12.png" v-if="eachof.num == 102" alt />
                      <div>{{eachof.title}}</div>
                    </td>
                    <td
                      class="td"
                      rowspan="2"
                      @mousedown="gaibtup = true"
                      @mouseup="gaibtup = false"
                      @click="submit"
                    >
                      <img :src="`${gaibtup?register[0]:register[1]}`" alt />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script>
import b3 from "@/assets/img/b3.png";
import b17 from "@/assets/img/b17.png";
import b9 from "@/assets/img/b9.png";
import b16 from "@/assets/img/b16.png";
import { mapActions, mapState, mapMutations } from "vuex";
import { sessionStorage, localStorage } from '@/utils/common/storage'
import md5 from "js-md5";
export default {
  name: "appinfo",
  data() {
    return {
      wa: [b3, b17], //图片控制
      controller: true, //图片控制器
      sense: false, //控制显示隐藏
      // account:'',//账号
      password: "", //密码
      pitchon: 2, //选中账号还是密码状态
      numList: [
        {
          title: "1",
          num: 1
        },
        {
          title: "2",
          num: 2
        },
        {
          title: "3",
          num: 3
        },
        {
          title: "4",
          num: 4
        },
        {
          title: "5",
          num: 5
        },
        {
          title: "6",
          num: 6
        },
        {
          title: "7",
          num: 7
        },
        {
          title: "8",
          num: 8
        },
        {
          title: "9",
          num: 9
        },
        {
          title: "清空",
          num: 100
        },
        {
          title: "0",
          num: 0
        },
        {
          title: "回退",
          num: 101
        },
        {
          title: "返回",
          num: 102
        }
      ],
      pressdowns: Number, //点了哪一个键盘数字
      register: [b9, b16], //切换图片
      gaibtup: false, //登录图片控制器

      // 路由跳转控制
      // http://192.168.124.5:8080/?#/appinfo
      // http://192.168.124.5:8080/#/Thelogin?client=org_mgr&oid=null
      clients: {
        name: "appinfo",
        id: [999], // 权限
        systemName: "超级管理员",
        url: "/ManagementSystem/appinfo"
      }
    };
  },
  methods: {
    ...mapMutations(["gaibian"]),
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
        this.account = "";
        this.password = "";
        this.pitchon = 0;
        this.sense = true;
      }
    },
    // 登录
    submit() {
      // console.log(this.$route.query.client);
      if (this.password == "") {
        this.$message.warning("密码不能为空");
      } else {
        this.$api.UtilAuth.appinfo
          .requestsauthlogin({
            password: md5(this.password)
              .toString()
              .toUpperCase()
          })
          .then(res => {
            if (res.code == 1) {
              this.$store.commit("updateUserInfo", {
                emp_id: 2
              });
              // 存储
              this.$localStorage.setItem("stk", res.data);
              this.$localStorage.setItem("priv", "-888");
              this.$localStorage.setItem("navigation", [
                0,
                0,
                this.clients.url
              ].join(','));
              this.$sessionStorage.setItem("client", "appinfo");
              this.$localStorage.setItem("client", "appinfo");
              this.$router.push(
                { path: this.clients.url },
                onComplete => {},
                onAbort => {}
              );
              this.gaibian(this.clients.systemName);
            } else {
              this.$message.warning(res.msg);
            }
          });
      }
    }
  },
  mounted() {
    document.onkeydown = e => { 
      if (e.keyCode == 13) this.submit()
    }
  },
  computed: {
    ...mapState(["name"])
  },

  beforeDestroy(){
    document.onkeydown = null
  }
};
</script>
<style>
.appinfo {
  background-image: url("../../assets/img/b2.png");
  width: 100vw;
  height: 100vh;
  background-repeat: no-repeat;
}

.appinfo .peak {
  display: flex;
}

.appinfo .slideshow {
  padding-top: 4vh;
}

.appinfo .upleft {
  width: 65vw;
  height: 13vh;
  background-image: url("../../assets/img/b24.png");
  background-repeat: no-repeat;
  background-size: 100% 100%;
  position: relative;
}

.appinfo .upleft img {
  width: 14vw;
  height: 9vh;
  position: absolute;
  top: 1vh;
  left: 12vw;
}

.appinfo .upright {
  width: 35vw;
  height: 13vh;
  background-image: url("../../assets/img/b25.png");
  background-repeat: no-repeat;
  background-size: 100% 100%;
}

.appinfo .elasticity {
  margin-top: 2vh;
  display: flex;
  justify-content: space-evenly;
}

.appinfo .location {
  width: 900px;
  height: 600px;
  /* background-color: #fff; */
  background-image: url("../../assets/img/b26.png");
  background-repeat: no-repeat;
  background-size: 100% 145%;
  /* background-size: 100% 135%; */
  background-position: 140px 30%;
}

.appinfo .location img {
  background-size: 100% 100%;
}

.appinfo .OpenKeyboard {
  width: 390px;
  height: 725px;
  /* background-color: rgb(8, 18, 48); */
}

.appinfo .Open {
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  transform: all 2s linear;
}

/* .appinfo .buttonswitch{ */
/* display: inline-block; */
/* margin: 50% auto 0; */
/* } */
.appinfo .buttonswitch-button {
  width: 80px;
  height: 80px;
  position: relative;
  background-repeat: no-repeat;
  background-size: 100% 100%;
}

.appinfo .buttonswitch-switch {
  width: 80px;
  margin-top: 10px;
}

.appinfo .buttonswitch-button-spin {
  position: absolute;
  top: -3px;
  left: -3px;
  width: 86px;
  height: 86px;
}

.appinfo .Keyboards {
  width: 100%;
  height: 600px;
  margin-top: 30px;
  /* background-color: #fff; */
  background-image: url("../../assets/img/b8.png");
  background-repeat: no-repeat;
  background-size: 100% 100%;
}

.appinfo .staff {
  position: relative;
  width: 200px;
  text-align: center;
  display: inline-block;
  padding-top: 1vh;
  margin-bottom: 2vh;
  margin-top: 1vh;
  margin-left: 30px;
}

.appinfo .staff span {
  color: #d9d9d9;
  font-size: 25px;
  display: inline-block;
  margin-bottom: 1.2vh;
}

.appinfo .staff img {
  width: 150%;
  height: 95%;
  position: absolute;
  bottom: 0;
  left: -50px;
}

.appinfo .middle {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.appinfo .AccountNumber {
  height: 60px;
  width: 80%;
  border-radius: 10px;
  display: flex;
  align-items: center;
  margin-bottom: 20px;
  border: 2px solid #114e83;
}

.appinfo .AccountNumber img {
  width: 35px;
}

.appinfo .aer {
  border: 2px solid #3ab4ff;
  box-shadow: 0 0 9px 0px #3ab4ff;
}

.appinfo .AccountNumber input {
  width: calc(100% - 37px);
  border: none !important;
  background-color: rgba(0, 0, 0, 0);
  color: #d9d9d9;
  font-size: 25px;
  height: calc(100% - 2px);
}

.appinfo .AccountNumber input[type="text"]:focus,
input[type="password"]:focus {
  border: 0px solid #eb7350;
  background: rgba(255, 255, 255, 0);
  outline: none;
  caret-color: rgba(0, 0, 0, 0);
}

.appinfo .el-input__inner::placeholder {
  color: #b6b5b5;
}

/* 谷歌 */
.appinfo .el-input__inner::-webkit-input-placeholder {
  color: #b6b5b5;
}

/* 火狐 */
.appinfo .el-input__inner:-moz-placeholder {
  color: #b6b5b5;
}

.appinfo .revolving {
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
</style>
<style>
.appinfo .keyboard {
  width: 80%;
  display: flex;
  justify-content: center;
  height: 370px;
  /* border-radius: 10px ; */
}

.appinfo .keyboard table {
  border: 2px solid #114e83;
  border-collapse: collapse;
  width: 100%;
}

.appinfo .keyboard tr {
  display: flex;
  flex-wrap: wrap;
  align-items: stretch;
}

.appinfo .keyboard td {
  border: 1px solid #114e83;
  color: #d9d9d9;
  height: 70px;
}

.appinfo .keyboard .tds {
  width: calc((100% - 12px) / 3);
  text-align: center;
  font-size: 24px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  transform: all 2s cubic-bezier(1, 1, 1, 1);
}

.appinfo .keyboard .tds img {
  width: 30px;
}

.appinfo .pressdown {
  box-shadow: 0 0px 22px 3px #32b9ff inset;
}

.appinfo .td {
  width: calc(((100% - 12px) / 3) * 2 + 4px);
}

.appinfo .td img {
  width: 100%;
  height: 70px;
}
</style>