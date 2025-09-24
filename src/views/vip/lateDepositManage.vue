<template>
  <div class="late-deposit-manage">
    <!-- 页面标题 -->
    <div class="page-header">
      <h2>滞留金管理</h2>
      <p class="page-desc">管理充值滞留金记录，支持退款操作</p>
    </div>

    <!-- 搜索区域 -->
    <div class="search-section">
      <div class="search-form" layout="row" layout-align="start center">
        <div class="search-input-group">
          <input
            type="text"
            v-model="searchForm.key"
            placeholder="会员卡号/手机号/姓名"
            class="search-input"
            @keyup.enter="handleSearch"
          />
        </div>
        <button class="btn-primary" @click="handleSearch">
          <span>查询</span>
        </button>
        <button class="btn-secondary" @click="handleReset">
          <span>重置</span>
        </button>
      </div>
    </div>

    <!-- 数据表格 -->
    <div class="table-section">
      <div class="table-container">
        <div class="table-header">
          <div class="th">序号</div>
          <div class="th">会员卡号</div>
          <div class="th">姓名</div>
          <div class="th">手机号</div>
          <div class="th">支付渠道</div>
          <div class="th">支付金额</div>
          <div class="th">操作时间</div>
          <div class="th">备注</div>
          <div class="th">操作</div>
        </div>
        
        <div class="table-body" v-if="lateDepositList.length > 0">
          <div 
            class="table-row" 
            v-for="(item, index) in lateDepositList" 
            :key="item.id"
          >
            <div class="td">{{ index + 1 }}</div>
            <div class="td">{{ item.c }}</div>
            <div class="td">{{ item.n }}</div>
            <div class="td">{{ item.p }}</div>
            <div class="td">{{ item.l }}</div>
            <div class="td">￥{{ formatAmount(item.a) }}</div>
            <div class="td">{{ item.o }}</div>
            <div class="td">{{ item.r }}</div>
            <div class="td">
              <button 
                class="btn-refund" 
                @click="handleRefund(item)"
                :disabled="item.processing"
              >
                {{ item.processing ? '退款中...' : '退款' }}
              </button>
            </div>
          </div>
        </div>

        <!-- 无数据状态 -->
        <div class="no-data" v-else-if="!loading">
          <p>暂无滞留金记录</p>
        </div>

        <!-- 加载状态 -->
        <div class="loading" v-if="loading">
          <p>数据加载中...</p>
        </div>
      </div>
    </div>

    <!-- 退款确认对话框 -->
    <div class="dialog-overlay" v-if="refundDialog.visible" @click="closeRefundDialog">
      <div class="refund-dialog-container" @click.stop>
        <div class="refund-dialog-header">
          <h3>退款</h3>
          <button class="refund-dialog-close" @click="closeRefundDialog">×</button>
        </div>
        
        <div class="refund-dialog-body">
          <div class="refund-warning">
            <p>请检查以下退款信息，退款后不得撤销！请谨慎操作！操作退款后可去收银系统-异议申请中查看退款进度。</p>
          </div>
          
          <div class="refund-details">
            <div class="refund-detail-row">
              <span class="refund-label">当前卡号：</span>
              <span class="refund-value">{{ refundDialog.currentItem.c }}</span>
              <span class="refund-label phone-label">手机号：</span>
              <span class="refund-value">{{ refundDialog.currentItem.p }}</span>
            </div>
            
            <div class="refund-amount-row">
              <span class="refund-amount-label">退款金额：</span>
              <span class="refund-amount-value">￥{{ formatAmount(refundDialog.currentItem.a) }}</span>
            </div>
          </div>
        </div>
        
        <div class="refund-dialog-footer">
          <button class="refund-btn-cancel" @click="closeRefundDialog">取消</button>
          <button 
            class="refund-btn-confirm" 
            @click="confirmRefund"
            :disabled="refundDialog.processing"
          >
            {{ refundDialog.processing ? '退款中...' : '确定' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import api_vip from "@/api/vip";

export default {
  name: "LateDepositManage",
  data() {
    return {
      loading: false,
      searchForm: {
        key: "", // 搜索关键字
      },
      lateDepositList: [], // 滞留金列表
      refundDialog: {
        visible: false,
        processing: false,
        currentItem: {}, // 当前要退款的项目
      },
    };
  },
  
  mounted() {
    this.loadLateDepositList();
  },
  
  methods: {
    // 加载滞留金列表
    async loadLateDepositList() {
      this.loading = true;
      try {
        const params = {
          key: this.searchForm.key,
        };
        
        const res = await api_vip.reqGetDepositLateList(params);
        
        if (res.code === 1) {
          this.lateDepositList = res.data.records || [];
        } else {
          this.$message.warning(res.msg || '获取滞留金列表失败');
          this.lateDepositList = [];
        }
      } catch (error) {
        console.error('获取滞留金列表失败:', error);
        this.$message.error('获取滞留金列表失败');
        this.lateDepositList = [];
      } finally {
        this.loading = false;
      }
    },
    
    // 搜索
    handleSearch() {
      this.loadLateDepositList();
    },
    
    // 重置搜索
    handleReset() {
      this.searchForm.key = "";
      this.loadLateDepositList();
    },
    
    // 格式化金额（分转元）
    formatAmount(amount) {
      if (!amount) return '0.00';
      return (amount / 100).toFixed(2);
    },
    
    // 处理退款
    handleRefund(item) {
      this.refundDialog.currentItem = { ...item };
      this.refundDialog.visible = true;
    },
    
    // 关闭退款对话框
    closeRefundDialog() {
      this.refundDialog.visible = false;
      this.refundDialog.processing = false;
      this.refundDialog.currentItem = {};
    },
    
    // 确认退款
    async confirmRefund() {
      this.refundDialog.processing = true;
      
      try {
        const params = {
          id: this.refundDialog.currentItem.id,
        };
        
        const res = await api_vip.reqBackDepositLate(params);
        
        if (res.code === 1) {
          this.$message.success('退款成功');
          this.closeRefundDialog();
          // 重新加载列表
          this.loadLateDepositList();
        } else {
          this.$message.warning(res.msg || '退款失败');
        }
      } catch (error) {
        console.error('退款失败:', error);
        this.$message.error('退款失败');
      } finally {
        this.refundDialog.processing = false;
      }
    },
  },
};
</script>

<style scoped>
.late-deposit-manage {
  padding: 20px;
  background: #f5f5f5;
  min-height: 100vh;
}

/* 页面头部 */
.page-header {
  background: #fff;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.page-header h2 {
  margin: 0 0 8px 0;
  color: #333;
  font-size: 24px;
  font-weight: 500;
}

.page-desc {
  margin: 0;
  color: #666;
  font-size: 14px;
}

/* 搜索区域 */
.search-section {
  background: #fff;
  padding: 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.search-form {
  gap: 15px;
}

.search-input-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.search-input-group label {
  font-size: 14px;
  color: #333;
  white-space: nowrap;
}

.search-input {
  width: 300px;
  height: 38px;
  padding: 0 12px;
  border: 1px solid #dcdfe6;
  border-radius: 6px;
  font-size: 14px;
  outline: none;
  transition: border-color 0.2s;
}

.search-input:focus {
  border-color: #409eff;
}

.btn-primary, .btn-secondary {
  height: 38px;
  padding: 0 20px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-primary {
  background: #409eff;
  color: #fff;
}

.btn-primary:hover {
  background: #337ecc;
}

.btn-secondary {
  background: #909399;
  color: #fff;
}

.btn-secondary:hover {
  background: #767a82;
}

/* 表格区域 */
.table-section {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.table-container {
  width: 100%;
  min-width: 1200px;
}

.table-header {
  display: flex;
  background: #f8f9fa;
  border-bottom: 1px solid #e9ecef;
}

.table-header .th {
  padding: 15px;
  font-weight: 500;
  color: #333;
  border-right: 1px solid #e9ecef;
  text-align: center;
}

.table-header .th:nth-child(1) { width: 80px; }   /* 序号 */
.table-header .th:nth-child(2) { width: 120px; }  /* 会员卡号 */
.table-header .th:nth-child(3) { width: 100px; }  /* 姓名 */
.table-header .th:nth-child(4) { width: 130px; }  /* 手机号 */
.table-header .th:nth-child(5) { width: 100px; }  /* 支付渠道 */
.table-header .th:nth-child(6) { width: 120px; }  /* 支付金额 */
.table-header .th:nth-child(7) { width: 160px; }  /* 操作时间 */
.table-header .th:nth-child(8) { flex: 1; }       /* 备注 */
.table-header .th:nth-child(9) { width: 100px; }  /* 操作 */

.table-body {
  max-height: 600px;
  overflow-y: auto;
}

.table-row {
  display: flex;
  border-bottom: 1px solid #e9ecef;
  transition: background-color 0.2s;
}

.table-row:hover {
  background: #f8f9fa;
}

.table-row .td {
  padding: 15px;
  color: #333;
  border-right: 1px solid #e9ecef;
  display: flex;
  align-items: center;
  justify-content: center;
  word-break: break-all;
}

.table-row .td:nth-child(1) { width: 80px; }   /* 序号 */
.table-row .td:nth-child(2) { width: 120px; }  /* 会员卡号 */
.table-row .td:nth-child(3) { width: 100px; }  /* 姓名 */
.table-row .td:nth-child(4) { width: 130px; }  /* 手机号 */
.table-row .td:nth-child(5) { width: 100px; }  /* 支付渠道 */
.table-row .td:nth-child(6) { width: 120px; }  /* 支付金额 */
.table-row .td:nth-child(7) { width: 160px; }  /* 操作时间 */
.table-row .td:nth-child(8) { flex: 1; justify-content: flex-start; } /* 备注 */
.table-row .td:nth-child(9) { width: 100px; }  /* 操作 */

.btn-refund {
  height: 32px;
  padding: 0 12px;
  background: #f56c6c;
  color: #fff;
  border: none;
  border-radius: 4px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-refund:hover:not(:disabled) {
  background: #f45454;
}

.btn-refund:disabled {
  background: #c0c4cc;
  cursor: not-allowed;
}

/* 无数据/加载状态 */
.no-data, .loading {
  padding: 60px 20px;
  text-align: center;
  color: #909399;
}

/* 退款对话框样式 */
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}

.refund-dialog-container {
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
  width: 480px;
  max-width: 90%;
  overflow: hidden;
}

.refund-dialog-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid #e5e5e5;
  background: #f8f9fa;
}

.refund-dialog-header h3 {
  margin: 0;
  color: #333;
  font-size: 16px;
  font-weight: 500;
}

.refund-dialog-close {
  width: 24px;
  height: 24px;
  border: none;
  background: none;
  font-size: 18px;
  color: #999;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 2px;
  transition: all 0.2s;
}

.refund-dialog-close:hover {
  background: #f0f0f0;
  color: #666;
}

.refund-dialog-body {
  padding: 24px;
}

.refund-warning {
  margin-bottom: 20px;
}

.refund-warning p {
  margin: 0;
  color: #333;
  font-size: 14px;
  line-height: 1.5;
}

.refund-details {
  margin-bottom: 20px;
}

.refund-detail-row {
  display: flex;
  align-items: center;
  margin-bottom: 16px;
}

.refund-label {
  color: #333;
  font-size: 14px;
  margin-right: 8px;
}

.refund-label.phone-label {
  margin-left: 24px;
}

.refund-value {
  color: #e74c3c;
  font-size: 14px;
  font-weight: 500;
}

.refund-amount-row {
  display: flex;
  align-items: center;
}

.refund-amount-label {
  color: #333;
  font-size: 14px;
  margin-right: 8px;
}

.refund-amount-value {
  color: #e74c3c;
  font-size: 20px;
  font-weight: 600;
}

.refund-dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 20px 24px;
  border-top: 1px solid #e5e5e5;
  background: #f8f9fa;
}

.refund-btn-cancel {
  height: 36px;
  padding: 0 20px;
  background: #fff;
  color: #666;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.refund-btn-cancel:hover {
  border-color: #409eff;
  color: #409eff;
}

.refund-btn-confirm {
  height: 36px;
  padding: 0 20px;
  background: #409eff;
  color: #fff;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.refund-btn-confirm:hover:not(:disabled) {
  background: #337ecc;
}

.refund-btn-confirm:disabled {
  background: #c0c4cc;
  cursor: not-allowed;
}

/* 响应式适配 */
@media (orientation: portrait) {
  .late-deposit-manage {
    padding: 15px;
  }
  
  .search-form {
    flex-direction: column;
    align-items: stretch;
    gap: 10px;
  }
  
  .search-input-group {
    flex-direction: column;
    align-items: flex-start;
    gap: 5px;
  }
  
  .search-input {
    width: 100%;
  }
  
  .table-container {
    min-width: 800px;
    overflow-x: auto;
  }
  
  .dialog-container {
    width: 95%;
  }
}

@media (max-width: 900px) {
  .late-deposit-manage {
    padding: 10px;
  }
  
  .table-container {
    min-width: 700px;
  }
}
</style>
