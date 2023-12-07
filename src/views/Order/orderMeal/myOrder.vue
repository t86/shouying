<template>
  <!-- 我的点单 -->
  <div class="my-order">
    <div class="my-order-content" :class="{ rect: !isRect }">
      <div class="my-order-content-top">
        <div class="thead">
          <div class="tr">
            <div class="th">状态</div>
            <div class="th">名称</div>
            <div class="th">数量</div>
            <div class="th">单价(元)</div>
            <div class="th">小计(元)</div>
            <div class="th">服务员</div>
            <div class="th">点单时间</div>
            <div class="th">优惠人</div>
            <div class="th">操作</div>
          </div>
        </div>
        <div class="tbody">
          <div
            class="coll"
            v-for="item in orderList"
            :key="item.id"
            :class="{ online: item.io == 1 }"
          >
            <div class="detail tr">
              <div class="td" layout="row" layout-align="start center">
                <span class="purple" v-if="item.s == 5">结</span>
                <span class="blue" v-if="item.l > 0">锁</span>
                <span class="red" v-if="item.back">退</span>
                <span
                  class="red"
                  v-if="item.s == 21"
                  style="width: 50px; border-radius: 10px"
                  >退单中</span
                >
                <span class="green" v-if="item.at == 2">惠</span>
                <span class="green" v-if="item.at == 3"
                  ><span style="display: block; transform: scale(0.7)"
                    >惠2</span
                  ></span
                >
                <!-- <span class="blue" v-if="item.at==6">自</span> -->
              </div>
              <div class="td" :class="{ opacity: item.back }">
                <div class="p one-txt-cut">{{ item.productInfo.name }}</div>
                <div class="p english-name one-txt-cut">
                  {{ item.productInfo.nameEng }}
                </div>
              </div>
              <div class="td" :class="{ opacity: item.back }">
                {{ item.pc }}
              </div>
              <div class="td" :class="{ opacity: item.back }">
                {{ item.pp }}
              </div>
              <div class="td" :class="{ opacity: item.back }">
                {{ item.at == 2 || item.at == 3 ? "0.00" : item.pa }}
              </div>
              <div class="td" :class="{ opacity: item.back }">
                {{ item.personInfo && item.personInfo.name }}
              </div>
              <div class="td" :class="{ opacity: item.back }">
                {{ item.ot.slice(7) }}
              </div>
              <div class="td" :class="{ opacity: item.back }">
                {{ item.authInfo ? item.authInfo.name : "---" }}
              </div>
              <div class="td">
                <!-- <div class="bg" v-if="item.showList" @click="showOrHideList(item)"></div> -->
                <img
                  v-if="
                    (item.s != 5 && !item.back) || item.productInfo.prdType == 2
                  "
                  :src="imgSrc.shoppingCarMore"
                  @click.stop="showOrHideList(item)"
                  alt
                />
                <img
                  :src="imgSrc.sanJiao"
                  v-if="
                    item.showList &&
                    (!item.back || item.productInfo.prdType == 2)
                  "
                  class="sanJiao"
                  alt
                />
                <div
                  class="do-list"
                  v-if="
                    item.showList &&
                    (!item.back || item.productInfo.prdType == 2)
                  "
                >
                  <div
                    class="li"
                    v-if="item.s != 5 && !item.back && hasOrderBackAuth"
                    @click.stop="showOrHideDrawer(1, item)"
                  >
                    退单
                  </div>
                  <div
                    class="li"
                    v-if="
                      item.productInfo.prdType == 2 &&
                      !item.back &&
                      hasChangeDetailAuth
                    "
                    @click.stop="showOrHideDrawer(4, item)"
                  >
                    更改套餐明细
                  </div>
                  <div
                    class="li"
                    v-if="item.productInfo.prdType == 2 && item.back"
                    @click.stop="showOrHideDrawer(5, item)"
                  >
                    查看套餐明细
                  </div>
                </div>
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
                <div class="td">{{ items.s * items.c * item.pc }}</div>
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
            <!-- 补单信息 -->
            <div v-if="item.rl" class="requested">{{ item.rl }}</div>
          </div>
        </div>
      </div>

      <div
        class="my-order-content-bottom"
        layout="row"
        layout-align="space-between center"
      >
        <div class="amt" layout="row">
          <div class="p m-r-5" layout="row" layout-align="start center">
            <span>点单金额：</span>
            <span class="num">￥{{ amt.allAmt }}</span>
          </div>
          <div class="p m-r-5" layout="row" layout-align="start center">
            <span>优惠金额：</span>
            <span class="num">￥{{ amt.giveAmt }}</span>
          </div>
          <div class="p" layout="row" layout-align="start center">
            <span>未结账金额：</span>
            <span class="num">￥{{ amt.notPayAmt }}</span>
          </div>
        </div>
        <div class="btn" layout="row" layout-align="end center">
          <button @click.stop="showOrHideDrawer(6, item)">批量优惠</button>
          <button @click.stop="showOrHideDrawer(7, item)">批量优惠2</button>
          <button @click.stop="showOrHidePrintDrawer">打印消费单</button>
        </div>
      </div>
    </div>

    <!-- 赠送、自用、退单等drawer -->
    <drawerMyOrder
      ref="drawerMyOrder"
      :status="drawer.status"
      :showDrawer="drawer.showDrawer"
      :currentItemInfo="drawer.currentItemInfo"
      :orderList="orderList"
      @showOrHideDrawer="showOrHideDrawer"
    />

    <!-- 打印消费单 -->
    <drawerPrintOrder
      ref="drawerPrintOrder"
      pageType="myOrder"
      :showDrawer="showPrintDrawer"
      @showOrHidePrintDrawer="showOrHidePrintDrawer"
    />
  </div>
</template>

<script>
import eventVue from "@/utils/eventVue";

import api_order from "@/api/order";
import common_order from "@/utils/common/order";
import common_book from "@/utils/common/book";

import add from "@/assets/order-img/order_add.png";
import sub from "@/assets/order-img/sub.png";
import addDisabled from "@/assets/order-img/add-disabled.png";
import subDisabled from "@/assets/order-img/sub-disabled.png";
import shoppingCarMore from "@/assets/order-img/shoppingCarMore.png";
import sanJiao from "@/assets/card-imgs/cardOptions/sanjiao.png";

import drawerMyOrder from "@/components/order/myOrder/drawerMyOrder";
import drawerPrintOrder from "@/components/order/myOrder/drawerPrintOrder";

// 键盘码 keycode
let downKeyCode = [0, 0];
const ctrlAndShiftCode = [17, 16];

export default {
  data() {
    return {
      isRect: true, // 是否为横屏
      orderList: [], // 订单列表数据
      updateDetail: {
        // 修改套餐明细
        productItemInfo: {}, // 当前被修改的套餐总信息
        groupList: [], // 修改套餐明细列表
        showDialog: false,
      },
      drawer: {
        showDrawer: false,
        status: 1, // 1：退单 2：赠送  3：自用
        currentItemInfo: {}, // 当前正在操作的商品信息
      },
      showPrintDrawer: false, // 是否显示打印消费单drawer
      amt: {
        allAmt: "0.00", // 点单金额
        giveAmt: "0.00", // 赠送金额
        notPayAmt: "0.00", // 未付金额
      },
      imgSrc: {
        add,
        sub,
        addDisabled,
        subDisabled,
        shoppingCarMore,
        sanJiao,
      },
    };
  },
  methods: {
    // 是否显示操作下拉框选项
    showOrHideList(info) {
      const index = this.orderList.findIndex((el) => el.id == info.id);
      this.orderList.forEach((el, i) => {
        el.showList = index == i ? !el.showList : false;
        el.isOnline = el.io == 1;
      });
    },

    // 获取已下单列表数据
    async getOrderedData() {
      try {
        let bizData = this.$store.state.cardPageInfo.resResultDataObj["businessData"];
        let biz = bizData.find(item => item.seatId == this.$store.state.orderInfo.currentCardInfo.seatId)
       console.log('biz', biz)
        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
          turnover_cnt: biz.turnoverCnt * 1
        };
        const res = await api_order.reqGetOrderList(params);
        if (res.code === 1) {
          this.amt.allAmt = ((res.data.pay_info.order_amt || 0) / 100).toFixed(2);
          this.amt.giveAmt = ((res.data.pay_info.yh_amt || 0) / 100).toFixed(2);
          this.amt.notPayAmt = ((res.data.pay_info.order_amt || 0 - res.data.pay_info.payed_amt || 0) / 100).toFixed(2);
          const data = res.data.records || [];
          data.forEach((el) => {
            el.productInfo = common_order.getProductInfo(el.pid);
            el.personInfo =
              el.wei == 0
                ? { name: "自助" }
                : common_book.getOrderPersonInfo(el.wei);
            el.authInfo = common_book.getOrderPersonInfo(el.ae);
            el.showList = false;
            if (el.is == 1)
              el.si.forEach((ele) => {
                ele.groupInfo = common_order.getProductInfoFromGroup(ele.i);
              });
          });
          // return console.log(data);
          // 处理退单数据
          const resultData = [];
          data.forEach((el) => {
            if (el.bs) {
              // 有退单
              el.bs.forEach((ele) => {
                ele.back = true;
                for (let key in el) {
                  if (key != "bs")
                    // ele[key] = ele[key] && key != "si" ? ele[key] : el[key];
                    ele[key] = ele[key] ? ele[key] : el[key];
                  if (key == "si" && ele[key]) {
                    ele.si.forEach((element) => {
                      element.groupInfo = common_order.getProductInfoFromGroup(
                        element.i
                      );
                    });
                  }
                }
              });

              if (el.pc != 0) resultData.push(el); // 部分退单
              resultData.push(...el.bs);
            } else {
              resultData.push(el);
            }
          });
          console.log("未权限过滤的信息",resultData)
          // const authList = [];
          // for(let i = 0;i<resultData.length;i++){
          //   let el = resultData[i]
          //   if(this.hasLookOrder){
          //     authList.push(el);
          //     continue
          //   }
          //   // 自己的 先添加
          //   if (el.wei == this.$store.state.userInfo.emp_id) {
          //     authList.push(el);
          //     continue
          //   }
          //   // 权限限制只能看自己的 非自己的返回
          //   if (this.hasOnlyLookSelf) {
          //     continue;
          //   }
          //   // 下属的
          //   if (
          //     !this.hasOnlyLookSelf &&
          //     this.loginUserSubordinateIds.includes(el.wei)
          //   ) {
          //     authList.push(el);
          //     continue;
          //   }
            
          //   // 能看同组的 非同组的返回
          //   const upper_emp_id = el.personInfo&&el.personInfo.upper_emp_id || ''
          //   if ( this.hasCanLookDept &&
          //     this.loginUserInfo.upper_emp_id == upper_emp_id && upper_emp_id != 0 ){
          //       authList.push(el);
          //   } 
          // }
          // this.orderList = authList;
          this.orderList = resultData;
        } else if (res.code == 2) {
          console.log("当前人员未参与当前卡台点单");
          this.orderList = [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("点单列表获取失败", error);
      }
    },

    showOrHidePrintDrawer() {
      this.showPrintDrawer = !this.showPrintDrawer;
    },

    // 显示drawer
    showOrHideDrawer(status, objInfo = {}) {
      this.drawer.showDrawer = !this.drawer.showDrawer;
      if (!objInfo && status < 6) return;
      this.showOrHideList(objInfo);

      // status 1：退单 2：优惠  3：自用  4：修改套餐明细  5：查看套餐明细  6：批量优惠  7：批量优惠2
      this.drawer.status = status;
      this.drawer.currentItemInfo = objInfo;
    },

    // 检测是否为横屏
    getRectVal() {
      const width = screen.availWidth;
      const height = screen.availHeight;
      this.isRect = width >= height;
    },

    // 收银快捷键
    keyHandle(e) {
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
            if (downKeyCode[0] == 17 && downKeyCode[1] == 81) {
              //  ctrl + q  // 返回收银首页
              e.preventDefault();
              this.$router.replace({ name: "moneyCard" });
            } else if (downKeyCode[0] == 16 && downKeyCode[1] == 65) {
              // shift + a // 商品菜单
              e.preventDefault();
              this.$parent.$refs.footBarRef &&
                this.$parent.$refs.footBarRef.footNavBarClick &&
                this.$parent.$refs.footBarRef.footNavBarClick({
                  id: 2,
                  name: "商品菜单",
                  routeName: "orderMealList",
                });
            } else if (downKeyCode[0] == 16 && downKeyCode[1] == 83) {
              // shift + s  // 购物车
              e.preventDefault();
              this.$parent.$refs.footBarRef &&
                this.$parent.$refs.footBarRef.footNavBarClick &&
                this.$parent.$refs.footBarRef.footNavBarClick({
                  id: 3,
                  name: "商品菜单",
                  routeName: "shoppingCart",
                });
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 122) {
              // ctrl + f11  // 打印消费单
              e.preventDefault();
              this.printOrderList();
            }
          });
          break;

        case "keyup":
          const index = downKeyCode.findIndex((item) => item == e.keyCode);

          if (index > -1) downKeyCode[1] = 0;

          if (ctrlAndShiftCode.includes(e.keyCode)) downKeyCode = [0, 0];

          break;
      }
    },

    // 点单快捷键
    keydownHandle(e) {
      if (e.keyCode == 13) {
        this.$nextTick(() => {
          if (this.drawer.showDrawer) {
            // 赠送、自用、退单等drawer
            this.$refs.drawerMyOrder.onSubmit();
          } else if (this.showPrintDrawer) {
            // 打印消费单
            this.$refs.drawerPrintOrder.onSubmit();
          }
        });
      }
    },
  },
  created() {
    setTimeout(() => {
      if (this.$store.state.userInfo.authStatus == 4) {
        document.onkeydown = this.keyHandle;
        document.onkeyup = this.keyHandle;
      } else {
        document.onkeydown = this.keydownHandle;
      }
    }, 200);
  },
  mounted() {
    this.getRectVal();
    this.getOrderedData();
    eventVue.$on("reloadMyOrderTableData", () => {
      this.getOrderedData();
    });
    document.body.addEventListener("click", this.showOrHideList);
  },
  components: {
    drawerMyOrder,
    drawerPrintOrder,
  },
  beforeDestroy() {
    document.body.removeEventListener("click", this.showOrHideList);
    eventVue.$off("reloadMyOrderTableData")
    document.onkeydown = null;
    document.onkeyup = null;
    downKeyCode = [0, 0];
  },
  computed: {
    // 是否退单权限
    hasOrderBackAuth() {
      return (
        this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(3)
      );
    },
    // 是否有替换商品明细权限
    hasChangeDetailAuth() {
      return (
        this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(4)
      );
    },
  // 是否有查单权限
    // hasLookOrder() {
    //   return (
    //     this.$store.state.userInfo.roleIds &&
    //     this.$store.state.userInfo.roleIds.includes(11)
    //   );
    // },
    // // 不允许查看下属点单消费  只能看自己
    // hasOnlyLookSelf() {
    //   return (
    //     (this.$store.state.userInfo.sys_modules &&
    //       this.$store.state.userInfo.sys_modules.includes(6)) ||
    //     this.$store.state.userInfo.sys_modules.includes(10)
    //   );
    // },

    // //能查看同组点单消费
    // hasCanLookDept() {
    //   return (
    //     this.$store.state.userInfo.sys_modules &&
    //     (this.$store.state.userInfo.sys_modules.includes(7) ||
    //       this.$store.state.userInfo.sys_modules.includes(11))
    //   );
    // },

    // // 当前用户信息
    // loginUserInfo() {
    //   return this.$store.state.userInfo;
    // },
    // // loginUser 下属列表
    // loginUserSubordinateIds() {
    //   const orderPersonInfo =
    //     this.$store.state.cardPageInfo.resResultDataObj["orderPersonInfo"] ||
    //     [];
    //   const subordinateList = orderPersonInfo.filter(
    //     (item) => item.upper_emp_id == this.loginUserInfo.emp_id
    //   );
    //   const ids = subordinateList.map((d) => d.id);
    //   return ids;
    // },
  },
};
</script>

<style scoped lang="less">
@import "../../../style/order/orderMeal/myOrder/myOrder.less";
</style>
