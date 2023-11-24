<template>
  <div>
    <el-drawer title="授权密码" :visible.sync="show" :before-close="closeDrawerHandle" append-to-body direction="rtl"
      size="50%">
      <el-form style="margin-top:20px" label-position="right" label-width="150px" ref="drawerRef" @submit.native.prevent>
        <el-form-item label="开启授权密码">
          <el-switch v-model="form.show"></el-switch>
        </el-form-item>
        <el-form-item v-show="form.show" label="登录密码">
          <div class="val" :class="{ 'active': checkedIndex == 1, 'text': form.loginPwd }" @click="checkedIndex = 1">
            {{ form.loginPwd ? form.loginPwd.replace(/\d/g, '*') : '请输入登录密码' }}</div>
        </el-form-item>
        <el-form-item v-show="form.show" label="授权密码">
          <div class="val" :class="{ 'active': checkedIndex == 2, 'text': form.authPwd }" @click="checkedIndex = 2">{{
            form.authPwd
            ? form.authPwd.replace(/\d/g, '*') : '请输入授权密码' }}</div>
        </el-form-item>
        <el-form-item v-show="form.show" label="确认授权密码" style="margin-bottom:40px">
          <div class="val" :class="{ 'active': checkedIndex == 3, 'text': form.repAuthPwd }" @click="checkedIndex = 3">
            {{ form.repAuthPwd ? form.repAuthPwd.replace(/\d/g, '*') : '请确认授权密码' }}</div>
        </el-form-item>

        <keyBoard v-show="form.show" @changeNum="changeNum" />

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
import api_order from "@/api/order";
import keyBoard from "@/components/common/newKeyBoard";
const checkInfo = {
  1: "loginPwd",
  2: "authPwd",
  3: "repAuthPwd"
};
export default {
  data() {
    return {
      show: false,
      checkedIndex: 1, // 选中的输入类型 1：username 2：password
      form: {
        show: false, // 是否开启
        loginPwd: "", // 登录密码
        authPwd: "", // 授权密码
        repAuthPwd: "" // 再次验证授权密码
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

    // 读取授权密码是否开启
    async getAuthStatus() {
      try {
        const res = await api_order.reqGetAuthStatus();
        if (res.code == 1) {
          this.form.show = res.data.enabled == 1;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("读取授权密码开启状态失败", error);
      }
    },
    closeDrawerHandle() {
      this.$emit("cancelUpdatePwdHandle");
    },

    onSubmit() {
      this.$emit("submitHandle", this.form);
    }
  },
  mounted() { },
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
          show: false, // 是否开启
          loginPwd: "", // 登录密码
          authPwd: "", // 授权密码
          repAuthPwd: "" // 再次验证授权密码
        };
        this.checkedIndex = 1
        this.getAuthStatus()
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/common/newElementDrawer.less";
@import "../../style/common/newElementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>

<style lang="less" scoped>
.val {

  border-radius: 8px;
  padding: 0 10px;
  box-sizing: border-box;
  width: 266px;
  height: 44px;
  background: #FFFFFF;
  border-radius: 8px;
  border: 1px solid #C4CBD7;
  cursor: pointer;
  font-size: 20px;
  color: #7A7A7A;

  &.text {
    color: #080808;
    letter-spacing: 2px;
  }

  &.active {

    border: 2px solid #3373E8;
    position: relative;
  }
}

/deep/.el-switch__core {
  background-color: #606882;
}

/deep/ .el-switch.is-checked .el-switch__core {

  background: #3373E8;
}

/deep/ .el-drawer .el-form .form-btn button {
    margin-top: 0px !important;
}
</style>
