<template>
  <div class="XC-detail">
    <!-- 现抽汇总表 -->
    <el-drawer
      title="现抽汇总表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div>
        <div class="top" layout="row" layout-align="space-between center">
          <div class="top-left" layout="row" layout-align="start center">
            <input v-model="keyword" placeholder="商品名称/点单人" />
            <el-button
              class="m-l-2"
              type="primary"
              style="width:70px;height:30px;line-height:30px;padding:0"
              @click="getTableData"
            >查询</el-button>
            <el-button
              type="info"
              style="width:70px;height:30px;line-height:30px;padding:0"
              @click="resetHandle"
            >重置</el-button>
          </div>
          <el-button
            type="primary"
            @click="exportExcel"
            style="width:90px;height:30px;line-height:30px;padding:0"
          >导出Excel</el-button>
        </div>

        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">抽成对象</div>
              <div class="th">抽成人</div>
              <div class="th">抽成部门</div>
              <div class="th">商品名称</div>
              <div class="th">点单总数量</div>
              <div class="th">点单总金额</div>
              <div class="th">抽成总金额</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              layout="row"
              layout-align="start center"
              v-for="(item, index) in tableData"
              :key="index"
            >
              <div class="td one-txt-cut">{{index + 1}}</div>
              <div class="td">{{item.o}}</div>
              <div class="td">{{item.tn}}</div>
              <div class="td">{{item.d}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.a}}</div>
              <div class="td">{{item.ca}}</div>
            </div>
            <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
let originTableData = [];
export default {
  data() {
    return {
      show: false,
      keyword: "",
      tableData: []
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      const params = {
        key: this.keyword //  string  查询关键字 
      };
      try {
        const res = await api_money.reqGetXCAllInfo(params);
        if (res.code == 1) {
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取表格数据失败", error);
      }
    },

    // 导出excel
    async exportExcel() {
      const params = {
        key: this.keyword //  string  查询关键字 
      };

      try {
        const res = await api_money.reqExportXCAllInfoReport(params);
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

    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
    },

    resetHandle() {
      this.keyword = "";
      this.getTableData();
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      newVal ? this.resetHandle() : "";
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>
<style lang="less" scoped>
.XC-detail {
  ::-webkit-scrollbar {
    width: 15px;
    height: 15px;
  }

  color: rgba(255, 255, 255, 0.8);
  //padding: 20px;
  font-size: 14px;
  box-sizing: border-box;
  
  .top {
    input {
      width: 180px;
      height: 30px;
      box-sizing: border-box;
      padding: 0 10px;
      margin-left: 10px;
      border-radius: 8px;
      border: 1px solid rgba(255, 255, 255, 0.15);
      font-size: 14px;

      &::placeholder{
        color: rgba(255, 255, 255, 0.3);
      }
    }
  }

  .table {
    margin-top: 20px;
    border: 1px solid #999;
    border-radius: 10px;
    height: calc(100vh - 220px);
    width: 100%;
    overflow: auto;

    .tr {
      box-sizing: border-box;
      min-height: 36px;
      // line-height: 36px;
      padding: 4px 0;
      font-size: 14px;
    }

    .thead {
      width: 100%;
      position: sticky;
      top: 0;
      z-index: 10;
      background-color: #131b31;
      color: rgba(255, 255, 255, .5);
    }

    .tbody {
      width: 100%;
      .tr:nth-child(2n) {
        background-color: #2f3342;
      }
      .tr:nth-child(2n + 1) {
        background-color: #2A3959;
      }
    }

    .th,
    .td {
      padding: 0 10px;
      box-sizing: border-box;
    }

    .th:nth-child(1),
    .td:nth-child(1) {
      width: 8%;
    }

    .th:nth-child(2),
    .td:nth-child(2) {
      width: 12%;
    }

    .th:nth-child(3),
    .td:nth-child(3) {
      width: 12%;
    }

    .th:nth-child(4),
    .td:nth-child(4) {
      width: 16%;
    }

    .th:nth-child(5),
    .td:nth-child(5) {
      width: 25%;
    }

    .th:nth-child(6),
    .td:nth-child(6) {
      width: 16%;
    }

    .th:nth-child(7),
    .td:nth-child(7) {
      width: 16%;
    }

    .th:nth-child(8),
    .td:nth-child(8) {
      width: 16%;
    }
  }
}

.pointer {
  cursor: pointer;
}
/deep/ .el-drawer__body {
  //flex: unset;
  //overflow-y: scroll;
  margin-bottom: 68px;
}
</style>