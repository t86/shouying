<template>
  <div class="code-rules">
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">
        <span>默认密码生成方式：</span>
      </div>
      <div class="value" layout="row" layout-align="start center">
        <el-radio v-model="passwordType" :label="1">与员工号相同</el-radio>
        <el-radio v-model="passwordType" :label="2">指定密码</el-radio>
        <div v-if="passwordType == 2">
          <el-input v-model="password" style="width:200px" size="small" placeholder="请输入密码，密码只能为数字" />
        </div>
      </div>
    </div>
    <p class="fs12 red-color p-l-10 m-l-10 m-t-3 m-b-3">员工使用账号密码登录系统时，账号为员工工号，密码为此处设置的密码</p>
    <div class="coll" layout="row" layout-align="start center">
      <div class="label">
        <span>员工号生成规则(工号位数)：</span>
      </div>
      <div class="value" layout="row" layout-align="start center">
        <el-input-number v-model="codeLength" :min="2" :max="8" />
      </div>
    </div>
    <p class="fs12 red-color p-l-10 m-l-10 m-t-3">说明：位数范围为2-8，默认为6</p>
    <div class="fs12 red-color p-l-10 m-l-10 m-t-3" layout="row" layout-align="start start">
      <span>工号示例：</span>
      <div>
        <div class="fs12 red-color m-b-2 m-l-2">{{'1'.padStart(codeLength, 0)}}</div>
        <div class="fs12 red-color m-b-2 m-l-2">{{'2'.padStart(codeLength, 0)}}</div>
        <div class="fs12 red-color m-b-2 m-l-2">...</div>
        <div class="fs12 red-color m-b-2 m-l-2">{{'9'.padStart(codeLength, 0)}}</div>
        <div class="fs12 red-color m-b-2 m-l-2">{{'10'.padStart(codeLength, 0)}}</div>
      </div>
    </div>
    <el-button type="primary" class="m-l-10 m-t-10" @click="onSubmit">保存</el-button>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      passwordType: 1,
      password: '',
      codeLength: 6
    };
  },
  methods: {
    async getRulesHandle(){
      try {
        const res = await this.$api.BMS.genRule.requestEmpGenRule()
        if(res.code == 1) {
          this.passwordType = res.data.passwd_use_code * 1
          this.codeLength = res.data.code_length || 6
          this.password = res.data.fixed_passwd || '666666'
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取工号规则失败', error);
      }
    },

    async onSubmit(){
      const params = {
        passwd_use_code: this.passwordType,
        fixed_passwd: this.password,
        code_length: this.codeLength * 1
      }
      try {
        const res = await this.$api.BMS.genRule.requestEmpSaveGenRule(params)
        if(res.code == 1) {
          this.$message.success('保存成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('保存工号规则失败', error);
      }
    }
  },
  created() {
    this.getRulesHandle()
  },
};
</script>

<style scoped lang='less'>
.code-rules {
  padding: 50px;
  .coll {
    .label {
      width: 230px;
      text-align: right;
    }
  }
}

/deep/.el-input-number__decrease,
/deep/.el-input-number__increase {
  width: 30px;
  height: 30px;
  transform: translateY(3px);
}
/deep/.el-icon-plus,
/deep/.el-icon-minus {
  transform: translateY(-3px);
}
</style>