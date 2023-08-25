<template>
  <!-- 扣款 -->
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
            <span>扣款类型:</span>
          </div>
          <div class="value" layout="row" layout-align="start center">
            <el-radio v-model="form.subType" label="1">业务扣款</el-radio>
            <el-radio v-model="form.subType" label="2">充错扣款</el-radio>
          </div>
        </div>
        <div class="row" layout="row" layout-align="start center">
          <div class="label">
            <span style="color:#E0304F">*</span>
            <span>储值金额:</span>
          </div>
          <div class="value">
            <el-input v-model="form.addAmt" size="small" style="width:284px" placeholder="请输入储值金额"></el-input>
          </div>
        </div>
        <div class="row" layout="row" layout-align="start center">
          <div class="label">
            <span>赠送金额:</span>
          </div>
          <div class="value">
            <el-input v-model="form.zSAmt" size="small" style="width:284px" placeholder="请输入赠送金额"></el-input>
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
      form: {
        subType: '1',
        addAmt: '',
        zSAmt: ''
      }
    };
  },
  methods: {
    async getVipInfo() {

      this.resetHandle()

      const params = {
        id: this.currentItemInfo.id * 1 //   int64   会员卡Id
      };
      try {
          const res = await api_vip.reqVipCardGetVNodeCard(params);
          if (res.code == 1) {
            this.vipInfo = res.data || {};
            this.phoneNum = '';
          } else {
            this.$message.warning(res.msg);
          }
      } catch (error) {
        console.log("获取会员信息失败", error);
      }
    },
    resetHandle(){
      this.form = {
        subType: '1',
        addAmt: '',
        zSAmt: ''
      }
    }
  },
  props: {
    currentItemInfo: {
      default: {}
    }
  },
  watch: {
    form: {
      handler(newVal) {
        this.$emit("updateInfoHandle", newVal);
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