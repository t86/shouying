<template>
  <div>
    <!-- 线上支付汇总 -->
    <el-drawer
      title="线上支付汇总"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="60%"
    >
      <div class="stop-class">
        <!-- 线上支付汇总预览 -->
        <div class="stop-class-prev">
          <div class="stop-class-top">
            <img :src="imgSrc.endStoreTop" alt />
          </div>
          <div class="stop-class-content">
            <div class="contain">
              <div class="contain-content">
                <!-- 班结表标题 -->
                <div class="contain-content-title">
                  <h3>{{dataInfo.org_name}}</h3>
                  <h3>线上支付汇总单</h3>
                  <p class="line">营业日期：{{dataInfo.biz_day}}</p>
                </div>
                <!-- 数据总览 -->
                <div class="contain-content-all-data line" v-for="(item, i) in dataInfo.pays" :key="i">
                  <h4 class="m-t-1 m-b-2">{{item.n}}</h4>
                  <div layout="row" layout-align="space-between center">
                    <p class="w40" layout="row" layout-align="space-between center"><span>成功笔数：</span><span>{{item.pc}}</span></p>
                    <p class="w50" layout="row" layout-align="space-between center"><span>金额：</span><span>¥{{item.pa}}</span></p>
                  </div>
                  <div layout="row" layout-align="space-between center">
                    <p class="w40" layout="row" layout-align="space-between center"><span>退单笔数</span><span>{{item.bc}}</span></p>
                    <p class="w50" layout="row" layout-align="space-between center"><span>金额：</span><span>¥{{item.ba}}</span></p>
                  </div>
                </div>
                
                <!-- 打印时间 -->
                <div class="m-t-4 contain-content-time">
                  打印时间：{{printTime}}
                </div>
              </div>
            </div>
            <img :src="imgSrc.endStoreBottom" alt />
          </div>
        </div>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="printAllData">打印</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";

import endStoreTop from "@/assets/money-img/end-store-top.png";
import endStoreBottom from "@/assets/money-img/end-store-bottom.png";
export default {
  data() {
    return {
      show: false,
      dataInfo: {},
      printTime: '',
      imgSrc: {
        endStoreTop,
        endStoreBottom
      }
    };
  },
  methods: {
    init(){
      this.getTime()
      this.getAllData()
    },
    // 获取数据
    async getAllData() {
      try {
        const res = await api_money.reqGetOnlinePayTotalInfo();
        if (res.code == 1) {
          res.data.pays = res.data.pays || []
          this.dataInfo = res.data
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('获取支付汇总单失败', error)
      }
    },

    // 打印班结表
    async printAllData() {
      try {
        const res = await api_money.reqPrintOnlinePayTotal();
        res.code === 1
          ? this.$message.success("打印成功")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("打印支付汇总单失败", error);
      }
    },

    onCancelDrawer() {
      this.$emit("showOrHideOnlineTotalHandle");
    },

    getTime(){
      const date = new Date()
      const year = date.getFullYear()
      const month = (date.getMonth() + 1).toString().padStart(2, 0)
      const day = date.getDate().toString().padStart(2, 0)
      const H = date.getHours().toString().padStart(2, 0)
      const M = date.getMinutes().toString().padStart(2, 0)
      const S = date.getSeconds().toString().padStart(2, 0)
      this.printTime = year + '-' + month + '-' + day + ' ' + H + ':' + M + ':' + S
    }
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      newVal ? this.init() : "";
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerStopClass.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>