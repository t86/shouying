<template>
  <div class="nav" layout="row" layout-align="start start">
    <div class="nav-left">
      <div class="ul first-menu" ref="firstMenuRef" :style="{'height': !isRect ? 'calc(100vh - 120px)' : 'calc(100vh - 180px)'}">
        <div
          class="li first-menu-item"
          :class="{'active': firstCategoryActiveId === item.id}"
          v-for="(item,index) in firstCategoryList"
          :key="index"
          @click="changeFirstCategory(item.id)"
        >
          <span>{{item.name}}</span>
        </div>
      </div>
      <div class="li arrow" :style="{'bottom': !isRect ? '0px' : '60px'}">
        <div class="bg" layout="row" layout-align="center center">
          <div class="bg-left" @click="scrollHandle('first','up')">
            <img :src="imgSrc.arrow" alt />
          </div>
          <div class="bg-right" @click="scrollHandle('first','down')">
            <img :src="imgSrc.arrow" alt />
          </div>
        </div>
      </div>
    </div>
    <div class="nav-right">
      <div class="ul second-menu" ref="secondMenuRef" :style="{'height': !isRect ? 'calc(100vh - 120px)' : 'calc(100vh - 180px)'}">
        <div
          class="li"
          :class="{'active': secondCategoryActiveId === item.id}"
          v-for="(item,index) in secondCategoryList"
          :key="index"
          @click="secondCategoryActiveId = item.id"
        >
          <div class="item">
            <span>{{item.name}}</span>
          </div>
        </div>
      </div>
      <div class="li arrow" :style="{'bottom': !isRect ? '0px' : '60px'}">
        <div class="bg" layout="row" layout-align="center center">
          <div class="bg-left" @click="scrollHandle('second','up')">
            <img :src="imgSrc.arrow" alt />
          </div>
          <div class="bg-right" @click="scrollHandle('second','down')">
            <img :src="imgSrc.arrow" alt />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import arrow from "@/assets/order-img/arrow-Bottom.png";
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
      }
    };
  },
  methods: {

    // 检测是否为横屏
    getRectVal(){
      const width = screen.availWidth
      const height = screen.availHeight
      this.isRect = width >= height
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
      return this.productListAll.filter(
        el => el.twoCateId === secondCategoryId
      );
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
      const prdId = this.$route.query.mustOrderPrdId;
      const prdInfo = this.$store.state.cardPageInfo.resResultDataObj.goodsAroundInfo.find(
        item => item.id == prdId
      );
      this.changeFirstCategory(prdInfo.oneCateId);
      this.getCurrentProductList(prdInfo.twoCateId);
      this.firstCategoryActiveId = prdInfo.oneCateId;
      this.secondCategoryActiveId = prdInfo.twoCateId;
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
      default: () => {}
    },
    isGQ: {
      default: false
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