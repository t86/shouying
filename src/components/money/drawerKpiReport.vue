<template>
  <div>
    <!-- 业绩日报表 -->
    <el-drawer
      title="业绩日报表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="kpi-report">
        <div class="top" layout="row" layout-align="start center">
          <span>类型：</span>
            <mySelect
              style="width:150px"
              :value="selectInfo.selectVal"
              :optionsList="selectInfo.selectOption"
              @selectOptionItem="setSelectValHandle"
              @selectBlurHandle="selectBlurHandle"
              @getOption="getOptionHandle"
            />
          <el-button
            type="primary"
            class="m-l-3"
            @click="exportExcel"
            style="width:90px;height:30px;line-height:30px;padding:0"
          >导出Excel</el-button>
        </div>
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">区域</div>
              <div class="th">卡台</div>
              <div class="th">订位人</div>
              <div class="th">订位人部门</div>
              <div class="th">开台时间</div>
              <div class="th">折前(含未结金额)</div>
              <div class="th">折后(含未结金额)</div>
              <div class="th">未结金额</div>
              <div class="th">优惠金额</div>
            </div>
          </div>
          <div class="tbody">
            <div
              class="tr"
              layout="row"
              layout-align="start center"
              v-for="(item, i) in tableData"
              :key="i"
            >
              <div class="td one-txt-cut">{{i + 1}}</div>
              <div class="td one-txt-cut">{{item.rn}}</div>
              <div class="td one-txt-cut">{{item.sn}}</div>
              <div class="td one-txt-cut">{{item.en}}</div>
              <div class="td one-txt-cut">{{item.sd}}</div>
              <div class="td one-txt-cut">{{item.o}}</div>
              <div class="td one-txt-cut">{{item.oza}}</div>
              <div class="td one-txt-cut">{{item.ozva}}</div>
              <div class="td one-txt-cut">{{item.uza}}</div>
              <div class="td one-txt-cut">{{item.ya}}</div>
            </div>
          </div>
          <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
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
import mySelect from "@/components/book/select";
export default {
  data() {
    return {
      show: false,
      selectInfo: {
        selectVal: "不分组",
        selectOption: [],
        originSelectOption: [
          {
            id: 1,
            name: "不分组"
          },
          {
            id: 2,
            name: "按部门分组"
          },
          {
            id: 3,
            name: "按区域分组"
          }
        ]
      },
      tableData: []
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      const params = {
        type_id: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1 //    int   查询类型:1 不分组 2 按部门分组 3 按区域分组
      }
      try {
        const res = await api_money.reqGetKpiReportInfo(params);
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
        type_id: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1 //    int   查询类型:1 不分组 2 按部门分组 3 按区域分组
      }
      try {
        const res = await api_money.reqExportExcelOfKpiReport(params);
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

    onCancelDrawer() {
      this.$emit("showOrHideKpiReportHandle");
    },

    /*
    筛选下拉框相关 start
    */
    setSelectValHandle(info) {
      this.selectInfo.selectVal = info.name;
      this.getTableData()
    },
    selectBlurHandle() {
      this.selectInfo.selectOption = [];
    },
    getOptionHandle() {
      this.selectInfo.selectOption = JSON.parse(
        JSON.stringify(this.selectInfo.originSelectOption)
      );
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  components: {
    mySelect
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
@import "../../style/money/drawerKpiReport.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>