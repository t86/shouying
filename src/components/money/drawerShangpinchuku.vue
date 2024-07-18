<template>
  <div>
    <!-- 点单记录 -->
    <el-drawer
      title="商品出库表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="order-detail">
        <div class="top" layout="row" layout-align="space-between center">
          <div class="value m-r-2">
            <span class="label">营业日期:</span>
            <el-date-picker style="width:140px" v-model="begin_day" type="date" :clearable="false" size="small"
                            value-format="yyyy-MM-dd" placeholder="开始日期"></el-date-picker>
            <span>至</span>
            <el-date-picker style="width:140px" v-model="end_day" type="date" :clearable="false" size="small"
                            value-format="yyyy-MM-dd" placeholder="结束日期"></el-date-picker>
            <span class="label">商品名称:</span>
              <input
                  v-model="keyword"
                  placeholder="商品名称"
              />
              <el-button
                  class="m-l-2"
                  type="primary"
                  style="width: 70px; height: 30px; line-height: 30px; padding: 0"
                  @click="getTableData"
              >查询</el-button
              >
              <el-button
                  type="info"
                  style="width: 70px; height: 30px; line-height: 30px; padding: 0"
                  @click="resetHandle"
              >重置</el-button
              >
          </div>

          <el-button
            type="primary"
            @click="exportExcel"
            style="width: 90px; height: 30px; line-height: 30px; padding: 0"
            >导出Excel</el-button
          >
        </div>

        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">一级分类</div>
              <div class="th">二级分类</div>
              <div class="th">商品名称</div>
              <div class="th">单品出库数量</div>
              <div class="th">套餐内出库数量</div>
              <div class="th">总出库量</div>
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
              <div class="td">{{ index + 1 }}</div>
              <div class="td">{{ item.on }}</div>
              <div class="td">{{ item.tn }}</div>
              <div class="td">{{ item.n }}</div>
              <div class="td">{{ item.dc }}</div>
              <div class="td">{{ item.sc }}</div>
              <div class="td">{{ item.c }}</div>
            </div>
            <p
              v-if="tableData.length === 0"
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
  data() {
    return {
      show: false,
      keyword: '',
      begin_day: '',
      end_day: '',
      tableData: [],
    };
  },
  methods: {
    resetHandle() {
      console.log('----------------------------')
      const oneHour = +new Date('2023/07/22 12:00:00') - +new Date('2023/07/22 11:00:00')
      const date = new Date(+new Date() - 8 * oneHour)
      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, 0);
      const day = date
          .getDate()
          .toString()
          .padStart(2, 0);
      const now = year + "-" + month + "-" + day;
      console.log(now)
      this.begin_day = now;
      this.end_day = now;
      this.getTableData();
    },
    // 获取数据
    async getTableData() {
      const params = {
        key: this.keyword || '', //  string  查询关键字
        start_day: this.begin_day || '',
        end_day: this.end_day || '',
      };
      try {
        const res = await api_money.reRptPrdOutList(params);
        if (res.code === 1) {
          this.tableData = res.data.records || [];
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
        key: this.keyword || '', //  string  查询关键字
        start_day: this.begin_day || '',
        end_day: this.end_day || '',
      };

      try {
        const res = await api_money.reqExportRptPrdOutList(params);
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
      this.$emit("showOrHideShangpinchukuDrawer");
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
@import "../../style/money/drawerOrder.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>

<style>
.el-scrollbar .el-scrollbar__view.el-select-dropdown__list {
  background-color: #2a3959;
}
.el-select-dropdown__empty {
  background-color: #2a3959;
}
</style>

<style scoped></style>
