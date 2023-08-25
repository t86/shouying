<template>
  <div>
    <!-- 结束营业日 -->
    <el-drawer
      :title="status==1?'手动结束营业':'自动结束营业日时间设置'"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="60%"
    >
      <!-- 手动结束 -->
      <div v-if="status==1" class="store-end">
        <!-- 班结表预览 -->
        <div class="store-end-prev">
          <div class="store-end-top">
            <img :src="imgSrc.endStoreTop" alt />
          </div>
          <div class="store-end-content">
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
                  <p/>
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
                      非主营合计：
                    </span>
                    <span>
                      ¥{{dataInfo.not_zy_amt?(dataInfo.not_zy_amt*1).toFixed(2):'0.00'}}
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
                      主营未付合计：
                    </span>
                    <span>
                      ¥{{dataInfo.zy_topay_amt?(dataInfo.zy_topay_amt*1).toFixed(2):'0.00'}}
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
                      实收合计：
                    </span>
                    <span>
                      ¥{{dataInfo.value_amt?(dataInfo.value_amt*1).toFixed(2):'0.00'}}
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

      <!-- 自动结束 -->
      <div v-else class="auto-store-end">
        <el-form label-position="right" label-width="220px" @submit.native.prevent>
          <el-form-item label="是否开启自动结束营业日功能:">
            <input type="radio" v-model="timeInfo.radio" value="1" /> 是
            <input type="radio" v-model="timeInfo.radio" value="2" class="m-l-5" /> 否
          </el-form-item>
          <el-form-item label="选择结束时间:">
            <div layout="row" layout-align="start center">
              <selectCom
                style="width:60px;height:24px"
                :value="timeInfo.hour"
                :optionsList="timeInfo.hourOption"
                @getOption="getHourOption"
                @selectBlurHandle="selectBlurHandle"
                @selectOptionItem="clickHourOption"
              />&nbsp;时 &nbsp;&nbsp;
              <selectCom
                style="width:60px;height:24px"
                :value="timeInfo.minute"
                :optionsList="timeInfo.minuteOption"
                @getOption="getMinuteOption"
                @selectBlurHandle="selectBlurHandle"
                @selectOptionItem="clickMinuteOption"
              />&nbsp;分
            </div>
          </el-form-item>
        </el-form>
      </div>
      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">{{status==1?'打印并结束':'确定'}}</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_money from "@/api/money";
import api_book from "@/api/Book";

import selectCom from "@/components/book/select";

import endStoreTop from "@/assets/money-img/end-store-top.png";
import endStoreBottom from "@/assets/money-img/end-store-bottom.png";
export default {
  data() {
    return {
      show: false,
      dataInfo: {},
      printTime: '',
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
    async getAllData() {
      this.getTime()
      const params = {
        region_ids: [-1], // []int64   限制区域Id, 如果不限制, 放一个元素-1
        cashier_ids: [-1], // []int64  限制收银员Id, 如果不限制, 放一个元素-1
      }
      try {
        const res = await api_money.reqGetAllData(params);
        if (res.code === 1) {
          res.data.pays = res.data.pays || [];
          res.data.orders = res.data.orders || [];
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
        region_ids: [-1], // []int64   限制区域Id, 如果不限制, 放一个元素-1
        cashier_ids: [-1], // []int64  限制收银员Id, 如果不限制, 放一个元素-1
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

    // 手动结束营业日并打印班结表
    async endStore() {
      try {
        const res = await api_book.reqWorkClose();
        if (res.code === 1) {
          this.$message.success("结束操作成功");
          this.onCancelDrawer();
          this.$emit("logoutHandle", "logoutNotConfirm");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("打印班结表失败", error);
      }
    },

    // 获取结束营业日配置
    async getAutoStopInfo() {
      try {
        const res = await api_book.reqGetAutoStopInfo();
        if (res.code === 1) {
          this.timeInfo.hour = res.data.hour.toString().padStart(2, 0);
          this.timeInfo.minute = res.data.minute.toString().padStart(2, 0);
          this.timeInfo.radio = res.data.on_off.toString();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取营业日配置失败", error);
      }
    },

    // 设置自动结束营业日
    async autoEndStore() {
      const params = {
        on_off: this.timeInfo.radio * 1, //     int    1 开 2 关
        hour: this.timeInfo.radio == 1 ? this.timeInfo.hour * 1 : 0, // int    自动结束时 >=0 <=23 如果开关是关闭的话填0
        minute: this.timeInfo.radio == 1 ? this.timeInfo.minute * 1 : 0 // int     自动结束分钟 >=0 <=59 如果开关是关闭的话填0
      };
      try {
        const res = await api_book.reqWorkCloseAuto(params);
        if (res.code === 1) {
          this.$message.success("设置成功");
          this.onCancelDrawer();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("设置自动结束营业日时间失败", error);
      }
    },

    onCancelDrawer() {
      this.$emit("showOrHideEndStoreDrawer");
    },

    onSubmit() {
      if (this.status == 1) {
        this.$confirm(
          "注意：结束营业日会清空当前营业数据，请确认场所已结束营业。相关人员已下班。",
          "结束营业日",
          {
            distinguishCancelAndClose: true,
            confirmButtonText: "确定",
            cancelButtonText: "取消"
          }
        )
          .then(() => {
            // this.printAllData();  // 仅仅打印班结表
            this.endStore();  // 结束营业日并打印班结表
          })
          .catch(e => "");
      } else {
        this.autoEndStore();
      }
    },

    getHourOption() {
      const hourOption = [];
      for (let i = 0; i < 24; i++) {
        hourOption.push({
          id: i.toString().padStart(2, 0),
          name: i.toString().padStart(2, 0)
        });
      }
      this.timeInfo.hourOption = hourOption;
    },

    getMinuteOption() {
      const minuteOption = [];
      for (let i = 0; i < 60; i++) {
        minuteOption.push({
          id: i.toString().padStart(2, 0),
          name: i.toString().padStart(2, 0)
        });
      }
      this.timeInfo.minuteOption = minuteOption;
    },

    clickHourOption(info) {
      this.timeInfo.hour = info.name;
    },

    clickMinuteOption(info) {
      this.timeInfo.minute = info.name;
    },

    selectBlurHandle() {
      this.timeInfo.hourOption = [];
      this.timeInfo.minuteOption = [];
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
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    status: {
      default: 1 // 1：手动结束  2：自动结束
    }
  },
  components: {
    selectCom
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      this.status == 1 && newVal ? this.getAllData() : "";
      this.status == 2 && newVal ? this.getAutoStopInfo() : "";
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/money/drawerStopStore.less";
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>