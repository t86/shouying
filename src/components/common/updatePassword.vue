<template>
  <div>
    <el-drawer
      title="修改密码"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      append-to-body
      direction="rtl"
      size="50%"
    >
      <el-form style="margin-top:40px" label-position="right" label-width="150px" ref="drawerRef" @submit.native.prevent>
        <el-form-item label="原密码">
          <el-input v-model="form.old_password"
          type="password" placeholder="请输入原密码"
          style="width:250px;margin:0 10px" size="small"></el-input>
       </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="form.new_password"
          type="password" placeholder="请输入新密码"
          style="width:250px;margin:0 10px" size="small"></el-input>
        </el-form-item>
        <el-form-item label="确认新密码" style="margin-bottom:40px">
          <el-input v-model="form.rnew_password"
          type="password" placeholder="请确认新密码"
          style="width:250px;margin:0 10px" size="small"></el-input>
        </el-form-item>

        <keyBoard @changeNum="changeNum" />

        <!-- 提交按钮 -->
        <div class="form-btn" layout="row" layout-align="center center">
          <el-button type="info" @click="closeDrawerHandle">取消</el-button>
          <el-button type="primary" @click="onSubmit">确认</el-button>
        </div>
      </el-form>
    </el-drawer>
  </div>
</template>

<script>
import keyBoard from "./keyBoard.vue";
const checkInfo = {
  1: "old_password",
  2: "new_password",
  3: "rnew_password"
};
export default {
  data() {
    return {
      show: false,
      checkedIndex: 1, // 选中的输入类型 1：username 2：password
      form: {
        old_password: "",
        new_password: "",
        rnew_password: ""
      }
    };
  },
  methods: {
    changeNum(id) {
      if (id == 10) {
        // 清空
        this.form[checkInfo[this.checkedIndex]] = "";
      } else if (id == 12) {
        // 回退
        const result = this.form[checkInfo[this.checkedIndex]].split("");
        result.splice(this.form[checkInfo[this.checkedIndex]].length - 1, 1);
        this.form[checkInfo[this.checkedIndex]] = result.join("");
      } else {
        this.form[checkInfo[this.checkedIndex]] = [
          ...this.form[checkInfo[this.checkedIndex]].split(""),
          id
        ].join("");
      }
    },
    closeDrawerHandle() {
      this.$emit("cancelUpdatePwdHandle");
    },

    onSubmit() {
      this.$emit("submitHandle", this.form);
    }
  },
  mounted() {},
  components: {
    keyBoard
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.form = {
          old_password: "",
          new_password: "",
          rnew_password: ""
        };
        this.checkedIndex = 1
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>

<style lang="less" scoped>
.val {
  width: 80%;
  height: 36px;
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 8px;
  color: rgba(255, 255, 255, 0.3);
  padding: 0 10px;
  box-sizing: border-box;
  line-height: 36px;
  background: rgba(0, 0, 0, 0.2);
  cursor: pointer;
  &.text {
    color: rgba(255, 255, 255, 0.8);
    line-height: 40px;
    letter-spacing: 2px;
  }
  &.active {
    border-color: #32b9ff;
    box-shadow: 0px 0px 8px 0px rgba(26, 137, 255, 0.8);
  }
}
</style>
