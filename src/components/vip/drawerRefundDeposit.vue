<template>
  <div>
    <!-- 退款弹窗 -->
    <el-dialog
      title="退款"
      :visible.sync="show"
      :before-close="onCancelDialog"
      width="800px"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      append-to-body
      class="refund-deposit-dialog"
    >
      <div class="dialog-content">
        <!-- 退款说明 -->
        <div class="refund-notice">
          <p>请检查以下退款信息，退款后不得撤销！请谨慎操作！如果退款的渠道是线上渠道，请在此操作后，再去滞留金管理处进行退款！</p>
        </div>

        <!-- 充值信息展示 -->
        <div class="deposit-info">
          <div class="info-row">
            <span class="label">当前卡号：</span>
            <span class="value">{{ depositInfo.cn }}</span>
          </div>
          <div class="info-row">
            <span class="label">手机号：</span>
            <span class="value">{{ depositInfo.bp }}</span>
          </div>
          <div class="info-row">
            <span class="label">退款金额：</span>
            <span class="value amount">￥{{ depositInfo.va }}</span>
          </div>
        </div>

        <!-- 退款备注 -->
        <div class="remark-section">
          <div class="section-title">退款备注：</div>
          <el-input
            v-model="refundRemark"
            type="textarea"
            :rows="3"
            placeholder="输入退款备注，不超过30个字"
            maxlength="30"
            show-word-limit
            style="width: 100%;"
          />
        </div>
      </div>

      <div slot="footer" class="dialog-footer">
        <el-button @click="onCancelDialog" size="medium">取消</el-button>
        <el-button 
          type="primary" 
          @click="confirmRefund" 
          size="medium"
          :loading="submitLoading"
        >
          确定
        </el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import api_vip from "@/api/vip";

export default {
  name: "DrawerRefundDeposit",
  props: {
    showDialog: {
      type: Boolean,
      default: false
    },
    depositInfo: {
      type: Object,
      default: () => ({})
    }
  },
  data() {
    return {
      show: false,
      refundRemark: "",
      submitLoading: false
    };
  },
  watch: {
    showDialog: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.resetForm();
        }
      },
      immediate: true
    }
  },
  methods: {
    resetForm() {
      this.refundRemark = "";
    },

    onCancelDialog() {
      this.show = false;
      this.$emit('showOrHideDialog', false);
    },

    // 确认退款
    async confirmRefund() {
      if (!this.refundRemark.trim()) {
        this.$message.warning("请输入退款备注");
        return;
      }

      this.submitLoading = true;
      try {
        const params = {
          id: this.depositInfo.id, // 充值订单ID
          remark: this.refundRemark.trim() // 退款备注
        };

        const res = await api_vip.reqCancelDeposit(params);
        if (res.code == 1) {
          this.$message.success("退款成功");
          this.onCancelDialog();
          this.$emit('refreshTable');
        } else {
          this.$message.warning(res.msg || "退款失败");
        }
      } catch (error) {
        console.error("退款失败:", error);
        this.$message.error("退款失败，请稍后重试");
      } finally {
        this.submitLoading = false;
      }
    }
  }
};
</script>

<style scoped lang="less">
.refund-deposit-dialog {
  .dialog-content {
    padding: 15px 0;

    .refund-notice {
      background: #f0f9ff;
      border: 1px solid #bfdbfe;
      border-radius: 8px;
      padding: 15px;
      margin-bottom: 20px;

      p {
        margin: 0;
        color: #1e40af;
        font-size: 14px;
        line-height: 1.6;
      }
    }

    .deposit-info {
      background: #f5f7fa;
      border-radius: 8px;
      padding: 15px;
      margin-bottom: 20px;

      .info-row {
        display: flex;
        align-items: center;
        margin-bottom: 12px;

        &:last-child {
          margin-bottom: 0;
        }

        .label {
          width: 120px;
          color: #606266;
          font-size: 14px;
        }

        .value {
          color: #303133;
          font-size: 14px;
          font-weight: 500;

          &.amount {
            color: #e6a23c;
            font-weight: 600;
            font-size: 16px;
          }
        }
      }
    }

    .remark-section {
      .section-title {
        font-size: 14px;
        color: #303133;
        margin-bottom: 12px;
        font-weight: 500;
      }
    }
  }

  .dialog-footer {
    text-align: center;
    padding: 15px 0 0 0;
  }
}

// 响应式适配
@media (orientation: portrait) {
  .refund-deposit-dialog {
    width: 95% !important;
    
    .dialog-content {
      .refund-notice {
        padding: 12px;
        
        p {
          font-size: 13px;
        }
      }
      
      .deposit-info {
        padding: 12px;
        
        .info-row {
          margin-bottom: 10px;
          
          .label {
            width: 100px;
            font-size: 13px;
          }
          
          .value {
            font-size: 13px;
            
            &.amount {
              font-size: 15px;
            }
          }
        }
      }
      
      .remark-section {
        .section-title {
          font-size: 13px;
        }
      }
    }
  }
}

@media (max-width: 900px) {
  .refund-deposit-dialog {
    width: 95% !important;
  }
}
</style>

<style>
.refund-deposit-dialog .el-dialog {
  max-width: 800px;
  max-height: 90vh;
  margin-top: 2vh !important;
}

.refund-deposit-dialog .el-dialog__body {
  padding: 15px !important;
}

.refund-deposit-dialog .el-textarea__inner {
  background: #f5f7fa;
  border: 1px solid #dcdfe6;
  border-radius: 6px;
  font-size: 14px;
}

.refund-deposit-dialog .el-textarea__inner:focus {
  border-color: #409eff;
}
</style>
