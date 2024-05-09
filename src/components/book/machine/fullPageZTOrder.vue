<template>
  <div class="fullPageTable white">
    <!-- 标题 -->
    <div
        class="title p-l-5 p-r-5"
        layout="row"
        layout-align="space-between center"
    >
      <span>{{ title }}</span>
      <i class="el-icon-close" @click.stop="closeFullPageHandle(false)"></i>
    </div>
    <!-- 内容 -->
    <div class="contain">
      <div class="contain-content">
        <ul>
          <li
              class="contain-content-item"
              v-for="(item, index) in pageData"
              :key="index"
          >
            <div class="contain-content-item-left">{{ item.name }}</div>
            <ul
                class="contain-content-item-right"
                layout="row"
                layout-align="start center"
            >
              <li
                  :class="{
                  active: items.id === activeId,
                  opacity:
                    (title == '转台' &&
                      (items.bizStatus != '1' || items.showOnlineText)) ||
                    (title == '并台' &&
                      [4, 5, 6].indexOf(items.bizStatus * 1) == -1),
                }"
                  v-for="(items, i) in item.cardList"
                  :key="i"
              >
                <img
                    :class="{ active: items.id === activeId }"
                    :src="selectActiveSrc"
                    alt
                />
                <div
                    :class="'bgc' + Number(items.bizStatus)"
                    @click.stop="chooseCard(items)"
                    layout="column"
                    layout-align="center start"
                >
                  <div
                      class="card-name"
                      :style="{ transform: 'scale(' + items.scaleNum + ')' }"
                  >
                    {{ items.name }}
                  </div>
                  <div class="card-amt">￥{{ items.grpMinCsmAmt }}</div>
                </div>
              </li>
            </ul>
          </li>
        </ul>
      </div>
    </div>
    <!-- 所选卡台信息 -->
    <div class="selected" layout="row" layout-align="end center">
      <span class="selected-info m-r-8">
        <span>当前选中卡台:</span>
        <span class="card-name">{{ selectedInfo.name }}</span>
      </span>
      <el-button
          type="info"
          class="m-r-5"
          @click.stop="closeFullPageHandle(false)"
      >取消</el-button
      >
      <el-button type="primary" class="m-r-5" @click.stop="submitHandle"
      >确定</el-button
      >
    </div>
  </div>
</template>

<script>
import selectActiveSrc from "@/assets/card-imgs/zhuantaiduigou.png";
let originPageData = [];
export default {
  data() {
    return {
      minAmt: "", // 筛选最小金额
      maxAmt: "", // 筛选最大金额
      pageData: [], // 页面数据
      selectedInfo: {}, // 所选中的卡台信息
      activeId: "",
      selectActiveSrc,
    };
  },
  methods: {
    getPageData() {
      const tabList = this.tabList || this.$store.state.cardPageInfo.tabList;
      const cardList = (
          this.cardList ||
          this.$store.state.cardPageInfo.cardList ||
          []
      ).map((item) => ({
        ...item,
        scaleNum: Math.min(1, 12 / this.$overall.character(item.name)),
      }));
      const resultData = JSON.parse(JSON.stringify(tabList));
      resultData.forEach((el) => {
        el.cardList = cardList.filter((ele) => ele.regionId === el.id);
      });
      originPageData = JSON.parse(JSON.stringify(resultData));
      this.pageData = resultData;
    },

    // 选择卡台
    chooseCard(cardInfo) {
      if (
          this.fromMerchant &&
          (Number(cardInfo.bizStatus) > 7 || Number(cardInfo.bizStatus) < 4)
      ) {
        this.$message.warning("不能选择空卡台、锁定卡台及预定卡台！");
        this.selectedCardInfo = { seatName: "/" };
        return;
      }
      if (
          (this.title == "转台" &&
              (cardInfo.bizStatus != "1" || cardInfo.showOnlineText)) ||
          (this.title == "并台" &&
              [4, 5, 6].indexOf(cardInfo.bizStatus * 1) == -1)
      )
        return;
      this.selectedInfo = cardInfo;
      this.selectedInfo.title = this.title;
      this.activeId = cardInfo.id;
    },

    // 点击确定按钮
    submitHandle() {
      if (!this.activeId) {
        return this.$message.warning("请选择卡台！");
      }
      this.$store.commit("updateNewCardInfo", this.selectedInfo);
      this.$emit("setChoosedCardInfo", this.selectedInfo);
      if (this.titleText != "并台") {
        this.closeFullPageHandle(true, true);
      }
    },

    // 关闭当前组件
    closeFullPageHandle(showDrawer, isSubmit = false) {
      console.log('fullpage-----showDrawer, isSubmit', showDrawer, isSubmit)
      this.$emit("showOrHideFullPageHandle", {
        showFullPage: false,
        showDrawer,
        isSubmit,
      });
    },
  },
  mounted() {
    console.log(this.fromMerchant);
    this.getPageData();
    this.selectedInfo = this.selectedCardInfo || {};
    this.selectedInfo.name = this.selectedInfo.exp_seat_id
        ? this.selectedInfo.seatName.split("/")[1]
        : "";
    this.activeId = this.selectedInfo.exp_seat_id
        ? this.selectedInfo.exp_seat_id.toString()
        : "";
  },
  props: [
    "titleText",
    "selectedCardInfo",
    "tabList",
    "cardList",
    "fromMerchant",
  ],
  computed: {
    title() {
      return this.titleText ? this.titleText : "转台";
    },
  },
  watch: {
    selectedCardInfo(newVal) {
      newVal.name = newVal.seatName.split("/")[1];
      this.selectedInfo = newVal;
      this.activeId = newVal.exp_seat_id ? newVal.exp_seat_id.toString() : "";
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../style/book/machine/fullPageZTOrder.less";
@import "../../../style/book/cardBgc.less";
</style>
