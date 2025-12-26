<template>
  <div class="drawer-choose-turnback">
    <el-dialog
      title="复台"
      :visible.sync="dialogVisible"
      width="800px"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      @close="handleClose"
    >
      <div class="turnback-content">
        <div class="tip-text">
          <span style="color: #f56c6c;">*</span>请选择要复台的流水：
        </div>

        <el-table
          :data="turnbackList"
          class="turnback-table"
          highlight-current-row
          @current-change="handleCurrentChange"
          :default-sort="{ prop: 'o', order: 'descending' }"
        >
          <el-table-column width="80" label="序号" align="center">
            <template slot-scope="scope">
              <el-radio
                v-model="selectedCsmId"
                :label="scope.row.id"
                @change="handleRadioChange(scope.row)"
              >
                {{ scope.$index + 1 }}
              </el-radio>
            </template>
          </el-table-column>

          <el-table-column
            prop="o"
            label="开台时间"
            align="center"
            min-width="180"
          >
          </el-table-column>

          <el-table-column
            prop="s"
            label="订位人"
            align="center"
            min-width="120"
          >
          </el-table-column>
        </el-table>
      </div>

      <div slot="footer" class="dialog-footer">
        <el-button @click="handleCancel" class="cancel-btn">取消</el-button>
        <el-button type="primary" @click="handleConfirm" class="confirm-btn">
          确定
        </el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import api_money from "@/api/money";

export default {
  name: "DrawerChooseTurnback",
  props: {
    visible: {
      type: Boolean,
      default: false,
    },
    seatId: {
      type: [Number, String],
      default: null,
    },
  },
  data() {
    return {
      dialogVisible: false,
      turnbackList: [],
      selectedCsmId: null,
      selectedRow: null,
    };
  },
  watch: {
    visible: {
      handler(val) {
        this.dialogVisible = val;
        if (val) {
          this.getTurnbackList();
        }
      },
      immediate: true,
    },
  },
  methods: {
    // 获取待复台流水列表
    async getTurnbackList() {
      try {
        const res = await api_money.reqGetSeatTurnbackList({
          id: this.seatId * 1, // int64 卡台Id
        });

        if (res.code === 1) {
          this.turnbackList = res.data.records || [];
          
          // 默认选中最后一笔流水（按开台时间最近的）
          if (this.turnbackList.length > 0) {
            // 按开台时间降序排序
            this.turnbackList.sort((a, b) => {
              return new Date(b.o) - new Date(a.o);
            });
            
            // 默认选中第一个（最新的）
            this.selectedCsmId = this.turnbackList[0].id;
            this.selectedRow = this.turnbackList[0];
          }
        } else {
          this.$message.warning(res.msg || "获取流水列表失败");
        }
      } catch (error) {
        console.error("获取待复台流水列表失败:", error);
        this.$message.error("获取流水列表失败");
      }
    },

    // 单选框改变
    handleRadioChange(row) {
      this.selectedRow = row;
    },

    // 当前行改变
    handleCurrentChange(row) {
      if (row) {
        this.selectedCsmId = row.id;
        this.selectedRow = row;
      }
    },

    // 确认选择
    handleConfirm() {
      if (!this.selectedCsmId) {
        this.$message.warning("请选择要复台的流水");
        return;
      }

      this.$emit("confirm", {
        csmId: this.selectedCsmId,
        row: this.selectedRow,
      });
      this.handleClose();
    },

    // 取消
    handleCancel() {
      this.handleClose();
    },

    // 关闭对话框
    handleClose() {
      this.selectedCsmId = null;
      this.selectedRow = null;
      this.turnbackList = [];
      this.$emit("update:visible", false);
      this.$emit("close");
    },
  },
};
</script>

<style lang="less" scoped>
.drawer-choose-turnback {
  /deep/ .el-dialog {
    max-width: 95%;
    margin-top: 2vh !important;
    border-radius: 8px;

    @media (max-width: 900px), (orientation: portrait) {
      width: 95% !important;
      margin-top: 1vh !important;
    }
  }

  /deep/ .el-dialog__header {
    padding: 15px;
    border-bottom: 1px solid #e8e8e8;

    .el-dialog__title {
      font-size: 18px;
      font-weight: 600;
      color: #333;
    }
  }

  /deep/ .el-dialog__body {
    padding: 15px;
    max-height: 70vh;
    overflow-y: auto;
  }

  /deep/ .el-dialog__footer {
    padding: 15px;
    border-top: 1px solid #e8e8e8;
  }

  .turnback-content {
    .tip-text {
      font-size: 14px;
      color: #333;
      margin-bottom: 15px;
      font-weight: 500;
    }

    .turnback-table {
      width: 100%;
      margin-bottom: 15px;

      /deep/ .el-table__header {
        th {
          background-color: #f5f7fa;
          color: #606266;
          font-weight: 600;
          font-size: 14px;
          height: 44px;
          padding: 8px 0;
        }
      }

      /deep/ .el-table__body {
        tr {
          height: 44px;

          td {
            padding: 8px 0;
            font-size: 14px;
          }
        }

        tr:hover {
          background-color: #f5f7fa;
        }
      }

      /deep/ .el-radio {
        .el-radio__label {
          font-size: 14px;
          color: #606266;
        }
      }
    }

    .warning-box {
      background: #fffbe6;
      border: 1px solid #ffe58f;
      border-radius: 6px;
      padding: 15px;
      margin-top: 15px;

      p {
        margin: 0;
        font-size: 14px;
        line-height: 1.6;
        color: #333;
      }
    }
  }

  .dialog-footer {
    display: flex;
    justify-content: flex-end;
    gap: 10px;

    .cancel-btn,
    .confirm-btn {
      min-width: 100px;
      height: 38px;
      font-size: 14px;
      border-radius: 6px;
    }

    .cancel-btn {
      border: 1px solid #dcdfe6;
      color: #606266;
      background: #fff;

      &:hover {
        color: #409eff;
        border-color: #c6e2ff;
        background-color: #ecf5ff;
      }
    }

    .confirm-btn {
      background-color: #409eff;
      border-color: #409eff;
      color: #fff;

      &:hover {
        background-color: #66b1ff;
        border-color: #66b1ff;
      }
    }
  }
}

// 响应式适配
@media (orientation: portrait) {
  .drawer-choose-turnback {
    .turnback-content {
      .turnback-table {
        /deep/ .el-table__header th,
        /deep/ .el-table__body td {
          font-size: 12px;
          padding: 6px 0;
        }
      }

      .warning-box {
        padding: 12px;

        p {
          font-size: 12px;
        }
      }
    }

    .dialog-footer {
      .cancel-btn,
      .confirm-btn {
        height: 36px;
        font-size: 13px;
        min-width: 90px;
      }
    }
  }
}

@media (max-width: 900px) {
  .drawer-choose-turnback {
    /deep/ .el-dialog__header .el-dialog__title {
      font-size: 16px;
    }

    .turnback-content {
      .tip-text {
        font-size: 13px;
      }
    }
  }
}
</style>

