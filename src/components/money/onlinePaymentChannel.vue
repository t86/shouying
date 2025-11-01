<template>
  <div class="online-payment-channel">
    <!-- 线上收款金额显示 -->
    <div class="amount-display" v-if="amount">
      <span class="amount-label">线上收款金额:</span>
      <span class="amount-value">￥{{ amount }}</span>
    </div>
    
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
  props: {
    amount: {
      type: [String, Number],
      default: "0.00"
    }
  },
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
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  
  .amount-display {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 10px;
    padding: 12px 20px;
    background: rgba(0, 0, 0, 0.2);
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.15);
    min-width: 280px;
    
    .amount-label {
      font-size: 14px;
      color: rgba(255, 255, 255, 0.8);
    }
    
    .amount-value {
      font-size: 18px;
      font-weight: 500;
      color: #1edaad;
    }
    
    @media (max-width: 900px) {
      min-width: auto;
      width: 100%;
      max-width: 300px;
    }
    
    @media (orientation: portrait) {
      width: 95%;
      max-width: none;
    }
  }
  
  .channel-buttons {
    display: flex;
    gap: 15px;
    justify-content: center;
    align-items: center;
    
    @media (max-width: 900px) {
      flex-direction: column;
      gap: 12px;
      width: 100%;
    }
    
    @media (orientation: portrait) {
      flex-direction: column;
      gap: 12px;
      width: 100%;
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
    
    @media (orientation: portrait) {
      width: 100%;
      max-width: none;
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