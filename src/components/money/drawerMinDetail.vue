<template>
  <div class="min-detail">
    <!-- 低消进度统计表 -->
    <el-drawer
      title="低消进度统计表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div >
        <div class="top">
          <el-button
            v-if="!isOrder()"
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
              <div class="th">开台时间</div>
              <div class="th">订位人部门</div>
              <div class="th">订位人</div>
              <div class="th">最低消费</div>
              <div class="th">主营金额</div>
              <div class="th">差额</div>
              <div class="th">低消进度</div>
              <div class="th">清台时间</div>
              <div class="th">标签</div>
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
              <div class="td">{{item.sn}}</div>
              <div class="td">{{item.o}}</div>
              <div class="td">{{item.sd}}</div>
              <div class="td">{{item.se}}</div>
              <div class="td">{{item.m}}</div>
              <div class="td">{{item.za}}</div>
              <div class="td">{{item.ga}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{item.t}}</div>
              <div class="td">{{item.mk}}</div>
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
      tableData: [],
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      try {
        const res = await api_money.reqGetMinDetail();
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
      try {
        const res = await api_money.reqExportMinDetailReport();
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
  isOrder(){
    return sessionStorage.getItem("client") == "order"
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
      newVal ? this.getTableData() : "";
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerMinDetail.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>