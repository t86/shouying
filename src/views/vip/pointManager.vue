<template>
  <div class="vip vip-manager">
    <h3 class="title">积分管理</h3>
      <div class="row">
        <span>充值送积分：</span>
        <el-switch 
              class="m-l-2"
              v-model="form.rechargePointEnabled"
              active-color="#409EFF">
            </el-switch>
      </div>
      <div class="row m-t-4">
        <span class="m-r-2">充值</span>
        <el-input
          class="m-r-2"
          v-model="form.amount"
          size="small"
          placeholder="输入整数"
          type="number"
          style="width: 100px"
          @keyup.native="
            (e) => {
              showMessage(e);
              form.amount = inputLimitPositiveNum(e.target.value);
            }
          "
          @blur="
            (e) => {
              form.amount = formatPointNumber(e.target.value);
            }
          "
        ></el-input>
        <span>元送1积分</span>
          </div>

      <div class="row m-t-4">
        <span style="color: red">说明: 不足的部分不会赠送，例如设置10元赠送1积分，充值999元则赠送99积分</span>
      </div>

      <button class="btn primary m-l-4 m-t-4" @click="save">保存</button>
  </div>
</template>

<script>
import api_vip from "@/api/vip";
import { inputLimitPositiveNum, formatPointNumber } from "@/utils/formatNumber";
export default {
  data() {
    return {
      form: {
        rechargePointEnabled: false,
        amount: "",
        inputLimitPositiveNum, 
        formatPointNumber
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
    async save(){
      try {
        const params = {
          type_id: this.form.rechargePointEnabled? 2 : 1,
          base_amt: this.form.amount * 1,
        }
        const res = await api_vip.reqSavePointRule(params);
        if (res.code == 1) {
          this.$message.success('保存成功')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("保存规则失败", error);
      }
    } 
  },
  created() {

  },
  components: {
   
  },
  watch: {
 
  },
};
</script>

<style lang="less" scoped>
@import "../../style/vip/vip.less";
@import "../../style/vip/vipBtn.less";
@import "../../style/vip/pointManager.less";
</style>

<style>
.el-select-dropdown__empty {
  background-color: #bec5d5 !important;
}
.el-scrollbar .el-scrollbar__view.el-select-dropdown__list {
  background-color: #bec5d5 !important;
}

.el-picker-panel {
  background-color: #bec5d5 !important;
}

/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}
.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}
</style>
<style scoped>
.el-select-dropdown__item {
  color: #1a1a21;
  font-size: 14px;
}
.el-select-dropdown__item.hover,
.el-select-dropdown__item:hover {
  background-color: rgba(90, 90, 90, 0.5) !important;
}
</style>
