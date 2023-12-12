<template>
  <div class="pay-order">
    <!-- 顶部翻台订单 -->
    <div class="top-tab">
      <ul
        :class="{ overflow: !turnOverInfo.turnOverTabShow }"
        ref="turnOverTabRef"
        layout="row"
        layout-align="start start"
      >
        <li
          :class="{ active: turnOverInfo.activeTurnOverCount == item.id }"
          v-for="(item, index) in turnOverInfo.turnOverTabList"
          :key="index"
          @click.stop="changeTab('turnOverCount', item.id)"
        >
          {{ item.name }}
        </li>
      </ul>
    </div>
    <!-- 订单详情 -->
    <div
      class="order-content"
      :style="
        isRect ? 'height: calc(100vh - 140px);' : 'height: calc(100vh - 160px);'
      "
    >
      <div class="order-content-tab">
        <ul
          ref="payTableRef"
          :class="{ overflow: !payTabInfo.payTabShow }"
          layout="row"
          layout-align="start start"
        >
          <li
            :class="{ active: item.id == payTabInfo.activePayId }"
            v-for="(item, i) in payTabInfo.payTabList"
            :key="i"
            @click.stop="changeTab('order', item.id)"
          >
            {{ item.name }}
          </li>
        </ul>
      </div>

      <!-- 表格内容 -->
      <div class="order-content-detail">
        <!-- 未支付订单表格 -->
        <notPayOrder
          v-if="payTabInfo.activePayId == 0"
          ref="notPayOrder"
          :notPayOrderList="notPayData.notPayOrderList"
          @updatePayOrderList="updatePayOrderList"
        />
        <!-- 已支付订单表格 -->
        <payedOrder
          v-else
          ref="payedOrder"
          :turnOverCount="turnOverInfo.activeTurnOverCount"
          :payedOrderList="payedData.payedOrderList"
          :payedOrderInfo="payedData.payedOrderInfo"
          :payTabList="payTabInfo.payTabList"
          :isTurnOver="isOldOrder"
          @updateChangedOrderData="updateBackOrderData"
        />
      </div>

      <!-- 底部数据 -->
      <div
        class="order-content-bottom"
        layout="row"
        layout-align="space-between center"
      >
        <div
          class="order-content-bottom-left"
          :class="{
            'not-pay': payTabInfo.activePayId == 0,
            'pay-item':
              payTabInfo.activePayId != 0 && payTabInfo.activePayId != -1,
          }"
          layout="row"
          layout-align="start center"
        >
          <div
            v-if="payTabInfo.activePayId == 0 || payTabInfo.activePayId == -1"
            class="money"
            layout="row"
            layout-align="start center"
          >
            <span>未结账金额:</span>
            <span class="amt">
              ¥{{
                turnOverInfo.activeTurnOverCount ==
                turnOverInfo.turnOverTabList.length - 1
                  ? (
                      $store.state.orderInfo.currentCardInfo.orderAmt -
                      $store.state.orderInfo.currentCardInfo.payedAmt
                    ).toFixed(2)
                  : "0.00"
              }}
            </span>
          </div>

          <div v-else layout="row" layout-align="start center">
            <div class="money" layout="row" layout-align="start center">
              <span>折前:</span>
              <span class="amt">
                ¥{{ payedData.payedOrderInfo.amts.o || "0.00" }}
              </span>
            </div>
            <div class="money" layout="row" layout-align="start center">
              <span>折后:</span>
              <span class="amt">
                ¥{{ payedData.payedOrderInfo.amts.pv || "0.00" }}
              </span>
            </div>
            <div class="money" layout="row" layout-align="start center">
              <span>本次实收:</span>
              <span class="amt">
                ¥{{ payedData.payedOrderInfo.amts.pzv || "0.00" }}
              </span>
            </div>
          </div>
        </div>
        <div
          v-if="$store.state.orderInfo.currentCardInfo.bizStatus != 1"
          class="order-content-bottom-right"
          :class="{
            'not-pay': payTabInfo.activePayId == 0,
            'pay-item':
              payTabInfo.activePayId != 0 && payTabInfo.activePayId != -1,
          }"
          layout="row"
          layout-align="end center"
        >
          <div
            class="button"
            v-if="payTabInfo.activePayId == 0"
            @click="openClockHandle"
            layout="row"
            layout-align="center center"
          >
            <img :src="require('@/assets/money-img/openClock.png')" />
            <span class="m-l-1">解锁</span>
          </div>
          <div
            class="button"
            :class="{ gray: hasChooseClockOrder }"
            v-if="payTabInfo.activePayId == 0"
            @click="togglePayType"
          >
            设为{{
              $store.state.orderInfo.currentCardInfo.settle_mode == 1
                ? "后"
                : "先"
            }}买单
          </div>
          <!-- 并台（转优惠2） -->
          <div
            class="button"
            :class="{ gray: hasChooseClockOrder }"
            v-if="payTabInfo.activePayId == 0"
            @click="mergeOrderToAnotherSeat"
          >
            转优惠2
          </div>
          <div
            class="button"
            :class="{ gray: hasChooseClockOrder }"
            v-if="payTabInfo.activePayId == 0"
            @click="updateToFirst"
          >
            立即出品
          </div>
          <div
            class="button change-pay-type"
            :class="{ gray: hasChooseClockOrder }"
            v-if="payTabInfo.activePayId == 0"
            @click="changePayType"
          >
            转为线下支付
          </div>
          <div
            class="button"
            v-if="payTabInfo.activePayId == 0"
            @click="sealPrdHandle(6)"
          >
            批量优惠
          </div>
          <div
            class="button"
            v-if="payTabInfo.activePayId == 0"
            @click="sealPrdHandle(7)"
          >
            批量优惠2
          </div>
          <div
            class="button"
            v-if="payTabInfo.activePayId == 0"
            @click="sealPrdHandle(8)"
          >
            批量退单
          </div>
          <div
            class="button pay"
            :class="{ gray: hasChooseClockOrder }"
            v-if="payTabInfo.activePayId == 0"
            @click="showOrHidePayDrawer"
          >
            收款
          </div>

          <div
            class="button"
            style="width: 160px"
            v-if="hasYh2Order && payTabInfo.activePayId == -1"
            @click="printYH2OrderList"
          >
            打印优惠2消费单
          </div>
          

          <!-- 如果是关联功能台和功能台 -->
          <div
            class="button"
            style="width: 150px"
            v-if="(this.$store.state.orderInfo.currentCardInfo.bizType == 3
                || this.$store.state.orderInfo.currentCardInfo.bizType == 4
                ) && payTabInfo.activePayId == -1"
            @click="showExportFormat = true"
          >
            导出数据
          </div>

          <div
            class="button"
            style="width: 150px"
            v-if="payTabInfo.activePayId == -1 && !isOldOrder"
            @click="showOrHidePrintDrawer(1)"
          >
            打印未结消费单
          </div>

          <div
            class="button"
            v-if="payTabInfo.activePayId != 0"
            @click="showOrHidePrintDrawer(2)"
          >
            {{ isOldOrder ? "补打" : "打印" }}消费单
          </div>

          <div
            class="button"
            v-if="payTabInfo.activePayId != 0"
            @click="printOrderPayedList"
          >
            {{ isOldOrder ? "补打" : "打印" }}结算单
          </div>
          <div
            class="button"
            v-if="
              payTabInfo.activePayId != 0 &&
              payTabInfo.activePayId != -1 &&
              !isOldOrder
            "
            @click="showOrHideBackDrawer"
          >
            退单
          </div>
          <div class="arrow" layout="row" layout-align="space-around center">
            <img
              class="arrow-top"
              @click.stop="scrollHandle('up')"
              :src="imgSrc.arrowBottom"
            />
            <img
              class="arrow-bottom"
              @click.stop="scrollHandle('down')"
              :src="imgSrc.arrowBottom"
            />
          </div>
        </div>
        <div
          v-if="
            $store.state.orderInfo.currentCardInfo.bizStatus == 1 &&
            $store.state.orderInfo.currentCardInfo.turnoverCnt > 0
          "
          class="order-content-bottom-right"
          :class="{
            'not-pay': payTabInfo.activePayId == 0,
            'pay-item':
              payTabInfo.activePayId != 0 && payTabInfo.activePayId != -1,
          }"
          layout="row"
          layout-align="end center"
        >
          <div
            class="button"
            v-if="payTabInfo.activePayId != 0"
            @click="showOrHidePrintDrawer(2)"
          >
            {{ isOldOrder ? "补打" : "打印" }}消费单
          </div>
          <div
            class="button"
            v-if="payTabInfo.activePayId != 0"
            @click="printOrderPayedList"
          >
            {{ isOldOrder ? "补打" : "打印" }}结算单
          </div>
        </div>
      </div>
    </div>

    <!-- 线上转线下、退单倒计时 -->
    <div class="num-sub-tips" v-show="showNumSubTips">
      <div class="contain">
        <i
          class="el-icon-close"
          style="
            position: absolute;
            top: 10px;
            right: 20px;
            color: #fff;
            cursor: pointer;
          "
          @click="hideTimeSubHandle()"
        ></i>
        {{ countSecond }}秒后将返回操作结果，请勿操作！
      </div>
    </div>

    <!-- 底部 -->
    <div class="bottom-nav" :style="isRect ? 'height: 60px' : 'height: 80px'">
      <footBar ref="footBar" :empId="empId" />
    </div>

    <!-- 收款drawer -->
    <drawerPayMoney
      ref="drawerPayMoney"
      :showDrawer="drawer.payDrawer.showDrawer"
      :choosePayOrderList="notPayData.choosePayOrderList"
      @showOrHideDrawer="showOrHidePayDrawer"
    />

    <!-- 退款drawer -->
    <drawerOrderBack
      ref="drawerOrderBack"
      :showDrawer="drawer.orderBackDrawer.showDrawer"
      :payedOrderList="payedData.payedOrderList"
      :orderId="payTabInfo.activePayId"
      @showOrHideDrawer="showOrHideBackDrawer"
      @updateBackOrderData="updateBackOrderData"
    />

    <!-- 并台 -->
    <fullPageTable
      titleText="转优惠2"
      @showOrHideFullPageHandle="showOrHideChooseCardDrawer"
      @setChoosedCardInfo="setChoosedCardInfo"
      v-if="chooseCardInfo.showDrawer"
    />

    <!-- 打印消费单 -->
    <drawerPrintOrder
      ref="drawerPrintOrder"
      :showDrawer="showPrintDrawer"
      :isNotPay="isPrintNotPay"
      :payId="payTabInfo.activePayId"
      :turnover_cnt="turnOverInfo.activeTurnOverCount"
      pageType="payOrder"
      @showOrHidePrintDrawer="showOrHidePrintDrawer"
    />

    <el-dialog title="选择导出格式" :visible.sync="showExportFormat" width="30%">
      <div >
          <el-radio v-model="exportType" label="1">汇总</el-radio>
          <el-radio v-model="exportType" label="2">非汇总</el-radio>
        </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="showExportFormat = false">取消</el-button>
        <el-button type="primary" @click="exportData">确定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import eventVue from "@/utils/eventVue";

import api_order from "@/api/order";
import api_money from "@/api/money";
import common_order from "@/utils/common/order";
import common_book from "@/utils/common/book";

import arrowBottom from "@/assets/card-imgs/new-arrow-bottom.png";

import notPayOrder from "@/components/money/notPayOrder";
import payedOrder from "@/components/money/payedOrder";
import drawerPayMoney from "@/components/money/drawerPayMoney";
import drawerOrderBack from "@/components/money/drawerOrderBack";
import footBar from "@/components/order/footBar";
import fullPageTable from "@/components/book/machine/fullPageTable"; // 转台
import drawerPrintOrder from "@/components/order/myOrder/drawerPrintOrder";

import navPrdList from "@/mixin/navPrdList";

const turnOverTabWidth = 166;
let turnOverTabList = []; //  页面加载完具有初始化顺序的翻台tab列表(用于排序高亮显示的tab放到第一个)
const payTabWidth = 137;
let timer = "";
// 键盘码 keycode
let downKeyCode = [0, 0];
const ctrlAndShiftCode = [17, 16];
export default {
  data() {
    return {
      isRect: window.innerWidth > 1024,
      empId: 0, // 订位人id
      flag: false, // 递归节流阀（用于请求到订单数据后更新结账前结账后数据）
      turnOverAmtInfo: [], // 已付款翻台记录的相关金额信息（用于展示在页面底部footer的金额）

      showNumSubTips: false, // 是否显示线上转线下倒计时
      countSecond: 10, // 线上转线下倒计时时间
      turnOverInfo: {
        turnOverTabList: [],
        activeTurnOverCount: 1,
        turnOverTabShow: false,
      },
      showPrintDrawer: false, // 是否显示打印消费单drawer
      payTabInfo: {
        // 当前卡台选中翻台后的结账次数详情tab
        payTabList: [],
        activePayId: 0,
        payTabShow: false,
      },
      // 当前卡台所有订单信息
      cardAllOrderInfo: [],
      // 未支付订单信息
      notPayData: {
        // 选择的即将要支付的订单信息
        choosePayOrderList: [],
        // 未支付订单，用于展示页面让用户选择要结账的商品
        notPayOrderList: [],
      },
      // 已支付订单信息
      payedData: {
        // allPayedOrderList: [], // 所有已支付订单信息集合
        payedOrderList: [], // 显示在已支付表格中的订单数据
        payedOrderInfo: {}, // 当前选中已支付订单所有数据
      },

      drawer: {
        payDrawer: {
          showDrawer: false,
        },
        orderBackDrawer: {
          showDrawer: false,
        },
      },

      // 是否显示选择并台（转优惠2）中的选择卡台
      chooseCardInfo: {
        showDrawer: false,
      },

      isPrintNotPay: false, // 是否打印为未结消费单

      imgSrc: {
        arrowBottom,
      },

      showExportFormat: false, // 选择导出数据格式
      exportType: '1', // 汇总
    };
  },
  methods: {
    init() {
      this.getTurnTabList();
      this.getOrderInfo(this.getPayTabList, false);

      // 解决空台状态（翻台后查看消费记录）tab补选中
      if (this.$store.state.orderInfo.currentCardInfo.bizStatus == 1) {
        setTimeout(() => {
          this.changeTab("order", this.payTabInfo.payTabList[0].id);
        }, 300);
      }
    },
    async exportData(){
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
        turnover_cnt: this.turnOverInfo.activeTurnOverCount, // int   第几次翻台,默认是0; 总翻台次数可以从业务原数据中获取
        type_id: this.exportType * 1        //TypeId 导出类型 1 汇总 2 不汇总
      }

      try {
        const res = await api_money.reqExpSpSeatRptList(params);
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
          this.showExportFormat = false
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("导出excel失败", error);
      }

    },
    // 获取翻台tab数据
    getTurnTabList() {
      let turnoverCnt = 0;
      if (this.$store.state.orderInfo.currentCardInfo.bizStatus == 1) {
        // 已清台，查看消费(空台)
        turnoverCnt =
          this.$store.state.orderInfo.currentCardInfo.turnoverCnt * 1 - 1;
      } else {
        // 已开台
        turnoverCnt =
          this.$store.state.orderInfo.currentCardInfo.turnoverCnt * 1;
      }

      const tabList = [];
      for (let i = turnoverCnt + 1; i > 0; i--) {
        tabList.push({
          id: i - 1,
          name:
            this.$store.state.orderInfo.currentCardInfo.name +
            "-" +
            i.toString().padStart(3, 0),
        });
      }
      this.turnOverInfo.turnOverTabList = tabList;
      this.turnOverInfo.activeTurnOverCount = turnoverCnt;
      // 存储初始化tab数据
      turnOverTabList = JSON.parse(JSON.stringify(tabList));
      this.$nextTick(() => {
        this.sortTurnOverTab();
      });
    },

    // 排序（高亮显示的放在第一个）
    sortTurnOverTab(id = this.turnOverInfo.activeTurnOverCount) {
      setTimeout(() => {
        const turnOverTabDom = this.$refs.turnOverTabRef;
        const offsetWidth = turnOverTabDom.offsetWidth - 16; // 16的padding
        const maxCountOfOneLine = Math.floor(offsetWidth / turnOverTabWidth);
        if (turnOverTabList.length > maxCountOfOneLine) {
          const index = turnOverTabList.findIndex((item) => item.id === id);
          const resultTurnOverTabList = JSON.parse(
            JSON.stringify(turnOverTabList)
          );
          resultTurnOverTabList.unshift(
            ...resultTurnOverTabList.splice(index, 1)
          );

          resultTurnOverTabList.splice(maxCountOfOneLine - 1, 0, {
            id: -2,
            name: "其它",
          });

          this.turnOverInfo.turnOverTabList = resultTurnOverTabList;
        }
      }, 200);
    },

    // 获取支付tab数据(同时附带获取全部消费数据)
    getPayTabList() {
      const payTabList = [];
      const hasPayed = this.cardAllOrderInfo.length > 1;
      const allOrderInfo = {
        // 全部消费数据
        list: [],
        pid: "-1",
        ps: [],
      };

      const notPayOrderInfo = { list: [], ps: [] }; // 用于全部订单中的排序
      const payedOrderInfo = { list: [], ps: [] }; // 用于全部订单中的排序

      // 判断是否为翻台后的空台状态进来查看详情
      const payTabCount =
        this.$store.state.orderInfo.currentCardInfo.bizStatus == 1
          ? this.turnOverInfo.turnOverTabList.length
          : this.turnOverInfo.turnOverTabList.length - 1;

      this.cardAllOrderInfo.forEach((el, i) => {
        if (
          !(this.turnOverInfo.activeTurnOverCount < payTabCount && el.pid == 0)
        ) {
          payTabList.push({
            name: el.pid == 0 ? "未结账" : `第${i}次结账`,
            id: el.pid,
          });
        }

        if (el.list.length > 0) {
          if (el.pid != 0) {
            // 已支付订单，给已支付订单打上标记
            el.list.forEach((ele) => {
              ele.payed = true; // 用于全部订单中打乱已支付未支付订单，在已支付订单前加上结账的标签
            });
            payedOrderInfo.list.unshift(...el.list);
            if (el.ps) payedOrderInfo.ps.unshift(...el.ps);
          } else {
            // 未支付订单
            notPayOrderInfo.list.unshift(...el.list);
            if (el.ps) notPayOrderInfo.ps.unshift(...el.ps);
          }
        }
      });
      allOrderInfo.list = [...notPayOrderInfo.list, ...payedOrderInfo.list];
      allOrderInfo.ps = [...notPayOrderInfo.ps, ...payedOrderInfo.ps];

      // 拼接全部结账数据
      // if (hasPayed) {
      payTabList.unshift({
        name: `全部消费`,
        id: "-1",
      });
      this.cardAllOrderInfo.push(allOrderInfo);
      // }

      const payedTabList = payTabList.filter((item) => item.id != 0);
      const notPayTabList = payTabList.filter((item) => item.id == 0);
      this.payTabInfo.payTabList = [
        ...notPayTabList,
        ...payedTabList.reverse(),
      ];

      setTimeout(() => {
        const payTableRef = this.$refs.payTableRef;
        const offsetWidth = payTableRef.offsetWidth - 32; // padding占据32px
        const maxCountOfOneLine = Math.floor(offsetWidth / payTabWidth);

        if (this.payTabInfo.payTabList.length > maxCountOfOneLine) {
          // 换行
          this.payTabInfo.payTabList.splice(maxCountOfOneLine - 1, 0, {
            name: `其它`,
            id: "-2",
          });
        }
      }, 200);
    },

    // 获取订单相关数据
    async getOrderInfo(callback, backToCardList) {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
        turnover_cnt: this.turnOverInfo.activeTurnOverCount, // int   第几次翻台,默认是0; 总翻台次数可以从业务原数据中获取
      };
      try {
        const res = await api_money.reqGetCardPayInfo(params);
        if (res.code === 1) {
          // 获取翻台记录
          // 最左边的记录，如果是清台状态，和翻台一样处理
          if (
            this.turnOverInfo.turnOverTabList.length !=
              this.turnOverInfo.activeTurnOverCount + 1 ||
            this.$store.state.orderInfo.currentCardInfo.bizStatus != 4
          ) {
            this.$refs.footBar.cardInfo = {
              ...this.$refs.footBar.cardInfo,
              chgSeatInfo: res.data.chgSeatInfo,
            };
          }

          this.flag = true;
          this.empId = res.data.sales_emp_id || 0;
          // 存储当前卡台的翻台记录金额，即已付款翻台记录的相关金额信息（用于展示在页面底部footer的金额）
          this.turnOverAmtInfo = (res.data.payed_order || []).map((item) => ({
            id: item.id,
            amts: item.amts || {},
          }));

          if (res.data.unpay_order) {
            // 包含未支付订单信息（其中包含线上和线下未支付订单）
            // 线上未结账订单
            let onlineNotPayOrderList = res.data.unpay_order.oos
              ? [...res.data.unpay_order.oos]
              : [];
            onlineNotPayOrderList.forEach((el) => {
              el.os.forEach((ele) => {
                el.orderTime = ele.ot.replace(":", "");
                el.orderTime = el.orderTime.replace(" ", "");
                ele.productInfo = common_order.getProductInfo(ele.pid);
                ele.personInfo =
                  ele.wei == 0
                    ? { name: "自助" }
                    : common_book.getOrderPersonInfo(ele.wei);
                ele.authInfo =
                  ele.ae == 0 ? {} : common_book.getOrderPersonInfo(ele.ae);
                ele.showList = false;
                // 优惠2订位人信息
                ele.Yh2SalesInfo =
                  ele.y2e == 0 ? {} : common_book.getOrderPersonInfo(ele.y2e);
                // 优惠2卡台信息
                ele.Yh2SeatInfo =
                  ele.y2s == 0 ? {} : common_book.getCardInfo(ele.y2s);
                if (ele.is == 1)
                  ele.si.forEach((element) => {
                    element.groupInfo = common_order.getProductInfoFromGroup(
                      element.dpi
                    );
                  });
              });
            });

            onlineNotPayOrderList = onlineNotPayOrderList.sort(
              (a, b) => b.orderTime * 1 - a.orderTime * 1
            );

            // 线下未结账订单
            let anotherNotPayOrderList = res.data.unpay_order.os
              ? [...res.data.unpay_order.os]
              : [];
            anotherNotPayOrderList.forEach((el) => {
              el.orderTime = el.ot.replace(":", "");
              el.orderTime = el.orderTime.replace(" ", "");
              el.productInfo = common_order.getProductInfo(el.pid);
              // 服务员
              el.personInfo =
                el.wei == 0
                  ? { name: "自助" }
                  : common_book.getOrderPersonInfo(el.wei);
              // 赠送人
              el.authInfo =
                el.ae == 0 ? {} : common_book.getOrderPersonInfo(el.ae);
              el.showList = false;
              // 优惠2订位人信息
              el.Yh2SalesInfo =
                el.y2e == 0 ? {} : common_book.getOrderPersonInfo(el.y2e);
              // 优惠2卡台信息
              el.Yh2SeatInfo =
                el.y2s == 0 ? {} : common_book.getCardInfo(el.y2s);
              if (el.is == 1)
                el.si.forEach((ele) => {
                  ele.groupInfo = common_order.getProductInfoFromGroup(ele.dpi);
                });
            });

            anotherNotPayOrderList = anotherNotPayOrderList.sort(
              (a, b) => b.orderTime * 1 - a.orderTime * 1
            );

            // 处理未支付订单数据
            this.getOrderDetailInfo(res, [
              ...anotherNotPayOrderList,
              ...onlineNotPayOrderList,
            ]);
          }

          const payedOrderList = [];

          if (res.data.payed_order) {
            // 已付款
            res.data.payed_order.forEach((el) => {
              let onlinePayedOrderList = el.oos || []; // 线上支付订单
              let anotherPayedOrderList = el.os || []; // 线下支付订单

              onlinePayedOrderList.forEach((ele) => {
                ele.os &&
                  ele.os.forEach((elem) => {
                    elem.orderTime = elem.ot.replace(":", "");
                    elem.orderTime = elem.orderTime.replace(" ", "");
                    elem.productInfo = common_order.getProductInfo(elem.pid);
                    elem.isOnlinePay = true;
                    elem.payed = true;
                    elem.personInfo =
                      elem.wei == 0
                        ? { name: "自助" }
                        : common_book.getOrderPersonInfo(elem.wei);
                    elem.authInfo =
                      elem.ae == 0
                        ? {}
                        : common_book.getOrderPersonInfo(elem.ae);
                    elem.showList = false;
                    // 优惠2订位人信息
                    elem.Yh2SalesInfo =
                      elem.y2e == 0
                        ? {}
                        : common_book.getOrderPersonInfo(elem.y2e);
                    // 优惠2卡台信息
                    elem.Yh2SeatInfo =
                      elem.y2s == 0 ? {} : common_book.getCardInfo(elem.y2s);
                    if (elem.is == 1 && elem.si)
                      // 获取套餐明细详情
                      elem.si.forEach((element) => {
                        element.groupInfo =
                          common_order.getProductInfoFromGroup(element.dpi);
                      });
                  });
              });
              onlinePayedOrderList = onlinePayedOrderList.sort(
                (a, b) => b.orderTime * 1 - a.orderTime * 1
              );

              anotherPayedOrderList.forEach((ele) => {
                ele.orderTime = ele.ot.replace(":", "");
                ele.orderTime = ele.orderTime.replace(" ", "");
                ele.productInfo = common_order.getProductInfo(ele.pid);
                ele.personInfo =
                  ele.wei == 0
                    ? { name: "自助" }
                    : common_book.getOrderPersonInfo(ele.wei);
                ele.authInfo =
                  ele.ae == 0 ? {} : common_book.getOrderPersonInfo(ele.ae);
                ele.showList = false;
                // 优惠2订位人信息
                ele.Yh2SalesInfo =
                  ele.y2e == 0 ? {} : common_book.getOrderPersonInfo(ele.y2e);
                // 优惠2卡台信息
                ele.Yh2SeatInfo =
                  ele.y2s == 0 ? {} : common_book.getCardInfo(ele.y2s);
                if (ele.is == 1 && ele.si)
                  // 获取套餐明细详情
                  ele.si.forEach((element) => {
                    element.groupInfo = common_order.getProductInfoFromGroup(
                      element.dpi
                    );
                  });
              });

              anotherPayedOrderList = anotherPayedOrderList.sort(
                (a, b) => b.orderTime * 1 - a.orderTime * 1
              );
              payedOrderList.push({
                pid: el.id,
                list: [...anotherPayedOrderList, ...onlinePayedOrderList],
                ps: el.ps.map(item => { return {...item, pt: el.pt} }), // 支付渠道
                amts: el.amts || {},
              });
            });
          }

          this.cardAllOrderInfo = [
            {
              pid: 0,
              list: JSON.parse(JSON.stringify(this.notPayData.notPayOrderList)),
            },
            ...payedOrderList,
          ];

          callback && callback();
          if (backToCardList) {
            if (res.data.unpay_order) {
              let onlineNotPayOrderList = res.data.unpay_order.oos
                ? [...res.data.unpay_order.oos]
                : [];
              let anotherNotPayOrderList = res.data.unpay_order.os
                ? [...res.data.unpay_order.os]
                : [];
              if (
                onlineNotPayOrderList.length == 0 &&
                anotherNotPayOrderList.length == 0
              ) {
                this.$router.replace("/moneyCard");
              }
            }
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取对应卡台的指定翻台的订单和支付信息失败", error);
      }
    },
    // 获取未付款订单列表
    /**
     * @params{
     * res:后台请求的数据，用于获取订单支付次数tab，有此参数代表第一次获取（即处理未支付订单），无此参数代表获取已支付订单
     * orderInfoList:支付订单信息列表
     * }
     */
    getOrderDetailInfo(res, orderInfoList) {
      // 未付款订单处理退单数据
      let resultNotPayData = [];
      if (orderInfoList && orderInfoList.length > 0) {
        orderInfoList.forEach((el) => {
          if (el.oid) {
            // 线上订单
            el.os = el.os || [];
            el.resultNotPayData = []; // 当前订单打包的子项商品信息列表
            el.os.forEach((ele) => {
              if (ele.bs) {
                // 有退单
                ele.bs.forEach((element) => {
                  element.back = true;
                  element.parentOrderId = ele.id;
                  for (let key in ele) {
                    if (key != "bs")
                      // ele[key] = ele[key] && key != "si" ? ele[key] : el[key];
                      element[key] = element[key] ? element[key] : ele[key];
                    if (key == "si" && element[key]) {
                      element.si.forEach((elements) => {
                        elements.groupInfo =
                          common_order.getProductInfoFromGroup(elements.dpi);
                      });
                    }
                  }
                });

                if (ele.pc != 0) {
                  // 部分退单
                  el.resultNotPayData.push(ele);
                }
                el.resultNotPayData.push(...ele.bs);
              } else {
                el.resultNotPayData.push(ele);
              }
            });

            resultNotPayData.push(el);
          } else {
            // 线下订单
            if (el.bs) {
              // 有退单
              el.bs.forEach((ele) => {
                ele.back = true;
                ele.parentOrderId = el.id;
                for (let key in el) {
                  if (key != "bs")
                    // ele[key] = ele[key] && key != "si" ? ele[key] : el[key];
                    ele[key] = ele[key] ? ele[key] : el[key];
                  if (key == "si" && ele[key]) {
                    ele.si.forEach((element) => {
                      element.groupInfo = common_order.getProductInfoFromGroup(
                        element.dpi
                      );
                    });
                  }
                }
              });

              if (el.pc != 0 && el.bs) {
                // 部分退单
                resultNotPayData.push(el);
              }

              resultNotPayData.push(...el.bs);
            } else {
              resultNotPayData.push(el);
            }
          }
        });
      }

      // 线下未结账商品部分退单 或 结账商品部分退单(未退单商品会变成未结账商品，退单变成未结账退单状态)，这种情况下会导致在全部商品中部分退单中的退单商品重复，此处做去重处理
      // resultNotPayData = resultNotPayData.filter((item, index, arr) => arr.findIndex(items => items.id == item.id && items.pid == item.pid) == index)

      // 结账订单数量
      resultNotPayData.forEach((el) => {
        // 线上全部退单的商品组默认勾选，未全部退单的商品默认不勾选
        el.checkout =
          !el.oid || (el.oid && el.resultNotPayData.every((item) => item.back));
        // 线下订单  线上订单不允许修改数量
        if (!el.oid) el.changeCount = el.pc;
      });
      if (res) {
        this.notPayData.notPayOrderList = resultNotPayData;
        this.notPayData.choosePayOrderList = resultNotPayData.filter(
          (item) => item.checkout
        );
        this.$forceUpdate();
      } else {
        this.payedData.payedOrderList = resultNotPayData;
      }
      setTimeout(() => {
        if (this.flag) this.getPayedOrderInfo(this.payTabInfo.activePayId);
      }, 500);
      // console.log("notPayOrderList", this.notPayData.notPayOrderList);
      // console.log("payedOrderList", this.payedData.payedOrderList);
    },

    // 获取已支付订单次数及相关详情列表
    getPayedOrderInfo(payedId) {
      if (payedId == 0) {
        // 未结账订单(同步为结账订单勾选和订单列表同步)
        this.notPayData.choosePayOrderList =
          this.notPayData.notPayOrderList.filter((item) => item.checkout);
      }
      const payedInfo = this.cardAllOrderInfo.find(
        (item) => item.pid == payedId
      );
      // payedId == -1 ==> 全部订单
      this.payedData.payedOrderInfo = payedInfo;
      this.getOrderDetailInfo(null, payedInfo.list);
      this.flag = false;
    },

    // 筛选翻台/订单信息订单
    async changeTab(type, id, isReset = true) {
      console.log(type, id)
      switch (type) {
        case "turnOverCount": // 点击翻台tab
          if (id == -2) {
            return (this.turnOverInfo.turnOverTabShow =
              !this.turnOverInfo.turnOverTabShow);
          }
          this.turnOverInfo.activeTurnOverCount = id;
          this.turnOverInfo.turnOverTabShow = false;
          this.$refs.footBar.cardInfo = {
            ...this.$store.state.orderInfo.currentCardInfo,
          };
          await this.getOrderInfo(this.getPayTabList);
          this.sortTurnOverTab();
          const turnOverId = this.payTabInfo.payTabList[0].id;
          this.payTabInfo.activePayId = turnOverId;
          this.getPayedOrderInfo(turnOverId);
          break;
        case "order": // 点击结账tab
          if (id == -2) {
            // 点击的显示隐藏
            return (this.payTabInfo.payTabShow = !this.payTabInfo.payTabShow);
          }
          this.payTabInfo.activePayId = id;
          if (isReset) this.payTabInfo.payTabShow = false;
          this.getPayedOrderInfo(id);
          break;
      }
    },

    // 获取退单后页面表格相关数据（退单结束后操作）
    async updateBackOrderData() {
      await this.getOrderInfo(this.getPayTabList);
      this.changeTab("order", 0);
    },

    // 打印优惠2消费单
    async printYH2OrderList() {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64 卡台Id
        pay_id: 0, //  int64  指定某次结算的优惠2消费单, =0 表示打印这个卡台全部优惠2消费
      };
      try {
        const res = await api_money.reqPrintYH2Order(params);
        res.code === 1
          ? this.$message.success("打印成功")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("手工打印优惠2消费单失败", error);
      }
    },

    // 打印消费单
    showOrHidePrintDrawer(type) {
      if (type && !this.showPrintDrawer) this.isPrintNotPay = type == 1;
      this.showPrintDrawer = !this.showPrintDrawer;
    },

    // 打印结算单
    async printOrderPayedList() {
      const hasNotPayOrder = this.cardAllOrderInfo[0].list.length > 0;
      if (hasNotPayOrder && this.payTabInfo.activePayId == -1)
        return this.$message.warning("存在未结账订单，不可打印结算单");
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64  卡台Id
        pay_id: this.payTabInfo.activePayId == -1 ? 0 : this.payTabInfo.activePayId,
        turnover_cnt: this.turnOverInfo.activeTurnOverCount,
      };
      try {
        const res = await api_money.reqPrintResultOrder(params);
        res.code === 1
          ? this.$message.success("打印成功")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("打印失败", error);
      }
    },

    // 箭头滚动
    scrollHandle(type) {
      const scrollDom = this.$children.find(
        (item) => item.$refs && item.$refs.scrollDom
      );
      const resultDom = scrollDom ? scrollDom.$refs.scrollDom : "";
      const resultDomItem = scrollDom ? scrollDom.$refs.scrollItem : "";
      if (!resultDom || !resultDomItem) return;
      const clientHeight = resultDom.getBoundingClientRect().height;
      const maxHeight = resultDomItem.getBoundingClientRect().height;
      if (clientHeight >= maxHeight) return; // 未能撑满可视区域，无需滚动
      let scrollTop = resultDom.scrollTop;
      switch (type) {
        case "up":
          scrollTop = Math.min(maxHeight, scrollTop - 200);
          resultDom.scrollTo(0, scrollTop);
          break;
        case "down":
          scrollTop = Math.max(0, scrollTop + 200);
          resultDom.scrollTo(0, scrollTop);
          break;
      }
    },

    // 解锁订单
    async openClockHandle() {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64   卡台Id
      };

      try {
        const res = await api_money.reqCancelClockOrder(params);
        if (res.code == 1) {
          this.$message.success("解锁成功");
          this.init();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("收银员解锁订单失败", error);
      }
    },

    // 切换先后买单方式
    async togglePayType() {
      if (this.hasChooseClockOrder)
        return this.$message.warning("所选订单存在锁定订单，不可操作");
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //   int64   待操作卡台Id
        settle_mode:
          this.$store.state.orderInfo.currentCardInfo.settle_mode * 1 == 1
            ? 2
            : 1, // int  1 先买单 2 后买单
      };
      try {
        const res = await api_money.reqTogglePayType(params);
        if (res.code == 1) {
          this.$message.success("设置成功");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("切换先后买单失败", error);
      }
    },

    // 并台（转优惠2）
    mergeOrderToAnotherSeat() {
      if (this.hasChooseClockOrder)
        return this.$message.warning("所选订单存在锁定订单，不可操作");
      const checkedOrderList = this.notPayData.choosePayOrderList.filter(
        (item) => item.checkout && !item.back && !item.oid
      );
      if (checkedOrderList.length === 0)
        return this.$message.warning("请选择要操作的优惠2订单");
      const isYh2 = checkedOrderList.every((item) => item.at == 3);
      if (!isYh2)
        return this.$message.warning("只允许优惠2订单进行转优惠2操作！");
      this.showOrHideChooseCardDrawer();
    },

    // 显示或隐藏并台（转优惠2）选择卡台
    showOrHideChooseCardDrawer() {
      this.chooseCardInfo.showDrawer = !this.chooseCardInfo.showDrawer;
    },

    // 获取选取的并台（转优惠2）卡台
    setChoosedCardInfo(cardInfo) {
      this.submitMergeOrder(cardInfo);
    },

    // 提交并台（转优惠2）数据
    async submitMergeOrder(cardInfo) {
      const checkedOrderList = this.notPayData.choosePayOrderList.filter(
        (item) => item.checkout && !item.back
      );
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64   待操作卡台Id
        order_ids: checkedOrderList.map((item) => item.id * 1), //  []int64    待操作订单列表
        dest_seat_id: cardInfo.seatId * 1, // int64    目标卡台Id
      };
      try {
        const res = await api_money.reqMergeYh2Order(params);
        if (res.code == 1) {
          this.$message.success("转优惠2成功");
          this.showOrHideChooseCardDrawer();
          this.getOrderInfo();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("转优惠2失败", error);
      }
    },

    // 立即出品
    updateToFirst() {
      if (this.hasChooseClockOrder)
        return this.$message.warning("所选订单存在锁定订单，不可操作");
      const checkedOrderList = this.notPayData.choosePayOrderList.filter(
        (item) => item.checkout && !item.back
      );

      if (checkedOrderList.length === 0)
        return this.$message.warning("请选择要操作的线上订单");

      const isOnlineOrder = checkedOrderList.every((item) => item.oid);
      if (!isOnlineOrder)
        return this.$message.warning("只允许线上订单进行设为先出品操作！");

      this.showConfirmHandle(
        "确认",
        "是否确认将所选的订单设为先出品？",
        async () => {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            ids: checkedOrderList.map((item) => item.oid * 1), //        []int64    线上支付订单Id列表
          };

          try {
            const res = await api_money.reqOnlineOrderToFirst(params);
            if (res.code == 1) {
              this.$message.success("操作成功");
              this.getOrderInfo(this.getPayTabList);
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("立即出品失败", error);
          }
        }
      );
    },

    // 更改线上支付为线下支付
    changePayType() {
      if (this.hasChooseClockOrder)
        return this.$message.warning("所选订单存在锁定订单，不可操作");
      const checkedOrderList = this.notPayData.choosePayOrderList.filter(
        (item) => item.checkout && !item.back
      );
      if (checkedOrderList.length === 0)
        return this.$message.warning("请选择要操作的线上订单");

      const isOnlineOrder = checkedOrderList.every((item) => !!item.oid);
      // 判断是否为线上订单
      if (!isOnlineOrder)
        return this.$message.warning("只允许线上支付的订单进行更改支付操作！");

      this.showConfirmHandle(
        "确认",
        `是否确认将所选的订单设为线下支付？`,
        () => {
          this.setLocalOrder(checkedOrderList);
        }
      );
    },

    // 正常将线上订单转为线下订单
    async setLocalOrder(checkedOrderList) {
      const loading = this.$loading({
        lock: true,
        text: "Loading",
        spinner: "el-icon-loading",
        background: "rgba(0, 0, 0, 0.7)",
      });
      try {
        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
          ids: checkedOrderList.map((item) => item.oid * 1), //   []int64    线上支付订单Id列表
        };
        const res = await api_money.reqOnlineOrderToOrgOrder(params);
        if (res.code == 1) {
          await this.getOrderInfo(this.getPayTabList);
        } else if (res.code == 2) {
          // 部分线上订单已支付
          // 强制转为线下订单
          this.forceSetLocalOrder(checkedOrderList, res.data || {});
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("线上转线下失败", error);
      }
      loading.close();
    },

    // 强制将线上订单转为线下订单（将线上部分付款订单,转为线下预留金）
    forceSetLocalOrder(checkedOrderList, orderInfo) {
      this.showConfirmHandle(
        "确认",
        `部分线上订单处于待支付中，强制转为线下支付，线上付款将会进入到滞留金，请确认是否转为线下支付？`,
        async () => {
          const loading = this.$loading({
            lock: true,
            text: "Loading",
            spinner: "el-icon-loading",
            background: "rgba(0, 0, 0, 0.7)",
          });
          try {
            const params = {
              seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
              ol_pay_ids: checkedOrderList.map((item) => item.oid * 1), // []int64    线上支付订单Id列表
              ol_pay_dtl_cnt: orderInfo.ol_pay_dtl_cnt, // int     线上支付子订单数量
              wkday_id: orderInfo.wkday_id, //   int64    营业日Id,云端仅记录
              csm_id: orderInfo.csm_id, //     int64   流水Id,云端仅记录
            };
            const res = await api_money.reqOnlineOrderForceToOrgOrder(params);
            if (res.code == 1) {
              this.setLocalOrder(checkedOrderList);
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("强制线上转线下失败", error);
          }
          loading.close();
        }
      );
    },

    // 批量优惠/批量优惠2/退单
    sealPrdHandle(type) {
      // type: 6：优惠  7：优惠2  8：批量退单
      this.$refs.notPayOrder && this.$refs.notPayOrder.showOrHideDrawer(type);
    },

    // 更新选择的未结账订单信息
    updatePayOrderList(orderList) {
      this.notPayData.choosePayOrderList = JSON.parse(
        JSON.stringify(orderList)
      );
    },

    // 支付金额为0的时候支付
    async payOrder0(wk_order_ids, prd_cnts, allAmt) {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64     卡台Id
        wk_order_ids, // []int64    待结账订单Id组
        prd_cnts, // []int  对应待结算订单的商品数量
        total_amt: allAmt.toString(), //  string   总待结算金额(当前勾选的商品总金额),做二次验证用
      };
      try {
        const res = await api_money.reqPayOrder(params);
        if (res.code === 1) {
          this.$message.success("支付成功");
          this.$router.replace("/moneyCard");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("支付失败", error);
      }
    },

    // 显示或隐藏付款drawer
    async showOrHidePayDrawer() {
      if (this.hasChooseClockOrder)
        return this.$message.warning("所选订单存在锁定订单，不可操作");
      if (
        !this.drawer.payDrawer.showDrawer &&
        this.notPayData.choosePayOrderList.length <= 0
      )
        return this.$message.warning("请选择需要结账的商品");

      //判断所选择订单是否有线上支付的订单
      const hasOnlinePayOrder = this.notPayData.choosePayOrderList.some(
        (item) =>
          item.oid &&
          item.resultNotPayData &&
          item.resultNotPayData.some((items) => !items.back)
      );

      if (!this.drawer.payDrawer.showDrawer && hasOnlinePayOrder) {
        if (this.drawer.payDrawer.showDrawer) this.$router.go(0);
        this.drawer.payDrawer.showDrawer = !this.drawer.payDrawer.showDrawer;

        return this.$message.warning("所选订单包含线上支付订单");
      }

      // 判断是否支付金额为0
      let amt = 0;
      const wk_order_ids = [];
      const prd_cnts = [];
      this.notPayData.choosePayOrderList.forEach((el) => {
        if (el.back) {
          if (wk_order_ids.indexOf(el.parentOrderId * 1) == -1) {
            wk_order_ids.push(el.parentOrderId * 1);
            prd_cnts.push(0);
          }
        } else {
          wk_order_ids.push(el.id * 1);
          prd_cnts.push(el.changeCount * 1);
        }
        el.back || el.at == 2 || el.at == 3
          ? (amt += 0)
          : (amt += el.pp * 1 == 0 ? el.pa * 1 : el.changeCount * el.pp);
      });

      if (amt == 0) {
        if (wk_order_ids.length > 0) {
          return this.payOrder0(wk_order_ids, prd_cnts, amt);
        }
      }

      wk_order_ids.length = 0;
      prd_cnts.length = 0;
      amt = 0;
      this.notPayData.choosePayOrderList.forEach((el) => {
        if (el.back) {
          if (wk_order_ids.indexOf(el.parentOrderId * 1) == -1) {
            wk_order_ids.push(el.parentOrderId * 1);
            prd_cnts.push(0);
          }
        } else {
          wk_order_ids.push(el.id * 1);
          prd_cnts.push(el.changeCount * 1);
        }
        el.back || el.at == 2 || el.at == 3
          ? (amt += 0)
          : (amt += el.pp * 1 == 0 ? el.pa * 1 : el.changeCount * el.pp);
      });
      if (!this.drawer.payDrawer.showDrawer) {
        //  结账之前,清理收银结账渠道购物车,并确认本次待结账订单
        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //  int64   卡台Id
          wk_order_ids, // []int64    待结账订单Id组
          prd_cnts, //  []int  对应待结算订单的商品数量, 时价特饮(3),时价小费(4),赔偿(5)不允许拆分数量,其他都可以拆分数量结账
          total_amt: amt.toFixed(2), //   //TotalAmt 总待结算金额,做二次验证用
        };
        console.log(params);
        const res = await api_money.reqConfirmBillInfo(params);
        if (res.code != 1) {
          return this.$message.warning(res.msg);
        }
      }

      // if (this.drawer.payDrawer.showDrawer) this.$router.go(0);
      this.drawer.payDrawer.showDrawer = !this.drawer.payDrawer.showDrawer;
    },

    // 显示或隐藏退款drawer
    showOrHideBackDrawer() {
      this.drawer.orderBackDrawer.showDrawer =
        !this.drawer.orderBackDrawer.showDrawer;
    },

    // 确认框
    showConfirmHandle(title = "", content = "", callback) {
      this.$confirm(content, title, {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      })
        .then(() => {
          callback && callback();
        })
        .catch((e) => "");
    },

    keyHandle(e) {
      // console.log(e, e.keyCode, downKeyCode)
      // alt 或 windows键(防止利用alt切屏)
      if (e.keyCode == 18 || e.keyCode == 91) return e.preventDefault();
      switch (e.type) {
        case "keydown":
          if (downKeyCode.findIndex((item) => item == 0) < 0) return;

          if (ctrlAndShiftCode.includes(e.keyCode)) {
            downKeyCode[0] = e.keyCode;
          } else if (downKeyCode[0] == 0 && downKeyCode[1] == 0) {
            downKeyCode[1] = e.keyCode;
          } else if (downKeyCode[0] == e.keyCode && downKeyCode[1] == 0) {
            // 重复按同一个件
          } else if (downKeyCode[0] != 0 && downKeyCode[1] == 0) {
            downKeyCode[1] = e.keyCode;
          }

          this.$nextTick(() => {
            if (downKeyCode[0] == 0 && downKeyCode[1] == 27) {
              //  ctrl + q  // 返回首页
              e.preventDefault();
              this.$router.replace({ name: "moneyCard" });
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 65) {
              // ctrl + a  // 订单全选
              e.preventDefault();
              if (this.payTabInfo.activePayId == 0) {
                // 未付款订单
                this.$refs.notPayOrder.checkoutAll =
                  !this.$refs.notPayOrder.checkoutAll;
                this.$refs.notPayOrder.chooseOrder(
                  {
                    target: {
                      checked: this.$refs.notPayOrder.checkoutAll,
                    },
                  },
                  "",
                  "all"
                );
              }
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 90) {
              // ctrl + z  // 选中所有优惠2订单
              e.preventDefault();
              if (this.payTabInfo.activePayId == 0) {
                // 未付款订单
                this.$refs.notPayOrder.checkedOrder("YH2");
              }
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 88) {
              // ctrl + x  // 选中所有线上支付订单
              e.preventDefault();
              if (this.payTabInfo.activePayId == 0) {
                // 未付款订单
                this.$refs.notPayOrder.checkedOrder("line");
              }
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 67) {
              // ctrl + c  // 选中所有线下支付订单
              e.preventDefault();
              if (this.payTabInfo.activePayId == 0) {
                // 未付款订单
                this.$refs.notPayOrder.checkedOrder("offLine");
              }
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 83) {
              // ctrl + s  // 立即出品
              e.preventDefault();
              if (this.payTabInfo.activePayId == 0) {
                // 未付款订单
                this.updateToFirst();
              }
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 68) {
              // ctrl + d  // 转为线下支付
              e.preventDefault();
              if (this.payTabInfo.activePayId == 0) {
                // 未付款订单
                this.changePayType();
              }
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 70) {
              // ctrl + f  // 并台（转优惠2）
              e.preventDefault();
              if (this.payTabInfo.activePayId == 0) {
                // 未付款订单
                this.mergeOrderToAnotherSeat();
              }
            } else if (downKeyCode[0] == 16 && downKeyCode[1] == 65) {
              // shift + a  // 点单
              e.preventDefault();
              this.$router.push({ name: "orderMealList" });
            } else if (downKeyCode[0] == 16 && downKeyCode[1] == 83) {
              // shift + s  // 优惠2
              e.preventDefault();
              this.$router.push({
                name: "orderMealList",
                query: { give: true },
              });
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 13) {
              // enter
              e.preventDefault();
              if (
                this.payTabInfo.activePayId == 0 &&
                this.$refs.notPayOrder.drawer.showDrawer
              ) {
                // 未支付订单套餐更改明细
                this.$refs.notPayOrder.$refs.drawerMyOrder &&
                  this.$refs.notPayOrder.$refs.drawerMyOrder.onSubmit();
              } else if (
                this.payTabInfo.activePayId > 0 &&
                this.$refs.payedOrder.showUpdateDetailDrawer
              ) {
                // 已支付订单套餐更改明细
                this.$refs.payedOrder.$refs.drawerMyOrder &&
                  this.$refs.payedOrder.$refs.drawerMyOrder.onSubmit();
              } else if (
                this.payTabInfo.activePayId == 0 &&
                !this.drawer.payDrawer.showDrawer
              ) {
                // 未付款订单收款列表
                this.showOrHidePayDrawer();
              } else if (
                this.payTabInfo.activePayId == 0 &&
                this.drawer.payDrawer.showDrawer &&
                !this.$refs.drawerPayMoney.showAuthDrawer
              ) {
                // 未付款订单确认收款
                this.$refs.drawerPayMoney.onSubmit();
              } else if (
                this.payTabInfo.activePayId == 0 &&
                this.$refs.drawerPayMoney.showAuthDrawer
              ) {
                // 确认添加支付渠道授权
                this.$refs.drawerPayMoney.$refs.authComponent.onSubmit();
              } else if (
                this.payTabInfo.activePayId != 0 &&
                this.$refs.payedOrder.showDrawer
              ) {
                // 修改支付渠道
                if (
                  this.$refs.payedOrder.$refs.drawerUpdatePayedType
                    .showAuthDrawer
                ) {
                  // 添加授权支付渠道授权授权账号密码
                  this.$refs.payedOrder.$refs.drawerUpdatePayedType.$refs.drawerPayMoneyAuth.onSubmit();
                } else {
                  // 提交更改授权渠道
                  const drawerUpdatePayedTypeCom =
                    this.$refs.payedOrder.$refs.drawerUpdatePayedType;
                  if (drawerUpdatePayedTypeCom)
                    drawerUpdatePayedTypeCom.onSubmit();
                }
              } else if (this.drawer.orderBackDrawer.showDrawer) {
                // 退单drawer中的确定按钮
                if (this.$refs.drawerOrderBack.showAuthDrawer) {
                  // 退单添加支付渠道（提交授权username和password）
                  this.$refs.drawerOrderBack.$refs.drawerPayMoneyAuth.onSubmit();
                } else {
                  this.$refs.drawerOrderBack.onSubmit();
                }
              } else if (
                this.payTabInfo.activePayId == -1 &&
                this.showPrintDrawer
              ) {
                // 打印消费单（未结/全部）
                this.$refs.drawerPrintOrder.onSubmit();
              }
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 8) {
              // ctrl + backspace  // 清台
              e.preventDefault();
              this.$refs.footBar.clearCardHandle();
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 37) {
              // left箭头
              e.preventDefault();
              if (this.drawer.payDrawer.showDrawer) {
                // 支付
                if (this.$refs.drawerPayMoney.showAuthDrawer) {
                  // 支付抹零授权
                  const authCom =
                    this.$refs.drawerPayMoney.$refs.authComponent.$refs
                      .authorization;
                  authCom.tabIndex = 1;
                }
              } else {
                // 左切换付款次数
                // 其它tab的索引
                const anotherIndex = this.payTabInfo.payTabList.findIndex(
                  (item) => item.id == -2
                );
                const resultPayTabList = this.payTabInfo.payTabList.filter(
                  (item) => item.id != -2
                );
                let index = resultPayTabList.findIndex(
                  (item) => item.id == this.payTabInfo.activePayId
                );
                index = Math.max(0, index - 1);
                this.payTabInfo.payTabShow = index >= anotherIndex;
                const payId = resultPayTabList[index].id;
                this.changeTab("order", payId, false);
              }
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 39) {
              // right箭头
              e.preventDefault();
              if (this.drawer.payDrawer.showDrawer) {
                // 支付
                if (this.$refs.drawerPayMoney.showAuthDrawer) {
                  // 支付抹零授权
                  const authCom =
                    this.$refs.drawerPayMoney.$refs.authComponent.$refs
                      .authorization;
                  authCom.tabIndex = 2;
                }
              } else {
                // 右切换付款次数
                // 其它tab的索引
                const anotherIndex = this.payTabInfo.payTabList.findIndex(
                  (item) => item.id == -2
                );
                const resultPayTabList = this.payTabInfo.payTabList.filter(
                  (item) => item.id != -2
                );
                let index = resultPayTabList.findIndex(
                  (item) => item.id == this.payTabInfo.activePayId
                );
                index = Math.min(resultPayTabList.length - 1, index + 1);
                this.payTabInfo.payTabShow = index >= anotherIndex;
                const payId = resultPayTabList[index].id;
                this.changeTab("order", payId, false);
              }
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 122) {
              // ctrl + f11  // 打印消费单
              e.preventDefault();
              if (this.payTabInfo.activePayId == -1) {
                this.showOrHidePrintDrawer();
              }
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 123) {
              // ctrl + f12  // 打印结算单
              e.preventDefault();
              if (this.payTabInfo.activePayId == -1) {
                this.printOrderPayedList();
              }
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 38) {
              // up箭头  // 向上选择支付方式
              e.preventDefault();
              if (
                this.payTabInfo.activePayId == 0 &&
                this.drawer.payDrawer.showDrawer
              ) {
                // 付款
                if (this.$refs.drawerPayMoney.showAuthDrawer) {
                  // 授权向上选择输入username
                  const authCom =
                    this.$refs.drawerPayMoney.$refs.authComponent.$refs
                      .authorization;
                  if (authCom && authCom.tabIndex == 2) {
                    this.$nextTick(() => {
                      authCom.focusInput(1);
                    });
                  }
                } else {
                  // 向上选择支付方式渠道
                  let index = this.$refs.drawerPayMoney.payList.findIndex(
                    (item) =>
                      item.id == this.$refs.drawerPayMoney.payActiveInfo.id
                  );
                  index = Math.max(0, index - 1);
                  this.$refs.drawerPayMoney.payActiveInfo =
                    this.$refs.drawerPayMoney.payList[index];
                }
              } else if (
                this.payTabInfo.activePayId != 0 &&
                this.$refs.payedOrder.showDrawer
              ) {
                // 修改支付渠道
                const com =
                  this.$refs.payedOrder.$refs.drawerUpdatePayedType &&
                  this.$refs.payedOrder.$refs.drawerUpdatePayedType.$refs
                    .drawerAddPayDetail;
                if (com) {
                  let index = com.payList.findIndex(
                    (item) => item.id == com.payActiveInfo.id
                  );
                  index = Math.max(0, index - 1);
                  com.payActiveInfo = com.payList[index];
                }
              } else if (this.drawer.orderBackDrawer.showDrawer) {
                // 退单添加支付渠道
                const com = this.$refs.drawerOrderBack.$refs.drawerAddPayDetail;
                if (com) {
                  let index = com.payList.findIndex(
                    (item) => item.id == com.payActiveInfo.id
                  );
                  index = Math.max(0, index - 1);
                  com.payActiveInfo = com.payList[index];
                }
              }
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 40) {
              // down  // 向下选择支付方式
              e.preventDefault();
              if (
                this.payTabInfo.activePayId == 0 &&
                this.drawer.payDrawer.showDrawer
              ) {
                // 付款
                if (this.$refs.drawerPayMoney.showAuthDrawer) {
                  // 授权向下选择输入username
                  const authCom =
                    this.$refs.drawerPayMoney.$refs.authComponent.$refs
                      .authorization;
                  if (authCom && authCom.tabIndex == 2) {
                    this.$nextTick(() => {
                      authCom.focusInput(2);
                    });
                  }
                } else {
                  // 向下选择支付方式渠道
                  let index = this.$refs.drawerPayMoney.payList.findIndex(
                    (item) =>
                      item.id == this.$refs.drawerPayMoney.payActiveInfo.id
                  );
                  index = Math.min(
                    this.$refs.drawerPayMoney.payList.length - 1,
                    index + 1
                  );
                  this.$refs.drawerPayMoney.payActiveInfo =
                    this.$refs.drawerPayMoney.payList[index];
                }
              } else if (
                this.payTabInfo.activePayId != 0 &&
                this.$refs.payedOrder.showDrawer
              ) {
                // 修改支付渠道
                const com =
                  this.$refs.payedOrder.$refs.drawerUpdatePayedType &&
                  this.$refs.payedOrder.$refs.drawerUpdatePayedType.$refs
                    .drawerAddPayDetail;
                if (com) {
                  let index = com.payList.findIndex(
                    (item) => item.id == com.payActiveInfo.id
                  );
                  index = Math.min(com.payList.length - 1, index + 1);
                  com.payActiveInfo = com.payList[index];
                }
              } else if (this.drawer.orderBackDrawer.showDrawer) {
                // 退单添加支付渠道
                const com = this.$refs.drawerOrderBack.$refs.drawerAddPayDetail;
                if (com) {
                  let index = com.payList.findIndex(
                    (item) => item.id == com.payActiveInfo.id
                  );
                  index = Math.min(com.payList.length - 1, index + 1);
                  com.payActiveInfo = com.payList[index];
                }
              }
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 9) {
              // tab  // 确认录入渠道
              e.preventDefault();
              if (
                this.payTabInfo.activePayId == 0 &&
                this.drawer.payDrawer.showDrawer
              ) {
                this.$refs.drawerPayMoney.addChooseList();
              }
            }
          });
          break;

        case "keyup":
          const index = downKeyCode.findIndex((item) => item == e.keyCode);

          if (index > -1) downKeyCode[index] = 0;

          if (ctrlAndShiftCode.includes(e.keyCode)) downKeyCode = [0, 0];

          break;
      }
    },
  },
  created() {},
  mounted() {
    this.getMenuInfo();
    this.init();
    document.body.addEventListener("click", () => {
      this.payTabInfo.payTabShow = false;
      this.turnOverInfo.turnOverTabShow = false;
    });

    // 监听是否有其他人更改订单相关数据
    eventVue.$on("reloadPayOrderList", this.init);

    document.onkeydown = this.keyHandle;
    document.onkeyup = this.keyHandle;
  },
  mixins: [navPrdList],
  components: {
    footBar,
    notPayOrder,
    payedOrder,
    drawerPayMoney,
    drawerOrderBack,
    fullPageTable,
    drawerPrintOrder,
  },
  computed: {
    hasChooseClockOrder() {
      return this.notPayData.choosePayOrderList
        .filter((item) => !item.oid)
        .some((item) => item.l > 0);
    },
    hasYh2Order() {
      return (
        this.cardAllOrderInfo &&
        this.cardAllOrderInfo[this.cardAllOrderInfo.length - 1] &&
        this.cardAllOrderInfo[this.cardAllOrderInfo.length - 1].list &&
        this.cardAllOrderInfo[this.cardAllOrderInfo.length - 1].list.some(
          (item) => item.y2s
        )
      );
    },
    // 已结账翻台记录总金额
    turnOverAllAmt() {
      let amt = 0;
      if (
        this.turnOverInfo.activeTurnOverCount <
        this.turnOverInfo.turnOverTabList.length - 1
      ) {
        amt = this.cardAllOrderInfo[this.cardAllOrderInfo.length - 1].ps.reduce(
          (a, b) => a + b.pa * 1,
          0
        );
      }
      return amt.toFixed(2);
    },
    // 翻台之前旧订单
    isOldOrder() {
      return (
        this.$store.state.orderInfo.currentCardInfo.turnoverCnt !=
        this.turnOverInfo.activeTurnOverCount
      );
    },
  },
  watch: {
    turnOverAmtInfo: {
      handler(newVal) {
        setTimeout(() => {
          if (this.payTabInfo.activePayId != 0) {
            eventVue.$emit("changeTurnOverCountHandle", newVal);
          } else {
            eventVue.$emit("changeTurnOverCountNotPayHandle");
          }
        }, 500);
      },
      deep: true,
      immediate: true,
    },
  },
  beforeDestroy() {
    document.body.removeEventListener("click", () => {
      this.payTabInfo.payTabShow = false;
      this.turnOverInfo.turnOverTabShow = false;
    });
    eventVue.$off("reloadPayOrderList")
    document.onkeydown = null;
    document.onkeyup = null;
    downKeyCode = [0, 0];
  },
};
</script>

<style scoped lang="less">
@import "../../style/money/payOrder.less";
</style>
