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
        <p class="m-b-2">复制结账配置</p>

        <div style="margin: 10px 0px;">
          <span class="red">*</span>
          <span>选择卡等级：</span>
          <el-select
            v-model="targetLevelVal"
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
        </div>

        <span class="red">*</span>
        <span>请选择要复制结账配置的卡类型：</span>
        <el-select
          v-model="typeVal"
          size="small"
          placeholder="请选择会员卡类型"
          style="width: 200px"
        >
          <el-option
            v-for="item in typeOption"
            :key="item.id"
            :label="item.n"
            :value="item.id"
          ></el-option>
        </el-select>

        <div v-if="typeVal" style="margin: 10px 0px;">
          <span class="red">*</span>
          <span>请选择要复制结账配置的卡等级：</span>
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
      typeVal: null,
      typeOption: [],
      levelVal: 0,
      levelOption: [],
      targetLevelVal: 0,
    };
  },
  methods: {
    async getTableData() {
      try {
        const res = await api_vip.reqGetVipTypeList();
        if (res.code == 1) {
          this.typeOption =
            res.data.records.filter((e) => e.id !== this.item.id) || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("会员卡类型列表获取失败", error);
      }
    },
    async submitHandle() {
      const params = {
        src_mb_card_type_id: this.typeVal,
        dest_mb_card_type_id: this.item.id, //   []int64   待添加商品列表
      };

      try {
        const res = await api_vip.reqCopyVipBillRule(params);
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
      this.$emit("showOrHideCopyDrawerHandle");
    },
  },
  props: {
    item: {},
    showDrawer: {
      default: false,
    },
    levelOption: {
      default: [],
    },
  },
  mounted() {},
  computed: {
    title() {
      return "复制结账配置";
    },
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      this.ruleValue = "";
      this.typeVal = null;
      if (newVal) {
        this.getTableData();
      }
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
