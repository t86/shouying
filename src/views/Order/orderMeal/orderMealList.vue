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
      performanceMarks: [], // 存储性能标记
      dataInitialized: false,
      imageLoadPromises: []
    };
  },
  methods: {
    logPerformancePoint(name, data = {}) {
      const timestamp = new Date().toISOString();
      console.log(`[${timestamp}] ${name}`, data);
      this.performanceMarks.push({ name, timestamp, ...data });
    },

    // 更新商品列表
    updateProductsList({ key, value }) {
      this.logPerformancePoint('开始更新商品列表');
      if(this.mustOrderProducts.length > 0) {
        return;
      }
      this[key] = value;
      this.logPerformancePoint('商品列表更新完成');
    },

    // 初始化基础数据
    async initBasicData() {
      try {
        this.logPerformancePoint('开始初始化基础数据');
        
        // 处理基本配置
        this.isYH2 = this.$route.query.give;
        this.isGQ = this.$route.name == 'moneyCard' || this.$route.name == 'orderCard';
        
        // 处理必选商品
        const mustOrderPrdIds = this.$route.query.mustOrderPrdId ? this.$route.query.mustOrderPrdId.split(',') : [];
        const mustPrdNames = this.$route.query.mustPrdName ? this.$route.query.mustPrdName.split(',') : [];
        this.mustOrderProducts = mustOrderPrdIds.map((id, index) => ({
          id: id,
          name: mustPrdNames[index] || ''
        }));

        // 获取商品数据
        const goodsAroundInfo = this.$store.state.cardPageInfo.resResultDataObj.goodsAroundInfo || [];
        this.allProductsList = goodsAroundInfo.filter(item => item.status === '1');
        
        if(this.mustOrderProducts.length > 0) {
          this.allProductsList = [...this.allProductsList, ...this.mustOrderProducts];
        }

        // 处理安全模式
        const safeMode = this.$store.state.cardPageInfo.resResultDataObj.safeMode || [];
        this.safeModeEnabled = safeMode.some(item => item.id * 1 === 1 && item.param1 * 1 === 1);
        
        this.logPerformancePoint('基础数据初始化完成');
        return true;
      } catch (error) {
        console.error('初始化基础数据失败:', error);
        this.logPerformancePoint('初始化基础数据失败', { error: error.message });
        return false;
      }
    },

    // 处理 VIP 价格逻辑
    initVipPriceLogic() {
      const showAmt = this.$store.state.cardPageInfo.resResultDataObj.showAmt || [];
      for(let item of showAmt) {
        if (item.id === '50' && item.param1 * 1 > 0) {
          this.vipPrice = true;
          this.vipPricePercent = item.param1 * 1;
          break;
        }
      }

      if (this.vipPrice) {
        this.allProductsList = this.allProductsList.map(item => {
          if(item.bizType === '1') {
            item.vipPrice = item.price;
            let p = (item.price * (1.0 + (this.vipPricePercent/100.0))).toFixed(2);
            p = Math.ceil(p).toString();
            item.price = p;
          }
          return item;
        });
      }
    },

    // 设置事件监听
    setupEventListeners() {
      eventVue.$on("safeModeChanged", (e) => {
        this.safeModeEnabled = e[0][0] * 1 === 1 && e[0][1] * 1 === 1;
      });
    },

    // 处理图片加载
    handleImageLoading() {
      const imgElements = Array.from(this.$el.getElementsByTagName('img'));
      this.imageLoadPromises = imgElements.map(img => {
        if (img.complete) return Promise.resolve();
        return new Promise(resolve => {
          const originalSrc = img.src;
          img.src = '';  // 清空src以避免立即加载
          
          // 使用 requestIdleCallback 在空闲时间加载图片
          requestIdleCallback(() => {
            img.src = originalSrc;
            img.onload = resolve;
            img.onerror = resolve;
          }, { timeout: 2000 });  // 设置2秒超时
        });
      });
    },

    // 初始化性能监控
    initPerformanceMonitoring() {
      if (process.env.NODE_ENV === 'development') {
        const observer = new PerformanceObserver((list) => {
          list.getEntries().forEach(entry => {
            if (entry.entryType === 'measure') {
              this.logPerformancePoint(`性能测量: ${entry.name}`, {
                duration: entry.duration
              });
            }
          });
        });
        observer.observe({ entryTypes: ['measure'] });
      }
    }
  },
  async created() {
    this.logPerformancePoint('组件创建开始');
    await this.initBasicData();
    this.logPerformancePoint('组件创建完成');
  },
  async mounted() {
    this.logPerformancePoint('组件挂载开始');
    await this.$nextTick();
    this.logPerformancePoint('组件挂载完成');
  },
  beforeRouteEnter(to, from, next) {
    next(async vm => {
      vm.logPerformancePoint('路由进入开始');
      await vm.initBasicData();
      vm.logPerformancePoint('路由进入完成');
    });
  },
  beforeRouteUpdate(to, from, next) {
    this.logPerformancePoint('路由更新开始');
    this.initBasicData().then(() => {
      this.logPerformancePoint('路由更新完成');
      next();
    });
  },
  props: ["String"],
  components: {
    mealNav,
    productList,
    productListYH,
    productListGQ
  },
  filters: {},
  computed: {}
};
</script>

<style scoped lang="less">
@import "../../../style/order/orderMeal/orderMealList.less";
</style>