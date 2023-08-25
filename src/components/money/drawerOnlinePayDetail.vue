<template>
  <div>
    <!-- 线上支付记录 -->
    <el-drawer
      title="线上支付记录"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="96%"
    >
      <div class="online-pay-detail">
        <div class="top" layout="row" layout-align="space-between center">
          <div class="top-left" layout="row" layout-align="start center">
            <span>类型：</span>
            <mySelect
              style="width:150px"
              :value="selectInfo.selectVal"
              :optionsList="selectInfo.selectOption"
              @selectOptionItem="setSelectValHandle"
              @selectBlurHandle="selectBlurHandle"
              @getOption="getOptionHandle"
            />
            <input v-model="keyword" placeholder="输入订位人或卡台名称" />
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
              <div class="th">卡台名称</div>
              <div class="th">区域</div>
              <div class="th">订位人</div>
              <div class="th">部门</div>
              <div class="th">支付渠道</div>
              <div class="th">交易金额</div>
              <div class="th">类型</div>
              <div class="th">交易时间</div>
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
              <div class="td one-txt-cut">{{item.sn}}</div>
              <div class="td one-txt-cut">{{item.rn}}</div>
              <div class="td one-txt-cut">{{item.en}}</div>
              <div class="td one-txt-cut">{{item.dn}}</div>
              <div class="td one-txt-cut">{{item.cn}}</div>
              <div class="td one-txt-cut">{{item.a}}</div>
              <div class="td one-txt-cut">{{item.t}}</div>
              <div class="td one-txt-cut">{{item.tt}}</div>
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
            name: "点单结账"
          },
          {
            id: 2,
            name: "退款"
          }
        ]
      },
      keyword: "",
      tableData: []
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      const params = {
        type_id: this.selectInfo.originSelectOption.find(
          item => item.name == this.selectInfo.selectVal
        ).id, //    int   类型 1 点单结账 2 退款 0 全部
        key: this.keyword //  string   查询关键字 过滤 定位人或定位人拼音或卡台名称
      };
      try {
        const res = await api_money.reqGetOnlinePayDetailInfo(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取在线支付流水单失败", error);
      }
    },

    // 导出excel
    async exportExcel() {
      const params = {
        type_id: this.selectInfo.originSelectOption.find(
          item => item.name == this.selectInfo.selectVal
        ).id, //    int   类型 1 点单结账 2 退款 0 全部
        key: this.keyword //  string   查询关键字 过滤 定位人或定位人拼音或卡台名称
      };

      try {
        const res = await api_money.reqExportExcelOfOnlinePayDetail(params);
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
      this.$emit("showOrHideOnlinePayDetailHandle");
    },

    resetHandle() {
      this.selectInfo.selectVal = "全部";
      this.keyword = "";
      this.getTableData();
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
      newVal ? this.getTableData() : "";
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerOnlinePayDetail.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>