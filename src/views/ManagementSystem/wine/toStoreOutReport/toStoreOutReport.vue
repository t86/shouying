<template>
  <!-- 充公出库记录 -->
  <div class="to-store-out-report">
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
        placeholder="商品名称"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="center center">
            <div class="th">商品名称</div>
            <div class="th">规格</div>
            <div class="th">数量</div>
            <div class="th">入库仓库</div>
            <div class="th">类型</div>
            <div class="th">出库时间</div>
            <div class="th">出库人</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item) in tableData" :key="item.id" layout="row" layout-align="space-between center">
            <div class="td one-txt-cut">{{item.p}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.y}}</div>
            <div class="td">{{item.t}}</div>
            <div class="td">{{item.oe}}</div>
          </div>
          <div class="no-data" v-if="tableData.length==0">
            <img src="@/assets/img/wu.png" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_wine from "@/api/wine";
export default {
  data() {
    return {
      keyword: "",
      dateVal: [],
      tableData: []
    };
  },
  methods: {
    async getTableData() {
      const params = {
        start_day: this.dateVal[0], //  string  充公出库开始日期
        end_day: this.dateVal[1], // string  充公出库结束日期
        key: this.keyword || "" //  string   模糊查询关键字
      };

      try {
        const res = await api_wine.reqGetToStoreOutReportList(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("存酒库列表数据获取失败", error);
      }
    },

    async exportExcelHandle(){
      const params = {
        start_day: this.dateVal[0], //  string  充公出库开始日期
        end_day: this.dateVal[1], // string  充公出库结束日期
        key: this.keyword || "" //  string   模糊查询关键字
      }
      try {
        const res = await api_wine.reqExportExcelOfToStoreOutReport(params);
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
      this.dateVal = [now, now];
      this.keyword = "";
      this.getTableData();
    }
  },
  created() {
    this.resetHandle();
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.to-store-out-report {
  padding: 20px;
  .table-content {
    position: relative;
    width: 100%;
    height: calc(100vh - 160px);
    overflow: auto;
    .table {
      .thead{
        .th {
          font-size: 15px;
        }
      }
      .th,.td {
        padding: 0 10px;
        
        &:nth-child(2),
        &:nth-child(3),
        &:nth-child(6){
          width: 40%;
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