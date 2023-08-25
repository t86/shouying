<template>
  <div>
    <!-- 批量设置二级分类 -->
    <el-drawer
      title="批量设置二级分类"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="720px"
    >
      <div class="session p-5 erp-lib-detail fs14">
        <div class="item m-t-4">
          <span>二级分类：</span>
          <el-cascader placeholder="请选择二级分类" clearable :options="options" v-model="value"></el-cascader>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="closeDrawerHandle">关闭</el-button>
        <el-button type="primary" @click="submitHandle">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      value: [0, 0],
      show: false,
      options: []
    };
  },
  methods: {
    async getOptions() {
      try {
        const res = await this.$api.ERP.mcate.requestmcatetree()
        if (res.code == 1) {
          res.data = res.data || []
          this.options = res.data.map(item => ({
            ...item,
            label: item.n,
            value: item.id,
            children: (item.subs || []).map(items => ({
              ...items,
              label: items.n,
              value: items.id,
            }))
          }))
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('分类列表获取失败', error)
      }
    },
    submitHandle() {
      this.$emit("submitSecondCategoryHandle", this.value[1]);
    },
    closeDrawerHandle() {
      this.$emit("showOrHideSetSecondCategoryHandle");
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      type: Boolean,
      default: false
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.value = [0, 0]
        this.getOptions();
      } 
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../../../style/common/elementDrawerWine.less";
@import "../../../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../../../style/common/elementFormBtnWine.less";
@import "../../../../../../style/erp/form.less";
@import "../../../../../../style/erp/table.less";
</style>

<style lang="less" scoped>
.table {
  .th,.td {
    &:nth-child(1) {
      width: 20%;
    }
  }
}
</style>