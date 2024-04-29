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
          <div v-if="tabIndex == 32 || tabIndex == 12" layout="column" layout-align="start center" @click="tabClick(1, tabIndex)">
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

      <div class="next-step" v-if="step > 2">
        <div class="order-meal-list">
          <mealNav :redeem="tabIndex" @updateProductsList="updateProductsList" :customStyle="{ 'left':'20%', 'top':'65px', 'heigth':'calc(100vh - 125px)' }"/>
          <productList
              @onRedeem="onRedeemSuccess"
              :redeem="tabIndex"
              :allProductsList="allProductsList"
              :currentCategoryProductList="currentCategoryProductList"
          />
        </div>
      </div>

      <div class="next-step" v-if="step == 1 || step == 2">
        <div layout="row" layout-align="start center" v-if="step == 1">
          <div>{{ scanCode == 0 ? '请扫描券码' : scanCode ==  1 ? '券码识别中' : scanCode == 3 ? '扫码失败，请重试' : `券码编号：${authCode}` }}</div>
        </div>
        <div layout="row" layout-align="start center" v-if="step == 2" style="padding: 10px;">
          <div>券码：</div>
          <el-input v-model="authCode" type="number" placeholder="请输入券码" style="width: 200px;margin-right: 20px;"></el-input>
        </div>
        <div layout="row" layout-align="start center" v-if="step == 2" style="padding: 10px;">
          <keyBoard
              class="key"
              :landscape="true"
              :itemHeight="44"
              :itemWidth="44"
              :width="270"
              @changeNum="changeNumHandle"
          />
          <el-button type="primary" @click="checkCode" style="margin-left: 20px;">确定</el-button>
        </div>
        <div class="order-meal-list">
          <div >券详情：请选择套餐明细</div>
          <!-- 点套餐 -->
          <groupProduct
              ref="groupProduct"
              :productInfo="productInfo"
              :singleInfo="singleInfo"
              :key="componentKey"
              :dy-info="dyInfo"
              @closeDrawerHandle="onRedeemSuccess"
          />
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="info" @click="doRedeem">核销卡券</el-button>
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
import groupProduct from "@/components/order/newDrawerMeal/groupProduct";
import keyBoard from "@/components/common/newKeyBoard.vue";

export default {
  data() {
    return {
      componentKey:0,
      step:0,
      tabIndex: 22,
      tableData: [],
      checkAll: false,
      checkedList: [],
      allProductsList: [],
      currentCategoryProductList: [],
      custKqId: "",
      prdId: "",
      authCode: "",
      productInfo: {},
      singleInfo: {},
      dyInfo: {},
      scanCode: 0, // 0 等待扫码 1：扫码中 2：扫码成功 3：扫码失败

    };
  },
  methods: {
    changeNumHandle(value) {
      switch (value) {
        case 11: // 清空
          this.authCode = "";
          break;
        case 10: // 回退(
          this.authCode =
              this.authCode
                  .toString()
                  .slice(0, this.authCode.toString().length - 1) * 1;
          break;
        default:
          this.authCode = this.authCode + value * 1;
          break;
      }
      this.$forceUpdate();
    },
    // 开始扫码
    startScan() {
      if (window.atool && "startScan" in window.atool) {
        window.atool.startScan("scan_callback");
      }
    },
    async getTableData(){

    },
    fullloading(){
      api_order.reqLocalManualKqCsm({})
    },
    onRedeemSuccess(){
      this.step = 0
      this.productInfo = {}
      this.singleInfo = {}
      this.dyInfo = {}
    },
    onCancelDrawer() {
      this.tabIndex = 22
      this.step = 0
      this.show = false;
      this.productInfo = {}
      this.singleInfo = {}
      this.dyInfo = {}
    },
    checkCode() {
      window.scan_callback({code: this.tabIndex, data: this.authCode})
    },

    doRedeem() {
      this.$refs.groupProduct.onSubmit()
    },
    updateProductsList({ key, value }) {
      this[key] = value;
    },
    tabClick(step, tabIndex){
      this.step = step
      if(step == 1) {
        this.startScan()
      }
    },
    changeFirstCategory(firstCategoryId = "") {},
  },
  created() {},
  mounted() {
    this.getMenuInfo(false);
    const that = this;
    async function scan_callback(value) {
      console.log('scan_callback value', value)
      try {
        if (value && that.tabIndex === 32) {
          const res = await api_order.reqValidCustKqCode({
            cust_kq_code: value.data,
          })
          if(res.code === 1) {
            that.custKqId = res.data.cust_kq_id
            that.prdId = res.data.prd_id
            that.authCode = res.data.auth_code
            that.productInfo = that.$store.state.orderInfo.allProductsList.find(item => item.id === res.data.prd_id.toString())
            console.log("query product=============:", that.productInfo)
            that.componentKey += 1
            that.singleInfo.prd_cnt = 1
            that.singleInfo.authCode = that.authCode
            that.$message.success("券码识别成功：" + value.data);
            console.log("券码识别成功：", that.custKqId , res)
          } else {
            that.step = 0
            console.log("券码识别失败：", res);
            that.$message.warning("券码识别失败：" + res.msg);
          }
        } else if  (value && that.tabIndex === 12 && value.code === 0) {
          let seat_id = that.$store.state.orderInfo.currentCardInfo.seatId * 1
          let params = {
            seat_id: seat_id,
            relate_csm_id: 0,
            dy_url: value.data
          }
          console.log('csm_dy_coupon_prepare params', params)
          const res = await api_order.csm_dy_coupon_prepare(params)
          if (res.code === 1) {
            that.prdId = res.data.prd_id
            that.dyInfo.coupon_pay_amt = res.data.coupon_pay_amt
            that.dyInfo.dy_order_id = res.data.dy_order_id
            that.dyInfo.order_id = res.data.order_id
            that.dyInfo.verify_token = res.data.verify_token
            let finder = res.data.prd_id.toString()
            that.singleInfo.prd_cnt = 1
            console.log("finder===========:", finder)
            that.productInfo = that.$store.state.cardPageInfo.resResultDataObj.goodsAroundInfo.find(item => item.id === finder)
            console.log("query product=============:", that.productInfo )
            that.componentKey += 1
            // that.$message.success("抖音券码识别成功：" + value.data);
            console.log("券码识别成功：", res)
          } else {
            that.step = 0
            console.log("券码识别失败：", res);
            that.$message.warning("券码识别失败：" + res.msg);
          }
        }
        else {
          that.step = 0
          that.$message.warning("扫码取消");
        }
      } catch (error) {
        that.step = 0
        console.log("券码识别失败：", error);
        that.$message.warning("券码识别失败：" + error);
      }
    }
    window.scan_callback = scan_callback;
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
    groupProduct,
    keyBoard
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
    gap: 10px;
    div {
      width: 100px;
      height: 100px;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      cursor: pointer;
      background-color: #cccccc;
      border: 1px solid rgba(0, 0, 255, 0.1);
      &:active {
        background-color: rgba(255, 255, 255, 0.3) !important;
        border: 1px solid rgba(0, 0, 255, 0.1);
      }
    }
  }
  .on-focus {
    background-color: rgba(0, 0, 255, 0.1) !important;
    border: 1px solid rgba(0, 0, 255, 0.5) !important;
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
      background-color: rgba(255, 255, 255, 0.3) !important;
      border: 1px solid rgba(0, 0, 255, 0.5);
    }
  }
}

/deep/input {
  height: 36px;
  padding: 0 40px 0 12px;
  box-sizing: border-box;
  background: #FFFFFF;
  color: black;
  border-radius: 22px;
  border: 1px solid #C4CBD7;
}
</style>
