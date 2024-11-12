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

<!--        <div class='li line' style="margin-left: 4px">-->
<!--          <el-dropdown @command="moreClick" type="primary">-->
<!--            <p style="margin-top:10px;margin-bottom: 10px; font-size: 16px; color: #1A1A21">更多功能<i class="el-icon-arrow-down el-icon&#45;&#45;right"></i></p>-->
<!--            <el-dropdown-menu slot="dropdown">-->
<!--              <el-dropdown-item v-if="isShowPayBtn" icon="el-icon-coin" command="a" style="font-size: 16px">滞留金</el-dropdown-item>-->
<!--              <el-dropdown-item v-if="hasQingTaiAuth" icon="el-icon-refresh-right" command="b" style="font-size: 16px">清台</el-dropdown-item>-->
<!--              <el-dropdown-item v-if="hasZhuantaiAuth" icon="el-icon-s-unfold" command="c" style="font-size: 16px">转台</el-dropdown-item>-->
<!--            </el-dropdown-menu>-->
<!--          </el-dropdown>-->
<!--        </div>-->

        <!-- 更多功能 -->
        <div class="server-more-btn">
          <el-dropdown @command="moreClick" type="primary">
            <div class="button" layout="row" layout-align="center center">
              <img :src="imgSrc.orderQRPayIcon" alt />
              <span>更多功能</span>
            </div>
            <el-dropdown-menu slot="dropdown" class="button">
              <el-dropdown-item v-if="isShowPayBtn" style="font-size: 20px; font-weight: bold; height: 45px" command="a"><img :src="imgSrc.caozuo_zhiliujin" style="margin-right: 10px;" alt />滞留金</el-dropdown-item>
              <el-dropdown-item v-if="hasQingTaiAuth" style="font-size: 20px; font-weight: bold; height: 45px" command="b"><img :src="imgSrc.caozuo_qingtai" style="margin-right: 10px" alt />清台</el-dropdown-item>
              <el-dropdown-item v-if="hasZhuantaiAuth" style="font-size: 20px; font-weight: bold; height: 45px" command="c"><img :src="imgSrc.caozuo_zhuantai" style="margin-right: 10px" alt />转台</el-dropdown-item>
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
          ($store.state.userInfo.authStatus == 4 || canLookOrderAmt) && !safeModeEnabled" style="padding-top: 8px; " layout="row"
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
      <div layout="row" layout-align="end center" class="bind-emp" v-if="showEmp && empId*1 == 0 && isValidCard" @click="showChangeFwy = true">
        <img :src="require('@/assets/card-imgs/bangdingfuwuyuan.png')" style="width: 16px;height: 16px" alt />
        绑定当台服务员
      </div> 
      <div v-if="isValidCard"  layout="row" layout-align="end center" class="author" :class="{ rect: !isRect }" @click="showDiandanEmpChange">
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
      @setNeedPayOrderIdHandle="setNeedPayOrderIdHandle" @showPayQRDrawer="showPayQRDrawerHandle" />


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
              @focus="handleFocus"
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
        <el-button @click="hideChgDiandan">取 消</el-button>
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
<!--      <cardDrawer-->
<!--          ref="cardDrawer"-->
<!--          :showDrawer="drawer.showDrawer"-->
<!--          :formStatus=7-->
<!--          :cardId="cardInfo.id"-->
<!--          :bookId="cardInfo.wkBookId"-->
<!--          :cardInfo="cardInfo"-->
<!--          @changeShowDrawer="changeShowDrawer"-->
<!--          @showOrHideFullPageHandle="showOrHideFullPageHandle"-->
<!--      />-->

      <el-dialog append-to-body title="转台" :visible="drawer.showDrawer" width="35%" :show-close="false">
        <el-form ref="form" label-width="200px">
          <el-form-item :label="chgTabLabel">
            <el-button type="primary" @click="showFullPageTable=true;drawer.showDrawer=false">更换目标台</el-button>
          </el-form-item>
          <el-form-item :label="`老卡台 ${cardInfo.name} 低消:`">
            <span style="color: #0D9940;font-weight: bold">
              {{cardInfo.assignMinCsmAmt}} 元
            </span>
          </el-form-item>
          <el-form-item :label="`新卡台 ${changeCard.newCardName} 低消:`">
            <el-input
                v-model="changeCard.new_min_csm_amt"
                min="0"
                placeholder="请输入新卡台低消"
                type="number"
                style="width: 50%"
            ></el-input>
            <span style="color: #0D9940;font-weight: bold">
              元
            </span>
          </el-form-item>
        </el-form>
        <div slot="footer" class="dialog-footer" style="text-align: center">
          <el-button type="primary" style="background: #374368;" @click="drawer.showDrawer = false">取消</el-button>
          <el-button type="primary" @click="reserveOrOpenToChange">确定</el-button>
        </div>
      </el-dialog>

    </div>
  </div>
</template>

<script>
import common_book from "@/utils/common/book";
import eventVue from "@/utils/eventVue";
import api_auth from "@/api/UtilAuth";
import api_order from "@/api/order";
import api_money from "@/api/money";
import api_card from "@/api/Book";

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
import caozuo_zhiliujin from "@/assets/order-img/caozuo_zhiliujin.png";
import caozuo_zhuantai from "@/assets/order-img/caozuo_zhuantai.png";
import caozuo_qingtai from "@/assets/order-img/caozuo_qingtai.png";
import weixin_kerensaowo from "@/assets/pay-img/weixin_kerensaowo.png";
import weixin_saokeren from "@/assets/pay-img/weixin_saokeren.png";
import weixinxiaochengxu from "@/assets/pay-img/weixinxiaochengxu.png";
import zhifubao_kerensaowo from "@/assets/pay-img/zhifubao_kerensaowo.png";
import zhifubaozhifu_saokeren from "@/assets/pay-img/zhifubaozhifu_saokeren.png";
import Observer, { BIND_EMP } from "@/observer";
import fullPageTable from "@/components/book/machine/fullPageZTOrder.vue";
import cardDrawer from "@/components/book/machine/cardDrawerZTOrder.vue";
import {cardPageMixins} from "@/mixin/cardPage";
import {cardOptions} from "@/utils/config/card";

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
      changeCard: {
        originAmt: "", // 原卡台低消
        originCardName: "", // 原卡台名称
        new_min_csm_amt: "", // 新卡台低消
        newCardName: "", // 新卡台名称
        change_card_status_arr: [7],
      },
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
        zhiliujin,
        caozuo_zhiliujin,
        caozuo_zhuantai,
        caozuo_qingtai
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
      safeModeEnabled: false, // 添加 safeModeEnabled
    };
  },
  methods: {
    handleFocus(){
      if (
        window.atool
        && window.atool.getTermType() == "android" &&
        ("showSoftInput" in window.atool)
      ) {
        const dropdown = document.querySelector('.el-select-dropdown');
        if (dropdown) {
          dropdown.style.transform = 'translateX(150px)';
        }
      }
    },
    // 预定或开台转台
    async reserveOrOpenToChange() {
      this.reserveOrOpenToChangeParams.new_min_csm_amt = Number(
          this.reserveOrOpenToChangeParams.new_min_csm_amt
      );
      try {
        // cardInfo.bizStatus: 8:预定转台  4：开台转台
        const res =
            this.cardInfo.bizStatus == 8
                ? await api_card.reqReserveToChangeCard(
                    this.reserveOrOpenToChangeParams
                )
                : await api_card.reqOpenToChange(this.reserveOrOpenToChangeParams);
        if (res.code === 1) {
          this.$message.success('转台成功');
          this.drawer.showDrawer = false
          this.$store.commit("updateNewCardInfo", {});
          this.$sessionStorage.removeItem("newCardInfo");
        }
      } catch (error) {
        console.log("转台失败", error);
      }
    },
    getNewCardInfo() {
      this.changeCard.new_min_csm_amt =
          this.$store.state.cardPageInfo.newCardInfo.grpMinCsmAmt; // 新卡台最基础低消
      this.changeCard.newCardName =
          this.$store.state.cardPageInfo.newCardInfo.name;
      console.log(this.formData)
    },
    // 是否显示drawer
    changeShowDrawer(val) {
      this.drawer.showDrawer = val;
      if (val)
        this.$nextTick(() => {
          const sessionDom = document.querySelector(".el-drawer__body");
          sessionDom.scrollTo(0, 0);
        });
    },
    // 筛选卡台数据
    filterCardList(key, id) {
      cardListInfoArr.forEach((el) => {
        el.showOption = false;
      });
      if (key === "keyword"){
        const result = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo || [];
        let orderPersons = result.filter(
            (item) => item.code.includes(this.keyWord) ||
                item.name.toLocaleUpperCase().includes(this.keyWord.toLocaleUpperCase()) ||
                item.namePy.toLocaleUpperCase().includes(this.keyWord.toLocaleUpperCase())
        );
        return cardListInfoArr.filter(
            (item) =>
                item.customerName
                    .toLocaleUpperCase()
                    .includes(this.keyWord.toLocaleUpperCase()) ||
                item.customerPhone.slice(-4).includes(this.keyWord) ||
                item.customer_name_py
                    .toLocaleUpperCase()
                    .includes(this.keyWord.toLocaleUpperCase()) ||
                item.name
                    .toLocaleUpperCase()
                    .includes(this.keyWord.toLocaleUpperCase()) ||
                orderPersons.filter(p => p.id && p.id * 1 > 0 && p.id == item.salesEmpId).length > 0
        );
      }

      if (key === "regionId" && id === 0) return cardListInfoArr; // 点击全部按钮
      return cardListInfoArr.filter((item) => item[key] == id);
    },
    // 获取当天年月日
    getCurrentDay() {
      const Y = new Date().getFullYear().toString().padStart(2, 0);
      const M = (new Date().getMonth() + 1).toString().padStart(2, 0);
      const D = new Date().getDate().toString().padStart(2, 0);
      return `${Y}${M}${D}`;
    },
    // 获取卡台options
    getCardOptions(status, platform_id, showOnlineText, turnoverCnt, topNum) {
      // 卡台状态status：1 空台 2 锁定 3 预订 4 开台 5 点单未结账 6 部分结账 7 已结账 8 小程序预留 22 无效 33 删除
      // 订单来源platform_id：0 代表本地系统 1 代表微信小程序
      let optionsIdArr = [];
      const cardResultOptions = [];
      switch (Number(status)) {
        case 1: // 空台
          if (
              this.modelVisible ||
              this.$store.state.cardPageInfo.resResultDataObj.canDoList[
                  this.dateTab.activeIndex
                  ].id > this.getCurrentDay()
          ) {
            // 未开启营业日 或 自然日日期为未来日期
            optionsIdArr = [1];
          } else if (
              this.$store.state.cardPageInfo.resResultDataObj.canDoList[
                  this.dateTab.activeIndex
                  ].id <= this.getCurrentDay()
          ) {
            // 自然日日期小于等于为当天
            if (this.dateTab.activeIndex == 0) {
              optionsIdArr = showOnlineText
                  ? [17]
                  : turnoverCnt > 0
                      ? [1, 2, 4, 5]
                      : [1, 2, 5];
            } else {
              optionsIdArr = [1];
            }
          }
          break;
        case 2: // 锁定台
          optionsIdArr =
              this.modelVisible || this.dateTab.activeIndex != 0 ? [] : [6];
          break;
        case 4: // 开台
          optionsIdArr = [10, 11, 7, 12, 14, 4, 20];
          break;
        case 5: // 点单未结账
          optionsIdArr = [10, 11, 7, 14, 4, 20];
          break;
        case 6: // 点单部分结账
          optionsIdArr = [10, 11, 7, 14, 4, 20];
          break;
        case 7: // 已结账
          optionsIdArr = [10, 11, 7, 14, 4, 20];
          if (
              this.$store.state.cardPageInfo.resResultDataObj.showAmt.length >
              0 &&
              this.$store.state.cardPageInfo.resResultDataObj.showAmt.find(
                  (item) => item.id == 5
              ) &&
              this.$store.state.cardPageInfo.resResultDataObj.showAmt.find(
                  (item) => item.id == 5
              ).param1 == 2
          ) {
            // 有清台权限
            optionsIdArr.push(16);
          }
          break;
        case 8: // 预留
          if (platform_id == 0) {
            // 线下预留
            optionsIdArr =
                this.modelVisible || this.dateTab.activeIndex != 0
                    ? [8, 15]
                    : [2, 7, 15, 8, 4]; // [2, 7, 15, 8, 3, 4]
          } else {
            // 线上预留
            if (!this.modelVisible) {
              optionsIdArr = this.dateTab.activeIndex != 0 ? [8, 15] : [2, 7];
            } else {
              optionsIdArr = [];
            }
          }
          break;
      }
      optionsIdArr.push(18);
      if (topNum > 0) optionsIdArr.push(19);
      optionsIdArr.forEach((el) => {
        cardResultOptions.push(cardOptions.find((ele) => ele.id === el));
      });
      return cardResultOptions;
    },
    getTimeTabData(nextDayDataArr = []) {
      this.dateTab.dateTabList = nextDayDataArr.map((item) => ({
        ...item,
      }));
    },
    async getAllData() {
      console.log('------------------')
      try {
        resResultDataObj = this.$store.state.cardPageInfo.resResultDataObj;
        if (
            !resResultDataObj &&
            (!resResultDataObj["areaInfo"] ||
                !resResultDataObj["cardInfo"] ||
                !resResultDataObj["businessData"])
        )
          return;

        // 日期tab
        this.getTimeTabData(JSON.parse(JSON.stringify(resResultDataObj["canDoList"])));
        await this.getCardList(
            resResultDataObj["cardInfo"],
            resResultDataObj["businessData"]
        );
        // 区域tab
        this.getTabList(resResultDataObj["areaInfo"]);
        // 获取卡台数据
      } catch (error) {
        console.log("全量数据请求失败", error);
      }
    },
    // 获取全量数据
    getCardList(cardInfo = [], businessData = []) {
      // // 获取设备可操作区域或卡台
      const currentMachineId = this.$localStorage.getItem("machineId");
      const currentAreaAndCardList = (
          this.$store.state.cardPageInfo.resResultDataObj["machineArea"] || []
      ).filter(
          (item) => item.license_id == currentMachineId && item.status == 1
      );
      const isNoLimit = currentAreaAndCardList.filter(
          (item) => item.type_id == 3
      );
      if (isNoLimit.length <= 0) {
        // 有限制
        const areaList = currentAreaAndCardList.filter(
            (item) => item.type_id == 1
        );
        const cardListNew = currentAreaAndCardList.filter(
            (item) => item.type_id == 2
        );
        // 当前配置的区域id
        let areaIdList = areaList.map((item) => item.region_o_seat_id);

        // 通过cardList反推出对应的区域，并添加到区域id中
        const allCardInfo =
            [...this.$store.state.cardPageInfo.resResultDataObj.cardInfo] || [];

        // 最终经过筛选过后的卡台列表，对应元数据的cardInfo
        let resultCardList = [];

        areaIdList.forEach((el) => {
          // 存储配置区域的区域下所有卡台
          const currentAreaCardList = allCardInfo.filter(
              (item) => item.regionId == el
          );
          resultCardList = [...resultCardList, ...currentAreaCardList];
        });

        cardListNew.forEach((el) => {
          const find = allCardInfo.find(
              (item) => item.id == el.region_o_seat_id
          );
          if (find) {
            resultCardList.push(find);
            if (!areaIdList.find((item) => item == find.regionId)) {
              areaIdList.push(find.regionId);
            }
          }
        });
        cardInfo = resultCardList;
      }
      cardInfo = cardInfo.sort((a, b) => a.dsp - b.dsp);
      let cardList = [];
      cardInfo.forEach((item, index) => {
        if (item.status == "1") {
          const cardOnlineStatus =
              this.$store.state.cardPageInfo.resResultDataObj[
                  "lineOrBookCard"
                  ].find((items) => items.seat_id == item.id) || {};

          // 查找对应的业务数据
          let data = businessData.find((el) => el.seatId === item.id) || {};
          // 初始化卡台状态（空台）
          data.bizStatus = data.bizStatus || "1";
          // 卡台是线上还是线下
          data.cardStatus = cardOnlineStatus.cardStatus || "";
          // 是否是线上转线下卡台
          data.isTurnBottomCard =
              this.$store.state.cardPageInfo.resResultDataObj[
                  "turnLineBottomCard"
                  ].find((items) => items.seat_id == item.id);
          // ‘线'字标签，显示优先级：订单预留方式 > 卡台属于线上还是线下
          data.showOnlineText =
              data.bizStatus > 2
                  ? data.platform_id == 1 && !data.isTurnBottomCard
                  : cardOnlineStatus.cardStatus == 1 && !data.isTurnBottomCard;

          // 是否有置顶
          const topNumInfo = this.$store.state.cardPageInfo.resResultDataObj[
              "topCard"
              ].find((items) => items.seat_id == item.id && items.status == 1);

          data.topNum = topNumInfo ? topNumInfo.seq_id : "0";

          if (data.bizStatus != "22" && data.bizStatus != "33") {
            cardList.push({
              // 卡台数据
              ...item,
              // 业务数据
              ...data,
              // 卡台名称放大倍数
              cardNameScale: this.getScaleCardName(item.name),
              // 赠送金额
              zengSongAmt: (Number(data.yhAmt) + Number(data.yh2Amt)).toFixed(
                  2
              ),
              totalAmt: Number(data.orderAmt).toFixed(2),
              // 当前卡台所处状态的小卡片
              tipsArr: this.getTips(data.bizStatus),
              // 低消进度
              diXiaoJindu:
                  Number(data.assignMinCsmAmt) > 0
                      ? (Number(data.order_zy_amt - data.payed_zy_free_amt) /
                          Number(data.assignMinCsmAmt)) *
                      100 >
                      100
                          ? "100%"
                          : (
                          (Number(data.order_zy_amt - data.payed_zy_free_amt) /
                              Number(data.assignMinCsmAmt)) *
                          100
                      ).toFixed(0) + "%"
                      : "",
              // 点击卡台出现的可操作选项
              options: this.getCardOptions(
                  data.bizStatus,
                  data.platform_id,
                  data.showOnlineText,
                  data.turnoverCnt,
                  data.topNum
              ),
              // 是否显示卡台的操作按钮选项
              // showOption: this.card.cardList[index] && this.card.cardList[index].showOption
              showOption:
                  cardListInfoArr[index] && cardListInfoArr[index].showOption,
              isLeftArrow: false, // 操作选项列表是否显示在左边
            });
          }
        }
      });

      // 设置图例中显示的抵达数量
      // this.setLegendCount(this.tab.activeIndex);

      cardList = cardList.sort((a, b) => b.topNum - a.topNum);

      cardListInfoArr = cardList;
      this.card.cardListInfoArr = JSON.parse(JSON.stringify(cardList));
      this.$store.commit("updateCardList", this.card.cardListInfoArr);
      this.card.cardList = JSON.parse(JSON.stringify(cardList));
      this.$forceUpdate();
    },

    // 获取区域tab数据
    getTabList(arr = []) {
      arr = arr.sort((a, b) => Number(a.dsp) - Number(b.dsp));
      const roleIds = this.$store.state.userInfo.roleIds;
      let tabList = [];
      if (roleIds.includes(2)) {
        // 有服务员权限
        tabList = this.getAuthArea(JSON.parse(JSON.stringify(arr)));
      }
      tabList = tabList.filter((item) => item.status == 1)
      this.tab.tabListOrigin = JSON.parse(JSON.stringify(tabList));
      this.tab.tabList = tabList;
    },
    // 服务员身份权限返回可点的对应区域及可查单区域列表
    getAuthArea(arr) {
      // 可点区域tab
      const canPayOrderAreaList = [];
      // 筛选可用的可点区域岗位(服务员)可点区域
      const authStationArea =
          this.$store.state.cardPageInfo.resResultDataObj.stationArea.filter(
              (el) => el.status == 1
          );
      const authStationId = this.$store.state.userInfo.station_id || "";
      // 将要展示在页面上的最终岗位可点区域
      const resultAreaInfo = authStationArea.filter(
          (el) => el.station_id == authStationId
      );
      resultAreaInfo.forEach((el) => {
        const info = arr.find((ele) => ele.id == el.region_id);
        if (info) canPayOrderAreaList.push(info);
      });

      // 可查单区域tab
      let canGetOrderAreaList = [];

      // 用户配置可查单区域
      const configAreaIdList = this.$store.state.userInfo.check_regions || [];
      canGetOrderAreaList = arr.filter((item) =>
          configAreaIdList.find((items) => items == item.id)
      );

      const tabList = [...canPayOrderAreaList, ...canGetOrderAreaList];
      return tabList.filter(
          (item, i, array) => array.findIndex((items) => items.id == item.id) == i
      );
    },
    /**
     * 全屏table(转台)
     */
    showOrHideFullPageHandle({ showFullPage, showDrawer }) {
      console.log('-----showFullPage, showDrawer', showFullPage, showDrawer)
      this.showFullPageTable = showFullPage;
      this.drawer.showDrawer = showDrawer;
      if (showDrawer) {
        // this.$nextTick(() => {
        //   let cd = this.$refs['cardDrawer']
        //   cd.getNewCardInfo && cd.getNewCardInfo()
        // });
        this.getNewCardInfo()
      }
    },
    moreClick(command) {
      // alert('button click' + command);
      if ('a' === command) {
        this.showAddBookDrawer = true
      } else if ('b' === command) {
        this.clearCardHandle()
      } else if ('c' === command) {
        if (this.hasForbidUnTipTableAuth) {
          this.$message.error('您当前暂无查看空台权限, 不支持操作转台!')
          return
        }
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
          atool.executeJs(`this.$refs.waiter.blur()`);
          atool.hideSoftInput();
          atool.restart();
        }
      }, 10)
    },
    showDiandanEmpChange() {
      if (this.hasChgKTWaiterAuth && isValidCard) {
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
              this.diandanDialogFormVisible = false
              this.keyboardLeave()
            } else {
              this.$message.warning(r.msg);
            }
          })
        } else {
          console.log('error submit!!');
          return false;
        }
      });
    },
    hideChgDiandan(){
      this.diandanDialogFormVisible = false
      this.keyboardLeave()
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
        if(!this.hasHexiao) {
          return this.$message.warning('无核销权限，请联系后台人员配置相关权限！')
        }
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
        bindWaiterStation: this.$store.state.userInfo.station_id
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
        this.authInfo.bindWaiterStation = bindWaiter.stationId
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
              await this.$router.replace({name: "orderCard"});
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
          console.log('changeTurnOverCountHandle=========================================', amtInfoList)
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

      this.getAllData()
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
          this.$message.success("退���成功！");
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

    // 显示支付二维码
    showPayQRDrawerHandle(data) {
      this.payType = data.payType
      this.orderInfoDetail = data.orderInfoDetail
      this.showOrHideQRDrawer = true
    }
  },
  mounted() {
    this.init();
    Observer.subscribe(BIND_EMP, (empId) => {
      console.log('bind emp', empId)
      this.empId = empId;
    });
    // 初始化 safeModeEnabled
    let safeMode = this.$store.state.cardPageInfo.resResultDataObj.safeMode || []
    this.safeModeEnabled = safeMode.some(item => item.id * 1 === 1 && item.param1 * 1 === 1)

    // 添加事件监听
    eventVue.$on("safeModeChanged", (e) => {
      console.log('safeModeChanged', e)
      this.safeModeEnabled = e[0][0] * 1 === 1 && e[0][1] * 1 === 1
      console.log('safeModeEnabled coming here newfoo', this.safeModeEnabled)
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
    hasHexiao() {
      let hashexiao =
          this.$store.state.userInfo.sys_modules &&
          this.$store.state.userInfo.sys_modules.includes(86)
      return hashexiao
    },
    hasZhuantaiAuth() {
      console.log('hasZhuantaiAuth', this.$store.state.userInfo)
      return (
          this.$store.state.userInfo.sys_modules &&
          this.$store.state.userInfo.sys_modules.includes(72) &&
          this.$store.state.userInfo.emp_id * 1 === this.empId * 1
      );
    },
    hasForbidUnTipTableAuth() {
      return (
          this.$store.state.userInfo.sys_modules &&
          this.$store.state.userInfo.sys_modules.includes(70)
      );
    },
    chgTabLabel() {
      return `从 ${this.cardInfo.name} 到 ${this.changeCard.newCardName}`
    },
    reserveOrOpenToChangeParams() {
      return {
        // cardInfo.bizStatus: 8:预定转台  4：开台转台
        id:
            this.cardInfo.bizStatus == 8
                ? Number(this.cardInfo.wkBookId)
                : Number(this.cardInfo.id), // int 待操作卡台Id
        dest_seat_id: Number(this.$store.state.cardPageInfo.newCardInfo.seatId), // int64  目标卡台Id
        new_min_csm_amt: this.changeCard.new_min_csm_amt, // int  抵消金额(元)
      };
    },
    isValidCard() {
      return this.$store.state.orderInfo.currentCardInfo.bizType == 1;
    }
  },
  watch: {
    "authInfo.bindWaiterId": {
      handler(newVal, oldVal) {
        console.log("changed auth:", newVal, oldVal)

      }
    }
  },
  beforeDestroy() {
    clearInterval(this.timer);
    // 移除事件监听
    eventVue.$off("safeModeChanged");
  },
  mixins: [cardPageMixins],
};
</script>
<style>
  .el-dialog__header{
    background-color: rgb(183, 192, 205) !important;
  }
  .el-dialog__title {
    line-height: 24px;
    font-size: 20px;
    color: #303133;
  }
  .el-dialog__body {
    padding: 30px 20px;
    color: #303133;
    word-break: break-all;
    background-color: rgb(212, 219, 228) !important;
  }
  .el-form-item {
    margin-bottom: 18px;
  }
  .el-form-item__label {
    text-align: right;
    vertical-align: middle;
    float: left;
    font-size: 18px;
    color: #303133;
    line-height: 30px;
    padding: 0 12px 0 0;
    box-sizing: border-box;
  }
  .el-form-item__content {
    line-height: 30px;
    position: relative;
    font-size: 18px;
  }
  /*.el-input__inner {*/
  /*  color: #0D9940;*/
  /*  font-weight: bold;*/
  /*  font-size: 18px;*/
  /*}*/
</style>

<style scoped lang="less">
@import "../../style/order/orderMeal/newFootBar.less";
</style>

<style lang="less">
@import "../../style/common/elementConfirm.less";
</style>

<style scoped lang="less">
.el-select-dropdown {
  transform-origin: right top;
  transform: translateX(150px) !important;
}
</style>

