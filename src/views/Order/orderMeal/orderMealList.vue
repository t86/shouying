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
export default {
  data() {
    return {
      vipPrice: false,
      vipPricePercent: 0,
      isYH2: false, // 是否是优惠2点餐
      isGQ: false, // 是否是估清
      allProductsList: [],
      currentCategoryProductList: [],
      mustOrderProducts: []
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
          let p = (item.price * (1.0 + (this.vipPricePercent/100.0))).toFixed(2)
          p = Math.ceil(p).toString()
          item.price = p
        }
        return item
      })]
    }
    console.log('------------,allprods2:', this.allProductsList)
    console.log('------------,vipPricePercent:', this.vipPricePercent)
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
    safeModeEnabled() {
      let safeMode = this.$store.state.cardPageInfo.resResultDataObj.safeMode || []
      return safeMode.some(item => item.id * 1 === 1 && item.param1 * 1 === 1)
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/order/orderMeal/orderMealList.less";
</style>