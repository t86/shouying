<template>
  <div class="card-box">
    <div class="contain" ref="containRef">
      <div class="contain-content" ref="containContentRef">
        <!-- tab -->
        <div class="tab" layout="row" layout-align="start center">
          <div
            class="tab-item"
            :class="{ active: item.id === tab.activeIndex }"
            v-for="(item, index) in tab.tabList"
            :key="index"
            @click="changeTab(index, item.id)"
          >
            <span>{{ item.name }}</span>
            <div
              v-if="item.id === 999 && tab.showAnotherInfo"
              class="anotherInfo"
            >
              <li
                class="another-item"
                :class="{ active: items.id === tab.anotherInfoActiveId }"
                v-for="(items, i) in tab.anotherInfo"
                :key="i"
                @click.stop="changeTab('9999', items.id)"
              >
                <span>{{ items.name }}</span>
              </li>
            </div>
          </div>
        </div>
        <!-- 卡台列表 -->
        <div class="content">
          <div
            v-if="card.cardList.length > 0"
            class="center-type"
            :style="'width:' + card.centerTypeWidth + 'px'"
            layout="row"
            layout-align="start center"
          >
            <div
              class="card-item"
              v-for="(item, index) in card.cardList"
              :key="index"
              :class="[
                {
                  opacity:
                    typeModule == 1 &&
                    (item.bizStatus == 1 ||
                      item.bizStatus == 2 ||
                      item.bizStatus == 8),
                },
                'bgc' + Number(item.bizStatus),
              ]"
              @click.stop="cardClickHandle(item)"
              @contextmenu.prevent.stop="rightClickHandle"
            >
              <p layout="row" layout-align="space-between center">
                <span class="area-name">{{ item.regionId | getAreaName }}</span>
                <span>
                  <span v-if="item.mark" class="mark">{{ item.mark }}</span>
                  <span v-if="typeModule == 1">{{
                    item.openTime ? "(" + item.openTime + ")" : "" | filterTime
                  }}</span>
                </span>
              </p>

              <h3 class="card-name" layout="row" layout-align="start center">
                <div
                  style="white-space: nowrap; transform-origin: left center"
                  :style="{ transform: 'scale(' + item.cardNameScale + ')' }"
                >
                  {{ item.name }}
                </div>
              </h3>

              <!-- 存酒  取酒  充公入口按钮 -->
              <div
                class="save-wine-enter"
                v-if="typeModule == 2"
                layout="row"
                layout-align="start center"
              >
                <div
                  class="enter-item cursor"
                  :class="{ 'border-right': i < item.options.length - 1 }"
                  v-for="(el, i) in item.options"
                  :key="i"
                  @click.stop="optionsClickHandle(el, item)"
                >
                  <img :src="el.icon" />
                  <p>{{ el.name }}</p>
                </div>
              </div>

              <!-- 点单金额 -->
              <p
                style="height: 18px"
                layout="row"
                v-if="
                  typeModule == 1 &&
                  item.bizStatus != 1 &&
                  item.bizStatus != 2 &&
                  item.bizStatus != 8
                "
                layout-align="space-between center"
              >
                <span>
                  <!-- 有查单权限 -->
                  <span v-if="item.canLookOrder">点:￥{{ item.orderAmt }}</span>
                  <!-- 无查单权限 -->
                  <span v-else></span>
                </span>

                <!-- ------------------------ 点单金额 end ----------------------------- -->

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
                  $store.state.userInfo.roleIds.includes(3)
                "
              >
                <span>惠:￥{{ item.zengSongAmt }}</span>
              </p>
              <p v-else style="height: 18px"></p>

              <p
                layout="row"
                layout-align="space-between center"
                style="margin-top: 4px"
              >
                <!-- tips -->
                <span
                  v-if="typeModule == 1 && item.tipsArr.length > 0"
                  layout="row"
                  layout-align="space-between center"
                >
                  <span
                    class="card-tips"
                    :class="{ green: items !== '锁', yellow: items === '锁' }"
                    v-for="(items, i) in item.tipsArr"
                    :key="i"
                    >{{ items }}</span
                  >
                </span>

                <!-- 订位人 -->
                <span
                  v-else-if="
                    typeModule == 1 &&
                    item.bizStatus != 1 &&
                    item.bizStatus != 2
                  "
                  class="one-txt-cut"
                  style="width: 130px"
                >
                  {{ item.salesEmpId | getDepartmentName }}
                  {{ item.salesEmpId | getOrderPersonName }}
                </span>
                <!-- 用于占位 -->
                <span v-else></span>

                <!-- 翻台数 -->
                <span
                  v-if="
                    item.turnoverCnt > 0 &&
                    ($store.state.userInfo.roleIds.includes(2) ||
                      $store.state.userInfo.roleIds.includes(3))
                  "
                >
                  翻{{ item.turnoverCnt }}
                </span>
              </p>
            </div>
          </div>
          <!-- 无数据 -->
          <div v-else class="no-data">
            <img :src="imgSrc.noCardInfo" alt />
            <p>
              {{
                tab.activeIndex == 0
                  ? "暂无服务过的卡台，快去点单吧！"
                  : "暂无卡台数据"
              }}
            </p>
          </div>
        </div>
        <!-- 卡台图例tab -->
        <div class="legend" layout="row" layout-align="space-between center">
          <!-- 卡台状态图例 -->
          <div
            class="legend-list"
            layout="row"
            layout-align="space-around center"
          >
            <!-- 过滤掉锁台 -->
            <div
              class="legend-list-item"
              v-for="(item, index) in legendList"
              :key="item.id"
            >
              <span
                class="btn"
                v-if="item.id != 20"
                :class="{ active: legendActive === item.id }"
              >
                <div
                  class="img-contain"
                  :class="[item.id == 20 ? '' : 'bgc' + (index + 2)]"
                >
                  <img :src="item.allRight" alt />
                </div>
              </span>
              <span
                class="btn"
                style="transform: translateY(26px)"
                v-else
                :class="{ active: legendActive === item.id }"
              >
                <div
                  class="img-contain"
                  :class="[item.id == 20 ? '' : 'bgc' + (index + 2)]"
                >
                  <span style="color: #fff; line-height: 20px">{{
                    cardStatusNoInfo[20] || 0
                  }}</span>
                </div>
              </span>
              <p v-if="item.id != 20">
                <span style="margin-right: 2px">{{ item.name }}</span
                ><span>{{
                  cardStatusNoInfo[item.id == 4 ? 10 : item.id] || 0
                }}</span>
              </p>
              <p v-else style="transform: translateY(-28px)">
                <span style="margin-right: 2px">{{ item.name }}</span>
              </p>
            </div>
            <div
              class="legend-list-item reload-btn"
              :class="{ pressdown: arrowStatus === 'reload' }"
              @mousedown="keyDownHandle('reload')"
              @touchstart="keyDownHandle('reload')"
              @mouseup="keyDownHandle"
            >
              <img :src="imgSrc.reload" alt />
              <p>刷新</p>
            </div>
          </div>
          <!-- 操作面板 -->
          <div
            class="dosomething"
            layout="row"
            layout-align="space-between center"
          >
            <div
              class="dosomething-item checkout-btn"
              v-show="hasWineAuth"
              layout="column"
              layout-align="center center"
              @click.stop="checkOutModuleHandle"
            >
              <img :src="require('@/assets/card-imgs/checkout.png')" alt />
              <p class="m-t-1">
                {{ typeModule == 1 ? "存酒模式" : "点单模式" }}
              </p>
            </div>

            <div
              class="dosomething-item"
              layout="row"
              layout-align="space-between center"
            >
              <div
                class="arrow arr-left"
                :class="{ pressdown: arrowStatus === 'down' }"
                @mousedown="keyDownHandle('down')"
                @touchstart="keyDownHandle('down')"
                @mouseup="keyDownHandle"
              >
                <img :src="imgSrc.arrowBottom" alt />
              </div>
              <div
                class="arrow arr-right"
                :class="{ pressdown: arrowStatus === 'up' }"
                @mousedown="keyDownHandle('up')"
                @touchstart="keyDownHandle('up')"
                @mouseup="keyDownHandle"
              >
                <img :src="imgSrc.arrowBottom" alt />
              </div>
            </div>
            <div
              class="dosomething-item more-effect"
              @click.stop="legendOptionHandle('more')"
            >
              <img :src="imgSrc.more" alt />
              <p>更多功能</p>
              <div class="option more" v-if="legendOptions.showMoreFunc">
                <div
                  class="option-item"
                  @click="showOrHideMinDetailDrawerHandle()"
                >
                  <img
                    :src="require('@/assets/money-img/ty-detail-icon.png')"
                    alt
                  />
                  <span>低消进度统计表</span>
                </div>
                <div
                  v-if="hasOutSomething"
                  class="option-item line"
                  @click="showOrHideOutSomethingHandle(true)"
                >
                  <img :src="require('@/assets/money-img/guqing.png')" alt />
                  <span>估清商品</span>
                </div>
              </div>
              <img
                class="sj"
                v-if="legendOptions.showMoreFunc"
                :src="imgSrc.sanJiao"
                alt
              />
            </div>
            <div
              class="dosomething-item"
              @click.stop="legendOptionHandle('pwd')"
            >
              <img
                :src="imgSrc.arrowTop"
                :class="{ rotate: legendOptions.showUpdatePwd }"
                alt
              />
              <p>{{ authName }}</p>
              <!-- 操作选项 -->
              <div class="option" v-if="legendOptions.showUpdatePwd">
                <div
                  class="option-item"
                  @click.stop="legendOptionHandle('updatePwd')"
                >
                  <img :src="imgSrc.updatepwd" alt />
                  <span>修改密码</span>
                </div>
                <div
                  class="option-item authPwd"
                  @click.stop="legendOptionHandle('authPwd')"
                >
                  <img :src="imgSrc.authPwd" alt />
                  <span>授权密码</span>
                </div>
                <div
                  class="option-item logout"
                  @click.stop="legendOptionHandle('logout')"
                >
                  <img :src="imgSrc.loginOut" alt />
                  <span>退出登录</span>
                </div>
                <img :src="imgSrc.sanJiao" alt />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 修改密码 -->
    <updatePassword
      ref="updatePassword"
      :showDrawer="legendOptions.updatePwdModel"
      @submitHandle="submitUpdatePwdHandle"
      @cancelUpdatePwdHandle="cancelUpdatePwdHandle"
    />

    <!-- 授权密码 -->
    <updateAuthPassword
      ref="updateAuthPassword"
      :showDrawer="legendOptions.showAuthPwdModel"
      @submitHandle="submitUpdateAuthPwdHandle"
      @cancelUpdatePwdHandle="legendOptions.showAuthPwdModel = false"
    />

    <!-- 低消进度统计表 -->
    <drawerMinDetail
      :showDrawer="showMinDetailDrawer"
      @showOrHideDrawer="showOrHideMinDetailDrawerHandle"
    />

    <!-- 估清 -->
    <div class="out-something" v-if="showOrHideOutSomething">
      <outSomething
        ref="outSomething"
        @showOrHideOutSomethingHandle="showOrHideOutSomethingHandle"
      />
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

import { legendList, orderSaveWineOptions } from "@/utils/config/card";

import { cardPageMixins } from "@/mixin/cardPage";
import authStatus from "@/mixin/authStatus";

import arrowBottom from "@/assets/card-imgs/arrow-bottom.png";
import more from "@/assets/card-imgs/more.png";
import reload from "@/assets/card-imgs/reload.png";
import arrowTop from "@/assets/card-imgs/arrow-top.png";
import checkout from "@/assets/card-imgs/checkout.png";
import loginOut from "@/assets/card-imgs/loginout.png";
import updatepwd from "@/assets/card-imgs/updatepwd.png";
import authPwd from "@/assets/card-imgs/authPwd.png";
import noCardInfo from "@/assets/card-imgs/no-card.png";
import sanJiao from "@/assets/card-imgs/cardOptions/sanjiao.png";
const TabWidth = 100; // tab固定宽度
const cardWidth = 168; // 卡台信息固定宽度
const cardOptionHos = 164; // 卡台选项横向偏移量
let resResultDataObj = {}; // 元数据（后台接口返回处理后的初始化数据）
let cardListInfoArr = []; // 卡台总数据
let hasShowOptions = false; // 是否有显示的options操作选项

let mySelfStaffList = []; // 自己下属员工列表
let mySelfAndMyStaffCardList = []; // 自己及下属员工卡台列表

// 低消进度统计表
import drawerMinDetail from "@/components/money/drawerMinDetail.vue";
// 估清弹框
import outSomething from "../Order/orderMeal/orderMealList.vue";

import updatePassword from "@/components/common/updatePassword.vue";
import updateAuthPassword from "@/components/common/updateAuthPassword.vue";
import drawerSaveWine from "@/components/order/saveWine/drawerSaveWine/index.vue";
import drawerGetWine from "@/components/order/saveWine/drawerGetWine/index.vue";
import drawerPayToStore from "@/components/order/saveWine/drawerPayToStore/index.vue";

export default {
  data() {
    return {
      // loadIndex: 0,
      // modelVisible: true, // 是否显示未开启营业日模态框
      socket: null,
      showFullPageTable: false, // 是否显示全屏表格（转台等操作）
      showMinDetailDrawer: false, // 低消进度统计表
      showOrHideOutSomething: false, // 是否显示估清商品
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
    };
  },
  methods: {
    // 获取tab展示的数量
    getTabShowCount(callback) {
      const windowWidth = document.body.clientWidth;
      this.tab.tabMaxCount = Math.floor(windowWidth / TabWidth);
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

      if (roleIds.includes(3) || roleIds.includes(4)) {
        // 有营销/花篮权限
        YXTabList = [...arr];
      }

      // 特饮，也需要判断可点区域
      if (roleIds.includes(4)) {
        HLTabList = this.getAuthArea(JSON.parse(JSON.stringify(arr)));
      }
      if (this.hasLookOrder) {
        QCTabList = [...arr];
      }

      if (
        !(
          roleIds.includes(2) ||
          roleIds.includes(3) ||
          roleIds.includes(4)||
          this.hasLookOrder
        )
      ) {
        // 无任何权限
        arr = [];
      } else {
        arr = [...FUTabList, ...YXTabList, ...HLTabList, ...QCTabList].filter(
          (item, index, arr) =>
            arr.findIndex((items) => items.id == item.id) == index
        );
      }

      let tabList = arr
        .sort((a, b) => a.dsp - b.dsp)
        .filter((item) => item.status == 1); // status:  1:有效 2:无效
      tabList = tabList.filter(
        (e) => this.filterCardList("regionId", e.id).length > 0,
        tabList
      );
      this.tab.tabListOrigin = JSON.parse(JSON.stringify(tabList));
      this.$store.commit("updateTabList", this.tab.tabListOrigin);

      if (tabList.length > 0) {
        tabList.unshift({
          id: 0,
          name: "全部",
        });
        tabList.unshift({
          id: 2001,
          name: "我的卡台",
        });
      }

      if (tabList.length > this.tab.tabMaxCount) {
        this.tab.anotherInfo = tabList.splice(this.tab.tabMaxCount - 1);
        tabList.push({
          id: 999,
          name: "其它",
        });
      }

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

    // 获取全量数据
    async getCardList(cardInfo = [], businessData = []) {
      // // 获取设备可操作区域或卡台
      const currentMachineId = this.$localStorage.getItem("machineId");
      const currentAreaAndCardList = (
        this.$store.state.cardPageInfo.resResultDataObj["machineArea"] || []
      ).filter(
        (item) => item.license_id == currentMachineId && item.status == 1
      );

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
          [...this.$store.state.cardPageInfo.resResultDataObj.cardInfo] || [];

        // 最终经过筛选过后的区域列表，对应元数据的areaInfo
        let resultAreaList = [];
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

      // 初始化图例中显示的抵达数量
      this.setLegendCount(this.tab.activeIndex);

      if (
        (this.$store.state.userInfo.roleIds.includes(2) ||
          this.$store.state.userInfo.roleIds.includes(3)) &&
        !this.modelVisible
      ) {
        // 服务员/营销/特饮  且已开启营业日
        cardList = await this.addOwnPayedAmtToCard(cardList);
      }

      // 没有配置任何权限同时不具有全场查单权限
      if (
        this.$store.state.userInfo.roleIds.length == 0 
      ) {
        cardListInfoArr = [];
        // this.$message.warning('当前账号未配置可点区域')
      } else {
        cardListInfoArr = JSON.parse(JSON.stringify(cardList)); // 首次更改，为了给获取自己及下属员工卡台提供数据
      }

      await this.getTabList(resResultDataObj["areaInfo"]);

      // 如果是服务员或者特饮，需要根据可点区域限制可点卡台
      if (
        this.$store.state.userInfo.roleIds.includes(2) ||
        this.$store.state.userInfo.roleIds.includes(4)
      ) {
        cardListInfoArr = cardList.filter(
          (item) =>
            this.tab.tabListOrigin.findIndex((i) => i.id == item.regionId) >= 0
        );
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

    // 我的卡台数据(卡台列表)
    getMyCardList() {
      const authEmpId =
        this.$store.state.userInfo && this.$store.state.userInfo.emp_id;

      return cardListInfoArr.filter((item) => {
        item.waiter_emp_ids_arr = item.waiter_emp_ids_arr || [];
        return item.waiter_emp_ids_arr.includes(authEmpId.toString());
      });
    },

    // 筛选卡台数据
    filterCardList(key, id, cardList) {
      let targetCardList = cardListInfoArr;
      if (cardList) {
        targetCardList = cardList;
      }
      targetCardList.forEach((el) => {
        el.showOption = false;
      });

      const filterArr = targetCardList.filter((item) => item[key] == id);
      return id == 2001
        ? this.getMyCardList()
        : id == 0
        ? JSON.parse(JSON.stringify(targetCardList))
        : filterArr;
    },

    // 递归获取自己下属卡台数据
    getSelfStaffList(selfId) {
      // 未传值表明是当前登录账号人的id
      selfId = selfId || this.$store.state.userInfo.emp_id;
      const allStaffList =
        this.$store.state.cardPageInfo.resResultDataObj["orderPersonInfo"];
      // 当前员工的下级
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

    // 获取自己以及下属员工的卡台
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
    cardClickHandle(info) {
      // 存酒模式
      if (this.typeModule == 2) return;
      // 点单模式
      if (info.bizStatus == 1 || info.bizStatus == 2 || info.bizStatus == 8){
        return this.$message.warning("空台/锁台/预定状态卡台不可点单！");
      }
      
      this.$store.commit("updateOrderInfo", {
        key: "currentCardInfo",
        value: info,
      });
      console.log("点击卡台开始跳转");
      this.$router.push({ name: "orderMealList" });
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

    // 当前卡台是否有查单权限
    currentCardCanLookOrder(n, cardItemInfo) {
      // 是否具有全场查单权限
      const isLookAll = this.hasLookOrder;
      // 是否是当前卡台订位人
      const isBooker =
        cardItemInfo.salesEmpId * 1 == this.$store.state.userInfo.emp_id * 1;
      // 是否是当前卡台点单服务员
      const isSealer =
        "waiter_emp_ids_arr" in cardItemInfo &&
        !!cardItemInfo.waiter_emp_ids_arr.find(
          (item) => item * 1 == this.$store.state.userInfo.emp_id * 1
        );
      const isLookDept = cardItemInfo&&cardItemInfo.upper_emp_id == this.loginUserInfo.upper_emp_id && this.hasCanLookDept;
      
      let isLookSubordinate = cardItemInfo && this.loginUserSubordinateIds.includes(cardItemInfo.salesEmpId);
      
      if(this.hasOnlyLookSelf){
        isLookSubordinate = false
      }
      return isLookAll || isBooker || isSealer || isLookDept || isLookSubordinate;
    },

    // 显示或隐藏低消进度统计表
    showOrHideMinDetailDrawerHandle() {
      this.showMinDetailDrawer = !this.showMinDetailDrawer;
    },
    // 显示或隐藏估清商品
    showOrHideOutSomethingHandle(value) {
      this.showOrHideOutSomething = !this.showOrHideOutSomething;
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

    // 登录后初始化图例中的抵达数量
    setLegendCount(regionId = 0) {
      setTimeout(() => {
        let result = {};
        if (
          this.$store.state.userInfo.roleIds.length == 0 
        ) {
          this.cardStatusNoInfo = {};
          return;
        }
        // 获取设备可操作区域或卡台
        const currentMachineId = this.$localStorage.getItem("machineId");
        const currentAreaAndCardList = (
          resResultDataObj["machineArea"] || []
        ).filter(
          (item) => item.license_id == currentMachineId && item.status == 1
        );
        const isNoLimit = currentAreaAndCardList.filter(
          (item) => item.type_id == 3
        );
        // 区域下部分卡台
        let cardStatusNo =
          regionId == 2001
            ? this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo.filter(
                (item) =>
                  this.card.cardList.findIndex((i) => i.id == item.region_id) >=
                  0
              ) || []
            : this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo.filter(
                (item) =>
                  this.tab.tabListOrigin.findIndex(
                    (i) => i.id == item.region_id
                  ) >= 0
              ) || [];

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
                  .forEach((el) => {
                    if (el.bizStatus != 4 && el.bizStatus != 20) {
                      // 除了开台数和抵达数以外的状态
                      result[el.bizStatus] =
                        (result[el.bizStatus] || 0) * 1 + 1;
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
        this.cardStatusNoInfo = result;
      }, 200);
    },
  },

  mounted() {
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
    // 是否有存取酒
    hasWineAuth() {
      return (
        this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(1)
      );
    },
    // 不允许查看下属点单消费  只能看自己
    hasOnlyLookSelf() {
      return (
        this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(6) 
      );
    },

    //能查看同组点单消费
    hasCanLookDept() {
      return (
        this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(7)
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
  },

  beforeDestroy() {
    console.log("beforeDestroy");
    window.removeEventListener("resize", this.windowResizeHandle);
    window.removeEventListener("click", (e) => this.legendOptionHandle());

    window.onkeydown = null;
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
};
</script>

<style scoped lang="less">
@import "../../style/common/scrollBar.less";
@import "../../style/order/orderCard.less";
@import "../../style/book/cardBgc.less";
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
