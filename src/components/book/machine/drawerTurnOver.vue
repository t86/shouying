<template>
  <div class="trunover">
    <el-drawer
      title="转台记录"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      size="80%"
    >
      <!-- 订单表格 -->
      <p class="white p-t-4 p-b-4 p-l-6 fs14">最近刷新时间：{{loadTime}}</p>
      <div class="table">
        <div class="thead">
          <div class="tr">
            <div class="th">序号</div>
            <div class="th">开台时间</div>
            <div class="th">转台记录</div>
          </div>
        </div>
        <div class="tbody" ref="scrollDom">
          <div v-if="tableData.length==0" style="text-align:center;transform:translateY(40px)">暂无数据</div>
          <div v-else ref="scrollItem">
            <div class="coll" v-for="(item,i) in tableData" :key="i">
              <div class="detail tr">
                <div class="td">{{i+1}}</div>
                <div class="td">{{item.o}}</div>
                <div class="td">
                  <p v-for="(items,index) in item.detailList" :key="index">{{items}}</p>
                </div>
              </div>
            </div>
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
import api_book from "@/api/Book";

export default {
  data() {
    return {
      show: false,
      loadTime: '',
      tableData: []
    };
  },
  methods: {
    getReloadTime(){
      const date = new Date();
      const Y = date.getFullYear();
      const M = (date.getMonth() + 1).toString().padStart(2, 0);
      const D = date.getDate().toString().padStart(2, 0);
      const hour = date.getHours().toString().padStart(2, 0);
      const minute = date.getMinutes().toString().padStart(2, 0);
      const second = date.getSeconds().toString().padStart(2, 0);
      this.loadTime = `${Y}-${M}-${D} ${hour}:${minute}:${second}`
    },
    async getTableData() {
      this.getReloadTime();
      try {
        const res = await api_book.reqTurnOverList()
        if(res.code == 1){
          res.data.records = res.data.records || []
          this.tableData = res.data.records.map(item => ({
            ...item,
            detailList: item.i.split('\n')
          }))


        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('转台记录获取失败', error);
      }
    },
    closeDrawerHandle() {
      this.$emit("showOrHideDrawer", false);
    },

    onCancelDrawer() {
      this.closeDrawerHandle();
    }
  },
  mounted() {
    // this.formData.customArriveInfo.exp_arrive_time = '202210030330'
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) this.getTableData();
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/scrollBar.less";
@import "../../../style/book/machine/drawerTurnOver.less";
</style>
