<template>
  <el-dialog
    title=""
    :visible.sync="show"
    :before-close="onClose"
    width="500px"
    custom-class="payment-success-dialog"
    :close-on-click-modal="false"
    :show-close="false"
    center
  >
    <div class="success-content">
      <!-- 成功图标 -->
      <div class="success-icon">
        <i class="el-icon-success"></i>
      </div>
      
      <!-- 成功标题 -->
      <div class="success-title">支付成功！</div>
      
      <!-- 支付信息 -->
      <div class="payment-info">
        <div class="info-item">
          <span class="label">会员姓名：</span>
          <span class="value">{{ paymentInfo.name }}</span>
        </div>
        <div class="info-item">
          <span class="label">支付金额：</span>
          <span class="value amount">¥{{ paymentInfo.amount }}</span>
        </div>
        <div class="info-item" v-if="paymentInfo.phone">
          <span class="label">手机号码：</span>
          <span class="value">{{ paymentInfo.phone }}</span>
        </div>
        <div class="info-item">
          <span class="label">支付时间：</span>
          <span class="value">{{ paymentTime }}</span>
        </div>
      </div>
      
      <!-- 温馨提示 -->
      <div class="tips">
        <i class="el-icon-info"></i>
        <span>充值金额已到账，感谢您的使用！</span>
      </div>
    </div>
    
    <!-- 底部按钮 -->
    <div slot="footer" class="dialog-footer">
      <el-button 
        type="primary" 
        @click="onConfirm" 
        size="large"
        class="confirm-btn"
      >
        返回充值页面
      </el-button>
    </div>
  </el-dialog>
</template>

<script>
export default {
  name: "PaymentSuccessDialog",
  props: {
    value: {
      type: Boolean,
      default: false
    },
    paymentInfo: {
      type: Object,
      default: () => ({})
    }
  },
  data() {
    return {
      show: false
    };
  },
  computed: {
    paymentTime() {
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      const hours = String(now.getHours()).padStart(2, '0');
      const minutes = String(now.getMinutes()).padStart(2, '0');
      const seconds = String(now.getSeconds()).padStart(2, '0');
      
      return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    }
  },
  watch: {
    value: {
      immediate: true,
      handler(val) {
        this.show = val;
      }
    },
    show(val) {
      this.$emit("input", val);
    }
  },
  methods: {
    onConfirm() {
      this.show = false;
      this.$emit("confirm");
    },
    
    onClose() {
      this.show = false;
      this.$emit("close");
    }
  }
};
</script>

<style scoped lang="less">
.payment-success-dialog {
  .success-content {
    text-align: center;
    padding: 20px 0;
    
    .success-icon {
      margin-bottom: 20px;
      
      i {
        font-size: 80px;
        color: #67c23a;
        animation: successPulse 0.6s ease-in-out;
      }
    }
    
    .success-title {
      font-size: 24px;
      font-weight: 600;
      color: #67c23a;
      margin-bottom: 30px;
    }
    
    .payment-info {
      background: #f8f9fa;
      border-radius: 8px;
      padding: 20px;
      margin-bottom: 20px;
      text-align: left;
      
      .info-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 12px;
        
        &:last-child {
          margin-bottom: 0;
        }
        
        .label {
          color: #666;
          font-size: 14px;
        }
        
        .value {
          color: #333;
          font-size: 14px;
          font-weight: 500;
          
          &.amount {
            color: #67c23a;
            font-size: 16px;
            font-weight: 600;
          }
        }
      }
    }
    
    .tips {
      display: flex;
      align-items: center;
      justify-content: center;
      color: #409eff;
      font-size: 14px;
      
      i {
        margin-right: 6px;
        font-size: 16px;
      }
    }
  }
  
  .dialog-footer {
    text-align: center;
    padding: 0;
    
    .confirm-btn {
      width: 200px;
      height: 42px;
      font-size: 16px;
      border-radius: 6px;
    }
  }
}

// 成功动画
@keyframes successPulse {
  0% {
    transform: scale(0.8);
    opacity: 0.5;
  }
  50% {
    transform: scale(1.1);
    opacity: 0.8;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

// 响应式设计（严格遵循收银系统开发规则）
@media (orientation: portrait) {
  /deep/ .payment-success-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
    margin-top: 1vh !important;
    max-height: 90vh !important;
  }
  
  .success-content {
    padding: 15px 0;
    
    .success-icon i {
      font-size: 60px;
    }
    
    .success-title {
      font-size: 20px;
      margin-bottom: 20px;
    }
    
    .payment-info {
      padding: 15px;
      margin-bottom: 15px;
      
      .info-item {
        margin-bottom: 10px;
        
        .label, .value {
          font-size: 13px;
        }
        
        .value.amount {
          font-size: 15px;
        }
      }
    }
    
    .tips {
      font-size: 13px;
    }
  }
  
  .dialog-footer .confirm-btn {
    width: 180px;
    height: 40px;
    font-size: 15px;
  }
}

@media (max-width: 900px) {
  /deep/ .payment-success-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
  }
  
  .success-content {
    .success-icon i {
      font-size: 60px;
    }
    
    .success-title {
      font-size: 20px;
    }
  }
}

// iPad适配
@media (max-width: 1024px) and (min-width: 768px) {
  /deep/ .payment-success-dialog .el-dialog {
    width: 85% !important;
    max-width: 500px !important;
  }
}
</style>

