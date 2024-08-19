<template>
  <div class="fullPageTable white" style="z-index: 99;">
    <!-- 标题 -->
    <div
      class="title p-l-5 p-r-5"
      layout="row"
      layout-align="space-between center"
    >
      <span>{{ title }}</span>
      <i class="el-icon-close" @click.stop="closeFullPageHandle(false)"></i>
    </div>
    <!-- 筛选 -->
    <div class="search" >
      <span style="color: red;">选择当前低消组中的卡台</span>
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
                  active: selectedInfo.map(item => item.id * 1).includes(items.id * 1)
                }"
                v-for="(items, i) in item.cardList"
                :key="i"
              >
                <img
                  :class="{ active: selectedInfo.map(item => item.id * 1).includes(items.id * 1)}"
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
                </div>
              </li>
            </ul>
          </li>
        </ul>
      </div>
    </div>
    <!-- 所选卡台信息 -->
    <div class="selected" layout="row" layout-align="end center">
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
export default {
  data() {
    return {
      pageData: [], // 页面数据
      selectedInfo: {}, // 所选中的卡台信息
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
        el.cardList = el.cardList.map(item =>{
          return {
            ...item,
            areaStatus: el.status,
            areaName: el.name
          }
        });
      });
      this.pageData = resultData;
    },

    // 选择卡台
    chooseCard(cardInfo) {
      if(this.selectedInfo.map(item => item.id * 1).includes(cardInfo.id * 1)){
        this.selectedInfo = this.selectedInfo.filter(item => item.id * 1 !== cardInfo.id * 1);
      } else {
        this.selectedInfo = [...this.selectedInfo, cardInfo];
      }
    },

    // 点击确定按钮
    submitHandle() {
      if (!this.selectedInfo || this.selectedInfo.length == 0) return this.$message.warning("请选择卡台！");
      this.$emit("setChoosedCardInfo", this.selectedInfo);
    },

    // 关闭当前组件
    closeFullPageHandle(showDrawer, isSubmit = false) {
      this.$emit("showOrHideFullPageHandle", {
        showFullPage: false,
        showDrawer,
        isSubmit,
      });
    },
  },
  mounted() {
    this.getPageData();
    this.selectedInfo = this.selectedCardInfo || [];
  },
  props: [
    "selectedCardInfo",
    "tabList",
    "cardList",
    "fromMerchant",
  ],
  computed: {
    title() {
      return "选中卡台";
    },
  },
  watch: {
    selectedCardInfo(newVal) {
      this.selectedInfo = [...newVal];
    },
  },
};
</script>

<style scoped lang="less">
@import "./fullPageTable.less";
@import "./cardBgc.less";
</style>
