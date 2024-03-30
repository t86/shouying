<template>
  <div>
    <!-- 线上预订记录 -->
    <el-drawer
      title="线上预订记录"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="online-booking">
        <div class="top" layout="row" layout-align="space-between center">
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
              <div class="th">卡台名称</div>
              <div class="th">区域</div>
              <div class="th">客人姓名</div>
              <div class="th">手机号</div>
              <div class="th">预订时间</div>
              <div class="th">开台时间</div>
              <div class="th">预付金</div>
              <div class="th">预付金(已使用)</div>
              <div class="th">预付金(剩余)</div>
              <div class="th">预付金(退还)</div>
              <div class="th">状态</div>
              <div class="th">备注</div>
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
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.rn}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{item.o}}</div>
              <div class="td">{{item.ot}}</div>
              <div class="td">{{item.pa}}</div>
              <div class="td">{{item.ua}}</div>
              <div class="td">{{item.b}}</div>
              <div class="td">{{item.ba}}</div>
              <div class="td">{{item.st}}</div>
              <div class="td">{{item.r}}</div>
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
        const res = await api_money.reqGetBookingList();
        if (res.code == 1) {
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("表格数据获取失败", error);
      }
    },

    // 导出excel
    async exportExcel() {
      try {
        const res = await api_money.reqExportBookingListReport();
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
      this.$emit("showOrHideOnlineBookingDrawer");
    },
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
@import "../../style/money/drawerOnlineBooking.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>