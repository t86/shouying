<template>
  <div>
    <!-- 班结表 -->
    <el-drawer
      title="班结表"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="60%"
    >
      <div class="stop-class">
        <!-- 班结表中数据筛选条件 -->
        <div class="condition m-b-4">
          <div class="area m-b-4" layout="row" layout-align="start center">
            <div class="label">区域：</div>
            <div class="label-content">
              <el-checkbox v-model="originCheckedAll" @change="changeCheckbox('areaAll')" :indeterminate="originIndeterminate">全部</el-checkbox>
              <el-checkbox v-model="item.checked" @change="changeCheckbox('areaItem')" v-for="item in originInfoArr" :key="item.id">{{item.n}}</el-checkbox>
            </div>
          </div>
          <div class="person p-b-4 border-bot" layout="row" layout-align="start center">
            <div class="label">收银员：</div>
            <div class="label-content">
              <el-checkbox v-model="personCheckedAll" @change="changeCheckbox('personAll')" :indeterminate="personIndeterminate">全部</el-checkbox>
              <el-checkbox v-model="item.checked" @change="changeCheckbox('personItem')" v-for="item in personInfoArr" :key="item.id">{{item.n}}</el-checkbox>
            </div>
          </div>
          <div class="m-t-4">
            <el-button type="primary" @click="getAllData">开始统计</el-button>
            <el-button type="primary" @click="printAllData">打印</el-button>
          </div>
        </div>
        
        <!-- 班结表预览 -->
        <div class="stop-class-prev">
          <div class="stop-class-top">
            <img :src="imgSrc.endStoreTop" alt />
          </div>
          <div class="stop-class-content" style="max-height:calc(100vh - 350px)">
            <div class="contain">
              <div class="contain-content">
                <!-- 班结表标题 -->
                <div class="contain-content-title">
                  <h3>{{dataInfo.org_name}}</h3>
                  <h3>班结表</h3>
                  <p class="line">营业日期：{{dataInfo.biz_day||'--'}}</p>
                </div>
                <!-- 数据总览 -->
                <div class="contain-content-all-data line">
                  <p>收银员：{{dataInfo.cashier_names||'--'}}</p>
                  <p>单数：{{dataInfo.total_items||0}}</p>
                  <div layout="row" layout-align="space-between center">
                    <p class="w40" layout="row" layout-align="space-between center"><span>退单笔数：</span><span>{{dataInfo.back_items||0}}</span></p>
                    <p class="w50" layout="row" layout-align="space-between center"><span>退单金额：</span><span>¥{{dataInfo.back_amt||'0.00'}}</span></p>
                  </div>
                  <div layout="row" layout-align="space-between center">
                    <p class="w40" layout="row" layout-align="space-between center"><span>优惠笔数：</span><span>{{dataInfo.yh_items||0}}</span></p>
                    <p class="w50" layout="row" layout-align="space-between center"><span>优惠金额：</span><span>¥{{dataInfo.yh_amt||'0.00'}}</span></p>
                  </div>
                  <div layout="row" layout-align="space-between center">
                    <p class="w40" layout="row" layout-align="space-between center"><span>优惠2笔数：</span><span>{{dataInfo.yh2_items||0}}</span></p>
                    <p class="w50" layout="row" layout-align="space-between center"><span>优惠2金额：</span><span>¥{{dataInfo.yh2_amt||'0.00'}}</span></p>
                  </div>
                  <div layout="row" layout-align="space-between center">
                    <p layout="row" layout-align="space-between center"><span>会员卡线上充值金额：</span><span>¥{{dataInfo.mb_ol_dep_amt||0}}</span></p>
                  </div>
                  <div layout="row" layout-align="space-between center">
                    <p layout="row" layout-align="space-between center"><span>会员卡线下充值金额：</span><span>¥{{dataInfo.mb_of_dep_amt||0}}</span></p>
                  </div>
                  <div layout="row" layout-align="space-between center">
                    <p layout="row" layout-align="space-between center"><span>挂账还款合计：</span><span>¥{{dataInfo.act_rtn_amt||0}}</span></p>
                  </div>
                </div>
                <!-- 支付渠道 -->
                <div class="contain-content-pay-list line">
                  <div class="title" layout="row">
                    <h4 class="w64">支付渠道</h4>
                    <h4 class="w36 txt-right">金额</h4>
                  </div>
                  <ul class="m-t-1">
                    <li layout="row" v-for="(item,index) in dataInfo.pays" :key="index">
                      <p class="w64">{{item.p}}</p>
                      <p class="w36 txt-right">¥{{(item.a*1).toFixed(2)}}</p>
                    </li>
                  </ul>
                </div>
                <!-- 收入 -->
                <div class="contain-content-get-money line">
                  <div class="title" layout="row">
                    <h4 class="w64">收入</h4>
                    <h4 class="w36 txt-right">金额</h4>
                  </div>
                  <ul class="m-t-1">
                    <li layout="row" v-for="(item,index) in dataInfo.orders" :key="index">
                      <p class="w64">{{item.c}}</p>
                      <p class="w36 txt-right">¥{{(item.a*1).toFixed(2)}}</p>
                    </li>
                  </ul>
                </div>
                <!-- 总结算数据 -->
                <div class="contain-content-result">
                  <p layout="row" layout-align="space-between center">
                    <span>
                      账单合计：
                    </span>
                    <span>
                      ¥{{dataInfo.total_amt?(dataInfo.total_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                  <p layout="row" layout-align="space-between center"> 
                    <span>
                      优惠合计：
                    </span>
                    <span>
                      ¥{{dataInfo.yh_amt?(dataInfo.yh_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                  <p layout="row" layout-align="space-between center"> 
                    <span>
                      优惠2合计：
                    </span>
                    <span>
                      ¥{{dataInfo.yh2_amt?(dataInfo.yh2_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                  <p layout="row" layout-align="space-between center">
                    <span>
                      应收合计：
                    </span>
                    <span>
                      ¥{{dataInfo.order_amt?(dataInfo.order_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                  <p layout="row" layout-align="space-between center">
                    <span>
                      折扣合计：
                    </span>
                    <span>
                      ¥{{dataInfo.free_amt?(dataInfo.free_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                  <p layout="row" layout-align="space-between center">
                    <span>
                      非主营未付合计：
                    </span>
                    <span>
                      ¥{{dataInfo.not_zy_topay_amt?(dataInfo.not_zy_topay_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                  <p layout="row" layout-align="space-between center">
                    <span>
                      主营未付合计：
                    </span>
                    <span>
                      ¥{{dataInfo.zy_topay_amt?(dataInfo.zy_topay_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                  <p layout="row" layout-align="space-between center">
                    <span>
                      实收合计：
                    </span>
                    <span>
                      ¥{{dataInfo.value_amt?(dataInfo.value_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                  <p layout="row" layout-align="space-between center">
                    <span>
                      非主营实收合计：
                    </span>
                    <span>
                      ¥{{dataInfo.not_zy_amt?(dataInfo.not_zy_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                  <p layout="row" layout-align="space-between center">
                    <span>
                      主营实收合计：
                    </span>
                    <span>
                      ¥{{dataInfo.value_amt?(dataInfo.zy_value_amt*1).toFixed(2):'0.00'}}
                    </span>
                  </p>
                </div>
                <!-- 打印时间 -->
                <div class="contain-content-time">
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
      originInfoArr: [], // 区域列表
      personInfoArr: [], // 收银员列表
      originCheckedAll: true,
      personCheckedAll: true,
      timeInfo: {
        radio: "1",
        hour: "",
        minute: "",
        hourOption: [],
        minuteOption: []
      },
      imgSrc: {
        endStoreTop,
        endStoreBottom
      }
    };
  },
  methods: {
    // 获取班结表
    async getAllData(status) {
      this.getTime()
      const params = {
        region_ids: this.originCheckedAll || status == -1 ? [-1] : this.originInfoArr.filter(item => item.checked).map(item => item.id * 1), // []int64 限制区域Id, 如果不限制, 放一个元素-1
        cashier_ids: this.personCheckedAll || status == -1 ? [-1] : this.personInfoArr.filter(item => item.checked).map(item => item.id * 1), // []int64 限制收银员Id, 如果不限制, 放一个元素-1
      }
      try {
        const res = await api_money.reqGetAllData(params);
        if (res.code === 1) {
          res.data.pays = res.data.pays || [];
          res.data.orders = res.data.orders || [];
          if(status == -1){
            res.data.region_filters = res.data.region_filters || []
            res.data.cashier_filters = res.data.cashier_filters || []
            this.originInfoArr = res.data.region_filters.map(item => ({
              ...item,
              checked: true
            }))
            this.personInfoArr = res.data.cashier_filters.map(item => ({
              ...item,
              checked: true
            }))
          }
          this.dataInfo = res.data;
          
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("班结表获取失败", error);
      }
    },

    // 打印班结表
    async printAllData() {
      const params = {
        region_ids: this.originCheckedAll ? [-1] : this.originInfoArr.filter(item => item.checked).map(item => item.id * 1), // []int64   限制区域Id, 如果不限制, 放一个元素-1
        cashier_ids: this.personCheckedAll ? [-1] : this.personInfoArr.filter(item => item.checked).map(item => item.id * 1), // []int64  限制收银员Id, 如果不限制, 放一个元素-1
      }
      try {
        const res = await api_money.reqPrintAllData(params);
        res.code === 1
          ? this.$message.success("打印成功")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("打印班结表失败", error);
      }
    },

    // 改变checkbox
    changeCheckbox(item){
      switch (item){
        case 'areaAll':
          this.originInfoArr.forEach(item => {
            item.checked = this.originCheckedAll
          })
          break
        case 'areaItem':
          this.originCheckedAll = this.originInfoArr.every(item => item.checked)
          break
        case 'personAll':
          this.personInfoArr.forEach(item => {
            item.checked = this.personCheckedAll
          })
          break
        case 'personItem':
          this.personCheckedAll = this.personInfoArr.every(item => item.checked)
          break
      }
    },

    onCancelDrawer() {
      this.$emit("showOrHideStopClassDrawer");
    },

    // 获取打印时间
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
  computed: {
    originIndeterminate(){
      return this.originInfoArr.some(item => item.checked) && !this.originCheckedAll
    },
    personIndeterminate(){
      return this.personInfoArr.some(item => item.checked) && !this.personCheckedAll}
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      newVal ? this.getAllData(-1) : "";
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