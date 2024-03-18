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
      <div class="redeem-container" v-if="step == 0">
        <div layout="row" layout-align="start center" class="nav" >
          <div :class="tabIndex == 22 && 'on-focus'" @click="tabIndex = 22" >美团券</div>
          <div :class="tabIndex == 12 && 'on-focus' " @click="tabIndex = 12">抖音券</div>
          <div :class="tabIndex == 32 && 'on-focus' " @click="tabIndex = 32">小程序卡券</div>
        </div>
        <div layout="row" layout-align="start center" class="redeem-sel">
          <div v-if="tabIndex == 32" layout="column" layout-align="start center" @click="tabClick(1, tabIndex)">
            <img src="@/assets/img/scan.svg" alt="" style="width:50px;height:50px"/>
            <span>扫码核销</span>
          </div>
          <div v-if="tabIndex == 32" layout="column" layout-align="start center" @click="tabClick(2, tabIndex)">
            <img src="@/assets/img/input-coupon.svg" alt=""  style="width:50px;height:50px"/>
            <span>输入券码核销</span>
          </div>
          <div v-if="tabIndex != 32" layout="column" layout-align="start center" @click="tabClick(3, tabIndex)">
            <img src="@/assets/img/offline.svg" alt="" style="width:50px;height:50px"/>
            <span>线下核销</span>
          </div>
        </div>
      </div>

      <div class="next-step" v-if="step != 0">
        <div class="order-meal-list">
          <mealNav :redeem="tabIndex" @updateProductsList="updateProductsList" :customStyle="{ 'left':'20%', 'top':'65px', 'heigth':'calc(100vh - 125px)' }"/>
          <productList
            @onRedeem="onCancelDrawer"
            :redeem="tabIndex"
            :allProductsList="allProductsList"
            :currentCategoryProductList="currentCategoryProductList"
          />
        </div>
      </div>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import api_order from "@/api/order";
import common_book from "@/utils/common/book";
import common_order from "@/utils/common/order";

import mealNav from "@/components/order/orderMealNav.vue";
import productList from "@/components/order/productList.vue";
import navPrdList from '@/mixin/navPrdList'
export default {
  data() {
    return {
      step:0, 
      tabIndex: 22,
      tableData: [],
      checkAll: false,
      checkedList: [],
      allProductsList: [],
      currentCategoryProductList: []
    };
  },
  methods: {
    async getTableData(){
     
    },
    onCancelDrawer() {
      this.tabIndex = 22
      this.step = 0
      this.show = false;
    },
    onSubmit() {

    },
    updateProductsList({ key, value }) {
      this[key] = value;
    },
    tabClick(step, tabIndex){
      this.step = step
    },
  },
  created() {},
  mounted() {
    this.getMenuInfo(false);
  },
  props: {
    value: {
      default: false
    }
  },
  mixins: [navPrdList],
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
          this.getTableData();
        }
      },
      immediate: true
    }
  },
  components: {
    mealNav,
    productList,
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
.redeem-container {
  .nav {
    padding: 20px 20px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.2);

    div {
      width: 100px;
      height: 100px;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      cursor: pointer;
      background-color: gray;
      border: 1px solid gray;
    }
  }
  .on-focus {
    background-color: rgba(255, 255, 255, 0.1) !important;
    border: 1px solid rgba(100, 100, 100, 0.2);
  }
}
.redeem-sel {
  padding: 20px 20px;
  gap: 20px;
  div {
      width: 100px;
      height: 100px;
      display: flex;
      padding: 10px;
      gap: 5px;
      align-items: center;
      justify-content: center;
      text-align: center;
      cursor: pointer;
      background-color: #cccccc;
      border: 1px solid #cccccc;
      &:active {
        background-color: rgba(255, 255, 255, 0.1);
        border: 1px solid rgba(100, 100, 100, 0.2);
      }
    }
  }
</style>