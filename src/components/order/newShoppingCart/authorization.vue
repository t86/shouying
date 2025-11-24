<template>
  <div class="auth">
    <div class="tab">
      <div class="tab-top" layout="row" layout-align="center center">
        <span :class="{'active':tabIndex==1}" @click="tabIndex=1">刷卡</span>
        <span :class="{'active':tabIndex==2}" @click="tabIndex=2">账号密码</span>
      </div>
      <div class="tab-content">
        <div class="tab-content-item" v-if="tabIndex==1">
          <p class="tips">请刷卡</p>
        </div>
        <div class="tab-content-item" v-if="tabIndex==2">
          <div class="form">
            <input v-if="$store.state.userInfo.authStatus==4" ref="userNameRef" @input="inputHandle" @click="focusInput(1)" :class="{'active': checkedIndex==1}" class="username" placeholder="请输入员工号" v-model="userName"/>
            <div v-else @click="checkedIndex=1" :class="{'active': checkedIndex==1,'text':userName==''}" class="username">
              {{userName ? userName :
              '请输入员工号'}}
            </div>
            <br />
            <input v-if="$store.state.userInfo.authStatus==4" ref="passwordRef" @input="inputHandle" @click="focusInput(2)" :class="{'active': checkedIndex==2}" class="password" placeholder="请输入授权密码" v-model="passWord" type="password"/>
            <div 
              v-else
              @click="checkedIndex=2"
              :class="{'active': checkedIndex==2,'text':passWord==''}"
              class="password"
              layout="row"
              layout-align="start center"
            >
              <span v-if="!passWord">请输入授权密码</span>
              <span v-else>
                <span v-for="(item,i) in passWord" :key="i">*</span>
              </span>
            </div>
          </div>
          <keyBoard @changeNum="changeNum" />
        </div>
      </div>
    </div>
    <!-- 提交按钮 -->
    <div v-if="type!=0" class="form-btn" layout="row" layout-align="center center">
      <el-button type="info" @click.stop="onCancelDrawer">取消</el-button>
      <el-button v-if="showSelfBtn" type="primary" @click.stop="onSubmit('self')">自己授权</el-button>
      <el-button type="primary" @click.stop="onSubmit('another')">确认</el-button>
    </div>
  </div>
</template>
 
<script>
import api_order from "@/api/order";

import keyBoard from "@/components/common/newKeyBoard";

import md5 from "js-md5";
export default {
  data() {
    return {
      // 授权
      tabIndex: 1, // 1: 刷卡  2： 输入账号密码
      checkedIndex: 1, // 选中的输入类型 1：username 2：password
      userName: "",
      passWord: ""
    };
  },
  methods: {
    changeNum(id) {
      if (id == 10) {
        // 清空
        this.checkedIndex == 1 ? (this.userName = "") : (this.passWord = "");
      } else if (id == 12) {
        // 回退
        if (this.checkedIndex == 1) {
          const userName = this.userName.split("");
          userName.splice(this.userName.length - 1, 1);
          this.userName = userName.join("");
        } else {
          const passWord = this.passWord.split("");
          passWord.splice(this.passWord.length - 1, 1);
          this.passWord = passWord.join("");
        }
      } else {
        this.checkedIndex == 1
          ? (this.userName = [...this.userName.split(""), id].join(""))
          : (this.passWord = [...this.passWord.split(""), id].join(""));
      }
      if (this.type) return;
      this.emitData({ key: "userName", value: this.userName });
      this.emitData({ key: "passWord", value: this.passWord });
    },

    inputHandle(){
      this.emitData({ key: "userName", value: this.userName });
      this.emitData({ key: "passWord", value: this.passWord });
    },

    focusInput(type){
      if(type == 1) {
        this.$refs['userNameRef'].focus();
        this.checkedIndex = 1
      } else{
        this.$refs['passwordRef'].focus();
        this.checkedIndex = 2
      }
    },

    emitData({ key, value }) {
      this.$emit("updateAuthorizationInfo", { key, value });
    },

    onCancelDrawer() {
      this.$emit("closeDrawerHandle");
    },

    getCodeAndPwd(personType, empCardInfo, type){
      let authEmpCode = ''
      let authEmpPasswd = ''
      if(type == 1) {
        // 账号密码授权
        authEmpCode = personType == "self" ? "" : this.userName
        authEmpPasswd = personType == "self" ? "" : md5(this.passWord).toString().toUpperCase()
      } else {
        // 刷卡授权
        authEmpCode = empCardInfo.cardNo
        authEmpPasswd = md5(empCardInfo.password).toString().toUpperCase()
      }
      return {
        authEmpCode,
        authEmpPasswd
      }
    },

    async onSubmit(personType, empCardInfo={}, type = 1) {
      if (this.$route.name == 'shoppingCart' || this.$route.name == 'myOrder' || this.$route.name == 'payOrder') {
        // 优惠2批量授权提交订单
        const {authEmpCode, authEmpPasswd} = this.getCodeAndPwd(personType, empCardInfo, type)

        const params = {
          auth_emp_code: authEmpCode, // string   授权员工工号, 如果不传, 代表本账号授权
          auth_emp_passwd: authEmpPasswd, // string  授权员工密码
          auth_reason: this.formData.reason || '', // string   授权理由
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64   卡台Id
          // shopping_cart_ids:  this.productInfo.map(item => item.id * 1), // []int64   要优惠的购物车项Id列表
          ...this.$route.name == 'shoppingCart' 
            ? {shopping_cart_ids:  this.productInfo.map(item => item.id * 1)}
            : {order_ids:  this.productInfo.map(item => item.id * 1)},
          auth_cnts: this.productInfo.map(item => item.pc * 1), //  []int     优惠数量列表
          pass_type: type, //  int    1 验证 员工号/密码  2 验证卡号/卡数据 为兼容之前的账号密码认证, 当=2的时候验证卡号和卡密, 共用emp_code,password
          yh2_sales_emp_id: this.formData.sales.sales_emp_id * 1, // int64   优惠2订位人Id
          yh2_seat_id: this.formData.choosedCardInfo.seatId * 1, // int64    优惠2卡台Id
        };

        if (personType == "self") {
          params.auth_emp_code = "";
          params.auth_emp_passwd = "";
        } else {
          if (!params.auth_emp_code)
            return this.$message.warning("请输入员工号");
          if (!params.auth_emp_passwd)
            return this.$message.warning("请输入密码");
        }

        try {
          const res = this.$route.name == 'shoppingCart' ? await api_order.reqSetYhMany2Order(params) : await api_order.reqSetYhMany2OrderAtOrdered(params);
          if (res.code == 1) {
            this.$message.success("批量优惠2成功");
            this.onCancelDrawer();
            this.$emit('showOrHideAnotherDrawer')
            // 发出批量优惠2成功事件，用于触发自动下单
            if(this.$route.name == 'shoppingCart') {
              this.$emit('batchYH2Success')
              this.$parent.$parent.$parent.$parent.$parent.getShoppingCartData()
            }
            if(this.$route.name == 'myOrder') this.$parent.$parent.$parent.$parent.$parent.getOrderedData()
          } else {
            window.loopReadCard()
            this.$message.warning(res.msg);
          }
        } catch (error) {
          window.loopReadCard()
          console.log("购物车优惠2批量下单失败", error);
        }
      }
    }
  },
  props: {
    authorizationInfo: {
      // 需要将输入的值传入父组件或拿取父组件中的userName和passWord的值时为必传参数
      type: Object,
      default: () => ({
        userName: "",
        passWord: ""
      })
    },
    type: {
      // 0:没有用到提交按钮(需要把输入的参数传递给父组件)  3：点单小费、特饮、赔偿授权提交
      type: Number,
      default: 0
    },
    // 是否显示自己授权按钮
    showSelfBtn:{
      default: true
    },
    productInfo: {
      // 授权商品信息
      default:  () => ({
      })
    },
    formData: {
      default:  () => ({
      })
    },
    singleInfo: {
      // 授权商品信息
      default: () => {}
    }
  },
  components: {
    keyBoard
  },
  watch: {
    authorizationInfo(newVal) {
      this.userName = newVal && newVal.userName;
      this.passWord = newVal && newVal.passWord;
      if (this.userName == "" && this.passWord == "") this.checkedIndex = 1;
    },
    tabIndex:{
      handler(newVal) {
        if(newVal == 2) {
          window.stopLoopReadCard()
          this.$nextTick(() => {
            this.focusInput(1)
          })
        } else {
          console.log('auth readCard')
          window.loopReadCard()
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/order/orderMeal/newShoppingCart/authorization.less";
@import "../../../style/common/elementFormBtn.less";
</style>