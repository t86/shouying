<template>
  <div class="card-box">
    <div class="contain" ref="containRef">
      <div class="contain-content" ref="containContentRef">
        
        <!-- tab -->
        <div class="tab" layout="row" layout-align="space-between center">
          <div layout="row" layout-align="center">
            <div class="tab-item" :class="{ active: item.id === tab.activeIndex }" v-for="(item, index) in tab.tabList"
              :key="index" @click="changeTab(index, item.id)">
              <span>{{ item.name }}</span>
              <div class="anotherInfo" v-if="item.id === 999 && tab.showAnotherInfo">
                <li class="another-item" :class="{ active: items.id === tab.anotherInfoActiveId }"
                  v-for="(items, i) in tab.anotherInfo" :key="i" @click.stop="changeTab('9999', items.id)">
                  <span>{{ items.name }}</span>
                </li>
              </div>
            </div>
          </div>
          <div class="new-dosomething-item" layout="row" layout-align="space-between center">
            <div class="arrow arr-left" :class="{ pressdown: arrowStatus === 'down' }" @mousedown="keyDownHandle('down')"
              @touchstart="keyDownHandle('down')" @mouseup="keyDownHandle">
              <img :src="imgSrc.arrowBottom" alt />
            </div>
            <div class="arrow arr-right" :class="{ pressdown: arrowStatus === 'up' }" @mousedown="keyDownHandle('up')"
              @touchstart="keyDownHandle('up')" @mouseup="keyDownHandle">
              <img :src="imgSrc.arrowBottom" alt />
            </div>
          </div>
        </div>
        <!-- 卡台列表 -->
        <div class="content">
          <div v-if="card.cardList.length > 0" class="center-type" :style="'width:' + card.centerTypeWidth + 'px'"
            layout="row" layout-align="start center">
            <div class="card-item" v-for="(item, index) in card.cardList" :key="index" :class="[
              'bgc' + Number(item.bizStatus)
              ]" @click.stop="cardClickHandle(item)" @contextmenu.prevent.stop="rightClickHandle">
              <p layout="row" layout-align="space-between center" class="item-row">
                <span class="area-name">{{ item.regionId | getAreaName }}</span>
                <span>
                  <span v-if="item.mark" class="mark">{{ item.mark }}</span>
                  <span v-if="typeModule == 1">{{
                    item.openTime ? "(" + item.openTime + ")" : "" | filterTime
                  }}</span>
                </span>
              </p>

              <h3 class="card-name" layout="row" layout-align="start center">
                <div ref="cardRef" style="white-space: nowrap; transform-origin: left center"
                  :style="{ fontSize: fontSize(item, index) + 'px' }">
                  {{ item.name }}
                </div>
              </h3>

              <!-- 存酒  取酒  充公入口按钮 -->
              <div class="save-wine-enter" v-if="typeModule == 2" layout="row" layout-align="start center">
                <div class="enter-item cursor" :class="{ 'border-right': i < item.options.length - 1 }"
                  v-for="(el, i) in item.options" :key="i" @click.stop="optionsClickHandle(el, item)">
                  <img :src="el.icon" />
                  <p>{{ el.name }}</p>
                </div>
              </div>

              <!-- 点单金额 -->
              <p
                class="order-amt"
                layout="row"
                v-if="
                  typeModule == 1 &&
                  item.bizStatus != 1 &&
                  item.bizStatus != 2 &&
                  item.bizStatus != 8 &&
                  !safeModeEnabled
                "
                layout-align="space-between center"
              >
                <span>
                  <!-- 有查单权限 -->
                  <span v-if="item.canLookOrder">点:￥{{ item.orderAmt }}</span>
                  <!-- 无查单权限 -->
                  <span v-else></span>
                </span>

                <span v-if="item.canLookOrder" class="card-step">{{
                  item.diXiaoJindu
                }}</span>
              </p>
              <p v-else style="height: 18px"></p>

              <!-- 优惠金额 -->
              <p
                style="height: 18px"
                v-if="
                  typeModule == 1 &&
                  item.canLookOrder &&
                  item.bizStatus != 1 &&
                  item.bizStatus != 2 &&
                  item.bizStatus != 8 &&
                  $store.state.userInfo.roleIds.includes(3) &&
                  !safeModeEnabled
                "
              >
                <span>惠:￥{{ item.zengSongAmt }}</span>
              </p>
              <p v-else style="height: 18px"></p>

              <p layout="row" layout-align="space-between center" class="order-person">
                <!-- tips -->
                <span v-if="typeModule == 1 && item.tipsArr.length > 0" layout="row" layout-align="space-between center">
                  <span class="card-tips" :class="{ green: items !== '锁', yellow: items === '锁' }"
                    v-for="(items, i) in item.tipsArr" :key="i">{{ items }}</span>
                </span>

                <!-- 订位人 -->
                <span v-else-if="
                  typeModule == 1 &&
                  item.bizStatus != 1 &&
                  item.bizStatus != 2
                " class="one-txt-cut" style="
                  word-break: normal;
                  white-space: normal; overflow: hidden; text-overflow: ellipsis; 
                  display: -webkit-box; -webkit-line-clamp: 2; 
                  -webkit-box-orient: vertical;">
                  {{ item.salesEmpId | getDepartmentName }}
                  {{ item.salesEmpId | getOrderPersonName }}
                </span>
                <!-- 用于占位 -->
                <span v-else></span>
                <!-- 翻台数 -->
                <span style="word-break: keep-all;" v-if="
                  typeModule == 1 && (item.turnoverCnt > 0 &&
                  ($store.state.userInfo.roleIds.includes(2) ||
                    $store.state.userInfo.roleIds.includes(3)))
                ">
                  翻{{ item.turnoverCnt }}
                </span>
              </p>
              <p
                layout="row"
                layout-align="start center"
                style="
                margin-top: 4px;
                overflow: hidden;
                  text-overflow: ellipsis;
                  white-space: nowrap;"
              >
                  <span>{{ item.remark }}</span>
              </p>
            </div>
          </div>
          <!-- 无数据 -->
          <div v-else class="no-data">
            <img :src="imgSrc.noCardInfo" alt />
            <p>
              {{
                tab.activeIndex == 0
                ? "暂无卡台数据"
                : "暂无服务过的卡台，快去点单吧！"
              }}
            </p>
          </div>
        </div>
        <!-- 卡台图例tab -->
        <div class="legend" layout="row" layout-align="space-between center">
          <!-- 卡台状态图例 -->
          <div class="legend-list" layout="row" layout-align="space-around center">
            <!-- 过滤掉锁台 -->
            <div class="legend-list-item" v-for="(item, index) in legendList" :key="item.id"
              :class="{ actives: legendActive === item.id }">
              <span class="btn" v-if="item.id != 20" :class="{ active: legendActive === item.id }"
                @click.stop="changeCardStatus(item.id)">
                <div class="img-contain" :class="[item.id == 20 ? '' : 'bgc' + (index + 2)]">
                  <img :src="item.allRight" alt />
                </div>
              </span>
              <span class="btn" style="transform: translateY(26px); border: none;" v-else
                :class="{ active: legendActive === item.id }">
                <div class="img-contain" :class="[item.id == 20 ? '' : 'bgc' + (index + 2)]">
                  <span>{{
                    cardStatusNoInfo[20] || 0
                  }}</span>
                </div>
              </span>
              <p v-if="item.id != 20">
                <span style="margin-right: 2px">{{ item.name }}</span><span>{{
                  cardStatusNoInfo[item.id == 4 ? 10 : item.id] || 0
                }}</span>
              </p>
              <p v-else style="transform: translateY(-28px)">
                <span style="margin-right: 2px">{{ item.name }}</span>
              </p>
            </div>
            <div class="legend-list-item reload-btn" :class="{ pressdown: arrowStatus === 'reload' }"
              @mousedown="keyDownHandle('reload')" @touchstart="keyDownHandle('reload')" @mouseup="keyDownHandle">
              <img :src="imgSrc.reload" alt />
              <p>刷新</p>
            </div>
          </div>
          <!-- 操作面板 -->
          <div class="dosomething" layout="row" layout-align="space-between center">
            <div class="dosomething-item checkout-btn" v-show="hasWineAuth" layout="row" layout-align="center center"
              @click.stop="checkOutModuleHandle">
              <img :src="require('@/assets/card-imgs/new-checkout.png')" alt />
              <span>
                {{ typeModule == 1 ? "存酒模式" : "点单模式" }}
              </span>
            </div>

            <div class="dosomething-item more-effect" @click.stop="legendOptionHandle('more')" v-if="!safeModeEnabled">
              <img :src="imgSrc.more" alt />
              <p class="do-title">更多功能</p>
              <div class="option more" v-if="legendOptions.showMoreFunc">
                <div class="option-item" @click="showOrHideMinDetailDrawerHandle()">
                  <img :src="require('@/assets/money-img/caozuo_dixiao.png')" alt />
                  <span>低消进度统计表</span>
                </div>
                <div class="option-item" @click="showOrHideTYDetailDrawer()">
                  <img :src="require('@/assets/money-img/caozuo_teyin.png')" alt />
                  <span>鸡尾酒明细表</span>
                </div>
                <div v-if="hasOutSomething" class="option-item line" @click="showOrHideOutSomethingHandle(true)">
                  <img :src="require('@/assets/money-img/caozuo_guqing.png')" alt />
                  <span>估清商品</span>
                </div>
              </div>
              <img class="sj" v-if="legendOptions.showMoreFunc" :src="imgSrc.sanJiao" alt />
            </div>
            <div class="dosomething-item" @click.stop="legendOptionHandle('pwd')">
              <img :src="imgSrc.arrowTop" :class="{ rotate: legendOptions.showUpdatePwd }" alt />
              <p class="do-title p-2">{{ authName }}</p>
              <!-- 操作选项 -->
              <div class="option" v-if="legendOptions.showUpdatePwd">
                <div class="option-item" @click.stop="legendOptionHandle('updatePwd')">
                  <img :src="imgSrc.updatepwd" alt />
                  <span>修改密码</span>
                </div>
                <div class="option-item authPwd" @click.stop="legendOptionHandle('authPwd')">
                  <img :src="imgSrc.authPwd" alt />
                  <span>授权密码</span>
                </div>
                <div class="option-item logout" @click.stop="legendOptionHandle('logout')" style="border-bottom: none;">
                  <img :src="imgSrc.loginOut" alt />
                  <span>退出登录</span>
                </div>
                <img :src="imgSrc.sanJiao" class="sj" alt />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 修改密码 -->
    <updatePassword ref="updatePassword" :showDrawer="legendOptions.updatePwdModel" @submitHandle="submitUpdatePwdHandle"
      @cancelUpdatePwdHandle="cancelUpdatePwdHandle" />

    <!-- 授权密码 -->
    <updateAuthPassword ref="updateAuthPassword" :showDrawer="legendOptions.showAuthPwdModel"
      @submitHandle="submitUpdateAuthPwdHandle" @cancelUpdatePwdHandle="legendOptions.showAuthPwdModel = false" />

    <!-- 低消进度统计表 -->
    <drawerMinDetail :showDrawer="showMinDetailDrawer" @showOrHideDrawer="showOrHideMinDetailDrawerHandle" />

    <!-- 鸡尾酒明细表 -->
    <drawerTYDetail :showDrawer="showOrHideTYDetail" @showOrHideTYDetailDrawer="showOrHideTYDetailDrawer" />

    <!-- 估清 -->
    <div class="out-something" v-if="showOrHideOutSomething">
      <outSomething ref="outSomething" @showOrHideOutSomethingHandle="showOrHideOutSomethingHandle" />
    </div>

    <!-- 存酒 -->
    <drawerSaveWine v-model="saveWineInfo.show" />

    <!-- 取酒 -->
    <drawerGetWine v-model="getWineInfo.show" />

    <!-- 充公 -->
    <drawerPayToStore v-model="payToStoreInfo.show" />

    <div class="modal" v-if="modelVisible">
      <div class="modal-content">暂未开启营业日，请联系咨客人员！</div>
    </div>
  </div>
</template>

<script>
import api_auth from "@/api/UtilAuth";
import api_order from "@/api/order";
import api_money from "@/api/money";

import { legendList, orderSaveWineOptions } from "@/utils/config/newCard";

import { cardPageMixins } from "@/mixin/cardPage";
import authStatus from "@/mixin/authStatus";

import arrowBottom from "@/assets/card-imgs/new-arrow-bottom.png";
import more from "@/assets/card-imgs/new-more.png";
import reload from "@/assets/card-imgs/new-reload.png";
import arrowTop from "@/assets/card-imgs/new-arrow-top.png";
import checkout from "@/assets/card-imgs/checkout.png";
import loginOut from "@/assets/card-imgs/new-loginout.png";
import updatepwd from "@/assets/card-imgs/new-updatepwd.png";
import authPwd from "@/assets/card-imgs/new-authPwd.png";
import noCardInfo from "@/assets/card-imgs/no-card.png";
import sanJiao from "@/assets/card-imgs/cardOptions/new-sanjiao.png";
const TabWidth = 112; // tab固定宽度
const cardWidth = 272; // 卡台信息固定宽度
const cardOptionHos = 164; // 卡台选项横向偏移量
let resResultDataObj = {}; // 元数据（后台接口返回处理后的初始化数据）
let cardListInfoArr = []; // 卡台总数据
let hasShowOptions = false; // 是否有显示的options操作选项

let mySelfStaffList = []; // 自己下属员工列表
let mySelfAndMyStaffCardList = []; // 自己及下属员工卡台列表

// 低消进度统计表
import drawerMinDetail from "@/components/money/newDrawerMinDetail.vue";
import drawerTYDetail from "@/components/money/newDrawerTYDetail.vue";

// 估清弹框
import outSomething from "./orderMeal/newOrderMealList.vue";

import updatePassword from "@/components/common/newUpdatePassword.vue";
import updateAuthPassword from "@/components/common/newUpdateAuthPassword.vue";
import drawerSaveWine from "@/components/order/newSaveWine/drawerSaveWine/index.vue";
import drawerGetWine from "@/components/order/newSaveWine/drawerGetWine/index.vue";
import drawerPayToStore from "@/components/order/newSaveWine/drawerPayToStore/index.vue";

// 添加 eventVue 引入
import eventVue from "@/utils/eventVue";

export default {
  data() {
    return {
      // loadIndex: 0,
      // modelVisible: true, // 是否��示未开启营��日模态框
      socket: null,
      showFullPageTable: false, // 是否显示全屏表格（转台等操作）
      showMinDetailDrawer: false, // 低消进度统计表
      showOrHideOutSomething: false, // 是否显示估清商品
      showOrHideTYDetail: false, // 鸡尾酒明细表
      typeModule: 1, // 1:点单模式  2：存酒模式
      tab: {
        tabListOrigin: [], // 原始数据（只经过排序处理的数据）
        tabList: [],
        activeIndex: 2001,
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
      imgSrc: {
        reload,
        arrowBottom,
        more,
        arrowTop,
        checkout,
        loginOut,
        updatepwd,
        authPwd,
        noCardInfo,
        sanJiao,
      },
      legendList: legendList.filter((item) => item.id !== 2),
      legendActive: 0,
      authName: "", // 员工姓名
      arrowStatus: "", // 鼠标按下按钮状态
      // 图例操作选项

      legendOptions: {
        showUpdatePwd: false, // 是否显示更改密码或退出
        showMoreFunc: false, // 是否显示更多功能
        updatePwdModel: false, // 是否显示更改密码模态框
        showAuthPwdModel: false, // 是否显示授权密码模态框
      },
      cardStatusNoInfo: {}, // 图例抵达卡台数量

      saveWineInfo: {
        show: false,
      },
      getWineInfo: {
        show: false,
      },
      payToStoreInfo: {
        show: false,
      },

      salesCanLookCardInfo: {
        all_seat: 0,     // 1 是  2 否 (否的话, 看返回的卡台列表)
        seats: []
      }, // 营销可查单区域列表
      safeModeEnabled: false, // 从 computed 移到 data 中
    };
  },
  methods: {
    // 获取tab展示的数量
    getTabShowCount(callback) {
      const windowWidth = document.body.clientWidth;
      this.tab.tabMaxCount = Math.floor(windowWidth / TabWidth) - 1;
      this.card.centerTypeWidth =
        Math.floor(windowWidth / cardWidth) * cardWidth;
      callback && callback();
    },


    // 获取tab数据
    getTabList(arr = []) {
      // 判断当前登录身份 1：服务员  2：营销  3：特饮/花篮
      const roleIds = this.$store.state.userInfo.roleIds;
      let FUTabList = [];
      let YXTabList = [];
      let HLTabList = [];
      let QCTabList = [];
      
      if (roleIds.includes(2)) {
        // 有服务员权限
        FUTabList = this.getAuthArea(JSON.parse(JSON.stringify(arr)));
      }

      // 有营销
      if (roleIds.includes(3)) {
        if (this.salesCanLookCardInfo.all_seat != 1) {
          YXTabList = [...JSON.parse(JSON.stringify(arr)).filter(i => 
            this.$store.state.cardPageInfo.resResultDataObj.cardInfo
              .filter(item => this.salesCanLookCardInfo.seats.includes(item.id * 1))
              .map(item => item.regionId)
              .includes(i.id)
          )];
        } else {
          YXTabList = [...arr];
        }
      }

      // 特饮，也需要判断可点区域
      if (roleIds.includes(4)) {
        HLTabList = this.getAuthArea(JSON.parse(JSON.stringify(arr)));
      }
      
      if (this.hasLookOrder) {
        QCTabList = [...arr];
      }

      if (!(roleIds.includes(2) || roleIds.includes(3) || roleIds.includes(4) || this.hasLookOrder)) {
        // 无任何权限
        arr = [];
      } else {
        arr = [...FUTabList, ...YXTabList, ...HLTabList, ...QCTabList].filter(
          (item, index, arr) => arr.findIndex((items) => items.id == item.id) == index
        );
      }

      let tabList = arr
        .sort((a, b) => a.dsp - b.dsp)
        .filter((item) => item.status == 1); // status:  1:有效 2:无效

      this.tab.tabListOrigin = JSON.parse(JSON.stringify(
        [...FUTabList, ...YXTabList, ...HLTabList, ...QCTabList]
          .filter((item, index, arr) => arr.findIndex((items) => items.id == item.id) == index)
          .sort((a, b) => a.dsp - b.dsp)
          .filter((item) => item.status == 1)
      ));

      tabList = tabList.filter(
        (e) => this.filterCardList("regionId", e.id).length > 0
      );

      this.$store.commit("updateTabList", this.tab.tabListOrigin);

      tabList.unshift({
        id: 0,
        name: "全部",
      });
      tabList.unshift({
        id: 2001,
        name: "我的卡台",
      });

      if (tabList.length > this.tab.tabMaxCount) {
        this.tab.anotherInfo = tabList.splice(this.tab.tabMaxCount - 1);
        tabList.push({
          id: 999,
          name: "其它",
        });
      }

      this.tab.tabList = tabList;
      if(this.safeModeEnabled) {
        this.tab.tabList = this.tab.tabList.filter(item => !item.name.includes('特饮'));
        this.tab.anotherInfo = this.tab.anotherInfo.filter(item => !item.name.includes('关联'));
      }
    },

    // 获取卡台数据
    async getCardList(cardInfo = [], businessData = []) {
      // 当岗位是营销时
      if (this.isSaleRole) {
        await this.getLookSelfCardList()
      }
      // // 获取设备可操作区域或卡台
      const currentAreaAndCardList = this.getCurrentAreaAndCardList();

      const orderPersonInfo =
        this.$store.state.cardPageInfo.resResultDataObj["orderPersonInfo"] ||
        [];
      const departmentInfo =
        this.$store.state.cardPageInfo.resResultDataObj["departmentInfo"] || [];

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
          [...this.$store.state.cardPageInfo.resResultDataObj.cardInfo || []] || [];

        // 最终经过筛选过后的区域列表，对应元数据的areaInfo
        let resultAreaList = [];
        // 最终经过筛选过后的卡台列表，对应元数据的cardInfo
        let resultCardList = [];
        // 筛选营销中符合设备限制的所有卡台
        let salesSeats = []
        areaIdList.forEach((el) => {
          // 存储配置区域的区域下所有卡台
          const currentAreaCardList = allCardInfo.filter(
            (item) => (item.regionId == el)
          );
          if (this.salesCanLookCardInfo.all_seat != 1) {
            salesSeats = [...salesSeats, ...this.salesCanLookCardInfo.seats.filter(id => currentAreaCardList.map(i => i.id).includes("" + id))]
          }
          resultCardList = [...resultCardList, ...currentAreaCardList];
        });

        cardListNew.forEach((el) => {
          const find = allCardInfo.find(
            (item) => item.id == el.region_o_seat_id
          );
          if (find) {
            if (this.salesCanLookCardInfo.all_seat != 1 && this.salesCanLookCardInfo.seats.includes(find.id * 1)) {
              salesSeats = [...salesSeats, find.id * 1]
            }
            resultCardList.push(find);
            if (!areaIdList.find((item) => item == find.regionId)) {
              areaIdList.push(find.regionId);
            }
          }
        });

        // 经过区域和卡台的筛选，理出所有营销符合设备限制的卡台id
        this.salesCanLookCardInfo.seats = [...salesSeats]
        cardInfo = resultCardList;
      }
      cardInfo = cardInfo.sort((a, b) => a.dsp - b.dsp);
      let cardList = [];

      cardInfo.forEach((item, index) => {
        if (item.status == "1") {
          // 查找对应的业务数据
          const data = businessData.find((el) => el.seatId === item.id) || {};
          if (data.bizStatus != "22" && data.bizStatus != "33") {
            // 订位人upper_emp_id
            function get_upper_emp_id() {
              const sealPersonInfo = orderPersonInfo.find(
                (el) => data.salesEmpId === el.id
              );
              return sealPersonInfo ? sealPersonInfo.upper_emp_id : ''
            }
            // 订位人的上级id
            const upper_emp_id = get_upper_emp_id()
            data.upper_emp_id = upper_emp_id
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
              // 当前卡台所处状态的小卡片
              tipsArr: this.getTips(data.bizStatus),
              // 是否可查单
              canLookOrder: this.currentCardCanLookOrder(item.name, data),
              isYX: this.checkYX(item),
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
              options: this.getCardOptions(data.bizStatus, data.turnoverCnt),
              // 是否显示卡台的操作按钮选项
              // showOption: this.card.cardList[index] && this.card.cardList[index].showOption
              showOption:
                cardListInfoArr[index] && cardListInfoArr[index].showOption,
              isLeftArrow: false, // 操作选项列表是否显示在左边
              // 订位人upper_emp_id
              upper_emp_id: upper_emp_id,
            });


          }
        }
      });
      console.log('cardList', cardList)
      // 初始化图例中显示的抵达数量
      this.setLegendCount(this.tab.activeIndex);

      if (
        (this.$store.state.userInfo.roleIds.includes(2) ||
          this.$store.state.userInfo.roleIds.includes(3)
          || this.$store.state.userInfo.roleIds.includes(4)) &&
        !this.modelVisible
      ) {
        // 服务员/营销/特饮  且已开启营业日
        cardList = await this.addOwnPayedAmtToCard(cardList);
      }

      // 获取功能台或者关联功能台的金额信息
      // 根据card_ids调用reqGetSpSeatList
      // 卡台类型 '1' 实体台 '2' 虚拟台 '3' 关联功能台 '4' 功能台
      let seat_ids = cardList.filter((item) => item.bizType == '3').map((item) => item.id * 1)
      if(seat_ids.length > 0) {
        try {
          const res = await api_money.reqGetSpSeatList({
            seat_ids,
          });
          if (res.code == 1) {
            /**
             *     客户端传入json:
              seat_ids   []int64      //SeatIds 待读取功能台列表,读取点单金额和优惠金额
            成功返回编码:1, 返回json:
              records    []*ResGetSpSeatListItem //Records 记录列表
                --------------------------------
                引用 ResGetSpSeatListItem 格式:
                  s          int64      //SeatId 卡台Id
                  y          int64      //YhAmt 优惠金额,单位分,需要前端格式化
                  o          int64      //OrderAmt 下单金额,单位分,需要前端格式化
            普通失败, 返回编码<>1, 数据为空
            */
            const { records } = res.data;
            cardList.forEach((item, index) => {
              const find = records.find((el) => el.s == item.id);
              if (find) {
                cardList[index].yhAmt = ((find.yh_amt || 0) / 100).toFixed(2);
                cardList[index].orderAmt = ((find.order_amt || 0) / 100).toFixed(2);
                cardList[index].payed_val_amt = ((find.payed_val_amt || 0) / 100).toFixed(2);
                cardList[index].order_zy_amt = ((find.order_zy_amt || 0) / 100).toFixed(2);
                cardList[index].payedAmt = ((find.payed_amt || 0) / 100).toFixed(2);
                cardList[index].payed_zy_val_amt = ((find.payed_zy_val_amt || 0) / 100).toFixed(2);
              }
            });
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("读取功能台卡台点单金额和优惠金额失败", error);
        }
      }

      if (this.hasForbidUnTipTableAuth()) {
        cardList = cardList.filter(item => {
          return (item.bizStatus !== '1' && item.bizStatus !== '2' && item.bizStatus !== '8')
        })
      }

      // 没有配置任何权限同时不具有全场查单权限
      if (this.isUserWithoutRoles()) {
        cardListInfoArr = [];
        // this.$message.warning('当前账号未配置可点区域')
      } else {
        cardListInfoArr = JSON.parse(JSON.stringify(cardList)); // 首次更改，为了给获取自己及下属员工卡台提供数据
      }

      await this.getTabList(JSON.parse(JSON.stringify(this.$store.state.cardPageInfo.resResultDataObj["areaInfo"])));

      // 如果是服务员或者特饮，需要根据可点区域限制可点卡台
      if (
        this.$store.state.userInfo.roleIds.includes(2) ||
        this.$store.state.userInfo.roleIds.includes(4)
      ) {
        cardListInfoArr = JSON.parse(JSON.stringify(cardList.filter(
          (item) =>
            this.tab.tabListOrigin.findIndex((i) => i.id == item.regionId) >= 0
        )));
        cardListInfoArr.forEach(item => item.isWaiter = true)
      }
      if(this.safeModeEnabled) {
        cardListInfoArr = cardListInfoArr.filter(item => {
          return (item.bizType !== '3' && item.bizType !== '4')
        })
      }

      // 如果只是营销 不写在这里前面的判断会把区域弄没
      // if (this.$store.state.userInfo.roleIds.includes(3) && this.$store.state.userInfo.roleIds.length == 1) {
      //   cardListInfoArr = []
      // }

      //trump 2024年08月03日01:23:55 如果有全场优惠权限，取消限制
      if (this.$store.state.userInfo.roleIds.includes(3)) {
        if (this.hasQuanchangyouhui){

        } else if (this.$store.state.userInfo.roleIds.length == 1){
          cardListInfoArr = []
        }
      }


      // 如果是营销，需要根据可点卡台列表限制卡台
      if (this.$store.state.userInfo.roleIds.includes(3) && this.salesCanLookCardInfo.all_seat != 1) {
        cardListInfoArr = [...cardListInfoArr, ...JSON.parse(JSON.stringify(cardList.filter(
          (item) => this.salesCanLookCardInfo.seats.includes(item.id * 1)
            && !cardListInfoArr.map(item => item.id).includes(item.id)
        )))]
      }

      // 如果是营销，添加可赠送卡台列表
      if (this.$store.state.userInfo.roleIds.includes(3)) {
        const giftableCardList = this.$store.state.cardPageInfo.resResultDataObj["giftableCard"].filter(item => item.station_id * 1 === this.$store.state.userInfo.station_id * 1 && item.status * 1=== 1)

        const giftableCardListTmp = JSON.parse(JSON.stringify(cardList)) || []
        // 遍历 giftableCardList，检查并添加数据
        giftableCardList.forEach(giftableCard => {
            // 检查 cardListInfoArr 中是否存在对应的 station_id 和 seat_id
            const exists = cardListInfoArr.some(card => 
                card.id *1 === giftableCard.seat_id *1
            );

            // 如果不存在，添加到 cardListInfoArr
            if (!exists) {
                cardListInfoArr.push(giftableCardListTmp.find(item => item.id * 1 === giftableCard.seat_id * 1));
            }
        });
      }

      try {
        // 此处为了解决点单系统websocket数据更新后页面不更新问题
        const index = this.tab.tabList.findIndex(
          (item) => item.id == this.tab.anotherInfoActiveId
        );
        this.changeTab(index, this.tab.activeIndex);
      } catch (error) {
        console.log("websocket数据更新了，但是此处报错了", error);
      }

      // this.$store.commit("updateCardList", cardList);
    },



    getCardOptions(bizStatus, turnoverCnt) {
      let cardOption = [];
      if (turnoverCnt <= 0) {
        // 未过翻台
        if (
          bizStatus == 4 ||
          bizStatus == 5 ||
          bizStatus == 6 ||
          bizStatus == 7
        ) {
          cardOption = [1, 2, 3];
        } else {
          cardOption = [3];
        }
      } else {
        if (
          bizStatus == 4 ||
          bizStatus == 5 ||
          bizStatus == 6 ||
          bizStatus == 7
        ) {
          cardOption = [1, 2, 3];
        } else {
          cardOption = [1, 3];
        }
      }
      return cardOption.map((item) =>
        orderSaveWineOptions.find((items) => items.id == item)
      );
    },



    /**
     * 检索与当前用户关联的卡台列表。
     * 
     * @returns {Array} 卡台列表。
     */
    getMyCardList() {
      const authEmpId =
        this.$store.state.userInfo && this.$store.state.userInfo.emp_id;

      const list = cardListInfoArr.filter((item) => {
        item.waiter_emp_ids_arr = item.waiter_emp_ids_arr || [];
        return item.waiter_emp_ids_arr.includes(authEmpId.toString()) || item.salesEmpId == this.loginUserInfo.emp_id;
      });
      return list;
    },

    /**
     * 根据指定的键和ID筛选卡台列表。
     * 
     * @param {string} key - 用于筛选卡台列表的键。
     * @param {number} id - 用于筛选卡台列表的ID。
     * @param {Array} cardList - 可选的卡台列表进行筛选。
     * @returns {Array} 筛选后的卡台列表。
     */
    filterCardList(key, id, cardList) {
      let targetCardList = cardListInfoArr;
      if (cardList) {
        targetCardList = cardList;
      }
      targetCardList.forEach((el) => {
        el.showOption = false;
      });

            /*
      对targetCardList返回的cardlist进行重新排序，按照tabListOrigin中regionId对应的dsp从小到大排，并且regionId一样的排在一起，regionId一样时，根据targetCardList的dsp从小到大排
      */

      let sortCardList = []
      this.tab.tabListOrigin && this.tab.tabListOrigin.forEach((item) => {
        const find = targetCardList.filter((el) => el.regionId == item.id);
        if (find.length > 0) {
          sortCardList.push(...find.sort((a, b) => {
            return a.dsp - b.dsp;
          }))
        }
      });
      targetCardList = sortCardList;
      const filterArr = targetCardList.filter((item) => item[key] == id);
      let result = (id == 2001 ? this.getMyCardList() : id == 0 ? JSON.parse(JSON.stringify(targetCardList)) : filterArr)
      if (this.hasForbidUnTipTableAuth()){
        result = result.filter(item => {
          return (item.bizStatus !== '1' && item.bizStatus !== '2' && item.bizStatus !== '8')
        })
      }
      if(this.safeModeEnabled) {
        result = result.filter(item => item.bizType * 1 !== 3)
        result = result.filter(item => item.bizType * 1 !== 4)
      }
      return result
    },



    /**
     * 递归检索与当前用户的下属关联的卡台列表。
     * 
     * @param {number} selfId - 用户的ID。如果未提供，则使用当前用户的ID。
     */
    getSelfStaffList(selfId) {
      // 未传值表明是当前登录账号人的id
      selfId = selfId || this.$store.state.userInfo.emp_id;
      const allStaffList =
        this.$store.state.cardPageInfo.resResultDataObj["orderPersonInfo"];
      // 当��员工的下级
      const selfStaffList = allStaffList.filter(
        (el) => el.upper_emp_id == selfId
      );
      if (selfStaffList.length > 0) {
        // 当前员工有下级
        mySelfStaffList.push(...selfStaffList);
        selfStaffList.forEach((ele) => {
          this.getSelfStaffList(ele.id);
        });
      }
    },


    /**
     * 检索与当前用户及其下属关联的卡台列表。
     */
    getSelfAndSelfStaffCardList() {
      mySelfAndMyStaffCardList = [];

      this.getSelfStaffList();
      const resultStaffList = [
        this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.find(
          (el) => el.id == this.$store.state.userInfo.emp_id
        ),
        ...mySelfStaffList,
      ];

      if (resultStaffList.length == 0) return;

      resultStaffList.forEach((el) => {
        const staffItemCardList = cardListInfoArr.filter(
          (ele) =>
            ele.salesEmpId == el.id && // 卡台订位人
            (ele.bizStatus == 4 || // 开台
              ele.bizStatus == 5 || // 点单未结账
              ele.bizStatus == 6 || // 部分结账
              ele.bizStatus == 7) // 已结账
        );

        if (staffItemCardList.length > 0) {
          mySelfAndMyStaffCardList.push(...staffItemCardList);
        }
      });

      // 需要进一步去重，因为有可能两个人共同拥有同一个卡台
      let map = new Map();
      for (let item of mySelfAndMyStaffCardList) {
        if (!map.has(item.id)) {
          map.set(item.id, item);
        }
      }
      mySelfAndMyStaffCardList = [...map.values()].map((item) => ({
        ...item,
        isOwnBookedCard: true,
      }));

      mySelfAndMyStaffCardList.forEach((el) => {
        cardListInfoArr.forEach((ele) => {
          if (el.id == ele.id) {
            ele.isOwnBookedCard = el.isOwnBookedCard;
          }
        });
      });

      // console.log("mySelfAndMyStaffCardList", JSON.parse(JSON.stringify(mySelfAndMyStaffCardList)));
    },



    // 点击卡台
    async handleOrderClick(info) {
      console.log("点击卡台开始跳转", info);
      // 检查卡台状态
      if (info.bizStatus == 1 || info.bizStatus == 2 || info.bizStatus == 8) {
        return this.$message.warning("空台/锁台/预定状态卡台不可点单！");
      }

      try {
        // 开启骨架屏
        this.$store.commit('setSkeletonDebug', true);

        // 预加载数据
        const promises = [
          // 清空产品列表
          this.$store.commit('clearProductList'),
          // 更新当前卡台信息
          this.$store.commit("updateOrderInfo", {
            key: "currentCardInfo",
            value: info,
          })
        ];

        // 并行执行所有状态更新
        await Promise.all(promises);

        // 使用 replace 进行路由跳转
        this.$router.replace({
          name: 'orderMeal',
          query: {
            cardId: info.id,
            _t: Date.now(), // 添加时间戳避免缓存
            skeleton: 'true', // 标记是否显示骨架屏
            ...this.$route.query
          }
        });
      } catch (error) {
        console.error('Error during navigation:', error);
        this.$message.error('跳转失败，请重试');
        // 发生错误时关闭骨架屏
        this.$store.commit('setSkeletonDebug', false);
      }
    },


    // 操作图例legend中的option
    async legendOptionHandle(type) {
      switch (type) {
        case "pwd": // 点击修改密码系列
          this.legendOptions.showUpdatePwd = !this.legendOptions.showUpdatePwd;
          this.legendOptions.showMoreFunc = false;
          break;
        case "logout": // 登出
          this.showConfirmHandle("退出登录", "是否退出登录？", async () => {
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
          });
          break;
        case "updatePwd":
          this.legendOptions.updatePwdModel = true;
          break;
        case "authPwd":
          this.legendOptions.showAuthPwdModel = true;
          break;
        case "more": // 更多功能
          if (this.$store.state.userInfo.check_priv == 3) {
            return this.$message.warning("开发中，敬请期待...");
          }
          this.legendOptions.showMoreFunc = !this.legendOptions.showMoreFunc;
          this.legendOptions.showUpdatePwd = false;
          break;
        default:
          this.legendOptions.showUpdatePwd = false;
          break;
      }
    },


    // 请求全量基础数据(首次页面加载在父组件中调用(返回到此页面数据由mounted加载))
    async getAllData() {
      this.getAuthStatus();
      // const loading = this.$loading({
      //   lock: true,
      //   text: "Loading",
      //   spinner: "el-icon-loading",
      //   background: "rgba(0, 0, 0, 0.7)"
      // });
      try {
        resResultDataObj = this.$store.state.cardPageInfo.resResultDataObj;
        if (
          !resResultDataObj &&
          (!resResultDataObj["areaInfo"] ||
            !resResultDataObj["cardInfo"] ||
            !resResultDataObj["businessData"])
        )
          return;

        // console.log("inOrder", resResultDataObj);
        // 获取卡台数据
        await this.getCardList(
          resResultDataObj["cardInfo"],
          resResultDataObj["businessData"]
        );

        // 获取自己及下属员工卡台列表
        if (this.$store.state.userInfo.roleIds.includes(3)) {
          this.getSelfAndSelfStaffCardList();
        }

        // 存储最终添加过下属员工卡台列表字段的最终数据
        this.$store.commit("updateCardList", cardListInfoArr);

        // 页面显示最新数据的卡台列表信息
        this.card.cardList = this.filterCardList(
          "regionId",
          this.tab.activeIndex
        );
        // this.$forceUpdate();
      } catch (error) {
        console.log("全量数据请求失败", error);
      }
      // loading.close();
    },


    // 给卡台数据添加登录人自己的点单金额
    async addOwnPayedAmtToCard(cardList) {
      const ownPayedCardList = (await this.getAuthOwnPayedAmt()) || [];
      return cardList.map((item) => {
        const OwnPayInfo = ownPayedCardList.find(
          (items) => items.s == item.seatId
        );
        return {
          ...item,
          ownPayedAmt: OwnPayInfo ? OwnPayInfo.a : "0",
        };
      });
    },

    // 获取当前登录人可自己的下单金额
    async getAuthOwnPayedAmt() {
      try {
        const res = await api_order.reqGetOwnPayAmt();
        if (res.code == 1) {
          return res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
        return [];
      } catch (error) {
        console.log("服务员自己点单金额获取失败", error);
      }
    },

    // 只是营销时 获取可查看卡台列表
    async getLookSelfCardList() {
      try {
        this.salesCanLookCardList = [];
        const res = await api_order.reqGetSalesmanSeatList();
        if (res.code == 1) {
          this.salesCanLookCardInfo.all_seat = res.data.all_seat || [];
          this.salesCanLookCardInfo.seats = res.data.seats || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("营销可查看卡台列表获取失败", error);
      }
    },

    // 当前卡台是否有查单权限
    currentCardCanLookOrder(n, cardItemInfo) {
      // 仅为营销时 不走下面鉴权 走接口返回的卡台列表
      const saleLookRole = this.salesCanLookCardInfo.seats.includes(cardItemInfo.seatId * 1);
      // 是否具有全场查单权限
      const isLookAll = this.hasLookOrder;
      // 是否是当前卡台订位人
      const isBooker =
        cardItemInfo.salesEmpId * 1 == this.$store.state.userInfo.emp_id * 1;
      // 是否是当前卡台点单服务员
      const waiter_emp_ids_arr = "waiter_emp_ids_arr" in cardItemInfo && cardItemInfo.waiter_emp_ids_arr || [];
      const isSealer =
        waiter_emp_ids_arr.find(
          (item) => item * 1 == this.$store.state.userInfo.emp_id * 1
        );
      // 是否是当前卡台订位人的同组人员
      let isLookDept = this.hasYXCanLookDept && cardItemInfo && cardItemInfo.upper_emp_id != 0 && cardItemInfo.upper_emp_id == this.loginUserInfo.upper_emp_id;

      // 下过单的服务员 也属于同组 
      let isWaiterDept = false;
      const orderPersonInfo =
        this.$store.state.cardPageInfo.resResultDataObj["orderPersonInfo"] || [];
      for (let i = 0; i < waiter_emp_ids_arr.length; i++) {
        const element = waiter_emp_ids_arr[i];
        if (element) {
          const waiter = orderPersonInfo.find(
            (item) => item.id == element);
          if (waiter && waiter.upper_emp_id == this.loginUserInfo.upper_emp_id && this.loginUserInfo.upper_emp_id != 0) {
            isWaiterDept = true;
            break
          }
        }
      }
      // 不允许查看同组
      if (!this.hasYXCanLookDept) {
        isWaiterDept = false;
      }

      let isLookSubordinate = cardItemInfo && this.loginUserSubordinateIds.includes(cardItemInfo.salesEmpId);

      // 服务员的下属 
      let isWaiterSealer = false;
      for (let i = 0; i < waiter_emp_ids_arr.length; i++) {
        const element = waiter_emp_ids_arr[i];
        if (this.loginUserSubordinateIds.includes(element)) {
          isWaiterSealer = true;
          break;
        }
      }

      // 营销 不能看下属
      if (this.hasYxOnlyLookSelf) {
        isLookSubordinate = false
      }
      // 下单服务员包括营销 所以都要判断
      if (this.hasWaitOnlyLookSelf || this.hasYxOnlyLookSelf) {
        isWaiterSealer = false
      }

      return saleLookRole || isLookAll || isBooker || isSealer || isLookDept || isWaiterDept || isLookSubordinate || isWaiterSealer;
    },

    checkYX(item) {
      if (this.salesCanLookCardInfo.all_seat != 1) {
        return this.salesCanLookCardInfo.seats.includes(item.id * 1)
      } else {
        return true
      }
    },

    // 显示或隐藏低消进度统计表
    showOrHideMinDetailDrawerHandle() {
      this.showMinDetailDrawer = !this.showMinDetailDrawer;
    },
    // 显示或隐藏估清商品
    showOrHideOutSomethingHandle(value) {
      this.showOrHideOutSomething = !this.showOrHideOutSomething;
    },
    // 鸡尾酒明细表
    showOrHideTYDetailDrawer() {
      this.showOrHideTYDetail = !this.showOrHideTYDetail;
    },


    /*
    存酒相关
  */
    checkOutModuleHandle() {
      this.typeModule = this.typeModule == 1 ? 2 : 1;
    },


    optionsClickHandle(optionsInfo, cardInfo) {
      switch (optionsInfo.id) {
        case 1:
          this.saveWineInfo.show = true;
          break;
        case 2:
          this.getWineInfo.show = true;
          break;
        case 3:
          this.payToStoreInfo.show = true;
          break;
      }
      this.$store.commit("updateOrderInfo", {
        key: "saveWineCardInfo",
        value: cardInfo,
      });
    },


    keydownHandle(e) {
      if (e.keyCode == 13) {
        this.$nextTick(() => {
          if (this.legendOptions.updatePwdModel) {
            // 修改密码
            this.$refs.updatePassword.onSubmit();
          } else if (this.legendOptions.showAuthPwdModel) {
            // 授权密码
            this.$refs.updateAuthPassword.onSubmit();
          } else if (this.showOrHideOutSomething) {
            // 估清
            const com = this.$refs.outSomething.$children.find(
              (item) => item.$el.className == "product-list-GQ"
            );
            if (com.drawer.showDrawer) {
              com &&
                com.$refs.mealDrawer &&
                com.$refs.mealDrawer.$refs.singleProductRef &&
                com.$refs.mealDrawer.$refs.singleProductRef.onSubmit();
            } else {
              com && com.$emit("showOrHideOutSomethingHandle");
            }
          }
        });
      } else if (e.keyCode == 27) {
        // esc
        if (this.showOrHideOutSomething) {
          // 估清
          const com = this.$refs.outSomething.$children.find(
            (item) => item.$el.className == "product-list-GQ"
          );
          com && com.$emit("showOrHideOutSomethingHandle");
        }
      }
    },


    rightClickHandle() {
      return false;
    },


    isUserWithoutRoles() {
      return this.$store.state.userInfo.roleIds.length == 0;
    },


    getCurrentAreaAndCardList() {
      const currentMachineId = this.$localStorage.getItem("machineId");
      return (resResultDataObj["machineArea"] || []).filter(
        (item) => item.license_id == currentMachineId && item.status == 1
      );

    },

    // 登录后初始化图例中的抵达数量
    setLegendCount(regionId = 0) {
      setTimeout(() => {

        let result = {};
        if (this.isUserWithoutRoles()) {
          this.cardStatusNoInfo = {};
          return;
        }
        // 获取设备可操作区域或卡台
        const currentAreaAndCardList = this.getCurrentAreaAndCardList();
        const isNoLimit = currentAreaAndCardList.filter(
          (item) => item.type_id == 3
        );
        // 区域下部分卡台
        let cardStatusNo =
          regionId == 2001
            ? this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo.filter(
              (item) =>
                this.card.cardList.findIndex((i) => i.regionId == item.region_id) >=
                0
            ) || []
            : regionId == 0 ? this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo : 
            this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo.filter(
              (item) =>
                this.tab.tabListOrigin.findIndex(
                  (i) => i.id == item.region_id
                ) >= 0
            ) || [];
        // 如果只是营销,又没有全场查单，需要通过设备情况一个个判断状态并累加
        if (this.isSaleRole && this.salesCanLookCardInfo.all_seat != 1) {
          let seats = this.salesCanLookCardInfo.seats
          this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo.filter(item =>
            seats.includes(item.region_id * 1) && (item.id == '30' || item.id == '31')
            && this.$store.state.cardPageInfo.resResultDataObj.cardInfo.filter(it => it.id == item.region_id
              && seats.includes(it.id * 1) && (it.regionId == regionId || regionId == 0 || regionId == 2001)).length > 0)
            .forEach(item => {
              item.id == 30 ?
                result["10"] =
                (result["10"] || 0) * 1 + item.cnt * 1  // 开台数
                : result["20"] =
                (result["20"] || 0) * 1 + item.cnt * 1  // 抵达数
            })
          this.card.cardList
            .filter((item) => seats.includes(item.id * 1))
            .forEach((el) => {
              if (el.bizStatus != 4 && el.bizStatus != 20) {
                // 除了开台数和抵达数以外的状态
                result[el.bizStatus] =
                  (result[el.bizStatus] || 0) * 1 + 1;
              }
            });
          result["5"] = result["6"] || 0 + result["5"] || 0;
          this.cardStatusNoInfo = result;
          if (this.$store.state.userInfo.roleIds.includes(3) && this.$store.state.userInfo.roleIds.length == 1) {
            return;
          }
        }

        if (isNoLimit.length > 0) {
          // 没有对设备进行卡台或区域限制
          if (regionId == 0 || regionId == 2001) {
            // 选择的'全部' 或我的卡台
            if (
              this.$store.state.userInfo.roleIds.length == 1 &&
              this.$store.state.userInfo.roleIds[0] == 2
            ) {
              // 累计卡台数
              const allOpenInfo = cardStatusNo.filter((item) => item.id == 30);
              // 累计抵达数
              const allArriveInfo = cardStatusNo.filter(
                (item) => item.id == 31
              );
              // 服务员，显示的我的卡台
              this.card.cardList.forEach((el) => {
                if (el.bizStatus != 4 && el.bizStatus != 20) {
                  // 除了开台数和抵达数以外的状态
                  result[el.bizStatus] = (result[el.bizStatus] || 0) * 1 + 1;
                }
                // 开台数、抵达数
                const currentSeatOpenInfo = allOpenInfo.find(
                  (items) => items.region_id == el.id
                ) || { cnt: 0 };
                const currentSeatArriveInfo = allArriveInfo.find(
                  (items) => items.region_id == el.id
                ) || { cnt: 0 };
                result["10"] =
                  (result["10"] || 0) * 1 + currentSeatOpenInfo.cnt * 1; // 开台数
                result["20"] =
                  (result["20"] || 0) * 1 + currentSeatArriveInfo.cnt * 1; // 抵达数
              });
            } else {
              if (regionId == 2001) {
                // 累计卡台数
                const allOpenInfo = cardStatusNo.filter(
                  (item) => item.id == 30
                );
                // 累计抵达数
                const allArriveInfo = cardStatusNo.filter(
                  (item) => item.id == 31
                );
                // 服务员，显示的我的卡台
                this.card.cardList.forEach((el) => {
                  if (el.bizStatus != 4 && el.bizStatus != 20) {
                    // 除了开台数和抵达数以外的状态
                    result[el.bizStatus] = (result[el.bizStatus] || 0) * 1 + 1;
                  } else {
                    // 开台数、抵达数
                    const currentSeatOpenInfo = allOpenInfo.find(
                      (items) => items.region_id == el.id
                    ) || { cnt: 0 };
                    const currentSeatArriveInfo = allArriveInfo.find(
                      (items) => items.region_id == el.id
                    ) || { cnt: 0 };
                    result["10"] =
                      (result["10"] || 0) * 1 + currentSeatOpenInfo.cnt * 1; // 开台数
                    result["20"] =
                      (result["20"] || 0) * 1 + currentSeatArriveInfo.cnt * 1; // 抵达数
                  }
                });
              } else {
                // 显示的全部
                cardStatusNo.forEach((el) => {
                  if (result[el.id] != undefined) {
                    result[el.id] = result[el.id] * 1 + el.cnt * 1;
                  } else {
                    result[el.id] = el.cnt * 1;
                  }
                });
              }
            }
          } else {
            cardStatusNo
              .filter((item) => item.region_id == regionId)
              .forEach((el) => {
                if (result[el.id] != undefined) {
                  result[el.id] = result[el.id] * 1 + el.cnt * 1;
                } else {
                  result[el.id] = el.cnt * 1;
                }
              });
          }
        } else {
          // 对设备进行了卡台区域配置
          if (regionId == 0 || regionId == 2001) {
            // 选择的'全部'
            this.tab.tabListOrigin.forEach((el) => {
              if (el.isAllCard) {
                // 区域下所有卡台
                const currentAreaData = cardStatusNo.filter(
                  (item) => item.region_id == el.id
                );
                // 当前区域下所有卡台都展示
                currentAreaData.forEach((el) => {
                  if (result[el.id] != undefined) {
                    result[el.id] = result[el.id] * 1 + el.cnt * 1;
                  } else {
                    result[el.id] = el.cnt * 1;
                  }
                });
              } else {
                // 累计卡台数
                const allOpenInfo = cardStatusNo.filter(
                  (item) => item.id == 30
                );
                // 累计抵达数
                const allArriveInfo = cardStatusNo.filter(
                  (item) => item.id == 31
                );
                this.card.cardList
                  .filter((item) => item.regionId == el.id)
                  .forEach((item) => {
                    if (item.bizStatus != 4 && item.bizStatus != 20) {
                      // 除了开台数和抵达数以外的状态
                      result[item.bizStatus] =
                        (result[item.bizStatus] || 0) * 1 + 1;
                    } else {
                      // 开台数、抵达数
                      const currentSeatOpenInfo = allOpenInfo.find(
                        (items) => items.region_id == el.id
                      ) || { cnt: 0 };
                      const currentSeatArriveInfo = allArriveInfo.find(
                        (items) => items.region_id == el.id
                      ) || { cnt: 0 };
                      result["10"] =
                        (result["10"] || 0) * 1 + currentSeatOpenInfo.cnt * 1; // 开台数
                      result["20"] =
                        (result["20"] || 0) * 1 + currentSeatArriveInfo.cnt * 1; // 抵达数
                    }
                  });
              }
            });
          } else {
            const currentAreaInfo =
              this.tab.tabListOrigin.find(
                (item) => item.id == this.tab.activeIndex
              ) || {};
            if (currentAreaInfo.isAllCard) {
              const currentAreaData = cardStatusNo.filter(
                (item) => item.region_id == regionId
              );
              // 当前区域下所有卡台都展示
              currentAreaData.forEach((el) => {
                if (result[el.id] != undefined) {
                  result[el.id] = result[el.id] * 1 + el.cnt * 1;
                } else {
                  result[el.id] = el.cnt * 1;
                }
              });
            } else {
              // 展示的是当前区域下部分卡台的信息，需要重新计算卡台的数量
              // 累计卡台数
              const allOpenInfo = cardStatusNo.filter((item) => item.id == 30);
              // 累计抵达数
              const allArriveInfo = cardStatusNo.filter(
                (item) => item.id == 31
              );
              this.card.cardList.forEach((el) => {
                if (el.bizStatus != 4 && el.bizStatus != 20) {
                  // 除了开台数和抵达数以外的状态
                  result[el.bizStatus] = (result[el.bizStatus] || 0) * 1 + 1;
                }
                // 开台数、抵达数
                const currentSeatOpenInfo = allOpenInfo.find(
                  (items) => items.region_id == el.id
                ) || { cnt: 0 };
                const currentSeatArriveInfo = allArriveInfo.find(
                  (items) => items.region_id == el.id
                ) || { cnt: 0 };
                result["10"] =
                  (result["10"] || 0) * 1 + currentSeatOpenInfo.cnt * 1; // 开台数
                result["20"] =
                  (result["20"] || 0) * 1 + currentSeatArriveInfo.cnt * 1; // 抵达数
              });
            }
          }
        }
        // console.log(result);
        // 合并点单和半结
        result["5"] = result["6"] || 0 + result["5"] || 0;

        console.log("result", result)
        if (this.hasForbidUnTipTableAuth()){
          result["1"] = 0
          result["8"] = 0
        }

        this.cardStatusNoInfo = result;
      }, 200);
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
    // 手动切换卡台订单状态
    changeCardStatus(cardStatusId) {
      if (cardStatusId === this.legendActive) {
        // 点击的同状态一个按钮
        this.legendActive = 0;
        this.card.cardList = cardListInfoArr;
      } else {
        this.legendActive = cardStatusId;
        this.tab.anotherInfoActiveId = 0;
        this.tab.activeIndex = 0;
        this.tab.showAnotherInfo = false;
        this.card.cardList = this.filterCardList("bizStatus", cardStatusId);
      }
    },
  },



  async mounted() {

        // 记录组件完全挂载的时间
    const componentMountedTime = performance.now();
    console.log(`OrderCard 组件完全挂载耗时: ${componentMountedTime - window.routeStartTime}ms`);
    
    // 使用 Performance Mark API 记录关键时间点
    performance.mark('component-mounted');

    performance.mark('component-rendered');
    performance.measure('component-full-render', 'component-mounted', 'component-rendered');
    
    const renderMeasure = performance.getEntriesByName('component-full-render')[0];
    console.log(`组件完整渲染周期: ${renderMeasure.duration}ms`);
    
    // 初始化 safeModeEnabled
    let safeMode = this.$store.state.cardPageInfo.resResultDataObj.safeMode || []
    this.safeModeEnabled = safeMode.some(item => item.id * 1 === 1 && item.param1 * 1 === 1)

    // 添加事件监听
    eventVue.$on("safeModeChanged", (e) => {
      console.log('safeModeChanged', e)
      this.safeModeEnabled = e[0][0] * 1 === 1 && e[0][1] * 1 === 1
      console.log('safeModeEnabled coming here', this.safeModeEnabled)
      this.getCardList(
        this.$store.state.cardPageInfo.resResultDataObj["cardInfo"],
        this.$store.state.cardPageInfo.resResultDataObj["businessData"]
      );
    });

    window.addEventListener("click", (e) => this.legendOptionHandle());
    window.addEventListener("resize", this.windowResizeHandle);

    window.onkeydown = this.keydownHandle;

  },

  components: {
    updatePassword,
    updateAuthPassword,
    drawerSaveWine,
    drawerGetWine,
    drawerPayToStore,
    drawerMinDetail,
    drawerTYDetail,
    outSomething,
  },

  watch: {
    "tab.activeIndex": {
      handler(newVal, oldVal) {
        let regionId = "";
        if (newVal == 999) {
          // 选的的是'其他'按钮
          regionId = oldVal;
        } else {
          regionId = newVal;
        }

        this.setLegendCount(regionId);
      },
      immediate: true,
    },

  },
  computed: {
    // 是否有沽清权限
    hasOutSomething() {
      return (
        this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(5)
      );
    },
    // 是否有查单权限
    hasLookOrder() {
      return (
        this.$store.state.userInfo.roleIds &&
        this.$store.state.userInfo.roleIds.includes(11)
      );
    },
    hasQuanchangyouhui() {
      return (
          this.$store.state.userInfo.sys_modules &&
          this.$store.state.userInfo.sys_modules.includes(12)
      );
    },
    // 是否有存取酒
    hasWineAuth() {
      return (
        this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(1)
      );
    },

    // 不允许查看下属点单消费  只能看自己
    hasYxOnlyLookSelf() {
      return this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(10)
    },
    hasWaitOnlyLookSelf() {
      return this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(6)
    },

    //营销能查看同组点单消费
    hasYXCanLookDept() {
      return (
        this.$store.state.userInfo.sys_modules &&
        (this.$store.state.userInfo.sys_modules.includes(7) || this.$store.state.userInfo.sys_modules.includes(11))
      );
    },

    // 当前用户信息
    loginUserInfo() {
      return this.$store.state.userInfo;
    },
    // loginUser 下属列表
    loginUserSubordinateIds() {
      const orderPersonInfo =
        this.$store.state.cardPageInfo.resResultDataObj["orderPersonInfo"] ||
        [];
      const subordinateList = orderPersonInfo.filter(
        (item) => item.upper_emp_id == this.loginUserInfo.emp_id
      );
      const ids = subordinateList.map((d) => d.id);
      return ids;
    },

    // 有且只有一个营销角色权限  无替身或替身岗位也只有营销时
    isSaleRole() {
      let isSales = (this.$store.state.userInfo.roleIds &&
      this.$store.state.userInfo.roleIds.includes(3));
      let isCloneisSaleRole = true;
      // 无替身或替身也只是销售
      if (isSales && this.loginUserInfo.clone_emp_id != '0') {
        const orderPersonInfo =
          this.$store.state.cardPageInfo.resResultDataObj["orderPersonInfo"] ||
          [];
        const clone_person = orderPersonInfo.find(
          (item) => item.id == this.loginUserInfo.clone_emp_id
        );
        // 替身权限
        const sysRole = this.$store.state.cardPageInfo.resResultDataObj['sysRole'] || [];
        // 获取角色ids
        const roles = sysRole.filter(item => item.station_id == clone_person.stationId && item.status == 1);
        const roleIds = [...new Set(roles.map(d => d.sys_role_id * 1))];
        isCloneisSaleRole = roleIds.includes(3);
      }
      return isSales || isCloneisSaleRole
    },
    // 判断是否功能台或者功能关联台
    isFunctionCard() {
      return this.$store.state.cardPageInfo.resResultDataObj["cardInfo"].find(
        (item) => item.typeId == 3
      );
    },
  },

  beforeDestroy() {
    // 移除事件监听
    eventVue.$off("safeModeChanged");

    console.log("beforeDestroy");
    window.removeEventListener("resize", this.windowResizeHandle);
    window.removeEventListener("click", (e) => this.legendOptionHandle());

    window.onkeydown = null;

        // 清理性能标记
    performance.clearMarks();
    performance.clearMeasures();

  },
  destroyed() {
    console.log("destroyed");
  },

  filters: {
    // 根据区域id获取区域名称
    getAreaName: (areaId) => {
      const result = resResultDataObj.areaInfo.find((el) => el.id === areaId);
      return (result && result.name) || "";
    },
    // 根据部门id获取员工姓名
    getOrderPersonName: (orderPersonId) =>
      (resResultDataObj.orderPersonInfo.find((el) => el.id === orderPersonId) &&
        resResultDataObj.orderPersonInfo.find((el) => el.id === orderPersonId)
          .name) ||
      "散客",
    // 根据定位人（员工）id获取部门名称
    getDepartmentName: (orderPersonId) => {
      const sealPersonInfo = resResultDataObj.orderPersonInfo.find(
        (el) => el.id === orderPersonId
      );
      if (sealPersonInfo) {
        // 非散客（有定位人）
        const result = resResultDataObj.departmentInfo.find(
          (el) => el.id === sealPersonInfo.deptId
        );
        return (result && result.name) || "";
      } else {
        // 散客
        return "";
      }
    },
  },

  mixins: [cardPageMixins, authStatus],
  directives: {
    fastClick: {
      bind(el, binding) {
        let lastTime = 0;
        const delay = 100; // 设置一个较短的防抖时间
        
        el.addEventListener('click', (e) => {
          const currentTime = new Date().getTime();
          
          if (currentTime - lastTime > delay) {
            binding.value(e);
            lastTime = currentTime;
          }
        });
      }
    }
  },
};
</script>

<style scoped lang="less">
@import "../../style/common/scrollBar.less";
@import "../../style/order/newOrderCard.less";
@import "../../style/book/newCardBgc.less";


</style>

<style lang="less">
@import "../../style/common/elementConfirm.less";
.out-something {
  position: fixed;
  z-index: 10;
  width: 100vw;
  height: 100vh;
  left: 0;
  top: 0;
}

.v-modal {
  z-index: 1 !important;
}
</style>