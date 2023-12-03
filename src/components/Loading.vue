<template>
    <div v-if="isLoading" class="loading-overlay">
        <div class="loading-spinner">
            <img class="loading-img" src='../assets/order-img/loading.png' />
            <span class="loading-span">页面加载中...</span>

        </div>
    </div>
</template>
  
<script>
export default {
    computed: {
        isLoading() {
            // 通过 Vuex 等状态管理来获取全局 loading 状态
            return this.$store.state.loading;
        },
    },
};
</script>
  
<style scoped>
.loading-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(255, 255, 255, 0.8);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000000;
}

.loading-spinner {
    border-radius: 20px;
    width: 240px;
    height: 240px;
    background: rgba(255, 255, 255, 0.97);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}

.loading-img {
    width: 80px;
    animation: rotateAnimation 0.7s linear infinite;
}

.loading-span {
    font-size: 24px;
    font-family: PingFangSC, PingFang SC;
    font-weight: 400;
    color: #08080A;
    margin-top: 72px;
}

@keyframes rotateAnimation {
    0% {
        transform: rotate(0deg);
    }

    100% {
        transform: rotate(360deg);
    }
}
</style>