<template>
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="720px"
      append-to-body
    >
      <div class="session p-3 fs14">
        <span class="red">*</span>
        <span>选择卡等级：</span>
        <el-select
          v-model="levelVal"
          size="small"
          placeholder="请选择会员卡等级"
          style="width: 200px"
        >
          <el-option
            v-for="item in levelOption"
            :key="item.id"
            :label="item.n"
            :value="item.id"
          ></el-option>
        </el-select>
        
        <p class="m-b-2">选择扣款规则</p>

        <div>
          <el-radio class="m-t-3 m-l-3" v-model="ruleValue" label="1"
            >按比例扣款</el-radio
          >
        </div>
        <div>
          <el-radio class="m-t-3 m-l-3" v-model="ruleValue" label="2"
            >优先用赠送金额</el-radio
          >
        </div>
        <div>
          <el-radio class="m-t-3 m-l-3" v-model="ruleValue" label="3"
            >只能用储值金额</el-radio
          >
        </div>
        <div>
          <el-radio class="m-t-3 m-l-3" v-model="ruleValue" label="4"
            >只能用赠送金额</el-radio
          >
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="primary" size="small" @click="submitHandle"
          >确定</el-button
        >
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
      ruleValue: "1",
      levelVal: 0,
    };
  },
  props: {
    levelOption: {
      default: () => [],
    },
  },
  methods: {
    async submitHandle() {
      const params = {
        prd_ids: this.addedSeatList
          .filter((item) => item.checked * 1)
          .map((item) => item.id),
        card_level_id: this.levelVal,
        type_id: this.ruleValue * 1, //   []int64   待添加商品列表
        card_type_id: this.item.id,
      };

      try {
        const res = await api_vip.reqUpdateVipBillRule(params);
        if (res.code == 1) {
          this.closeDrawerHandle();
          this.$emit("getTableData", this.menuId);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("扣款规则更新失败", error);
      }
    },
    // 关闭drawer
    closeDrawerHandle() {
      this.$emit("showOrHideDrawerHandle");
    },
  },
  props: {
    showDrawer: {
      default: false,
    },
    item: {},
    addedSeatList: {
      default: () => [],
    },
  },
  computed: {
    title() {
      return "批量更改扣款规则";
    },

    addedSeatListId() {
      return this.addedSeatList.map((item) => item.id * 1);
    },
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      this.ruleValue = "";
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawerWine.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtnWine.less";
@import "../../../style/erp/form.less";
@import "../../../style/erp/table.less";
</style>
<style scoped lang="less">
@import "./drawerUpdateRuleCom.less";
</style>

<style>
.el-icon-arrow-right:before {
  color: #606266;
}
</style>
