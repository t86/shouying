<template>
  <div class="vip-nav">
    <div class="nav-top">
      <ul class="first-cate" layout="row" layout-align="start center">
        <li
          v-for="item in navList"
          :key="item.id"
          :class="{
            back: item.id == 0,
            active: item.hover || item.id == firstCateId,
          }"
          layout="row"
          v-show="!(!$store.getters.vipAuth && item.id == 0)"
          layout-align="center center"
          @click="cateClickHandle('firstCate', item)"
          @mouseenter="mouseHandle(item, 1)"
          @mouseleave="mouseHandle(item, 2)"
        >
          <img
            :src="
              item.hover || item.id == firstCateId ? item.hoverIcon : item.icon
            "
            alt
          />
          <span>{{ item.name }}</span>
        </li>

        <div
          class="options-contain cursor"
          @click.stop="showOption = !showOption"
        >
          <span>{{ $store.state.userInfo.name }}</span>
          <el-icon class="el-icon-arrow-down cursor m-r-10"></el-icon>
          <ul class="m-r-10 cursor" v-if="showOption">
            <!-- <li class="cursor" @click="showOrHideDrawer">修改密码</li> -->
            <li class="cursor" @click="logOutHandle">退出登录</li>
          </ul>
        </div>
      </ul>
      <ul class="second-cate" layout="row" layout-align="start center">
        <li
          v-for="item in navList[firstCateId].children"
          :key="item.id"
          :class="{ active: item.id == secondCateId }"
          v-show="!(!$store.getters.vipAuth && item.id == 32)"
          layout="row"
          layout-align="center center"
          @click="cateClickHandle('secondCate', item)"
        >
          <span>{{ item.name }}</span>
        </li>
      </ul>
    </div>
    <div class="contain">
      <div class="content">
        <router-view></router-view>
      </div>
    </div>
  </div>
</template>

<script>
import navList from "./navList";
import api_auth from "@/api/UtilAuth";
export default {
  data() {
    return {
      firstCateId: 2,
      secondCateId: 1,
      showOption: false,
    };
  },
  methods: {
    mouseHandle(itemInfo, type) {
      itemInfo.hover = type === 1;
      this.$forceUpdate();
    },
    cateClickHandle(type, itemInfo) {
      switch (type) {
        case "firstCate":
          if (itemInfo.id == 0) {
            this.$router.replace("moneyCard");
          } else if (itemInfo.id == 1) {
            return this.$message.warning("开发中，敬请期待...");
          } else {
            this.firstCateId = itemInfo.id;
            if (itemInfo.children.length > 0) {
              this.secondCateId = itemInfo.children[0].id;
              this.$router.push({
                name: itemInfo.children[0].routerName,
              });
            }
          }
          break;
        case "secondCate":
          this.secondCateId = itemInfo.id;
          this.$router.push({ name: itemInfo.routerName });
          break;
      }
    },
    async logOutHandle() {
      try {
        const res = await api_auth.auth.requestauthlogout();
        if (res.code === 1) {
          // this.$store.commit("updateResResultDataObj", "");
          this.$store.commit("updateUserInfo", "");
          this.$router.replace({
            name: "Thelogin",
            replace: true,
          });
          this.$message.success("退出成功！");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("logout失败", error);
      }
    },
  },
  mounted() {
    const routerParams = {
      vipManager: 21,
      vipType: 22,
      pointManager: 23,
      onlineMakeMoneyToVip: 31,
      vipNumRules: 32,
      vipBillRules: 33,
      makeMoneyToVip: 41,
      payMoneyAll: 42,
      vipPay: 43,
    };
    this.firstCateId = Math.floor(routerParams[this.$route.name] / 10);
    this.secondCateId = routerParams[this.$route.name];

    window.onclick = () => {
      this.showOption = false;
    };
  },
  computed: {
    navList() {
      let list =  navList.map((item) => {
        if(item.children){
          item.children = item.children.filter((child) => {
            if(child.id == 31){
              return this.hasTopUpSettingAuth
            }else if(child.id == 23){
              return this.hasSettingPointAuth
            }else{
              return true
            }
          })
        }
        return {
        ...item,
        hover: false,
        }
      });
      return list;
    },
      // 是否有积分设置权限
      hasSettingPointAuth() {
        return this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(35)
    },
     // 是否有积分设置权限
     hasTopUpSettingAuth() {
        return this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(32)
    },
  },
};
</script>

<style lang="less" scoped>
@import "../../style/common/scrollBarVip.less";
</style>

<style scoped lang="less">
.vip-nav {
  color: #1a1a21;
  .nav-top {
    box-sizing: border-box;
    ul.first-cate {
      position: relative;
      height: 48px;
      background-color: #181b41;
      li {
        line-height: 48px;
        font-size: 16px;
        cursor: pointer;
        color: #aed8ff;
        margin-right: 20px;
        margin-left: 10px;
        img {
          width: 16px;
          margin-right: 2px;
        }
      }
      li.back {
        width: 76px;
        height: 32px;
        background: #31355b;
        border-radius: 20px;
        text-align: center;
        &.active {
          position: relative;
          color: #3a89ff;
        }
      }
      li:not(.back) {
        &.active {
          position: relative;
          color: #3a89ff;
          &:before {
            position: absolute;
            bottom: 2px;
            left: 50%;
            transform: translateX(-50%);
            content: "";
            width: 40px;
            height: 3px;
            background: #3a89ff;
            border-radius: 2px;
          }
        }
      }

      .options-contain {
        position: absolute;
        right: 50px;
        top: 50%;
        transform: translateY(-50%);
        color: #aed8ff;
        font-size: 14px;
        ul {
          position: absolute;
          top: 26px;
          right: 0%;
          background-color: #bec5d5;
          border: 1px solid #999;
          width: 100px;
          padding: 10px 0;
          box-sizing: border-box;
          border-radius: 8px;
          li {
            text-align: center;
            font-size: 14px;
            color: #333;
            line-height: 30px;
            &:hover {
              color: #2362d5;
            }
          }
        }
      }
    }
    ul.second-cate {
      height: 44px;
      padding-left: 20px;
      background: #bec5d5;
      li {
        font-size: 14px;
        color: #1a1a21;
        padding: 0 10px;
        cursor: pointer;
        margin-right: 16px;
        &.active {
          height: 28px;
          background: #dde0e9;
          border-radius: 18px;
        }
      }
    }
  }

  .contain {
    height: calc(100vh - 92px);
    background: linear-gradient(179deg, #8a95b0 0%, #abb2c5 100%);
    padding: 10px;
    box-sizing: border-box;
    .content {
      height: 100%;
      overflow-y: auto;
      border-radius: 4px;
      background: #bec5d5;
      padding: 10px 15px;
      box-sizing: border-box;
    }
  }
}
</style>
