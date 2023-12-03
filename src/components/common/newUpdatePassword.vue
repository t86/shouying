<template>
  <div>
    <el-drawer title="修改密码" :visible.sync="show" :before-close="closeDrawerHandle" append-to-body direction="rtl"
      size="50%">

      <el-form style="margin-top:40px" label-position="right" label-width="150px" ref="drawerRef" @submit.native.prevent
        class="val">
        <el-form-item label="原密码">
          <div @click="checkedIndex = 1">
            <el-input v-model="form.old_password" type="password" placeholder="请输入原密码"></el-input>
          </div>
        </el-form-item>
        <el-form-item label="新密码">
          <div @click="checkedIndex = 2">
            <el-input v-model="form.new_password" type="password" placeholder="请输入新密码"></el-input>
          </div>
        </el-form-item>
        <el-form-item label="确认新密码" style="margin-bottom:40px">
          <div @click="checkedIndex = 3">
            <el-input v-model="form.rnew_password" @click="checkedIndex = 3" type="password"
              placeholder="请确认新密码"></el-input>
          </div>
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
import keyBoard from "@/components/common/newKeyBoard";
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
@import "../../style/common/newElementDrawer.less";
@import "../../style/common/newElementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>

<style lang="less" scoped>
.val {
  /deep/ .el-input {
    width: 266px;
    height: 44px;
    background: #FAFAFC;
    border-radius: 8px;
    border: 1px solid #C4CBD7;

    input {
      height: 44px;
      font-size: 20px;
      font-family: PingFangSC, PingFang SC;
      font-weight: 400;
      color: #080808;
      background: #FAFAFC;
      border-radius: 8px;
      resize: none;
      caret-color: #3373E8 !important;

      &::placeholder {
        color: #7A7A7A;
      }
    }


  }

  /deep/ .el-input__inner:focus {
    // box-shadow: 0 0 0 2px #3373E8 !important; /* 可选的光标外发光效果 */
    border: 2px solid #3373E8 !important;
  }


}

/deep/ .el-drawer .el-form .form-btn button {
  margin-top: 0px !important;
}
</style>
