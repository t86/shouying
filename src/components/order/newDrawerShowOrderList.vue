<template>
<!-- 点单系统服务员买单选择商品列表 -->
  <div>
    <el-drawer
      title="选择买单商品"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      append-to-body
      size="100%"
    >
      <div class="session choose-pay-order p-5 fs14">
        <div class="fs22">请勾选结账商品
          <span class="red-color">(含有“线”标志的为线上支付的订单，线上支付的订单需线联系收银员转为线下支付才可进行买单)</span>
        </div>
        <div class="tab" layout="row" layout-align="start center">
          <div class="tab-item" :class="{active: tabIndex == 1}" @click="changeTabIndexHandle(1)">勾选全部未结</div>
          <div class="tab-item" :class="{active: tabIndex == 2}" @click="changeTabIndexHandle(2)">勾选我的未结</div>
          <div class="tab-item" :class="{active: tabIndex == 3}" @click="changeTabIndexHandle(3)">勾选我和客人未结</div>
          <div class="tab-item red-active" @click="continuePayHandle">继续支付</div>
        </div>
        <div class="order-table m-t-3">
          <div class="thead">
            <div class="tr">
              <div class="th" layout="row" layout-align="start center">
                <!-- <el-checkbox :indeterminate="isIndeterminate" v-model="checkAll" @change="changeCheckBoxHandle('all')">全选</el-checkbox> -->
                序号
              </div>
              <div class="th">状态</div>
              <div class="th">名称</div>
              <div class="th">待结数量</div>
              <div class="th">单价(元)</div>
              <div class="th">小计(元)</div>
              <div class="th">服务员</div>
              <div class="th">点单时间</div>
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
                      <el-checkbox disabled  v-model="item.checked" @change="changeCheckBoxHandle('item', item)">{{i + 1}}</el-checkbox>
                    </div>
                    <div class="td" style="padding:0">
                      <div v-for="(items,index) in item.resultNotPayData" :key="index">
                        <div class="td-tr" layout="row" layout-align="start center">
                          <div class="td-td" layout="row" layout-align="start center">
                            <span class="red" v-if="items.back">退</span>
                            <span class="green" v-if="items.at==2">惠</span>
                            <span class="blue" v-if="items.l>0">锁</span>
                            <span class="green" v-if="items.at==3"><span style="display:block;transform:scale(0.7)">惠2</span></span>
                            <span class="pink">线</span>
                            <span class="gray-tips" v-if="items.im==2">
                              <span>出</span>
                              <img src="@/assets/money-img/notOut.png" />
                            </span>
                          </div>
                          <div class="td-td" :class="{'opacity':items.back}">{{items.productInfo.name}}</div>
                          <div class="td-td" :class="{'opacity':items.back}">{{items.pc}}</div>
                          <div class="td-td" :class="{'opacity':items.back}"><span class="fc-price-stack"><del v-if="!items.back && fcOrderOriginal(items, getDisplayPrice(items))" class="fc-original-price">{{ fcOriginalText(items) }}</del><span>{{ getDisplayPrice(items) }}</span></span></div>
                          <div
                            class="td-td"
                            :class="{'opacity':items.back}"
                          ><span class="fc-price-stack"><del v-if="!items.back && items.at != 2 && items.at != 3 && fcSubtotalOriginal(items, getSubtotal(items))" class="fc-original-price">{{ fcOriginalSubtotal(items).toFixed(2) }}</del><span>{{ getSubtotal(items) }}</span></span></div>
                          <div
                            class="td-td"
                            :class="{'opacity':items.back}"
                          >{{items.personInfo ? items.personInfo.name : '自助'}}</div>
                          <div class="td-td" :class="{'opacity':items.back}">{{items.ot.slice(7)}}</div>
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
                              class="online-detail-td one-txt-cut name"
                            >{{itemss.groupInfo.name}}{{itemss.r ? '（'+itemss.r+'）':''}}</div>
                            <div class="online-detail-td" style="font-size: 12px">{{itemss.sc * itemss.dpc * items.pc}}</div>
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
                      <el-checkbox  v-model="item.checked" 
                      :disabled="item.back"
                      @change="changeCheckBoxHandle('item', item)">{{i + 1}}</el-checkbox>
                    </div>
                    <div class="td" layout="row" layout-align="start center">
                      <span class="red" v-if="item.back">退</span>
                      <span class="blue" v-if="item.l>0">锁</span>
                      <span class="green" v-if="item.at==2">惠</span>
                      <span class="green" v-if="item.at==3"><span style="display:block;transform:scale(0.7)">惠2</span></span>
                    </div>
                    <div class="td">{{item.productInfo.name}}</div>
                    <div class="td" :class="{'opacity':item.back}">{{item.pc}}</div>
                    <div class="td" :class="{'opacity':item.back}"><span class="fc-price-stack"><del v-if="!item.back && fcOrderOriginal(item, getDisplayPrice(item))" class="fc-original-price">{{ fcOriginalText(item) }}</del><span>{{ getDisplayPrice(item) }}</span></span></div>
                    <div
                      class="td"
                      :class="{'opacity':item.back}"
                    ><span class="fc-price-stack"><del v-if="!item.back && item.at != 2 && item.at != 3 && fcSubtotalOriginal(item, getSubtotal(item))" class="fc-original-price">{{ fcOriginalSubtotal(item).toFixed(2) }}</del><span>{{ getSubtotal(item) }}</span></span></div>
                    <div
                      class="td"
                      :class="{'opacity':item.back}"
                    >{{item.personInfo ? item.personInfo.name : '自助'}}</div>
                    <div class="td" :class="{'opacity':item.back}">{{item.ot.slice(7)}}</div>
                  </div>
                  <!-- 线下套餐明细 -->
                  <div v-if="item.is==1&&(!item.back)">
                    <div class="detail-list tr" v-for="(items,i) in item.si" :key="i">
                      <div class="td"></div>
                      <div class="td"></div>
                      <div
                        class="td one-txt-cut name"
                      >{{items.groupInfo.name}}{{items.r ? '（'+items.r+'）':''}}</div>
                      <div class="td" style="font-size: 12px">{{items.sc * items.dpc * item.pc}}</div>
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
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import payOrderPriceMixin from "./payOrderPriceMixin";
import api_money from "@/api/money";
import api_order from "@/api/order";
import common_book from "@/utils/common/book";
import common_order from "@/utils/common/order";
export default {
  mixins: [payOrderPriceMixin],
  data() {
    return {
      tabIndex: 1,  // tab选中下标
      checkAll: false,
      originTableData: [], // 元数据
      tableData: []
    };
  },
  methods: {
    async getTableData(){
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1   //  int64 卡台Id
      }
      try {
        const res = await api_order.reqGetPayOrderList(params)
        if(res.code == 1) {
            // 线上未结账订单
          let onlineNotPayOrderList = res.data.oos || []
            onlineNotPayOrderList.forEach(el => {
              el.os.forEach(ele => {
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
                  ele.si.forEach(element => {
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
            let anotherNotPayOrderList = res.data.os || []
            anotherNotPayOrderList.forEach(el => {
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
              if (el.is == 1 && el.si)
                el.si.forEach(ele => {
                  ele.groupInfo = common_order.getProductInfoFromGroup(ele.dpi);
                });
            });

            anotherNotPayOrderList = anotherNotPayOrderList.sort(
              (a, b) => b.orderTime * 1 - a.orderTime * 1
            );

            console.log('onlineNotPayOrderList, anotherNotPayOrderList', onlineNotPayOrderList, anotherNotPayOrderList)
            // 处理未支付订单数据
            this.getOrderDetailInfo([
              ...anotherNotPayOrderList,
              ...onlineNotPayOrderList
            ]);

        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('获取未支付订单列表请求失败', error);
      }
    },

        // 获取未付款订单列表
    /**
     * @params{
     * res:后台请求的数据，用于获取订单支付次数tab，有此参数代表第一次获取（即处理未支付订单），无此参数代表获取已支付订单
     * orderInfoList:支付订单信息列表
     * }
     */
    getOrderDetailInfo(orderInfoList) {
      // 未付款订单处理退单数据
      let resultNotPayData = [];
      if (orderInfoList && orderInfoList.length > 0) {
        orderInfoList.forEach(el => {
          if (el.oid) {
            // 线上订单
            el.os = el.os || [];
            el.resultNotPayData = []; // 当前订单打包的子项商品信息列表
            el.os.forEach(ele => {
              if (ele.bs) {
                // 有退单
                ele.bs.forEach(element => {
                  element.back = true;
                  element.parentOrderId = ele.id;
                  for (let key in ele) {
                    if (key != "bs")
                      // ele[key] = ele[key] && key != "si" ? ele[key] : el[key];
                      element[key] = element[key] ? element[key] : ele[key];
                    if (key == "si" && element[key]) {
                      element.si.forEach(elements => {
                        elements.groupInfo = common_order.getProductInfoFromGroup(
                          elements.dpi
                        );
                      });
                    }
                  }
                });

                if (ele.pc != 0) {
                  // 部分退单
                  el.resultNotPayData.push(ele);
                } 
                ele.bs.forEach(e => {
                  e.opc = ele.pc;
                });
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
              el.bs.forEach(ele => {
                ele.back = true;
                ele.parentOrderId = el.id;
                for (let key in el) {
                  if (key != "bs")
                    // ele[key] = ele[key] && key != "si" ? ele[key] : el[key];
                    ele[key] = ele[key] ? ele[key] : el[key];
                  if (key == "si" && ele[key]) {
                    ele.si.forEach(element => {
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
              el.bs.forEach(e => {
                  e.opc = el.pc;
                });
              resultNotPayData.push(...el.bs);
            } else {
              resultNotPayData.push(el);
            }
          }
        });
      }
      // 应用权限过滤
      const filteredData = this.applyPermissionFilter(resultNotPayData);
      
      this.originTableData = filteredData
      this.tableData = this.originTableData.map(item => ({
        ...item,
        checked: !item.oid
      }))

      this.sortOrderHandle()
    },

    // 应用权限过滤（与 myOrder 页面逻辑一致）
    applyPermissionFilter(resultData) {
      const userInfo = this.$store.state.userInfo;
      
      // 检查是否有全场赠送权限
      const hasFullVenueGiftPermission = userInfo.sys_modules && userInfo.sys_modules.includes(12);
      
      // 检查全场赠送权限的子权限
      let canViewCurrentTableConsumption = true; // 默认可以查看当台消费
      if (hasFullVenueGiftPermission) {
        // 检查是否有"可查看当台消费"权限
        canViewCurrentTableConsumption = userInfo.sys_modules && userInfo.sys_modules.includes(98);
      }
      
      // 【优先级最高】如果配置了"全场赠送 + 不可查看当台消费"，只显示本人点单的订单
      const hasCannotViewPermission = hasFullVenueGiftPermission && !canViewCurrentTableConsumption;
      
      if (hasCannotViewPermission) {
        console.log("买单页面应用权限过滤：只显示本人点单的订单");
        // 只显示本人点单的订单
        return resultData.filter(el => {
          // 线上订单特殊处理
          if (el.oid && el.resultNotPayData) {
            // 线上订单包含多个子订单，过滤掉非本人点单的子订单
            el.resultNotPayData = el.resultNotPayData.filter(item => item.wei == userInfo.emp_id);
            // 如果过滤后还有订单，保留这个线上订单
            return el.resultNotPayData.length > 0;
          } else {
            // 线下订单直接过滤
            return el.wei == userInfo.emp_id;
          }
        });
      }
      
      // 如果没有特殊权限限制，返回所有订单
      return resultData;
    },

    // 订单排序
    sortOrderHandle(){
      const ownOrderList = this.tableData.filter(item => item.wei == this.$store.state.userInfo.emp_id).sort((a, b) => b.orderTime - a.orderTime)
      const customOnlineOrderList = this.tableData.filter(item => item.oid || item.io == 1).sort((a, b) => b.orderTime - a.orderTime)
      const anotherPersonOrderList = this.tableData.filter(item => (item.wei != this.$store.state.userInfo.emp_id) && !(item.oid || item.io == 1)).sort((a, b) => b.orderTime - a.orderTime)
      this.tableData = [...ownOrderList, ...customOnlineOrderList, ...anotherPersonOrderList]
      this.$forceUpdate()
    },

    // 改变tab
    changeTabIndexHandle(index){
      this.tabIndex = index
      if(index == 1) {
        // 勾选全部未结
        this.tableData = this.originTableData.map(item => ({
          ...item,
          checked: !item.oid
        }))

      } else if (index == 2) {
        // 勾选我的未结
        this.tableData = this.originTableData.map(item => ({
          ...item,
          checked: item.wei == this.$store.state.userInfo.emp_id
        }))
        this.tableData.filter(item => item.back).forEach(item => {
          let parent = this.tableData.find(i => i.id == item.parentOrderId)
          item.checked = parent && parent.checked
        })

      } else if (index == 3) {
        // 勾选我和客人未结
        this.tableData = this.originTableData.map(item => ({
          ...item,
          checked: item.wei == this.$store.state.userInfo.emp_id || (!item.oid && item.io == 1)
        }))
        this.tableData.filter(item => item.back).forEach(item => {
          let parent = this.tableData.find(i => i.id == item.parentOrderId)
          item.checked = parent && parent.checked
        })
      }
      
      this.sortOrderHandle()
    },

    changeCheckBoxHandle(type, itemInfo){
      switch (type) {
        // case 'all': 
        //   this.tableData = this.tableData.map(item => ({
        //     ...item,
        //     checked: this.checkAll
        //   }))
        //   break
        case 'item': 
          if(itemInfo.oid) {
            itemInfo.checked = false
            this.$message.warning('线上支付订单无法线下结账')
          }
          this.tableData.filter(item => item.back).forEach(item => {
            let parent = this.tableData.find(i => i.id == item.parentOrderId)
            if(parent) {
              item.checked = parent.checked
            }
          })
          this.checkAll = this.tableData.every(item => item.checked)
          break
      }
    },

    onSubmit() {
      const selectedOrderIdList = []
      this.tableData.forEach(el => {
        if((el.checked && el.opc != 0) && !el.oid) {
          // 勾选的非线上订单
          if(el.back && el.parentOrderId) {
            // 退单商品
            selectedOrderIdList.push(el.parentOrderId)
          } else {
            selectedOrderIdList.push(el.id)
          }
        }
      })
      // 去重
      const resultSelectedOrderIdList = [...new Set(selectedOrderIdList)]
      if(resultSelectedOrderIdList.length <= 0) return this.$message.warning('请选择需要结账的订单')
      this.$emit('setNeedPayOrderIdHandle', resultSelectedOrderIdList)
      this.onCancelDrawer()
    },
    onCancelDrawer() {
      this.show = false;
    },
    // 继续支付处理
    async continuePayHandle() {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1
      }
      
      try {
        const res = await api_order.do_continue_waiter_olpay_with_orders(params)
        if(res.code == 1) {
          // 设置支付类型为微信小程序自助
          this.payType = 3
          
          // 构造支付信息
          this.orderInfoDetail = {
            ol_pay_id: res.data.ol_pay_id,
            pay_amt: res.data.pay_amt,
            pay_url: res.data.pay_url,
            force: 2
          }
          
          // 关闭当前抽屉
          this.onCancelDrawer()
          
          // 通知父组件显示支付二维码
          this.$emit('showPayQRDrawer', {
            payType: this.payType,
            orderInfoDetail: this.orderInfoDetail
          })
        } else {
          this.$message.warning(res.msg)
        }
      } catch(error) {
        console.log('继续支付失败:', error)
        this.$message.error('继续支付失败')
      }
    },
  },
  created() {},
  mounted() {},
  props: {
    value: {
      default: false
    }
  },
  computed: {
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      }
    },
    isIndeterminate(){
      return !this.checkAll && this.tableData.some(item => item.checked)
    }
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.tabIndex = 1
          this.getTableData();
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang='less'>
@import "../../style/common/newElementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/newElementFormBtn.less";
@import "../../style/common/scrollBar.less";
@import "../../style/order/orderMeal/newDrawerShowOrderList.less";

.fc-price-stack { display: inline-flex; flex-direction: column; align-items: flex-end; line-height: 1.2; }
.fc-original-price { color: #9299a8; font-size: 12px; text-decoration: line-through; }
</style>
<style scoped lang='less'>
.session {
  color: rgba(255, 255, 255, 0.8);

}
</style>