<template>
  <div>
    <!-- 新增、修改线上充值 -->
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session add-or-update-make-money-to-vip">
        <div class="form">
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span class="red">*</span>
              <span>充值金额</span>
            </div>
            <div class="value">
              <el-input v-model="makeMoney" :disabled="!!editInfo.d" size="small" style="width:284px" placeholder="请输入充值金额"></el-input>
            </div>
          </div>
          <div class="row" layout="row" layout-align="start center">
            <div class="label">
              <span>赠送金额</span>
            </div>
            <div class="value">
              <el-input v-model="zsMoney" size="small" style="width:284px" placeholder="请输入赠送金额"></el-input>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      show: false,
      makeMoney: "",
      zsMoney: ""
    };
  },
  methods: {
    // 提交
    async onSubmit() {
      const params = {
        deposit_amt: this.makeMoney * 1, // int   充值金额
        free_amt: this.zsMoney * 1 //   int    赠送金额
      };
      if(params.deposit_amt == 0) return this.$message.warning('充值金额不可为0')
      if(params.deposit_amt.toFixed(0) * 1 != params.deposit_amt) return this.$message.warning('充值金额必须为正整数')
      try {
        const res = this.editInfo.d ? await api_vip.reqUpdateVipCardMakeMoneyRule(params) : await api_vip.reqAddVipCardMakeMoneyRule(params)
        if (res.code == 1) {
          this.$message.success(`${this.editInfo.d ? '编辑': '新建'}成功`)
          this.onCancelDrawer()
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log(`${this.editInfo.d ? '编辑': '新建'}充值规则失败`, error)
      }
    },
    onCancelDrawer() {
      this.$emit("showOrHideHandle");
    },
    resetData() {
      this.makeMoney = "";
      this.zsMoney = "";
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    editInfo: {
      default: {}
    }
  },
  computed: {
    title() {
      return this.editInfo.d ? "编辑" : "新增";
    }
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          if (this.editInfo.d) {
            // 编辑
            this.makeMoney = this.editInfo.d
            this.zsMoney = this.editInfo.f
          } else {
            this.resetData();
          }
        } else {
          this.$emit("getTableData");
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawerVip.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/vip/vipBtn.less";
@import "../../../style/common/elementFormBtnVip.less";
@import "../../../style/common/scrollBarVip.less";
@import "../../../style/vip/vipBtn.less";
</style>
<style lang="less" scoped>
.add-or-update-make-money-to-vip {
  .form {
    padding-bottom: 30px;
    .row {
      margin: 20px 0;

      .label {
        width: 150px;
        text-align: right;
        font-size: 14px;
        margin-right: 10px;

        span.red {
          color: #f51f4b;
        }
      }

      .value {
        .tips {
          margin-top: 10px;
          font-size: 13px;
          color: #72727b;
        }
      }
    }
  }
}
</style>