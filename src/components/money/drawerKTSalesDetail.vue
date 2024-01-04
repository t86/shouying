<template>
  <div>
    <!-- 商品卡台销售表 -->
    <el-drawer
      title="商品-卡台销售表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="KT-detail">
        <div class="top" layout="row" layout-align="space-between center">
          <div class="top-left" layout="row" layout-align="start center">
            <input v-model="keyword" placeholder="输入商品名称/简写搜索" />
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
              <div class="th">商品名称</div>
              <div class="th">一级分类</div>
              <div class="th">二级分类</div>
              <div class="th">卡台</div>
              <div class="th">开台时间</div>
              <div class="th">订位人</div>
              <div class="th">单品销售数</div>
              <div class="th">套餐内销售数</div>
              <div class="th">合计数</div>
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
              <div class="td">{{index + 1}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{item.o}}</div>
              <div class="td">{{item.t}}</div>
              <div class="td">{{item.sn}}</div>
              <div class="td">{{item.ot}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.dc}}</div>
              <div class="td">{{item.sc}}</div>
              <div class="td">{{item.tc}}</div>
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
export default {
  data() {
    return {
      show: false,
      keyword: "",
      tableData: [],
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      const params = {
        key: this.keyword, //        string    模糊查询关键字(订台人/优惠人/商品名称)
      }
      try {
        const res = await api_money.reqGePrdSetSoldCnt(params);
        if (res.code == 1) {
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
      }
    },

    
    resetHandle() {
      this.keyword = "";
      this.getTableData();
    },

    // 导出excel
    async exportExcel() {
      const params = {
        key: this.keyword, //        string    模糊查询关键字(订台人/优惠人/商品名称)
      }

      try {
        const res = await api_money.reqExportPrdSetSoldCnt(params);
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
      this.$emit("showOrHideYHDetailDrawer");
    },

  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  components: {
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
@import "../../style/money/drawerKTSalesDetail.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>