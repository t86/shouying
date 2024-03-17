<template>
<!-- 点单系统服务员买单选择商品列表 -->
  <div>
    <el-drawer
      title="核销方式"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      size="80%"
    >
      <div class="redeem-container"></div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import api_order from "@/api/order";
import common_book from "@/utils/common/book";
import common_order from "@/utils/common/order";
export default {
  data() {
    return {

    };
  },
  methods: {
    async getTableData(){
     
    },
    onCancelDrawer() {
    },
    onSubmit() {

    },
    onCancelDrawer() {
      this.show = false;
    }
  },
  created() {},
  mounted() {},
  props: {
    value: {
      default: false
    }
  },
  computed: {
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      }
    },
    isIndeterminate(){
      return !this.checkAll && this.tableData.some(item => item.checked)
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.tabIndex = 1
          this.getTableData();
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang='less'>
@import "../../style/common/newElementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/newElementFormBtn.less";
@import "../../style/common/scrollBar.less";
@import "../../style/order/orderMeal/newDrawerShowOrderList.less";
</style>
<style scoped lang='less'>
.session {
  color: rgba(255, 255, 255, 0.8);

}
</style>