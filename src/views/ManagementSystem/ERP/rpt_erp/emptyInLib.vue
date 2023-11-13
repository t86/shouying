<template>
  <div class="empty-in-lib">
    <div class="top">
      <div layout="row" layout-align="start center">
        <span class="label fs14">日期：</span>
        <ul class="time-select fs14 m-r-1" layout="row" layout-align="start center">
          <li layout="row" layout-align="start center" @click="setDateVal(1)">
            <img
              :src="activeTime == 1 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt />
            <span :class="{ active: activeTime == 1 }">近7天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(2)">
            <img
              :src="activeTime == 2 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt />
            <span :class="{ active: activeTime == 2 }">近30天</span>
          </li>
          <li layout="row" layout-align="start center" @click="setDateVal(3)">
            <img
              :src="activeTime == 3 ? require('@/assets/img/date_label_selete.png') : require('@/assets/img/date_label_grey.png')"
              alt />
            <span :class="{ active: activeTime == 3 }">近90天</span>
          </li>
        </ul>
        <div class="value m-r-2">
          <el-date-picker style="width:140px" v-model="start_day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
          <span>至</span>
          <el-date-picker style="width:140px" v-model="end_day" type="date" :clearable="false" size="small"
            value-format="yyyy-MM-dd" placeholder="结束日期"></el-date-picker>
        </div>

      </div>
      <div class="m-t-3">
        <span>服务员：</span>
        <el-input v-model="empKeyword" size="small" placeholder="请输入姓名或工号" style="width:200px"></el-input>
        <el-input v-model="keyword" size="small" placeholder="请输入空瓶名称或简写" style="width:200px"></el-input>
        <el-button type="primary" size="small" @click="getTableData">查询</el-button>
        <el-button type="primary" size="small" @click="resetHandle">重置</el-button>
        <el-button type="primary" size="small" @click="exportExcelHandle">导出Excel</el-button>
      </div>
    </div>

    <div class="table-content m-t-4">
      <div class="table">
        <div class="thead">
          <div class="tr" layout="row" layout-align="space-between center">
            <div class="th">入库日期</div>
            <div class="th">入库单号</div>
            <div class="th">服务员</div>
            <div class="th">空瓶名称</div>
            <div class="th">操作类型</div>
            <div class="th">入库数量</div>
            <div class="th">入库操作人</div>
            <div class="th">备注</div>
          </div>
        </div>
        <div class="tbody">
          <div class="tr" layout="row" layout-align="space-between center" v-for="(item) in tableData" :key="item.id">
            <div class="td">{{ item.t }}</div>
            <div class="td">{{ item.id }}</div>
            <div class="td">{{ item.w }}</div>
            <div class="td">{{ item.m }}</div>
            <div class="td">{{ item.n }}</div>
            <div class="td">{{ item.c }}</div>
            <div class="td">{{ item.o }}</div>
            <div class="td">{{ item.r }}</div>
          </div>
          <div class="no-data" v-if="tableData.length == 0">
            <img :src="require('@/assets/img/wu.png')" alt />
            <p>暂无数据</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
export default {
  data() {
    return {
      empKeyword: '',  // 服务员搜索关键字
      keyword: '', // 物料搜索关键字
      activeTime: 1, // 1：近7天  2：近30天  3：近3个月
      start_day: "",
      end_day: "",
      checkAll: false,
      tableData: [],
    };
  },
  methods: {
    async getTableData() {
      const params = {
        start_day: this.start_day, //  string   查询开始日期
        end_day: this.end_day, //    string   查询结束日期
        waiter_key: this.empKeyword, //  string   服务员模糊查询关键字
        mat_key: this.keyword  // string   物料模糊查询关键字
      };

      try {
        const res = await this.$api.ERP.reportEmpty.reqGetEmptyInLibDetailList(params);
        if (res.code == 1) {
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("读取空瓶入库明细表失败", error);
      }
    },

    async exportExcelHandle() {
      const params = {
        start_day: this.start_day, //  string   查询开始日期
        end_day: this.end_day, //    string   查询结束日期
        waiter_key: this.empKeyword, //  string   服务员模糊查询关键字
        mat_key: this.keyword  // string   物料模糊查询关键字
      };
      try {
        const res = await this.$api.ERP.reportEmpty.reqExportEmptyInLibDetailList(params)
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

    getDate(dateNum = +new Date()) {
      const date = new Date(dateNum);
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date
        .getDate()
        .toString()
        .padStart(2, 0);
      return year + "-" + month + "-" + day;
    },

    setDateVal(activeTime) {
      this.activeTime = activeTime;
      const dayInfo = {
        "1": 7,
        "2": 30,
        "3": 90
      };
      const oneDay = +new Date("2023/05/24") - +new Date("2023/05/23");
      const begin = this.getDate(+new Date() - oneDay * dayInfo[activeTime]);
      const end = this.getDate();
      this.start_day = begin;
      this.end_day = end;
      this.getTableData();
    },

    resetHandle() {
      this.keyword = ''
      this.empKeyword = ''
      this.setDateVal(1);
    }
  },
  created() {
    this.resetHandle();
  }
};
</script>

<style lang="less" scoped>
@import "../../../../style/erp/table.less";
</style>
<style scoped lang="less">
.empty-in-lib {
  padding: 20px;

  .top {
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
      height: calc(100vh - 250px);
      overflow: auto;
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