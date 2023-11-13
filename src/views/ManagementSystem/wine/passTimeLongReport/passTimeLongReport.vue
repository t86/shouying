<template>
  <!-- 延期记录 -->
  <div class="pass-time-long-report">
    <div class="top" layout="row" layout-align="start center">
      <div class="label fs14">操作日期：</div>
      <div class="value m-r-2">
        <el-date-picker style="width:140px" v-model="start_day" type="date" :clearable="false" size="small"
          value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
        <span>至</span>
        <el-date-picker style="width:140px" v-model="end_day" type="date" :clearable="false" size="small"
          value-format="yyyy-MM-dd" placeholder="结束日期"></el-date-picker>
      </div>
      <el-input
        v-model="keyword"
        style="width:200px"
        class="m-r-2 m-l-2"
        size="small"
        placeholder="输入客人姓名/手机号码/商品/卡台"
      ></el-input>
      <el-button type="primary" size="small" @click="getTableData">查询</el-button>
      <el-button size="small" @click="resetHandle">重置</el-button>
      <el-button type="primary" size="small" @click="exportExcelHandle">导出</el-button>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="center center">
            <div class="th">操作时间</div>
            <div class="th">延期操作人</div>
            <div class="th">延期天数</div>
            <div class="th">商品名称</div>
            <div class="th">规格</div>
            <div class="th">每瓶克数</div>
            <div class="th">数量</div>
            <div class="th">存酒流水号</div>
            <div class="th">客人姓名</div>
            <div class="th">联系方式</div>
            <div class="th">卡台</div>
            <div class="th">订位人</div>
            <div class="th">服务员</div>
            <div class="th">存酒时间</div>
            <div class="th">备注姓名</div>
            <div class="th">备注手机号</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" v-for="(item) in tableData" :key="item.id" layout="row" layout-align="space-between center">
            <div class="td">{{item.t}}</div>
            <div class="td">{{item.e}}</div>
            <div class="td">{{item.d}}</div>
            <div class="td one-txt-cut">{{item.pn}}</div>
            <div class="td">{{item.u}}</div>
            <div class="td">{{item.g}}</div>
            <div class="td">{{item.c}}</div>
            <div class="td" style="user-select: text;">{{item.i}}</div>
            <div class="td">{{item.n}}</div>
            <div class="td">{{item.p}}</div>
            <div class="td">{{item.s}}</div>
            <div class="td">{{item.se}}</div>
            <div class="td">{{item.we}}</div>
            <div class="td">{{item.it}}</div>
            <div class="td">{{item.rn}}</div>
            <div class="td">{{item.rp}}</div>
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
      start_day: "",
      end_day: "",
      tableData: []
    };
  },
  methods: {
    async getTableData() {
      const params = {
        start_day: this.start_day, //  string  存取开始日期
        end_day: this.end_day, // string  存取结束日期
        key: this.keyword || "" //  string   模糊查询关键字
      };

      try {
        const res = await api_wine.reqGetPassTimeLongReportList(params);
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
        start_day: this.start_day, //  string  存取开始日期
        end_day: this.end_day, // string  存取结束日期
        key: this.keyword || "" //  string   模糊查询关键字
      }
      try {
        const res = await api_wine.reqExportExcelOfPassTimeLongReport(params);
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
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/wine/table.less";
</style>
<style scoped lang="less">
.pass-time-long-report {
  padding: 20px;
  .table-content {
    position: relative;
    width: 100%;
    height: calc(100vh - 160px);
    overflow: auto;
    .table {
      min-width: 2060px;
      .thead{
        position: sticky;
        z-index: 10;
        .th {
          font-size: 15px;
          &:nth-child(1){
            position: sticky;
            left: 0;
            background-color: #eee;
          }
          &:nth-child(2){
            position: sticky;
            left: 152px;
            background-color: #eee;
          }
          &:nth-child(3){
            position: sticky;
            left: 305px;
            background-color: #eee;
          }
          &:nth-child(4){
            position: sticky;
            left: 403px;
            background-color: #eee;
          }
        }
      }
      .tbody {
        .tr {
          height: 40px;
          font-size: 15px;
          .td:nth-child(1) {
            position: sticky;
            left: 0;
          }
          .td:nth-child(2) {
            position: sticky;
            left: 152px;
          }
          
          .td:nth-child(3) {
            position: sticky;
            left: 304px;
          }
          .td:nth-child(4) {
            position: sticky;
            left: 402px;
          }
          &:nth-child(2n) {
            .td:nth-child(1),
            .td:nth-child(2),
            .td:nth-child(3),
            .td:nth-child(4){
              background-color: #f5f5f5;
            }
          }
          &:nth-child(2n + 1) {
            .td:nth-child(1),
            .td:nth-child(2),
            .td:nth-child(3),
            .td:nth-child(4){
              background-color: #f9f9f9;
            }
          }
        }

        
      }
      .th,.td {
        padding: 0 10px;
        box-sizing: border-box;
        &:nth-child(3),
        &:nth-child(5),
        &:nth-child(6),
        &:nth-child(7),
        &:nth-child(9),
        &:nth-child(12),
        &:nth-child(13){
          width: 30%;
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