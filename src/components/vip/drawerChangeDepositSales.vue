<template>
  <div>
    <!-- 修改充值推荐人弹窗 -->
    <el-dialog
      title="修改充值推荐人"
      :visible.sync="show"
      :before-close="onCancelDialog"
      width="800px"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      append-to-body
      class="change-deposit-sales-dialog"
    >
      <div class="dialog-content">
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
            <span class="label">充值金额：</span>
            <span class="value amount">￥{{ depositInfo.va }}</span>
          </div>
          <div class="info-row">
            <span class="label">当前推荐人：</span>
            <span class="value">{{ depositInfo.sd }}-{{ depositInfo.s }}</span>
          </div>
        </div>

        <!-- 推荐人选择 -->
        <div class="recommender-section">
          <div class="section-title">选择新推荐人：</div>
          <el-select
            v-model="selectedRecommenderId"
            placeholder="输入员工姓名或工号进行查询"
            filterable
            remote
            :remote-method="searchEmployee"
            style="width: 100%;"
            size="medium"
            clearable
            :loading="searchLoading"
          >
            <el-option
              v-for="emp in employeeOptions"
              :key="emp.id"
              :label="`${emp.name}${emp.code ? ' (' + emp.code + ')' : ''}`"
              :value="emp.id"
            />
          </el-select>
          <div class="recommender-tip" v-if="selectedRecommenderId">
            <span class="tip-text">请确认选择的推荐人信息</span>
          </div>
        </div>
      </div>

      <div slot="footer" class="dialog-footer">
        <el-button @click="onCancelDialog" size="medium">取消</el-button>
        <el-button 
          type="primary" 
          @click="confirmChange" 
          size="medium"
          :loading="submitLoading"
          :disabled="!selectedRecommenderId"
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
  name: "DrawerChangeDepositSales",
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
      selectedRecommenderId: null,
      employeeOptions: [],
      searchLoading: false,
      submitLoading: false
    };
  },
  watch: {
    showDialog: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.resetForm();
          this.loadInitialEmployees();
        }
      },
      immediate: true
    }
  },
  methods: {
    resetForm() {
      this.selectedRecommenderId = null;
      this.employeeOptions = [];
    },

    onCancelDialog() {
      this.show = false;
      this.$emit('showOrHideDialog', false);
    },

    // 加载初始员工列表
    async loadInitialEmployees() {
      if (this.employeeOptions.length === 0) {
        await this.searchEmployee("");
      }
    },

    // 搜索员工
    async searchEmployee(query) {
      this.searchLoading = true;
      try {
        // 从store中获取员工信息
        const cardPageInfo = this.$store.state.cardPageInfo;
        const resResultDataObj = cardPageInfo && cardPageInfo.resResultDataObj;
        const orderPersonInfo = (resResultDataObj && resResultDataObj.orderPersonInfo) || [];
        
        if (orderPersonInfo.length > 0) {
          // 根据查询条件过滤员工
          const filteredEmployees = query 
            ? orderPersonInfo.filter(emp => 
                emp.name.includes(query) || 
                emp.code.toString().includes(query) ||
                (emp.namePy && emp.namePy.toLowerCase().includes(query.toLowerCase()))
              )
            : orderPersonInfo;
          
          this.employeeOptions = filteredEmployees.map(emp => ({
            id: emp.id,
            name: emp.name,
            code: emp.code
          }));
        } else {
          this.employeeOptions = [];
        }
      } catch (error) {
        console.error("搜索员工失败:", error);
        this.employeeOptions = [];
      } finally {
        this.searchLoading = false;
      }
    },

    // 确认修改
    async confirmChange() {
      if (!this.selectedRecommenderId) {
        this.$message.warning("请选择新的推荐人");
        return;
      }

      this.submitLoading = true;
      try {
        const params = {
          id: this.depositInfo.id, // 充值订单ID
          sales_emp_id: this.selectedRecommenderId * 1 // 推荐人ID
        };

        const res = await api_vip.reqChangeDepositSales(params);
        if (res.code == 1) {
          this.$message.success("修改充值推荐人成功");
          this.onCancelDialog();
          this.$emit('refreshTable');
        } else {
          this.$message.warning(res.msg || "修改失败");
        }
      } catch (error) {
        console.error("修改充值推荐人失败:", error);
        this.$message.error("修改失败，请稍后重试");
      } finally {
        this.submitLoading = false;
      }
    }
  }
};
</script>

<style scoped lang="less">
.change-deposit-sales-dialog {
  .dialog-content {
    padding: 15px 0;

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
          }
        }
      }
    }

    .recommender-section {
      .section-title {
        font-size: 14px;
        color: #303133;
        margin-bottom: 12px;
        font-weight: 500;
      }

      .recommender-tip {
        margin-top: 8px;

        .tip-text {
          font-size: 12px;
          color: #909399;
        }
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
  .change-deposit-sales-dialog {
    width: 95% !important;
    
    .dialog-content {
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
          }
        }
      }
      
      .recommender-section {
        .section-title {
          font-size: 13px;
        }
      }
    }
  }
}

@media (max-width: 900px) {
  .change-deposit-sales-dialog {
    width: 95% !important;
  }
}
</style>

<style>
.change-deposit-sales-dialog .el-dialog {
  max-width: 800px;
  max-height: 90vh;
  margin-top: 2vh !important;
}

.change-deposit-sales-dialog .el-dialog__body {
  padding: 15px !important;
}

.change-deposit-sales-dialog .el-select-dropdown__empty {
  background-color: #bec5d5 !important;
}

.change-deposit-sales-dialog .el-scrollbar .el-scrollbar__view.el-select-dropdown__list {
  background-color: #bec5d5 !important;
}

.change-deposit-sales-dialog .el-select-dropdown__item {
  color: #1a1a21;
}

.change-deposit-sales-dialog .el-select-dropdown__item.hover,
.change-deposit-sales-dialog .el-select-dropdown__item:hover {
  background-color: rgba(90, 90, 90, 0.5) !important;
}
</style>
