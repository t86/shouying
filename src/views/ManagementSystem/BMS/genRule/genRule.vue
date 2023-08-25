<template>
    <div class="genRule form">
        <el-form label-position="left">
            <div class="compatibil">
                <div class="compatibility">
                    <div class="mandatory">
                        <span class="reqfieldsd"></span>默认密码生成方式：
                    </div>
                    <div class="controlling">
                        <el-radio v-model="gen_rule.passwd_use_code" :label="true">与员工号相同</el-radio>
                        <el-radio v-model="gen_rule.passwd_use_code" :label="false">指定密码</el-radio>
                        <div style="display: flex;align-items: center;width: 230px;" v-show="!gen_rule.passwd_use_code">
                            <el-input v-model="gen_rule.fixed_passwd" :disabled="gen_rule.passwd_use_code" placeholder="请输入密码，密码只能为数字"/>
                        </div>
                    </div>
                </div>
                <div class="layouts">员工使用账号密码登录系统时，账号为员工工号，密码为此处设置的密码</div>
            </div>
            <div class="compatibil">
                <div class="compatibility">
                    <div class="mandatory">
                        <span class="reqfieldsd"></span>员工号生成规则(工号位数)：
                    </div>
                    <el-form-item class="controlling">
                        <el-input-number v-model="gen_rule.code_length" :min='2' :max='8'/>
                    </el-form-item>
                </div>
                <div class="layouts">说明：位数范围为2-8，默认为6</div>
                <div class="layouts preview">
                    <div class="mandatory" style="padding-top: 5px;width: 60px;color: #ce4153;">工号示例：</div>
                    <div class="Taketogenerate">
                        <span>{{exampleNum[0]}}</span>
                        <span>{{exampleNum[1]}}</span>
                        <span>......</span>
                        <span>{{exampleNum[2]}}</span>
                        <span>{{exampleNum[3]}}</span>
                    </div>
                </div>
            </div>
        </el-form>
        <span slot="footer" class="dialog-footer">
          <el-button class="save" type="primary" @click="save">保存</el-button>
        </span>
    </div>
</template>
<script>
export default{
  name: "",
  props: {},
  data(){
    return {
      gen_rule: {
        passwd_use_code: true,//默认密码规则: true 与员工号相同  false 指定密码
        fixed_passwd: '', //在指定密码的规则下,所指定的密码
        code_length: "6",//生成工号长度
      },
      exampleNum: ["000001", "000002", "000009", "000010"]
    }
  },
  mounted(){
    this.demand();
  },
  methods: {
    // 获取员工密码,工号生成规则
    demand(){
      this.$api.BMS.genRule.requestEmpGenRule().then(res => {
        if (res.code == 1) {
          res.data.passwd_use_code = res.data.passwd_use_code == 1 ? true : false;
          this.gen_rule = res.data || {}
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 保存编辑内容
    save(){
      this.$api.BMS.genRule.requestEmpSaveGenRule({
        passwd_use_code: this.gen_rule.passwd_use_code ? 1 : 2,
        fixed_passwd: this.gen_rule.fixed_passwd,
        code_length: parseInt(this.gen_rule.code_length)
      }).then(res => {
        if (res.code == 1) {
          this.$message({
            showClose: true,
            message: "操作成功",
            type: 'success'
          })
          this.demand();
        } else {
          this.$message.warning(res.msg)
        }
      })
    },
    // 填充数字0 工号示例使用
    pad(num, cover) {
      return String("0".repeat(cover) + num).slice(-cover);
    }
  },
  watch: {
    gen_rule: {
      deep: true,
      handler: function (after, before) {
        this.exampleNum = [this.pad(1, after.code_length), this.pad(2, after.code_length), this.pad(9, after.code_length), this.pad(10, after.code_length)]
      }
    }
  },
  components: {},
  destroyed(){
  }
}
</script>
<style>
    .genRule {
        width: calc(100% - 40px);
        height: calc(100% - 40px);
        padding: 20px 30px;
    }

    .genRule .compatibil {
        margin-bottom: 20px;
    }

    .genRule .compatibility {
        display: flex;
        align-items: center;
        margin-bottom: 10px;
        height:34px;
    }

    .genRule .required {
        width: 60px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .genRule .el-dialog .el-button--default {
        background-color: #ccc;
        border: 1px solid #ccc;
        color: #40404e;
    }

    .genRule .el-dialog {
        background-color: #1A1A20;
    }

    .genRule .el-input__inner {
        background-color: rgba(0, 0, 0, 0);
        color: #40404e;
    }

    .genRule .el-dialog__header, .genRule .el-dialog__footer {
        background-color: #22232B;
    }

    .genRule .el-dialog__title, .genRule .el-dialog__headerbtn .el-dialog__close, .genRule .el-form-item__label {
        color: #1a1a21;
    }

    .genRule .el-form-item {
        display: flex;
        margin: 0;
    }

    .genRule .dialogPrinter .el-form-item__content {
        display: flex;
        margin: 0;
    }

    .genRule table thead tr th, .genRule table tbody tr td {
        height: 40px;
        font-size: 14px;
    }

    .genRule .el-checkbox__input {
        background-color: rgba(0, 0, 0, 0);
    }

    .genRule .printer .el-dialog {
        width: 30vw;
    }

    .genRule .has-gutter {
        border: 1px solid #383943;
    }

    .genRule .el-input-number__decrease, .genRule .el-input-number__increase {
        background-color: rgba(0, 0, 0, 0);
    }

    .genRule .el-radio__label {
        color: #40404e;
    }

    /* 必填 */
    .genRule .mandatory {
        color: #40404e;
        width: 250px;
        text-align: right;
    }

    .genRule .reqfieldsd {
        font-size: 14px;
        padding-right: 4px;
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .genRule .controlling {
        color: #40404e;
        width: 500px !important;
        display: flex;
        align-items: center;
    }

    /* 输入框禁用颜色 */
    .el-input.is-disabled .el-input__inner {
        background-color: rgba(255, 255, 255, 0.075);
    }

    /* 单选框框文字颜色 */
    .el-radio {
        color: #40404e;
    }

    .genRule .layouts {
        margin-left: 100px;
        font-size: 12px;
        /* margin-bottom: 5px; */
        color: #ce4153;
        /* 文字不可选中 */
        -webkit-user-select: none;
        -moz-user-select: none;
        -ms-user-select: none;
        user-select: none;
    }

    .save {
        width: 150px;
        margin-left: 100px;
        margin-top: 25px;
    }

    .genRule .preview {
        display: flex;
        color: #ce4153;
    }

    .genRule .Taketogenerate {
        margin-top: 2px;
    }

    .genRule .Taketogenerate span {
        display: block;
        padding: 0;
        line-height: 20px;
    }

    /* 单选框改变颜色 */

    .genRule .el-radio__input.is-checked .el-radio__inner {
        background-color: #2A5DE9 !important;
    }


</style>