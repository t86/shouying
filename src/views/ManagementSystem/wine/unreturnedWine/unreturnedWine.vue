<template>
  <!-- 未还酒水 -->
  <div class="unreturned-wine">
    <div class="top" layout="row" layout-align="start center">
      <el-input
        v-model="keyword"
        style="width:300px"
        class="m-r-2"
        size="small"
        placeholder="输入酒水名称"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
      <el-button type="primary" size="small" @click="exportHandle">导出</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">酒水名称</div>
            <div class="th">剩余未还数量</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="tr"
            layout="row"
            layout-align="space-between center"
            v-for="(item, index) in tableData"
            :key="item.id"
          >
            <div class="td">{{ index + 1 + (pageInfo.page - 1) * pageInfo.pageSize }}</div>
            <div class="td">{{ item.wine_name || '—' }}</div>
            <div class="td">
              <span class="link-text" @click="showDetailDialog(item)">{{ item.unreturned_count || 0 }}</span>
            </div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
      <div class="pagination">
        <el-pagination
          background
          layout="prev, pager, next"
          :total="pageInfo.total"
          :page-size="pageInfo.pageSize"
          :current-page="pageInfo.page"
          @current-change="changePageHandle"
        ></el-pagination>
      </div>
    </div>

    <!-- 借还明细对话框 -->
    <el-dialog
      title="存酒借还明细"
      :visible.sync="showDetailDialogVisible"
      :close-on-click-modal="false"
      width="80%"
      :before-close="handleCloseDetailDialog"
      class="borrow-return-detail-dialog"
    >
      <div style="padding: 15px;">
        <!-- 当前酒水信息 -->
        <div v-if="currentWineInfo.wine_name" style="margin-bottom: 15px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 10px;">
          <div style="font-size: 14px; color: #333;">
            <strong>当前酒水：</strong>{{ currentWineInfo.wine_name }}
          </div>
        </div>

        <!-- 筛选条件 -->
        <div style="margin-bottom: 15px; display: flex; align-items: center; gap: 15px; flex-wrap: wrap;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <span style="font-size: 14px; color: #333; white-space: nowrap;">日期：</span>
            <el-date-picker
              v-model="detailStartDate"
              type="date"
              placeholder="开始日期"
              format="yyyy-MM-dd"
              value-format="yyyy-MM-dd"
              size="small"
              style="width: 150px;"
            ></el-date-picker>
            <span style="margin: 0 5px;">-</span>
            <el-date-picker
              v-model="detailEndDate"
              type="date"
              placeholder="结束日期"
              format="yyyy-MM-dd"
              value-format="yyyy-MM-dd"
              size="small"
              style="width: 150px;"
            ></el-date-picker>
          </div>
          <div style="display: flex; align-items: center; gap: 8px;">
            <span style="font-size: 14px; color: #333; white-space: nowrap;">类型：</span>
            <el-select
              v-model="detailOpType"
              placeholder="全部"
              size="small"
              style="width: 120px;"
            >
              <el-option label="全部" :value="0"></el-option>
              <el-option label="借酒" :value="1"></el-option>
              <el-option label="还酒" :value="2"></el-option>
            </el-select>
          </div>
          <el-button type="primary" size="small" @click="queryDetailData">查询</el-button>
          <el-button size="small" @click="resetDetailData">重置</el-button>
        </div>

        <!-- 明细表格 -->
        <div class="detail-table">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="space-between center">
                <div class="th">日期</div>
                <div class="th">类型</div>
                <div class="th">操作数量</div>
                <div class="th">借酒人/还酒人</div>
                <div class="th">操作人</div>
                <div class="th">备注</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                layout="row"
                layout-align="space-between center"
                v-for="(item, index) in detailTableData"
                :key="item.id"
              >
                <div class="td">{{ item.date || '—' }}</div>
                <div class="td">
                  <span :style="{ color: item.op_type === 1 ? '#409eff' : '#67c23a' }">
                    {{ item.op_type === 1 ? '借酒' : '还酒' }}
                  </span>
                </div>
                <div class="td">{{ item.count || 0 }}</div>
                <div class="td">{{ item.person || '—' }}</div>
                <div class="td">{{ item.operator || '—' }}</div>
                <div class="td" style="max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;" :title="item.remark">
                  {{ item.remark || '—' }}
                </div>
              </div>
              <div class="no-data" v-if="detailTableData.length == 0">
                <img src="@/assets/img/wu.png" alt />
                <p>暂无数据</p>
              </div>
            </div>
          </div>
        </div>

        <!-- 分页 -->
        <div class="pagination" style="margin-top: 15px; display: flex; justify-content: center;">
          <el-pagination
            background
            layout="prev, pager, next"
            :total="detailPageInfo.total"
            :page-size="detailPageInfo.pageSize"
            :current-page="detailPageInfo.page"
            @current-change="changeDetailPageHandle"
          ></el-pagination>
        </div>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="handleCloseDetailDialog">关闭</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { keyHandle } from "../../../../mixin/keyhandle";
import api_wine from "@/api/wine";
export default {
  data() {
    // 获取当月第一天和最后一天
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
    const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
    const formatDate = (date) => {
      const year = date.getFullYear();
      const month = String(date.getMonth() + 1).padStart(2, '0');
      const day = String(date.getDate()).padStart(2, '0');
      return `${year}-${month}-${day}`;
    };

    return {
      keyword: "",
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0,
      },
      showDetailDialogVisible: false,
      currentWineInfo: {},
      detailTableData: [],
      detailStartDate: formatDate(firstDay),
      detailEndDate: formatDate(lastDay),
      detailOpType: 0, // 0=全部, 1=借酒, 2=还酒
      detailPageInfo: {
        page: 1,
        pageSize: 20,
        total: 0,
      },
    };
  },
  methods: {
    async getTableData() {
      const params = {
        key: this.keyword || "",
      };

      try {
        const res = await api_wine.reqGetWineBorrowInvtList(params);
        if (res.code == 1) {
          // 映射返回字段：id->id, n->wine_name, c->unreturned_count
          // 注意：该接口不支持分页，返回所有数据，需要前端分页
          const allData = (res.data.records || []).map(item => ({
            id: item.id || 0,
            wine_name: item.n || '—',
            unreturned_count: item.c || 0,
          })).filter(item => item.unreturned_count > 0); // 只显示未还数量大于0的

          // 前端分页处理
          this.pageInfo.total = allData.length;
          const start = (this.pageInfo.page - 1) * this.pageInfo.pageSize;
          const end = start + this.pageInfo.pageSize;
          this.tableData = allData.slice(start, end);
        } else {
          this.$message.warning(res.msg || "获取未还酒水列表失败");
          this.tableData = [];
          this.pageInfo.total = 0;
        }
      } catch (error) {
        console.log("未还酒水列表获取失败", error);
        this.$message.error("获取未还酒水列表失败");
        this.tableData = [];
        this.pageInfo.total = 0;
      }
    },

    async showDetailDialog(item) {
      this.currentWineInfo = { ...item };
      this.showDetailDialogVisible = true;
      // 重置分页和筛选条件
      this.detailPageInfo.page = 1;
      // 日期默认为当月
      this.setCurrentMonth();
      this.detailOpType = 0;
      // 加载数据
      await this.queryDetailData();
    },

    // 设置日期为当月
    setCurrentMonth() {
      const now = new Date();
      const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
      const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      const formatDate = (date) => {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
      };
      this.detailStartDate = formatDate(firstDay);
      this.detailEndDate = formatDate(lastDay);
    },

    // 查询明细数据
    async queryDetailData() {
      if (!this.currentWineInfo.id) {
        this.$message.warning("请先选择酒水");
        return;
      }

      try {
        // 根据类型筛选获取借还明细（op_type: 0=全部, 1=借酒, 2=还酒）
        let allRecords = [];
        
        // 统一处理：全部、借酒、还酒都使用同一个接口，通过 op_type 参数区分
        const params = {
          page_num: 1,
          page_size: 10000,
          begin_day: this.detailStartDate || "",
          end_day: this.detailEndDate || "",
          op_type: this.detailOpType, // 0=全部, 1=借酒, 2=还酒
          prd_id: this.currentWineInfo.id || 0,
          key: "",
        };
        
        const res = await api_wine.reqGetWineBorrowReturnList(params);
        // 判断接口是否成功：code == 1 或者没有明确的错误码
        if (res) {
          // 成功条件：code == 1，或者没有code字段（视为成功，尝试解析数据）
          // 只有当code明确不等于1时才认为是错误
          if (res.code == 1 || res.code === undefined) {
            // 尝试解析数据，即使data为空或records为空也算成功（只是没有数据）
            allRecords = ((res.data && res.data.records) || []).map(record => {
              // 从接口返回的 t 字段判断操作类型
              let opType = this.detailOpType; // 默认使用筛选条件
              if (record.t) {
                // 如果 t 字段包含"借"，则为借酒(1)
                if (record.t.includes('借')) {
                  opType = 1;
                } 
                // 如果 t 字段包含"还"，则为还酒(2)
                else if (record.t.includes('还')) {
                  opType = 2;
                }
                // 如果 t 是数字字符串，直接转换
                else if (/^[12]$/.test(String(record.t).trim())) {
                  opType = parseInt(record.t, 10);
                }
              }
              
              return {
                id: record.id || Math.random(),
                date: record.u || '—',
                op_type: opType,
                count: record.c || 0,
                person: record.bre || '—',
                operator: record.oe || '—',
                remark: record.r || '—',
              };
            });
            // 按日期排序（降序）
            allRecords.sort((a, b) => {
              if (a.date === '—' || b.date === '—') return 0;
              return new Date(b.date) - new Date(a.date);
            });
          } else if (res.code !== undefined && res.code != 1) {
            // 明确的错误码
            this.$message.warning(res.msg || "获取借还明细失败");
          }
        }

        // 前端分页处理
        this.detailPageInfo.total = allRecords.length;
        const start = (this.detailPageInfo.page - 1) * this.detailPageInfo.pageSize;
        const end = start + this.detailPageInfo.pageSize;
        this.detailTableData = allRecords.slice(start, end);
      } catch (error) {
        // 只有在真正发生异常时才显示错误（比如网络错误、请求被取消等）
        console.log("借还明细获取失败", error);
        
        // 检查是否是请求被取消（频率限制）
        const isCanceled = error && (
          (error.message && (
            error.message.includes("请求频率过快") || 
            error.message.includes("已自动拦截")
          )) ||
          error.__CANCEL__ === true ||
          error.name === 'Cancel'
        );
        
        // 如果是请求被取消（频率限制），不显示错误提示
        if (isCanceled) {
          console.warn("⚠️ [借还明细] 请求被频率限制拦截，不显示错误提示");
        } else {
          this.$message.error("获取借还明细失败，请重试");
        }
        
        this.detailTableData = [];
        this.detailPageInfo.total = 0;
      }
    },

    // 重置明细筛选条件
    resetDetailData() {
      this.setCurrentMonth();
      this.detailOpType = 0;
      this.detailPageInfo.page = 1;
      this.queryDetailData();
    },

    // 明细分页切换
    changeDetailPageHandle(page = 1) {
      this.detailPageInfo.page = page;
      this.queryDetailData();
    },

    handleCloseDetailDialog() {
      this.showDetailDialogVisible = false;
      this.currentWineInfo = {};
      this.detailTableData = [];
      this.detailPageInfo.page = 1;
      this.detailPageInfo.total = 0;
    },

    async exportHandle() {
      try {
        const res = await api_wine.reqExportWineBorrowInvtList();
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            })
          );
          const a = document.createElement("a");
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", decodeURIComponent(res.fileName || `未还酒水数量列表_${new Date().getTime()}.xlsx`));
          a.click();
          document.body.removeChild(a);
          window.URL.revokeObjectURL(url);
          this.$message.success("导出成功");
        } else {
          this.$message.warning(res.msg || "导出失败");
        }
      } catch (error) {
        console.log("导出excel失败", error);
        this.$message.error("导出失败");
      }
    },

    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },

    resetHandle() {
      this.keyword = "";
      this.pageInfo.page = 1;
      this.getTableData();
    },
  },
  created() {
    this.getTableData();
  },
  mixins: [keyHandle],
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.unreturned-wine {
  padding: 20px;

  .table {
    .tbody {
      height: calc(100vh - 280px);
      overflow: auto;

      .link-text {
        color: #2170ff;
        cursor: pointer;
        text-decoration: underline;

        &:hover {
          color: #409eff;
        }
      }
    }
  }

  .detail-table {
    max-height: 90vh;
    overflow: auto;

    .table {
      .tbody {
        height: auto;
        max-height: 350px;
        overflow: auto;
      }
    }
  }
}

// 借还明细对话框样式
.borrow-return-detail-dialog {
  .el-dialog {
    height: 90vh;
    margin-top: 2vh !important;
    border-radius: 8px;
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }

  .el-dialog__body {
    flex: 1;
    overflow-y: auto;
    padding: 15px;
  }

  .el-dialog__footer {
    padding: 12px 20px;
  }

  .detail-table {
    background: #fff;
    border: 1px solid #ebeef5;
    border-radius: 6px;

    .table {
      .thead .tr,
      .tbody .tr {
        display: grid;
        grid-template-columns: 150px 90px 100px 170px 130px 1fr;
        align-items: center;
        column-gap: 12px;
        padding: 0 12px;
      }

      .thead .tr {
        background: #f5f7fa;
        font-weight: 600;
      }

      .tbody .tr {
        min-height: 44px;
        border-bottom: 1px solid #f0f2f5;

        &:last-child {
          border-bottom: none;
        }
      }

      .th,
      .td {
        width: auto;
        text-align: left;
        padding: 0;
      }

      .td:nth-child(3),
      .td:nth-child(4),
      .td:nth-child(5) {
        white-space: nowrap;
      }

      .td:last-child {
        justify-self: stretch;
      }
    }
  }

  @media (orientation: portrait) {
    .el-dialog {
      width: 95% !important;
      max-width: 95%;
      max-height: 90vh;
      margin-top: 1vh !important;
    }

    .detail-table {
      .table {
        .thead .tr,
        .tbody .tr {
          grid-template-columns: 130px 80px 90px 140px 110px 1fr;
          column-gap: 8px;
        }
      }
    }
  }

  @media (max-width: 900px) {
    .el-dialog {
      width: 95% !important;
      max-width: 95%;
      max-height: 90vh;
      margin-top: 1vh !important;
    }

    .detail-table {
      .table {
        .thead .tr,
        .tbody .tr {
          grid-template-columns: 120px 70px 80px 130px 100px 1fr;
          column-gap: 6px;
        }
      }
    }
  }
}

@media (orientation: portrait) {
  .unreturned-wine {
    .top {
      flex-wrap: wrap;
    }
  }
}
</style>

<style>
/* 对话框样式 */
.el-dialog {
  width: 1200px !important;
}

@media (orientation: portrait) {
  .el-dialog {
    width: 95% !important;
    margin-top: 1vh !important;
  }
}
</style>

