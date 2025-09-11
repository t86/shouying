<template>
  <el-dialog
    title="选择支付方式"
    :visible.sync="show"
    :before-close="onCancelDialog"
    width="600px"
    custom-class="payment-method-dialog"
    :close-on-click-modal="false"
  >
    <!-- 充值信息摘要 -->
    <div class="recharge-summary">
      <div class="summary-header">
        <i class="el-icon-user"></i>
        <span>充值信息</span>
      </div>
      <div class="summary-content">
        <div class="info-row">
          <span class="label">会员卡号：</span>
          <span class="value">{{ rechargeInfo.member.card_no }}</span>
        </div>
        <div class="info-row">
          <span class="label">会员姓名：</span>
          <span class="value">{{ rechargeInfo.member.name }}</span>
        </div>
        <div class="info-row">
          <span class="label">充值金额：</span>
          <span class="value amount">¥{{ rechargeAmount }}</span>
        </div>
        <div class="info-row" v-if="giftAmount > 0">
          <span class="label">赠送金额：</span>
          <span class="value gift">¥{{ giftAmount }}</span>
        </div>
      </div>
    </div>

    <!-- 支付方式选择 -->
    <div class="payment-methods-section">
      <div class="section-header">
        <i class="el-icon-bank-card"></i>
        <span>选择支付方式</span>
      </div>
      <div class="payment-grid">
        <div 
          v-for="method in paymentMethods" 
          :key="method.value"
          class="payment-card"
          :class="{ active: selectedPaymentMethod === method.value }"
          @click="selectPaymentMethod(method.value)"
        >
          <div class="payment-icon">
            <img :src="method.icon" alt="" />
          </div>
          <div class="payment-name">{{ method.name }}</div>
          <div class="payment-desc">{{ method.desc }}</div>
        </div>
      </div>
    </div>

    <!-- 实付金额显示 -->
    <div class="total-payment">
      <div class="payment-amount">
        <span class="label">实付金额：</span>
        <span class="amount">¥{{ rechargeAmount }}</span>
      </div>
    </div>

    <!-- 底部按钮 -->
    <div slot="footer" class="dialog-footer">
      <el-button @click="onCancelDialog" size="large">取消</el-button>
      <el-button 
        type="primary" 
        @click="confirmPayment" 
        size="large"
        :disabled="!selectedPaymentMethod"
        :loading="isProcessing"
      >
        确认支付
      </el-button>
    </div>

    <!-- 支付二维码弹窗 -->
    <el-dialog
      title="请扫码支付"
      :visible.sync="showPayQRCode"
      width="400px"
      custom-class="qrcode-dialog"
      :close-on-click-modal="false"
      :show-close="false"
      append-to-body
    >
      <div class="qrcode-section">
        <div class="qrcode-container" v-if="paymentQRCode">
          <div id="payment-qrcode-canvas"></div>
        </div>
        <div class="payment-info">
          <p class="payment-amount">支付金额：¥{{ rechargeAmount }}</p>
          <p class="payment-tip">请使用{{ getPaymentTypeName() }}扫码支付</p>
        </div>
        <div class="payment-status">
          <el-button 
            @click="cancelPayment" 
            size="medium"
            type="info"
            class="cancel-payment-btn"
          >
            取消支付
          </el-button>
        </div>
      </div>
    </el-dialog>
  </el-dialog>
</template>

<script>
import api_vip from "@/api/vip";
import QRCode from "qrcode";
import weixin_kerensaowo from "@/assets/pay-img/weixin_kerensaowo.png";
import weixinxiaochengxu from "@/assets/pay-img/weixinxiaochengxu.png";
import zhifubao_kerensaowo from "@/assets/pay-img/zhifubao_kerensaowo.png";

export default {
  name: "PaymentMethodDialog",
  props: {
    value: {
      type: Boolean,
      default: false
    },
    rechargeInfo: {
      type: Object,
      default: () => ({})
    }
  },
  data() {
    return {
      show: false,
      selectedPaymentMethod: null,
      isProcessing: false,
      showPayQRCode: false,
      paymentQRCode: "",
      currentOrderId: null,
      currentPayId: null,
      paymentTimer: null,
      paymentMethods: [
        {
          value: 1,
          name: "客人扫我-支付宝",
          desc: "商家收款码",
          icon: zhifubao_kerensaowo
        },
        {
          value: 2,
          name: "客人扫我-微信",
          desc: "商家收款码",
          icon: weixin_kerensaowo
        },
        {
          value: 3,
          name: "微信小程序自助",
          desc: "小程序自助支付",
          icon: weixinxiaochengxu
        }
      ]
    };
  },
  computed: {
    rechargeAmount() {
      if (!this.rechargeInfo || !this.rechargeInfo.depositAmount) return "0.00";
      return parseFloat(this.rechargeInfo.depositAmount).toFixed(2);
    },
    giftAmount() {
      if (!this.rechargeInfo || !this.rechargeInfo.freeAmount) return 0;
      return parseFloat(this.rechargeInfo.freeAmount).toFixed(2);
    }
  },
  watch: {
    value: {
      immediate: true,
      handler(val) {
        this.show = val;
        if (val) {
          this.resetDialog();
        }
      }
    },
    show(val) {
      this.$emit("input", val);
    }
  },
  methods: {
    resetDialog() {
      this.selectedPaymentMethod = null;
      this.isProcessing = false;
      this.clearPaymentTimer();
      this.showPayQRCode = false;
      this.paymentQRCode = "";
      this.currentOrderId = null;
      this.currentPayId = null;
    },

    selectPaymentMethod(method) {
      this.selectedPaymentMethod = method;
    },

    async confirmPayment() {
      if (!this.selectedPaymentMethod || !this.rechargeInfo) {
        return;
      }

      this.isProcessing = true;
      try {
        // 首先创建充值订单
        const orderParams = {
          mode: this.rechargeInfo.mode || 1,
          id: this.rechargeInfo.member.id,
          deposit_amt: Math.round(parseFloat(this.rechargeAmount) * 100), // 转换为分
          free_amt: Math.round(parseFloat(this.giftAmount) * 100),
          free_pt_amt: parseInt(this.rechargeInfo.freePoints || 0),
          free_kq_id: parseInt(this.rechargeInfo.freeKqId || 0), // 传递卡券ID
          sales_emp_id: this.rechargeInfo.salesEmpId || 0,
          remark: this.rechargeInfo.remark || ""
        };

        const orderRes = await api_vip.reqNewCustDeptOrder(orderParams);
        
        if (orderRes.code === 1) {
          this.currentOrderId = orderRes.data.order_id;
          this.currentPayId = orderRes.data.pay_id; // 保存pay_id用于支付接口
          await this.createPaymentOrder();
        } else {
          this.$message.error(orderRes.msg || "创建充值订单失败");
        }
      } catch (error) {
        console.error("创建充值订单失败:", error);
        this.$message.error("创建充值订单失败，请重试");
      } finally {
        this.isProcessing = false;
      }
    },

    async createPaymentOrder() {
      try {
        const payParams = {
          pay_id: this.currentPayId, // 使用pay_id而不是order_id
          pay_amt: Math.round(parseFloat(this.rechargeAmount) * 100),
          pay_type: this.selectedPaymentMethod,
          auth_code: "" // 扫码模式暂时为空
        };

        const payRes = await api_vip.reqNewCustDeptOrderPay(payParams);
        
        if (payRes.code === 1) {
          if (payRes.data.scan_url) {
            // 显示二维码
            this.paymentQRCode = payRes.data.scan_url;
            this.showPayQRCode = true;
            this.generateQRCode();
            this.startPaymentStatusCheck();
          } else if (payRes.data.pay_rst === 1) {
            // 直接支付成功
            this.$message.success("充值成功！");
            this.onSuccess();
          } else if (payRes.data.pay_rst === 2) {
            this.$message.error("支付失败");
          }
        } else {
          this.$message.error(payRes.msg || "创建支付订单失败");
        }
      } catch (error) {
        console.error("创建支付订单失败:", error);
        this.$message.error("创建支付订单失败，请重试");
      }
    },

    async generateQRCode() {
      try {
        const canvas = document.createElement('canvas');
        await QRCode.toCanvas(canvas, this.paymentQRCode, {
          width: 200,
          margin: 2,
          color: {
            dark: '#000000',
            light: '#FFFFFF'
          }
        });
        
        const container = document.getElementById('payment-qrcode-canvas');
        if (container) {
          container.innerHTML = '';
          container.appendChild(canvas);
        }
      } catch (error) {
        console.error("生成二维码失败:", error);
      }
    },

    startPaymentStatusCheck() {
      this.paymentTimer = setInterval(async () => {
        await this.autoCheckPaymentStatus();
      }, 2000); // 每2秒检查一次
    },

    async autoCheckPaymentStatus() {
      if (!this.currentOrderId) return;

      try {
        const statusRes = await api_vip.reqGetCustDeptOrderStatus({
          order_id: this.currentOrderId
        });

        if (statusRes.code === 1) {
          if (statusRes.data.pay_rst === 1) {
            // 支付成功
            this.clearPaymentTimer();
            this.$message.success("充值成功！");
            this.onSuccess();
          } else if (statusRes.data.pay_rst === 2) {
            // 支付失败
            this.clearPaymentTimer();
            this.$message.error("支付失败");
            this.showPayQRCode = false;
          }
          // pay_rst === 0 继续等待
        }
      } catch (error) {
        console.error("自动检查支付状态失败:", error);
      }
    },

    clearPaymentTimer() {
      if (this.paymentTimer) {
        clearInterval(this.paymentTimer);
        this.paymentTimer = null;
      }
    },

    cancelPayment() {
      this.clearPaymentTimer();
      this.showPayQRCode = false;
      this.paymentQRCode = "";
      this.currentOrderId = null;
      this.currentPayId = null;
    },

    getPaymentTypeName() {
      const types = {
        1: "支付宝",
        2: "微信",
        3: "微信小程序"
      };
      return types[this.selectedPaymentMethod] || "支付宝";
    },

    onSuccess() {
      this.clearPaymentTimer();
      this.showPayQRCode = false;
      
      // 主动关闭支付弹窗
      this.show = false;
      
      // 发送支付成功事件，包含完整的支付信息
      this.$emit("paymentSuccess", {
        phone: this.rechargeInfo.member.bind_phone,
        name: this.rechargeInfo.member.name,
        amount: this.rechargeAmount,
        cardNo: this.rechargeInfo.member.card_no,
        giftAmount: this.giftAmount
      });
    },

    onCancelDialog() {
      this.clearPaymentTimer();
      this.show = false;
      this.$emit("cancel");
    }
  },

  beforeDestroy() {
    this.clearPaymentTimer();
  }
};
</script>

<style scoped lang="less">
.payment-method-dialog {
  .recharge-summary {
    background: linear-gradient(135deg, #e6f7ff, #f0f9ff);
    border: 1px solid #91d5ff;
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 20px;

    .summary-header {
      display: flex;
      align-items: center;
      margin-bottom: 12px;
      font-size: 16px;
      font-weight: 600;
      color: #0050b3;

      i {
        margin-right: 8px;
        font-size: 18px;
      }
    }

    .summary-content {
      .info-row {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 8px;

        &:last-child {
          margin-bottom: 0;
        }

        .label {
          font-size: 14px;
          color: #595959;
        }

        .value {
          font-size: 14px;
          font-weight: 600;
          color: #262626;

          &.amount {
            color: #1890ff;
            font-size: 16px;
          }

          &.gift {
            color: #52c41a;
          }
        }
      }
    }
  }

  .payment-methods-section {
    margin-bottom: 20px;

    .section-header {
      display: flex;
      align-items: center;
      margin-bottom: 15px;
      font-size: 16px;
      font-weight: 600;
      color: #262626;

      i {
        margin-right: 8px;
        font-size: 18px;
        color: #409eff;
      }
    }

    .payment-grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 15px;

      .payment-card {
        border: 1px solid #e4e7ed;
        border-radius: 6px;
        padding: 15px;
        text-align: center;
        cursor: pointer;
        transition: all 0.2s ease;
        background: #fafafa;

        &:hover {
          border-color: #409eff;
          background: #f0f9ff;
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(64, 158, 255, 0.15);
        }

        &.active {
          border-color: #409eff;
          background: #409eff;
          color: white;
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
        }

        .payment-icon {
          margin-bottom: 8px;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 40px;

          img {
            width: 32px;
            height: 32px;
            object-fit: contain;
          }
        }

        .payment-name {
          font-size: 14px;
          font-weight: 500;
          margin-bottom: 4px;
        }

        .payment-desc {
          font-size: 12px;
          color: #8c8c8c;
        }

        &.active .payment-desc {
          color: rgba(255, 255, 255, 0.8);
        }
      }
    }
  }

  .total-payment {
    background: linear-gradient(135deg, #f0f9ff, #e6f7ff);
    border: 1px solid #91d5ff;
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 20px;

    .payment-amount {
      display: flex;
      justify-content: space-between;
      align-items: center;

      .label {
        font-size: 16px;
        font-weight: 600;
        color: #262626;
      }

      .amount {
        font-size: 24px;
        font-weight: 700;
        color: #1890ff;
      }
    }
  }

  .dialog-footer {
    text-align: center;
    padding: 15px 0;
    border-top: 1px solid #e4e7ed;
    background: #fafafa;

      .el-button {
        width: 120px;
        height: 42px;
        font-size: 14px;
        font-weight: 500;
        margin: 0 10px;
        border-radius: 6px;
      
      &.el-button--primary {
        background: linear-gradient(135deg, #409eff, #337ecc);
        border: none;
        
        &:hover {
          background: linear-gradient(135deg, #337ecc, #2d6bb3);
        }
      }
    }
  }
}

.qrcode-dialog {
  .qrcode-section {
    text-align: center;
    padding: 20px;

    .qrcode-container {
      margin-bottom: 20px;
      display: flex;
      justify-content: center;
      
      canvas {
        border: 1px solid #e4e7ed;
        border-radius: 8px;
      }
    }

    .payment-info {
      margin-bottom: 20px;

      .payment-amount {
        font-size: 20px;
        font-weight: 600;
        color: #1890ff;
        margin-bottom: 8px;
      }

      .payment-tip {
        font-size: 14px;
        color: #8c8c8c;
        margin: 0;
      }
    }

    .payment-status {
      display: flex;
      justify-content: center;
      margin-top: 20px;
      
      .cancel-payment-btn {
        min-width: 120px;
        height: 42px;
        font-size: 16px;
      }
    }
  }
}

// 全局弹窗样式
/deep/ .payment-method-dialog .el-dialog {
  margin-top: 2vh !important;
  border-radius: 6px;
  overflow: hidden;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
  max-height: 90vh;
  max-width: 800px;
  overflow-y: auto;
}

/deep/ .payment-method-dialog .el-dialog__header {
  background: linear-gradient(135deg, #409eff, #337ecc);
  padding: 15px 20px;
  border-bottom: none;

  .el-dialog__title {
    font-size: 16px;
    font-weight: 600;
    color: #ffffff;
  }

  .el-dialog__close {
    color: #ffffff;
    font-size: 18px;
    
    &:hover {
      color: #ffffff;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
    }
  }
}

/deep/ .payment-method-dialog .el-dialog__body {
  padding: 15px;
  background: #ffffff;
}

/deep/ .payment-method-dialog .el-dialog__footer {
  padding: 0;
  border-top: none;
}

/deep/ .qrcode-dialog .el-dialog {
  border-radius: 6px;
  overflow: hidden;
  max-width: 500px;
  max-height: 90vh;
  margin-top: 2vh !important;
}

// QR码对话框响应式设计
@media (orientation: portrait) {
  /deep/ .qrcode-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
    margin-top: 1vh !important;
  }
}

@media (max-width: 900px) {
  /deep/ .qrcode-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
  }
}

// 响应式设计（严格遵循收银系统开发规则）
@media (orientation: portrait) {
  /deep/ .payment-method-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
    margin-top: 1vh !important;
    max-height: 90vh !important;
  }

  .payment-methods-section .payment-grid {
    grid-template-columns: 1fr !important;
    gap: 15px;
  }
  
  .payment-methods-section .payment-card {
    padding: 15px;
  }
}

@media (max-width: 900px) {
  /deep/ .payment-method-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
  }

  .payment-methods-section .payment-grid {
    grid-template-columns: 1fr;
    gap: 15px;
  }
  
  .payment-methods-section .payment-card {
    padding: 15px;
  }
}

// iPad适配
@media (max-width: 1024px) and (min-width: 768px) {
  /deep/ .payment-method-dialog .el-dialog {
    width: 85% !important;
    max-width: 800px !important;
  }
  
  .payment-methods-section .payment-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 15px;
  }
}
</style>
