<template>
  <div class="dept-region-seat-open-report">
    <el-drawer
      title="部门实时订台/区域开台表"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="90%"
    >
      <div class="report-toolbar" layout="row" layout-align="space-between center">
        <span>最后刷新时间：{{ nowTime || '--' }}</span>
        <button class="export-button" @click="exportExcelHandle">导出Excel</button>
      </div>

      <section class="report-section">
        <h3>部门实时订台数</h3>
        <div class="report-table">
          <div class="report-row report-header">
            <div>订台部门</div>
            <div>实时订台数量</div>
          </div>
          <template v-if="deptList.length">
            <div
              v-for="(item, index) in deptList"
              :key="`dept-${item.id}-${index}`"
              class="report-row"
              :class="{ 'report-total': isTotal(item) }"
            >
              <div
                class="report-name"
                :style="{ paddingLeft: `${departmentDisplay(item).indent * 14}px` }"
              >{{ departmentDisplay(item).name }}</div>
              <div>{{ safeCount(item.c) }}</div>
            </div>
          </template>
          <div v-else class="report-empty">暂无数据</div>
        </div>
      </section>

      <div class="report-divider"></div>

      <section class="report-section">
        <h3>区域开台总数</h3>
        <div class="report-table">
          <div class="report-row report-header">
            <div>区域</div>
            <div>开台总数</div>
          </div>
          <template v-if="regionList.length">
            <div
              v-for="(item, index) in regionList"
              :key="`region-${item.id}-${index}`"
              class="report-row"
              :class="{ 'report-total': isTotal(item) }"
            >
              <div class="report-name">{{ regionDisplayName(item) }}</div>
              <div>{{ safeCount(item.c) }}</div>
            </div>
          </template>
          <div v-else class="report-empty">暂无数据</div>
        </div>
      </section>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="closeDrawerHandle">关闭</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_book from "@/api/Book";
import reportUtils from "@/utils/deptRegionSeatOpenReport";

const { formatDepartmentName, isTotalRow, toSafeCount } = reportUtils;

export default {
  props: {
    showDrawer: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      show: Boolean(this.showDrawer),
      nowTime: '',
      deptList: [],
      regionList: []
    };
  },
  methods: {
    isTotal (item) {
      return isTotalRow(item);
    },
    safeCount (value) {
      return toSafeCount(value);
    },
    departmentDisplay (item) {
      if (this.isTotal(item)) {
        return { name: '合计', indent: 0 };
      }
      return formatDepartmentName(item && item.n);
    },
    regionDisplayName (item) {
      return this.isTotal(item) ? '合计' : ((item && item.n) || '');
    },
    async getReportData () {
      this.nowTime = '';
      this.deptList = [];
      this.regionList = [];

      try {
        const res = await api_book.reqGetDeptRegionSeatOpenList({});
        if (res.code === 1) {
          const data = res.data || {};
          this.nowTime = data.now_time || '';
          this.deptList = Array.isArray(data.dept_list) ? data.dept_list : [];
          this.regionList = Array.isArray(data.region_list) ? data.region_list : [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取部门实时订台/区域开台表失败", error);
      }
    },
    async exportExcelHandle () {
      try {
        const res = await api_book.reqExportDeptRegionSeatOpenList({});
        if (res.msg) {
          this.$message.warning(res.msg);
          return;
        }

        const url = window.URL.createObjectURL(
          new Blob([res], {
            type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
          })
        );
        const a = document.createElement("a");
        const fileName = res.fileName
          ? decodeURIComponent(res.fileName)
          : "部门实时订台区域开台表.xlsx";

        document.body.appendChild(a);
        a.href = url;
        a.download = fileName;
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
      } catch (error) {
        console.log("导出部门实时订台/区域开台表失败", error);
      }
    },
    closeDrawerHandle () {
      this.$emit("showOrHideDrawer", false);
    }
  },
  watch: {
    showDrawer: {
      immediate: true,
      handler (newVal) {
        this.show = Boolean(newVal);
        if (this.show) {
          this.getReportData();
        }
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/book/machine/drawerDeptRegionSeatOpen.less";
</style>
