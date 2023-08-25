<template>
  <div>
    <!-- 未支付订单选择支付渠道授权页面drawer -->
    <el-drawer
      title="授权"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      append-to-body
      direction="rtl"
      size="60%"
    >
      <div class="auth-content" layout="row" layout-align="center start">
        <div class="auth-content-left">
          <p>抹零金额</p>
          <p class="amt">￥{{(amt*1).toFixed(2)}}</p>
        </div>
        <div class="auth-content-right">
          <authorization
            ref="authorization"
            :authorizationInfo="{userName,passWord}"
            @updateAuthorizationInfo="updateAuthorizationInfo"
          />
        </div>
      </div>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <!-- <el-button type="primary" @click="onSubmit">自己授权</el-button>   -->  
        <!-- 暂时不支持抹零操作的自己授权 -->
        <el-button type="primary" @click="onSubmit">确认</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import eventVue from '@/utils/eventVue';
import api_money from "@/api/money";
import authorization from "@/components/order/shoppingCart/authorization";
import md5 from "js-md5";
export default {
  data() {
    return {
      show: false,
      userName: "",
      passWord: ""
    };
  },
  methods: {
    closeDrawerHandle() {
      this.$emit("showOrHideDrawer");
    },

    onCancelDrawer() {
      this.closeDrawerHandle();
    },

    updateAuthorizationInfo({ key, value }) {
      this[key] = value;
    },

    // 刷卡授权
    swipingOrderHandle(empCardInfo){
      if(this.show) {
        const childrenVNode = this.$children[0].$children || []
        childrenVNode.forEach(el => {
          if(el.$el.className == 'auth') {
            if(el.tabIndex == 1) {
              // 刷卡
              this.onSubmit(empCardInfo, 2)
            } else {
              this.$message.warning('当前为输入账号授权，不可刷卡')
            }
          }
        })
      } else {
        this.$message.warning('刷卡无效，请在登录或授权时进行刷卡！')
      }
    },

    async onSubmit(empInfo={}, type=1) {
      const authEmpCode = type == 1 ? this.userName : empInfo.cardNo
      const authEmpPwd = type == 1 ? this.passWord : empInfo.password
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64   卡台Id
        pay_cnl_id: 10, // int     支付渠道Id, 目前只支持抹零, =10
        pay_amt: this.amt.toString(), //    string   支付金额
        auth_emp_code: authEmpCode, // string   授权人工号
        auth_emp_passwd: md5(authEmpPwd)
          .toString()
          .toUpperCase(), // string   授权人密码
        pass_type : type  // 1:账号密码， 2：刷卡
      };

      try {
        const res = await api_money.reqAddShoppingFromZero(params);
        if (res.code === 1) {
          this.$message.success("加入成功");
          this.$emit("getChoosePayList");
          this.userName = "";
          this.passWord = "";
          this.closeDrawerHandle();
        } else {
          window.loopReadCard()
          this.$message.warning(res.msg);
        }
      } catch (error) {
        window.loopReadCard()
        console.log("人工授权加入购物车失败", error);
      }
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    // 抹零金额
    amt: {
      default: 0
    },
    orderId: {
      default: ""
    }
  },
  components: {
    authorization
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        eventVue.$off('moneyPayOrderHandle')
        eventVue.$on('moneyPayOrderHandle', empCardInfo => { this.swipingOrderHandle(empCardInfo) })
        // moneyPayOrderHandle
        this.userName = "";
        this.passWord = "";
        this.$refs.authorization.tabIndex = 1;
      } else {
        window.stopLoopReadCard()
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style//money/drawerPayMoneyAuth.less";
</style>