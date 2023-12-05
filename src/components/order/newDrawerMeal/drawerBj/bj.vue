<template>
  <div class="bj">
    <div class="coll" layout="row" layout-align="center center">
      <div class="label">
        <span class="label-red">*</span>
        <span class="label-title">关联日期：</span>
      </div>
      <div class="value">
        <el-select v-model="dateValue" size="small" placeholder="请选择日期">
          <el-option v-for="item in dateOptions" :key="item.label" :label="item.label" :value="item.label">
          </el-option>
        </el-select>
      </div>
    </div>
    <div class="coll" layout="row" layout-align="center center">
      <div class="label">
        <span class="label-red">*</span>
        <span class="label-title">卡台流水：</span>
      </div>
      <div class="value">
        <span class="card fs12 m-r-3" v-if="cardInfo.id && orderInfo.id">{{
          orderInfo.n
        }}</span>
        <span class="primary-link cursor" style="font-size: 20px;"  @click="$emit('changeStatus', 2)">{{ cardInfo.id && orderInfo.id ? "更改" :
          "选择卡台流水" }}</span>
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
.bj {

  // color: rgba(255, 255, 255, 0.8);
  .label-red {
    font-size: 20px;
    font-family: PingFangSC, PingFang SC;
    font-weight: 400;
    color: #D44F44;
  }

  .label-title {
    font-size: 20px;
    font-family: PingFangSC, PingFang SC;
    font-weight: 400;
    color: #08080A;
  }

  .coll {
    padding-top: 20px;

    .label {
      width: 120px;
      text-align: right;
      margin-right: 20px;
    }

    .value {
      width: 200px;

      .card {
        padding: 4px 16px;
        border: 1px solid #ccc;
        border-radius: 8px;
      }
    }
  }
}

/deep/ .el-input {
  input {
    width: 300px;
    height: 44px;
    background: #FAFAFC;
    font-size: 20px;
    color: #08080A;
  }
}

/deep/ .el-select-dropdown__empty {
  background-color: #92a5cf !important;
}

/deep/ .el-scrollbar .el-scrollbar__view.el-select-dropdown__list {
  background-color: #92a5cf !important;
}

/deep/ .el-picker-panel {
  background-color: #92a5cf !important;
}

/deep/ .el-select-dropdown__item {
  color: #111;
}
</style>
<!-- <style>
/* 下拉框 */
.el-select-dropdown__empty {
  background-color: #92a5cf !important;
}

.el-scrollbar .el-scrollbar__view.el-select-dropdown__list {
  background-color: #92a5cf !important;
}

.el-picker-panel {
  background-color: #92a5cf !important;
}

.el-select-dropdown__item {
  color: #111;
}
</style> -->
