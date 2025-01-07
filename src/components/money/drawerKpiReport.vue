<template>
  <div  class="kpi-report">
    <!-- 业绩日报表 -->
    <el-drawer
      title="业绩日报表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div >
        <div class="top" layout="row" layout-align="start center">
          <span style="margin-left: 10px;">类型：</span>
            <mySelect
             style="width:150px; height: 30px;"
             :value="selectInfo.selectVal"
             :optionsList="selectInfo.selectOption"
             @selectOptionItem="setSelectValHandle"
             @selectBlurHandle="selectBlurHandle"
             @getOption="getOptionHandle"
             />
             <span style="margin:0 10px">订位部门：</span>
             <el-cascader
              style="width: 200px"
              placeholder="请选择部门"
              clearable
              :options="deptItrems"
              :props="optionProp"
              v-model="deptIds"
              popper-class="liebdwd"
              @change="getTableData"
              ref="deptRef"
            >
            </el-cascader>
            <span style="margin:0 10px">订位人：</span>
            <input-select
                    :autoFocus="true"
                    style="width: 200px"
                    :value="sales_name"
                    placeholder="请输入姓名或工号"
                    :optionsList="sales_info_option"
                    @selectInputHandle="inputAeName"
                    @selectOptionItem="changeAeName"
                    @selectBlurHandle="selectAeBlurHandle"
                ></input-select>
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
              <div class="th" v-if="selectInfo.selectVal != '按部门分组'" style=" width: 12%">订位人</div>
              <div class="th" v-if="selectInfo.selectVal != '按部门分组'" style=" width: 12%">订位人部门</div>

              <div class="th" style="width: 8%">开台时间</div>
              <div class="th" style="width: 10%">折前(含未结金额)</div>
              <div class="th" style="width: 10%">折后(含未结金额)</div>
              <div class="th" style="width: 10%">可计业绩</div>
              <div class="th" style="width: 10%">未结金额</div>
              <div class="th" style="width: 10%">优惠金额</div>
              <div class="th" v-if="selectInfo.selectVal !== '按订位人排名汇总'" style=" width: 10%">转台记录</div>
              <div class="th" v-if="selectInfo.selectVal !== '按订位人排名汇总'" style=" width: 10%">咨客备注</div>
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
              <div class="td one-txt-cut"  v-if="selectInfo.selectVal != '按部门分组'" style="width: 12%"> {{item.e || '-'}}</div>
              <div class="td one-txt-cut" v-if="selectInfo.selectVal != '按部门分组'" style="width: 12%">{{item.n || '-'}}</div>
              <div class="td one-txt-cut" style="width: 8%">{{item.o || '-'}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{format2(item.z)}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{format2(item.v)}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{format2(item.y)}}</div>
              <div class="td one-txt-cut" style="width: 10%">{{format2(item.u)}}</div>
              <div class="td one-txt-cut" style="width: 10%;padding-right: 0;">{{format2(item.h)}}</div>
              <div class="td one-txt-cut"  v-if="selectInfo.selectVal !== '按订位人排名汇总'" style="width: 10%"> {{item.c || '-'}}</div>
              <div class="td one-txt-cut"  v-if="selectInfo.selectVal !== '按订位人排名汇总'" style="width: 10%"> {{item.br || '-'}}</div>

             
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
import inputSelect from "@/components/book/inputSelect";
export default {
  data() {
    return {
      deptItrems: [], //部门信息
      deptIds: [], //选中的分类
      optionProp: {
        value: "id",
        label: "n",
        children: "subs",
        checkStrictly: true,
        expandTrigger: "hover",
      }, //规则
      sales_name: '',
      sales_phone: '',
      sales_emp_id: '',
      sales_info_option: [],
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
    inputAeName(query) {
      this.sales_name = query;
      this.sales_phone = "";
      this.sales_emp_id = "";
      const sealInfoArr =
          this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
      const results = query? sealInfoArr.filter(
              (el) =>
                  el.code.toString().includes(query) ||
                  el.name.toString().includes(query) ||
                  el.namePy.toString().includes(query.toLowerCase())
          )
          : sealInfoArr;
      this.sales_info_option = results;
    },
    changeAeName(info) {
      this.sales_name = info.name;
      this.sales_phone = info.phoneNum;
      this.sales_emp_id = info.id;
      this.sales_info_option = [];
      this.getTableData()
    },
    selectAeBlurHandle() {
      this.sales_info_option = [];
    },
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
        type_id: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1, //    int 查询类型:1 不分组 2 按部门分组 3 按区域分组 4 直属部门分组
        dept_id: this.deptIds.length > 0 ?this.deptIds[this.deptIds.length - 1] * 1: 0,
        sales_emp_id: this.sales_emp_id ? this.sales_emp_id * 1: 0
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
    mySelect,
    inputSelect,
  },
  computed: {
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      newVal ? this.getTableData() : "";

      if(newVal) {
        this.$api.BMS.dept.requestDeptTree().then((res) => {
          if (res.code == 1) {
            this.deptItrems = res.data || [];
          } else {
            this.$message.warning(res.msg);
          }
        });
      }
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

<style lang="less">
.liebdwd {
  .el-cascader-menu {
    border-right: solid 1px rgba(255, 255, 255, 0.1);
    background: #2A3959 !important;
    overflow-x: hidden;
  }

  
  .el-cascader-menu__list {
    position: relative;
    min-height: 100%;
    margin: 0;
    padding: 6px 0;
    list-style: none;
    box-sizing: border-box;
    background: #2A3959;
    overflow-x: hidden;
  }
  &.el-cascader__dropdown {
    margin: 5px 0;
    font-size: 14px;
    background: #2A3959;
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 4px;
    box-shadow: 0 2px 12px 0 rgba(0, 0, 0, .1);
  }

  .el-cascader-node {
    color: rgba(255, 255, 255, 0.8);
    
    &:not(.is-disabled):hover, 
    &:not(.is-disabled):focus {
      background: rgba(255, 255, 255, 0.1);
    }

    &.in-active-path, 
    &.is-active, 
    &.is-selectable.in-checked-path {
      color: #409EFF;
      background: rgba(64, 158, 255, 0.08);
    }
  }

  .el-cascader-menu__wrap{
    height: auto;
  }
}
</style>