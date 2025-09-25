<template>
  <el-dialog
    title="选择滞留金"
    :visible.sync="show"
    :before-close="onCancelDialog"
    width="90%"
    custom-class="late-deposit-dialog"
    :close-on-click-modal="false"
  >
    <!-- 充值信息摘要 -->
    <div class="recharge-summary">
      <div class="summary-content">
        <div class="info-row">
          <span class="label">本次充值金额：</span>
          <span class="value amount">¥{{ rechargeInfo.makeAmt || '0.00' }}</span>
        </div>
        <div class="info-row">
          <span class="label">剩余待支付金额：</span>
          <span class="value amount">¥{{ remainingAmount }}</span>
        </div>
      </div>
    </div>

    <!-- 说明文字 -->
    <div class="instruction-text">
      <p><strong>说明：</strong></p>
      <p>1. 点击即可选中使用当前滞留金，再次点击取消选中</p>
      <p>2. 选择的滞留金不得超过本次充值金额</p>
    </div>

    <!-- 推荐滞留金 -->
    <div class="recommended-deposits" v-if="recommendedDeposits.length > 0">
      <div class="section-title">推荐：该列表滞留金卡号与当前充值的卡号相同</div>
      <div class="deposits-grid">
        <div 
          v-for="deposit in recommendedDeposits" 
          :key="deposit.id"
          class="deposit-card"
          :class="{ active: isSelected(deposit.id) }"
          @click="toggleDeposit(deposit)"
        >
          <div class="deposit-amount">¥{{ formatAmount(deposit.amount) }}</div>
          <div class="deposit-info">{{ deposit.card_no }}</div>
          <div class="deposit-date">{{ deposit.create_time }}</div>
        </div>
      </div>
    </div>

    <!-- 其他滞留金 -->
    <div class="other-deposits" v-if="otherDeposits.length > 0">
      <div class="section-title">其他滞留金：该列表滞留金卡号与当前充值的卡号不相同，请谨慎使用</div>
      <div class="deposits-grid">
        <div 
          v-for="deposit in otherDeposits" 
          :key="deposit.id"
          class="deposit-card"
          :class="{ active: isSelected(deposit.id) }"
          @click="toggleDeposit(deposit)"
        >
          <div class="deposit-amount">¥{{ formatAmount(deposit.amount) }}</div>
          <div class="deposit-info">{{ deposit.card_no }}</div>
          <div class="deposit-date">{{ deposit.create_time }}</div>
        </div>
      </div>
    </div>

    <!-- 滞留金过多自动排行提示 -->
    <div class="auto-sort-notice" v-if="lateDepositList.length > 10">
      <p>滞留金过多了自动排行，要求显示出所有滞留金；所以该弹框页面尽量大一些</p>
    </div>

    <!-- 底部按钮 -->
    <div slot="footer" class="dialog-footer">
      <el-button @click="onCancel">取消</el-button>
      <el-button type="primary" @click="onConfirm" :disabled="selectedDeposits.length === 0">
        支付
      </el-button>
    </div>
  </el-dialog>
</template>

<script>
export default {
  name: "LateDepositDialog",
  props: {
    value: {
      type: Boolean,
      default: false
    },
    rechargeInfo: {
      type: Object,
      default: () => ({})
    },
    lateDepositList: {
      type: Array,
      default: () => []
    },
    currentCardNo: {
      type: String,
      default: ""
    }
  },
  data() {
    return {
      show: false,
      selectedDeposits: [] // 选中的滞留金列表
    };
  },
  computed: {
    // 推荐的滞留金（卡号相同）
    recommendedDeposits() {
      return this.lateDepositList.filter(deposit => 
        deposit.card_no === this.currentCardNo
      );
    },
    
    // 其他滞留金（卡号不同）
    otherDeposits() {
      return this.lateDepositList.filter(deposit => 
        deposit.card_no !== this.currentCardNo
      );
    },
    
    // 剩余待支付金额
    remainingAmount() {
      const totalSelected = this.selectedDeposits.reduce((sum, deposit) => 
        sum + parseFloat(deposit.amount), 0
      );
      const rechargeAmount = parseFloat(this.rechargeInfo.makeAmt || 0);
      return Math.max(0, rechargeAmount - totalSelected).toFixed(2);
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
      this.selectedDeposits = [];
    },

    // 格式化金额（分转元）
    formatAmount(amount) {
      if (!amount) return '0.00';
      return (amount / 100).toFixed(2);
    },

    // 检查是否选中
    isSelected(depositId) {
      return this.selectedDeposits.some(deposit => deposit.id === depositId);
    },

    // 切换滞留金选择状态
    toggleDeposit(deposit) {
      const index = this.selectedDeposits.findIndex(d => d.id === deposit.id);
      
      if (index > -1) {
        // 已选中，取消选中
        this.selectedDeposits.splice(index, 1);
      } else {
        // 未选中，检查是否超过充值金额
        const currentTotal = this.selectedDeposits.reduce((sum, d) => 
          sum + parseFloat(this.formatAmount(d.amount)), 0
        );
        const depositAmount = parseFloat(this.formatAmount(deposit.amount));
        const rechargeAmount = parseFloat(this.rechargeInfo.makeAmt || 0);
        
        if (currentTotal + depositAmount > rechargeAmount) {
          this.$message.warning("选择的滞留金不得超过本次充值金额！请重新选择");
          return;
        }
        
        // 添加到选中列表
        this.selectedDeposits.push(deposit);
      }
    },

    // 取消
    onCancel() {
      this.show = false;
    },

    // 确认
    onConfirm() {
      if (this.selectedDeposits.length === 0) {
        this.$message.warning("请选择要使用的滞留金");
        return;
      }

      // 发射选择结果
      this.$emit("confirm", {
        selectedDeposits: this.selectedDeposits,
        remainingAmount: parseFloat(this.remainingAmount),
        rechargeInfo: this.rechargeInfo
      });

      this.show = false;
    },

    onCancelDialog() {
      this.show = false;
    }
  }
};
</script>

<style scoped lang="less">
.late-deposit-dialog {
  @media (orientation: portrait) {
    width: 95% !important;
  }
  
  @media (max-width: 900px) {
    width: 95% !important;
  }
}

.recharge-summary {
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
          font-size: 16px;
        }
      }
    }
  }
}

.instruction-text {
  background: #fff3cd;
  border: 1px solid #ffeaa7;
  border-radius: 6px;
  padding: 15px;
  margin-bottom: 20px;
  
  p {
    margin: 0 0 8px 0;
    font-size: 14px;
    color: #856404;
    
    &:last-child {
      margin-bottom: 0;
    }
  }
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  margin-bottom: 15px;
  color: #333;
}

.deposits-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 15px;
  margin-bottom: 20px;
}

.deposit-card {
  border: 2px solid #e4e7ed;
  border-radius: 8px;
  padding: 15px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: #fff;
  
  &:hover {
    border-color: #409eff;
    box-shadow: 0 2px 8px rgba(64, 158, 255, 0.2);
  }
  
  &.active {
    border-color: #409eff;
    background: #ecf5ff;
    box-shadow: 0 2px 8px rgba(64, 158, 255, 0.3);
  }
  
  .deposit-amount {
    font-size: 18px;
    font-weight: 600;
    color: #409eff;
    margin-bottom: 8px;
  }
  
  .deposit-info {
    font-size: 14px;
    color: #666;
    margin-bottom: 4px;
  }
  
  .deposit-date {
    font-size: 12px;
    color: #999;
  }
}

.auto-sort-notice {
  background: #d4edda;
  border: 1px solid #c3e6cb;
  border-radius: 6px;
  padding: 15px;
  margin-bottom: 20px;
  
  p {
    margin: 0;
    font-size: 14px;
    color: #155724;
  }
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
  .deposits-grid {
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: 10px;
  }
  
  .deposit-card {
    padding: 12px;
    
    .deposit-amount {
      font-size: 16px;
    }
  }
}

@media (max-width: 900px) {
  .deposits-grid {
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  }
  
  .recharge-summary,
  .instruction-text,
  .auto-sort-notice {
    padding: 12px;
  }
}
</style>
