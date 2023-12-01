<template>
  <!-- 充公明细统计 -->
  <div class="to-store-all-data-report">
    <div class="top" layout="row" layout-align="start center">
      <div class="label fs14">充公日期：</div>
      <div class="value m-r-2">
        <el-date-picker style="width:140px" v-model="start_day" type="date" :clearable="false" size="small"
          value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
        <span>至</span>
        <el-date-picker style="width:140px" v-model="end_day" type="date" :clearable="false" size="small"
          value-format="yyyy-MM-dd" placeholder="结束日期"></el-date-picker>
      </div>
      <div class="label fs14">类型：</div>
      <div class="value m-r-2">
        <el-select style="width:100px" size="small" v-model="selectVal" placeholder="请选择">
          <el-option
            v-for="item in options"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          ></el-option>
        </el-select>
      </div>
      <el-input
        v-model="keyword"
        style="width:200px"
        class="m-r-2 m-l-2"
        size="small"
        placeholder="商品名称/存酒流水号/手机号"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出</el-button>
    </div>

    <div class="tab m-t-4" layout="row" layout-align="start center">
      <div class="tab-item" :class="{active: tabIndex == 1}" @click="tabIndex = 1">充公明细统计</div>
      <div class="tab-item" :class="{active: tabIndex == 2}" @click="tabIndex = 2">充公网格统计</div>
    </div>

    <!-- 充公明细统计 -->
    <toStoreDetail v-if="tabIndex == 1" :tableData="tableData" />
    <!-- 充公网格统计 -->
    <toStoreGrid v-if="tabIndex == 2" :tableData="tableData" />

  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
import toStoreDetail from './toStoreAllDataReportCom/toStoreDetail.vue'
import toStoreGrid from './toStoreAllDataReportCom/toStoreGrid.vue'
export default {
  data() {
    return {
      tabIndex: 1,      
      selectVal: 0,
      options: [
        {
          value: 0,
          label: "全部"
        },
        {
          value: 1,
          label: "消费充公"
        },
        {
          value: 2,
          label: "过期充公"
        },
        {
          value: 5,
          label: "库存充公"
        }
      ],
      keyword: "",
      start_day: "",
      end_day: "",
      tableData: []
    };
  },
  methods: {
    async getTableData() {
      const params = {
        start_day: this.start_day, //  string 充公开始日期
        end_day: this.end_day, // string  充公结束日期
        key: this.keyword || "", //  string   模糊查询关键字
        type_id: this.selectVal * 1  //  int   类型 1 消费充公 2 过期充公 0 全部
      };

      try {
        const res = this.tabIndex == 1 ? await api_wine.reqToStoreDetailReportList(params) : await api_wine.reqGridDetailOfToStoreReportList(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log( this.tabIndex == 1 ? '充公明细统计' : '充公网格统计' + "数据获取失败", error);
      }
    },

    async exportExcelHandle(){
      const params = {
        start_day: this.start_day, //  string  充公开始日期
        end_day: this.end_day, // string  充公结束日期
        key: this.keyword || "", //  string   模糊查询关键字
        type_id: this.selectVal * 1  //  int   类型 1 消费充公 2 过期充公 0 全部
      };
      try {
        const res = this.tabIndex == 1 ? await api_wine.reqExportExcelOfToStoreDetailReport(params) : await api_wine.reqExportExcelOfToStoreGridDetailReport(params);
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
          a.setAttribute("download", decodeURIComponent(res.fileName)); // 下载文件的名称及文件类型后缀
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
      this.start_day = now;
      this.end_day = now;
      this.keyword = "";
      this.getTableData();
    }
  },
  created() {
    this.resetHandle();
  },
  components: {
    toStoreDetail,
    toStoreGrid
  },

  watch: {
    tabIndex(){
      this.getTableData()
    }
  }
};
</script>

<style scoped lang="less">
.to-store-all-data-report {
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