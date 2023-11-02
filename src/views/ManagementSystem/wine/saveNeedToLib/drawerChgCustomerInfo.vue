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
          <div class="item m-b-10" layout="row" layout-align="start center">
            <div class="reqfieldsd">*</div>
            <div class="label m-r-4" style="width: 100px">手机号:</div>
            <el-input
              v-model="phone"
              style="width: 200px"
              placeholder="1-10个字符"
            ></el-input>
          </div>
          <div class="item" layout="row" layout-align="start center">
            <div class="reqfieldsd">*</div>
            <div class="label m-r-4" style="width: 100px">客人姓名:</div>
            <el-input
              v-model="name"
              style="width: 200px"
              placeholder="1-10个字符"
            ></el-input>
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
import { TimeSelect } from 'element-ui';

export default {
  data() {
    return {
      show: false,
      // 筛选条件
      name: "",
      phone: "",
    };
  },
  methods: {
    validator() {
      if (this.name == "") {
        this.$message.warning("请输入客人姓名")
        return false
      } else if (this.phone == "") {
        this.$message.warning("请输入手机号")
        return false
      } else if (this.$overall.character(this.name) > 20) {
        this.$message.warning("姓名太长，请确认是否正确")
        return false
      } else if (this.$overall.character(this.phone) != 11) {
        this.$message.warning("手机号长度异常，请确认是否正确")
        return false
      }
      return true
    },
    async submitHandle() {
      if(!this.validator()) return
      this.$emit("onSubmit", {
          name: this.name,
          phone: this.phone
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
      return "更改客人信息" 
    },

  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.name = this.item.c
        this.phone = this.item.p
      }
    }
  }
};
</script>

<style scoped lang="less">
@import '../../../../style/common/elementDrawerWine.less';
@import '../../../../style/common/elementDrawerHeaderAndSession.less';
@import '../../../../style/common/elementFormBtnWine.less';
@import '../../../../style/erp/form.less';
@import '../../../../style/erp/table.less';
</style>
<style scoped lang="less">
@import "./drawerchg.less";
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
</style>