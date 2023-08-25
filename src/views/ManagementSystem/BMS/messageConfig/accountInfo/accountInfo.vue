<template>
  <div class="account-info">
    <div class="info">
      <h3 class="m-b-6 m-t-3">基本信息</h3>
      <div class="bx">
        <div class="coll p-t-2 p-b-2" layout="row" layout-align="start center">
          <div class="label">客户名称：</div>
          <div class="value">{{info.n}}</div>
        </div>
        <div class="coll p-t-2 p-b-2" layout="row" layout-align="start center">
          <div class="label">账户余额：</div>
          <div class="value">{{info.b}}</div>
        </div>
        <div class="coll p-t-2 p-b-2" layout="row" layout-align="start center">
          <div class="label">剩余短信条数：</div>
          <div class="value">{{info.c}}</div>
        </div>
        <div class="coll p-t-2 p-b-2" layout="row" layout-align="start center">
          <div class="label">最近充值金额：</div>
          <div class="value">{{info.ld}}</div>
        </div>
        <div class="coll p-t-2 p-b-2" layout="row" layout-align="start center">
          <div class="label">最近充值日期：</div>
          <div class="value">{{info.lt}}</div>
        </div>
        <div class="coll p-t-2 p-b-2" layout="row" layout-align="start center">
          <div class="label">当前状态：</div>
          <div class="value">{{info.s}}</div>
        </div>
        <div class="coll p-t-2 p-b-2" layout="row" layout-align="start center">
          <div class="label">开通状态：</div>
          <div class="value">{{info.o}}</div>
        </div>
      </div>
    </div>

    <div class="info p-t-3">
      <h3 class="m-b-6 m-t-6">短信自查</h3>
      <div class="bx">
        <div class="coll p-t-2 p-b-2" layout="row" layout-align="start center">
          <div class="label">自查手机号：</div>
          <div class="value m-r-3">
            <el-input placeholder="请输入手机号" v-model="phoneNum"></el-input>
          </div>
          <el-button type="primary" size="small" :disabled="btnDisabled" :class="{'disabled': btnDisabled}" @click="sendMsgHandle">{{btnText}}</el-button>
        </div>
      </div>
    </div>
   
  </div>
</template>
 
<script>
  export default {
    data() {
      return {
        info: {},
        phoneNum: '',
        btnText: '发送短信',
        btnDisabled: false
      }
    },
    methods: {
      async getData(){
        try {
          const res = await this.$api.BMS.messageConfig.reqGetAccountInfo()
          if(res.code == 1) {
            this.info = res.data || {}
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('数据请求失败', error);
        }
      },
      async sendMsgHandle(){
        const params = {
          mobile: this.phoneNum || '',  //  string    手机号
        }
        if(params.mobile.length != 11) return this.$message.warning('请输入11位手机号')
        try {
          const res = await this.$api.BMS.messageConfig.reqMsgSend(params)
          if(res.code == 1) {
            this.setTime()
            this.$message.success('发送成功')
          } else {
            this.$message.warning(res.msg)
          }
        } catch (error) {
          console.log('数据请求失败', error);
        }
      },

      setTime(){
        const now = +new Date()
        localStorage.setItem('currentTime', now.toString())
        this.loopHandle(0)
      },

      loopHandle(second = 1000) {
        clearTimeout(this.timer)
        this.timer = setTimeout(() => {
          const now = +new Date()
          const dis = now - (localStorage.getItem('currentTime') || 0)
          let result = (60 - (dis / 1000)).toFixed(0)
          if(result > 0) {
            this.btnText = result + '秒后发送'
            this.btnDisabled = true
            this.loopHandle()
          } else {
            clearTimeout(this.timer)
            this.btnText = '发送短信'
            this.btnDisabled = false
          }
        }, second);
      }
    },
    created() {
      this.loopHandle(0)
      this.getData()
    },
    mounted() {
 
    },
    props: {
 
    },
    components: {
 
    },
    filters: {
 
    }
  }
 
</script>

<style scoped lang='less'>
.account-info {
  padding: 20px;
  .info {
    padding-left: 30px;
    .coll {
      font-size: 15px;
      padding-left: 50px;
      .label {
        width: 120px;
        text-align: right;
      }
      .value {
        padding-left: 10px;
      }
    }
  }

  .disabled{
    background: #c5c3c3;
    border-color: #c5c3c3;
  }
}
</style>