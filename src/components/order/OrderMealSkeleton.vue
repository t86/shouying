<template>
  <div class="order-meal-skeleton">
    <!-- 顶部区域 -->
    <div class="skeleton-header">
      <div class="skeleton-search pulse"></div>
      <div class="skeleton-tabs">
        <div class="skeleton-tab pulse" v-for="n in 4" :key="'tab'+n"></div>
      </div>
    </div>

    <!-- 商品列表区域 -->
    <div class="skeleton-products">
      <div class="skeleton-product pulse" v-for="n in 8" :key="'product'+n">
        <div class="skeleton-image"></div>
        <div class="skeleton-content">
          <div class="skeleton-title"></div>
          <div class="skeleton-price"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'OrderMealSkeleton'
}
</script>

<style scoped>
.order-meal-skeleton {
  padding: 16px;
  background: #fff;
}

.skeleton-header {
  margin-bottom: 20px;
}

.skeleton-search {
  height: 36px;
  background: #f0f0f0;
  border-radius: 4px;
  margin-bottom: 16px;
}

.skeleton-tabs {
  display: flex;
  gap: 12px;
}

.skeleton-tab {
  width: 80px;
  height: 32px;
  background: #f0f0f0;
  border-radius: 4px;
}

.skeleton-products {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 16px;
}

.skeleton-product {
  background: #fff;
  border-radius: 8px;
  overflow: hidden;
}

.skeleton-image {
  width: 100%;
  height: 160px;
  background: #f0f0f0;
}

.skeleton-content {
  padding: 12px;
}

.skeleton-title {
  height: 20px;
  background: #f0f0f0;
  margin-bottom: 8px;
  border-radius: 4px;
}

.skeleton-price {
  height: 16px;
  background: #f0f0f0;
  width: 60%;
  border-radius: 4px;
}

@keyframes pulse {
  0% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
  100% {
    opacity: 1;
  }
}

.pulse {
  animation: pulse 1.5s ease-in-out infinite;
  will-change: opacity;
  transform: translateZ(0);
}
</style>
