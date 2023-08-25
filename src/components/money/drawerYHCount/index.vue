<template>
  <div>
    <!-- 查询优惠额度 -->
    <el-drawer
      :title=title
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      :size=size
    >
      <div class="YH">
        <authorization v-if="status == 1" :authorizationInfo="{userName,passWord}" @updateAuthorizationInfo="updateAuthorizationInfo" />
        <tableDetail v-if="status == 2" :resultInfo="resultInfo"/>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <!-- <el-button type="primary" v-if="status==1" @click="onSubmit('self')">自己授权</el-button> -->
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button v-if="status==1" type="primary" @click="onSubmit('another')">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import md5 from "js-md5";
import api_money from "@/api/money";
import eventVue from '@/utils/eventVue';
import authorization from '../../order/shoppingCart/authorization.vue'
import tableDetail from './tableDetail.vue'
export default {
  data() {
    return {
      show: false,
      status: 1,
      userName: "",
      passWord: "",
      resultInfo: {}
    };
  },
  methods: {
    changeStatus(status){
      this.status = status
    },

    updateAuthorizationInfo({ key, value }) {
      this[key] = value;
    },

        // 刷卡授权
    swipingOrderHandle(empCardInfo){
      if(this.show && this.status == 1) {
        const childrenVNode = this.$children[0].$children || []
        childrenVNode.forEach(el => {
          if(el.$el.className == 'auth') {
            if(el.tabIndex == 1) {
              this.onSubmit('another', empCardInfo, 2)
            } else {
              this.$message.warning('当前为输入账号授权，不可刷卡')
            }
          }
        })
      } else {
        this.$message.warning('刷卡无效，请在登录或授权时进行刷卡！')
      }
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

    async onSubmit(personType, empCardInfo={}, type=1){
      const {authEmpCode, authEmpPasswd} = this.getCodeAndPwd(personType, empCardInfo, type)
      const params = {
        auth_emp_code: authEmpCode, // string    授权人工号
        auth_emp_passwd: authEmpPasswd, // string    授权人密码
        pass_type: type, //  int   1 验证 员工号/密码  2 验证卡号/卡数据 为兼容之前的账号密码认证, 当=2的时候验证卡号和卡密, 共用emp_code,password
      }

      try {
        const res = await api_money.reqAuthYHCount(params)
        if(res.code == 1) {
          this.resultInfo = res.data || {}
          this.changeStatus(2)
        } else {
          window.loopReadCard()
          this.$message.warning(res.msg)
        }
      } catch (error) {
        window.loopReadCard()
        console.log('认证身份失败', error)
      }
    },
    
    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  computed: {
    title(){
      return this.status == 1 ? '授权' : '查询优惠额度'
    },
    size(){
      return this.status == 1 ? '60%' : '90%'
    }
  },
  components: {
    authorization,
    tableDetail
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if(newVal) {
        this.status = 1
        this.userName = ''
        this.passWord = ''
        // 监听刷卡
        window.loopReadCard()
        eventVue.$off('YHCount')
        eventVue.$on('YHCount', empCardInfo => { this.swipingOrderHandle(empCardInfo) })
      } else {
        window.stopLoopReadCard()
      }
    },
    status:{
      handler(newVal){
        if(newVal == 1) {
          // 监听刷卡
          eventVue.$off('YHCount')
          eventVue.$on('YHCount', empCardInfo => { this.swipingOrderHandle(empCardInfo) })
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
</style>
<style lang="less" scoped>

</style>