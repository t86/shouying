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
              <p class="amt" style="font-size: 12px" layout="row" layout-align="start center">
                <span style="width: 70px">结账人:</span>{{ formatPaymentCashier(paymentCashiers[item.checkoutPayId], item.checkoutOnline) }}
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
                          <div class="td-td" :class="{ opacity: items.back }">
                      <span class="fc-price-stack"><del v-if="showOriginalUnit(items)" class="fc-original-price">{{originalUnit(items)}}</del><span>{{getDisplayPrice(items)}}</span></span>
                    </div>
                    <div class="td-td" :class="{ opacity: items.back }">
                      <span class="fc-price-stack"><del v-if="showOriginalSubtotal(items, true)" class="fc-original-price">{{originalSubtotal(items)}}</del><span>{{getSubtotal(items, true)}}</span></span>
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
                          <div class="td-td"></div>
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
                    <div class="td" :class="{ opacity: item.back }">
                      <span class="fc-price-stack"><del v-if="showOriginalUnit(item)" class="fc-original-price">{{originalUnit(item)}}</del><span>{{getDisplayPrice(item)}}</span></span>
                    </div>
                    <div class="td" :class="{ opacity: item.back }">
                      <span class="fc-price-stack"><del v-if="showOriginalSubtotal(item)" class="fc-original-price">{{originalSubtotal(item)}}</del><span>{{getSubtotal(item)}}</span></span>
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
import { getFcPrice } from "@/utils/fcPrice";
import { formatPaymentCashier } from "@/utils/paymentCashiers";
import api_money from "@/api/money";
import common_money from "@/utils/common/money";
import api_order from "@/api/order";
import {
  buildPriceContextFromStore,
  calcItemAmount,
} from "@/utils/orderItemPrice";
import eventVue from "@/utils/eventVue";

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
    // Display current author-plan prices without rewriting historical payment amounts.
    schemePrice(item) {
      if (!item) return null;
      const metadata = this.$store.state.cardPageInfo.resResultDataObj;
      return getFcPrice(item.pid || (item.productInfo && item.productInfo.id), item.ae, item.wei, metadata);
    },
    originalUnit(item) { return Number(item.pp || 0).toFixed(2); },
    displayCount(item) {
      return Number(item.pc || 0);
    },
    originalSubtotal(item) {
      return (Number(item.pp) === 0 ? Number(item.pa || 0) : Number(item.pp || 0) * this.displayCount(item)).toFixed(2);
    },
    showOriginalUnit(item) {
      const price = this.schemePrice(item);
      return price !== null && Number(item.pp) !== 0 && Number(item.pp).toFixed(2) !== price.toFixed(2);
    },
    showOriginalSubtotal(item, online) {
      const price = this.schemePrice(item);
      return price !== null && !this.isFreeDisplay(item, online) && this.originalSubtotal(item) !== (price * this.displayCount(item)).toFixed(2);
    },
    isFreeDisplay(item, online) {
      return item.at == 2 || (item.at == 3 && (online || !(item.io == 1 || item.oid)));
    },
    getDisplayPrice(item) {
      const price = this.schemePrice(item);
      if (price !== null) return price.toFixed(2);
      return Number(item.pp) === 0 ? '时价' : Number(item.p2 || item.pp || 0).toFixed(2);
    },
    getSubtotal(item, online) {
      if (this.isFreeDisplay(item, online)) return '0.00';
      const price = this.schemePrice(item);
      if (price !== null) return (price * this.displayCount(item)).toFixed(2);
      return Number(item.pa !== undefined && item.pa !== null ? item.pa : item.pp * item.pc).toFixed(2);
    },

    formatPaymentCashier,
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
          // ✅ 退单成功后，先调用 csm_orders 获取最新的待结账商品信息
          const cardPayInfoParams = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
            turnover_cnt: this.turnOverCount,
          };

          console.log('📋 [退单] 调用 csm_orders 参数:', cardPayInfoParams);
          const cardPayInfoRes = await api_money.reqGetCardPayInfo(cardPayInfoParams);
          console.log('📋 [退单] csm_orders 返回:', cardPayInfoRes);

          if (cardPayInfoRes.code !== 1) {
            return this.$message.warning('获取待结账商品信息失败: ' + cardPayInfoRes.msg);
          }

          // ✅ 数据在 unpay_order.os 字段中
          const unpayOrder = cardPayInfoRes.data.unpay_order;
          const orderList = (unpayOrder && unpayOrder.os) ? unpayOrder.os : [];
          console.log('📋 [退单] unpay_order.os 列表:', orderList);
          console.log('📋 [退单] tableData 更新前:', this.tableData);

          // ✅ 用 csm_orders 返回的新数据更新 tableData
          // 这样 drawerPayMoney 组件就会使用最新的数据（包含正确的价格）
          orderList.forEach((newItem) => {
            const index = this.tableData.findIndex(td => td.id === newItem.id);
            if (index >= 0) {
              // 找到匹配的商品，用新数据替换旧数据
              // 使用 $set 确保触发 Vue 响应式更新
              Object.keys(newItem).forEach(key => {
                this.$set(this.tableData[index], key, newItem[key]);
              });
            }
          });

          console.log('📋 [退单] tableData 更新后:', this.tableData);
          // 强制触发更新
          this.$forceUpdate();

          // ✅ 更改支付渠道：只传递 tableData 中的商品给 cart_begin_process
          let wk_order_ids = [];
          let prd_cnts = [];
          let amt = 0;

          // 构建价格上下文
          const priceContext = buildPriceContextFromStore(this.$store);

          // 遍历 tableData（现在已经是最新的数据了）
          this.tableData.forEach((item) => {
            console.log('📋 [退单] 处理商品:', item.id, 'pid:', item.pid);

            wk_order_ids.push(item.id * 1);
            prd_cnts.push(item.pc || 1);

            // 使用通用的价格公式计算金额
            const itemAmt = calcItemAmount(item, priceContext);
            amt += itemAmt;

            console.log('📋 [退单] 添加商品:', item.id, 'pid:', item.pid, '数量:', item.pc, '金额:', itemAmt);
          });

          const confirmParams = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
            wk_order_ids,
            prd_cnts,
            total_amt: amt.toFixed(2)
          };

          console.log('📋 [退单] cart_begin_process 参数:', confirmParams);

          const confirmRes = await api_money.reqConfirmBillInfo(confirmParams);
          console.log('📋 [退单] cart_begin_process 返回:', confirmRes);

          if (confirmRes.code != 1) {
            return this.$message.warning(confirmRes.msg);
          }

          // ✅ 更改支付渠道成功后，通知父组件刷新订单数据
          // 这样 payOrder.vue 的 notPayData.choosePayOrderList 才会更新为最新数据
          console.log('📋 [退单] 发出 reloadPayOrderList 事件');
          eventVue.$emit("reloadPayOrderList");

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

    // ✅ 监听价格更新事件（会员绑定/取消绑定）
    // 添加防抖，避免与 payOrder.vue 同时请求导致被拦截
    let priceUpdateTimer = null;
    eventVue.$on("priceUpdated", async () => {
      console.log('🔄 [payedOrder] 收到 priceUpdated 事件，延迟 300ms 后更新 tableData 价格');

      // 清除之前的定时器
      if (priceUpdateTimer) {
        clearTimeout(priceUpdateTimer);
      }

      // 延迟 300ms 执行，避免与 payOrder.vue 的请求冲突
      priceUpdateTimer = setTimeout(async () => {
        // 调用 API 获取最新价格
        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
          turnover_cnt: this.turnOverCount,
        };

        try {
          const res = await api_money.reqGetCardPayInfo(params);
          if (res.code !== 1) {
            console.error('获取价格数据失败:', res.msg);
            return;
          }

          // 更新 tableData 的价格字段
          const unpayOrder = res.data.unpay_order;
          const orderList = (unpayOrder && unpayOrder.os) ? unpayOrder.os : [];

          this.tableData.forEach((item) => {
            const newItem = orderList.find(n => n.id === item.id);
            if (newItem) {
              // 只更新价格字段
              this.$set(item, 'pp', newItem.pp);
              this.$set(item, 'pa', newItem.pa);
              this.$set(item, 'p2', newItem.p2);
              this.$set(item, 'pm', newItem.pm);
              console.log('📋 [payedOrder] 更新商品价格:', item.id, 'p2:', item.p2, 'pa:', item.pa);
            }
          });

          this.$forceUpdate();
          console.log('♻️ [payedOrder] tableData 价格更新完成');
        } catch (error) {
          console.error('更新价格失败:', error);
        }
      }, 300);
    });
  },
  props: {
    paymentCashiers: {
      type: Object,
      default: () => ({}),
    },
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
    // 移除事件监听
    eventVue.$off("priceUpdated");
  },
};
</script>

<style scoped lang="less">
@import "../../style/money/payedOrder.less";
@import "../../style/common/scrollBar.less";
@import "../../style/common/elementConfirm.less";

.fc-price-stack { display: inline-flex; flex-direction: column; align-items: center; line-height: 18px; }
.fc-original-price { color: #9299a8; font-size: 12px; text-decoration: line-through; }
</style>
