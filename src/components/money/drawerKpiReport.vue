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
              <div class="th" style="width: 8%">序号</div>
              <div class="th" v-if="selectInfo.selectVal == '按部门分组'" style=" width: 20%">订位部门/订位人</div>
              <div class="th" style=" width: 10%">区域</div>
              <div class="th" style="width: 10%">卡台</div>
              <div class="th" v-if="selectInfo.selectVal != '按部门分组'" style=" width: 15%">订位人</div>
              <div class="th" v-if="selectInfo.selectVal != '按部门分组'" style=" width: 15%">订位人部门</div>

              <div class="th" style="width: 10%">开台时间</div>
              <div class="th" style="width: 10%">折前(含未结金额)</div>
              <div class="th" style="width: 10%">折后(含未结金额)</div>
              <div class="th" style="width: 10%">可计业绩</div>
              <div class="th" style="width: 10%">未结金额</div>
              <div class="th" style="width: 10%">优惠金额</div>
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
              <div class="td one-txt-cut" style="width: 8%">{{i + 1}}</div>
              <div class="td one-txt-cut" v-if="selectInfo.selectVal == '按部门分组'" style=" width: 20%"><div :style="{
                paddingLeft: (item.b* 5) + 'px'}">{{item.n}}</div></div>
              <div class="td one-txt-cut" style=" width: 10%">{{item.r || '-'}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{item.s || '-'}}</div>
              <div class="td one-txt-cut"  v-if="selectInfo.selectVal != '按部门分组'" style="width: 15%"> {{item.e || '-'}}</div>
              <div class="td one-txt-cut" v-if="selectInfo.selectVal != '按部门分组'" style="width: 15%">{{item.n || '-'}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{item.o || '-'}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{format2(item.z)}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{format2(item.v)}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{format2(item.y)}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{format2(item.u)}}</div>
              <div class="td one-txt-cut" style="width: 10%;padding-right: 0;">{{format2(item.h)}}</div>
             
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
          },
          {
            id: 4,
            name: "按直属部门分组"
          },
          {
            id: 5,
            name: "按订位人排名汇总"
          }
       ]
     },
      tableData: []
    };
  },
  methods: {
    countStartingSpaces(str) {
      const spaces = str.match(/^\s*/)[0].length;
      return spaces;
    },
    format(number) {
        if(number == 0 || !number) return '-';
        number = number.toString();

        let decimalIndex = number.length - 2; 
        return number.substring(0, decimalIndex) + "." + number.substring(decimalIndex);
      },
    format2(number) {
      if(number == 0 || !number) return '-';
      return (number/100.0).toFixed(2)
    },
    // 获取数据
    async getTableData() {
      const params = {
        type_id: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1 //    int 查询类型:1 不分组 2 按部门分组 3 按区域分组 4 直属部门分组
      };
      try {
        const res = await api_money.reqGetKpiReportInfo(params);
        if (res.code == 1) {
          this.tableData = res.data.records || []
          this.tableData = this.tableData.map(item => {
            return {...item, 
              b: this.countStartingSpaces(item.n)}
          })
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
        type_id: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1 //    int 查询类型:1 不分组 2 按部门分组 3 按区域分组
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