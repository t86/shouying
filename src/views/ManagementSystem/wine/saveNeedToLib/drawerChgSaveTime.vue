<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="60%"
      append-to-body
    >
      <div class="session p-3 fs14">
        <!-- 头部筛选项 -->
        <div class="select-top" layout="col" style="width: 100%;">
          <div class="item" layout="row" layout-align="start center">
            <div class="reqfieldsd">*</div>
            <div class="label m-r-4">存酒时间:</div>
            <el-date-picker
              v-model="datetime"
              type="datetime"
              format="yyyy/MM/dd HH:mm:ss"
              value-format="yyyy/MM/dd HH:mm:ss">
            </el-date-picker>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button size="small" type="info" @click.stop="closeDrawerHandle">取消</el-button>
        <el-button type="primary" size="small" @click="submitHandle">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>

export default {
  data() {
    return {
      show: false,
      // 筛选条件
      datetime: "",
    };
  },
  methods: {
    validator() {
      if (this.datetime == "") {
        this.$message.warning("请输入存酒时间")
        return false
      }
      return true
    },
    async submitHandle() {
      if(!this.validator()) return
      this.$emit("onSubmit", {
          time: this.datetime
      });
    },
    // 关闭drawer
    closeDrawerHandle() {
      this.$emit("showOrHideDrawerHandle");
    }
  },
  props: {
    showDrawer: {
      default: false
    },
    item: {}
  },
  computed: {
    title() {
      return "更改存酒时间" 
    },

  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.datetime = this.item.t
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "./drawerchg.less";
@import "../../../../style/wine/table.less";
</style>
<style>
.reqfieldsd {
  font-size: 16px;
  padding-right: 4px;
  color: #ce4153;
  /* 文字不可选中 */
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.el-icon-arrow-right:before {
  color: #606266;
}

/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}
.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}
.el-range-editor--small .el-range-input {
  background-color: transparent;
}

.el-picker-panel__footer {
  background-color: #eaecf3;
  border: 1px solid #838786
}
.el-button--default {
  background-color: #fff;
}
</style>
