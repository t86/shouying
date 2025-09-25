<template>
  <el-dialog
    title="扫客人付款码"
    :visible.sync="show"
    :before-close="onCancelDialog"
    width="80%"
    custom-class="customer-payment-scan-dialog"
    :close-on-click-modal="false"
  >
    <!-- 充值信息摘要 -->
    <div class="payment-summary">
      <div class="summary-content">
        <div class="info-row">
          <span class="label">收款金额：</span>
          <span class="value amount">¥{{ paymentAmount }}</span>
        </div>
        <div class="info-row" v-if="usedLateDepositAmount > 0">
          <span class="label">已使用滞留金：</span>
          <span class="value">¥{{ usedLateDepositAmount.toFixed(2) }}</span>
        </div>
      </div>
    </div>

    <!-- 扫码区域 -->
    <div class="scan-area">
      <div class="scan-container">
        <!-- 隐藏的输入框用于接收扫码枪输入 -->
        <input 
          ref="customerPaymentCodeInput"
          v-model="customerPaymentCode"
          class="hidden-scan-input"
          placeholder="请使用扫码枪扫描客人付款码"
          @input="onCustomerPaymentCodeInput"
          @keydown.enter="processCustomerPayment"
          @blur="focusInput"
        />
        
        <div class="scan-status" v-if="paymentStatus === 'processing'">
          <div class="loading-icon"></div>
          <p>正在处理支付...</p>
        </div>
        
        <div class="scan-instructions" v-else>
          <div class="scan-icon">📱</div>
          <p>请使用扫码枪扫描客人付款码</p>
          <p class="sub-text">或手动输入付款码</p>
          
          <!-- 手动输入区域 -->
          <div class="manual-input" v-if="showManualInput">
            <el-input
              v-model="manualPaymentCode"
              placeholder="手动输入客人付款码"
              size="small"
              style="width: 300px; margin-top: 15px;"
              @keydown.enter.native="processManualPayment"
            />
            <el-button 
              type="primary" 
              size="small" 
              @click="processManualPayment"
              style="margin-left: 10px;"
            >
              确认
            </el-button>
          </div>
          
          <el-button 
            type="text" 
            @click="toggleManualInput"
            style="margin-top: 15px;"
          >
            {{ showManualInput ? '隐藏手动输入' : '手动输入付款码' }}
          </el-button>
        </div>
      </div>
    </div>

    <!-- 底部按钮 -->
    <div slot="footer" class="dialog-footer">
      <el-button @click="onCancel">取消</el-button>
    </div>
  </el-dialog>
</template>

<script>
import api_vip from "@/api/vip";

export default {
  name: "CustomerPaymentScanDialog",
  props: {
    value: {
      type: Boolean,
      default: false
    },
    paymentAmount: {
      type: [String, Number],
      default: "0.00"
    },
    rechargeInfo: {
      type: Object,
      default: () => ({})
    },
    selectedLateDeposits: {
      type: Array,
      default: () => []
    }
  },
  data() {
    return {
      show: false,
      customerPaymentCode: "",
      manualPaymentCode: "",
      paymentStatus: "idle", // idle, processing, success, failed
      scanTimeout: null,
      paymentTimeout: null,
      showManualInput: false
    };
  },
  computed: {
    usedLateDepositAmount() {
      return this.selectedLateDeposits.reduce((sum, deposit) => {
        return sum + parseFloat((deposit.amount / 100).toFixed(2));
      }, 0);
    }
  },
  watch: {
    value: {
      immediate: true,
      handler(val) {
        this.show = val;
        if (val) {
          this.resetDialog();
          this.startScan();
        } else {
          this.clearTimeouts();
        }
      }
    },
    show(val) {
      this.$emit("input", val);
    }
  },
  methods: {
    resetDialog() {
      this.customerPaymentCode = "";
      this.manualPaymentCode = "";
      this.paymentStatus = "idle";
      this.showManualInput = false;
      this.clearTimeouts();
    },

    // 开始扫描
    startScan() {
      this.focusInput();
      
      // 设置扫码超时（60秒）
      this.scanTimeout = setTimeout(() => {
        this.$message.warning("扫码超时，请重试");
        this.onCancel();
      }, 60000);
      
      // 设置扫码回调
      const that = this;
      function customer_scan_callback(value) {
        try {
          console.log("customer_scan_callback:", JSON.stringify(value));
          
          // 清除扫码超时
          if (that.scanTimeout) {
            clearTimeout(that.scanTimeout);
            that.scanTimeout = null;
          }
          
          if (value && value.code === 0) {
            that.customerPaymentCode = value.data;
            that.processCustomerPayment();
          } else {
            that.$message.warning("扫码取消");
            that.onCancel();
          }
        } catch (error) {
          console.log("扫码失败：", error);
          that.$message.warning("扫码失败：" + error);
          that.onCancel();
        }
      }
      
      window.customer_scan_callback = customer_scan_callback;
      
      // 尝试启动原生扫码
      if (window.atool && "startScan" in window.atool) {
        window.atool.startScan("customer_scan_callback");
      }
    },

    // 聚焦输入框
    focusInput() {
      this.$nextTick(() => {
        if (this.$refs.customerPaymentCodeInput) {
          this.$refs.customerPaymentCodeInput.focus();
        }
      });
    },

    // 扫码输入处理
    onCustomerPaymentCodeInput() {
      // 延迟处理，等待完整的扫码输入
      setTimeout(() => {
        if (this.customerPaymentCode && this.customerPaymentCode.length > 10) {
          this.processCustomerPayment();
        }
      }, 100);
    },

    // 切换手动输入
    toggleManualInput() {
      this.showManualInput = !this.showManualInput;
      if (this.showManualInput) {
        this.manualPaymentCode = "";
      }
    },

    // 处理手动输入支付
    processManualPayment() {
      if (!this.manualPaymentCode) {
        this.$message.warning("请输入付款码");
        return;
      }
      this.customerPaymentCode = this.manualPaymentCode;
      this.processCustomerPayment();
    },

    // 处理客人付款码支付
    async processCustomerPayment() {
      if (!this.customerPaymentCode) {
        this.$message.warning("请扫描或输入客人付款码");
        return;
      }

      this.paymentStatus = "processing";

      // 设置支付超时（30秒）
      this.paymentTimeout = setTimeout(() => {
        if (this.paymentStatus === "processing") {
          this.paymentStatus = "failed";
          this.$message.error("支付超时，请重试");
          this.resetPaymentInput();
        }
      }, 30000);

      try {
        // 使用标准的充值接口，客人付款码的渠道ID为9998
        const params = {
          id: this.rechargeInfo.memberId, // 会员ID
          val_amt: this.rechargeInfo.makeAmt,
          free_amt: this.rechargeInfo.freeAmt,
          pt_amt: this.rechargeInfo.sendPoint || 0,
          m: this.rechargeInfo.isCustom ? 2 : 1,
          oper_emp_id: this.$store.state.userInfo.emp_id * 1,
          deposit_cnl: 9998, // 客人付款码渠道ID（暂定）
          sales_emp_id: this.rechargeInfo.salesEmpId * 1,
          remark: this.rechargeInfo.remark || "",
          auth_code: this.customerPaymentCode, // 付款码
          pay_amt: this.paymentAmount.toString() // 实际支付金额
        };

        // 调用标准充值API
        const res = await api_vip.reqMakeMoneyToCard(params);
        
        // 清除支付超时
        if (this.paymentTimeout) {
          clearTimeout(this.paymentTimeout);
          this.paymentTimeout = null;
        }
        
        if (res.code === 1) {
          this.paymentStatus = "success";
          this.$message.success("充值成功");
          
          // 发射成功事件
          this.$emit("success", {
            amount: this.paymentAmount,
            paymentCode: this.customerPaymentCode,
            lateDeposits: this.selectedLateDeposits
          });
          
          this.onCancel();
        } else {
          this.paymentStatus = "failed";
          this.$message.error(res.msg || "支付失败");
          this.resetPaymentInput();
        }
      } catch (error) {
        console.error("客人付款码支付失败:", error);
        this.paymentStatus = "failed";
        this.$message.error("支付失败，请重试");
        this.resetPaymentInput();
        
        // 清除支付超时
        if (this.paymentTimeout) {
          clearTimeout(this.paymentTimeout);
          this.paymentTimeout = null;
        }
      }
    },

    // 重置支付输入
    resetPaymentInput() {
      setTimeout(() => {
        this.customerPaymentCode = "";
        this.manualPaymentCode = "";
        this.paymentStatus = "idle";
        this.focusInput();
      }, 2000);
    },

    // 清除定时器
    clearTimeouts() {
      if (this.scanTimeout) {
        clearTimeout(this.scanTimeout);
        this.scanTimeout = null;
      }
      if (this.paymentTimeout) {
        clearTimeout(this.paymentTimeout);
        this.paymentTimeout = null;
      }
    },

    // 取消
    onCancel() {
      this.show = false;
    },

    onCancelDialog() {
      this.show = false;
    }
  },

  beforeDestroy() {
    this.clearTimeouts();
  }
};
</script>

<style scoped lang="less">
.customer-payment-scan-dialog {
  @media (orientation: portrait) {
    width: 95% !important;
  }
  
  @media (max-width: 900px) {
    width: 95% !important;
  }
}

.payment-summary {
  background: #f8f9fa;
  border-radius: 6px;
  padding: 15px;
  margin-bottom: 20px;
  
  .summary-content {
    .info-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
      font-size: 14px;
      
      &:last-child {
        margin-bottom: 0;
      }
      
      .label {
        color: #666;
      }
      
      .value {
        font-weight: 600;
        
        &.amount {
          color: #409eff;
          font-size: 18px;
        }
      }
    }
  }
}

.scan-area {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 300px;
  background: #fafbfc;
  border-radius: 8px;
  border: 2px dashed #d9d9d9;
}

.scan-container {
  text-align: center;
  padding: 40px 20px;
  
  .hidden-scan-input {
    position: absolute;
    left: -9999px;
    opacity: 0;
  }
  
  .scan-status {
    .loading-icon {
      width: 40px;
      height: 40px;
      border: 3px solid #f3f3f3;
      border-top: 3px solid #409eff;
      border-radius: 50%;
      animation: spin 1s linear infinite;
      margin: 0 auto 20px;
    }
    
    p {
      font-size: 16px;
      color: #666;
      margin: 0;
    }
  }
  
  .scan-instructions {
    .scan-icon {
      font-size: 60px;
      margin-bottom: 20px;
    }
    
    p {
      font-size: 16px;
      color: #666;
      margin: 0 0 10px 0;
      
      &.sub-text {
        font-size: 14px;
        color: #999;
      }
    }
    
    .manual-input {
      margin-top: 20px;
      padding-top: 20px;
      border-top: 1px solid #e4e7ed;
    }
  }
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.dialog-footer {
  text-align: center;
  padding-top: 20px;
  
  .el-button {
    min-width: 100px;
    height: 40px;
  }
}

// 响应式适配
@media (orientation: portrait) {
  .scan-container {
    padding: 30px 15px;
    
    .scan-icon {
      font-size: 50px;
    }
  }
}

@media (max-width: 900px) {
  .payment-summary {
    padding: 12px;
  }
  
  .scan-area {
    min-height: 250px;
  }
}
</style>
