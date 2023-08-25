<template>
  <div>
    <!-- 优惠明细表 -->
    <el-drawer
      title="优惠明细表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="98%"
    >
      <div class="YH-detail">
        <div class="top" layout="row" layout-align="space-between center">
          <div class="top-left" layout="row" layout-align="start center">
            <span>优惠类型：</span>
            <mySelect
              style="width:150px"
              :value="selectInfo.selectVal"
              :optionsList="selectInfo.selectOption"
              @selectOptionItem="setSelectValHandle"
              @selectBlurHandle="selectBlurHandle"
              @getOption="getOptionHandle"
            />
            <input v-model="keyword" placeholder="订台人/优惠人/商品名称" />
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
              <div class="th">优惠时间</div>
              <div class="th">优惠类型</div>
              <div class="th">优惠人</div>
              <div class="th">优惠部门</div>
              <div class="th">优惠理由</div>
              <div class="th">商品一级分类</div>
              <div class="th">商品二级分类</div>
              <div class="th">商品名称</div>
              <div class="th">商品单价</div>
              <div class="th">优惠数量</div>
              <div class="th">优惠金额小计</div>
              <div class="th">订台人</div>
              <div class="th">订台部门</div>
              <div class="th">优惠2关联台</div>
              <div class="th">优惠2关联台区域</div>
              <div class="th">优惠2订位人</div>
              <div class="th">优惠2订位人部门</div>
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
              <div class="td">{{item.rn}}</div>
              <div class="td">{{item.s}}</div>
              <div class="td">{{item.o}}</div>
              <div class="td">{{item.t}}</div>
              <div class="td">{{item.ae}}</div>
              <div class="td">{{item.ad}}</div>
              <div class="td">{{item.r}}</div>
              <div class="td">{{item.on}}</div>
              <div class="td">{{item.tn}}</div>
              <div class="td">{{item.n}}</div>
              <div class="td">{{item.p}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.a}}</div>
              <div class="td">{{item.se}}</div>
              <div class="td">{{item.sd}}</div>
              <div class="td">{{item.es}}</div>
              <div class="td">{{item.er}}</div>
              <div class="td">{{item.ee}}</div>
              <div class="td">{{item.ed}}</div>
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
import mySelect from "@/components/book/select";
export default {
  data() {
    return {
      show: false,
      selectInfo: {
        selectVal: "全部",
        selectOption: [],
        originSelectOption: [
          {
            id: 0,
            name: "全部"
          },
          {
            id: 1,
            name: "优惠"
          },
          {
            id: 2,
            name: "优惠2"
          }
        ]
      },
      keyword: "",
      tableData: [],
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      const params = {
        yh_type: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1, //    int      0 全部 1 优惠 2 优惠2
        key: this.keyword, //        string    模糊查询关键字(订台人/优惠人/商品名称)
      }
      try {
        const res = await api_money.reqGetYHList(params);
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
      this.selectInfo.selectVal = "全部";
      this.getTableData();
    },

    // 导出excel
    async exportExcel() {
      const params = {
        yh_type: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id * 1, //    int      0 全部 1 优惠 2 优惠2
        key: this.keyword, //        string    模糊查询关键字(订台人/优惠人/商品名称)
      }

      try {
        const res = await api_money.reqExportYHListReport(params);
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
      this.$emit("showOrHideYHDetailDrawer");
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
      newVal ? this.resetHandle() : "";
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerYHDetail.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>