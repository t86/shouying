<template>
  <!-- 出库明细统计 -->
  <div class="get-all-data-report">
    <div class="top" layout="row" layout-align="start center">
      <div class="label fs14">出库日期：</div>
      <div class="value m-r-2">
        <el-date-picker
          style="width:260px"
          v-model="dateVal"
          type="daterange"
          :clearable="false"
          size="small"
          value-format="yyyy-MM-dd"
          range-separator="至"
          start-placeholder="开始日期"
          end-placeholder="结束日期"
        ></el-date-picker>
      </div>
      <el-input
        v-model="keyword"
        style="width:200px"
        class="m-r-2 m-l-2"
        size="small"
        placeholder="商品名称/存酒流水号"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出</el-button>
    </div>

    <div class="tab m-t-4" layout="row" layout-align="start center">
      <div class="tab-item" :class="{active: tabIndex == 1}" @click="tabIndex = 1">出库明细统计</div>
      <div class="tab-item" :class="{active: tabIndex == 2}" @click="tabIndex = 2">出库网格统计</div>
    </div>

    <!-- 出库明细统计 -->
    <getDetail v-if="tabIndex == 1" :tableData="tableData" />
    <!-- 出库网格统计 -->
    <getGrid v-if="tabIndex == 2" :tableData="tableData" />

  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
import getDetail from './getAllDataReportCom/getDetail.vue'
import getGrid from './getAllDataReportCom/getGrid.vue'
export default {
  data() {
    return {
      tabIndex: 1,
      keyword: "",
      dateVal: [],
      tableData: []
    };
  },
  methods: {
    async getTableData() {
      const params = {
        start_day: this.dateVal[0], //  string 出库开始日期
        end_day: this.dateVal[1], // string  出库结束日期
        key: this.keyword || "" //  string   模糊查询关键字
      };

      try {
        const res = this.tabIndex == 1 ? await api_wine.reqGetDetailReportList(params) : await api_wine.reqGridDetailOfGetReportList(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log( this.tabIndex == 1 ? '出库明细统计' : '出库网格统计' + "数据获取失败", error);
      }
    },

    async exportExcelHandle(){
      const params = {
        start_day: this.dateVal[0], //  string  出库开始日期
        end_day: this.dateVal[1], // string  出库结束日期
        key: this.keyword || "" //  string   模糊查询关键字
      };
      try {
        const res = this.tabIndex == 1 ? await api_wine.reqExportExcelOfGetDetailReport(params) : await api_wine.reqExportExcelOfGetGridDetailReport(params);
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type:
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            })
          );
          const a = document.createElement("a"); //添加a标签
          document.body.appendChild(a);
          a.href = url;
          a.setAttribute("download", res.fileName); // 下载文件的名称及文件类型后缀
          a.click(); //点击标签
          document.body.removeChild(a); // 下载完成移除元素
          window.URL.revokeObjectURL(url); // 释放掉blob对象
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("导出excel失败", error);
      }
    },

    resetHandle() {
      const oneHour = +new Date('2023/07/22 12:00:00') - +new Date('2023/07/22 11:00:00')
      const date = new Date(+new Date() - 8 * oneHour)
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date
        .getDate()
        .toString()
        .padStart(2, 0);
      const now = year + "-" + month + "-" + day;
      this.dateVal = [now, now];
      this.keyword = "";
      this.getTableData();
    }
  },
  created() {
    this.resetHandle();
  },
  components: {
    getDetail,
    getGrid
  },

  watch: {
    tabIndex(){
      this.getTableData()
    }
  }
};
</script>

<style scoped lang="less">
.get-all-data-report {
  padding: 20px;

  .tab {
    .tab-item {
      padding: 10px;
      border-bottom: 2px solid transparent;
      margin-right: 10px;
      cursor: pointer;
      &.active {
        color: #2170ff;
        border-bottom: 2px solid #2170ff;
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