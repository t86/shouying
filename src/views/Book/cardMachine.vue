<template>
  <div class="contain" ref="containRef">
    <div class="contain-content" ref="containContentRef">
      <div class="contain-top">
        <!-- 日期tab -->
        <div class="scroll-date">
          <div
            class="tab-date"
            :style="{ width: tabDateWidth + 'px' }"
            layout="row"
            layout-align="start center"
          >
            <div
              class="date-item"
              :class="{ active: index === dateTab.activeIndex }"
              v-for="(item, index) in dateTab.dateTabList"
              :key="index"
              @click="changeDateTab(index)"
            >
              <p>{{ item.name }}</p>
            </div>
          </div>
        </div>

        <!-- 区域tab -->
        <div class="area" layout="row" layout-align="space-between center">
          <div class="tab" layout="row" layout-align="start center">
            <div
              class="area-item"
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
                <div
                  class="another-item"
                  :class="{ active: items.id === tab.anotherInfoActiveId }"
                  v-for="(items, i) in tab.anotherInfo"
                  :key="i"
                  @click.stop="changeTab('9999', items.id)"
                >
                  <span>{{ items.name }}</span>
                </div>
              </div>
            </div>
          </div>
          <!-- 搜索框 -->
          <div class="search" v-if="tab.tabList.length > 0">
            <input
              type="text"
              v-model="keyWord"
              @input="inputSearchHandle"
              placeholder="卡台名称/客人/手机/订位人"
            />
          </div>
        </div>
      </div>

      <!-- 卡台列表 -->
      <div class="content">
        <!-- 开启营业日 -->
        <div class="open-store" v-if="modelVisible">
          <div class="open-store-btn" @click.stop="openStoreHandle">
            营业日未开启，点击开启营业日
          </div>
        </div>
        <!-- 卡台列表 -->
        <div
          v-if="card.cardList.length > 0"
          class="center-type"
          :style="{
            width: card.centerTypeWidth + 'px',
            'padding-top': modelVisible ? '50px' : '0px',
          }"
          layout="row"
          layout-align="start center"
        >
          <div
            class="card-item"
            v-for="(item, index) in card.cardList"
            :key="index"
            :class="'bgc' + Number(item.bizStatus)"
            @click.stop="showOrHideOptionHandle(index, item, true)"
            @contextmenu.prevent.stop="rightClickHandle"
          >
            <p layout="row" layout-align="space-between center">
              <span class="area-name" layout="row" layout-align="center center">
                <span>{{ item.regionId | getAreaName }}</span>
                <!-- 当前这个‘线’字标记代表：线上卡台或者卡台的线上预定（线上卡台先被预定，后来被转为线下卡台，但是线上的预定没有被取消） -->
                <span class="line-tips" v-if="item.showOnlineText">线</span>
              </span>
              <span layout="row" layout-align="center center">
                <span v-if="item.mark" class="mark">{{ item.mark }}</span>
                <span>{{
                  item.openTime ? "(" + item.openTime + ")" : "" | filterTime
                }}</span>
                <span v-if="item.bizStatus == 1">{{ item.capacity }}人</span>
              </span>
            </p>

            <h3 class="card-name" layout="row" layout-align="start center">
              <div
                ref="cardRef"
                style="white-space: nowrap; transform-origin: left center"
                :style="{fontSize: fontSize(item, index) + 'px'}"
              >
                {{ item.name }}
              </div>
            </h3>

            <!-- 金额 -->
            <p
              layout="row"
              v-if="[4, 5, 6, 7].find((items) => items == item.bizStatus)"
              layout-align="space-between center"
            >
              <span
                layout="column"
                v-if="
                  $store.state.cardPageInfo.resResultDataObj.showAmt.find(
                    (item) => item.id == 3
                  )
                    ? $store.state.cardPageInfo.resResultDataObj.showAmt.find(
                        (item) => item.id == 3
                      ).param1 == 2
                    : true
                "
                layout-align="center start"
              >
                <span class="hui-name" layout="row" layout-align="center start">
                  <span class="line-tips">惠</span>
                  <span>￥{{ item.zengSongAmt }}</span>
                </span>
                <span
                  class="zong-name"
                  layout="row"
                  layout-align="start center"
                >
                  <span class="line-tips">主</span>
                  <span>￥{{ item.order_zy_amt * 1 - item.payed_zy_free_amt * 1 }}</span>
                </span>
              </span>
              <span class="card-step">{{ item.diXiaoJindu }}</span>
            </p>
            <p v-else style="height: 17px"></p>

            <!-- 订位人 -->
            <p
              class="one-txt-cut"
              v-if="item.bizStatus != 1 && item.bizStatus != 2"
            >
              {{ item.salesEmpId | getDepartmentName }}
              {{ item.salesEmpId | getOrderPersonName }}
            </p>
            <p v-else style="height: 17px"></p>

            <!-- 客人信息 -->
            <p
              class="one-txt-cut"
              v-if="item.bizStatus != 1 && item.bizStatus != 2"
            >
              {{ item.customerName }}
              {{
                item.customerPhone
                  ? item.customerPhone.slice(0, 3) +
                    "****" +
                    item.customerPhone.slice(-4)
                  : ""
              }}
            </p>
            <p v-else style="height: 18px"></p>

            <p
              layout="row"
              layout-align="space-between center"
              style="margin-top: 2px"
            >
              <!-- tips -->
              <span layout="row" layout-align="space-between center">
                <span
                  class="card-tips"
                  :class="{ green: items !== '锁', yellow: items === '锁' }"
                  v-for="(items, i) in item.tipsArr"
                  :key="i"
                  >{{ items }}</span
                >
                <!-- remark -->
                <span class="card-remark">{{ item.remark && item.remark.slice(0, 6) }}</span>
              </span>
              <!-- 翻台数 -->
              <span>
                <span v-if="item.turnoverCnt > 0"
                  >翻{{ item.turnoverCnt }}</span
                >
              </span>
            </p>
            <!-- 选项操作箭头 -->
            <img
              v-if="item.showOption && item.isLeftArrow"
              :src="imgSrc.sanJiao"
              alt
              class="sanjiao left"
            />
            <img
              v-if="item.showOption && !item.isLeftArrow"
              :src="imgSrc.sanJiao"
              alt
              class="sanjiao right"
            />
            <!-- 卡台内部操作选项 -->
            <div
              class="card-options"
              v-if="item.showOption"
              :style="{
                top: card.optionsPosition.top,
                bottom: card.optionsPosition.bottom,
                left: card.optionsPosition.left,
                right: card.optionsPosition.right,
                transform: card.optionsPosition.transform,
              }"
              ref="cardOptions"
            >
              <div
                class="options-item"
                v-for="(el, i) in item.options"
                :key="i"
                @click.stop="optionsClickHandle(el, item, index)"
              >
                <div class="options-item-contain">
                  <img :src="el.icon" alt />
                  <span>{{ el.name }}</span>
                </div>
              </div>
              <div class="close">
                <i class="el-icon-close fs14"></i>
                关闭
              </div>
            </div>
          </div>
        </div>
        <!-- 无数据 -->
        <div v-else class="no-data">
          <img :src="imgSrc.noCardInfo" alt />
          <p>暂无卡台数据</p>
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
              @click.stop="changeCardStatus(item.id)"
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
              v-else
              style="transform: translateY(26px)"
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
        <ul
          class="dosomething"
          layout="row"
          layout-align="space-between center"
        >
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
            class="dosomething-item"
            @click.stop="legendOptionHandle('more')"
          >
            <img :src="imgSrc.more" alt />
            <p>更多功能</p>
            <div class="option more" v-if="legendOptions.showMoreFunc">
              <div class="option-item" @click="showOrHideOpenCardDrawerHandle">
                <img :src="imgSrc.openCard" alt />
                <span>开台记录</span>
              </div>
              <div
                class="option-item line"
                @click="showOrHideTurnOverDrawerHandle"
              >
                <img :src="imgSrc.turnOver" alt />
                <span>转台记录</span>
              </div>
              <div
                class="option-item"
                @click="showOrHideReservedRecordDrawerHandle"
              >
                <img :src="imgSrc.openCard" alt />
                <span>预留记录</span>
              </div>
              <div
                class="option-item"
                @click="showOrHideOnlineBookingDrawerHandle"
              >
                <img :src="imgSrc.openCard" alt />
                <span>线上预订记录</span>
              </div>
              <img :src="imgSrc.sanJiao" alt />
            </div>

          </div>

          <div class="dosomething-item" @click.stop="legendOptionHandle('pwd')">
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
                class="option-item logout"
                @click.stop="legendOptionHandle('logout')"
              >
                <img :src="imgSrc.loginOut" alt />
                <span>退出登录</span>
              </div>
              <img :src="imgSrc.sanJiao" alt />
            </div>
          </div>
        </ul>
      </div>
    </div>
    <!-- 除了预留以外的drawer操作 -->
    <cardDrawer
      ref="cardDrawer"
      :showDrawer="drawer.showDrawer"
      :formStatus="drawer.formStatus"
      :cardId="drawer.cardId"
      :bookId="drawer.bookId"
      :cardInfo="drawer.cardInfo"
      :cardInfoIndex="drawer.cardInfoIndex"
      @changeShowDrawer="changeShowDrawer"
      @showOrHideFullPageHandle="showOrHideFullPageHandle"
    />

    <!-- 当日/未来日期预定/预留 -->
    <drawerReserved
      ref="drawerReserved"
      :dateTabActiveIndex="dateTab.activeIndex"
      :dateVal="dateTab.dateTabList.length > 0 ? dateTab.dateTabList[dateTab.activeIndex].name : ''"
      :cardList="card.cardListInfoArr"
      :tabList="tab.tabListOrigin"
      :showDrawer="reserved.showDrawer"
      @changeShowDrawer="changeReservedShowDrawer"
    />
    <!-- 全屏表格 -->
    <fullPageTable
      ref="fullPageTable"
      :tabList="tab.tabListOrigin"
      :cardList="card.cardListInfoArr"
      @showOrHideFullPageHandle="showOrHideFullPageHandle"
      v-if="showFullPageTable"
    />

    <!-- 开台记录 -->
    <drawerOpenCard
      :showDrawer="showOpenCardDrawer"
      @showOrHideDrawer="showOrHideOpenCardDrawerHandle"
    />

    <!-- 转台记录 -->
    <drawerTurnOver
      :showDrawer="showTurnOverDrawer"
      @showOrHideDrawer="showOrHideTurnOverDrawerHandle"
    />

    <!-- 预留记录 -->
    <drawerReservedRecord
      :showDrawer="showReservedRecordDrawer"
      @showOrHideDrawer="showOrHideReservedRecordDrawerHandle"
    />

    <!-- 线上预订记录 -->
    <drawerOnlineBooking
      :showDrawer="showOrHideOnlineBookingDrawer"
      @showOrHideOnlineBookingDrawer="showOrHideOnlineBookingDrawerHandle"
    />


    <!-- 修改密码 -->
    <updatePassword
      ref="updatePassword"
      :showDrawer="legendOptions.updatePwdModel"
      @submitHandle="submitUpdatePwdHandle"
      @cancelUpdatePwdHandle="cancelUpdatePwdHandle"
    />
  </div>
</template>

<script>
import drawerReserved from "@/components/book/reserved/drawerReserved.vue";
import cardDrawer from "@/components/book/machine/cardDrawer"; // 抽屉组件
import fullPageTable from "@/components/book/machine/fullPageTable"; // 全屏表格
import drawerOpenCard from "@/components/book/machine/drawerOpenCard.vue"; // 开台记录
import drawerTurnOver from "@/components/book/machine/drawerTurnOver.vue"; // 转台记录
import drawerReservedRecord from '@/components/book/machine/drawerReservedRecord.vue'; // 预留记录
// 线上预订记录
import drawerOnlineBooking from "../../components/money/drawerOnlineBooking.vue";
import updatePassword from "@/components/common/updatePassword.vue"; // 修改密码

import api_card from "@/api/Book";
import api_money from "@/api/money";
import api_auth from "@/api/UtilAuth";
import { legendList, cardOptions } from "@/utils/config/card";

import { cardPageMixins } from "@/mixin/cardPage";

import arrowBottom from "@/assets/card-imgs/new-arrow-bottom.png";
import more from "@/assets/card-imgs/more.png";
import openCard from "@/assets/card-imgs/open-card.png";
import turnOver from "@/assets/card-imgs/turn-over.png";
import reload from "@/assets/card-imgs/reload.png";
import arrowTop from "@/assets/card-imgs/arrow-top.png";
import checkout from "@/assets/card-imgs/checkout.png";
import loginOut from "@/assets/card-imgs/loginout.png";
import updatepwd from "@/assets/card-imgs/updatepwd.png";
import noCardInfo from "@/assets/card-imgs/no-card.png";
import sanJiao from "@/assets/card-imgs/cardOptions/sanjiao.png";
const TabWidth = 100; // tab固定宽度
const cardWidth = 168; // 卡台信息固定宽度
const cardOptionHos = 164; // 卡台选项横向偏移量
let resResultDataObj = {}; // 元数据（后台接口返回处理后的初始化数据）
let cardListInfoArr = []; // 卡台总数据
let hasShowOptions = false; // 是否有显示的options操作选项

export default {
  data() {
    return {
      // loadIndex: 0,
      // modelVisible: true, // 是否显示未开启营业日模态框
      socket: null,
      showFullPageTable: false, // 是否显示全屏表格（转台等操作）
      showOpenCardDrawer: false, // 是否显示卡台记录drawer
      showTurnOverDrawer: false, // 是否显示转台记录drawer
      showReservedRecordDrawer: false, // 是否显示预留记录drawer
      showOrHideOnlineBookingDrawer: false, // 是否显示线上预订记录drawer
      dateTab: {
        dateTabList: [],
        activeIndex: 0,
      },
      keyWord: "", // 搜索框
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
      reserved: {
        showDrawer: false,
      },
      imgSrc: {
        reload,
        arrowBottom,
        more,
        openCard,
        turnOver,
        arrowTop,
        checkout,
        loginOut,
        updatepwd,
        noCardInfo,
        sanJiao,
      },
      legendList: legendList.filter((item) => item.id !== 2),
      legendActive: 0,
      authName: "", // 员工姓名
      arrowStatus: "", // 鼠标按下按钮状态
      // 图例操作选项

      legendOptions: {
        showUpdatePwd: false,
        showMoreFunc: false, // 是否显示更多功能
        updatePwdModel: false,
        form: {
          old_password: "",
          new_password: "",
          rnew_password: "",
        },
      },
      cardStatusNoInfo: {}, // 图例抵达卡台数量

      // 点击options选项后的弹框数据
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
    };
  },
  methods: {
    // 获取时间tab
    getTimeTabData(nextDayDataArr = []) {
      this.dateTab.dateTabList = nextDayDataArr.map((item) => ({
        ...item,
      }));
    },
    // 切换时间tab
    changeDateTab(index) {
      this.keyWord = "";
      this.dateTab.activeIndex = index;
      const resResultDataObj = this.$store.state.cardPageInfo.resResultDataObj;

      // 获取卡台数据
      this.getCardList(
        resResultDataObj["cardInfo"],
        resResultDataObj["businessData"]
      );
    },

    // 获取区域tab数据
    getTabList(arr = []) {
      arr = arr.sort((a, b) => Number(a.dsp) - Number(b.dsp));
      let tabList = arr.filter((el) => el.status === "1"); // status:  1:有效 2:无效
      tabList = tabList.filter(
        (e) => this.filterCardList("regionId", e.id).length > 0
      );
      this.tab.tabListOrigin = JSON.parse(JSON.stringify(tabList));
      this.$store.commit("updateTabList", this.tab.tabListOrigin);
      // 数量大于0 再添加全部
      if (tabList.length > 0) {
        tabList.unshift({
          id: 0,
          name: "全部",
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
    // 获取区域tab展示的数量
    getTabShowCount(callback) {
      const windowWidth = document.body.clientWidth;
      this.tab.tabMaxCount = Math.floor((windowWidth * 0.68) / TabWidth);
      this.card.centerTypeWidth =
        Math.floor(windowWidth / cardWidth) * cardWidth;
      callback && callback();
    },

    // 搜索卡台(关键字搜索)
    inputSearchHandle() {
      this.legendActive = 0;
      this.tab.anotherInfoActiveId = 0;
      this.tab.activeIndex = 0;
      this.card.cardList = this.filterCardList("keyword");
    },

    // 手动切换卡台订单状态
    changeCardStatus(cardStatusId) {
      if (this.modelVisible) return;
      if (cardStatusId === this.legendActive) {
        // 点击的同状态一个按钮
        this.legendActive = 0;
        this.card.cardList = cardListInfoArr;
        return;
      }
      this.legendActive = cardStatusId;
      this.tab.anotherInfoActiveId = 0;
      this.tab.activeIndex = 0;
      this.tab.showAnotherInfo = false;
      this.card.cardList = this.filterCardList("bizStatus", cardStatusId);
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
          // ‘线’字标签，显示优先级：订单预留方式 > 卡台属于线上还是线下
          data.showOnlineText =
            data.bizStatus > 2
              ? data.platform_id == 1 && !data.isTurnBottomCard
              : cardOnlineStatus.cardStatus == 1 && !data.isTurnBottomCard;

          // 是否有置顶
          const topNumInfo = this.$store.state.cardPageInfo.resResultDataObj[
            "topCard"
          ].find((items) => items.seat_id == item.id && items.status == 1);

          data.topNum = topNumInfo ? topNumInfo.seq_id : "0";
          // 未来日期的卡台相关数据
          if (this.dateTab.activeIndex != 0) {
            // 只有空台和预留两个状态
            // 未来预留数据
            const nextDayData =
              this.$store.state.cardPageInfo.resResultDataObj["nextDayData"];
            const currentDayInfo = nextDayData.find(
              (el) =>
                el.seat_id == item.id &&
                el.status == 1 &&
                el.book_day_value ==
                  this.dateTab.dateTabList[this.dateTab.activeIndex].id
            );

            if (currentDayInfo) {
              // 有预定的
              const _data = {
                showOnlineText:
                  data.bizStatus > 2
                    ? currentDayInfo.platform_id == 1
                    : cardOnlineStatus.cardStatus == 1, // ‘线’字标签，显示优先级：订单预定方式 > 卡台属于线上还是线下
                cardStatus: cardOnlineStatus.cardStatus || "", // 卡台是线上还是线下
                seatId: currentDayInfo.seat_id, // 卡台id
                wkBookId: currentDayInfo.book_id, // 预订记录
                wkBookTime: currentDayInfo.book_time, // 预定时间
                wkCsmId: data.wkCsmId, // 流水记录id
                expArriveTime: currentDayInfo.exp_arrive_time, // 期望达到时间
                openTime: "", // 开台时间
                // openType: data.openType, // 开台类型  0 未开台 1 消费 2 内招 3 外招 4 气氛 5 全转 6 半转
                orderAmt: 0, // 点单金额
                backAmt: 0, // 退款金额
                payedAmt: 0, // 已付款金额
                grpMinCsmAmt: data.grpMinCsmAmt, // 卡台自带低消金额(根据实际情况设置的默认值)
                assignMinCsmAmt: data.assignMinCsmAmt, // 操作员设置低消金额(根据grpMinCsmAmt上下调动的金额)
                yhAmt: data.yhAmt, // 优惠金额
                yh2Amt: data.yh2Amt, // 优惠2金额
                turnoverCnt: 0, // 翻台数
                salesEmpId: currentDayInfo.sales_emp_id, // 订位人Id
                secondSalesEmpId: currentDayInfo.second_sales_emp_id, // 联合订位人Id
                customerName: currentDayInfo.customer_name, // 客户姓名
                customer_name_py: currentDayInfo.customer_name_py || "", // 客户姓名拼音
                customerPhone: currentDayInfo.customer_phone, // 客户电话
                customerCnt: currentDayInfo.customer_cnt, // 到店人数
                bizStatus: currentDayInfo.status == 1 ? "8" : "1", // 业务状态 1 空台 2 锁定 4 开台 5 点单未结账 6 部分结账 7 已结账 8 预定 22 无效 33 删除
                waiter_emp_ids: "", // 下单服务员列表 列表以;;分隔 对应empId的列表 例如 ;123;112; 对应empId=123和empId=112两个服务员都在这个卡台下过单
                waiter_emp_ids_arr: "", // 当前卡台对应的点单服务员empId（展示在首页我的卡台）
                pay_notify: data.pay_notify, // 支付超时提醒 1 需要提醒 2 不需要提醒
                platform_id: currentDayInfo.platform_id, // 渠道来源 0 代表本地系统 1 代表微信小程序 (以后有抖音,大众点评等再扩展)
                remark: currentDayInfo.remark,
                topNum: data.topNum,
              };
              data = { ..._data };
            } else {
              // 没有预定的
              const _data = {
                showOnlineText: cardOnlineStatus.cardStatus == 1, // ‘线’字标签，显示优先级：订单预定方式 > 卡台属于线上还是线下
                cardStatus: cardOnlineStatus.cardStatus || "", // 卡台是线上还是线下（后台配置）
                seatId: data.seat_id, // 卡台id
                wkBookId: data.wkBookId, // 预订记录
                wkBookTime: "", // 预定时间
                wkCsmId: data.wkCsmId, // 流水记录id
                expArriveTime: "", // 期望达到时间
                openTime: "", // 开台时间
                // openType: data.openType, // 开台类型  0 未开台 1 消费 2 内招 3 外招 4 气氛 5 全转 6 半转
                orderAmt: 0, // 点单金额
                backAmt: 0, // 退款金额
                payedAmt: 0, // 已付款金额
                grpMinCsmAmt: data.grpMinCsmAmt, // 卡台自带低消金额(根据实际情况设置的默认值)
                assignMinCsmAmt: data.assignMinCsmAmt, // 操作员设置低消金额(根据grpMinCsmAmt上下调动的金额)
                yhAmt: data.yhAmt, // 优惠金额
                yh2Amt: data.yh2Amt, // 优惠2金额
                turnoverCnt: 0, // 翻台数
                salesEmpId: "", // 订位人Id
                secondSalesEmpId: "", // 联合订位人Id
                customerName: "", // 客户姓名
                customer_name_py: "", // 客户姓名拼音
                customerPhone: "", // 客户电话
                customerCnt: "", // 到店人数
                bizStatus: data.bizStatus == 2 ? 2 : 1, // 业务状态 1 空台 2 锁定 3 预订 4 开台 5 点单未结账 6 部分结账 7 已结账 8 线上小程序预定 22 无效 33 删除
                waiter_emp_ids: "", // 下单服务员列表 列表以;;分隔 对应empId的列表 例如 ;123;112; 对应empId=123和empId=112两个服务员都在这个卡台下过单
                waiter_emp_ids_arr: "", // 当前卡台对应的点单服务员empId（展示在首页我的卡台）
                pay_notify: data.pay_notify, // 支付超时提醒 1 需要提醒 2 不需要提醒
                platform_id: "", // 渠道来源 0 代表本地系统 1 代表微信小程序 (以后有抖音,大众点评等再扩展)
                remark: "",
                topNum: data.topNum,
              };
              data = { ..._data };
            }
          }
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
      this.setLegendCount(this.tab.activeIndex);

      cardList = cardList.sort((a, b) => b.topNum - a.topNum);

      cardListInfoArr = cardList;
      this.card.cardListInfoArr = JSON.parse(JSON.stringify(cardList));
      this.$store.commit("updateCardList", this.card.cardListInfoArr);

      if (this.tab.activeIndex != 0) {
        // tab已选择
        this.card.cardList = this.filterCardList(
          "regionId",
          this.tab.activeIndex
        );
      } else if (this.legendActive != 0) {
        // 卡台状态已选择
        this.card.cardList = this.filterCardList(
          "bizStatus",
          this.legendActive
        );
      } else {
        this.card.cardList = JSON.parse(JSON.stringify(cardList));
      }
      this.$forceUpdate();
    },

    // 去往预留管理
    goReserved() {
      if (this.modelVisible) return;
      this.$router.push({ name: "reserved" });
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

    // 操作图例legend中的option
    legendOptionHandle(type) {
      this.showOrHideOptionHandle();
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
                });
                this.$message.success("退出成功！");
              } else {
                this.$message.warning(res.msg);
              }
            } catch (error) {
              console.log("login失败", error);
            }
          });

          break;
        case "updatePwd":
          this.legendOptions.updatePwdModel = true;
          break;
        case "more": // 更多功能
          this.legendOptions.showMoreFunc = !this.legendOptions.showMoreFunc;
          this.legendOptions.showUpdatePwd = false;
          break;
        default:
          this.legendOptions.showUpdatePwd = false;
          this.legendOptions.showMoreFunc = false;
          break;
      }
    },

    // 请求全量基础数据(首次页面加载在父组件中调用(返回到此页面数据由mounted加载))
    async getAllData() {
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
          optionsIdArr = [10, 11, 7, 12, 14, 4, 20, 21, 23];
          break;
        case 5: // 点单未结账
          optionsIdArr = [10, 11, 7, 14, 4, 20, 23];
          break;
        case 6: // 点单部分结账
          optionsIdArr = [10, 11, 7, 14, 4, 20, 23];
          break;
        case 7: // 已结账
          optionsIdArr = [10, 11, 7, 14, 4, 20, 23];
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

    // 点击卡台options选项
    async optionsClickHandle(optionsInfo, cardInfo, index) {
      console.log(optionsInfo);
      //index:卡台的index索引值
      this.showOrHideOptionHandle(index);
      // 预定（预留）新建或修改
      if (optionsInfo.id == 1 || optionsInfo.id == 8) {
        this.changeReservedShowDrawer(
          optionsInfo.id == 1 || optionsInfo.id == 18
            ? { seatId: cardInfo.id }
            : { id: cardInfo.wkBookId, seatId: cardInfo.id }
        );
        return;
      }
      switch (optionsInfo.id) {
        case 3: // 查看卡台消费
          console.log("查看卡台消费");
          break;
        case 4: // 修改翻台订位人
          if (cardInfo.turnoverCnt == 0)
            return this.$message.warning("当前卡台没有翻过台！");
          break;
        case 5: // 锁台
          this.showConfirmHandle(
            "锁定卡台",
            "是否确认锁定卡台，锁定后该卡台除取消锁定外，其他功能均不能使用",
            async () => {
              try {
                const res = await api_card.reqClockCard({
                  id: Number(cardInfo.id),
                });
                this.confirmSuccess(res);
              } catch (error) {
                console.log(error);
                this.$message.warning("锁定卡台失败");
              }
            }
          );
          return;
        case 6: // 取消锁定
          this.showConfirmHandle("取消锁定", "是否确认取消锁定？", async () => {
            try {
              const res = await api_card.reqCancelClockCard({
                id: Number(cardInfo.id),
              });
              this.confirmSuccess(res);
            } catch (error) {
              console.log(error);
              this.$message.warning("取消锁台失败");
            }
          });
          return;
        case 12: // 撤台
          this.showConfirmHandle("撤台", "是否确认撤台操作？", async () => {
            try {
              const res = await api_card.reqCancelOpenCard({
                id: Number(cardInfo.id),
              });
              this.confirmSuccess(res);
            } catch (error) {
              console.log(error);
              this.$message.warning("取消锁台失败");
            }
          });
          return;
        case 15: // 取消预留
          this.showConfirmHandle("取消预留", "是否确认取消预留", async () => {
            try {
              const res = await api_card.reqCancelReservedInfo({
                id: cardInfo.wkBookId * 1, // int64   待操作预留记录Id
              });
              this.confirmSuccess(res);
            } catch (error) {
              console.log(error);
              this.$message.warning("取消预留失败");
            }
          });
          return;
        case 16: // 清台
          this.showConfirmHandle("清台", "是否确认清台", async () => {
            try {
              const res = await api_money.reqClearCard({
                seat_id: cardInfo.id * 1, //    int64  卡台Id
              });
              this.confirmSuccess(res);
            } catch (error) {
              console.log(error);
              this.$message.warning("清台失败");
            }
          });
          return;
        case 17: // 临时转为线下卡台
          this.showConfirmHandle(
            "临时转为线下卡台",
            "是否确认将此卡台临时转为线下卡台",
            async () => {
              try {
                const res = await api_card.reqTurnLineBottomCard({
                  id: Number(cardInfo.id), // int64  待操作卡台Id
                });
                if (res.code == 1) {
                  this.$message.success("转线下操作中，请稍后...");
                } else {
                  this.$message.warning(res.msg);
                }
              } catch (error) {
                console.log(error);
                this.$message.warning("临时转为线下卡台失败");
              }
            }
          );
          return;
        case 18: // 卡台置顶
          try {
            const res = await api_card.reqTopCard({
              id: Number(cardInfo.id), // int64  待操作卡台Id
            });
            if (res.code == 1) {
              this.$message.success("置顶成功");
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log(error);
            this.$message.warning("临时转为线下卡台失败");
          }
          return;
        case 19: // 卡台取消置顶
          try {
            const res = await api_card.reqCancelTopCard({
              id: Number(cardInfo.id), // int64  待操作卡台Id
            });
            if (res.code == 1) {
              this.$message.success("取消置成功");
            } else {
              this.$message.warning(res.msg);
            }
          } catch (error) {
            console.log(error);
            this.$message.warning("临时转为线下卡台失败");
          }
          return;
        case 23:
          console.log("------修改服务员")
      }

      if (optionsInfo.id === 7) {
        // 转台
        this.showFullPageTable = true;
      } else {
        this.drawer.showDrawer = true;
        // this.$children[0] &&
        //   this.$children[0].cardInfoChange &&
        //   this.$children[0].cardInfoChange();
      }
      console.log('-------------', optionsInfo, index)
      this.drawer.cardInfo = {...cardInfo};
      this.drawer.formStatus = optionsInfo.id;
      this.drawer.cardId = cardInfo.id;
      this.drawer.bookId = cardInfo.wkBookId;
      this.drawer.cardInfoIndex = index;
    },

    // 点击卡台出现或隐藏options选项
    showOrHideOptionHandle(index, itemInfo = {}, isClickCard = false) {
      if (itemInfo.id) console.log(itemInfo);
      if (this.dateTab.activeIndex != 0 && itemInfo.bizStatus == 2)
        return this.$message.warning("未来日期无法解锁卡台！");
      if (
        (itemInfo.bizStatus == 1 || itemInfo.bizStatus == 8) &&
        itemInfo.showOnlineText
      ) {
        // if(this.$store.state.cardPageInfo.resResultDataObj.canDoList[this.dateTab.activeIndex].id > this.getCurrentDay() || ( this.dateTab.activeIndex != 0 && this.$store.state.cardPageInfo.resResultDataObj.canDoList[this.dateTab.activeIndex].id == this.getCurrentDay() && this.isMorning)){
        //   return this.$message.warning("未来日期的线上卡台，线下不可操作！");
        // }
        if (this.dateTab.activeIndex != 0)
          return this.$message.warning(
            "非营业日栏所在线上卡台，线下不可操作！"
          );
      }

      this.card.cardList.forEach((el, i) => {
        el.showOption = index === i ? !el.showOption : false;
      });
      if (this.legendOptions.showUpdatePwd)
        this.legendOptions.showUpdatePwd = false;
      hasShowOptions = false;

      // 初始化position位置
      this.card.optionsPosition = {
        top: "50%",
        bottom: "",
        transform: "translate(0,-50%)",
        left: cardOptionHos + "px",
        right: "",
      };

      if (isClickCard) {
        // 点击卡台
        hasShowOptions = true;
        this.$store.commit("updateOrderInfo", {
          key: "currentCardInfo",
          value: itemInfo,
        });
        this.$nextTick(() => {
          this.getOptionsPosition(index);
        });
      }
      this.$forceUpdate();
    },

    // 获取卡台操作选项的位置(上移/下移/居左/居右)
    getOptionsPosition(index) {
      this.$nextTick(() => {
        const cardDom = this.$refs.cardOptions;
        if (!cardDom || cardDom.length === 0) return false;
        // console.log(cardDom[0]);

        // 设置最小上下偏移量
        const minDistant = 17;

        // 计算一行显示几列卡台
        const oneLineCount = Math.floor(this.card.centerTypeWidth / cardWidth);

        // dom元素高度
        const domHeight = cardDom[0].getBoundingClientRect().height;
        // 距离浏览器可视区域顶部的距离
        const domTop = cardDom[0].getBoundingClientRect().top;
        // 距离浏览器可视区域底部的距离
        const domBottom = cardDom[0].getBoundingClientRect().bottom;
        // dom元素距离底部最大距离
        const domMaxBottomDistant =
          window.innerHeight ||
          document.documentElement.clientHeight ||
          document.body.clientHeight;

        if (domTop < 0) {
          const beyondDis = Math.abs(domTop);
          const translateY = Math.max(minDistant, domHeight / 2 - beyondDis);
          this.card.optionsPosition.transform = `translate(0,${
            -1 * translateY
          }px)`;
        } else if (domBottom > domMaxBottomDistant) {
          const beyondDis = Math.abs(domMaxBottomDistant - domBottom);
          const translateY =
            Math.min(domHeight - minDistant, domHeight / 2 + beyondDis) + 60;
          // console.log('bottom:', `translate(0,${-1 * translateY}px)`);
          this.card.optionsPosition.transform = `translate(0,${
            -1 * translateY
          }px)`;
        }

        // 判断左右显示
        if ((index + 1) % oneLineCount === 0) {
          // 每行最后一个卡台
          this.card.optionsPosition.left = "";
          this.card.optionsPosition.right = cardOptionHos + "px";
          this.card.cardList[index].isLeftArrow = true;
        }
        this.$forceUpdate();
      });
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

    // 改变未来日期预留drawer
    changeReservedShowDrawer(info) {
      this.reserved.showDrawer = !this.reserved.showDrawer;
      this.$children[1].setFomData && this.$children[1].setFomData(info);
    },

    // confirm提示框操作后接口成功后的操作
    confirmSuccess(res, message = "操作成功！") {
      res.code === 1
        ? this.$message({
            type: "success",
            message,
          })
        : this.$message.warning(res.msg);
    },

    // 页面滚动隐藏目前页面中显示的卡台操作选项
    windowScrollHideOptionsHandle() {
      if (hasShowOptions) {
        this.card.cardList.forEach((el) => {
          el.showOption = false;
        });
        hasShowOptions = false;
        this.$forceUpdate();
      }
    },

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

    /**
     * 显示或隐藏开台记录
     */
    showOrHideOpenCardDrawerHandle() {
      this.showOpenCardDrawer = !this.showOpenCardDrawer;
    },

    /**
     * 显示或隐藏转台记录
     */
    showOrHideTurnOverDrawerHandle() {
      this.showTurnOverDrawer = !this.showTurnOverDrawer;
    },

    /**
     * 显示或隐藏预留记录
     */
     showOrHideReservedRecordDrawerHandle() {
      this.showReservedRecordDrawer = !this.showReservedRecordDrawer;
    },

      /**
     * 显示或隐藏线上预订记录
     */
     showOrHideOnlineBookingDrawerHandle() {
      this.showOrHideOnlineBookingDrawer = !this.showOrHideOnlineBookingDrawer;
    },

    /**
     * 开启营业日
     */
    openStoreHandle() {
      this.showConfirmHandle("开启营业日", "是否确认开启营业日？", async () => {
        try {
          const res = await api_card.reqWorkStart();
          if (res.code === 1) {
            // 此处卡台的业务数据websocket会返回相应的更新数据
            // this.modelVisible = false;
            this.$message.success("开启营业日成功！");
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("开启营业日失败", error);
        }
      });
    },

    // 获取当天年月日
    getCurrentDay() {
      const Y = new Date().getFullYear().toString().padStart(2, 0);
      const M = (new Date().getMonth() + 1).toString().padStart(2, 0);
      const D = new Date().getDate().toString().padStart(2, 0);
      return `${Y}${M}${D}`;
    },

    keydownHandle(e) {
      if (e.keyCode == 13) {
        this.$nextTick(() => {
          if (this.reserved.showDrawer) {
            // 预留
            this.$refs.drawerReserved.onSubmit();
          } else if (this.drawer.showDrawer) {
            // 除了预留以外的drawer操作
            this.$refs.cardDrawer.onSubmit();
          } else if (this.showFullPageTable) {
            // 全屏表格
            this.$refs.fullPageTable.submitHandle();
          } else if (this.legendOptions.updatePwdModel) {
            // 修改密码
            this.$refs.updatePassword.onSubmit();
          }
        });
      }
    },

    rightClickHandle() {
      return false;
    },

    // 赋值图例中的抵达数量
    setLegendCount(regionId = 0) {
      setTimeout(() => {
        let result = {};

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
        if (isNoLimit.length > 0) {
          // 没有对设备进行卡台或区域限制
          if (regionId == 0) {
            // 选择的'全部'
            (
              this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo || []
            ).forEach((el) => {
              if (result[el.id] != undefined) {
                result[el.id] = result[el.id] * 1 + el.cnt * 1;
              } else {
                result[el.id] = el.cnt * 1;
              }
            });
          } else {
            (this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo || [])
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
          if (regionId == 0) {
            // 选择的'全部'
            this.tab.tabListOrigin.forEach((el) => {
              if (el.isAllCard) {
                // 区域下所有卡台
                const currentAreaData = (
                  this.$store.state.cardPageInfo.resResultDataObj
                    .cardStatusNo || []
                ).filter((item) => item.region_id == el.id);
                // 当前区域下所有卡台都展示
                currentAreaData.forEach((el) => {
                  if (result[el.id] != undefined) {
                    result[el.id] = result[el.id] * 1 + el.cnt * 1;
                  } else {
                    result[el.id] = el.cnt * 1;
                  }
                });
              } else {
                // 区域下部分卡台
                const cardStatusNo =
                  this.$store.state.cardPageInfo.resResultDataObj
                    .cardStatusNo || [];
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
            });
          } else {
            const currentAreaInfo =
              this.tab.tabList.find(
                (item) => item.id == this.tab.activeIndex
              ) || {};
            if (currentAreaInfo.isAllCard) {
              const currentAreaData = (
                this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo ||
                []
              ).filter((item) => item.region_id == regionId);
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

              const cardStatusNo =
                this.$store.state.cardPageInfo.resResultDataObj.cardStatusNo ||
                [];
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
        result['5'] = result['6'] || 0 + result['5'] || 0;
        this.cardStatusNoInfo = result;
      }, 200);
    },
  },

  mounted() {
    window.addEventListener("click", (e) => this.legendOptionHandle());
    this.$refs.containRef.addEventListener(
      "scroll",
      this.windowScrollHideOptionsHandle
    );
    window.addEventListener("resize", this.windowResizeHandle);
    document.body.addEventListener("click", this.showOrHideOptionHandle);

    window.onkeydown = this.keydownHandle;
  },

  computed: {
    tabDateWidth() {
      return this.dateTab.dateTabList.length * 120;
    },
    // 是否为中午12点之前
    isMorning() {
      return new Date().getHours() < 12;
    },
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

  beforeDestroy() {
    document.body.removeEventListener("click", this.showOrHideOptionHandle);
    this.$refs.containRef.removeEventListener(
      "scroll",
      this.windowScrollHideOptionsHandle
    );
    window.removeEventListener("resize", this.windowResizeHandle);
    window.removeEventListener("click", (e) => this.legendOptionHandle());
    window.onkeydown = null;
  },

  components: {
    drawerReserved, // 未来日期预留
    cardDrawer, // 右侧弹出框
    fullPageTable, // 全屏表格数据
    drawerOpenCard, // 开台记录
    drawerTurnOver, // 转台记录
    updatePassword, // 修改密码
    drawerReservedRecord, // 预留记录
    drawerOnlineBooking, // 线上预订记录
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

  mixins: [cardPageMixins],
};
</script>

<style scoped lang="less">
@import "../../style/common/scrollBar.less";
@import "../../style/book/machine/cardMachine.less";
@import "../../style/book/cardBgc.less";
</style>

<style lang="less">
@import "../../style/common/elementConfirm.less";
</style>
