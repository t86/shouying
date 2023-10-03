<template>
  <div>
    <!-- 分类渠道汇总表 -->
    <el-drawer
      title="分类渠道汇总表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="QD-detail">
        <div class="top" layout="row" layout-align="start center">
          <div class="top-left" layout="row" layout-align="start center">
            <el-button
              class="m-l-2"
              type="primary"
              style="width: 70px; height: 30px; line-height: 30px; padding: 0"
              @click="getTableData"
              >查询</el-button
            >
            <!-- <el-button
              type="info"
              style="width: 70px; height: 30px; line-height: 30px; padding: 0"
              @click="resetHandle"
              >重置</el-button
            > -->
          </div>
          <el-button
            type="primary"
            @click="exportExcel"
            style="
              width: 90px;
              height: 30px;
              line-height: 30px;
              padding: 0;
              margin-left: 10px;
            "
            >导出Excel</el-button
          >
        </div>
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">类别</div>
              <div class="th" v-for="cn in cnls" :key="cn.id">{{cn.n}}</div>
              <div class="th">合计</div>
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
              <div class="td one-txt-cut">{{ index + 1 }}</div>
              <div class="td">{{ item.name }}</div>
              <div class="td" v-for="cnl in cnls" :key="name">
                <span>{{ item[cnl.id] || "0.00" }} </span>
              </div>
              <div class="td">{{ item.total }}</div>
            </div>
            <div
              class="tr"
              layout="row"
              layout-align="end center">
              <div class="td" style="margin-right: 28px;"> 总合计: {{ all_total }}</div>
            </div>
            <p
              v-if="tableData.length == 0"
              class="m-t-10 fs14"
              style="text-align: center"
            >
              暂无数据
            </p>
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
export default {
  name: "drawerCatQDAllInfo",
  data() {
    return {
      show: false,
      tableData: [],
      cnls: [],
      all_total: 0,
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      try {
        const res = await api_money.reqGetJkList();
        if (res.code == 1) {
          const records = res.data.records || [];
          const cnls = res.data.cnls || [];
          this.all_total = 0;
          const row = Array.from(new Set([...records.map(item => item.c)]));
          this.tableData = row.map(d=>{
            const items = records.filter(item=>item.c == d);
            const total = items.reduce((total, item) => {
              return total + Number(item.a);
            }, 0);
            this.all_total += total;
            const res =  {
              name:d,
              total:total.toFixed(2),
            }
            for(var item in items){
              res[items[item].l] = items[item].a;
            }
            return res;
          });
          this.all_total = this.all_total.toFixed(2);
          this.cnls = cnls;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取表格数据失败", error);
      }
    },

    // 导出excel
    async exportExcel() {
      try {
        const res = await api_money.reqExportJkList();
        if (!res.msg) {
          const url = window.URL.createObjectURL(
            new Blob([res], {
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
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
      this.getTableData();
    },
  },
  props: {
    showDrawer: {
      default: false, // 是否显示drawer
    },
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      newVal ? this.resetHandle() : "";
    },
  },
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>
<style lang="less" scoped>
.QD-detail {
  color: rgba(255, 255, 255, 0.8);
  padding: 20px;
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

      &::placeholder {
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
      position: sticky;
      top: 0;
      z-index: 10;
      background-color: #131b31;
      width: 100%;
      color: rgba(255, 255, 255, 0.5);
    }

    .tbody {
      width: 100%;
      .tr:nth-child(2n) {
        background-color: #2f3342;
      }
      .tr:nth-child(2n + 1) {
        background-color: #2a3959;
      }
    }

    .th,
    .td {
      padding: 0 10px;
      box-sizing: border-box;
      width: 25%;
    }

    .th:nth-child(1),
    .td:nth-child(1) {
      width: 10%;
    }
  }
}

.pointer {
  cursor: pointer;
}
</style>
