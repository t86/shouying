<template>
  <div class="footBar" :class="{ rect: !isRect }" :layout="isRect ? 'row' : 'column'"
    :layout-align="isRect ? 'space-between center' : 'start center'">
    <div style="width: 100%" :layout="isRect ? 'row' : 'column'" :layout-align="isRect ? 'start center' : 'start start'">
      <div style="margin-bottom: -2px; width: 100%; display: flex; " :layout="isRect ? 'row' : 'column'"
        :layout-align="isRect ? 'start center' : 'start start'">
        <div style="flex: 1" class="ul" layout="row" layout-align="start center">
          <div class="li line" v-for="(item, index) in navList" :key="index"
            :class="{ active: item.routeName === activeRouteName }" @click="footNavBarClick(item)">
            <div class="shopping-count" v-if="
              item.id === 3 &&
              $store.state.orderInfo.shoppingCartInfo.shoppingCount
            ">
              {{ $store.state.orderInfo.shoppingCartInfo.shoppingCount }}
            </div>
            <img width="20" :src="item.routeName === activeRouteName ? item.activeIcon : item.icon" alt />
            <img class="sanJiao" v-if="item.routeName === activeRouteName" :src="item.icon1" alt />
            <p>{{ item.name }}</p>
          </div>
          <!-- 督查 特饮 服务员买单结账按钮 -->
          <div v-if="
            isShowPayBtn && cardInfo.orderAmt - cardInfo.payedAmt > 0
          " class="server-pay-btn">
            <div class="button" layout="row" layout-align="center center" @click="showOrderListDrawerHandle">
              <img :src="imgSrc.orderQRPayIcon" alt />
              <span>买单</span>
            </div>
          </div>
          <!-- 服务员充值滞留金 -->
          <div v-if="
            isShowPayBtn
          " class="server-pay-btn line">
            <div class="button" layout="row" layout-align="center center" @click="showAddBookDrawer = true">
              <img :src="imgSrc.zhiliujin" alt />
              <span>滞留金</span>
            </div>
          </div>
          <!-- 收银系统按钮 -->
          <div class="pay-btn line" :style="isNarrowWidth && 'padding: 0px 0px'" v-if="
            $store.state.userInfo.authStatus == 4 &&
            !this.$route.path.startsWith('/orderMeal') &&
            $store.state.orderInfo.currentCardInfo.bizStatus != 1
          " layout="row">
            <div class="button" layout="row" layout-align="center center"
              @click="$router.push({ name: 'orderMealList' })">
              <img :src="imgSrc.shoppingNav" alt />
              <span>点单</span>
            </div>
            <!-- <div
          class="button"
          @click="$router.push({name:'orderMealList', query:{give:true}})"
          layout="row"
          layout-align="center center"
        >
          <img :src="imgSrc.giveNav" alt />
          <span>优惠2</span>
        </div> -->
            <div class="button" @click.stop="clearCardHandle" layout="row" layout-align="center center">
              <img :src="imgSrc.clearNav" alt />
              <span>清台</span>
            </div>

            <div class="button" @click.stop="showMerchantConfig = true" style="width: 140px" layout="row"
              layout-align="center center">
              <img :src="require('@/assets/money-img/merchant-btn-icon.png')" alt />
              <span style="transform: translateX(-2px)">滞留金管理</span>
            </div>
          </div>
        </div>
        <div>
          <!-- v-if="
            isRect &&
            ($store.state.userInfo.authStatus == 4 || canLookOrderAmt)
          "  -->
          <!-- 消费情况 -->
          <div class="new-one" v-if="isRect &&
            ($store.state.userInfo.authStatus == 4 || canLookOrderAmt)" style="padding-top: 8px; " layout="row"
            layout-align="start start">
            <p class="new-one-txt-cut">
              <!-- 折前：当太总消费的应收金额（不含赠送） -->
              <span class="new-one-txt-title">折前金额:</span>
              <span class="new-one-txt-price">￥{{ Number(cardInfo.orderAmt || 0).toFixed(2) }}</span>
            </p>
            <p class="new-one-txt-cut">
              <!-- 折后：已结账的金额（包含主营非主营，不含折扣） -->
              <span class="new-one-txt-title ">折后金额:</span>
              <span class="new-one-txt-price payed-val-amt">￥{{ Number(cardInfo.payed_val_amt || 0).toFixed(2) }}</span>
            </p>
            <p class="new-one-txt-cut">
              <!-- 折后：已结账的金额（包含主营非主营，不含折扣） -->
              <span class="new-one-txt-title">主营点单金额:</span>
              <span class="new-one-txt-price order-zy-amt">￥{{ Number(cardInfo.order_zy_amt || 0).toFixed(2) }}</span>
            </p>

            <p class="new-one-txt-cut">
              <!-- 已收：已结账的金额（包含主营非主营，折扣金额） -->
              <span class="new-one-txt-title">已收金额:</span>
              <span class="new-one-txt-price">￥{{ Number(cardInfo.payedAmt || 0).toFixed(2) }}</span>
            </p>
            <p class="new-one-txt-cut">
              <!-- 当台实收：已结账的金额（主营商品已支付的金额，不含折扣） -->
              <span class="new-one-txt-title">当台实收:</span>
              <span class="new-one-txt-price">￥{{
                Number(cardInfo.payed_zy_val_amt || 0).toFixed(2)
              }}</span>
            </p>
          </div>
        </div>
      </div>

      <div layout="row" layout-align="center center" v-if="(!isRect) &&
        ($store.state.userInfo.authStatus == 4 || canLookOrderAmt)">
        <!-- 消费情况 -->
        <div class="new-one" layout="row" layout-align="start start">
          <p class="new-one-txt-cut">
            <!-- 折前：当太总消费的应收金额（不含赠送） -->
            <span class="new-one-txt-title">折前金额:</span>
            <span class="new-one-txt-price">￥{{ Number(cardInfo.orderAmt || 0).toFixed(2) }}</span>
          </p>
          <p class="new-one-txt-cut">
            <!-- 折后：已结账的金额（包含主营非主营，不含折扣） -->
            <span class="new-one-txt-title ">折后金额:</span>
            <span class="new-one-txt-price payed-val-amt">￥{{ Number(cardInfo.payed_val_amt || 0).toFixed(2) }}</span>
          </p>
          <p class="new-one-txt-cut">
            <!-- 折后：已结账的金额（包含主营非主营，不含折扣） -->
            <span class="new-one-txt-title">主营点单金额:</span>
            <span class="new-one-txt-price order-zy-amt">￥{{ Number(cardInfo.order_zy_amt || 0).toFixed(2) }}</span>
          </p>

          <p class="new-one-txt-cut">
            <!-- 已收：已结账的金额（包含主营非主营，折扣金额） -->
            <span class="new-one-txt-title">已收金额:</span>
            <span class="new-one-txt-price">￥{{ Number(cardInfo.payedAmt || 0).toFixed(2) }}</span>
          </p>
          <p class="new-one-txt-cut">
            <!-- 当台实收：已结账的金额（主营商品已支付的金额，不含折扣） -->
            <span class="new-one-txt-title">当台实收:</span>
            <span class="new-one-txt-price">￥{{
              Number(cardInfo.payed_zy_val_amt || 0).toFixed(2)
            }}</span>
          </p>
        </div>

      </div>
      <!-- 暂不支付倒计时退出 -->
      <div class="num-sub-tips" v-show="showNumSubTips">
        <div class="contain">
          <i class="el-icon-close" style="
                                    position: absolute;
                                    top: 10px;
                                    right: 20px;
                                    color: #fff;
                                    cursor: pointer;
                                  " @click="hideTimeSubHandle()"></i>
          {{ logoutCount }}秒后将退出登录！
        </div>
      </div>

      <!-- 选择支付渠道方式 -->
      <div class="choose-pay-type" v-show="showChoosePayType">
        <div class="contain">
          <div class="top" layout="row" layout-align="space-between center">
            <div>选择支付方式</div>
            <i class="el-icon-close cursor" style="color: #fff" @click="showChoosePayType = false"></i>
          </div>

          <div class="center" layout="row" layout-align="start center">
            <div class="choose" :class="{ active: payType == item.id }" v-for="item in payTypeList" :key="item.id"
              @click="payType = item.id">
              <img :src="item.icon" style="height: 25px; width: 25px; vertical-align: middle" alt="" />
              <span style="vertical-align: middle">{{ item.name }}</span><span v-if="[5, 6].includes(item.id)"
                style="margin-left: 4px; vertical-align: middle; color: red">(推荐)</span>
            </div>
          </div>

          <div class="bottom" layout="row" layout-align="center center">
            <div class="button info cursor" @click="showChoosePayType = false">
              取消
            </div>
            <div class="button primary cursor" @click="getPayQRCode(2)">
              确定
            </div>
          </div>
        </div>
      </div>

      <!-- 扫码输入支付码 -->
      <div class="scan_input" v-if="scanStart">
        <div class="contain">
          <div class="top center" layout="row" layout-align="space-between center">
            <input style="width: 260px" v-model="scanCode" class="value focus" size="small" placeholder="请输入支付码" />
          </div>
          <div class="m-t-6">
            <keyBoard @changeNum="changeCode" />
          </div>
          <div class="bottom" layout="row" layout-align="center center">
            <div class="button info cursor" @click="onCancelScan">取消</div>
            <div class="button primary cursor" @click="onSubmitScan">确定</div>
          </div>
        </div>
      </div>
      <!-- 服务员买单选择商品列表 -->
      <drawerOrderList v-show="showOrderListDrawer" v-model="showOrderListDrawer"
        @setNeedPayOrderIdHandle="setNeedPayOrderIdHandle" />

      <!-- 客人扫码支付订单费用/扫码支付订单 -->
      <drawerPayQR :showDrawer="showOrHideQRDrawer" :payType="payType" :orderInfoDetail="orderInfoDetail"
        @showOrHideQRDrawerHandle="showOrHideQRDrawerHandle" @subSecondLogoutHandle="subSecondLogoutHandle"
        @reloadQrRequest="showChoosePayTypeHandle" />

      <!-- 服务员让客人扫码添加滞留金 -->
      <!-- 此处在打开drawer之前，会影响flex布局，因此需要添加一个v-show -->
      <drawerAddBookAmt v-if="showAddBookDrawer" v-model="showAddBookDrawer"
        @subSecondLogoutHandle="subSecondLogoutHandle" />

      <!-- 收银系统滞留金管理 -->
      <!-- 此处在打开drawer之前，会影响flex布局，因此需要添加一个v-show -->
      <drawerMerchantConfig v-show="showMerchantConfig" v-model="showMerchantConfig" />
    </div>
  </div>
</template>

<script>
import common_book from "@/utils/common/book";
import eventVue from "@/utils/eventVue";
import api_auth from "@/api/UtilAuth";
import api_order from "@/api/order";
import api_money from "@/api/money";

import drawerPayQR from "./drawerPayQR.vue";

import goBack from "@/assets/order-img/newBack.png";
import shoppingNav from "@/assets/order-img/newShoppingNav.png";
import shoppingNavActive from "@/assets/order-img/shoppingNavActive.png";
import myselfNavActive from "@/assets/order-img/myselfNavActive.png";
import shoppingCartAcive from "@/assets/order-img/shoppingCartAcive.png";
import clearNav from "@/assets/money-img/clear.png";
import giveNav from "@/assets/money-img/give.png";
import choosedNav from "@/assets/money-img/choosedNav.png";
import shoppingCart from "@/assets/order-img/newShoppingCart.png";
import myselfNav from "@/assets/order-img/newMyselfNav.png";
import orderQRPayIcon from "@/assets/order-img/newOrderQRPayIcon.png";
import zhiliujin from "@/assets/order-img/zhiliujin.png";
import sanJiao from "@/assets/order-img/gengduo_sanjiao.png";

import weixin_kerensaowo from "@/assets/pay-img/weixin_kerensaowo.png";
import weixin_saokeren from "@/assets/pay-img/weixin_saokeren.png";
import weixinxiaochengxu from "@/assets/pay-img/weixinxiaochengxu.png";
import zhifubao_kerensaowo from "@/assets/pay-img/zhifubao_kerensaowo.png";
import zhifubaozhifu_saokeren from "@/assets/pay-img/zhifubaozhifu_saokeren.png";

const orderNavList = [
  {
    id: 1,
    name: "返回首页",
    icon: goBack,
    activeIcon: goBack
  },
  {
    id: 2,
    name: "商品菜单",
    routeName: "orderMealList",
    icon: shoppingNav,
    activeIcon: shoppingNavActive
  },
  {
    id: 3,
    name: "购物车",
    routeName: "newShoppingCart",
    icon: shoppingCart,
    icon1: sanJiao,
    activeIcon: shoppingCartAcive
  },
  {
    id: 4,
    name: "我的点单",
    routeName: "myOrder",
    icon: myselfNav,
    icon1: sanJiao,
    activeIcon: myselfNavActive
  },
];
const payNavList = [
  {
    id: 1,
    name: "返回首页",
    icon: goBack,
  },
];

const payTypeList =
  window.atool &&
    ("startScan" in window.atool || window.atool.getTermType() == "android")
    ? [
      {
        id: 6,
        icon: weixin_saokeren,
        name: "扫客人-微信",
      },
      {
        id: 5,
        icon: zhifubaozhifu_saokeren,
        name: "扫客人-支付宝",
      },
      {
        id: 2,
        icon: weixin_kerensaowo,
        name: "客人扫我-微信",
      },
      {
        id: 1,
        icon: zhifubao_kerensaowo,
        name: "客人扫我-支付宝",
      },
      {
        id: 3,
        icon: weixinxiaochengxu,
        name: "微信小程序自助",
      },
    ]
    : [
      {
        id: 2,
        icon: weixin_kerensaowo,
        name: "客人扫我-微信",
      },
      {
        id: 1,
        icon: zhifubao_kerensaowo,
        name: "客人扫我-支付宝",
      },
      {
        id: 3,
        icon: weixinxiaochengxu,
        name: "微信小程序自助",
      },
    ];

export default {
  data() {
    return {
      canLookOrderAmt: false,

      isRect: window.innerWidth > 1024,
      isNarrowWidth: window.innerWidth < 850,

      activeRouteName: "", // 当前页面的routerName
      navList: [],

      showOrHideQRDrawer: false, // 是否显示付款二维码
      orderInfoDetail: {},

      payType: "",
      showChoosePayType: false, // 选择支付渠道方式

      timer: "", // 暂不支付倒计时退出登录
      showNumSubTips: false, // 暂不支付倒计时退出模态框
      logoutCount: 4, // 暂不支付倒计时秒数

      showOrderListDrawer: false, // 服务员买单显示待买单商品列表
      selectedOrderList: [], // 选择好的服务员买单列表

      showAddBookDrawer: false, // 新增滞留金

      showMerchantConfig: false, // 滞留金管理
      scanStart: false,

      // 扫码支付
      qrResult: null, // 扫码结果

      cardInfo: {},
      scanCode: "",

      imgSrc: {
        orderQRPayIcon,
        shoppingNav,
        giveNav,
        choosedNav,
        clearNav,
        zhiliujin
      },

      payTypeList, // 支付方式
      terminalType: '',
      // 是否收银系统
      isMoneyClient: false,
      // 是否是点单系统
      isOrderMeal: false,
    };
  },
  methods: {
    footNavBarClick(item) {
      if (this.$route.name === item.routeName) return; // 重复点击同一个tab
      item.id === 1
        ? this.$store.state.userInfo.authStatus == 4
          ? this.$router.replace({ name: "moneyCard" })
          : this.$router.replace({ name: "orderCard" })
        : this.$router.replace(
          {
            name: item.routeName,
            query: {
              give: this.$route.query.give,
              mustOrderPrdId: item.mustOrderPrdId,
              mustPrdName: item.mustPrdName,
            },
          },
          () => {
            this.activeRouteName = this.navList[item.id - 1].routeName;
          }
        );
    },

    getAuthInfo() {
      const date = new Date();
      this.authInfo = {
        month: (date.getMonth() + 1).toString().padStart(2, 0),
        day: date.getDate().toString().padStart(2, 0),
        hour: date.getHours().toString().padStart(2, 0),
        minute: date.getMinutes().toString().padStart(2, 0),
        name: this.$store.state.userInfo.name,
      };
    },

    // 清台
    clearCardHandle() {
      this.$confirm("确定要进行清台操作吗？", "清台", {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      })
        .then(async () => {
          try {
            const res = await api_money.reqClearCard({
              seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
            });
            if (res.code === 1) {
              this.$message.success("清台成功");
              this.$router.replace({ name: "moneyCard" });
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log("清台失败", error);
          }
        })
        .catch((e) => "");
    },

    terminal() {
      let termType = "";
      try {
        termType = atool.getTermType();
      } catch (error) {
        console.log("获取终端类型失败", error);
      }
      return termType;
    },
    init() {
      this.isMoneyClient = sessionStorage.getItem("client") == "money"
      this.terminalType = this.terminal()
      this.activeRouteName = this.$route.name;
      if (this.$store.state.userInfo.authStatus == 4) {
        // 查看翻台记录（开台/清台状态下，查看历史消费），更新页面底部的五个金额
        eventVue.$off("changeTurnOverCountHandle");
        eventVue.$on("changeTurnOverCountHandle", (amtInfoList = []) => {
          let orderAmt = 0;
          let payed_val_amt = 0;
          let order_zy_amt = 0;
          let payedAmt = 0;
          let payed_zy_val_amt = 0;

          amtInfoList.forEach((el) => {
            // 折前金额
            orderAmt += el.amts.o * 1;
            // 折后金额
            payed_val_amt += el.amts.pv * 1;
            // 主营点单金额
            order_zy_amt += el.amts.pzv * 1;
            // 已收金额
            payedAmt += el.amts.p * 1;
            // 当台实收
            payed_zy_val_amt += el.amts.pzv * 1;
          });

          this.cardInfo = {
            ...this.cardInfo,
            orderAmt,
            payed_val_amt,
            order_zy_amt,
            payedAmt,
            payed_zy_val_amt,
          };
        });

        // 查看当台记录，更新页面底部的五个金额
        eventVue.$off("changeTurnOverCountNotPayHandle");
        eventVue.$on("changeTurnOverCountNotPayHandle", () => {
          this.cardInfo = this.$store.state.orderInfo.currentCardInfo;
        });
      }
      this.cardInfo = this.$store.state.orderInfo.currentCardInfo;
      this.getAuthInfo();
      this.timer = setInterval(this.getAuthInfo, 30000);
      this.$store.dispatch("getShoppingCount", this);
      this.navList =
        this.$store.state.userInfo.authStatus == 4 &&
          !this.$route.path.startsWith("/orderMeal")
          ? payNavList
          : orderNavList;
      if (
        this.$store.state.userInfo.authStatus == 4 &&
        this.$route.path.startsWith("/orderMeal")
      ) {
        this.navList[0]["name"] = "返回收银";
        this.navList = this.$route.query.give
          ? [this.navList[0], this.navList[1]]
          : [
            this.navList[0],
            this.navList[1],
            this.navList[2],
            this.navList[3],
          ];
      } else {
        this.navList[0]["name"] = "返回首页";
      }

      // 是否为收银系统查看翻台记录
      if (this.$store.state.orderInfo.currentCardInfo.bizStatus != 1)
        this.getOrderedData(); // 通过后台获取当前当前账号是否有查单权限
    },

    // 服务员买单
    showOrderListDrawerHandle() {
      this.showOrderListDrawer = true;
    },

    // 设置选择好的服务员买单列表
    setNeedPayOrderIdHandle(selectedOrderIdList = []) {
      this.selectedOrderIdList = [...selectedOrderIdList];
      this.showChoosePayTypeHandle();
    },

    showChoosePayTypeHandle(scan = 0) {
      this.qrResult = null;
      if (scan == 1) {
        this.getPayQRCode(2);
      } else {
        const that = this;
        this.payType = "";
        this.showChoosePayType = true;
        function scan_callback(value) {
          try {
            console.log("scan_callback:", JSON.stringify(value));
            if (value && value.code === 0) {
              that.qrResult = value.data;
              that.getPayQRCode(1);
            } else {
              that.qrResult = null;
              that.$message.warning("扫码取消");
              that.orderInfoDetail.r = 2;
              // that.showOrHideQRDrawerHandle();
            }
          } catch (error) {
            console.log("扫码失败：", error);
            that.$message.warning("扫码失败：" + error);
          }
        }

        window.scan_callback = scan_callback;
      }
    },

    // 开始扫码
    startScan() {
      console.log("startScan");
      if (window.atool && "startScan" in window.atool) {
        window.atool.startScan("scan_callback");
        // scan_callback({ code: 0, data: "284058227514617549" });
      } else {
        this.scanStart = true;
      }
    },
    onCancelScan() {
      this.scanStart = false;
      this.qrResult = null;
      this.scanCode = "";
    },
    onSubmitScan() {
      this.scanStart = false;
      scan_callback({ code: this.scanCode ? 0 : 1, data: this.scanCode });
      this.scanCode = "";
      this.qrResult = null;
    },
    changeCode(value) {
      switch (value) {
        case 10: // 清空
          this.scanCode = "";
          break;
        case 12: // 回退
          this.scanCode = this.scanCode
            .toString()
            .slice(0, this.scanCode.toString().length - 1);
          break;
        default:
          this.scanCode = this.scanCode.toString() + value;
          break;
      }
    },
    // 获取去买单数据
    async getPayQRCode(force = 2) {
      if (!this.payType) return this.$message.warning("请选择支付方式");

      this.showChoosePayType = false;
      // 5:扫客人-支付宝 6:扫客人-微信   扫码结果为空 调用客户端扫码
      if ([5, 6].includes(this.payType)) {
        if (
          window.atool.getTermType() == "android" &&
          !("startScan" in window.atool)
        ) {
          this.$message.warning("当前版本还不支持, 请联系系统运维人员升级版本");
          return;
        }
        if (force == 2) {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64      //SeatId 卡台Id
            order_ids: this.selectedOrderIdList.map((item) => item * 1), //  []int64   要买单的订单Id列表
          };
          const res = await api_order.reqCheckPayOrder(params);
          if (res.code == 2) {
            const result = await this.showConfirmHandle("买单", res.msg);
            if (result != "confirm") {
              return;
            }
          } else if (res.code != 1) {
            this.$message.warning(res.msg);
            return;
          }
        }
        if (this.qrResult == null) {
          try {
            this.startScan();
          } catch (e) {
            console.log(e);
            this.$message.warning("启动扫码失败，请重试");
          }
          return;
        }
      }
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64      //SeatId 卡台Id
        force: force, //  int   1：强制操作  2：不强制操作, 如果卡台有未结账的线上订单,会返回code=2的特殊错误,用以提示服务员  3:获取未付款订单信息
        pay_type: this.payType * 1, //   int   买单方式: 1 支付宝扫码 2 微信扫码 3 会员微信自助  5:扫客人-支付宝 6:扫客人-微信
        order_ids: this.selectedOrderIdList.map((item) => item * 1), //  []int64   要买单的订单Id列表
        auth_code: this.qrResult ? this.qrResult.toString() : "", //  string   扫码结果
      };

      try {
        console.log("reqGetPayQRcode, req:", JSON.stringify(params));
        const res = await api_order.reqGetPayQRcode(params);
        console.log("reqGetPayQRcode, res:", JSON.stringify(res));
        if (res.code == 1) {
          res.data = res.data || {};
          res.data.orders = res.data.orders || [];
          this.orderInfoDetail = { ...res.data, force };
          if (res.data.r == 1) {
            this.$message.success("支付成功");
            this.subSecondLogoutHandle();
            return;
          }
          this.showOrHideQRDrawerHandle();
        } else if (res.code == 2) {
          const result = await this.showConfirmHandle("买单", res.msg);
          if (result == "confirm") {
            this.getPayQRCode(1);
          }
        } else if (res.code == 3) {
          // 已经发起过生成二维码，当前订单正在处于付款状态
          this.getPayQRCode(3);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("生成二维码相关数据获取失败", error);
      }
    },

    showOrHideQRDrawerHandle() {
      this.showOrHideQRDrawer = !this.showOrHideQRDrawer;
    },

    // 倒计时退出登录
    subSecondLogoutHandle() {
      this.showNumSubTips = true;
      if (this.$route.name == "shoppingCart") {
        for (var i = 0; i < this.$parent.$children.length; i++) {
          if (this.$parent.$children[i].$el.className == "shopping-cart") {
            this.$parent.$children[i].getShoppingCartData();
          }
        }
      }
      if (this.timer) clearInterval(this.timer);
      this.timer = setInterval(() => {
        this.logoutCount--;
        if (this.logoutCount == 0) {
          this.hideTimeSubHandle();
          this.logOutHandle();
          clearInterval(this.timer);
        }
      }, 1000);
    },

    hideTimeSubHandle() {
      this.showNumSubTips = false;
      this.logoutCount = 4;
      if (this.timer) clearInterval(this.timer);
    },

    async logOutHandle() {
      try {
        const res = await api_auth.auth.requestauthlogout();
        if (res.code === 1) {
          // this.$store.commit("updateResResultDataObj", "");
          this.$store.commit("updateUserInfo", "");
          this.$router.replace({
            name: "Thelogin",
            replace: true,
            query: {
              client: "order",
            },
          });
          this.$message.success("退出成功！");
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("logout失败", error);
      }
    },

    // 获取已下单列表数据(此处调用的是我的点单列表接口，判断是否有点单权限)
    async getOrderedData() {
      try {
        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
        };
        const res = await api_order.reqCanLookMyOrderData(params);
        if (res.code === 1) {
          this.canLookOrderAmt = true;
        } else if (res.code == 2) {
          this.canLookOrderAmt = false;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取是否有查单权限失败", error);
      }
    },

    // 操作确认框
    async showConfirmHandle(title = "", content = "") {
      return this.$confirm(content, title, {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      })
        .then((res) => {
          return res;
        })
        .catch((e) => "");
    },

  },
  mounted() {
    this.init();
  },
  props: {
    empId: {
      default: 0,
    },
  },
  computed: {
    isShowPayBtn() {
      let isHaveAuth = false;
      if (this.$store.state.userInfo.authStatus != 4) {
        // 服务员 特饮 督查
        if (this.$store.state.userInfo.roleIds.includes(2) || this.$store.state.userInfo.roleIds.includes(4) || this.$store.state.userInfo.roleIds.includes(11)) {
          isHaveAuth = true
        }
      }
      if (this.$store.state.userInfo.authStatus == 4 &&
        this.terminalType == 'android') {
        isHaveAuth = true
      }
      return isHaveAuth;
    },
  },
  components: {
    drawerPayQR,
    drawerAddBookAmt: () => import("./drawerAddBookAmt.vue"),
    drawerMerchantConfig: () => import("./drawerMerchantConfig.vue"),
    drawerOrderList: () => import("./drawerShowOrderList.vue"),
    keyBoard: () => import("@/components/common/keyBoard"),
  },
  beforeDestroy() {
    clearInterval(this.timer);
  },
};
</script>

<style scoped lang="less">
@import "../../style/order/orderMeal/newFootBar.less";
</style>

<style lang="less">
@import "../../style/common/elementConfirm.less";
</style>
