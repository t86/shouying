<template>
  <!-- 点单列表 -->
  <div>
    <!-- 优惠2 -->
    <div v-if="isYH2" class="order-meal-list-yh2">
      <mealNav @updateProductsList="updateProductsList" :isGQ="isGQ"/>
      <productListYH
        :allProductsList="allProductsList"
        :currentCategoryProductList="currentCategoryProductList"
      />
    </div>

    <!-- 估清 -->
    <div v-else-if="isGQ" class="order-meal-list-gq">
      <mealNav @updateProductsList="updateProductsList" :isGQ="true"/>
      <productListGQ
        :allProductsList="allProductsList"
        :currentCategoryProductList="currentCategoryProductList"
        @showOrHideOutSomethingHandle="$emit('showOrHideOutSomethingHandle')"
      />
    </div>

    <!-- 正常点单 -->
    <div v-else class="order-meal-list">
      <mealNav @updateProductsList="updateProductsList"/>
      <productList
        :mustOrderProducts="mustOrderProducts"
        :vipPrice="vipPrice"
        :vipPricePercent="vipPricePercent"
        :allProductsList="allProductsList"
        :currentCategoryProductList="currentCategoryProductList"
        :safeModeEnabled="safeModeEnabled"
      />
    </div>
  </div>
</template>

<script>
import mealNav from "@/components/order/orderMealNav.vue";
import productList from "@/components/order/productList.vue";
import productListYH from "@/components/order/productListYH.vue";
import productListGQ from "@/components/order/productListGQ.vue";
import eventVue from "@/utils/eventVue";
export default {
  data() {
    return {
      vipPrice: false,
      vipPricePercent: 0,
      isYH2: false, // 是否是优惠2点餐
      isGQ: false, // 是否是估清
      allProductsList: [],
      currentCategoryProductList: [],
      mustOrderProducts: [],
      safeModeEnabled: false
    };
  },
  methods: {
    updateProductsList({ key, value }) {
      if(this.mustOrderProducts.length > 0) {
        return
      }
      this[key] = value;
    }
  },
  mounted() {
    this.isYH2 = this.$route.query.give
    this.isGQ = this.$route.name == 'moneyCard' || this.$route.name == 'orderCard'
    const showAmt = this.$store.state.cardPageInfo.resResultDataObj.showAmt || []
    if(showAmt.length > 0){
      for(let item of showAmt){
        if (item.id === '50') {
          if(item.param1 * 1 > 0){
            this.vipPrice = true
            this.vipPricePercent = item.param1 * 1
            break
          }
        }
      }
    }

    if (this.vipPrice){
      this.allProductsList = [...this.allProductsList.map(item => {
        if(item.bizType  === '1'){
          item.vipPrice = item.price
          const p = (item.price * (1.0 + (this.vipPricePercent/100.0))).toFixed(2)
          // 保留两位小数显示，避免小数商品被进位成整数
          item.price = p
        }
        return item
      })]
    }
    console.log('------------,allprods2:', this.allProductsList)
    console.log('------------,vipPricePercent:', this.vipPricePercent)

    // let hasShouyin = this.$store.state.userInfo.roleIds &&this.$store.state.userInfo.roleIds.includes(5)
    // const emp_id = this.$store.state.userInfo.emp_id
    // let dianzhangInfo = this.$store.state.cardPageInfo.resResultDataObj.shopManagerConfig || []
    // const hasDianzhang = dianzhangInfo.findIndex((item) => item.emp_id == emp_id && item.status == 1) > -1

    // console.log('order meal list shouyin :', hasShouyin)
    // console.log('order meal emp_id :', emp_id)
    // console.log("hasDianzhang", hasDianzhang)

    // 如果既不是店长也不是收银，需要过滤掉不可见的商品
    // console.log('before: ', this.allProductsList.length)
    // if (!hasDianzhang && !hasShouyin) {

    // 设备限制, 在这个设备上就不展示
    if (true) {
      this.allProductsList = this.allProductsList.filter(item => {
        return item.limit_pc === '2' || item.limit_pad === "2"
      })
    }
    console.log('after: ', this.allProductsList)

    this.$store.state.cardPageInfo.resResultDataObj

    let safeMode = this.$store.state.cardPageInfo.resResultDataObj.safeMode || []
    this.safeModeEnabled = safeMode.some(item => item.id * 1 === 1 && item.param1 * 1 === 1)

    eventVue.$on("safeModeChanged", (e) => {
      console.log('------------,safeModeChanged:', e)
      this.safeModeEnabled = e[0][0] * 1 === 1 && e[0][1] * 1 === 1
      console.log('------------,safeModeEnabled:', this.safeModeEnabled)
    });
  },
  beforeDestroy() {
    eventVue.$off("safeModeChanged")
  },
  props: ["String"],
  components: {
    mealNav,
    productList,
    productListYH,
    productListGQ
  },
  filters: {},
  created() {
    const mustOrderPrdIds = this.$route.query.mustOrderPrdId ? this.$route.query.mustOrderPrdId.split(',') : [];
    const mustPrdNames = this.$route.query.mustPrdName ? this.$route.query.mustPrdName.split(',') : [];
    this.mustOrderProducts = mustOrderPrdIds.map((id, index) => ({
      id: id,
      name: mustPrdNames[index] || ''
    }));

    // 使用 this.mustOrderProducts 进行后续处理
    if(this.mustOrderProducts.length > 0) {
      this.mustOrderProducts.forEach(item => {
        this.allProductsList.push(item)
      })
    }
  },
  computed: {
  }
};
</script>

<style scoped lang="less">
@import "../../../style/order/orderMeal/orderMealList.less";
</style>