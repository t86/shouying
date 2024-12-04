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
      <OrderMealSkeleton v-if="loading" />
      <template v-else>
        <mealNav @updateProductsList="updateProductsList"/>
        <productList
          :mustOrderProducts="mustOrderProducts"
          :vipPrice="vipPrice"
          :vipPricePercent="vipPricePercent"
          :allProductsList="allProductsList"
          :currentCategoryProductList="currentCategoryProductList"
          :safeModeEnabled="safeModeEnabled"
        />
      </template>
    </div>
  </div>
</template>

<script>
import mealNav from "@/components/order/orderMealNav.vue";
import productList from "@/components/order/productList.vue";
import productListYH from "@/components/order/productListYH.vue";
import productListGQ from "@/components/order/productListGQ.vue";
import eventVue from "@/utils/eventVue";
import OrderMealSkeleton from "@/components/order/OrderMealSkeleton.vue";

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
      imageLoadPromises: [],
      loading: true,
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

        await this.simulateLoading(); // 移到数据加载后

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
    },
    
    // 添加调试方法
    async simulateLoading() {
      if (this.$store.state.debugSkeleton) {
        await new Promise(resolve => setTimeout(resolve, 2000));
      }
    },
    
    // 添加快捷键处理方法
    handleKeyPress(event) {
      // 按下 Ctrl + Shift + S 切换调试模式
      if (event.ctrlKey && event.shiftKey && event.key === 'S') {
        this.$store.commit('setSkeletonDebug', !this.$store.state.debugSkeleton);
        this.$message.info(`骨架屏调试模式: ${this.$store.state.debugSkeleton ? '开启' : '关闭'}`);
        if (this.$store.state.debugSkeleton) {
          this.initBasicData(); // 重新加载数据以显示骨架屏
        }
      }
    },
  },
  computed: {
    debugSkeleton() {
      return this.$store.state.debugSkeleton;
    }
  },
  watch: {
    // 监听调试模式变化
    debugSkeleton: {
      immediate: true,
      handler(val) {
        if (!val) {
          this.loading = false;
        }
      }
    }
  },
  beforeRouteLeave(to, from, next) {
    // 离开路由时关闭调试模式
    this.$store.commit('setSkeletonDebug', false);
    next();
  },
  async created() {
    this.logPerformancePoint('组件创建开始');
    this.loading = true;
    await this.initBasicData();
    this.loading = false;
    this.logPerformancePoint('组件创建完成');
  },
  mounted() {
    this.logPerformancePoint('组件挂载开始');
    
    // 添加快捷键监听
    window.addEventListener('keydown', this.handleKeyPress);
    
    this.$nextTick(() => {
      this.logPerformancePoint('组件挂载完成');
    });
  },
  beforeDestroy() {
    // 移除快捷键监听
    window.removeEventListener('keydown', this.handleKeyPress);
  },
  beforeRouteEnter(to, from, next) {
    next(async vm => {
      vm.logPerformancePoint('路由进入开始');
      vm.loading = true;
      await vm.$nextTick();
      await vm.initBasicData();
      vm.loading = false;
      vm.logPerformancePoint('路由进入完成');
    });
  },
  beforeRouteUpdate(to, from, next) {
    this.logPerformancePoint('路由更新开始');
    this.loading = true;
    this.$nextTick().then(() => {
      this.initBasicData().then(() => {
        this.loading = false;
        this.logPerformancePoint('路由更新完成');
        next();
      });
    });
  },
  props: ["String"],
  components: {
    mealNav,
    productList,
    productListYH,
    productListGQ,
    OrderMealSkeleton
  },
  filters: {},
};
</script>

<style scoped lang="less">
@import "../../../style/order/orderMeal/orderMealList.less";
</style>