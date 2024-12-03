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
      safeModeEnabled: false,
      loadStartTime: 0,
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

    let safeMode = this.$store.state.cardPageInfo.resResultDataObj.safeMode || []
    this.safeModeEnabled = safeMode.some(item => item.id * 1 === 1 && item.param1 * 1 === 1)

    eventVue.$on("safeModeChanged", (e) => {
      console.log('------------,safeModeChanged:', e)
      this.safeModeEnabled = e[0][0] * 1 === 1 && e[0][1] * 1 === 1
      console.log('------------,safeModeEnabled:', this.safeModeEnabled)
    });

    // 创建性能观察者
    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries();
      entries.forEach(entry => {
        if (entry.entryType === 'measure') {
          console.log(`${entry.name}: ${entry.duration}ms`);
        }
      });
    });
    
    observer.observe({ entryTypes: ['measure'] });

    // 标记组件挂载完成
    performance.mark('component-mounted');

    // 等待所有子组件和数据加载完成
    this.$nextTick(async () => {
      try {
        // 等待所有图片加载完成
        const imgPromises = Array.from(this.$el.getElementsByTagName('img'))
          .map(img => {
            if (img.complete) return Promise.resolve();
            return new Promise(resolve => {
              img.onload = resolve;
              img.onerror = resolve;
            });
          });

        await Promise.all(imgPromises);

        // 标记组件完全加载
        performance.mark('component-fully-loaded');
        
        // 测量总加载时间
        performance.measure(
          'OrderMealList Total Load Time',
          'component-mounted',
          'component-fully-loaded'
        );

        // 测量从路由变化到组件加载完成的时间
        if (window.routeStartTime) {
          const totalTime = performance.now() - window.routeStartTime;
          console.log(`从路由变化到组件完全加载耗时: ${totalTime}ms`);
        }

        // 记录详细的性能指标
        const metrics = {
          componentLoadTime: performance.now() - this.loadStartTime,
          fromRouteChange: window.routeStartTime ? performance.now() - window.routeStartTime : null,
          timestamp: new Date().toISOString()
        };

        console.log('OrderMealList 性能指标:', metrics);

      } catch (error) {
        console.error('性能监控出错:', error);
      }
    });
  },
  beforeDestroy() {
    eventVue.$off("safeModeChanged")
    // 清理性能标记
    performance.clearMarks();
    performance.clearMeasures();
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

    // 记录组件开始加载的时间
    this.loadStartTime = performance.now();

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