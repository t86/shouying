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
        <!-- 收银核销卡券按钮 -->
        <div v-if="
          isShowPayBtn && cardInfo.orderAmt - cardInfo.payedAmt > 0 && isMoneyClient
        " class="server-redeem-btn">
          <div class="button" layout="row" layout-align="center center" @click="showRedeemCouponDrawerHandle">
            <img :src="imgSrc.coupon" alt />
            <span>核销卡券</span>
          </div>
        </div>
        <!-- 服务员充值滞留金 -->
<!--        <div v-if="-->
<!--          isShowPayBtn-->
<!--        " class="server-pay-btn line">-->
<!--          <div class="button" layout="row" layout-align="center center" @click="showAddBookDrawer = true">-->
<!--            <img :src="imgSrc.zhiliujin" alt />-->
<!--            <span>滞留金</span>-->
<!--          </div>-->
<!--        </div>-->

        <div class='li line' style="margin-left: 4px">
          <el-dropdown @command="moreClick" type="primary">
            <p style="margin-top:10px;margin-bottom: 10px;">更多功能<i class="el-icon-arrow-down el-icon--right"></i></p>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="isShowPayBtn" icon="el-icon-coin" command="a">滞留金</el-dropdown-item>
              <el-dropdown-item v-if="hasQingTaiAuth" icon="el-icon-refresh-right" command="b">清台</el-dropdown-item>
              <el-dropdown-item v-if="hasZhuantaiAuth" icon="el-icon-s-unfold" command="c">转台</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
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
            <!-- 主营实收：已结账的金额（主营商品已支付的金额，不含折扣） -->
            <span class="new-one-txt-title">主营实收:</span>
            <span class="new-one-txt-price">￥{{
              Number(cardInfo.payed_zy_val_amt || 0).toFixed(2)
            }}</span>
          </p>
        </div>
      </div>
    </div>

    <div layout="row" layout-align="center center" style="padding-top: 8px; width: 100%;" v-if="(!isRect) &&
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
          <!-- 主营实收：已结账的金额（主营商品已支付的金额，不含折扣） -->
          <span class="new-one-txt-title">主营实收:</span>
          <span class="new-one-txt-price">￥{{
            Number(cardInfo.payed_zy_val_amt || 0).toFixed(2)
          }}</span>
        </p>
      </div>
      <div layout="row" layout-align="end center" class="bind-emp" v-if="showEmp && empId*1 == 0" @click="showChangeFwy = true">
        <img :src="require('@/assets/card-imgs/bangdingfuwuyuan.png')" style="width: 16px;height: 16px" alt />
        绑定当台服务员
      </div> 
      <div v-else layout="row" layout-align="end center" class="author" :class="{ rect: !isRect }" @click="showDiandanEmpChange">
        <span>
        {{authInfo.name}}
        </span>
        <img class="item-img" alt="修改卡台服务员" v-if="hasChgKTWaiterAuth"  :src="require('@/assets/img/btn_edit.png')" />
      </div>
    </div>
    <!-- 暂不支付倒计时退出 -->
    <div class="num-sub-tips" v-show="showNumSubTips">
      <div class="contain">
        <i class="el-icon-close" style="
                                    position: absolute;
                                    top: 10px;
                                    right: 20px;
                                    color: #08080A;
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
          <i class="el-icon-close cursor" style="color: #1A1A21;" @click="showChoosePayType = false"></i>
        </div>

        <div class="center" layout="row" layout-align="start center">
          <div class="choose" :class="{ active: payType == item.id }" v-for="item in payTypeList" :key="item.id"
            @click="payType = item.id">
            <img :src="item.icon" style="height: 30px; width: 30px; vertical-align: middle" alt="" />
            <span style="margin-left: 8px;">{{ item.name }}</span><span v-if="[5, 6].includes(item.id)"
              class="tuijian">推荐</span>
          </div>
        </div>

        <div class="bottom" layout="row" layout-align="center center">
          <div class="button info cursor" @click="showChoosePayType = false">
            取消
          </div>
          <div class="button primary cursor" @click="getPayQRCode(1)">
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


    <!-- 服务员核销卡券 -->
    <drawerRedeemCoupon v-show="showRedeemCouponDrawer" v-model="showRedeemCouponDrawer" />

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

    <el-dialog append-to-body title="修改卡台服务员" :visible.sync="diandanDialogFormVisible">
      <el-form :model="ruleForm" :rules="rules" ref="ruleForm" label-position="right" @submit.native.prevent label-width="150px">
        <el-form-item label="原服务员:">
<!--          {{this.$store.state.userInfo.name}}-->
          {{authInfo.name}}
        </el-form-item>
        <el-form-item label="绑定服务员:" required prop="waiter">
          <el-select
              ref="waiter"
              v-model="ruleForm.waiter"
              filterable
              remote
              reserve-keyword
              placeholder="输入工号或者姓名搜索"
              :remote-method="remoteMethod"
              :loading="loading">
            <el-option
                v-for="item in ruleForm.waiters"
                :key="item.id"
                :label="item.name"
                :value="item.id">
            </el-option>
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="diandanDialogFormVisible = false">取 消</el-button>
        <el-button type="primary" @click="chgDiandan">确 定</el-button>
      </div>
    </el-dialog>

    <el-dialog append-to-body title="提示" :visible="showChangeFwy" @close="closeChangeFwy">
        <h3>绑定当台服务员？</h3>
        <div slot="footer" class="dialog-footer">
          <el-button type="primary" @click="closeChangeFwy">关闭</el-button>
          <el-button type="primary" @click="submitChangeFwy">确定</el-button>
        </div>
      </el-dialog>

      <!-- 全屏表格 -->
      <fullPageTable
          ref="fullPageTable"
          :tabList="tab.tabListOrigin"
          :cardList="card.cardListInfoArr"
          @showOrHideFullPageHandle="showOrHideFullPageHandle"
          v-if="showFullPageTable"
      />

    </div>
  </div>
</template>

<script>
import common_book from "@/utils/common/book";
import eventVue from "@/utils/eventVue";
import api_auth from "@/api/UtilAuth";
import api_order from "@/api/order";
import api_money from "@/api/money";

import drawerPayQR from "./newDrawerPayQR.vue";

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
import redeem from "@/assets/order-img/redeem.png";
import redeemActive from "@/assets/order-img/redeemActive.png";
import orderQRPayIcon from "@/assets/order-img/newOrderQRPayIcon.png";
import coupon from "@/assets/order-img/coupon.png";
import zhiliujin from "@/assets/order-img/zhiliujin.png";
import sanJiao from "@/assets/order-img/gengduo_sanjiao.png";

import weixin_kerensaowo from "@/assets/pay-img/weixin_kerensaowo.png";
import weixin_saokeren from "@/assets/pay-img/weixin_saokeren.png";
import weixinxiaochengxu from "@/assets/pay-img/weixinxiaochengxu.png";
import zhifubao_kerensaowo from "@/assets/pay-img/zhifubao_kerensaowo.png";
import zhifubaozhifu_saokeren from "@/assets/pay-img/zhifubaozhifu_saokeren.png";
import Observer, { BIND_EMP } from "@/observer";
import fullPageTable from "@/components/book/machine/fullPageTable.vue";

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
    routeName: "shoppingCart",
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
  {
    id: 5,
    name: "核销卡券",
    routeName: "redeem",
    icon: redeem,
    icon1: sanJiao,
    activeIcon: redeemActive
  },
];
const payNavList = [
  {
    id: 1,
    name: "返回首页",
    icon: goBack,
  },
];
const cardOptionHos = 164; // 卡台选项横向偏移量
let resResultDataObj = {}; // 元数据（后台接口返回处理后的初始化数据）
let cardListInfoArr = []; // 卡台总数据


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
      dateTab: {
        dateTabList: [],
        activeIndex: 0,
      },
      showFullPageTable: false, // 是否显示全屏表格（转台等操作）
      tab: {
        tabListOrigin: [], // 原始数据（只经过排序处理的数据）
        tabList: [],
        activeIndex: 0,
        tabMaxCount: 0,
        anotherInfo: [],
        showAnotherInfo: false,
        anotherInfoActiveId: 0,
      },
      card: {
        centerTypeWidth: 0, // 版心宽度
        cardList: [],
        cardListInfoArr: [],
        optionsPosition: {
          top: "50%",
          bottom: "",
          transform: "translate(0,-50%)",
          left: cardOptionHos + "px",
          right: "",
        },
      },
      drawer: {
        showDrawer: false,
        cardId: "", // 操作的卡台id
        bookId: "", // 操作的预定id
        cardInfoIndex: 0, // 当前操作卡台的索引值
        formStatus: 0, // 所选选项的表单状态
        // 1:预定 2：开台 3：查看卡台消费 4：修改翻台订位人 5：锁定 6：取消锁定 7：转台 8：修改预定 9：修改翻台定位人
        // 10：修改低消  11:修改订位人  12：撤台  13：修改开台类型（已删除此功能）  14：查看卡台详情  15：取消预定
        cardInfo: {}, // 数据修改等相关操作时当前卡台的信息
      },
      authInfo: {},
      canLookOrderAmt: false,

      isRect: window.innerWidth >= 1024,
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
      showRedeemCouponDrawer: false, // 服务员核销卡券
      selectedOrderList: [], // 选择好的服务员买单列表

      showAddBookDrawer: false, // 新增滞留金

      showMerchantConfig: false, // 滞留金管理
      scanStart: false,

      // 扫码支付
      qrResult: null, // 扫码结果

      cardInfo: {},
      scanCode: "",

      imgSrc: {
        coupon,
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

      ruleForm: {
        waiter: '',
        waiters:[],
      },
      rules: {
        waiter: [
          {required: true, message: '请输入卡台服务员', trigger: 'change'}
        ],
      },
      diandanDialogFormVisible: false,
      showChangeFwy: false, // 是否显示绑定服务员弹窗
      empId: 0,
      showEmp: false,
      loading: false,
    };
  },
  methods: {
    // // 请求全量基础数据(首次页面加载在父组件中调用(返回到此页面数据由mounted加载))
    // async getAllData() {
    //   try {
    //     resResultDataObj = this.$store.state.cardPageInfo.resResultDataObj;
    //     if (
    //         !resResultDataObj &&
    //         (!resResultDataObj["areaInfo"] ||
    //             !resResultDataObj["cardInfo"] ||
    //             !resResultDataObj["businessData"])
    //     )
    //       return;
    //
    //     // 日期tab
    //     this.getTimeTabData(JSON.parse(JSON.stringify(resResultDataObj["canDoList"])));
    //     await this.getCardList(
    //         resResultDataObj["cardInfo"],
    //         resResultDataObj["businessData"]
    //     );
    //     // 区域tab
    //     this.getTabList(resResultDataObj["areaInfo"]);
    //     // 获取卡台数据
    //   } catch (error) {
    //     console.log("全量数据请求失败", error);
    //   }
    // },
    /**
     * 全屏table(转台)
     */
    showOrHideFullPageHandle({ showFullPage, showDrawer }) {
      this.showFullPageTable = showFullPage;
      this.drawer.showDrawer = showDrawer;
      if (showDrawer) {
        this.$nextTick(() => {
          this.$children[0].getNewCardInfo &&
          this.$children[0].getNewCardInfo();
        });
      }
    },
    moreClick(command) {
      // alert('button click' + command);
      if ('a' === command) {
        this.showAddBookDrawer = true
      } else if ('b' === command) {
        this.clearCardHandle()
      } else if ('c' === command) {
        this.showFullPageTable = true
      }
    },
    keyboardShow() {
      if (
        window.atool
        && window.atool.getTermType() == "android" &&
        ("showSoftInput" in window.atool)
      ) {
        atool.showSoftInput();
        atool.executeJs(`this.$refs.waiter.focus()`)

      }
    },
    keyboardLeave() {
      setTimeout(() => {
        if (
          window.atool
          && window.atool.getTermType() == "android" &&
          ("hideSoftInput" in window.atool)
        ) {
          atool.hideSoftInput();
          atool.restart();
        }
      }, 10)
    },
    showDiandanEmpChange() {
      if (this.hasChgKTWaiterAuth) {
        this.diandanDialogFormVisible = true;
        this.remoteMethod();
        this.ruleForm.waiter = this.empId + ""
        setTimeout(() => {
          this.keyboardShow()
        }, 100)
      }
    },
    showEmpDialog() {
      console.log('showEmpDialog', this.showEmp, this.empId)
      if (this.showEmp && !this.empId) {
        this.showChangeFwy = true;
      }
    },
    closeChangeFwy() {
      this.showChangeFwy = false;
    },
    async submitChangeFwy() {
      this.showChangeFwy = false;
      try {
        const res = await api_order.reqSetCsmWaiter({
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
        })
        if (res.code === 1) {
          this.empId = this.$store.state.userInfo.emp_id;
          this.getAuthInfo();
          this.$message.success('绑定成功');
          console.log(res.data, '绑定成功')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('绑定服务员失败', error)
      }
    },
    async chgDiandan() {
      this.$refs['ruleForm'].validate((valid) => {
        console.log(valid)
        if (valid) {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            waiter_emp_id: this.ruleForm.waiter * 1
          };
          const res =  api_order.chg_csm_waiter_inord(params);
          res.then( r => {
            if (r.code === 1) {
              this.empId = this.ruleForm.waiter * 1
              this.getAuthInfo();
              this.$message.success('修改卡台服务员成功');
            } else {
              this.$message.warning(r.msg);
            }
            this.diandanDialogFormVisible = false
          })
        } else {
          console.log('error submit!!');
          return false;
        }
      });
    },
    remoteMethod(query) {
      this.loading = true;
      this.ruleForm.waiters = []
      const sealInfoArr = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo;
      const results = query ? sealInfoArr.filter(
              (el) =>
                  el.code.toString().includes(query) ||
                  el.name.toString().includes(query) ||
                  el.namePy.toString().includes(query.toLowerCase())
          )
          : sealInfoArr;
      console.log('waiters:', results)
      this.ruleForm.waiters = results;
      this.loading = false;
    },

    footNavBarClick(item) {
      if (this.$route.name === item.routeName) return; // 重复点击同一个tab
      if(item.id == 5) {
        this.activeRouteName = this.navList[item.id - 1].routeName;
        this.showRedeemCouponDrawerHandle()
        return
      }
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
        bindWaiterId: this.$store.state.userInfo.empId,
      };
      const businessData = this.$store.state.cardPageInfo.resResultDataObj.businessData || []
      this.showEmp = [1,2].includes(businessData.find(ite => ite.seatId == this.cardInfo.id).seat_biz_type * 1)
      this.empId = this.empId || businessData.find(ite => ite.seatId * 1 == this.$store.state.orderInfo.currentCardInfo.seatId * 1).waiter_emp_id
      // this.authInfo.name = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.filter(
      //     (item) => item.id == this.empId
      // ).map((item) => item.name).join("");
      console.log('getAuthInfo', this.empId)
      let bindWaiters =  this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.filter(item => item.id === this.empId)
      let bindWaiter
      if (bindWaiters.length > 0) {
        bindWaiter = bindWaiters[0]
        this.authInfo.name = bindWaiter.name
        this.authInfo.bindWaiterId = bindWaiter.id
      }
      this.authInfo = { ...this.authInfo };
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
            order_zy_amt += el.amts.oz * 1;
            // 已收金额
            payedAmt += el.amts.p * 1;
            // 主营实收
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
            this.navList[4],
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

    // 服务员核销卡券
    showRedeemCouponDrawerHandle() {
      this.showRedeemCouponDrawer = true;
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
        // force: force, //  int   1：强制操作  2：不强制操作, 如果卡台有未结账的线上订单,会返回code=2的特殊错误,用以提示服务员  3:获取未付款订单信息
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
          // const result = await this.showConfirmHandle("买单", res.msg);
          // if (result == "confirm") {
            this.getPayQRCode(1);
          // }
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
    Observer.subscribe(BIND_EMP, (empId) => {
      console.log('bind emp', empId)
      this.empId = empId;
    });
  },
  props: {

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
    // 是否有修改卡台
    hasChgKTWaiterAuth () {
      return (
        this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(9)
      );
    },
    hasQingTaiAuth() {
      console.log('hasQingTaiAuth', this.$store.state.userInfo)
      return (
          this.$store.state.userInfo.sys_modules &&
          this.$store.state.userInfo.sys_modules.includes(71) &&
          this.$store.state.userInfo.emp_id * 1 === this.empId * 1
      );
    },
    hasZhuantaiAuth() {
      console.log('hasZhuantaiAuth', this.$store.state.userInfo)
      return (
          this.$store.state.userInfo.sys_modules &&
          this.$store.state.userInfo.sys_modules.includes(72) &&
          this.$store.state.userInfo.emp_id * 1 === this.empId * 1
      );
    },
  },
  watch: {
    "authInfo.bindWaiterId": {
      handler(newVal, oldVal) {
        console.log("changed auth:", newVal, oldVal)

      }
    }
  },
  components: {
    drawerPayQR,
    drawerAddBookAmt: () => import("./newDrawerAddBookAmt.vue"),
    drawerMerchantConfig: () => import("./drawerMerchantConfig.vue"),
    drawerOrderList: () => import("./newDrawerShowOrderList.vue"),
    drawerRedeemCoupon: () => import("./drawerRedeemCoupon.vue"),
    keyBoard: () => import("@/components/common/keyBoard"),
    fullPageTable, // 全屏表格数据
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
