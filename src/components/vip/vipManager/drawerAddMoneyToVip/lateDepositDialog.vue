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
    <div class="amount-info-container">
      <div class="amount-row">
        <div class="label-column">剩余待支付金额：</div>
        <div class="amount-column">¥{{ remainingAmount }}</div>
      </div>
      <div class="amount-row">
        <div class="label-column">选择滞留金：</div>
        <div class="amount-column">¥{{ selectedTotalAmount }}</div>
      </div>
    </div>

    <!-- 说明文字 -->
    <div class="instruction-text">
      <p><strong>说明：</strong></p>
      <p>1. 点击即可选中使用当前滞留金，再次点击取消选中</p>
      <p>2. 选择的滞留金不得超过本次充值金额</p>
      <p>3. 可以不选择滞留金，直接点击"支付"进入下一步</p>
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
            <div class="deposit-amount" :style="{ textAlign: 'left', display: 'block', float: 'none', direction: 'ltr', marginLeft: '0', marginRight: 'auto', transform: 'none', position: 'relative', left: '0', right: 'auto' }">¥{{ formatAmount(deposit) }}</div>
            <div class="deposit-info">卡号：{{ deposit.c || deposit.card_no }}</div>
            <div class="deposit-name">姓名：{{ deposit.n || deposit.name }}</div>
            <div class="deposit-phone">手机号：{{ deposit.p || deposit.phone }}</div>
            <div class="deposit-date">{{ deposit.t || deposit.create_time }}</div>
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
          <div class="deposit-amount" :style="{ textAlign: 'left', display: 'block', float: 'none', direction: 'ltr', marginLeft: '0', marginRight: 'auto', transform: 'none', position: 'relative', left: '0', right: 'auto' }">¥{{ formatAmount(deposit) }}</div>
          <div class="deposit-info">卡号：{{ deposit.c || deposit.card_no }}</div>
          <div class="deposit-name">姓名：{{ deposit.n || deposit.name }}</div>
          <div class="deposit-phone">手机号：{{ deposit.p || deposit.phone }}</div>
          <div class="deposit-date">{{ deposit.t || deposit.create_time }}</div>
        </div>
      </div>
    </div>

    <!-- 底部按钮 -->
    <div slot="footer" class="dialog-footer">
      <el-button @click="onCancel">取消</el-button>
      <el-button type="primary" @click="onConfirm">
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
        (deposit.c || deposit.card_no) === this.currentCardNo
      );
    },
    
    // 其他滞留金（卡号不同）
    otherDeposits() {
      return this.lateDepositList.filter(deposit => 
        (deposit.c || deposit.card_no) !== this.currentCardNo
      );
    },
    
    // 剩余待支付金额
    remainingAmount() {
      const totalSelected = this.selectedDeposits.reduce((sum, deposit) => 
        sum + parseFloat((deposit.a || deposit.amount)/100), 0
      );
      const rechargeAmount = parseFloat(this.rechargeInfo.makeAmt || 0);
      return Math.max(0, rechargeAmount - totalSelected).toFixed(2);
    },
    
    // 选中滞留金的总金额
    selectedTotalAmount() {
      const totalSelected = this.selectedDeposits.reduce((sum, deposit) => 
        sum + parseFloat((deposit.a || deposit.amount)/100), 0
      );
      return totalSelected.toFixed(2);
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
    formatAmount(deposit) {
      const amount = deposit.a || deposit.amount;
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
          sum + parseFloat(this.formatAmount(d)), 0
        );
        const depositAmount = parseFloat(this.formatAmount(deposit));
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
      // 允许不选择滞留金，直接支付
      // 如果没有选择滞留金，剩余金额就是全部充值金额
      const remainingAmt = this.selectedDeposits.length === 0 
        ? parseFloat(this.rechargeInfo.makeAmt || 0)
        : parseFloat(this.remainingAmount);

      // 发射选择结果
      this.$emit("confirm", {
        selectedDeposits: this.selectedDeposits,
        remainingAmount: remainingAmt,
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
/* 全局强制左对齐样式 - 最高优先级 */
:deep(.deposit-amount) {
  text-align: left !important;
  display: block !important;
  float: none !important;
  direction: ltr !important;
  margin-left: 0 !important;
  margin-right: auto !important;
  transform: none !important;
  position: relative !important;
  left: 0 !important;
  right: auto !important;
}

/* 更强的全局样式重置 - 只针对内容区域，不影响标题 */
:deep(.late-deposit-dialog) {
  .el-dialog__body * {
    text-align: inherit !important;
  }
  
  .deposit-amount {
    text-align: left !important;
    display: block !important;
    float: none !important;
    direction: ltr !important;
    margin-left: 0 !important;
    margin-right: auto !important;
    transform: none !important;
    position: relative !important;
    left: 0 !important;
    right: auto !important;
    width: auto !important;
    box-sizing: border-box !important;
  }
}
/* 确保对话框标题正常显示 */
:deep(.late-deposit-dialog) {
  .el-dialog__header {
    position: relative !important;
    z-index: 1 !important;
    text-align: center !important;
    background: #fff !important;
  }
  
  .el-dialog__title {
    text-align: center !important;
    font-weight: 600 !important;
    color: #303133 !important;
  }
  
  .el-dialog__body {
    position: relative !important;
    z-index: 0 !important;
  }
}

.late-deposit-dialog {
  @media (orientation: portrait) {
    width: 95% !important;
  }
  
  @media (max-width: 900px) {
    width: 95% !important;
  }
}

.amount-info-container {
  background: #f8f9fa;
  border-radius: 6px;
  padding: 15px;
  margin-bottom: 20px;
  
  .amount-row {
    display: flex;
    align-items: center;
    margin-bottom: 12px;
    
    &:last-child {
      margin-bottom: 0;
    }
    
    .label-column {
      width: 140px;
      flex-shrink: 0;
      font-size: 14px;
      color: #606266;
      font-weight: 500;
      text-align: left;
    }
    
    .amount-column {
      flex: 1;
      font-size: 16px;
      font-weight: 600;
      color: #409eff;
      text-align: left;
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

/* 强制金额左对齐 - 最高优先级 */
.late-deposit-dialog .deposit-card .deposit-amount,
.late-deposit-dialog .deposits-grid .deposit-card .deposit-amount,
.late-deposit-dialog div.deposit-card div.deposit-amount,
.el-dialog .late-deposit-dialog .deposit-card .deposit-amount {
  text-align: left !important;
  justify-content: flex-start !important;
  align-items: flex-start !important;
  display: block !important;
  margin-left: 0 !important;
  margin-right: auto !important;
  float: none !important;
  direction: ltr !important;
  position: relative !important;
  left: 0 !important;
  right: auto !important;
  width: auto !important;
  transform: none !important;
}

.deposit-card {
  border: 2px solid #e4e7ed;
  border-radius: 8px;
  padding: 15px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: #fff;
  display: flex;
  flex-direction: column;
  text-align: left !important;
  align-items: flex-start !important;
  justify-content: flex-start !important;
  
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
    text-align: left !important;
    float: none !important;
    display: block !important;
    width: auto !important;
    position: relative !important;
    left: 0 !important;
    right: auto !important;
    direction: ltr !important;
    margin-left: 0 !important;
    margin-right: auto !important;
    padding-left: 0 !important;
    padding-right: 0 !important;
    transform: none !important;
    box-sizing: border-box !important;
  }
  
  .deposit-info {
    font-size: 14px;
    color: #666;
    margin-bottom: 4px;
    font-weight: 500;
    text-align: left !important;
    float: none !important;
  }
  
  .deposit-name {
    font-size: 13px;
    color: #303133;
    margin-bottom: 3px;
    font-weight: 500;
    text-align: left !important;
    float: none !important;
  }
  
  .deposit-phone {
    font-size: 12px;
    color: #606266;
    margin-bottom: 4px;
    text-align: left !important;
    float: none !important;
  }
  
  .deposit-date {
    font-size: 12px;
    color: #999;
    text-align: left !important;
    float: none !important;
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
