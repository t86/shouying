<template>
  <!-- 扣款 -->
  <div class="step-four step-one">
    <div class="form-grid">
      <div class="row">
        <div class="label">会员卡号：</div>
        <div class="value">{{ vipInfo.card_no }}</div>
      </div>
      <div class="row">
        <div class="label">姓名：</div>
        <div class="value">{{ vipInfo.name || '---' }}</div>
      </div>
      <div class="row">
        <div class="label">绑定手机：</div>
        <div class="value">{{ vipInfo.bind_phone || '---' }}</div>
      </div>
      <div class="row">
        <div class="label">联系手机：</div>
        <div class="value">{{ vipInfo.contact_phone || '---' }}</div>
      </div>
      <div class="row">
        <div class="label">储蓄余额：</div>
        <div class="value">{{ vipInfo.val_bal }}</div>
      </div>
      <div class="row">
        <div class="label">赠送余额：</div>
        <div class="value">{{ vipInfo.free_bal }}</div>
      </div>
      <div class="row">
        <div class="label">积分余额：</div>
        <div class="value">{{ vipInfo.pt_bal || 0 }}</div>
      </div>
    </div>
    <div class="content">
      <div class="form">
        <div class="row" layout="row" layout-align="start center">
          <div class="label">
            <span>扣款类型:</span>
          </div>
          <div class="value" layout="row" layout-align="start center">

            <el-radio-group v-model="form.subType" @change="onSubTypeChange"> 
              <el-radio label="1">业务扣款</el-radio>
              <el-radio label="2">充错扣款</el-radio>
            </el-radio-group>

          </div>
        </div>
        <div class="row" layout="row" layout-align="start center">
          <div class="label">
            <span style="color:#E0304F">*</span>
            <span>储值金额:</span>
          </div>
          <div class="value">
            <el-input v-model="form.addAmt" size="small" style="width:284px" placeholder="请输入储值金额"
              @input="onAddAmtChange"></el-input>
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
        <div class="row" layout="row" layout-align="start center">
          <div class="label">
            <span>{{ form.subType == "1" ? '本次消费赠送积分:' : '扣除积分' }}</span>
          </div>
          <div class="value">
            <div v-if="form.subType == '1'">
              {{ vipInfo.consume_base_amt == 0 ? '---' : form.point || 0 }}
            </div>
            <div v-else>
              <el-input v-model="form.point" size="small" style="width:284px" placeholder="请输入扣除积分" type="number"
              @input="onPointChange"></el-input>
            </div>

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
        zSAmt: '',
        point: 0,
        kkAmt: 0,
      }
    };
  },
  methods: {
    showMessage(e) {
      let value = e.target.value;
      if (value && value.indexOf(".") > -1) {
        this.$message.warning("请输入正整数");
      }
    },
    async getVipInfo() {

      this.resetHandle()

      const res = await api_vip.reqGetMbCardCsmPtRule({
        id: this.currentItemInfo.id * 1
      });
      if (res.code == 1) {
        // 充值赠送积分
        if(res.data.type_id == 2) {
          this.form.kkAmt = res.data.base_amt
        }
      } else {
        this.$message.warning(res.msg);
      }

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
    resetHandle() {
      this.form = {
        subType: '1',
        addAmt: '',
        zSAmt: '',
        point: 0,
        kkAmt: 0
      }
    },
    onAddAmtChange(e) {
      if (e && e > 0) {
        if (this.form.subType == '1') {
          if (this.vipInfo.consume_base_amt == 0) {
            this.form.point = 0;
          } else {
            const num = e * 1 / this.vipInfo.consume_base_amt;
            this.form.point = Math.floor(num) || 0;
          }
        } else if (this.form.subType == '2') {
          if (this.form.kkAmt == 0) {
            this.form.point = 0;
          } else {
            const num = e * 1 / this.form.kkAmt;
            this.form.point = Math.floor(num) || 0;
          }
          if(this.form.point > this.vipInfo.pt_bal){
              this.form.point = this.vipInfo.pt_bal || 0;
              this.$message.warning("积分余额不足") 
          }
        }
      } else {
        this.form.point = 0;
      }
    },
    onSubTypeChange(){
      this.form.addAmt = '';
      this.form.zSAmt = '';
      this.form.point = 0;
    },
    onPointChange(value){
      if(value < 0){
        this.form.point = 0
        this.$message.warning("积分最小为0")
      }
      if(value> this.vipInfo.pt_bal){
        this.form.point = this.vipInfo.pt_bal;
        this.$message.warning("积分余额不足") 
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