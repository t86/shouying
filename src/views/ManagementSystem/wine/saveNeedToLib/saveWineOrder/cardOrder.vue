<template>
  <div class="bj">
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">
        <span class="red-color">*</span>
        <span class="fs14">营业日期：</span>
      </div>
      <div class="value">
        <el-select v-model="dateValue" size="small" placeholder="请选择日期">
          <el-option
            v-for="item in dateOptions"
            :key="item.label"
            :label="item.label"
            :value="item.label"
          >
          </el-option>
        </el-select>
      </div>
    </div>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">
        <span class="red-color">*</span>
        <span class="fs14">卡台流水：</span>
      </div>
      <div class="value">
        <span class="card fs12 m-r-3" v-if="cardInfo.id && orderInfo.id">{{
          orderInfo.n
        }}</span>
        <span
          class="primary-link cursor fs14"
          @click="$emit('changeStatus', 2)"
          >{{ cardInfo.id && orderInfo.id ? "更改" : "选择卡台流水" }}</span
        >
      </div>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {};
  },
  props: {
    cardInfo: {
      default: () => ({}),
    },
    orderInfo: {
      default: () => ({}),
    },
    dateOptions: {
      default: [],
    },
    value: "",
  },
  computed: {
    dateValue: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      },
    },
  },
};
</script>

<style scoped lang="less">
@import '../../../../../style/common/elementDrawerWine.less';
@import '../../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../../style/common/elementFormBtnWine.less';
@import '../../../../../style/erp/form.less';
@import '../../../../../style/erp/table.less';
@import "./../drawerchg.less";
.bj {
  color: #000000cc;

  .coll {
    padding-top: 20px;
    .label {
      width: 88px;
      text-align: left;
      margin-right: 20px;
    }
    .value {
      width: 250px;

      .card {
        padding: 4px 16px;
        border: 1px solid #ccc;
        border-radius: 8px;
      }
    }
  }
}
</style>
