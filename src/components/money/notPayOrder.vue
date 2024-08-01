<template>
  <!-- 未支付订单表格展示订单详细信息组件 -->
  <div>
    <div class="order-table">
      <div class="thead">
        <div class="tr">
          <div class="th" layout="row" layout-align="start center">
            <input type="checkbox" v-model="checkoutAll" @change="chooseOrder($event, '', 'all')" />
            <span style="white-space:nowrap">全选</span>
          </div>
          <div class="th">状态</div>
          <div class="th">名称</div>
          <div class="th">数量</div>
          <div class="th">待结数量</div>
          <div class="th">单价(元)</div>
          <div class="th">小计(元)</div>
          <div class="th">服务员</div>
          <div class="th">点单时间</div>
          <div class="th">操作</div>
        </div>
      </div>
      <div class="tbody" ref="scrollDom">
        <div ref="scrollItem">
          <div
            class="coll"
            :class="{'online': item.io==1 || item.oid}"
            v-for="(item,i) in tableData"
            :key="i"
          >
            <!-- 线上订单 -->
            <div class="online-order" v-if="item.oid">
              <div class="detail tr">
                <div class="td" layout="row" layout-align="start center">
                  <input
                    type="checkbox"
                    class="m-r-1"
                    :disabled="item.resultNotPayData.every(items=>items.back)"
                    v-model="item.checkout"
                    @change="chooseOrder($event,item,'item')"
                  />
                  {{i+1}}
                </div>
                <div class="td" style="padding:0">
                  <div v-for="(items,index) in item.resultNotPayData" :key="index">
                    <div class="td-tr" layout="row" layout-align="start center">
                      <div class="td-td" layout="row" layout-align="start center">
                        <span class="purple" v-if="items.s==5">结</span>
                        <span class="red" v-if="items.back">退</span>
                        <span class="red" v-if="items.s==21" style="width:50px;border-radius:10px">退单中</span>
                        <span class="green" v-if="items.at==2">惠</span>
                        <span class="blue" v-if="items.l>0">锁</span>
                        <span class="green" v-if="items.at==3"><span style="display:block;transform:scale(0.7)">惠2</span></span>
                        <!-- <span class="blue" v-if="items.at==6">自</span> -->
                        <span class="pink">线</span>
                        <span class="gray-tips" v-if="items.im==2">
                          <span>出</span>
                          <img src="@/assets/money-img/notOut.png" />
                        </span>
                      </div>
                      <div class="td-td" :class="{'opacity':items.back}">{{ items.productInfo.name }}</div>
                      <div class="td-td">
                        <img :src="imgSrc.subDisabled" />
                        <input type="number" disabled v-model="items.pc" />
                        <img :src="imgSrc.addDisabled" />
                      </div>
                      <div class="td-td" :class="{'opacity':items.back}">{{items.pc}}</div>
                      <div class="td-td" :class="{'opacity':items.back}">{{(items.pp*1).toFixed(2)}}</div>
                      <div
                        class="td-td"
                        :class="{'opacity':items.back}"
                      >{{items.at==2 || items.at==3 ? '0.00' : items.pp==0? (items.pa*1).toFixed(2) : (items.pp * items.pc).toFixed(2)}}</div>
                      <div
                        class="td-td"
                        :class="{'opacity':items.back}"
                      >{{items.personInfo ? items.personInfo.name : '自助'}}</div>
                      <div class="td-td" :class="{'opacity':items.back}">{{items.ot.slice(7)}}</div>
                      <div class="td-td">
                        <img
                          :src="imgSrc.shoppingCarMore"
                          v-if="(items.at == 2 || items.at == 3) || !items.back||items.productInfo.prdType==2"
                          @click.stop="showOrHideList(item,items)"
                          alt
                        />
                        <img
                          :src="imgSrc.sanJiao"
                          v-if="items.showList&&((items.at == 2 || items.at == 3) || !items.back||items.productInfo.prdType==2)"
                          class="sanJiao"
                          alt
                        />
                        <div
                          class="do-list"
                          v-if="items.showList&&(!items.back|| (items.at == 2 || items.at == 3) || items.productInfo.prdType==2)"
                        >
                          <div class="li" v-if="!items.back" @click.stop="showOrHideDrawer(1,items)">退单</div>
                          <div
                          class="li"
                          v-if="(items.at == 2 || items.at == 3) && !items.back"
                          @click.stop="showOrHideDrawer(9, items)"
                          >
                            修改优惠人</div>
                          <!-- <div class="li"
                            v-if="items.productInfo.prdType!=2&&items.at!=6&&!(items.at==2||items.at==3||items.at==5)&&!items.back"
                            @click.stop="showOrHideDrawer(2,items)"
                          >优惠</div>-->
                          <!-- <div class="li"
                            v-if="items.productInfo.prdType!=2&&items.at!=6&&!(items.at==2||items.at==3||items.at==5)&&!items.back"
                            @click.stop="showOrHideDrawer(3,items)"
                          >自用</div>-->
                          <div class="li"
                            v-if="items.productInfo.prdType==2&&!items.back"
                            @click.stop="showOrHideDrawer(4,items)"
                          >更改套餐明细</div>
                          <div class="li"
                            v-if="items.productInfo.prdType==2&&items.back"
                            @click.stop="showOrHideDrawer(5,items)"
                          >查看套餐明细</div>
                          <div class="li"
                            @click.stop="printPrdTicket(item)"
                          >补打出品小票</div>
                        </div>
                      </div>
                    </div>
                    <!-- 线上套餐明细 -->
                    <div v-if="items.is==1&&(!items.back)">
                      <div
                        class="detail-list online-detail-tr"
                        v-for="(itemss,i) in items.si"
                        :key="i"
                        layout="row"
                        layout-align="start center"
                      >
                        <div class="online-detail-td"></div>
                        <div
                          class="online-detail-td one-txt-cut"
                        >{{itemss.groupInfo.name}}{{itemss.r ? '（'+itemss.r+'）':''}}</div>
                        <div class="online-detail-td">{{itemss.sc * itemss.dpc * items.pc}}</div>
                        <div class="online-detail-td"></div>
                        <div class="online-detail-td"></div>
                        <div class="online-detail-td"></div>
                        <div class="online-detail-td"></div>
                        <div class="online-detail-td"></div>
                        <div class="online-detail-td"></div>
                      </div>
                    </div>
                    <div
                      v-if="(item.r||item.is==1)&&!item.back"
                      :class="{'pt':item.is==1}"
                      class="requested"
                    >{{item.r}}</div>
                  </div>
                </div>
              </div>
            </div>
            <!-- 线下订单 -->
            <div class="another-order" v-else>
              <div class="detail tr">
                <div class="td" layout="row" layout-align="start center">
                  <input
                    type="checkbox"
                    class="m-r-1"
                    :disabled="item.back"
                    v-model="item.checkout"
                    @change="chooseOrder($event, item, 'item')"
                  />
                  {{i+1}}
                </div>
                <div class="td" layout="row" layout-align="start center">
                  <span class="purple" v-if="item.s==5">结</span>
                  <span class="red" v-if="item.back">退</span>
                  <span class="red" v-if="item.s==21" style="width:50px;border-radius:10px">退单中</span>
                  <span class="blue" v-if="item.l>0">锁</span>
                  <span class="green" v-if="item.at==2">惠</span>
                  <span class="green" v-if="item.at==3"><span style="display:block;transform:scale(0.7)">惠2</span></span>
                  <!-- <span class="blue" v-if="item.at==6">自</span> -->
                  <!-- <span class="pink" v-if="item.ip==1">线</span> -->
                  <!-- <span class="gray-tips" v-if="item.im==2">
                    <span>出</span>
                    <img src="@/assets/money-img/notOut.png" />
                  </span> -->
                </div>
                <div class="td">
                  <h5>{{item.productInfo.name}}</h5>
                  <h5 v-if="item.back">{{item.b + " - " + item.be}}</h5></div>
                <div class="td">
                  <img
                    :src="item.back||item.changeCount==1||(item.at==2||item.at==3||item.at==5)||item.pp * 1==0?imgSrc.subDisabled:imgSrc.sub"
                    @click="changeCount('sub',item)"
                    alt
                  />
                  <input
                    type="number"
                    min="1"
                    :disabled="(item.at==2||item.at==3||item.at==5||item.back)||item.pp * 1==0"
                    v-model="item.changeCount"
                    @input="changeCount('input',item)"
                  />
                  <img
                    :src="item.back||item.changeCount>=item.pc||(item.at==2||item.at==3||item.at==5)||item.pp * 1==0?imgSrc.addDisabled:imgSrc.add"
                    @click="changeCount('add',item)"
                    alt
                  />
                </div>
                <div class="td" :class="{'opacity':item.back}">{{item.pc}}</div>
                <div class="td" :class="{'opacity':item.back}">{{item.pp * 1 == 0 ? '时价' : (item.pp*1).toFixed(2)}}</div>
                <div
                  class="td"
                  :class="{'opacity':item.back}"
                >{{item.at==2 || item.at==3 ? '0.00' : item.pp==0? (item.pa*1).toFixed(2) : (item.pp * item.changeCount).toFixed(2)}}</div>
                <div
                  class="td"
                  :class="{'opacity':item.back}"
                >{{item.personInfo ? item.personInfo.name : '自助'}}</div>
                <div class="td" :class="{'opacity':item.back}">{{item.ot.slice(7)}}</div>
                <div class="td">
                  <img
                    :src="imgSrc.shoppingCarMore"
                    v-if="(item.at == 2 || item.at == 3) || !item.back||item.productInfo.prdType==2"
                    @click.stop="showOrHideList('', item)"
                    alt
                  />
                  <img
                    :src="imgSrc.sanJiao"
                    v-if="item.showList&&((item.at == 2 || item.at == 3) || !item.back||item.productInfo.prdType==2)"
                    class="sanJiao"
                    alt
                  />
                  <div
                    class="do-list"
                    v-if="item.showList&&((item.at == 2 || item.at == 3) || !item.back||item.productInfo.prdType==2)"
                  >
                    <div class="li" v-if="!item.back" @click.stop="showOrHideDrawer(1,item)">退单</div>
                    <div
                      class="li"
                      v-if="(item.at == 2 || item.at == 3)&& !item.back"
                      @click.stop="showOrHideDrawer(9,item)"
                    >
                      修改优惠人
                    </div>
                    <!-- <div class="li"
                      v-if="(item.productInfo.prdType == 1||item.productInfo.prdType == 7||item.productInfo.prdType == 6)&&item.at!=6&&!(item.at==2||item.at==3||item.at==5)&&!item.back"
                      @click.stop="showOrHideDrawer(2,item)"
                    >优惠</div> -->
                    <!-- <div class="li"
                      v-if="item.productInfo.prdType!=2&&item.at!=6&&!(item.at==2||item.at==3||item.at==5)&&!item.back"
                      @click.stop="showOrHideDrawer(3,item)"
                    >自用</div>-->
                    <div class="li"
                      v-if="item.productInfo.prdType==2&&!item.back"
                      @click.stop="showOrHideDrawer(4,item)"
                    >更改套餐明细</div>
                    <div class="li"
                      v-if="item.productInfo.prdType==2&&item.back"
                      @click.stop="showOrHideDrawer(5,item)"
                    >查看套餐明细</div>
                    <div class="li"
                      @click.stop="showOrHideDrawer(11,item)"
                    >更改下单人</div>
                    <div class="li"
                      @click.stop="printPrdTicket(item)"
                    >补打出品小票</div>

                    <div class="li" v-if="item.at == 8" @click.stop="showOrHideDrawer(99,item)"
                    >修改授权人</div>

                  </div>

                </div>
              </div>
              <!-- 线下套餐明细 -->
              <div v-if="item.is==1&&(!item.back)">
                <div class="detail-list tr" v-for="(items,i) in item.si" :key="i">
                  <div class="td"></div>
                  <div class="td"></div>
                  <div
                    class="td one-txt-cut"
                  >{{items.groupInfo.name}}{{items.r ? '（'+items.r+'）':''}}</div>
                  <div class="td">{{items.sc * items.dpc * item.changeCount}}</div>
                  <div class="td"></div>
                  <div class="td"></div>
                  <div class="td"></div>
                  <div class="td"></div>
                  <div class="td"></div>
                  <div class="td"></div>
                </div>
              </div>
              <div
                v-if="(item.r||item.is==1)&&!item.back"
                :class="{'pt':item.is==1}"
                class="requested"
              >{{item.r}}</div>
              <!-- 优惠2订位人及卡台信息 -->
              <div v-if="item.at==3" class="requested m-l-3">{{item.Yh2SalesInfo.name}}；{{item.Yh2SeatInfo.name}}</div>
              <!-- 补单信息 -->
              <div v-if="item.rl" class="requested m-l-3">{{item.rl}}</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 赠送、自用、退单、更改套餐明细、查看套餐明细等drawer -->
    <drawerMyOrder
      ref="drawerMyOrder"
      :status="drawer.status"
      :showDrawer="drawer.showDrawer"
      :currentItemInfo="drawer.currentItemInfo"
      :orderList="tableData"
      @showOrHideDrawer="showOrHideDrawer"
      @closeBackDrawer="closeBackDrawer"
    />
  </div>
</template>
 
<script>
import add from "@/assets/order-img/order_add.png";
import sub from "@/assets/order-img/sub.png";
import addDisabled from "@/assets/order-img/add-disabled.png";
import subDisabled from "@/assets/order-img/sub-disabled.png";
import shoppingCarMore from "@/assets/order-img/shoppingCarMore.png";
import sanJiao from "@/assets/card-imgs/cardOptions/sanjiao.png";
import api_order from "@/api/order";

import drawerMyOrder from "@/components/order/myOrder/drawerMyOrder";
export default {
  data() {
    return {
      checkoutAll: false, // 全选
      // 表格数据
      tableData: [],
      // 选择的即将要支付的订单信息
      choosePayOrderList: [],

      drawer: {
        showDrawer: false,
        status: 1, // 1：退单 2：赠送  3：自用  4：更改套餐明细  5：查看套餐明细 9 修改优惠人
        currentItemInfo: {} // 当前正在操作的商品信息
      },

      imgSrc: {
        add,
        sub,
        addDisabled,
        subDisabled,
        shoppingCarMore,
        sanJiao
      }
    };
  },
  methods: {
    chooseOrder(e, orderInfo, type) {
      // 批量操作勾选、反勾选退单套餐商品
      if (type == "all") {
        this.tableData.forEach(el => {
          if (!el.oid) {
            // 线下结算商品
            if (el.back && el.parentOrderId) {
              // 退单商品
              // 是否全部退单
              const isAllBack = !this.tableData.find(
                item => item.id == el.parentOrderId
              );
              if (isAllBack) {
                // 全退  让其永远处于勾选状态
                el.checkout = true;
              } else {
                // 非全退  此处需要根据未退商品的选择结账数量是否与待结账商品总数量相同  相同则勾选，否则不勾选
                const parentPrdInfo = this.tableData.find(
                  item => item.id == el.parentOrderId
                );
                el.checkout =
                  parentPrdInfo.pc == parentPrdInfo.changeCount
                    ? e.target.checked
                    : false;
              }
            } else {
              el.checkout = e.target.checked;
            }
          } else {
            // 线上结算订单
            if (
              el.resultNotPayData &&
              el.resultNotPayData.every(item => item.back)
            ) {
              // 全退
              el.checkout = true;
            } else {
              // 未全退
              el.checkout = e.target.checked;
            }
          }
        });
      } else if (type == "item") {
        this.tableData.forEach(el => {
          if (orderInfo.oid && el.oid && el.oid == orderInfo.oid) {
            // 线上结算订单
            el.checkout = e.target.checked;
          } else if (
            !orderInfo.oid &&
            !el.oid &&
            ((el.id && el.id == orderInfo.id) ||
              el.parentOrderId == orderInfo.id)
          ) {
            // 线下结算订单
            if (el.parentOrderId == orderInfo.id) {
              // 对应的退单商品
              const parentPrdInfo = this.tableData.find(
                item => item.id == orderInfo.id
              );
              /*
              此处逻辑为：只有结账选择的未结账订单数量与待结账商品总数量相同时，才能让退单的商品勾选状态跟着结账的走，否则不勾选已退单商品
              */
              el.checkout =
                parentPrdInfo.changeCount == parentPrdInfo.pc
                  ? e.target.checked
                  : false;
            } else if (el.l > 0){ // 锁定状态订单 一选则全选
              this.tableData = this.tableData.map(items => {
                return {
                ...items,
                checkout: items.l && items.l > 0 && !items.oid ? e.target.checked : items.checkout
              }})
            } else {
              el.checkout = e.target.checked;
            }
          }
        });
        this.checkoutAll = this.tableData
          .filter(item => !item.back)
          .every(item => item.checkout);
      }

      this.choosePayOrderList = this.tableData.filter(item => item.checkout);
      this.$emit("updatePayOrderList", this.choosePayOrderList);
      this.$forceUpdate();
    },

    // 切换选择优惠2订单
    checkedOrder(type) {
      if (type == 'YH2') {
        const checkoutYH2All = this.tableData.filter(item => !item.oid && item.at == 3).every(item => item.checkout)
        this.tableData.forEach(el => {
          if (!el.oid && el.at == 3) {
            // 线下优惠2订单
            el.checkout = !checkoutYH2All;
          }
        })
      } else if (type == 'line') {  // 线上支付订单
        const checkoutLineAll = this.tableData.filter(item => item.oid).every(item => item.checkout)
        this.tableData.forEach(el => {
          if (el.oid) {
            // 线上订单
            el.checkout = !checkoutLineAll;
          }
        })
      } else if (type == 'offLine') {  // 线下支付订单
        const checkoutOffLineAll = this.tableData.filter(item => !item.oid).every(item => item.checkout)
        this.tableData.forEach(el => {
          if (!el.oid) {
            // 线下支付订单
            el.checkout = !checkoutOffLineAll;
          }
        })
      }
      
    },

    // 是否显示操作下拉框选项
    // params:item: 当前tableData的子项  info：当前tableData子项的子项
    showOrHideList(item = "", info = {}) {
      if (item == "all") {
        // 全部
        const tableData = [...this.tableData];
        tableData.forEach(el => {
          if (el.oid) {
            el.resultNotPayData.forEach(ele => {
              ele.showList = ele.id == info.id ? !ele.showList : false;
            });
          } else {
            const index = this.tableData.findIndex(el => el.id == info.id);
            this.tableData.forEach((el, i) => {
              el.showList = index == i ? !el.showList : false;
            });
          }
        });
        this.tableData = [...tableData];
      } else if (item) {
        // 线上订单
        const tableData = [...this.tableData];
        tableData.forEach(el => {
          if (el.oid) {
            el.resultNotPayData.forEach(ele => {
              ele.isOnline = true
              ele.showList = ele.id == info.id ? !ele.showList : false;
            });
          } else {
            el.showList = false;
          }
        });
        this.tableData = [...tableData];
      } else {
        // 线下订单
        const index = this.tableData.findIndex(el => el.id == info.id);
        this.tableData.forEach((el, i) => {
          el.showList = index == i ? !el.showList : false;
        });
      }
    },
    // 更改结账商品数量
    changeCount(type, info) {
      if (info.back) return;
      if (
        this.authId != info.ae &&
        (info.at == 2 || info.at == 3 || info.at == 5)
      )
        return this.$message.warning("此优惠商品非当前用户授权，不可修改数量");
      if(info.pp * 1 == 0) {
        return this.$message.warning('时价商品不可修改数量')
      }
      let count = info.changeCount;
      switch (type) {
        case "add":
          count = Math.min(count + 1, info.pc);
          break;
        case "sub":
          count = Math.max(count - 1, 1);
          break;
        case "input":
          count = Math.min(count, info.pc);
          count = Math.max(count, 1);
          break;
      }
      info.changeCount = count;

      // 判断选择结账的数量是否与待结账总数量相同，来判断当前商品的退单商品是否勾选
      this.tableData.forEach(el => {
        if (el.parentOrderId == info.id) {
          // 有退单商品
          el.checkout = info.pc == count && info.checkout;
        }
      });

      this.choosePayOrderList = this.tableData.filter(item => item.checkout);
      this.$emit("updatePayOrderList", this.choosePayOrderList);
    },

    // 显示隐藏赠送或自用信息
    showOrHideDrawer(status, objInfo = {}) {
      this.drawer.showDrawer = !this.drawer.showDrawer;
      if (!objInfo && status < 6) return;
      // status 1：退单 2：赠送  3：自用  4：更改套餐明细  5：查看套餐明细  6：批量优惠  7：批量优惠2  8：批量退单 9：修改优惠人 11：修改下单人 12：补打出品小票
      this.drawer.status = status;
      if(status < 6 || status == 9 || status == 11 || status == 99) this.drawer.currentItemInfo = {...objInfo};
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

    // 关闭批量退单drawer
    closeBackDrawer() {
      this.drawer.showDrawer = false;
    },
  },
  created() {},
  mounted() {
    this.tableData = JSON.parse(JSON.stringify(this.notPayOrderList));
    this.choosePayOrderList = JSON.parse(JSON.stringify(this.notPayOrderList));
    setTimeout(() => {
      this.checkoutAll = this.tableData
        .filter(item => !item.back)
        .every(item => item.checkout);
    }, 500);
    document.body.addEventListener("click", () => this.showOrHideList("all"));
  },
  props: ["notPayOrderList"],
  components: {
    drawerMyOrder
  },
  watch: {
    notPayOrderList(newVal) {
      this.tableData = newVal;
    }
  },
  beforeDestroy() {
    document.body.removeEventListener("click", () =>
      this.showOrHideList("all")
    );
  }
};
</script>

<style scoped lang="less">
@import "../../style/money/notPayOrder.less";
@import "../../style/common/scrollBar.less";
</style>