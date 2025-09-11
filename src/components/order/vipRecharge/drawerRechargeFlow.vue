<template>
  <div>
    <!-- 充值流程弹窗 -->
    <el-dialog
      title="会员卡充值"
      :visible.sync="show"
      :before-close="onCancelDialog"
      width="800px"
      custom-class="recharge-flow-dialog"
      :close-on-click-modal="false"
    >
      <!-- 会员信息显示 -->
      <div class="member-info-section">
        <div class="info-header">
          <i class="el-icon-user"></i>
          <span>会员信息</span>
        </div>
        <div class="info-content">
          <div class="info-item">
            <span class="label">会员卡号：</span>
            <span class="value">{{ currentMember.card_no }}</span>
          </div>
          <div class="info-item">
            <span class="label">手机号：</span>
            <span class="value">{{ currentMember.bind_phone }}</span>
          </div>
          <div class="info-item">
            <span class="label">姓名：</span>
            <span class="value">{{ currentMember.name }}</span>
          </div>
        </div>
      </div>

      <!-- 充值模式选择 -->
      <div class="recharge-mode-section">
        <div class="section-header">
          <i class="el-icon-money"></i>
          <span>充值模式</span>
        </div>
        <el-radio-group v-model="rechargeForm.mode" @change="handleModeChange">
          <el-radio :label="1" class="mode-radio">
            <span class="mode-title">标准充值</span>
            <span class="mode-desc">使用预设充值规则</span>
          </el-radio>
          <el-radio :label="2" class="mode-radio">
            <span class="mode-title">自定义充值</span>
            <span class="mode-desc">自定义充值金额和赠送</span>
          </el-radio>
        </el-radio-group>
      </div>

      <!-- 充值表单 -->
      <div class="recharge-form-section">
        <div class="form-row">
          <div class="form-label">
            <span class="required">*</span>
            <span>充值金额：</span>
          </div>
          <div class="form-input">
            <el-input
              v-model="rechargeForm.depositAmount"
              placeholder="请输入充值金额"
              @focus="currentFocusField = 'depositAmount'"
              @input="handleAmountInput"
            >
              <template slot="append">元</template>
            </el-input>
          </div>
        </div>

        <div class="form-row">
          <div class="form-label">赠送金额：</div>
          <div class="form-input">
            <el-input
              v-model="rechargeForm.freeAmount"
              placeholder="赠送金额"
              :disabled="rechargeForm.mode === 1"
              @focus="currentFocusField = 'freeAmount'"
              @input="handleAmountInput"
            >
              <template slot="append">元</template>
            </el-input>
          </div>
        </div>

        <div class="form-row">
          <div class="form-label">赠送积分：</div>
          <div class="form-input">
            <el-input
              v-model="rechargeForm.freePoints"
              placeholder="赠送积分"
              :disabled="rechargeForm.mode === 1"
              @focus="currentFocusField = 'freePoints'"
            >
              <template slot="append">分</template>
            </el-input>
          </div>
        </div>

        <div class="form-row">
          <div class="form-label">备注：</div>
          <div class="form-input">
            <el-input
              v-model="rechargeForm.remark"
              type="textarea"
              :rows="2"
              placeholder="请输入备注信息"
              maxlength="100"
            />
          </div>
        </div>
      </div>

      <!-- 数字键盘 -->
      <div class="number-keyboard">
        <div class="keyboard-grid">
          <div class="key-row">
            <div class="key" @click="inputNumber('7')">7</div>
            <div class="key" @click="inputNumber('8')">8</div>
            <div class="key" @click="inputNumber('9')">9</div>
            <div class="key special" @click="inputNumber('.')">.</div>
          </div>
          <div class="key-row">
            <div class="key" @click="inputNumber('4')">4</div>
            <div class="key" @click="inputNumber('5')">5</div>
            <div class="key" @click="inputNumber('6')">6</div>
            <div class="key special" @click="inputNumber('00')">00</div>
          </div>
          <div class="key-row">
            <div class="key" @click="inputNumber('1')">1</div>
            <div class="key" @click="inputNumber('2')">2</div>
            <div class="key" @click="inputNumber('3')">3</div>
            <div class="key clear" @click="clearAmount">清空</div>
          </div>
          <div class="key-row">
            <div class="key backspace" @click="backspaceAmount">回退</div>
            <div class="key" @click="inputNumber('0')">0</div>
            <div class="key preset" @click="inputPreset('100')">100</div>
            <div class="key preset" @click="inputPreset('500')">500</div>
          </div>
        </div>
      </div>

      <!-- 支付方式选择 -->
      <div class="payment-section">
        <div class="section-header">
          <i class="el-icon-bank-card"></i>
          <span>支付方式</span>
        </div>
        <el-radio-group v-model="paymentForm.payType" class="payment-methods">
          <el-radio :label="1" class="payment-radio">
            <i class="payment-icon alipay-icon"></i>
            <span>支付宝扫码</span>
          </el-radio>
          <el-radio :label="2" class="payment-radio">
            <i class="payment-icon wechat-icon"></i>
            <span>微信扫码</span>
          </el-radio>
          <el-radio :label="5" class="payment-radio">
            <i class="payment-icon scan-icon"></i>
            <span>扫客人支付宝</span>
          </el-radio>
          <el-radio :label="6" class="payment-radio">
            <i class="payment-icon scan-icon"></i>
            <span>扫客人微信</span>
          </el-radio>
        </el-radio-group>
      </div>

      <!-- 总金额显示 -->
      <div class="total-amount-section">
        <div class="amount-row">
          <span class="label">充值金额：</span>
          <span class="amount">¥{{ rechargeForm.depositAmount || '0.00' }}</span>
        </div>
        <div class="amount-row">
          <span class="label">赠送金额：</span>
          <span class="amount bonus">¥{{ rechargeForm.freeAmount || '0.00' }}</span>
        </div>
        <div class="amount-row total">
          <span class="label">实付金额：</span>
          <span class="amount">¥{{ rechargeForm.depositAmount || '0.00' }}</span>
        </div>
      </div>

      <!-- 底部按钮 -->
      <div slot="footer" class="dialog-footer">
        <el-button @click="onCancelDialog" size="large">取消</el-button>
        <el-button 
          type="primary" 
          @click="confirmRecharge" 
          size="large"
          :disabled="!canConfirmRecharge"
          :loading="isProcessing"
        >
          确认充值
        </el-button>
      </div>
    </el-dialog>

    <!-- 支付二维码弹窗 -->
    <el-dialog
      title="请扫码支付"
      :visible.sync="showPayQRCode"
      width="400px"
      custom-class="qrcode-dialog"
      :close-on-click-modal="false"
      :show-close="false"
    >
      <div class="qrcode-section">
        <div class="qrcode-container" v-if="paymentQRCode">
          <div id="qrcode-canvas"></div>
        </div>
        <div class="payment-info">
          <p class="payment-amount">支付金额：¥{{ rechargeForm.depositAmount }}</p>
          <p class="payment-tip">请使用{{ getPaymentTypeName() }}扫码支付</p>
        </div>
        <div class="payment-status">
          <el-button 
            type="primary" 
            @click="checkPaymentStatus"
            :loading="checkingPayment"
            size="small"
          >
            检查支付状态
          </el-button>
          <el-button @click="cancelPayment" size="small">取消支付</el-button>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import api_vip from "@/api/vip";
import QRCode from "qrcode";

export default {
  name: "DrawerRechargeFlow",
  props: {
    value: {
      type: Boolean,
      default: false
    },
    rechargeInfo: {
      type: Object,
      default: () => null
    }
  },
  data() {
    return {
      show: false,
      currentFocusField: "depositAmount",
      currentMember: {},
      rechargeForm: {
        mode: 1, // 1 标准 2 自定义
        depositAmount: "",
        freeAmount: "",
        freePoints: "",
        remark: ""
      },
      paymentForm: {
        payType: 1 // 1 支付宝扫码 2 微信扫码 5 扫客人支付宝 6 扫客人微信
      },
      isProcessing: false,
      showPayQRCode: false,
      paymentQRCode: "",
      checkingPayment: false,
      currentOrderId: null,
      paymentTimer: null
    };
  },
  computed: {
    canConfirmRecharge() {
      return this.rechargeForm.depositAmount && parseFloat(this.rechargeForm.depositAmount) > 0;
    }
  },
  watch: {
    value: {
      immediate: true,
      handler(val) {
        this.show = val;
        if (val && this.rechargeInfo) {
          this.initializeRechargeData();
        } else if (val) {
          this.resetForm();
        }
      }
    },
    show(val) {
      this.$emit("input", val);
    },
    rechargeInfo: {
      immediate: true,
      handler(info) {
        if (info && this.show) {
          this.initializeRechargeData();
        }
      }
    }
  },
  methods: {
    initializeRechargeData() {
      if (!this.rechargeInfo) return;
      
      // 设置会员信息
      this.currentMember = this.rechargeInfo.member || {};
      
      // 设置充值表单数据
      this.rechargeForm = {
        mode: this.rechargeInfo.mode || 1,
        depositAmount: (this.rechargeInfo.depositAmount && this.rechargeInfo.depositAmount.toString()) || "",
        freeAmount: (this.rechargeInfo.freeAmount && this.rechargeInfo.freeAmount.toString()) || "",
        freePoints: (this.rechargeInfo.freePoints && this.rechargeInfo.freePoints.toString()) || "",
        remark: this.rechargeInfo.remark || ""
      };
    },

    handleModeChange(mode) {
      if (mode === 1) {
        // 标准模式，清空自定义字段
        this.rechargeForm.freeAmount = "";
        this.rechargeForm.freePoints = "";
      }
    },

    handleAmountInput(value) {
      // 只允许数字和小数点
      const cleanValue = value.replace(/[^\d.]/g, "");
      if (this.currentFocusField === "depositAmount") {
        this.rechargeForm.depositAmount = cleanValue;
      } else if (this.currentFocusField === "freeAmount") {
        this.rechargeForm.freeAmount = cleanValue;
      }
    },

    inputNumber(num) {
      if (this.currentFocusField === "depositAmount") {
        this.rechargeForm.depositAmount += num;
      } else if (this.currentFocusField === "freeAmount") {
        this.rechargeForm.freeAmount += num;
      } else if (this.currentFocusField === "freePoints") {
        this.rechargeForm.freePoints += num;
      }
    },

    inputPreset(amount) {
      if (this.currentFocusField === "depositAmount") {
        this.rechargeForm.depositAmount = amount;
      } else if (this.currentFocusField === "freeAmount") {
        this.rechargeForm.freeAmount = amount;
      }
    },

    clearAmount() {
      if (this.currentFocusField === "depositAmount") {
        this.rechargeForm.depositAmount = "";
      } else if (this.currentFocusField === "freeAmount") {
        this.rechargeForm.freeAmount = "";
      } else if (this.currentFocusField === "freePoints") {
        this.rechargeForm.freePoints = "";
      }
    },

    backspaceAmount() {
      if (this.currentFocusField === "depositAmount") {
        this.rechargeForm.depositAmount = this.rechargeForm.depositAmount.slice(0, -1);
      } else if (this.currentFocusField === "freeAmount") {
        this.rechargeForm.freeAmount = this.rechargeForm.freeAmount.slice(0, -1);
      } else if (this.currentFocusField === "freePoints") {
        this.rechargeForm.freePoints = this.rechargeForm.freePoints.slice(0, -1);
      }
    },

    async confirmRecharge() {
      if (!this.canConfirmRecharge) {
        return;
      }

      this.isProcessing = true;
      try {
        // 直接使用已有的会员信息创建充值订单
        const orderParams = {
          mode: this.rechargeForm.mode,
          id: this.currentMember.id,
          deposit_amt: Math.round(parseFloat(this.rechargeForm.depositAmount || 0) * 100), // 转换为分
          free_amt: Math.round(parseFloat(this.rechargeForm.freeAmount || 0) * 100),
          free_pt_amt: parseInt(this.rechargeForm.freePoints || 0),
          free_kq_id: 0,
          sales_emp_id: (this.rechargeInfo && this.rechargeInfo.salesEmpId) * 1 || 0,
          remark: this.rechargeForm.remark || ""
        };

        const orderRes = await api_vip.reqNewCustDeptOrder(orderParams);
        
        if (orderRes.code === 1) {
          this.currentOrderId = orderRes.data.order_id;
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
          pay_id: this.currentOrderId,
          pay_amt: Math.round(parseFloat(this.rechargeForm.depositAmount) * 100),
          pay_type: this.paymentForm.payType,
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
        
        const container = document.getElementById('qrcode-canvas');
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
        await this.checkPaymentStatus();
      }, 2000); // 每2秒检查一次
    },

    async checkPaymentStatus() {
      if (!this.currentOrderId) return;

      this.checkingPayment = true;
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
        console.error("检查支付状态失败:", error);
      } finally {
        this.checkingPayment = false;
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
    },

    getPaymentTypeName() {
      const types = {
        1: "支付宝",
        2: "微信",
        5: "支付宝",
        6: "微信"
      };
      return types[this.paymentForm.payType] || "支付宝";
    },

    onSuccess() {
      this.clearPaymentTimer();
      this.showPayQRCode = false;
      this.$emit("rechargeSuccess", {
        phone: this.memberInfo.phone,
        name: this.memberInfo.name,
        amount: this.rechargeForm.depositAmount
      });
      this.onCancelDialog();
    },

    resetForm() {
      this.rechargeForm = {
        mode: 1,
        depositAmount: "",
        freeAmount: "",
        freePoints: "",
        remark: ""
      };
      this.paymentForm = {
        payType: 1
      };
      this.currentFocusField = "depositAmount";
      this.clearPaymentTimer();
      this.showPayQRCode = false;
      this.paymentQRCode = "";
      this.currentOrderId = null;
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
.recharge-flow-dialog {
  .member-info-section {
    background: linear-gradient(135deg, #e6f7ff, #f0f9ff);
    border: 1px solid #91d5ff;
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 20px;

    .info-header {
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

    .info-content {
      display: flex;
      gap: 30px;

      .info-item {
        .label {
          font-size: 14px;
          color: #595959;
          margin-right: 8px;
        }

        .value {
          font-size: 14px;
          font-weight: 600;
          color: #262626;
        }
      }
    }
  }

  .recharge-mode-section, .payment-section {
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

    .mode-radio {
      display: block;
      margin-bottom: 12px;
      padding: 12px;
      border: 1px solid #e4e7ed;
      border-radius: 6px;
      transition: all 0.2s ease;

      &:hover {
        border-color: #409eff;
        background: #f0f9ff;
      }

      /deep/ .el-radio__input.is-checked + .el-radio__label {
        color: #409eff;
      }

      .mode-title {
        font-size: 14px;
        font-weight: 600;
        color: #262626;
        display: block;
        margin-bottom: 4px;
      }

      .mode-desc {
        font-size: 12px;
        color: #8c8c8c;
      }
    }

    .payment-methods {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 10px;

      .payment-radio {
        display: flex;
        align-items: center;
        padding: 12px;
        border: 1px solid #e4e7ed;
        border-radius: 6px;
        transition: all 0.2s ease;
        margin: 0;

        &:hover {
          border-color: #409eff;
          background: #f0f9ff;
        }

        /deep/ .el-radio__input.is-checked + .el-radio__label {
          color: #409eff;
        }

        .payment-icon {
          width: 20px;
          height: 20px;
          margin-right: 8px;
          background-size: contain;
          
          &.alipay-icon {
            background: url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIGZpbGw9IiMwMGE5ZmYiIHZpZXdCb3g9IjAgMCAxMDI0IDEwMjQiPjxwYXRoIGQ9Ik01MTIgMEM3OTQuNzY0IDAgMTAyNCAyMjkuMjM2IDEwMjQgNTEyUzc5NC43NjQgMTAyNCA1MTIgMTAyNCAyNTYgNzk0Ljc2NCAyNTYgNTEyIDQ4NS4yMzYgMCA3NjggMHoiLz48L3N2Zz4=');
          }
          
          &.wechat-icon {
            background: url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIGZpbGw9IiMwN2MxNjAiIHZpZXdCb3g9IjAgMCAxMDI0IDEwMjQiPjxwYXRoIGQ9Ik01MTIgMEM3OTQuNzY0IDAgMTAyNCAyMjkuMjM2IDEwMjQgNTEyUzc5NC43NjQgMTAyNCA1MTIgMTAyNCAyNTYgNzk0Ljc2NCAyNTYgNTEyIDQ4NS4yMzYgMCA3NjggMHoiLz48L3N2Zz4=');
          }
          
          &.scan-icon {
            background: url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAiIGhlaWdodD0iMjAiIGZpbGw9IiM1OTU5NTkiIHZpZXdCb3g9IjAgMCAxMDI0IDEwMjQiPjxwYXRoIGQ9Ik01MTIgMEM3OTQuNzY0IDAgMTAyNCAyMjkuMjM2IDEwMjQgNTEyUzc5NC43NjQgMTAyNCA1MTIgMTAyNCAyNTYgNzk0Ljc2NCAyNTYgNTEyIDQ4NS4yMzYgMCA3NjggMHoiLz48L3N2Zz4=');
          }
        }
      }
    }
  }

  .recharge-form-section {
    background: #fafafa;
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 20px;

    .form-row {
      display: flex;
      align-items: flex-start;
      margin-bottom: 15px;

      .form-label {
        width: 100px;
        font-size: 14px;
        font-weight: 600;
        color: #262626;
        line-height: 38px;

        .required {
          color: #f56c6c;
          margin-right: 4px;
        }
      }

      .form-input {
        flex: 1;

        /deep/ .el-input__inner {
          height: 38px;
          font-size: 14px;
          border: 1px solid #dcdfe6;
          border-radius: 6px;
          
          &:focus {
            border-color: #409eff;
            box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.2);
          }
        }

        /deep/ .el-input-group__append {
          background: #f5f7fa;
          border-color: #dcdfe6;
          color: #909399;
        }

        /deep/ .el-textarea__inner {
          font-size: 14px;
          border: 1px solid #dcdfe6;
          border-radius: 6px;
          
          &:focus {
            border-color: #409eff;
            box-shadow: 0 0 0 2px rgba(64, 158, 255, 0.2);
          }
        }
      }
    }
  }

  .number-keyboard {
    margin: 20px auto;
    max-width: 320px;

    .keyboard-grid {
      .key-row {
        display: flex;
        gap: 8px;
        margin-bottom: 8px;

        .key {
          flex: 1;
          height: 42px;
          background: linear-gradient(145deg, #ffffff, #f0f2f5);
          border: 1px solid #e4e7ed;
          border-radius: 6px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.2s ease;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);

          &:hover {
            background: linear-gradient(145deg, #e6f7ff, #d9ecff);
            border-color: #409eff;
            transform: translateY(-1px);
            box-shadow: 0 2px 6px rgba(64, 158, 255, 0.2);
          }

          &:active {
            transform: translateY(0);
          }

          &.special {
            background: linear-gradient(145deg, #f0f9ff, #e6f7ff);
            border-color: #91d5ff;
            color: #1890ff;
          }

          &.clear, &.backspace {
            background: linear-gradient(145deg, #fef0f0, #fde2e2);
            border-color: #fbc4c4;
            color: #f56c6c;
            font-size: 12px;
            font-weight: 500;
          }

          &.preset {
            background: linear-gradient(145deg, #f6ffed, #e6f7ff);
            border-color: #b7eb8f;
            color: #52c41a;
            font-weight: 600;
          }
        }
      }
    }
  }

  .total-amount-section {
    background: linear-gradient(135deg, #f0f9ff, #e6f7ff);
    border: 1px solid #91d5ff;
    border-radius: 8px;
    padding: 15px;
    margin-bottom: 20px;

    .amount-row {
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

      .amount {
        font-size: 16px;
        font-weight: 600;
        color: #262626;

        &.bonus {
          color: #52c41a;
        }
      }

      &.total {
        border-top: 1px solid #d9ecff;
        padding-top: 8px;
        margin-top: 8px;

        .label {
          font-size: 16px;
          font-weight: 600;
          color: #262626;
        }

        .amount {
          font-size: 20px;
          color: #1890ff;
        }
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
      height: 38px;
      font-size: 14px;
      font-weight: 500;
      margin: 0 10px;
      border-radius: 19px;
      
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
      .el-button {
        margin: 0 5px;
      }
    }
  }
}

// 全局弹窗样式
/deep/ .recharge-flow-dialog .el-dialog {
  margin-top: 2vh !important;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.15);
  max-height: 90vh;
  overflow-y: auto;
}

/deep/ .recharge-flow-dialog .el-dialog__header {
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

/deep/ .recharge-flow-dialog .el-dialog__body {
  padding: 15px;
  background: #ffffff;
}

/deep/ .recharge-flow-dialog .el-dialog__footer {
  padding: 0;
  border-top: none;
}

/deep/ .qrcode-dialog .el-dialog {
  border-radius: 8px;
  overflow: hidden;
}

// 响应式设计（严格遵循收银系统开发规则）
@media (orientation: portrait) {
  /deep/ .recharge-flow-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
    margin-top: 1vh !important;
    max-height: 92vh !important;
  }

  .number-keyboard {
    max-width: 280px !important;
    
    .keyboard-grid .key-row .key {
      height: 36px;
      font-size: 14px;
    }
  }
  
  .payment-methods {
    grid-template-columns: 1fr !important;
    gap: 8px;
  }
  
  .recharge-form-section .form-row {
    flex-direction: column;
    align-items: flex-start;
    
    .form-label {
      width: auto;
      margin-bottom: 6px;
    }
  }
}

@media (max-width: 900px) {
  /deep/ .recharge-flow-dialog .el-dialog {
    width: 95% !important;
    max-width: 95% !important;
  }
  
  .number-keyboard {
    max-width: 260px;
    
    .keyboard-grid .key-row .key {
      height: 38px;
      font-size: 14px;
    }
  }
}
</style>
