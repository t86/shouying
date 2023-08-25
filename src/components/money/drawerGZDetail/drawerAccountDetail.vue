<template>
  <div>
    <!-- 查看记录 -->
    <el-drawer
      title="查看记录"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="80%"
    >
      <div class="GZ-detail">
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

        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="start center">
              <div class="th">序号</div>
              <div class="th">操作时间</div>
              <div class="th">类型</div>
              <div class="th">金额</div>
              <div class="th">还款方式</div>
              <div class="th">操作人</div>
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
              <div class="td">{{item.o}}</div>
              <div class="td">{{item.t}}</div>
              <div class="td">{{item.a}}</div>
              <div class="td">{{item.c}}</div>
              <div class="td">{{item.e}}</div>
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
            name: "挂账"
          },
          {
            id: 2,
            name: "挂账还款"
          }
        ]
      },
      tableData: [],
    };
  },
  methods: {
    // 获取数据
    async getTableData() {
      const params = {
        id: this.currentInfo.id * 1, //  int64   挂账账户Id
        type_id: this.selectInfo.originSelectOption.find(item => item.name == this.selectInfo.selectVal).id  //    int   类型 0 全部 1 挂账 2 挂账还款
      }
      try {
        const res = await api_money.reqGetGZLogs(params);
        if (res.code == 1) {
          this.tableData = res.data.records || []
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("详情获取失败", error);
      }
    },

    
    resetHandle() {
      this.selectInfo.selectVal = "全部";
      this.getTableData();
    },


    onCancelDrawer() {
      this.$emit("showOrHideDetailDrawer");
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
    },
    currentInfo: {
      default: () => ({})
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
@import "../../../style/money/drawerGZDetail/drawerAccountDetail.less";
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
</style>