<template>
  <div class="region-income-drawer">
    <el-drawer
      title="区域实时营收"
      :visible.sync="show"
      direction="rtl"
      size="92%"
      :before-close="handleClose"
      custom-class="region-income-drawer-panel"
      append-to-body
    >
      <div class="drawer-content">
        <div class="top" layout="row" layout-align="space-between center">
          <div class="top-left" layout="row" layout-align="start center">
            <span class="label">区域：</span>
            <el-select
              class="filter-select"
              v-model="form.regionId"
              placeholder="请选择区域"
              filterable
              clearable
              @clear="handleReset"
            >
              <el-option
                v-for="option in regionOptions"
                :key="option.value"
                :label="option.label"
                :value="option.value"
              />
            </el-select>
            <el-button type="primary" class="m-l-2" @click="handleQuery">
              查询
            </el-button>
            <el-button type="info" @click="handleReset">重置</el-button>
          </div>
          <el-button
            type="primary"
            :loading="exportLoading"
            @click="handleExport"
          >
            导出Excel
          </el-button>
        </div>

        <div class="table-wrapper">
          <el-table
            class="dark-table"
            :data="tableRenderData"
            v-loading="loading"
            border
            stripe
            empty-text="暂无数据"
            :row-class-name="rowClassName"
            :header-cell-style="{ textAlign: 'center' }"
            :cell-style="{ textAlign: 'center' }"
          >
            <el-table-column
              prop="regionName"
              label="区域"
              min-width="120"
              fixed
            />
            <el-table-column
              prop="tableCount"
              label="开台数汇总"
              min-width="120"
              fixed
            >
              <template slot-scope="scope">
                <span class="table-count-text">{{ scope.row.tableCount || 0 }}</span>
              </template>
            </el-table-column>
            <el-table-column label="主营" align="center">
              <el-table-column
                prop="mainPaid"
                label="已收款"
                min-width="130"
                :formatter="cellFormatter"
              />
              <el-table-column
                prop="mainUnpaid"
                label="未收款"
                min-width="130"
                :formatter="cellFormatter"
              />
              <el-table-column
                prop="mainTotal"
                label="总额"
                min-width="130"
                :formatter="cellFormatter"
              />
            </el-table-column>
            <el-table-column label="非主营" align="center">
              <el-table-column
                prop="nonPaid"
                label="已收款"
                min-width="130"
                :formatter="cellFormatter"
              />
              <el-table-column
                prop="nonUnpaid"
                label="未收款"
                min-width="130"
                :formatter="cellFormatter"
              />
              <el-table-column
                prop="nonTotal"
                label="总额"
                min-width="130"
                :formatter="cellFormatter"
              />
            </el-table-column>
          </el-table>
        </div>
      </div>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="handleClose">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_money from "@/api/money";

export default {
  name: "DrawerRegionRealtimeIncome",
  props: {
    showDrawer: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      show: false,
      loading: false,
      exportLoading: false,
      tableData: [],
      form: {
        regionId: 0,
      },
    };
  },
  computed: {
    areaInfo() {
      const list =
        this.$store.state.cardPageInfo.resResultDataObj.areaInfo || [];
      return list
        .filter((item) => item.status === 1 || item.status === "1")
        .map((item) => ({
          ...item,
          dsp: Number(item.dsp || 0),
        }))
        .sort((a, b) => a.dsp - b.dsp);
    },
    regionOptions() {
      const options = this.areaInfo.map((item) => ({
        label: item.name,
        value: item.id,
      }));
      return [{ label: "全部", value: 0 }, ...options];
    },
    summaryRow() {
      if (!this.tableData.length) return null;
      const stats = this.tableData.reduce(
        (acc, row) => {
          acc.tableCount += row.tableCount || 0;
          acc.mainPaid += row.mainPaid;
          acc.mainUnpaid += row.mainUnpaid;
          acc.mainTotal += row.mainTotal;
          acc.nonPaid += row.nonPaid;
          acc.nonUnpaid += row.nonUnpaid;
          acc.nonTotal += row.nonTotal;
          return acc;
        },
        {
          tableCount: 0,
          mainPaid: 0,
          mainUnpaid: 0,
          mainTotal: 0,
          nonPaid: 0,
          nonUnpaid: 0,
          nonTotal: 0,
        }
      );
      return {
        regionName: "合计",
        tableCount: stats.tableCount,
        mainPaid: this.toFixed(stats.mainPaid),
        mainUnpaid: this.toFixed(stats.mainUnpaid),
        mainTotal: this.toFixed(stats.mainTotal),
        nonPaid: this.toFixed(stats.nonPaid),
        nonUnpaid: this.toFixed(stats.nonUnpaid),
        nonTotal: this.toFixed(stats.nonTotal),
        isSummary: true,
      };
    },
    tableRenderData() {
      if (!this.tableData.length) return [];
      const rows = [...this.tableData];
      return rows;
    },
  },
  watch: {
    showDrawer: {
      immediate: true,
      handler(val) {
        this.show = val;
        if (val) this.handleReset();
      },
    },
    show(val) {
      if (!val) {
        this.$emit("showOrHideRegionIncomeDrawer");
      }
    },
  },
  methods: {
    handleQuery() {
      this.fetchTableData();
    },
    handleReset() {
      this.form.regionId = 0;
      this.fetchTableData();
    },
    handleClose(payload) {
      this.show = false;
      if (typeof payload === "function") {
        payload();
      }
    },
    async fetchTableData() {
      this.loading = true;
      try {
        const params = {
          id: Number(this.form.regionId) || 0,
        };
        const res = await api_money.reqGetRegionRealAmts(params);
        if (res.code === 1) {
          const records = (res.data && res.data.records) || [];
          this.tableData = records.map((item, index) =>
            this.transformRecord(item, index)
          );
        } else {
          this.tableData = [];
          this.$message.warning(res.msg || "获取区域实时营收失败");
        }
      } catch (error) {
        this.tableData = [];
        console.error("获取区域实时营收失败", error);
        this.$message.error("获取区域实时营收失败，请稍后重试");
      } finally {
        this.loading = false;
      }
    },
    transformRecord(record, index) {
      const mainPaid = this.centToAmount(record.zp);
      const mainUnpaid = this.centToAmount(record.zup);
      const mainTotal = this.centToAmount(record.t);
      const nonPaid = this.centToAmount(record.fzp);
      const nonUnpaid = this.centToAmount(record.fzup);
      const nonTotal = this.centToAmount(record.ft);
      return {
        regionId:
          record.id ||
          record.regionId ||
          record.region_id ||
          record.regionID ||
          index + 1,
        regionName: record.r || "未知区域",
        tableCount: Number(record.c || 0), // 开台数量，翻台也累计
        mainPaid: this.toFixed(mainPaid),
        mainUnpaid: this.toFixed(mainUnpaid),
        mainTotal: this.toFixed(mainTotal),
        nonPaid: this.toFixed(nonPaid),
        nonUnpaid: this.toFixed(nonUnpaid),
        nonTotal: this.toFixed(nonTotal),
      };
    },
    centToAmount(val) {
      const num = Number(val);
      if (!Number.isFinite(num)) return 0;
      return num / 100;
    },
    toFixed(value) {
      const num = Number(value);
      const valid = Number.isFinite(num) ? num : 0;
      return Number(valid.toFixed(2));
    },
    cellFormatter(row, column, value) {
      return this.formatAmount(value);
    },
    formatAmount(value) {
      return Number(value || 0).toFixed(2);
    },
    rowClassName({ row }) {
      return row.isSummary ? "summary-row" : "";
    },
    async handleExport() {
      this.exportLoading = true;
      try {
        const params = {
          id: Number(this.form.regionId) || 0,
        };
        const res = await api_money.reqExportRegionRealAmts(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type:
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            })
          );
          const link = document.createElement("a");
          document.body.appendChild(link);
          link.href = url;
          link.setAttribute(
            "download",
            decodeURIComponent(res.fileName || "区域实时营收.xlsx")
          );
          link.click();
          document.body.removeChild(link);
          window.URL.revokeObjectURL(url);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.error("导出区域实时营收失败", error);
        this.$message.error("导出失败，请稍后重试");
      } finally {
        this.exportLoading = false;
      }
    },
  },
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";

.region-income-drawer {
  color: rgba(255, 255, 255, 0.85);
  font-size: 14px;

  ::-webkit-scrollbar {
    width: 8px;
    height: 8px;
  }

  ::-webkit-scrollbar-corner {
    background-color: transparent;
  }

}

::v-deep .region-income-drawer-panel {
  background-color: #0b1224;

  .el-drawer__header {
    margin-bottom: 0;
    padding: 18px 24px 0;
    color: rgba(255, 255, 255, 0.85);
  }

  .el-drawer__body {
    padding: 0 24px 24px;
    background: #0e1425;
  }

  .drawer-content {
    padding: 16px 0 0;
    background: transparent;
    min-height: calc(100vh - 120px);
  }

  .top {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 10px 16px;
    border-radius: 10px;
    background: #23283a;
    box-shadow: inset 0 0 0 1px rgba(255, 255, 255, 0.06);
    margin-bottom: 12px;
  }

  .top-left {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;

    .label {
      color: rgba(255, 255, 255, 0.85);
    }

    .filter-select {
      width: 200px;
    }
  }

  .table-wrapper {
    margin-top: 0;
    border: 1px solid rgba(255, 255, 255, 0.12);
    border-radius: 12px;
    background: #151b2d;
    height: calc(100vh - 260px);
    overflow: hidden;
    box-shadow: 0 10px 30px rgba(5, 7, 16, 0.55);
  }

  .summary-row {
    background-color: rgba(64, 158, 255, 0.12) !important;
    color: #a4d6ff !important;
    font-weight: 600;
  }

  .table-count-text {
    color: rgba(255, 255, 255, 0.85);
    font-weight: 500;
  }

  .summary-row .table-count-text {
    color: rgba(255, 255, 255, 0.85) !important;
  }
}

::v-deep
  .region-income-drawer-panel
  .el-table__body
  .summary-row
  > td,
::v-deep
  .region-income-drawer-panel
  .el-table__fixed-body-wrapper
  .summary-row
  > td {
  background: rgba(64, 158, 255, 0.12) !important;
  color: #a4d6ff !important;
  font-weight: 600;
}

::v-deep
  .region-income-drawer-panel
  .el-table__body
  .summary-row
  .table-count-text,
::v-deep
  .region-income-drawer-panel
  .el-table__fixed-body-wrapper
  .summary-row
  .table-count-text {
  color: rgba(255, 255, 255, 0.85) !important;
}

::v-deep .region-income-drawer-panel .el-select .el-input__inner {
  height: 40px;
  line-height: 40px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.18);
  background: rgba(8, 12, 24, 0.7);
  color: rgba(255, 255, 255, 0.9);
}

::v-deep .region-income-drawer-panel .el-input__inner::placeholder {
  color: rgba(255, 255, 255, 0.35);
}

::v-deep .region-income-drawer-panel .el-button {
  height: 38px;
  line-height: 38px;
  padding: 0 20px;
  border-radius: 20px;
  font-size: 14px;
  transition: box-shadow 0.2s ease, transform 0.2s ease;

  &:hover {
    transform: translateY(-1px);
  }
}

::v-deep .region-income-drawer-panel .el-button--primary {
  background: linear-gradient(90deg, #3e73ff 0%, #409eff 100%);
  border: none;
  box-shadow: 0 6px 16px rgba(64, 158, 255, 0.35);
}

::v-deep .region-income-drawer-panel .el-button--info {
  color: rgba(255, 255, 255, 0.8);
  background: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(255, 255, 255, 0.18);
}

::v-deep .region-income-drawer-panel .el-table {
  background: transparent;
  color: rgba(255, 255, 255, 0.85);
  border: none;
  border-collapse: collapse;

  &::before {
    background: transparent;
  }
}

::v-deep .region-income-drawer-panel .el-table__body-wrapper table,
::v-deep .region-income-drawer-panel .el-table__fixed-body-wrapper table {
  border-collapse: collapse;
  border-spacing: 0;
}

::v-deep .region-income-drawer-panel .el-table__header-wrapper th,
::v-deep .region-income-drawer-panel
  .el-table__fixed-header-wrapper
  th {
  background: #1f2638 !important;
  color: rgba(255, 255, 255, 0.68);
  font-weight: 500;
  border-bottom: none;
  border-right: none;
  padding: 10px 8px;
}

::v-deep .region-income-drawer-panel .el-table__body-wrapper td,
::v-deep .region-income-drawer-panel
  .el-table__fixed-body-wrapper
  td {
  background: #1a2033;
  border-bottom: none;
  border-top: none;
  border-right: none;
  padding: 10px 8px;
  font-size: 14px;
  transition: background 0.2s ease;
}

::v-deep .region-income-drawer-panel .el-table__body tr > td {
  border-bottom: none !important;
  border-top: none !important;
}

::v-deep
  .region-income-drawer-panel
  .el-table--striped
  .el-table__body
  .el-table__row--striped
  td {
  background: #171d2d;
}

::v-deep .region-income-drawer-panel .el-table__body tr:hover > td,
::v-deep .region-income-drawer-panel .el-table__body tr.hover-row > td,
::v-deep .region-income-drawer-panel
  .el-table__fixed-body-wrapper
  tr:hover
  > td,
::v-deep .region-income-drawer-panel
  .el-table__fixed-body-wrapper
  tr.hover-row
  > td {
  background: #1f263a !important;
  color: rgba(255, 255, 255, 0.95);
  box-shadow: none;
}

::v-deep .region-income-drawer-panel .el-table__fixed,
::v-deep .region-income-drawer-panel .el-table__fixed-right {
  background: #1a2033;
  box-shadow: none;
}

::v-deep .region-income-drawer-panel .el-table__fixed::before,
::v-deep .region-income-drawer-panel .el-table__fixed-right::before,
::v-deep .region-income-drawer-panel .el-table__fixed::after,
::v-deep .region-income-drawer-panel .el-table__fixed-right::after {
  background: transparent;
  border-color: transparent;
}

::v-deep .region-income-drawer-panel .el-table__fixed-right-patch {
  background: transparent;
  border-color: transparent;
}

::v-deep .region-income-drawer-panel
  .el-table__fixed,
::v-deep .region-income-drawer-panel
  .el-table__fixed-right,
::v-deep .region-income-drawer-panel
  .el-table__body-wrapper,
::v-deep .region-income-drawer-panel
  .el-table__header-wrapper {
  border-color: rgba(255, 255, 255, 0.05);
}

::v-deep .region-income-drawer-panel .el-table--border td,
::v-deep .region-income-drawer-panel .el-table--border th,
::v-deep .region-income-drawer-panel .el-table td,
::v-deep .region-income-drawer-panel .el-table th {
  border-right: none;
  border-bottom: none;
}

::v-deep
  .region-income-drawer-panel
  .el-table__body
  td.el-table__cell,
::v-deep
  .region-income-drawer-panel
  .el-table__header
  th.el-table__cell {
  border-bottom: none !important;
}

::v-deep .region-income-drawer-panel .el-table--border::after,
::v-deep .region-income-drawer-panel .el-table--border::before,
::v-deep .region-income-drawer-panel .el-table--group::after,
::v-deep .region-income-drawer-panel .el-table--group::before,
::v-deep .region-income-drawer-panel .el-table::before,
::v-deep .region-income-drawer-panel .el-table::after {
  display: none;
}

::v-deep .region-income-drawer-panel .el-table__footer-wrapper,
::v-deep .region-income-drawer-panel .el-table__footer-wrapper::before {
  border-top: none;
  display: none;
}

::v-deep .region-income-drawer-panel .el-table__footer-wrapper td,
::v-deep .region-income-drawer-panel .el-table__footer-wrapper th {
  border-top: none;
}

// Loading 深色调样式
::v-deep .region-income-drawer-panel .table-wrapper .el-loading-mask {
  background-color: rgba(10, 14, 25, 0.9) !important;
}

::v-deep .region-income-drawer-panel .table-wrapper .el-loading-spinner {
  .el-loading-text {
    color: rgba(255, 255, 255, 0.5) !important;
    font-size: 14px;
  }

  .circular {
    width: 42px;
    height: 42px;
  }

  .path {
    stroke: #409eff !important;
  }
}

::v-deep .region-income-drawer-panel .table-wrapper .el-loading-spinner .el-loading-circular {
  .path {
    stroke: #409eff !important;
  }
}

@media (orientation: portrait) {
  ::v-deep .region-income-drawer-panel {
    .el-drawer__body {
      padding: 0 12px 16px;
    }

    .drawer-content {
      padding: 12px 0 0;
    }

    .top {
      flex-direction: column;
      align-items: flex-start;
      gap: 10px;
    }

    .top-left {
      width: 100%;
    }
  }
}
</style>

