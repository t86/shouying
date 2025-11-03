<template>
  <div>
    <!-- 批量修改授权人弹窗 -->
    <el-dialog
      title="批量修改授权人"
      :visible.sync="show"
      :before-close="onCancelDialog"
      width="1000px"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      append-to-body
      class="batch-update-auther-dialog"
    >
      <div class="dialog-content">
        
        <!-- 订单列表 -->
        <div class="order-list">
          <div class="order-header">
            <div class="col col-check">
              <el-checkbox v-model="checkAll" @change="handleCheckAll"></el-checkbox>
            </div>
            <div class="col col-name">名称</div>
            <div class="col col-cnt">数量</div>
            <div class="col col-price">单价</div>
            <div class="col col-total">小计</div>
            <div class="col col-waiter">服务员</div>
            <div class="col col-auth">授权人</div>
            <div class="col col-time">点单时间</div>
          </div>
          <div class="order-body">
            <div
              v-for="(item, index) in authOrderList"
              :key="index"
              class="order-row"
              :class="{ selected: item.checked }"
            >
              <div class="col col-check">
                <el-checkbox v-model="item.checked" @change="handleCheckItem"></el-checkbox>
              </div>
              <div class="col col-name">{{ item.productInfo ? item.productInfo.name : '' }}</div>
              <div class="col col-cnt">{{ item.pc }}</div>
              <div class="col col-price">{{ item.pp * 1 == 0 ? '时价' : (item.pp * 1).toFixed(2) }}</div>
              <div class="col col-total">{{ (item.pp * 1 == 0 ? item.pa * 1 : item.pp * item.pc).toFixed(2) }}</div>
              <div class="col col-waiter">{{ item.personInfo ? item.personInfo.name : '自助' }}</div>
              <div class="col col-auth">{{ item.authInfo ? item.authInfo.name : '——' }}</div>
              <div class="col col-time">{{ item.ot ? item.ot.slice(7) : '' }}</div>
              
              <!-- 套餐明细 -->
              <div v-if="item.is == 1 && item.si && item.si.length > 0" class="meal-detail">
                <div
                  v-for="(subItem, subIndex) in item.si"
                  :key="subIndex"
                  class="meal-detail-row"
                >
                  <div class="col col-check"></div>
                  <div class="col col-name">{{ subItem.groupInfo ? subItem.groupInfo.name : '' }}</div>
                  <div class="col col-cnt">{{ subItem.sc * subItem.dpc * item.pc }}</div>
                  <div class="col col-price"></div>
                  <div class="col col-total"></div>
                  <div class="col col-waiter"></div>
                  <div class="col col-auth"></div>
                  <div class="col col-time"></div>
                </div>
              </div>
            </div>
            <p v-if="authOrderList.length === 0" class="empty-tip">暂无含授权人的订单</p>
          </div>
        </div>

        <!-- 授权人选择 -->
        <div class="auther-section">
          <div class="label">
            <span class="required">*</span>
            <span>请选择授权人：</span>
          </div>
          <div class="input-area">
            <input-select
              :autoFocus="false"
              style="width: 260px"
              :value="autherInfo.name"
              placeholder="输入姓名或工号"
              :optionsList="autherOptions"
              @selectInputHandle="inputAutherName"
              @selectOptionItem="changeAutherName"
              @selectBlurHandle="selectBlurHandle"
            ></input-select>
          </div>
        </div>
      </div>

      <div slot="footer" class="dialog-footer">
        <el-button @click="onCancelDialog">取消</el-button>
        <el-button type="primary" @click="onSubmit" :loading="loading">确定</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import api_money from "@/api/money";
import inputSelect from "@/components/book/inputSelect";

export default {
  components: {
    inputSelect,
  },
  props: {
    showDrawer: {
      type: Boolean,
      default: false,
    },
    orderList: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      show: false,
      checkAll: true,
      loading: false,
      autherInfo: {
        id: 0,
        name: "",
      },
      autherOptions: [],
    };
  },
  computed: {
    // 只显示含授权人的订单（at == 8 表示特饮类型需要授权）
    authOrderList() {
      return this.orderList.filter(item => {
        // 特饮类型(at == 8)有授权人
        return item.at == 8;
      });
    },
  },
  watch: {
    showDrawer(val) {
      this.show = val;
      if (val) {
        this.initData();
      }
    },
  },
  methods: {
    initData() {
      // 初始化时全部勾选
      this.authOrderList.forEach((item) => {
        item.checked = true;
      });
      this.checkAll = true;
      this.autherInfo = {
        id: 0,
        name: "",
      };
    },

    handleCheckAll() {
      this.authOrderList.forEach((item) => {
        item.checked = this.checkAll;
      });
    },

    handleCheckItem() {
      this.checkAll = this.authOrderList.every(item => item.checked);
    },

    inputAutherName(val) {
      this.autherInfo.name = val;
      if (!val) {
        this.autherOptions = [];
        return;
      }
      // 从 store 中获取员工列表并过滤
      const sealInfoArr =
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      const results = sealInfoArr.filter(
        (el) =>
          el.code.toString().includes(val) ||
          el.name.toString().includes(val) ||
          el.namePy.toString().includes(val.toLowerCase())
      );
      this.autherOptions = results.map((item) => ({
        id: item.id,
        name: item.name,
        code: item.code,
        deptName: item.deptName || "",
      }));
    },

    changeAutherName(item) {
      this.autherInfo = {
        id: item.id,
        name: item.name,
      };
    },

    selectBlurHandle() {
      setTimeout(() => {
        this.autherOptions = [];
      }, 200);
    },

    async onSubmit() {
      const selectedOrders = this.authOrderList.filter((item) => item.checked);
      if (selectedOrders.length === 0) {
        this.$message.warning("请至少选择一个订单");
        return;
      }
      if (!this.autherInfo.id) {
        this.$message.warning("请选择授权人");
        return;
      }

      this.loading = true;
      let successCount = 0;
      let failCount = 0;

      for (const order of selectedOrders) {
        try {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
            order_id: order.id * 1,
            auth_emp_id: this.autherInfo.id * 1,
          };
          const res = await api_money.chg_wkorder_auther(params);
          if (res.code == 1) {
            successCount++;
          } else {
            failCount++;
            console.log(`订单${order.id}修改失败:`, res.msg);
          }
        } catch (error) {
          failCount++;
          console.log(`订单${order.id}修改失败:`, error);
        }
      }

      this.loading = false;

      if (successCount > 0) {
        this.$message.success(
          `批量修改完成！成功${successCount}个${failCount > 0 ? `，失败${failCount}个` : ""}`
        );
        this.$emit("success");
        this.onCancelDialog();
      } else {
        this.$message.error("批量修改失败，请重试");
      }
    },

    onCancelDialog() {
      this.show = false;
      this.$emit("showOrHideDrawer");
    },
  },
};
</script>

<style scoped lang="less">
.batch-update-auther-dialog {
  /deep/ .el-dialog {
    max-height: 90vh;
    margin-top: 2vh !important;
    border-radius: 8px;
    background: #fff;
    display: flex;
    flex-direction: column;
    overflow: visible;
  }

  /deep/ .el-dialog__header {
    padding: 15px;
    background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
    border-radius: 8px 8px 0 0;
    flex-shrink: 0;

    .el-dialog__title {
      color: #fff;
      font-size: 18px;
      font-weight: 500;
    }

    .el-dialog__close {
      color: #fff;
      font-size: 20px;
    }
  }

  /deep/ .el-dialog__body {
    padding: 15px;
    flex: 1;
    overflow: visible;
    position: relative;
    z-index: 1;
  }

  /deep/ .el-dialog__footer {
    padding: 15px;
    border-top: 1px solid #e8e8e8;
    flex-shrink: 0;
  }
}

.dialog-content {
  .tip {
    margin-bottom: 15px;
    font-size: 14px;
    color: #333;
    line-height: 1.6;

    .highlight {
      color: #f5576c;
      font-weight: 500;
    }

    .tip-sub {
      color: #999;
      font-size: 12px;
    }
  }

  .order-list {
    margin-bottom: 20px;
    border: 1px solid #e8e8e8;
    border-radius: 6px;
    max-height: 350px;
    overflow-x: hidden;
    overflow-y: auto;

    .order-header {
      display: flex;
      align-items: center;
      background: #f5f7fa;
      padding: 10px 15px;
      font-size: 13px;
      font-weight: 500;
      color: #333;
      border-bottom: 1px solid #e8e8e8;
      position: sticky;
      top: 0;
      z-index: 2;
      background-clip: padding-box;
    }

    .order-body {
      .order-row {
        display: flex;
        align-items: center;
        padding: 10px 15px;
        font-size: 13px;
        color: #666;
        border-bottom: 1px solid #f0f0f0;
        transition: background 0.2s;

        &:hover {
          background: #f9f9f9;
        }

        &.selected {
          background: #fff0f0;
        }

        &:last-child {
          border-bottom: none;
        }
      }

      .meal-detail {
        padding-left: 40px;

        .meal-detail-row {
          display: flex;
          align-items: center;
          padding: 6px 15px;
          font-size: 12px;
          color: #999;
        }
      }

      .empty-tip {
        padding: 40px 0;
        text-align: center;
        color: #999;
        font-size: 14px;
      }
    }

    .col {
      padding: 0 8px;

      &.col-check {
        width: 50px;
        flex-shrink: 0;
        position: relative;
        z-index: 0;
        
        /deep/ .el-checkbox {
          position: relative;
          z-index: 0;
        }
      }

      &.col-name {
        flex: 1;
        min-width: 120px;
      }

      &.col-cnt {
        width: 60px;
        flex-shrink: 0;
        text-align: center;
      }

      &.col-price {
        width: 80px;
        flex-shrink: 0;
        text-align: right;
      }

      &.col-total {
        width: 90px;
        flex-shrink: 0;
        text-align: right;
      }

      &.col-waiter {
        width: 90px;
        flex-shrink: 0;
      }

      &.col-auth {
        width: 90px;
        flex-shrink: 0;
      }

      &.col-time {
        width: 120px;
        flex-shrink: 0;
      }
    }
  }

  .auther-section {
    display: flex;
    align-items: center;
    padding: 15px;
    background: #fff9f9;
    border-radius: 6px;
    border: 1px solid #ffe0e0;
    margin-bottom: 150px;

    .label {
      font-size: 14px;
      color: #333;
      margin-right: 15px;
      white-space: nowrap;

      .required {
        color: #f56c6c;
        margin-right: 4px;
      }
    }

    .input-area {
      flex: 1;
      position: relative;
      z-index: 100;
    }
  }
}

// 确保下拉列表层级足够高
/deep/ .el-select-dropdown {
  z-index: 3000 !important;
}

/deep/ .select-option {
  z-index: 3000 !important;
}

.dialog-footer {
  text-align: right;

  .el-button {
    min-width: 80px;
    height: 38px;
    font-size: 14px;
  }
}

// 响应式适配
@media (max-width: 1100px) {
  .batch-update-auther-dialog {
    /deep/ .el-dialog {
      width: 95% !important;
      max-width: 95%;
    }
  }
}

@media (orientation: portrait) {
  .batch-update-auther-dialog {
    /deep/ .el-dialog {
      width: 95% !important;
      max-width: 95%;
      margin-top: 1vh !important;
    }
  }
}
</style>

