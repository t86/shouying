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
    // 判断是否为PC端
    isPcDevice() {
      if (window.atool && typeof window.atool.getTermType === 'function') {
        return window.atool.getTermType() === 'pc';
      }
      // 降级方案：通过 userAgent 判断
      return !/android|iphone|ipad/i.test(navigator.userAgent);
    },
    
    // 根据设备类型过滤商品列表
    filterProductsByDeviceLimit(products) {
      if (!products || !Array.isArray(products)) {
        return products;
      }
      
      const isPc = this.isPcDevice();
      
      return products.filter(item => {
        // 如果是PC端，检查 limit_pc 字段
        // limit_pc: "1" 表示限制PC端（不可见），"2" 表示不限制（可见）
        if (isPc) {
          // PC端：只显示 limit_pc !== '1' 的商品（即 limit_pc === '2' 或不存在）
          return item.limit_pc !== '1';
        } else {
          // Pad端：只显示 limit_pad !== '1' 的商品（即 limit_pad === '2' 或不存在）
          return item.limit_pad !== '1';
        }
      });
    },
    
    updateProductsList({ key, value }) {
      if(this.mustOrderProducts.length > 0) {
        return
      }
      
      // 如果是更新 allProductsList，需要应用设备限制过滤
      if (key === 'allProductsList') {
        const filteredValue = this.filterProductsByDeviceLimit(value);
        this[key] = filteredValue;
        console.log('设备限制过滤 - 设备类型:', this.isPcDevice() ? 'PC' : 'Pad');
        console.log('设备限制过滤 - 过滤前数量:', value ? value.length : 0);
        console.log('设备限制过滤 - 过滤后数量:', filteredValue ? filteredValue.length : 0);
      } else {
        this[key] = value;
      }
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

    // let hasShouyin = this.$store.state.userInfo.roleIds &&this.$store.state.userInfo.roleIds.includes(5)
    // const emp_id = this.$store.state.userInfo.emp_id
    // let dianzhangInfo = this.$store.state.cardPageInfo.resResultDataObj.shopManagerConfig || []
    // const hasDianzhang = dianzhangInfo.findIndex((item) => item.emp_id == emp_id && item.status == 1) > -1

    // console.log('order meal list shouyin :', hasShouyin)
    // console.log('order meal emp_id :', emp_id)
    // console.log("hasDianzhang", hasDianzhang)

    // 注意：设备限制过滤逻辑已移至 updateProductsList 方法中
    // 这样可以确保在数据从子组件传递过来时立即应用过滤
    // 如果 mounted 时 allProductsList 已有数据，也需要过滤一次
    if (this.allProductsList && this.allProductsList.length > 0) {
      this.allProductsList = this.filterProductsByDeviceLimit(this.allProductsList);
      console.log('mounted 时应用设备限制过滤 - 过滤后数量:', this.allProductsList.length);
    }

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