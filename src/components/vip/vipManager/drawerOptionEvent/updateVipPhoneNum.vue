<template>
  <!-- 更改/绑定会员手机号 -->
  <div class="step-four step-one">
    <div class="form-grid">
      <div class="row">
        <div class="label">会员卡号：</div>
        <div class="value">{{vipInfo.card_no}}</div>
      </div>
      <div class="row">
        <div class="label">姓名：</div>
        <div class="value">{{vipInfo.name || '---'}}</div>
      </div>
      <div class="row">
        <div class="label">绑定手机：</div>
        <div class="value">{{vipInfo.bind_phone || '---'}}</div>
      </div>
      <div class="row">
        <div class="label">联系手机：</div>
        <div class="value">{{vipInfo.contact_phone || '---'}}</div>
      </div>
      <div class="row">
        <div class="label">储蓄余额：</div>
        <div class="value">{{vipInfo.val_bal}}</div>
      </div>
      <div class="row">
        <div class="label">赠送余额：</div>
        <div class="value">{{vipInfo.free_bal}}</div>
      </div>
      <!-- <div class="row">
        <div class="label">剩余积分：</div>
        <div class="value">1000</div>
      </div>-->
    </div>
    <div class="content">
      <div class="form">
        <div class="row" layout="row" layout-align="start center">
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
        <div class="row" layout="row" layout-align="start center">
          <div class="label">
            <span class="red">*</span>
            <span>验证码:</span>
          </div>
          <div class="value">
            <el-input v-model="validateVal" size="small" style="width:284px" placeholder="请输入验证码"></el-input>
          </div>
        </div>
        <div v-if="!currentItemInfo.bp" class="row" layout="row" layout-align="start center">
          <div class="label">
            <span>订阅短信类型:</span>
          </div>
          <div class="value">
            <el-checkbox v-model="item.checked" v-for="item in messageList" :key="item.id">{{item.n}}</el-checkbox>
          </div>
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
      vipInfo: {},
      timer: null,
      count: 60, // 验证码倒计时
      phoneNum: "",
      validateVal: "",
      messageList: []
    };
  },
  methods: {
    async getVipInfo() {

      this.interValHandle()

      const params = {
        id: this.currentItemInfo.id * 1 //   int64   会员卡Id
      };
      try {
        if (this.currentItemInfo.bp) {
          // 更换手机号
          const res = await api_vip.reqVipCardGetVNodeCard(params);
          if (res.code == 1) {
            this.vipInfo = res.data || {};
            this.phoneNum = '';
          } else {
            this.$message.warning(res.msg);
          }
        } else {
          // 绑定手机号
          const res = await api_vip.reqUGetVipCardInfoFromBindPhoneNum(params);
          if (res.code == 1) {
            this.vipInfo = res.data.card_info || {};
            this.phoneNum = '';
            res.data.reg_sms_types = res.data.reg_sms_types || []
            this.messageList = (res.data.sms_types || []).map(item => ({
              ...item,
              checked: res.data.reg_sms_types.includes(item.id)
            }))
          } else {
            this.$message.warning(res.msg);
          }
        }
      } catch (error) {
        console.log("获取会员信息失败", error);
      }
    },

    interValHandle() {
      const storageSecondCount = this.$sessionStorage.getItem("secondCount"); // 获取发送短信时的时间戳
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
        t: this.vipInfo.bind_phone ? 102 : 103, //  int   操作类型 101 创建记名卡 102 会员卡修改绑定手机 103 会员卡绑定手机
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
  created() {
    this.getVipInfo();
  },
  props: {
    currentItemInfo: {
      default: {}
    }
  },
  computed: {
    btnText() {
      return this.count == 60 ? "发送验证码" : this.count + "s后发送";
    }
  },
  watch: {
    phoneNum: {
      handler() {
        this.$emit("updateInfoHandle", {
          phoneNum: this.phoneNum,
          validateVal: this.validateVal,
          messageList: this.messageList
        });
      },
      immediate: true
    },
    validateVal: {
      handler() {
        this.$emit("updateInfoHandle", {
          phoneNum: this.phoneNum,
          validateVal: this.validateVal,
          messageList: this.messageList
        });
      },
      immediate: true
    },
    messageList: {
      handler() {
        this.$emit("updateInfoHandle", {
          phoneNum: this.phoneNum,
          validateVal: this.validateVal,
          messageList: this.messageList
        });
      },
      immediate: true,
      deep: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/vip/vipBtn.less";
@import "../../../../style/vip/drawerManager/stepOne.less";
@import "../../../../style/vip/drawerManager/stepFour.less";
</style>