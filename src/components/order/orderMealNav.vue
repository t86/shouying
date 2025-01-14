<template>
  <div class="nav" :style="customStyle" layout="row" layout-align="start start" v-if="!isMustPrd">
    <div class="nav-left">
      <div class="ul first-menu" ref="firstMenuRef"
        :style="{ 'height': isRect ? 'calc(100vh - 120px)' : 'calc(100vh - 180px)' }">
        <div class="li first-menu-item" :class="{ 'active': firstCategoryActiveId === item.id }"
          v-for="(item, index) in firstCategoryList" :key="index" @click="changeFirstCategory(item.id)">
          <span>{{ item.name }}</span>
        </div>
      </div>
      <div class="li arrow">
        <div class="bg" layout="row" layout-align="center center">
          <div class="bg-left" @click="scrollHandle('first', 'up')">
            <img :src="imgSrc.arrow" alt />
          </div>
          <div class="bg-right" @click="scrollHandle('first', 'down')">
            <img :src="imgSrc.arrow" alt />
          </div>
        </div>
      </div>
    </div>
    <div class="nav-right">
      <div class="ul second-menu" ref="secondMenuRef"
        :style="{ 'height': isRect ? 'calc(100vh - 120px)' : 'calc(100vh - 180px)' }">
        <div class="li" :class="{ 'active': secondCategoryActiveId === item.id }" v-for="(item, index) in secondCategoryList"
          :key="index" @click="secondCategoryActiveId = item.id">
          <div class="item" :style="{ fontSize: fontSize(item, index) + 'px'}" ref="cardRef">
            <span>{{ item.name }}</span>
          </div>
        </div>
      </div>
      <div class="li arrow">
        <div class="bg" layout="row" layout-align="center center">
          <div class="bg-left" @click="scrollHandle('second', 'up')">
            <img :src="imgSrc.arrow" alt />
          </div>
          <div class="bg-right" @click="scrollHandle('second', 'down')">
            <img :src="imgSrc.arrow" alt />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import arrow from "@/assets/card-imgs/new-arrow-bottom.png";
import navPrdList from '@/mixin/navPrdList'
export default {
  data() {
    return {
      isRect: true, // 是否为横屏

      firstCategoryList: [], // 所有一级分类列表数据集合
      secondCategoryList: [], // 当前一级分类下二级分类列表数据集合
      secondCategoryListAll: [], // 所有二级分类列表数据集合
      firstCategoryActiveId: "",
      secondCategoryActiveId: "",
      productListAll: [], // 当前有效可点的商品/套餐列表
      imgSrc: {
        arrow
      },
      isMustPrd: false
    };
  },
  methods: {
    fontSize(item) {
      let fontSize = 22;

      if (item.name.length > 12 ) {
          fontSize *= 0.6;
      }
      if (item.name.length > 6 ) {
          fontSize *= 0.8;
      }
      return fontSize;
    },
    // 检测是否为横屏
    getRectVal() {
      const width = screen.availWidth
      const height = screen.availHeight

      // this.isRect = width >= height
      this.isRect = window.innerWidth >= 1024
    },

    changeFirstCategory(firstCategoryId = "") {
      if (this.firstCategoryList.length > 0) {
        this.firstCategoryActiveId = firstCategoryId
          ? firstCategoryId
          : this.firstCategoryList[0].id;
        this.secondCategoryList = this.getCurrentSecondCategoryList(
          this.firstCategoryActiveId
        );
        this.secondCategoryActiveId =
          this.secondCategoryList.length > 0
            ? this.secondCategoryList[0].id
            : "";
      }
    },

    getCurrentSecondCategoryList(firstCategoryId) {
      return this.secondCategoryListAll.filter(
        el => el.oneCateId === firstCategoryId
      );
    },

    getCurrentProductList(secondCategoryId = this.secondCategoryActiveId) {
      // let hasShouyin = this.$store.state.userInfo.roleIds && this.$store.state.userInfo.roleIds.includes(5)
      // const emp_id = this.$store.state.userInfo.emp_id
      // let dianzhangInfo = this.$store.state.cardPageInfo.resResultDataObj.shopManagerConfig || []
      // const hasDianzhang = dianzhangInfo.findIndex((item) => item.emp_id == emp_id && item.status == 1) > -1

      let products = this.productListAll.filter(
        el => el.twoCateId === secondCategoryId
      );

      // if (!hasDianzhang && !hasShouyin) {
      if (true) {
        products = products.filter(item => {
          return item.limit_pc === '2' || item.limit_pad === "2"
        })
      }
      return products
    },

    scrollHandle(type, direction) {
      let dom = this.$refs[type + "MenuRef"];
      const step = 200;
      const scrollTop =
        direction === "down" ? dom.scrollTop + step : dom.scrollTop - step;
      dom.scrollTo(0, scrollTop);
    },

    // 通过购物车中未点商品定位商品
    getMustPrdInfo() {
      const prdIds = this.$route.query.mustOrderPrdId.split(',');
      const prdInfo = this.$store.state.cardPageInfo.resResultDataObj.goodsAroundInfo.find(
        item => prdIds.includes(item.id.toString()) 
      );
      // this.changeFirstCategory(prdInfo.oneCateId);
      // this.getCurrentProductList(prdInfo.twoCateId);
      // this.firstCategoryActiveId = prdInfo.oneCateId;
      // this.secondCategoryActiveId = prdInfo.twoCateId;
      // if(prdInfo) {
      //   this.isMustPrd = true
      // }
    }
  },
  created() {
  },
  mounted() {
    this.getMenuInfo(this.isGQ);
    this.getRectVal();
  },
  mixins: [navPrdList],
  props: {
    cardInfo: {
      default: () => { }
    },
    isGQ: {
      default: false
    },
    customStyle: {
      default: () => { }
    },
    // 是否核销卡券, 22.美团 12:抖音 32:小程序卡券
    redeem: {
      default: 0,
    }
  },
  watch: {
    secondCategoryActiveId(newVal) {
      console.log('gq', this.isGQ)
      this.$emit("updateProductsList", {
        key: "currentCategoryProductList",
        value: this.getCurrentProductList()
      });
    },
    isGQ(newValue) {
      if (newValue) {
        this.isGQ = true
        this.getMenuInfo(newValue)
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/order/orderMeal/orderMealNav.less";
</style>