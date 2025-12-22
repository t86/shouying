<template>
  <!-- 已支付订单表格展示订单详细信息组件 -->
  <div class="payed-order-wrapper">
    <div class="order-info" layout="row" layout-align="center start">
      <!-- 支付途径列表 -->
      <div class="order-info-left">
        <div class="order-id">
          <p v-if="payedOrderInfo.pid != -1">单号:{{ payedOrderInfo.pid }}</p>
        </div>
        <div class="ul" :class="{ 'show-change-btn': payTabList.length == 3 }">
          <div class="li" v-for="(item, i) in payedList" :key="i">
            <div class="pay-detail">
              <p v-if="item.choosedPayInfo.id == 500">
                {{ item.cn }}{{ item.n ? "(" + item.n + ":" : "("
                }}{{ item.c + ")" }}:
              </p>
              <p v-else>
                {{ item.cn }}{{ item.n ? "( " + item.n + ")" : "" }}:
              </p>
              <!-- 会员卡落单 -->
              <div
                v-if="
                  item.choosedPayInfo.id == 5 || item.choosedPayInfo.id == 500
                "
              >
                <p
                  class="amt"
                  style="font-size: 12px"
                  layout="row"
                  layout-align="start center"
                >
                  <span style="width: 70px">总金额:</span>￥{{
                    (item.pa * 1).toFixed(2)
                  }}
                </p>
                <p
                  class="amt"
                  style="font-size: 12px"
                  layout="row"
                  layout-align="start center"
                >
                  <span style="width: 70px">卡储值金额:</span>￥{{
                    (item.pv * 1).toFixed(2)
                  }}
                </p>
                <p
                  class="amt"
                  style="font-size: 12px"
                  layout="row"
                  layout-align="start center"
                >
                  <span style="width: 70px">卡折扣金额:</span>￥{{
                    (item.pf * 1).toFixed(2)
                  }}
                </p>
                <p
                  class="amt"
                  style="font-size: 12px"
                  layout="row"
                  layout-align="start center"
                >
                  <span style="width: 70px">赠送积分:</span>{{ item.p }}
                </p>
                
              </div>
              <p v-else class="amt">￥{{ item.chooseAmt }}</p>
              <p
                  class="amt"
                  style="font-size: 12px"
                  layout="row"
                  layout-align="start center"
                >
                  <span style="width: 70px">结账时间:</span>{{ item.pt || '' }}
                </p>
            </div>
          </div>
        </div>

        <div
          class="change-type"
          v-if="
            showChangeTypeBtn &&
            !(payedOrderList[0] ? payedOrderList[0].isOnlinePay : false)
          "
          @click="showOrHideDrawer"
        >
          <div class="button">更改支付渠道</div>
        </div>
      </div>
      <!-- 表格订单信息 -->
      <div class="order-info-right">
        <div class="order-table">
          <div class="thead">
            <div class="tr">
              <div class="th">状态</div>
              <div class="th">名称</div>
              <div class="th">数量</div>
              <div class="th">单价(元)</div>
              <div class="th">小计(元)</div>
              <div class="th">服务员</div>
              <div class="th">优惠人</div>
              <div class="th">点单时间</div>
              <div class="th">关联卡台</div>
              <div class="th">操作</div>
            </div>
          </div>
          <div class="tbody" ref="scrollDom">
            <div ref="scrollItem">
              <div
                class="coll"
                :class="{ online: item.io == 1 || item.oid }"
                v-for="(item, i) in tableData"
                :key="i"
              >
                <!-- 线上未支付订单（全部订单中显示） -->
                <div class="online-order" v-if="item.oid">
                  <div class="detail tr">
                    <div class="td" style="padding: 0">
                      <div
                        v-for="(items, index) in item.resultNotPayData"
                        :key="index"
                      >
                        <div
                          class="td-tr"
                          layout="row"
                          layout-align="start center"
                        >
                          <div
                            class="td-td"
                            layout="row"
                            layout-align="start center"
                          >
                            <span class="purple" v-if="items.s == 5">结</span>
                            <span class="red" v-if="items.back">退</span>
                            <span
                              class="red"
                              v-if="items.s == 21"
                              style="width: 50px; border-radius: 10px"
                              >退单中</span
                            >
                            <span class="green" v-if="items.at == 2">惠</span>
                            <!-- <span class="green" v-if="item.at==3"><span style="display:block;transform:scale(0.7)">惠2</span></span> -->
                            <!-- <span class="blue" v-if="items.at==6">自</span> -->
                            <span class="pink">线</span>
                            <span class="gray-tips" v-if="items.im == 2">
                              <span>出</span>
                              <img src="@/assets/money-img/notOut.png" />
                            </span>
                          </div>
                          <div class="td-td" :class="{ opacity: items.back }">
                            {{ items.productInfo.name }}
                          </div>
                          <div class="td-td" :class="{ opacity: items.back }">
                            {{ items.pc }}
                          </div>
                          <!-- 单价：使用 p2（实际价格）而不是 pp（原价） -->
                          <div class="td-td" :class="{ opacity: items.back }">
                            {{ items.pp * 1 == 0 ? '时价' : (items.p2 ? (items.p2 * 1).toFixed(2) : (items.pp * 1).toFixed(2)) }}
                          </div>
                          <!-- 小计：使用 pa（实际金额）而不是重新计算 -->
                          <div class="td-td" :class="{ opacity: items.back }">
                            {{
                              items.at == 2 || items.at == 3
                                ? "0.00"
                                : items.pa !== undefined && items.pa !== null
                                ? (items.pa * 1).toFixed(2)
                                : (items.pp * items.pc).toFixed(2)
                            }}
                          </div>
                          <div class="td-td" :class="{ opacity: items.back }">
                            {{
                              items.personInfo ? items.personInfo.name : "自助"
                            }}
                          </div>
                          <div class="td-td" :class="{ opacity: items.back }">
                            {{ items.authInfo ? items.authInfo.name : "自助" }}
                          </div>
                          <div class="td-td" :class="{ opacity: items.back }">
                            {{ items.ot.slice(7) }}
                          </div>
                          <div class="td-td" :class="{ opacity: items.back }">
                            {{ items.ri ? items.ri : (items.Yh2SeatInfo ? items.Yh2SeatInfo.name : '') }}
                          </div>
                        </div>
                        <!-- 线上套餐明细 -->
                        <div v-if="items.is == 1 && !items.back">
                          <div
                            class="detail-list online-detail-tr"
                            v-for="(itemss, i) in items.si"
                            :key="i"
                            layout="row"
                            layout-align="start center"
                          >
                            <div class="online-detail-td"></div>
                            <div class="online-detail-td one-txt-cut">
                              {{ itemss.groupInfo.name
                              }}{{ itemss.r ? "（" + itemss.r + "）" : "" }}
                            </div>
                            <div class="online-detail-td">
                              {{ itemss.sc * itemss.dpc * items.pc }}
                            </div>
                            <div class="online-detail-td"></div>
                            <div class="online-detail-td"></div>
                            <div class="online-detail-td"></div>
                            <div class="online-detail-td"></div>
                            <div class="online-detail-td"></div>
                            <div class="online-detail-td"></div>
                          </div>
                        </div>
                        <div
                          v-if="(item.r || item.is == 1) && !item.back"
                          :class="{ pt: item.is == 1 }"
                          class="requested"
                        >
                          {{ item.r }}
                        </div>
                        <!-- 优惠2订位人及卡台信息 -->
                        <div v-if="item.at == 3" class="requested m-l-3">
                          {{ item.Yh2SalesInfo.name }}；{{
                            item.Yh2SeatInfo.name
                          }}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <!-- 线上线下已支付订单订单 -->
                <div class="another-order" v-else>
                  <div class="detail tr">
                    <div class="td" layout="row" layout-align="start center">
                      <span class="purple" v-if="item.payed">结</span>
                      <span class="red" v-if="item.back">退</span>
                      <span
                        class="red"
                        v-if="item.s == 21"
                        style="width: 50px; border-radius: 10px"
                        >退单中</span
                      >
                      <span class="green" v-if="item.at == 2">惠</span>
                      <span
                        class="green"
                        v-if="item.at == 3 && !(item.io == 1 || item.oid)"
                        ><span style="display: block; transform: scale(0.7)"
                          >惠2</span
                        ></span
                      >
                      <!-- <span class="blue" v-if="item.at==6">自</span> -->
                      <span class="pink" v-if="item.isOnlinePay">线</span>
                      <span
                        class="gray-tips"
                        v-if="item.im == 2 && item.isOnlinePay"
                      >
                        <span>出</span>
                        <img src="@/assets/money-img/notOut.png" />
                      </span>
                    </div>
                    <div class="td" :class="{ opacity: item.back }">
                      <h5>{{item.productInfo.name}}</h5>
<!--                      <h5 v-if="item.back">{{item.b + " - " + item.be}}</h5>-->
                      <h5 v-if="item.back">{{item.b}}</h5>
                    </div>
                    <div class="td" :class="{ opacity: item.back }">
                      {{ item.pc }}
                    </div>
                    <!-- 单价：使用 p2（实际价格）而不是 pp（原价） -->
                    <div class="td" :class="{ opacity: item.back }">
                      {{ item.pp * 1 == 0 ? "时价" : (item.p2 ? (item.p2 * 1).toFixed(2) : (item.pp * 1).toFixed(2)) }}
                    </div>
                    <!-- 小计：使用 pa（实际金额）而不是重新计算 -->
                    <div class="td" :class="{ opacity: item.back }">
                      {{
                        item.at == 2 ||
                        (item.at == 3 && !(item.io == 1 || item.oid))
                          ? "0.00"
                          : item.pa !== undefined && item.pa !== null
                          ? (item.pa * 1).toFixed(2)
                          : (item.pp * item.pc).toFixed(2)
                      }}
                    </div>
                    <div class="td" :class="{ opacity: item.back }">
                      {{ item.personInfo ? item.personInfo.name : "自助" }}
                    </div>
                    <div class="td" :class="{ opacity: item.back }">
                      {{ item.authInfo ? item.authInfo.name : "" }}
                    </div>
                    <div class="td" :class="{ opacity: item.back }">
                      {{ item.ot.slice(7) }}
                    </div>
                    <div class="td" :class="{ opacity: item.back }">
                      {{ item.ri ? item.ri : (item.Yh2SeatInfo ? item.Yh2SeatInfo.name : '') }}
                    </div>
                    <!-- 只显示未退款套餐中的更改套餐明细 或者是优惠变更-->
                    <div class="td">
                      <img
                        :src="imgSrc.shoppingCarMore"
                        @click.stop="showOrHideList(item)"
                        alt
                      />
                      <img
                        :src="imgSrc.sanJiao"
                        class="sanJiao"
                        v-if="item.showList"
                        alt
                      />
                      <ul
                        class="do-list"
                        v-if="item.showList"
                      >
                        <div
                          class="li"
                          v-if="item.showList && item.productInfo.prdType == 2 && !item.back"
                          @click.stop="showOrHideUpdateDetailDrawer(item, 4)"
                        >
                          更改套餐明细
                        </div>
                        <div
                          class="li"
                          v-if="item.showList && item.productInfo.prdType == 2 && item.back"
                          @click.stop="showOrHideUpdateDetailDrawer(item, 5)"
                        >
                          查看套餐明细
                        </div>
                        <div
                          class="li"
                          v-if="item.showList && (item.at == 2 || item.at == 3)"
                          @click.stop="showOrHideUpdateDetailDrawer(item, 9)"
                        >
                          修改优惠人
                        </div>
                        <!-- 已结账并且优惠可取消 -->
                        <div
                          class="li"
                          v-if="item.showList && (item.at == 2 || item.at == 3)"
                          @click.stop="showOrHideUpdateDetailDrawer(item, 10)"
                        >
                          取消优惠
                        </div>
                        <div
                          class="li"
                          v-if="item.showList"
                          @click.stop="showOrHideUpdateDetailDrawer(item, 11)"
                        >
                          修改下单人
                        </div>
                        <div class="li"
                            @click.stop="printPrdTicket(item)"
                          >补打出品小票</div>

                        <div class="li" v-if="item.showList && item.at == 8" @click.stop="showOrHideUpdateDetailDrawer(item, 99)">
                          修改授权人
                        </div>

                      </ul>
                    </div>
                  </div>
                  <div v-if="item.is == 1 && !item.back">
                    <div
                      class="detail-list tr"
                      v-for="(items, i) in item.si"
                      :key="i"
                    >
                      <div class="td"></div>
                      <div class="td one-txt-cut">
                        {{ items.groupInfo.name
                        }}{{ items.r ? "（" + items.r + "）" : "" }}
                      </div>
                      <div class="td">{{ items.sc * items.dpc * item.pc }}</div>
                      <div class="td"></div>
                      <div class="td"></div>
                      <div class="td"></div>
                      <div class="td"></div>
                      <div class="td"></div>
                    </div>
                  </div>
                  <div
                    v-if="(item.r || item.is == 1) && !item.back"
                    :class="{ pt: item.is == 1 }"
                    class="requested"
                  >
                    {{ item.r }}
                  </div>
                  <!-- 优惠2订位人及卡台信息 -->
                  <div v-if="item.at == 3" class="requested m-l-3">
                    {{ item.Yh2SalesInfo.name }}；{{ item.Yh2SeatInfo.name }}
                  </div>
                  <!-- 补单信息 -->
                  <div v-if="item.rl" class="requested m-l-3">
                    {{ item.rl }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 更改支付渠道，收款drawer -->
    <drawerPayMoney
      :showDrawer="showDrawer"
      :choosePayOrderList="tableData.filter((item) => !item.back)"
      @showOrHideDrawer="showOrHideDrawer"
      @paySuccess="handlePaySuccess"
    />

    <!-- 更改套餐明细drawer -->
    <drawerMyOrder
      ref="drawerMyOrder"
      :status="status"
      :showDrawer="showUpdateDetailDrawer"
      :currentItemInfo="currentItemInfo"
      :orderList="tableData"
      @showOrHideDrawer="showOrHideUpdateDetailDrawer"
    />

    <!-- 批量修改下单人drawer -->
    <drawerBatchUpdateWaiter
      :showDrawer="showBatchWaiterDrawer"
      :orderList="tableData"
      @showOrHideDrawer="handleCloseBatchWaiter"
      @success="handleBatchUpdateSuccess"
    />

    <!-- 批量修改授权人drawer -->
    <drawerBatchUpdateAuther
      :showDrawer="showBatchAutherDrawer"
      :orderList="tableData"
      @showOrHideDrawer="handleCloseBatchAuther"
      @success="handleBatchUpdateSuccess"
    />

  </div>
</template>

<script>
import api_money from "@/api/money";
import common_money from "@/utils/common/money";
import api_order from "@/api/order";

import shoppingCarMore from "@/assets/order-img/shoppingCarMore.png";
import sanJiao from "@/assets/card-imgs/cardOptions/sanjiao.png";

import drawerPayMoney from "@/components/money/drawerPayMoney";
import drawerMyOrder from "@/components/order/myOrder/drawerMyOrder";
import drawerBatchUpdateWaiter from "@/components/money/drawerBatchUpdateWaiter";
import drawerBatchUpdateAuther from "@/components/money/drawerBatchUpdateAuther";

export default {
  data() {
    return {
      // 显示更改支付渠道drawer
      showDrawer: false,
      // 显示更改套餐明细drawer
      showUpdateDetailDrawer: false,
      currentItemInfo: {},
      // 订单结算渠道列表
      payedList: [],
      // 表格数据
      tableData: [],
      // 当前支付订单的信息
      payedOrderDetailInfo: {},

      imgSrc: {
        shoppingCarMore,
        sanJiao,
      },
      status: 4, // 4:更改套餐明细 5：套餐退单后查看套餐明细
      
    };
  },
  methods: {
    // 获取当前支付详情的支付渠道列表
    getPayedDetailList() {
      const payedList = JSON.parse(JSON.stringify(this.payedOrderInfo.ps));
      payedList.forEach((el) => {
        el.chooseAmt = (el.pa * 1).toFixed(2);
        el.choosedPayInfo = common_money.getPayInfo(el.pc);
      });
      this.payedList = payedList;
    },

    // 是否显示操作下拉框选项
    showOrHideList(info = {}) {
      const index = this.tableData.findIndex((el) => el.id == info.id);
      this.tableData = this.tableData.map((item, i) => {
        return {
          ...item,
          showList: index == i ? !item.showList : false,
        };
      });
      // return false
    },

    // 更改支付渠道
    showOrHideDrawer() {
      if (!this.showDrawer) {
        this.$confirm(
          "如果继续操作，本订单已支付渠道将进入滞留金列表，本订单需重新支付。请确认是否继续操作？",
          "提示",
          {
            confirmButtonText: "确定",
            cancelButtonText: "取消",
            type: "warning",
          }
        )
          .then(async () => {
            const backResult = await this.orderBack();
            if (backResult) this.showDrawer = !this.showDrawer;
          })
          .catch(() => {});
      } else {
        this.showDrawer = !this.showDrawer;
      }
    },

    // 支付成功后的处理
    handlePaySuccess() {
      // 选中"未结账"tab
      this.$parent.changeTab('order', 0);
    },

    // 关闭批量修改下单人drawer
    handleCloseBatchWaiter() {
      this.$emit('hideBatchUpdateWaiter');
    },

    // 关闭批量修改授权人drawer
    handleCloseBatchAuther() {
      this.$emit('hideBatchUpdateAuther');
    },

    // 批量修改成功后刷新数据
    handleBatchUpdateSuccess() {
      // 通知父组件刷新订单数据
      this.$emit('updateChangedOrderData');
    },

    // 退单（完成退单操作）
    async orderBack() {
          const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64     卡台Id
          pay_id: this.orderId * 1, //     int64     支付订单Id
          remark: "", //     string    退单备注
          wk_order_ids: [], // []int64     待退单订单Id列表
          prd_back_cnts: [], // []int      对应上面退单列表的退单商品数量
          prd_back_amts: [], // []string    对应上面退单列表的退单商品金额
        };

      try {
        const res = await api_money.reqPayedBackOrder(params);
        if (res.code === 1) {
          // 重新确认待结账订单
          let wk_order_ids = [];
          let prd_cnts = [];
          let amt = 0;
          

          this.tableData.forEach((el) => {
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
              : (amt += el.pa * 1);
          });

          const confirmParams = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
            wk_order_ids,
            prd_cnts,
            total_amt: amt.toFixed(2)
          };

          const confirmRes = await api_money.reqConfirmBillInfo(confirmParams);
          if (confirmRes.code != 1) {
            return this.$message.warning(confirmRes.msg);
          }

          return true;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("退单失败", error);
      }
    },

    // 更改已支付套餐明细/更改优惠人 9修改优惠人 11 修改下单人
    showOrHideUpdateDetailDrawer(objInfo, status) {
      this.showUpdateDetailDrawer = !this.showUpdateDetailDrawer;
      if (objInfo) {
        this.currentItemInfo = objInfo;
        this.status = status;
      }
    },

    updateChangedOrderData() {
      this.$emit("updateChangedOrderData");
    },

    
    // 商品补打出品小票
    async printPrdTicket(objInfo = {}) {
      try {
        const res = await api_order.reqReprtCp({ order_id: objInfo.id * 1 })
        if (res.code === 1) {
          this.$message.success('补打成功')
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        this.$message.warning('补打失败，请稍后重试')
      }
    },
  },
  mounted() {
    this.tableData = JSON.parse(JSON.stringify(this.payedOrderList));
    this.getPayedDetailList(); // 获取支付途径
    document.body.addEventListener("click", () => this.showOrHideList());
  },
  props: {
    turnOverCount: {
      // 当前选中的翻台数 activeTurnOverCount
      default: 0,
    },
    payedOrderList: {
      // 支付订单列表
      default: () => [],
    },
    payedOrderInfo: {
      // 支付渠道
      default: () => ({}),
    },
    payTabList: {
      // 支付结账次数
      default: () => [],
    },
    isTurnOver: false, // 是否为已翻台的订单
    showBatchWaiterDrawer: {
      // 是否显示批量修改下单人弹窗
      type: Boolean,
      default: false,
    },
    showBatchAutherDrawer: {
      // 是否显示批量修改授权人弹窗
      type: Boolean,
      default: false,
    },
  },
  computed: {
    showChangeTypeBtn() {
      const currentTypeId = this.payedOrderInfo.pid;
      const result =
        !this.isTurnOver &&
        ((this.payTabList.length == 3 && currentTypeId == -1) ||
          currentTypeId != -1);
      return result;
    },
    orderId() {
      return this.payedOrderInfo.pid == -1
        ? this.payTabList[1].id * 1
        : this.payedOrderInfo.pid * 1;
    },
  },
  components: {
    drawerMyOrder,
    drawerPayMoney,
    drawerBatchUpdateWaiter,
    drawerBatchUpdateAuther,
  },
  watch: {
    payedOrderList: {
      handler(newVal) {
        this.tableData = newVal;
        this.getPayedDetailList(); // 获取支付途径
        this.$forceUpdate();
      },
      deep: true,
      immediate: true,
    },
  },
  beforeDestroy() {
    document.body.removeEventListener("click", () => this.showOrHideList());
  },
};
</script>

<style scoped lang="less">
@import "../../style/money/payedOrder.less";
@import "../../style/common/scrollBar.less";
@import "../../style/common/elementConfirm.less";
</style>
