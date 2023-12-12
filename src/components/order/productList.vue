<template>
  <!-- 点单商品/套餐列表 -->
  <div class="product-list" ref="productListRef">
    <div class="search" layout="row" layout-align="start center">
      <input @blur="keyboardLeave" @click="keyboardShow('searchInputRef')" type="text" ref="searchInputRef"
        :style="{ 'width': isRect ? '220px' : '190px', color: '#1A1A21' }" @input="getPageData(1)"
        v-model="search.keyWord" placeholder="请输入商品首字母缩写" />
      <i v-if="search.keyWord" class="el-icon-circle-close" @click="search.keyWord = ''" />
      <img class="icon" :src="imgSrc.search" alt />
      <span>开台时间：</span>
      <span>{{ openTime }}</span>
    </div>

    <div class="card-list" ref="cardListRef">
      <div class="center-type" layout="row" layout-align="start start" :style="{ 'width': centerType + 'px' }">
        <div class="prd-item" v-if="pic_show" style="height: 384px;" v-for="item in productsList" :key="item.id"
          @click="setMealForProduct(item)" :class="{ 'opacity': item.outSomethingCount == 0 }">
          <div class="item-img-count">
            <img class="item-img" :src="item.picName ? pic_prefix_url + item.picName : $store.state.defaultImg" />
            <span class="item-span"
              v-if="shoppingCartList && shoppingCartList.length > 0 && shoppingCartList.findIndex(d => d.pid === item.id * 1) > -1">已点：{{
                shoppingCount(item.id * 1) }}</span>
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
        </div>


        <div class="prd-item" style="height: 160px;" v-if="!pic_show" v-for="item in productsList" :key="item.id"
          @click="setMealForProduct(item)" :class="{ 'opacity': item.outSomethingCount == 0 }">
          <div class="title">
            <h5>{{ item.name }}</h5>
            <p class="english-name one-txt-cut">{{ item.nameEng }}</p>
          </div>
          <div class="al-product">
            <span class="item-span"
              v-if="shoppingCartList && shoppingCartList.length > 0 && shoppingCartList.findIndex(d => d.pid === item.id * 1) > -1">已点：{{
                shoppingCount(item.id * 1) }}</span>
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




    <div class="card-name-top" ref="cardNameTop">
      <div class="card-name-title" ref="cardNameTitle">
        <span :style="{ fontSize: titleFontSize }">{{ cardInfo.name }}</span>
        <span :style="{ fontSize: titleFontSize1 }">
          {{
            empInfoFilter($store.state.orderInfo.currentCardInfo.salesEmpId)
          }}
        </span>
      </div>
      <div class="card-name-seat" v-if="cardInfo.chgSeatInfo">
        <p :style="{ fontSize: seatFontSize }">{{ cardInfo.chgSeatInfo }}</p>
      </div>
    </div>

    <div class="line-top"></div>

    <!-- 箭头 -->
    <div class="arrow">
      <div class="bg" layout="row" layout-align="center center">
        <div class="bg-left" @click="scrollArrowHandle('up')">
          <img :src="require('@/assets/card-imgs/new-arrow-bottom.png')" alt />
        </div>
        <div class="bg-right" @click="scrollArrowHandle('down')">
          <img :src="require('@/assets/card-imgs/new-arrow-bottom.png')" alt />
        </div>
      </div>
    </div>


    <!-- 系统时间 -->
    <div class="date-time-top" :class="{
      'm-l-6': !isRect && !isNarrowWidth,
      'p-l-3': !isNarrowWidth,
    }" layout="column" layout-align="center center">
      <p class="time">
        {{ authInfo.month }}-{{ authInfo.day }} {{ authInfo.hour }}:{{
          authInfo.minute
        }}
      </p>
      <p class="time" :class="{ rect: !isRect }">
        {{ authTips }}:{{ authInfo.name }}
      </p>
    </div>


    <!-- <el-dialog :visible.sync="dialogVisible" width="100%" :fullscreen="true" :before-close="beforeClose">
      <div style="width: 100%; display: flex; align-items: center; justify-content: center;">
        <img :src="bigImageUrl" style="width: 60%">
      </div>

    </el-dialog> -->

    <!-- 单品点单 -->
    <mealDrawer ref="mealDrawerRef" :showDrawer="drawer.showDrawer" :productInfo="currentProductInfo"
      @showOrHideDrawer="showOrHideDrawer" />

    <ImagePreview :dialogVisible="dialogVisible" :imgSrc="bigImageUrl" @handleCloseClick="handleCloseClick" />
  </div>
</template>

<script>
import common_book from "@/utils/common/book";
import api_order from "@/api/order";
import search from "@/assets/order-img/search-icon.png";
import mealDrawer from "@/components/order/newDrawerMeal";
import ImagePreview from "@/components/ImagePreview"
import common_order from "@/utils/common/order";
import { cloneDeep } from "lodash-es";

// 键盘码 keycode
let downKeyCode = [0, 0]
const ctrlAndShiftCode = [17, 16]

const cardWidth = 282;
let oneLineCount = 0;
let pageColl = 10; // 每页加载10行数据

let firstLoad = true; // 首次加载
export default {
  data() {
    return {
      isRect: true, // 是否为横屏

      centerType: 100, // 卡台版心宽度

      productsList: [], // 页面卡台分页后展示在页面的数据
      productsListTotal: [], // 卡台数据分页之前的所有数据
      currentProductInfo: {}, // 当前点单的商品信息
      page: 1,
      totalPage: 1, // 总页数
      search: {
        keyWord: ""
      },
      imgSrc: {
        search
      },

      drawer: {
        showDrawer: false
      },
      dialogVisible: false,
      bigImageUrl: "",
      pic_prefix_url: "",
      shoppingCartList: [],
      authInfo: {
        month: "00",
        day: "00",
        hour: "00",
        minute: "00",
        name: "",
      },
      cardInfo: {},
      // 是否收银系统
      isMoneyClient: false,
      titleFontSize: '32px', // 初始字体大小
      titleFontSize1: '24px',
      seatFontSize: '18px',
      isNarrowWidth: window.innerWidth < 850,
      pic_show: false,
      openTime: "",
    };
  },
  methods: {
    adjustFontSize() {
      const windowWidth = window.innerWidth;
      const titleElement = this.$refs.cardNameTitle;
      const titleWidth = titleElement.clientWidth;
      if (windowWidth > 1300) {
        this.titleFontSize = titleWidth > 350 ? '26px' : '30px';
        this.titleFontSize1 = titleWidth > 350 ? '20px' : '24px';
        this.seatFontSize = titleWidth > 350 ? '14px' : '18px';

      } else {
        let s = parseInt(windowWidth / 70);
        let s1 = parseInt(windowWidth / 90);
        let f = parseInt(windowWidth / 100);
        this.titleFontSize = `${s}px`
        this.titleFontSize1 = `${s1}px`
        this.seatFontSize = `${f}px`

      }
    },
    empInfoFilter(empId) {
      empId = this.$route.path.startsWith("/payOrder") ? this.empId : empId;
      const empInfo = common_book.getOrderPersonInfo(empId) || { name: "散客" };
      const groupInfoName = common_book.getDepartmentName(empId) || "";
      return (this.cardInfo.name ? "/" : "") + (groupInfoName ? groupInfoName + "/" : "") + empInfo.name;
    },
    getAuthInfo() {
      const date = new Date();
      this.authInfo = {
        month: (date.getMonth() + 1).toString().padStart(2, 0),
        day: date.getDate().toString().padStart(2, 0),
        hour: date.getHours().toString().padStart(2, 0),
        minute: date.getMinutes().toString().padStart(2, 0),
        name: this.$store.state.userInfo.name,
      };
    },
    keyboardShow(refString) {
      if (
        window.atool
        && window.atool.getTermType() == "android" &&
        ("showSoftInput" in window.atool)
      ) {
        atool.showSoftInput();
        atool.executeJs(`this.$refs.${refString}.focus()`)

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

    async getShoppingCartData() {
      try {
        const params = {
          id: this.$store.state.orderInfo.currentCardInfo.seatId * 1 // int64  卡台Id
        };
        const res = await api_order.reqGetShoppingList(params);
        if (res.code === 1) {
          this.shoppingCartList = res.data;
          console.log(res.data, '?????')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("购物车列表获取失败", error);
      }
    },

    getCenterType() {
      const containWidth = this.$refs.cardListRef.offsetWidth;
      oneLineCount = Math.floor(containWidth / cardWidth);
      this.centerType = oneLineCount * cardWidth;
      this.getPageData();
      this.getRectVal();
    },

    // 检测是否为横屏
    getRectVal() {
      const width = screen.availWidth
      const height = screen.availHeight
      this.isRect = width >= height
    },

    getPageData(page = 1) {
      this.page = page;
      const { keyWord } = this.search;

      this.productsListTotal =
        keyWord === ""
          ? this.currentCategoryProductList.filter(
            el => el.namePy.toLowerCase().includes(keyWord.toLowerCase()) || el.name.toLowerCase().includes(keyWord.toLowerCase())
          )
          : this.allProductsList.filter(
            el => el.namePy.toLowerCase().includes(keyWord.toLowerCase()) || el.name.toLowerCase().includes(keyWord.toLowerCase())
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

      this.productsList = this.productsListTotal || []
      this.pic_prefix_url = this.$store.state.cardPageInfo.resResultDataObj.storeStatusInfo[0].pic_prefix_url;
      let showAmt = this.$store.state.cardPageInfo.resResultDataObj.showAmt.find((item) => item.id == 8);
      this.pic_show = showAmt && showAmt.param1 === '1';
      // 获取当前估清商品的数量
      const outSomethingPrdList = this.$store.state.cardPageInfo.resResultDataObj[
        "prdOutOfSomething"
      ].filter(item => item.status == 1)

      /*  根据card.js secondCategoryInfo 3) 商品二级分类 id,name,status,dsp,oneCateId,enable_time_limit,begin_time,end_time,begin_time2,end_time2
         商品二级分类Id,分类名称,分类状态:1有效 2无效 3 删除, 分类显示顺序, 二级分类所属一级分类Id,开启时间段限制 1 开启 2 未开启,时间段1开始时间格式hh24:mi,时间段1结束时间,时间段2开始时间,时间段2结束时间 
         里的 enable_time_limit,begin_time,end_time,begin_time2,end_time2，判断当前商品是否在时间段内
         如果二级分类下没有商品，隐藏二级分类，如果一级分类下没有商品隐藏一级分类
         */
      const secondCategoryInfo = this.$store.state.cardPageInfo.resResultDataObj.secondCategoryInfo
      const nowTime = new Date().getTime()
      this.productsList = this.productsList.filter(item => {
        const find = secondCategoryInfo.find(el => el.id == item.twoCateId)
        if (find && find.enable_time_limit == 1) {
          const beginTime = new Date(new Date().toLocaleDateString() + ' ' + find.begin_time).getTime()
          const endTime = new Date(new Date().toLocaleDateString() + ' ' + find.end_time).getTime()
          const beginTime2 = new Date(new Date().toLocaleDateString() + ' ' + find.begin_time2).getTime()
          const endTime2 = new Date(new Date().toLocaleDateString() + ' ' + find.end_time2).getTime()
          if (nowTime < beginTime || nowTime > endTime) {
            if (nowTime < beginTime2 || nowTime > endTime2) {
              return false
            }
          }
        }
        return true
      })

      this.productsList.forEach(el => {
        const find = outSomethingPrdList.find(item => item.id == el.id)
        el.outSomethingCount = find ? find.cnt : 'many'
      })
      this.getGroupOutSomethingCount()
    },

    // 商品列表中套餐估清数量与不可选明细单品数量作比较（当前套餐可点数量为套餐估清数量与不可选商品估清数量最小值）
    getGroupOutSomethingCount() {
      const groupDetailList = this.$store.state.cardPageInfo.resResultDataObj["goodsDetailInfo"].filter(item => item.status == 1)
      const outSomethingPrdList = this.$store.state.cardPageInfo.resResultDataObj["prdOutOfSomething"].filter(item => item.status == 1)
      const allProductsList = cloneDeep(this.allProductsList)
      this.productsList.forEach(el => {
        if (el.prdType == 2) {  // 套餐
          // 不可选商品
          const canNotSelectProOutSomethingCount = []
          const canNotSelectProOutSomethingName = []
          const canNotSelectPrdDetailList = groupDetailList.filter(item => item.prdId == el.id && item.grpId == 1)
          canNotSelectPrdDetailList.forEach(ele => {
            const find = outSomethingPrdList.find(item => item.id == ele.dtlPrdId)
            if (find) {
              canNotSelectProOutSomethingCount.push(Math.floor(find.cnt / ele.prdCnt))
              const product = allProductsList.find(item => item.id == find.id);
              canNotSelectProOutSomethingName.push(product.name)
            }
          })
          if (canNotSelectProOutSomethingCount.length > 0) {  // 不可选单品配置过估清数量
            el.outSomethingCount = el.outSomethingCount == 'many' ? Math.min(...canNotSelectProOutSomethingCount) : Math.min(el.outSomethingCount, ...canNotSelectProOutSomethingCount);
            el['outSomethingName'] = canNotSelectProOutSomethingName.join('、')
          }
        }
      })
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

    // 点击放大镜放大图片
    clickDescImage(item) {
      this.bigImageUrl = item.picName ? this.pic_prefix_url + item.picName : this.$store.state.defaultImg
      this.dialogVisible = true;
    },
    handleCloseClick() {
      this.dialogVisible = false;
    },
    beforeClose(done) {
      // 在关闭对话框前重置状态
      this.dialogVisible = false;
      done();
    },
    // 点击商品/套餐
    setMealForProduct(productInfo) {
      if (productInfo.outSomethingCount == 0) {
        if (productInfo.prdType == 2 && productInfo.outSomethingName) {
          return this.$message.warning(`当前套餐内: ${productInfo.outSomethingName} 已售罄`)
        } else {
          return this.$message.warning('当前商品已售罄')
        }
      }
      productInfo.requireInfo = common_order.getRequireInfo(
        productInfo.twoCateId
      );
      this.currentProductInfo = productInfo;
      this.showOrHideDrawer(true);
    },

    showOrHideDrawer(value) {
      this.drawer.showDrawer = value;
      if (!value) {
        this.getShoppingCartData();
      }
    },

    scrollArrowHandle(direction) {
      let dom = this.$refs.productListRef;
      const step = 200;
      const scrollTop =
        direction === "down" ? dom.scrollTop + step : dom.scrollTop - step;
      dom.scrollTo(0, scrollTop);
    },

    // 收银快捷键
    keyHandle(e) {
      // alt 或 windows键(防止利用alt切屏)
      if (e.keyCode == 18 || e.keyCode == 91) return e.preventDefault()
      switch (e.type) {
        case 'keydown':

          if (downKeyCode.findIndex(item => item == 0) < 0) return

          if (ctrlAndShiftCode.includes(e.keyCode)) {
            downKeyCode[0] = e.keyCode
          } else if (downKeyCode[0] == 0 && downKeyCode[1] == 0) {
            downKeyCode[1] = e.keyCode
          } else if (downKeyCode[0] == e.keyCode && downKeyCode[1] == 0) {
            // 重复按同一个件
          } else if (downKeyCode[0] != 0 && downKeyCode[1] == 0) {
            downKeyCode[1] = e.keyCode
          }

          this.$nextTick(() => {
            if (downKeyCode[0] == 17 && downKeyCode[1] == 81) {
              //  ctrl + q  // 返回收银首页
              e.preventDefault()
              this.$router.replace({ name: 'moneyCard' })
            } else if (downKeyCode[0] == 17 && downKeyCode[1] == 70) {
              // ctrl + f  // 搜索框获取焦点
              e.preventDefault()
              this.$refs.searchInputRef.focus()
            } else if (downKeyCode[0] == 16 && downKeyCode[1] == 83) {
              // shift + s  // 购物车
              e.preventDefault()
              this.$parent.$parent.$refs.footBarRef &&
                this.$parent.$parent.$refs.footBarRef.footNavBarClick &&
                this.$parent.$parent.$refs.footBarRef.footNavBarClick({
                  id: 3,
                  name: "商品菜单",
                  routeName: "shoppingCart"
                });
            } else if (downKeyCode[0] == 16 && downKeyCode[1] == 68) {
              // shift + d  // 我的点单
              e.preventDefault()
              this.$parent.$parent.$refs.footBarRef &&
                this.$parent.$parent.$refs.footBarRef.footNavBarClick &&
                this.$parent.$parent.$refs.footBarRef.footNavBarClick({
                  id: 4,
                  name: "商品菜单",
                  routeName: "myOrder"
                });
            } else if (downKeyCode[0] == 0 && downKeyCode[1] == 13) {
              // enter  // 确认点单数量
              e.preventDefault()
              if (this.drawer.showDrawer) {
                this.$refs.mealDrawerRef.$refs.singleProductRef &&
                  this.$refs.mealDrawerRef.$refs.singleProductRef.onSubmit &&
                  this.$refs.mealDrawerRef.$refs.singleProductRef.onSubmit()
              }

            }
          })
          break;

        case 'keyup':
          const index = downKeyCode.findIndex(item => item == e.keyCode)

          if (index > -1) downKeyCode[1] = 0

          if (ctrlAndShiftCode.includes(e.keyCode)) downKeyCode = [0, 0]

          break
      }
    },

    // 点单快捷键
    keydownHandle(e) {
      if (e.keyCode == 13) {
        this.$nextTick(() => {
          if (this.drawer.showDrawer) {
            if (this.$refs.mealDrawerRef.type == 1 || this.$refs.mealDrawerRef.type == 4) {
              // 点单数量
              this.$refs.mealDrawerRef.$refs.singleProductRef.onSubmit()
            } else if (this.$refs.mealDrawerRef.type == 2) {
              // 点套餐
              this.$refs.mealDrawerRef.$refs.groupProduct.onSubmit()
            } else {
              // 授权
              this.$refs.mealDrawerRef.$refs.authorization.onSubmit()
            }
          }
        })
      }
    },

    addInputHandle(value) {
      this.search.keyWord = this.search.keyWord.toString() + value.toString()
      this.getPageData(1)
    },

    subInputHandle() {
      if (this.search.keyWord == '') return
      this.search.keyWord = this.search.keyWord.toString().slice(0, -1)
      this.getPageData(1)
    },
    getOpenTime() {
      let cardInfo = this.$store.state.orderInfo.currentCardInfo;
      if (cardInfo && cardInfo.openTime) {
        let h = parseInt(cardInfo.openTime.substring(8, 10)); // 时
        let s = parseInt(cardInfo.openTime.substring(10, 12)); // 分
        this.openTime = `${h}:${s}`
      }
    },
    shoppingCount(pid) {
      // 已点
      return this.shoppingCartList.reduce((sum, item) => {
        // 如果当前元素的 pid 与目标 pid 相同，则将其 count 累加到总和
        return item.pid === pid ? sum + item.pc : sum;
      }, 0);
    },
  },
  created() {
    setTimeout(() => {
      if (this.$store.state.userInfo.authStatus == 4) {
        document.onkeydown = this.keyHandle
        document.onkeyup = this.keyHandle
      } else {
        document.onkeydown = this.keydownHandle
      }
    }, 200);
  },
  mounted() {

    firstLoad = true;
    this.getShoppingCartData()
    this.getCenterType();
    this.getAuthInfo();
    this.isMoneyClient = sessionStorage.getItem("client") == "money"
    this.cardInfo = this.$store.state.orderInfo.currentCardInfo;
    this.getOpenTime(); //开台时间
    this.adjustFontSize(); // 在组件加载后调整一次字体大小
    window.addEventListener('resize', this.adjustFontSize); // 在窗口大小改变时再次调整字体大小
    // this.$refs.productListRef.addEventListener("scroll", this.scrollHandle);
  },
  props: ["allProductsList", "currentCategoryProductList"],
  computed: {
    isTerminal() {
      let termType = ''
      try {
        termType = atool.getTermType();
      } catch (error) {
        console.log('获取终端类型失败', error)
      }
      return termType == 'android' || termType == 'pc'
    },
    authTips() {
      return this.$route.path.startsWith("/orderMeal") ? "点单人" : "收银员";
    },
  },
  components: {
    mealDrawer,
    ImagePreview
  },
  watch: {
    currentCategoryProductList(newVal) {
      this.search.keyWord = firstLoad
        ? this.$route.query.mustPrdName || ""
        : "";
      this.productsListTotal = newVal;
      this.getPageData();
      firstLoad = false;
    }
  },

  beforeDestroy() {
    document.onkeydown = null
    document.onkeyup = null
    downKeyCode = [0, 0]
    window.removeEventListener('resize', this.adjustFontSize); // 在组件销毁前移除事件监听器
  }
};
</script>

<style scoped lang="less">
@import "../../style/order/orderMeal/productList.less";
</style>