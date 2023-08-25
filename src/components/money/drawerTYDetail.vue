<template>
  <div>
    <!-- 特饮小费明细表 -->
    <el-drawer
      title="特饮小费明细表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="TY-detail">
        <div class="top" layout="row" layout-align="space-between center">
          <div class="top-left" layout="row" layout-align="start center">
            <input v-model="keyword" placeholder="订台人/点单人/商品名称" />
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
              <div class="th">区域</div>
              <div class="th">卡台名称</div>
              <div class="th">下单/补交时间</div>
              <div class="th">点单人</div>
              <div class="th">点单人部门</div>
              <div class="th">商品一级分类</div>
              <div class="th">商品二级分类</div>
              <div class="th">商品名称</div>
              <div class="th">点单金额</div>
              <div class="th">订台人</div>
              <div class="th">订位部门</div>
              <div class="th">补交台</div>
              <div class="th">补交营业日</div>
              <div class="th">支付信息描述</div>
              <div class="th">{{showArrow ? '>>' : ''}}</div>
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
              <div class="td">{{item.rn}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.o}}</div>
              <div class="td">{{item.ae}}</div>
              <div class="td">{{item.ad}}</div>
              <div class="td">{{item.on}}</div>
              <div class="td">{{item.tn}}</div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.a}}</div>
              <div class="td">{{item.se}}</div>
              <div class="td">{{item.sd}}</div>
              <div class="td">{{item.bs}}</div>
              <div class="td">{{item.bb}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{showArrow ? '>>' : ''}}</div>
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
      tableData: [],
      showArrow: true,
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      const params = {
        key: this.keyword //  string  查询关键字 
      };
      try {
        const res = await api_money.reqGetTYList(params);
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
        const res = await api_money.reqExportTYListReport(params);
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

    // 表格数据排序  index:1 升序  2 降序
    sortTableHandle(index) {
      this.sortIndex = this.sortIndex == index ? "" : index;
      if (this.sortIndex === "") {
        this.tableData = JSON.parse(JSON.stringify(originTableData));
      } else {
        this.tableData.sort((a, b) => (this.sortIndex == 1 ? a.ca - b.ca : b.ca - a.ca));
      }
    },

    onCancelDrawer() {
      this.$emit("showOrHideTYDetailDrawer");
    },

    resetHandle() {
      this.keyword = "";
      this.getTableData();
      setTimeout(() => {
        const table = document.querySelector('.table')
        const tableWidth = table.offsetWidth
        const tbody = document.querySelector('.tbody')
        const tbodyWidth = tbody.offsetWidth
        const that = this
        table.onscroll = function() {
          that.showArrow = tbodyWidth - (table.scrollLeft + tableWidth) >= 40
        }
      }, 1000);
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
@import "../../style/money/drawerTYDetail.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>