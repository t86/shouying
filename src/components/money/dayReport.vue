<template>
  <div class="day-report">
    <div class="header white p-l-4 p-r-4" layout="row" layout-align="space-between center">
      <span>售出日报表</span>
      <i class="el-icon-close" @click="$emit('showOrHideDayReportHandle')"></i>
    </div>
    <div class="session white" layout="row" layout-align="space-between center">
      <div class="session-left" layout="row" layout-align="space-around center">
        <div class="session-left-contain">
          <h4>二级分类</h4>
          <div class="session-left-contain-checkbox">
            <div>
              <el-checkbox
                v-model="secondCategoryInfo.checkedAll"
                :indeterminate="secondCategoryInfo.indeterminate"
                @change="changeSelectHandle('category', 'all')"
              >全部</el-checkbox>
            </div>
            <div class="m-t-2" v-for="item in secondCategoryInfo.list" :key="item.id">
              <el-checkbox
                v-model="item.checked"
                @change="changeSelectHandle('category', 'item')"
              >{{item.n}}</el-checkbox>
            </div>
          </div>
        </div>
        <div class="session-left-contain">
          <h4>出品库</h4>
          <div class="session-left-contain-checkbox">
            <div>
              <el-checkbox
                v-model="outLibraryInfo.checkedAll"
                :indeterminate="outLibraryInfo.indeterminate"
                @change="changeSelectHandle('library', 'all')"
              >全部</el-checkbox>
            </div>
            <div class="m-t-2" v-for="item in outLibraryInfo.list" :key="item.id">
              <el-checkbox
                v-model="item.checked"
                @change="changeSelectHandle('library', 'item')"
              >{{item.n}}</el-checkbox>
            </div>
          </div>
        </div>
      </div>
      <div class="session-center" layout="row" layout-align="center center">
        <div class="session-center-contain">
          <div layout="row" layout-align="start center">
            <span class="m-r-2" style="width: 80px;">打印出品库</span>
            <mySelect
              style="width:50%"
              :value="prtSelectInfo.selectVal"
              :optionsList="prtSelectInfo.selectOption"
              @selectOptionItem="setSelectPrtValHandle"
              @selectBlurHandle="selectPrtBlurHandle"
              @getOption="getPrtOptionHandle"
            />
          </div>
          <div class="m-t-4" layout="row" layout-align="start center">
            <span class="m-r-2" style="width: 80px;">订单类型</span>
            <mySelect
              style="width:50%"
              :value="selectInfo.selectVal"
              :optionsList="selectInfo.selectOption"
              @selectOptionItem="setSelectValHandle"
              @selectBlurHandle="selectBlurHandle"
              @getOption="getOptionHandle"
            />
          </div>
          <div class="m-t-4" layout="row" layout-align="center center">
            <button class="primary" @click="getTableData">统计</button>
          </div>
          <div class="m-t-4" layout="row" layout-align="center center">
            <button class="primary" @click="printTableData">打印</button>
          </div>
          <div class="m-t-4" layout="row" layout-align="center center">
            <button class="cancel" @click="$emit('showOrHideDayReportHandle')">关闭</button>
          </div>
        </div>
      </div>
      <div class="session-right">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">商品名称</div>
              <div class="th">售出数量</div>
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
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.c}}</div>
            </div>
            <p v-if="tableData.length == 0" class="m-t-10 fs14" style="text-align:center">暂无数据</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import mySelect from "@/components/book/select";
export default {
  data() {
    return {
      secondCategoryInfo: {
        list: [],
        checkedAll: true,
        indeterminate: false
      },
      outLibraryInfo: {
        list: [],
        checkedAll: true,
        indeterminate: false
      },
      prtSelectInfo: {
        selectVal: "",
        selectOption: [],
        originSelectOption: []
      },
      selectInfo: {
        selectVal: "全部订单",
        selectOption: [],
        originSelectOption: [
          {
            id: 0,
            name: "全部订单"
          },
          {
            id: 5,
            name: "已结订单"
          },
          {
            id: 1,
            name: "未结订单"
          }
        ]
      },
      tableData: []
    };
  },
  methods: {
    // 获取二级分类及出品库
    async getParams() {
      try {
        const res = await api_money.reqGetSoldOutRptItems();
        if (res.code == 1) {
          res.data.two_cates = res.data.two_cates || [];
          res.data.mklibs = res.data.mk_libs || [];
          this.secondCategoryInfo.list = res.data.two_cates.map(item => ({
            ...item,
            checked: true
          }));
          this.outLibraryInfo.list = res.data.mk_libs.map(item => ({
            ...item,
            checked: true
          }));
          this.prtSelectInfo.originSelectOption = res.data.prt_mk_libs.map(item => {
            return {name: item.n, id: item.id}
          } )
          this.prtSelectInfo.selectVal = this.prtSelectInfo.originSelectOption.length > 0 ? this.prtSelectInfo.originSelectOption[0].name : ''
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取日报表参数失败", error);
      }
    },

        /*
     打印出品筛选下拉框相关 start
    */
    setSelectPrtValHandle(info) {
      this.prtSelectInfo.selectVal = info.name;
    },
    selectPrtBlurHandle() {
      this.prtSelectInfo.selectOption = [];
    },
    getPrtOptionHandle() {
      this.prtSelectInfo.selectOption = JSON.parse(
        JSON.stringify(this.prtSelectInfo.originSelectOption)
      );
    },
    /*
    筛选下拉框相关 start
    */
    setSelectValHandle(info) {
      this.selectInfo.selectVal = info.name;
    },
    selectBlurHandle() {
      this.selectInfo.selectOption = [];
    },
    getOptionHandle() {
      this.selectInfo.selectOption = JSON.parse(
        JSON.stringify(this.selectInfo.originSelectOption)
      );
    },
    /*
    筛选下拉框相关 end
    */

    async getTableData() {
      const params = {
        is_all_cate: this.secondCategoryInfo.checkedAll ? 1: 2,
        is_all_mklib: this.outLibraryInfo.checkedAll ? 1 : 2,
        two_cate_ids: this.secondCategoryInfo.checkedAll
          ? []
          : this.secondCategoryInfo.list
              .filter(item => item.checked)
              .map(item => item.id * 1), // []int64   二级分类列表,如果是全部,传一个元素为0的数组
        mklib_ids: this.outLibraryInfo.checkedAll
          ? []
          : this.outLibraryInfo.list
              .filter(item => item.checked)
              .map(item => item.id * 1), //  []int64   出品库列表,如果是全部,传一个元素为0的数组
        status: this.selectInfo.originSelectOption.find(
          item => item.name == this.selectInfo.selectVal
        ).id, // int     订单类型, 0 全部 1 已结账 2 未结账
        prt_mklib_id: this.prtSelectInfo.originSelectOption.find(item => item.name == this.prtSelectInfo.selectVal).id
      };

      if (params.two_cate_ids.length == 0 && !params.is_all_cate)
        return this.$message.warning("请选择二级分类筛选条件");
      if (params.mklib_ids.length == 0 && !params.is_all_mklib)
        return this.$message.warning("请选择出品库筛选条件");
      try {
        const res = await api_money.reqGetSoldOutRpt(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("读取售出汇总表失败", error);
      }
    },

    async printTableData() {
      const params = {
        is_all_cate: this.secondCategoryInfo.checkedAll ? 1: 2,
        is_all_mklib: this.outLibraryInfo.checkedAll ? 1 : 2,
        two_cate_ids: this.secondCategoryInfo.checkedAll
          ? []
          : this.secondCategoryInfo.list
              .filter(item => item.checked)
              .map(item => item.id * 1), // []int64   二级分类列表,如果是全部,传一个元素为0的数组
        mklib_ids: this.outLibraryInfo.checkedAll
          ? []
          : this.outLibraryInfo.list
              .filter(item => item.checked)
              .map(item => item.id * 1), //  []int64   出品库列表,如果是全部,传一个元素为0的数组
        status: this.selectInfo.originSelectOption.find(
          item => item.name == this.selectInfo.selectVal
        ).id, // int     订单类型, 0 全部 1 已结账 2 未结账
        prt_mklib_id: this.prtSelectInfo.originSelectOption.find(item => item.name == this.prtSelectInfo.selectVal).id
      };

      if (params.two_cate_ids.length == 0 && !params.is_all_cate)
        return this.$message.warning("请选择二级分类筛选条件");
      if (params.mklib_ids.length == 0 && !params.is_all_mklib)
        return this.$message.warning("请选择出品库筛选条件");

      try {
        const res = await api_money.reqPrtSoldOutRpt(params);
        if (res.code == 1) {
          this.$message.success('打印成功');
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("打印售出报表失败", error);
      }

    },

    changeSelectHandle(type1, type2) {
      const info =
        type1 == "category" ? this.secondCategoryInfo : this.outLibraryInfo;
      if (type2 == "all") {
        info.list.forEach(el => {
          el.checked = info.checkedAll;
        });
      } else {
        info.checkedAll = info.list.every(item => item.checked);
        info.indeterminate =
          !info.checkedAll && info.list.some(item => item.checked);
      }
    }
  },
  async mounted() {
    await this.getParams();
    await this.getTableData();
  },
  components: {
    mySelect
  }
};
</script>

<style scoped lang="less">
@import "../../style/money/dayReport.less";
</style>