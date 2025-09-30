<template>
  <div class="online-payment-channel">
    <div class="channel-buttons">
      <el-button 
        class="channel-btn buy-order-btn" 
        type="primary"
        @click="handleBuyOrder"
      >
        买单
      </el-button>
      
      <el-button 
        class="channel-btn book-amt-btn" 
        type="success"
        @click="handleBookAmt"
      >
        滞留金
      </el-button>
    </div>
  </div>
</template>

<script>
export default {
  name: "OnlinePaymentChannel",
  methods: {
    handleBuyOrder() {
      this.$emit("showBuyOrder");
    },
    handleBookAmt() {
      this.$emit("showBookAmt");
    }
  }
};
</script>

<style lang="less" scoped>
.online-payment-channel {
  width: 100%;
  padding: 15px 20px;
  
  .channel-buttons {
    display: flex;
    gap: 15px;
    justify-content: center;
    align-items: center;
    
    @media (max-width: 900px) {
      flex-direction: column;
      gap: 12px;
    }
  }
  
  .channel-btn {
    height: 42px;
    padding: 0 30px;
    font-size: 15px;
    
    @media (max-width: 900px) {
      width: 100%;
      max-width: 300px;
    }
  }
  
  .buy-order-btn {
    background-color: #409eff;
    border-color: #409eff;
    
    &:hover {
      background-color: #66b1ff;
      border-color: #66b1ff;
    }
    
    &:active {
      background-color: #3a8ee6;
      border-color: #3a8ee6;
    }
  }
  
  .book-amt-btn {
    background-color: #67c23a;
    border-color: #67c23a;
    
    &:hover {
      background-color: #85ce61;
      border-color: #85ce61;
    }
    
    &:active {
      background-color: #5daf34;
      border-color: #5daf34;
    }
  }
}
</style>