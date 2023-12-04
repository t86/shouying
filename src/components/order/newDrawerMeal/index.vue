<template>
  <div>
    <el-drawer
      @click.native="blueHandle"
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      :size="size"
    >
      <!-- 点单品 -->
      <singleProduct
        ref="singleProductRef"
        v-if="type == 1 || type == 4"
        :type="type"
        :productInfo="productInfo"
        :orderMealStatus="orderMealStatus"
        :show="show"
        @updateOrderMealStatus="updateOrderMealStatus"
        @changeType="changeType"
        @getYh2ProInfo="getYh2ProInfo"
        @getGQPrdList="$emit('getGQPrdList')"
        @setSingleInfo="setSingleInfo"
        @closeDrawerHandle="closeDrawerHandle"
      />

      <!-- 点套餐 -->
      <groupProduct
        ref="groupProduct"
        v-else-if="type==2"
        :productInfo="productInfo"
        :singleInfo="singleInfo"
        @closeDrawerHandle="closeDrawerHandle"
      />

      <!-- 授权 -->
      <div class="auth" v-else layout="row" layout-align="center start">
        <div class="auth-left p-l-3">
          <p class="m-b-5 fs14">当前卡台：{{$store.state.orderInfo.currentCardInfo.name}}</p>
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="start start">
                <div class="th">序号</div>
                <div class="th">商品名称</div>
                <div class="th">数量</div>
              </div>
            </div>
            <div class="tbody">
              <div class="tr" layout="row" layout-align="start start">
                <div class="td">1</div>
                <div class="td">{{singleInfo.name}}</div>
                <div class="td">{{singleInfo.count}}</div>
              </div>
            </div>
          </div>
        </div>
        <div class="auth-right">
          <authorization
            ref="authorization"
            :type="type"
            :productInfo="productInfo"
            :singleInfo="singleInfo"
            @closeDrawerHandle="closeDrawerHandle"
          />
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import singleProduct from "@/components/order/newDrawerMeal/singleProduct";
import groupProduct from "@/components/order/newDrawerMeal/groupProduct";
import authorization from "@/components/order/newShoppingCart/authorization";

export default {
  data() {
    return {
      show: false,
      type: 1, // 1:单品点单  2：套餐点单选择商品  3：授权  4:估清
      singleInfo: {},
      orderMealStatus: 1,  // 1：点单  2：优惠  3：花篮
    };
  },
  methods: {
    closeDrawerHandle() {
      this.$emit("showOrHideDrawer", false);
    },

    blueHandle() {
      const singleDom = this.$children[0].$children[0];
      if (singleDom) this.$children[0].$children[0].focus = false;
    },

    changeType(value = 1) {
      this.type = value;
    },

    setSingleInfo(obj) {
      this.singleInfo = obj;
    },

    // 提交优惠2选择的单品（目前只支持单品可以优惠2）
    getYh2ProInfo(prdInfo) {
      this.$emit("getYh2ProInfo", prdInfo);
    },

    // 选择下单进购物车方式  1：直接下单  2：优惠下单  3：花篮下单
    updateOrderMealStatus(status=1){
      this.orderMealStatus = status
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    productInfo: {
      default: () => {}
    }
  },
  components: {
    singleProduct,
    groupProduct,
    authorization
  },
  computed: {
    size() {
      return this.type == 1 || this.type == 4 ? "50%" : "88%";
    },
    title() {
      let title = "";
      switch (this.type * 1) {
        case 1:
          title = "点单数量";
          break;
        case 2:
          title = "选择套餐";
          break;
        case 3:
          title = "授权";
          break;
        case 4:
          title = "估清数量";
          break;
      }
      return title;
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.type = 1;
        this.$nextTick(() => {
          const singleDom = this.$children[0] && this.$children[0].$children[0];
          singleDom && singleDom.resetSingleForm();
        });

        if (this.$route.name == "moneyCard" || this.$route.name == 'orderCard') {this.changeType(4)};
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/newElementDrawer.less";
@import "../../../style/order/orderMeal/newDrawerMeal/drawerMeal.less";
</style>