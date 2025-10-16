<template>
  <el-dialog
    title="扫客人付款码"
    :visible.sync="show"
    :before-close="onCancelDialog"
    width="80%"
    custom-class="customer-payment-scan-dialog"
    :close-on-click-modal="false"
    :append-to-body="true"
    :modal-append-to-body="true"
  >
    <!-- 充值信息摘要 -->
    <div class="payment-summary">
      <div class="summary-content">
        <div class="info-row">
          <span class="label">支付方式：</span>
          <span class="value">{{ payTypeText }}</span>
        </div>
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
              ref="manualPaymentCodeInput"
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
    },
    payType: {
      type: Number,
      default: 5 // 5:扫客人-支付宝 6:扫客人-微信
    }
  },
  data() {
    return {
      show: false,
      customerPaymentCode: "",
      manualPaymentCode: "",
      paymentStatus: "idle", // idle, processing, success, failed
      scanTimeout: null,
      scanInputTimeout: null,
      paymentTimeout: null,
      showManualInput: false,
      currentOrderId: null,
      paymentTimer: null
    };
  },
  computed: {
    usedLateDepositAmount() {
      return this.selectedLateDeposits.reduce((sum, deposit) => {
        return sum + parseFloat((deposit.amount / 100).toFixed(2));
      }, 0);
    },
    payTypeText() {
      return this.payType === 5 ? '扫客人-支付宝' : this.payType === 6 ? '扫客人-微信' : '扫客人付款码';
    }
  },
  watch: {
    value: {
      immediate: true,
      handler(val) {
        console.log("=== 📱 [扫客人付款码组件] value变化 ===");
        console.log("  - 新值:", val);
        console.log("  - payType:", this.payType);
        console.log("  - paymentAmount:", this.paymentAmount);
        console.log("  - rechargeInfo:", this.rechargeInfo);
        console.log("  - 当前 show 值:", this.show);
        
        this.show = val;
        console.log("  - 设置后 show 值:", this.show);
        
        if (val) {
          console.log("  - ✅ 开始重置对话框并启动扫码");
          this.resetDialog();
          this.startScan();
          // 确保对话框显示在最上层
          this.$nextTick(() => {
            this.fixZIndex();
          });
        } else {
          console.log("  - ❌ 值为 false，清理超时");
          this.clearTimeouts();
        }
        console.log("=== 📱 [扫客人付款码组件] value变化 结束 ===");
      }
    },
    show(val) {
      console.log("=== 📱 [扫客人付款码组件] show变化 ===");
      console.log("  - 新值:", val);
      console.log("  - 触发 input 事件");
      this.$emit("input", val);
      console.log("=== 📱 [扫客人付款码组件] show变化 结束 ===");
    }
  },
  created() {
    console.log("=== 📱 [扫客人付款码组件] created ===");
    console.log("  - value:", this.value);
    console.log("  - payType:", this.payType);
    console.log("  - paymentAmount:", this.paymentAmount);
  },
  mounted() {
    console.log("=== 📱 [扫客人付款码组件] mounted ===");
    console.log("  - value:", this.value);
    console.log("  - show:", this.show);
  },
  methods: {
    // 修复 z-index，确保对话框显示在 drawer 之上
    fixZIndex() {
      try {
        // 找到对话框的 wrapper 元素
        const dialogWrapper = document.querySelector('.el-dialog__wrapper .customer-payment-scan-dialog');
        if (dialogWrapper) {
          const wrapper = dialogWrapper.closest('.el-dialog__wrapper');
          if (wrapper) {
            wrapper.style.zIndex = '3100';
            console.log('✅ 设置对话框 z-index 为 3100');
          }
        }
        
        // 找到遮罩层
        const modals = document.querySelectorAll('.v-modal');
        if (modals.length > 0) {
          // 设置最后一个遮罩层（最新的）
          const lastModal = modals[modals.length - 1];
          lastModal.style.zIndex = '3099';
          console.log('✅ 设置遮罩层 z-index 为 3099');
        }
      } catch (error) {
        console.error('❌ 设置 z-index 失败:', error);
      }
    },

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
      
      // 移除扫码超时限制，用户手动取消即可
      // 不再设置60秒超时，界面不关就一直尝试
      
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
        if (this.showManualInput && this.$refs.manualPaymentCodeInput) {
          this.$refs.manualPaymentCodeInput.focus();
        } else if (this.$refs.customerPaymentCodeInput) {
          this.$refs.customerPaymentCodeInput.focus();
        }
      });
    },

    // 扫码输入处理
    onCustomerPaymentCodeInput() {
      // 延迟处理，等待完整的扫码输入

        if (this.customerPaymentCode && this.customerPaymentCode.length > 10) {
          console.log('scan out ', this.customerPaymentCode)
          if(this.scanInputTimeout != null) {
            clearTimeout(this.scanInputTimeout);
          }
          this.scanInputTimeout = setTimeout(()=> {
            console.log('scan in ', this.customerPaymentCode)
            this.processCustomerPayment();
          })

        }
    },

    // 切换手动输入
    toggleManualInput() {
      this.showManualInput = !this.showManualInput;
      if (this.showManualInput) {
        this.manualPaymentCode = "";
      }
      this.$nextTick(() => {
        if (this.showManualInput && this.$refs.manualPaymentCodeInput) {
          this.$refs.manualPaymentCodeInput.focus();
        } else {
          this.focusInput();
        }
      });
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

      // 移除支付超时限制，允许用户手动取消，界面不关就一直尝试

      try {
        // 第一步：创建充值订单
        const orderParams = {
          mode: this.rechargeInfo.isCustom ? 2 : 1,
          id: this.rechargeInfo.memberId,
          deposit_amt: Math.round(parseFloat(this.rechargeInfo.makeAmt || this.paymentAmount || 0) * 100),
          free_amt: Math.round(parseFloat(this.rechargeInfo.freeAmt || 0) * 100),
          free_pt_amt: parseInt(this.rechargeInfo.sendPoint || 0, 10),
          free_kq_id: parseInt(this.rechargeInfo.freeKqId || 0, 10),
          sales_emp_id: parseInt(this.rechargeInfo.salesEmpId || 0, 10),
          remark: this.rechargeInfo.remark || ""
        };

        const orderRes = await api_vip.reqNewCustDeptOrder(orderParams);
        
        if (orderRes.code === 1 && orderRes.data.pay_id) {
          // 第二步：创建支付订单
          // 使用正确的支付类型参数：5=扫客人支付宝 6=扫客人微信
          const payParams = {
            pay_id: orderRes.data.pay_id,
            pay_amt: Math.round(parseFloat(this.paymentAmount) * 100),
            pay_type: this.payType, // 使用传入的支付类型：5=扫客人支付宝 6=扫客人微信
            auth_code: this.customerPaymentCode
          };

          const payRes = await api_vip.reqNewCustDeptOrderPay(payParams);
          
          if (payRes.code === 1) {
            if (payRes.data.pay_rst === 1) {
              // 直接支付成功
              this.paymentStatus = "success";
              this.$message.success("充值成功");
              
              // 发射成功事件
              this.$emit("success", {
                amount: this.paymentAmount,
                paymentCode: this.customerPaymentCode,
                lateDeposits: this.selectedLateDeposits
              });
              
              this.onCancel();
            } else if (payRes.data.pay_rst === 0) {
              // 需要轮询检查支付状态
              this.startPaymentStatusCheck(orderRes.data.order_id);
            } else {
              // 支付失败
              this.paymentStatus = "failed";
              this.$message.error("支付失败");
              this.resetPaymentInput();
            }
          } else {
            this.paymentStatus = "failed";
            this.$message.error(payRes.msg || "创建支付订单失败");
            this.resetPaymentInput();
          }
        } else {
          this.paymentStatus = "failed";
          this.$message.error(orderRes.msg || "创建订单失败");
          this.resetPaymentInput();
        }
      } catch (error) {
        console.error("客人付款码支付失败:", error);
        this.paymentStatus = "failed";
        this.$message.error("支付失败，请重试");
        this.resetPaymentInput();
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
      if (this.paymentTimer) {
        clearInterval(this.paymentTimer);
        this.paymentTimer = null;
      }
    },

    // 取消
    onCancel() {
      this.clearTimeouts();
      this.show = false;
    },

    onCancelDialog() {
      this.show = false;
    },

    // 开始支付状态检查
    startPaymentStatusCheck(orderId) {
      console.log('startPaymentStatusCheck go')
      this.currentOrderId = orderId;
      if (this.paymentTimer) {
              clearInterval(this.paymentTimer);
      }
      this.paymentTimer = setInterval(async () => {
        await this.checkPaymentStatus();
      }, 2000); // 每2秒检查一次

    },

    // 检查支付状态
    async checkPaymentStatus() {
      if (!this.currentOrderId) return;

      console.log('checkPaymentStatus go')
      try {
        const statusRes = await api_vip.reqGetCustDeptOrderStatus({
          order_id: this.currentOrderId
        });

        if (statusRes.code === 1) {
          if (statusRes.data.pay_rst === 1) {
            // 支付成功
            if (this.paymentTimer) {
              clearInterval(this.paymentTimer);
              this.paymentTimer = null;
            }
            
            this.paymentStatus = "success";
            this.$message.success("充值成功");
            
            // 发射成功事件
            this.$emit("success", {
              amount: this.paymentAmount,
              paymentCode: this.customerPaymentCode,
              lateDeposits: this.selectedLateDeposits
            });
            
            this.onCancel();
          } else if (statusRes.data.pay_rst === 2) {
            // 支付失败
            if (this.paymentTimer) {
              clearInterval(this.paymentTimer);
              this.paymentTimer = null;
            }
            
            this.paymentStatus = "failed";
            this.$message.error("支付失败");
            this.resetPaymentInput();
          }
          // pay_rst === 0 继续等待
        }
      } catch (error) {
        console.error("检查支付状态失败:", error);
      }
    }
  },

  beforeDestroy() {
    this.clearTimeouts();
  }
};
</script>

<style scoped lang="less">
.customer-payment-scan-dialog {
  z-index: 3100 !important;
  
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

<style lang="less">
/* 确保对话框在 drawer (z-index: 3000) 之上 */
body > .el-dialog__wrapper:has(.customer-payment-scan-dialog) {
  z-index: 3100 !important;
}

/* 遮罩层也需要在 drawer 之上，但在对话框之下 */
body > .v-modal {
  z-index: 3099 !important;
}
</style>
