<template>
  <!-- 估清商品列表 -->
  <div class="product-list-GQ" layout="row" layout-align="space-between start" ref="productListRef">
    <div class="pro-list">
      <div class="search" layout="row" layout-align="start center" @input="getPageData(1)">
        <!-- <span>全局搜索：</span> -->
        <input type="text" v-model="search.keyWord" placeholder="请输入商品名称或简写" />
        <i v-if="search.keyWord" class="el-icon-circle-close" @click="search.keyWord = ''" />
        <img class="icon" :src="imgSrc.search" alt />
      </div>
      <div class="card-list" ref="cardListRef">
        <div class="center-type" layout="row" layout-align="start start" :style="{ 'width': centerType + 'px' }">
          <!-- <div class="prd-item" v-if="pic_show" style="height: 384px;" v-for="item in productsList" :key="item.id"
            @click="setMealForProduct(item)" :class="{ 'opacity': item.outSomethingCount == 0 }">
            <div class="item-img-count">
              <img class="item-img"
                :src="item.picName ? pic_prefix_url + item.picName : $store.state.defaultImg" />
              <span class="item-span"
                v-if="shoppingCartList && shoppingCartList.length > 0 && shoppingCartList.findIndex(d => d.pid === item.id * 1) > -1">已点：{{
                  shoppingCartList.find(d => d.pid === item.id * 1).pc }}</span>
            </div>
            <div class="title">
              <h5>{{ item.name }}</h5>
              <p class="english-name one-txt-cut">{{ item.nameEng }}</p>
            </div>
            <div class="item-footer">
              <p v-if="item.outSomethingCount != 'many'" class="count">余:{{ item.outSomethingCount }}</p>
              <p v-else class="count"></p>
              <p class="price">{{ item.prdType == 3 || item.prdType == 4 || item.prdType == 5 ? '时价' : '￥' + item.price }}
              </p>
            </div>

            <img v-if="item.outSomethingCount == 0" class="no-data-count"
              :src="require('@/assets/order-img/noCount.png')" />

            <img :src="require('@/assets/order-img/fangdatu.png')" class="fangda" @click.stop="clickDescImage(item)" />
            <div class="hover-click"></div>
          </div> -->

          <div class="prd-item" style="height: 160px;" v-for="item in productsList" :key="item.id"
            @click="setMealForProduct(item)" :class="{ 'opacity': item.outSomethingCount == 0 }">
            <div class="title">
              <h5>{{ item.name }}</h5>
              <p class="english-name one-txt-cut">{{ item.nameEng }}</p>
            </div>
            <div class="al-product">
              <span class="item-span"
                v-if="shoppingCartList && shoppingCartList.length > 0 && shoppingCartList.findIndex(d => d.pid === item.id * 1) > -1">已点：{{
                  shoppingCartList.find(d => d.pid === item.id * 1).pc }}</span>
            </div>
            <div class="item-footer">
              <p v-if="item.outSomethingCount != 'many'" class="count">余:{{ item.outSomethingCount }}</p>
              <p v-else class="count"></p>
              <p class="price">{{ item.prdType == 3 || item.prdType == 4 || item.prdType == 5 ? '时价' : '￥' + item.price }}
              </p>
            </div>

            <img v-if="item.outSomethingCount == 0" class="no-data-count1"
              :src="require('@/assets/order-img/noCount.png')" />
          </div>
          <p v-if="totalPage != 1" class="tips">{{ page >= totalPage ? '没有更多了' : '加载中...' }}</p>
        </div>
      </div>
    </div>
    <!-- 估清已选商品列表 -->
    <div class="selected-pro-list">
      <div class="title">估清商品</div>
      <div class="content">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">商品名称</div>
              <div class="th">剩余估清数量</div>
              <div class="th">操作</div>
            </div>
          </div>
          <div class="tbody">
            <div class="tr" v-for="(item, i) in tableData" :key="i">
              <div class="prd-info" layout="row" layout-align="space-between center">
                <div class="td">{{ item.n }}</div>
                <div class="td">{{ item.c }}</div>
                <div class="td" style="color: #2170ff; cursor: pointer;" @click.stop="deletePrdHandle(item.id)">删除</div>
              </div>
              <div class="require p-l-2">{{ item.require }}</div>

            </div>
          </div>
        </div>

      </div>
      <div class="btn-area" layout="row" layout-align="center center">
        <div class="button cancel" @click.stop="$emit('showOrHideOutSomethingHandle')">取消</div>
        <div class="button" style="margin-left: 4px;" @click.stop="$emit('showOrHideOutSomethingHandle')">确定</div>
      </div>
    </div>

    <!-- 单品点单 -->
    <mealDrawer ref="mealDrawer" :showDrawer="drawer.showDrawer" :productInfo="currentProductInfo"
      @showOrHideDrawer="showOrHideDrawer" @getGQPrdList="getGQPrdList" />

    <ImagePreview :dialogVisible="dialogVisible" :imgSrc="bigImageUrl" @handleCloseClick="handleCloseClick" />

  </div>
</template>

<script>
import api_order from "@/api/order";
import search from "@/assets/order-img/new-search.png";
import mealDrawer from "@/components/order/newDrawerMeal";
import ImagePreview from "@/components/ImagePreview";
import common_order from "@/utils/common/order";

import add from "@/assets/order-img/new_order_add.png";
import sub from "@/assets/order-img/new_sub.png";
import addDisabled from "@/assets/order-img/new-add-disabled.png";
import subDisabled from "@/assets/order-img/new-sub-disabled.png";

const cardWidth = 282;
let oneLineCount = 0;
let pageColl = 10; // 每页加载10行数据
export default {
  data() {
    return {
      centerType: 100, // 卡台版心宽度

      productsList: [], // 页面卡台分页后展示在页面的数据
      productsListTotal: [], // 卡台数据分页之前的所有数据
      currentProductInfo: {}, // 当前点单的商品信息
      page: 1,
      totalPage: 1, // 总页数
      search: {
        keyWord: ""
      },
      shoppingCartList:[],
      
      drawer: {
        showDrawer: false
      },

      imgSrc: {
        search,
        add,
        sub,
        addDisabled,
        subDisabled
      },

      // 估清商品列表
      tableData: [],
      pic_prefix_url: "",
      bigImageUrl: "",
      dialogVisible: false,
      pic_show: false
    };
  },
  methods: {
    getPicUrl() {
      this.pic_prefix_url = this.$store.state.cardPageInfo.resResultDataObj.storeStatusInfo[0].pic_prefix_url;
      let showAmt = this.$store.state.cardPageInfo.resResultDataObj.showAmt.find((item) => item.id == 8);
      this.pic_show = showAmt && showAmt.param1 === '1';
    },
    // 点击放大镜放大图片
    clickDescImage(item) {
      this.bigImageUrl = item.picName ? this.pic_prefix_url + item.picName : this.$store.state.defaultImg
      this.dialogVisible = true;
    },
    handleCloseClick() {
      this.dialogVisible = false;
    },
    getCenterType() {
      this.$nextTick(() => {
        const containWidth = this.$refs.cardListRef.offsetWidth;
        oneLineCount = Math.floor(containWidth / cardWidth);
        this.centerType = oneLineCount * cardWidth ;
      });
    },


    getPageData(page = 1) {
      this.page = page;
      const { keyWord } = this.search;

      this.productsListTotal =
        keyWord === ""
          ? this.currentCategoryProductList.filter(
            el => el.namePy.includes(keyWord) || el.name.includes(keyWord)
          )
          : this.allProductsList.filter(
            el => el.namePy.includes(keyWord) || el.name.includes(keyWord)
          );

      // this.productsListTotal =
      //   this.allProductsList.filter(el => el.namePy.startsWith(keyWord) || el.name.startsWith(keyWord))

      /*
      this.totalPage = Math.ceil(
        this.productsListTotal.length / (pageColl * oneLineCount)
      );
      this.productsList = this.productsListTotal.slice(
        0,
        this.page * oneLineCount * pageColl
      );
      */
      this.productsList = (this.productsListTotal || []).map(item => {
        // console.log(this.tableData.find(items => items.id == item.id), 90);
        return {
          ...item,
          outSomethingCount: (this.tableData.find(items => items.id * 1 == item.id * 1) || { c: 'many' }).c
        }
      })
      console.log(this.productsList);
    },

    // scrollHandle() {
    //   const pageHeight = this.$refs.cardListRef.offsetHeight;
    //   const clientHeight = this.$refs.productListRef.offsetHeight;
    //   const scrollTop = this.$refs.productListRef.scrollTop;
    //   if (pageHeight - clientHeight - scrollTop < 20) {
    //     this.page += 1;
    //     if (this.page <= this.totalPage) this.getPageData(this.page);
    //   }
    // },

    // 点击商品/套餐
    setMealForProduct(productInfo) {
      productInfo.requireInfo = common_order.getRequireInfo(
        productInfo.twoCateId
      );
      this.currentProductInfo = productInfo;
      this.showOrHideDrawer(true);
    },

    // 显示或隐藏点单数量或授权抽屉
    showOrHideDrawer(value) {
      this.drawer.showDrawer = value;
    },

    // ====================估清相关===========================

    // 获取估清商品列表
    async getGQPrdList() {
      try {
        const res = await api_order.reqGetGQOrderList();
        if (res.code == 1) {
          res.data.items = res.data.items || []
          this.tableData = res.data.items.map(item => ({
            ...item,
            originCount: item.c
          }))
          this.getPageData()
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("估清商品获取失败", error);
      }
    },

    // // 更改数据库对应的估清商品数量
    // async changeGQPrdCount(itemInfo, needLoad = true) {
    //   const params = {
    //     prd_id: itemInfo.id * 1, //     int64    商品Id
    //     cnt: itemInfo.c * 1 //   int  数量
    //   };
    //   try {
    //     const res = await api_order.reqAddGQOrder(params);
    //     if (res.code == 1) {
    //       if (needLoad) this.getGQPrdList();
    //     } else {
    //       this.$message.warning(res.msg);
    //     }
    //   } catch (error) {
    //     console.log("修改估清商品数量失败", error);
    //   }
    // },

    // // 更改估清商品数量
    // changeCount(type, info) {
    //   let count = info.c;
    //   switch (type) {
    //     case "add":
    //       count = Math.min(count + 1, 1000);
    //       break;
    //     case "sub":
    //       if (count <= 0) return
    //       count = Math.max(count - 1, 0);
    //       break;
    //     case "input":
    //       count = Math.min(count, 1000);
    //       count = Math.max(count, 0);
    //       break;
    //   }
    //   this.changeGQPrdCount({
    //     id: info.id,
    //     c: count - info.originCount
    //   }, false);
    //   info.c = info.originCount = count

    //   this.getPageData()
    // },

    async deletePrdHandle(id) {
      const params = {
        prd_id: id * 1, //     int64    商品Id
      };
      try {
        const res = await api_order.reqDelGQOrder(params);
        if (res.code == 1) {
          this.getGQPrdList();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("解除估清失败", error);
      }
    }
  },
  mounted() {
    this.getCenterType();
    this.getGQPrdList();
    this.getPicUrl();
    // this.$refs.productListRef.onscroll = this.scrollHandle
  },
  props: ["allProductsList", "currentCategoryProductList"],
  components: {
    mealDrawer,
    ImagePreview
  },
  watch: {
    currentCategoryProductList(newVal) {
      this.search.keyWord = "";
      this.productsListTotal = newVal;
      this.getPageData();
    }
  }
};
</script>

<style scoped lang="less">
@import "../../style/order/orderMeal/newProductListGQ.less";
</style>