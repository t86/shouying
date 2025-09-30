<template>
  <el-dialog
    title="扫客人付款码"
    :visible.sync="show"
    :before-close="onCancelDialog"
    width="80%"
    custom-class="customer-payment-scan-dialog"
    :close-on-click-modal="false"
  >
    <!-- 买单信息摘要 -->
    <div class="payment-summary">
      <div class="summary-content">
        <div class="info-row">
          <span class="label">支付方式：</span>
          <span class="value">{{ payTypeText }}</span>
        </div>
        <div class="info-row">
          <span class="label">卡台：</span>
          <span class="value">{{ seatName }}</span>
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
import api_order from "@/api/order";

export default {
  name: "CustomerPaymentScanDialog",
  props: {
    value: {
      type: Boolean,
      default: false
    },
    payType: {
      type: Number,
      default: 5 // 5:扫客人-支付宝 6:扫客人-微信
    },
    orderIds: {
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
      showManualInput: false,
      olPayId: null, // 在线支付订单ID
      statusPollingTimer: null // 支付状态轮询定时器
    };
  },
  computed: {
    payTypeText() {
      return this.payType === 5 ? '扫客人-支付宝' : '扫客人-微信';
    },
    seatName() {
      const currentCardInfo = this.$store.state.orderInfo.currentCardInfo;
      return (currentCardInfo && currentCardInfo.seatName) || '--';
    }
  },
  watch: {
    value: {
      immediate: true,
      handler(val) {
        this.show = val;
        if (val) {
          this.resetDialog();
          console.log("接收到的订单ID列表:", this.orderIds);
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
      this.olPayId = null;
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

      // 不设置支付超时，允许用户手动取消

      try {
        // 调用买单接口（扫客人付款码）- 这个接口只是锁定订单
        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
          pay_type: this.payType * 1, // 5:扫客人-支付宝 6:扫客人-微信
          auth_code: this.customerPaymentCode.toString(),
          order_ids: this.orderIds.length > 0 ? this.orderIds : [] // 传递未结订单ID列表
        };

        console.log("customer_payment_code_pay 创建支付订单, req:", JSON.stringify(params));
        const res = await api_order.reqGetPayQRcode(params);
        console.log("customer_payment_code_pay 创建支付订单, res:", JSON.stringify(res));

        if (res.code === 1) {
          res.data = res.data || {};
          
          // 获取在线支付订单ID
          this.olPayId = res.data.ol_pay_id || res.data.olPayId;
          
          if (!this.olPayId) {
            this.$message.error("未获取到支付订单ID");
            this.paymentStatus = "failed";
            this.clearTimeouts();
            this.resetPaymentInput();
            return;
          }

          console.log("customer_payment_code_pay 支付订单已创建, ol_pay_id:", this.olPayId);
          
          // 开始轮询支付状态
          this.startPollingPaymentStatus();
          
        } else if (res.code === 2) {
          // 需要确认
          this.clearTimeouts();
          const result = await this.$confirm(res.msg, '提示', {
            confirmButtonText: '确定',
            cancelButtonText: '取消',
            type: 'warning'
          }).catch(() => 'cancel');
          
          if (result === 'confirm') {
            // 重新调用，force=1
            this.processCustomerPayment();
          } else {
            this.paymentStatus = "failed";
            this.resetPaymentInput();
          }
        } else if (res.code === 3) {
          // 订单正在处理中
          this.clearTimeouts();
          this.$message.info("订单正在处理中，请稍候");
          setTimeout(() => {
            this.processCustomerPayment();
          }, 2000);
        } else {
          this.paymentStatus = "failed";
          this.$message.error(res.msg || "创建支付订单失败");
          this.clearTimeouts();
          this.resetPaymentInput();
        }
      } catch (error) {
        console.error("客人付款码支付失败:", error);
        this.paymentStatus = "failed";
        this.$message.error("支付失败，请重试");
        this.clearTimeouts();
        this.resetPaymentInput();
      }
    },

    // 开始轮询支付状态
    startPollingPaymentStatus() {
      if (!this.olPayId) {
        console.error("没有支付订单ID，无法轮询状态");
        return;
      }

      console.log("customer_payment_code_pay 开始轮询支付状态, ol_pay_id:", this.olPayId);
      
      // 立即查询一次
      this.checkPaymentStatus();
    },

    // 查询支付状态
    async checkPaymentStatus() {
      if (!this.olPayId || this.paymentStatus !== "processing") {
        return;
      }

      try {
        const params = {
          ol_pay_id: this.olPayId
        };

        console.log("customer_payment_code_pay 查询支付状态, req:", JSON.stringify(params));
        const res = await api_order.reqGetOrderOnlinePayStatus(params);
        console.log("customer_payment_code_pay 查询支付状态, res:", JSON.stringify(res));

        if (res.code === 1) {
          const status = (res.data && res.data.status) || 0;
          console.log("customer_payment_code_pay 支付状态:", status);

          if (status === 5) {
            // 支付成功
            this.paymentStatus = "success";
            this.$message.success("支付成功");
            this.clearTimeouts();
            
            // 发射成功事件
            this.$emit("success", {
              payType: this.payType,
              paymentCode: this.customerPaymentCode,
              orderInfo: res.data,
              olPayId: this.olPayId
            });
            
            this.onCancel();
            
          } else if (status === 2) {
            // 支付已取消
            this.paymentStatus = "failed";
            this.$message.warning("支付已取消");
            this.clearTimeouts();
            this.resetPaymentInput();
            
          } else if (status === 1) {
            // 支付中，继续轮询
            console.log("customer_payment_code_pay 支付进行中，2秒后再次查询");
            this.statusPollingTimer = setTimeout(() => {
              this.checkPaymentStatus();
            }, 2000);
            
          } else {
            // 其他状态，继续轮询
            console.log("customer_payment_code_pay 未知状态:", status, "，2秒后再次查询");
            this.statusPollingTimer = setTimeout(() => {
              this.checkPaymentStatus();
            }, 2000);
          }
        } else {
          // 查询失败，继续轮询
          console.warn("customer_payment_code_pay 查询支付状态失败:", res.msg);
          this.statusPollingTimer = setTimeout(() => {
            this.checkPaymentStatus();
          }, 2000);
        }
      } catch (error) {
        console.error("customer_payment_code_pay 查询支付状态异常:", error);
        // 继续轮询
        this.statusPollingTimer = setTimeout(() => {
          this.checkPaymentStatus();
        }, 2000);
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
      if (this.statusPollingTimer) {
        clearTimeout(this.statusPollingTimer);
        this.statusPollingTimer = null;
      }
    },

    // 取消
    async onCancel() {
      // 如果正在支付中，需要确认
      if (this.paymentStatus === "processing") {
        try {
          await this.$confirm(
            "点击暂不支付后，如果客人已经成功付款，则该金额将进入滞留金列表。是否确认暂不支付？",
            "确认",
            {
              confirmButtonText: "确认",
              cancelButtonText: "取消",
              type: "warning"
            }
          );
          
          // 用户确认取消，停止轮询并关闭弹窗
          this.clearTimeouts();
          this.resetDialog();
          this.show = false;
        } catch (error) {
          // 用户点击了取消按钮，继续等待支付
          console.log("用户取消了暂不支付操作");
        }
      } else {
        // 不在支付中，直接关闭
        this.show = false;
      }
    },

    onCancelDialog() {
      this.onCancel();
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
        color: #409eff;
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
