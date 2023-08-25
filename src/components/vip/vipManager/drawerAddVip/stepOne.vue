<template>
  <div class="step-one">
    <div class="form">
      <div class="row" layout="row" layout-align="start start">
        <div class="label">
          <span>卡属性:</span>
        </div>
        <div class="value">
          <el-radio v-model="radioVal" label="1">记名卡</el-radio>
          <el-radio v-model="radioVal" label="2">不记名卡</el-radio>
          <div class="tips">不记名卡必须制卡后才能正常使用</div>
        </div>
      </div>
      <div v-if="radioVal==1" class="row" layout="row" layout-align="start center">
        <div class="label">
          <span class="red">*</span>
          <span>手机号:</span>
        </div>
        <div class="value" layout="row" layout-align="start center">
          <el-input v-model="phoneNum" size="small" style="width:284px" placeholder="请输入手机号"></el-input>
          <button
            class="btn primary m-l-2"
            :class="{'disabled': count != 60}"
            style="width:100px;height:30px"
            @click="sendPhoneMessage"
          >{{btnText}}</button>
        </div>
      </div>
      <div v-if="radioVal==1" class="row" layout="row" layout-align="start center">
        <div class="label">
          <span class="red">*</span>
          <span>验证码:</span>
        </div>
        <div class="value">
          <el-input v-model="validateVal" size="small" style="width:284px" placeholder="请输入验证码"></el-input>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      timer: null,
      count: 60, // 验证码倒计时
      radioVal: "1",
      phoneNum: "",
      validateVal: ""
    };
  },
  methods: {
    init() {
      if (this.stepOneInfo.radioVal) {
        this.radioVal = this.stepOneInfo.radioVal
        this.phoneNum = this.stepOneInfo.phoneNum
        this.validateVal = this.stepOneInfo.validateVal
      }
      this.interValHandle()
    },
    interValHandle(){
      const storageSecondCount = this.$sessionStorage.getItem("secondCount") || '';  // 获取发送短信时的时间戳
      const now = +new Date()
      const oneMinute = +new Date('2023/05/25 12:01:00') - +new Date('2023/05/25 12:00:00')
      if (now - storageSecondCount < oneMinute) {
        // 倒计时为结束接着倒计时
        this.count = ((oneMinute - (now - storageSecondCount)) / (oneMinute / 60)).toFixed(0) * 1;
        this.loopSecond();
      } else {
        this.count = 60;
      }
    },
    // 发送验证码
    async sendPhoneMessage() {
      if (this.count != 60) return;
      const params = {
        t: 101, //  int   操作类型 101 创建记名卡 102 会员卡修改绑定手机 103 会员卡绑定手机
        m: this.phoneNum //  string   手机号
      };
      if (params.m.length != 11)
        return this.$message.warning("请输入正确的11位手机号");
      try {
        const res = await api_vip.reqSendPhoneMsg(params);
        if (res.code == 1) {
          this.$message.success("验证码发送成功");
          this.count--
          this.loopSecond();
          this.$sessionStorage.setItem("secondCount", (+new Date()).toString());
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("发送验证码失败", error);
      }
    },

    // 倒计时
    loopSecond() {
      if (this.timer) clearInterval(this.timer);
      this.timer = setInterval(() => {
        this.count--;
        if (this.count == 0) {
          clearInterval(this.timer);
          this.count = 60;
        }
      }, 1000);
    }
  },
  mounted() {
    this.init();
  },
  props: {
    stepOneInfo: {
      default: {}
    }
  },
  computed: {
    btnText() {
      return this.count == 60 ? "发送验证码" : this.count + "s后发送";
    }
  },
  watch: {
    radioVal: {
      handler() {
        this.$emit("updateStepOneInfo", {
          radioVal: this.radioVal,
          phoneNum: this.phoneNum,
          validateVal: this.validateVal
        });
      },
      immediate: true
    },
    phoneNum: {
      handler() {
        this.$emit("updateStepOneInfo", {
          radioVal: this.radioVal,
          phoneNum: this.phoneNum,
          validateVal: this.validateVal
        });
      },
      immediate: true
    },
    validateVal: {
      handler() {
        this.$emit("updateStepOneInfo", {
          radioVal: this.radioVal,
          phoneNum: this.phoneNum,
          validateVal: this.validateVal
        });
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/vip/vipBtn.less";
@import "../../../../style/vip/drawerManager/stepOne.less";
</style>