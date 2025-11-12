<template>
  <!-- 借酒出库 -->
  <div class="borrow-wine">
    <div class="top" layout="row" layout-align="start center">
      <span class="label fs14">出库日期：</span>
      <ul class="time-select fs14 m-r-1" layout="row" layout-align="start center">
        <li layout="row" layout-align="start center" @click="setDateVal(1)">
          <img
            :src="
              activeTime == 1
                ? require('@/assets/img/date_label_selete.png')
                : require('@/assets/img/date_label_grey.png')
            "
            alt
          />
          <span :class="{ active: activeTime == 1 }">近7天</span>
        </li>
        <li layout="row" layout-align="start center" @click="setDateVal(2)">
          <img
            :src="
              activeTime == 2
                ? require('@/assets/img/date_label_selete.png')
                : require('@/assets/img/date_label_grey.png')
            "
            alt
          />
          <span :class="{ active: activeTime == 2 }">近30天</span>
        </li>
        <li layout="row" layout-align="start center" @click="setDateVal(3)">
          <img
            :src="
              activeTime == 3
                ? require('@/assets/img/date_label_selete.png')
                : require('@/assets/img/date_label_grey.png')
            "
            alt
          />
          <span :class="{ active: activeTime == 3 }">近3个月</span>
        </li>
      </ul>
      <div class="value m-r-2">
        <el-date-picker
          style="width:140px"
          v-model="start_day"
          type="date"
          :clearable="false"
          size="small"
          value-format="yyyy-MM-dd"
          placeholder="开始日期"
        ></el-date-picker>
        <span>至</span>
        <el-date-picker
          style="width:140px"
          v-model="end_day"
          type="date"
          :clearable="false"
          size="small"
          value-format="yyyy-MM-dd"
          placeholder="结束日期"
        ></el-date-picker>
      </div>
      <el-input
        v-model="keyword"
        style="width:300px"
        class="m-r-2"
        size="small"
        placeholder="酒水名称或备注信息"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
    </div>

    <div class="btn-area m-t-4">
      <el-button type="primary" size="small" @click="showBorrowDialog">借酒</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">序号</div>
            <div class="th">酒水名称</div>
            <div class="th">借酒数量</div>
            <div class="th">借酒人</div>
            <div class="th">出库时间</div>
            <div class="th">操作人</div>
            <div class="th">备注</div>
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
            <div class="td">{{ item.borrow_count || 0 }}</div>
            <div class="td">{{ item.borrower || '—' }}</div>
            <div class="td">{{ item.out_time || '—' }}</div>
            <div class="td">{{ item.operator || '—' }}</div>
            <div class="td" :title="item.remark">
              <el-tooltip v-if="item.remark && item.remark.length > 20" :content="item.remark" placement="top">
                <span>{{ item.remark ? (item.remark.length > 20 ? item.remark.substring(0, 20) + '...' : item.remark) : '—' }}</span>
              </el-tooltip>
              <span v-else>{{ item.remark || '—' }}</span>
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

    <!-- 借酒对话框 -->
    <el-dialog
      title="借酒"
      :visible.sync="showBorrowDialogVisible"
      :close-on-click-modal="false"
      width="80%"
      :before-close="handleCloseBorrowDialog"
      class="borrow-wine-dialog"
    >
      <div style="padding: 15px;">
        <!-- 借酒人选择 -->
        <div style="margin-bottom: 20px; display: flex; align-items: center; gap: 10px; flex-wrap: wrap;">
          <div style="font-size: 14px; color: #333; white-space: nowrap;">
            <span style="color: #f56c6c;">*</span> 借酒人：
          </div>
          <el-select
            v-model="borrowForm.br_emp_id"
            filterable
            remote
            reserve-keyword
            placeholder="请选择借酒人"
            :remote-method="remoteEmpHandle"
            :loading="empLoading"
            style="flex: 1; min-width: 200px;"
            size="small"
          >
            <el-option
              v-for="item in empOptions"
              :key="item.id"
              :label="item.n"
              :value="item.id"
            ></el-option>
          </el-select>
        </div>

        <!-- 商品表格 -->
        <div style="margin-bottom: 20px;">
          <div style="margin-bottom: 8px; font-size: 14px; color: #333;">
            <span style="color: #f56c6c;">*</span> 借酒商品：
          </div>
          <div class="wine-table">
            <div class="table-header">
              <div class="th" style="width: 50px;">序号</div>
              <div class="th" style="width: 60px;">操作</div>
              <div class="th" style="flex: 1;">酒水名称</div>
              <div class="th" style="width: 120px;">可借数量</div>
              <div class="th" style="width: 120px;">借酒数量</div>
              <div class="th" style="flex: 1;">备注</div>
            </div>
            <div class="table-body">
              <div
                v-for="(item, index) in borrowForm.productList"
                :key="index"
                class="table-row"
              >
                <div class="td" style="width: 50px; text-align: center;">{{ index + 1 }}</div>
                <div class="td" style="width: 60px; text-align: center;">
                  <el-button
                    type="text"
                    icon="el-icon-plus"
                    size="mini"
                    @click="addProduct"
                    style="padding: 0 5px;"
                  ></el-button>
                  <el-button
                    type="text"
                    icon="el-icon-minus"
                    size="mini"
                    @click="removeProduct(index)"
                    :disabled="borrowForm.productList.length <= 1"
                    style="padding: 0 5px;"
                  ></el-button>
                </div>
                <div class="td" style="flex: 1;">
                  <el-select
                    v-model="item.prd_id"
                    filterable
                    remote
                    reserve-keyword
                    placeholder="输入酒水名称或拼音简写"
                    :remote-method="(query) => remoteWineHandle(query, index)"
                    :loading="wineLoading[index]"
                    @change="handleWineChange(index)"
                    style="width: 100%;"
                    size="small"
                  >
                    <el-option
                      v-for="wine in wineOptions[index]"
                      :key="wine.id"
                      :label="wine.n"
                      :value="wine.id"
                    ></el-option>
                  </el-select>
                </div>
                <div class="td" style="width: 120px;">
                  <el-input
                    :value="item.borrowable_cnt || 0"
                    readonly
                    style="width: 100%;"
                    size="small"
                  ></el-input>
                </div>
                <div class="td" style="width: 120px;">
                  <el-input-number
                    v-model="item.prd_cnt"
                    :min="0"
                    :max="item.borrowable_cnt || 0"
                    :precision="0"
                    placeholder="0"
                    style="width: 100%;"
                    size="small"
                  ></el-input-number>
                </div>
                <div class="td" style="flex: 1;">
                  <el-input
                    v-model="item.remark"
                    placeholder="输入借酒备注,不超过30字"
                    maxlength="30"
                    show-word-limit
                    style="width: 100%;"
                    size="small"
                  ></el-input>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="handleCloseBorrowDialog">取消</el-button>
        <el-button type="primary" @click="submitBorrow" :loading="submitLoading">确认借酒</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { keyHandle } from "../../../../mixin/keyhandle";
import api_wine from "@/api/wine";
import api_emp from "@/api/BMS/emp";
export default {
  data() {
    return {
      activeTime: 1, // 1：近7天  2：近30天  3：近3个月
      start_day: "",
      end_day: "",
      keyword: "",
      tableData: [],
      pageInfo: {
        page: 1,
        pageSize: 20,
        total: 0,
      },
      showBorrowDialogVisible: false,
      // 借酒表单
      borrowForm: {
        br_emp_id: null,
        productList: [
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0, // 可借数量
          },
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0,
          },
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0,
          },
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0,
          },
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0,
          },
        ],
      },
      // 员工选择
      empOptions: [],
      empLoading: false,
      // 商品选择（每个商品行独立）
      wineOptions: [[], [], [], [], []],
      wineLoading: [false, false, false, false, false],
      submitLoading: false,
    };
  },
  methods: {
    async getTableData() {
      const params = {
        page_num: this.pageInfo.page * 1,
        page_size: this.pageInfo.pageSize,
        begin_day: this.start_day || "",
        end_day: this.end_day || "",
        op_type: 1, // 1 借酒
        prd_id: 0, // 0 代表全部商品
        key: this.keyword || "",
      };

      try {
        const res = await api_wine.reqGetWineBorrowReturnList(params);
        console.log('res', res)
        if (res.code == 1) {
          // 映射返回字段：n->wine_name, c->borrow_count, bre->borrower, u->out_time, oe->operator, r->remark
          // 处理records为null的情况，转换为空数组
          const records = res.data.records || [];
          this.tableData = records.map(item => ({
            id: item.id || Math.random(),
            wine_name: item.n || '—',
            borrow_count: item.c || 0,
            borrower: item.bre || '—',
            out_time: item.u || '—',
            operator: item.oe || '—',
            remark: item.r || '—',
            op_type: item.t || '—',
          }));
          this.pageInfo.total = res.data.row_cnt || 0;
        } else {
          this.$message.warning(res.msg || "获取借酒列表失败");
          this.tableData = [];
          this.pageInfo.total = 0;
        }
      } catch (error) {
        console.log("借酒列表获取失败", error);
        // 如果是请求被频率拦截，不显示错误提示
        if (error.message && error.message === '请求频率过快，已自动拦截') {
          console.log("请求被频率拦截，已忽略");
          return;
        }
        this.$message.error("获取借酒列表失败");
        this.tableData = [];
        this.pageInfo.total = 0;
      }
    },

    showBorrowDialog() {
      // 重置表单，默认5行
      this.borrowForm = {
        br_emp_id: null,
        productList: [
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0,
          },
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0,
          },
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0,
          },
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0,
          },
          {
            prd_id: null,
            prd_cnt: 0,
            remark: "",
            borrowable_cnt: 0,
          },
        ],
      };
      this.empOptions = [];
      this.wineOptions = [[], [], [], [], []];
      this.wineLoading = [false, false, false, false, false];
      this.showBorrowDialogVisible = true;
    },

    handleCloseBorrowDialog() {
      this.showBorrowDialogVisible = false;
    },

    // 员工远程搜索
    async remoteEmpHandle(query) {
      if (query !== "") {
        this.empLoading = true;
        try {
          const params = {
            name: query,
            page_num: 1,
            page_size: 50,
            mod_emp_ids: [],
          };
          const res = await api_emp.requestEmpUpperItems(params);
          if (res.code == 1) {
            this.empOptions = res.data || [];
          } else {
            this.$message.warning(res.msg || "搜索员工失败");
          }
        } catch (error) {
          console.log("搜索员工失败", error);
          this.$message.error("搜索员工失败");
        } finally {
          this.empLoading = false;
        }
      } else {
        this.empOptions = [];
      }
    },

    // 商品远程搜索 - 使用可借酒水列表接口
    async remoteWineHandle(query, index) {
      if (query !== "") {
        this.$set(this.wineLoading, index, true);
        try {
          const params = {
            key: query,
          };
          const res = await api_wine.reqGetWineCanBorrowList(params);
          if (res.code == 1) {
            this.$set(this.wineOptions, index, res.data.records || []);
          } else {
            this.$message.warning(res.msg || "搜索酒水失败");
          }
        } catch (error) {
          console.log("搜索酒水失败", error);
          this.$message.error("搜索酒水失败");
        } finally {
          this.$set(this.wineLoading, index, false);
        }
      } else {
        this.$set(this.wineOptions, index, []);
      }
    },

    // 选择酒水后，获取可借数量
    async handleWineChange(index) {
      const item = this.borrowForm.productList[index];
      if (!item.prd_id) {
        item.borrowable_cnt = 0;
        return;
      }

      // 从搜索结果中找到对应的商品，获取可借数量
      const wineOption = this.wineOptions[index].find(w => w.id === item.prd_id);
      if (wineOption) {
        item.borrowable_cnt = wineOption.c || 0;
        // 如果借酒数量超过可借数量，自动调整
        if (item.prd_cnt > item.borrowable_cnt) {
          item.prd_cnt = item.borrowable_cnt;
        }
      } else {
        // 如果不在搜索结果中，重新搜索获取
        try {
          const params = {
            key: "",
          };
          const res = await api_wine.reqGetWineCanBorrowList(params);
          if (res.code == 1) {
            const wine = (res.data.records || []).find(w => w.id === item.prd_id);
            if (wine) {
              item.borrowable_cnt = wine.c || 0;
              if (item.prd_cnt > item.borrowable_cnt) {
                item.prd_cnt = item.borrowable_cnt;
              }
            } else {
              item.borrowable_cnt = 0;
            }
          }
        } catch (error) {
          console.log("获取可借数量失败", error);
          item.borrowable_cnt = 0;
        }
      }
    },

    // 添加商品
    addProduct() {
      this.borrowForm.productList.push({
        prd_id: null,
        prd_cnt: 0,
        remark: "",
        borrowable_cnt: 0,
      });
      this.wineOptions.push([]);
      this.wineLoading.push(false);
    },

    // 删除商品
    removeProduct(index) {
      if (this.borrowForm.productList.length > 1) {
        this.borrowForm.productList.splice(index, 1);
        this.wineOptions.splice(index, 1);
        this.wineLoading.splice(index, 1);
      }
    },

    // 提交借酒
    async submitBorrow() {
      // 验证借酒人
      if (!this.borrowForm.br_emp_id) {
        this.$message.warning("请选择借酒人");
        return;
      }

      // 验证商品列表
      const validProducts = this.borrowForm.productList.filter(
        (item) => item.prd_id && item.prd_cnt > 0
      );
      if (validProducts.length === 0) {
        this.$message.warning("请至少添加一个有效的借酒商品");
        return;
      }

      // 检查借酒数量是否超过可借数量
      const invalidProducts = validProducts.filter(
        (item) => item.prd_cnt > item.borrowable_cnt
      );
      if (invalidProducts.length > 0) {
        this.$message.warning("借酒数量不能超过可借数量");
        return;
      }

      this.submitLoading = true;
      try {
        const params = {
          br_emp_id: this.borrowForm.br_emp_id,
          prd_ids: validProducts.map((item) => item.prd_id),
          prd_cnts: validProducts.map((item) => item.prd_cnt),
          remarks: validProducts.map((item) => item.remark || ""),
        };

        const res = await api_wine.reqNewWineBorrow(params);
        if (res.code == 1) {
          this.$message.success("借酒成功");
          this.handleCloseBorrowDialog();
          this.getTableData(); // 刷新列表
        } else {
          this.$message.warning(res.msg || "借酒失败");
        }
      } catch (error) {
        console.log("借酒失败", error);
        this.$message.error("借酒失败");
      } finally {
        this.submitLoading = false;
      }
    },

    changePageHandle(page = 1) {
      this.pageInfo.page = page;
      this.getTableData();
    },

    getDate(dateNum = +new Date()) {
      const date = new Date(dateNum);
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date.getDate().toString().padStart(2, 0);
      return year + "-" + month + "-" + day;
    },

    setDateVal(activeTime) {
      this.activeTime = activeTime;
      const dayInfo = {
        1: 7,
        2: 30,
        3: 90,
      };
      const oneDay = +new Date("2023/05/24") - +new Date("2023/05/23");
      const begin = this.getDate(+new Date() - oneDay * dayInfo[activeTime]);
      const end = this.getDate();
      this.start_day = begin;
      this.end_day = end;
      this.getTableData();
    },

    resetHandle() {
      this.setDateVal(1);
      this.keyword = "";
      this.getTableData();
    },
  },
  created() {
    this.resetHandle();
  },
  mixins: [keyHandle],
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.borrow-wine {
  padding: 20px;

  .top {
    flex-wrap: wrap;

    .time-select {
      li {
        cursor: pointer;
        margin-right: 16px;

        img {
          width: 12px;
          margin-right: 6px;
        }

        span {
          &.active {
            color: #2170ff;
          }
        }
      }
    }
  }

  .table {
    .tbody {
      height: calc(100vh - 280px);
      overflow: auto;
    }
  }
}

@media (orientation: portrait) {
  .borrow-wine {
    .top {
      flex-direction: column;
      align-items: flex-start;

      .time-select {
        margin-bottom: 15px;
      }
    }
  }
}

// 借酒对话框样式
.borrow-wine-dialog {
  .el-dialog {
    height: 80vh;
    margin-top: 10vh !important;
    overflow-y: auto;
  }

  .el-dialog__body {
    max-height: calc(80vh - 120px);
    overflow-y: auto;
    padding: 15px;
  }

  @media (orientation: portrait) {
    .el-dialog {
      width: 95% !important;
      height: 95vh !important;
      max-height: 95vh !important;
      margin-top: 2.5vh !important;
    }
  }

  @media (max-width: 900px) {
    .el-dialog {
      width: 95% !important;
      height: 95vh !important;
      max-height: 95vh !important;
      margin-top: 2.5vh !important;
    }
  }

  .wine-table {
    border: 1px solid #e4e7ed;
    border-radius: 6px;
    overflow: hidden;

    .table-header {
      display: flex;
      background-color: #f5f7fa;
      border-bottom: 1px solid #e4e7ed;

      .th {
        padding: 12px 8px;
        font-size: 14px;
        font-weight: 600;
        color: #333;
        text-align: center;
        border-right: 1px solid #e4e7ed;

        &:last-child {
          border-right: none;
        }
      }
    }

    .table-body {
      .table-row {
        display: flex;
        border-bottom: 1px solid #e4e7ed;
        align-items: center;

        &:last-child {
          border-bottom: none;
        }

        .td {
          padding: 8px;
          border-right: 1px solid #e4e7ed;
          display: flex;
          align-items: center;

          &:last-child {
            border-right: none;
          }
        }
      }
    }
  }

  @media (orientation: portrait) {
    .wine-table {
      .table-header,
      .table-body .table-row {
        flex-wrap: wrap;

        .th,
        .td {
          min-width: 100px;
        }
      }
    }
  }
}
</style>

<style>
/* 日期选择器 */
.el-date-picker__header-label {
  color: #1a1a21;
}

.el-date-table th,
.el-picker-panel__content {
  color: #1a1a21;
}

.el-range-editor--small .el-range-input {
  background-color: transparent;
}
</style>

