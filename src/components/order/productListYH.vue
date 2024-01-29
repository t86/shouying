<template>
  <!-- 优惠2点单商品列表 -->
  <div class="product-list-YH" layout="row" layout-align="space-between start" ref="productListRef">
    <div class="pro-list">
      <div class="search" layout="row" layout-align="start center" @input="getPageData(1)">
        <span>全局搜索：</span>
        <input type="text" ref="searchInputRef" v-model="search.keyWord" placeholder="请输入商品名称或简写" />
        <i v-if="search.keyWord" class="el-icon-circle-close" @click="search.keyWord=''" />
        <img class="icon" :src="imgSrc.search" alt />
      </div>
      <div class="card-list" ref="cardListRef">
        <div
          class="center-type"
          layout="row"
          layout-align="start start"
          :style="{'width':centerType+'px'}"
        >
          <div class="prd-item" v-for="item in productsList" :key="item.id" @click="setMealForProduct(item)" :class="{'opacity': item.outSomethingCount == 0}">
            <h5 class="title">{{item.name}}</h5>
            <p v-if="item.outSomethingCount!='many'" class="count">余:{{item.outSomethingCount}}</p>
            <p v-else class="count"></p>
            <p class="price">{{item.prdType == 3 || item.prdType == 4 || item.prdType == 5 ? '时价' : '￥' + item.price}}</p>
            <img v-if="item.outSomethingCount==0" class="no-data-count" :src="require('@/assets/order-img/noCount.png')" />
          </div>
          <p v-if="totalPage!=1" class="tips">{{page>=totalPage? '没有更多了':'加载中...'}}</p>
        </div>
      </div>
    </div>
    <!-- 优惠2已选商品列表 -->
    <div class="selected-pro-list">
      <div class="title">已选商品</div>
      <div class="content">
        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">名称</div>
              <div class="th">数量</div>
              <div class="th">小计</div>
              <div class="th">操作</div>
            </div>
          </div>
          <div class="tbody">
            <div class="tr" v-for="(item, i) in selectedProList" :key="i">
              <div class="prd-info" layout="row" layout-align="space-between center">
                <div class="td">{{item.name}}</div>
                <div class="td">
                  <img
                    :src="item.prdType == 4 || item.pc == 1 ? imgSrc.subDisabled : imgSrc.sub"
                    @click="changeCount('sub',item)"
                    alt
                  />
                  <input
                    type="number"
                    min="1"
                    v-model="item.pc"
                    :disabled="item.prdType == 4"
                    @input="changeCount('input',item)"
                  />
                  <img
                    :src="item.prdType==4? imgSrc.addDisabled : imgSrc.add"
                    @click="changeCount('add',item)"
                    alt
                  />
                </div>
                <div class="td">{{item.price * 1 == 0 ? item.amt.toFixed(2) : item.pc * item.price}}</div>
                <div class="td" @click="deletePrdHandle(item.id)">删除</div>
              </div>
              <div class="require p-l-2">{{item.require}}</div>
            </div>
          </div>
        </div>
        <div class="btn-area" layout="row" layout-align="space-between center">
          <div
            class="person-info"
            style="cursor:pointer;width:calc(100% - 160px);font-weight:600"
            @click="choosePersonInfoHandle"
          >
            <div
              v-if="personInfo.sales.sales_name"
              style="line-height:20px"
            >{{personInfo.sales.sales_name}};{{personInfo.choosedCardInfo.name}}</div>
            <div
              v-if="personInfo.sales.sales_name"
              style="line-height:20px"
              class="one-txt-cut"
            >{{personInfo.reason}}</div>
          </div>
          <div
            class="button"
            @click="showOrHideSubmitDrawer"
          >{{personInfo.sales.sales_name ? '确定' : '下一步'}}</div>
        </div>
      </div>
    </div>

    <!-- 单品点单 -->
    <mealDrawer
      ref="mealDrawerRef"
      :showDrawer="drawer.showDrawer"
      :productInfo="currentProductInfo"
      @showOrHideDrawer="showOrHideDrawer"
      @getYh2ProInfo="getYh2ProInfo"
    />

    <!-- 提交优惠2 -->
    <drawerYH2Submit
      ref="drawerYH2Submit"
      :status="status"
      :showDrawer="drawer.showSubmitDrawer"
      :selectedProList="selectedProList"
      :personInfo="personInfo"
      @setPersonInfo="setPersonInfo"
      @showOrHideDrawer="showOrHideSubmitDrawer"
    />
  </div>
</template>

<script>
import search from "@/assets/order-img/search.png";
import mealDrawer from "@/components/order/drawerMeal";
import drawerYH2Submit from "@/components/order/drawerMeal/drawerYH2Submit.vue";

import common_order from "@/utils/common/order";

import add from "@/assets/order-img/order_add.png";
import sub from "@/assets/order-img/sub.png";
import addDisabled from "@/assets/order-img/add-disabled.png";
import subDisabled from "@/assets/order-img/sub-disabled.png";

const cardWidth = 180;
let oneLineCount = 0;
let pageColl = 10; // 每页加载10行数据

// 键盘码 keycode
let downKeyCode = [0, 0]
const ctrlAndShiftCode = [17, 16]

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

      imgSrc: {
        search,
        add,
        sub,
        addDisabled,
        subDisabled
      },

      // 优惠2已选商品列表相关
      drawer: {
        showDrawer: false,
        showSubmitDrawer: false
      },

      status: 1,

      // 已选优惠2商品列表
      selectedProList: [],

      personInfo: {
        sales: {
          sales_name: "", // 订位人名称
          sales_emp_id: "", // 订位人id
          sales_phone: "", // 订位人电话
          sales_info_option: [] // 订位人下拉框选项
        },
        reason: "",
        showFullPage: false, // 是否显示选择卡台组件
        choosedCardInfo: {} // 选择好的卡台信息
      }
    };
  },
  methods: {
    getCenterType() {
      const containWidth = this.$refs.cardListRef.offsetWidth;
      oneLineCount = Math.floor(containWidth / cardWidth);
      this.centerType = oneLineCount * cardWidth;
      this.getPageData();
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

      this.productsList = this.productsListTotal || []

      // 获取当前估清商品的数量
      const outSomethingPrdList = this.$store.state.cardPageInfo.resResultDataObj[
        "prdOutOfSomething"
        ].filter(item => item.status == 1)

      this.productsList.forEach(el => {
        const find = outSomethingPrdList.find(item => item.id == el.id)
        el.outSomethingCount = find ? find.cnt : 'many'
      })

      /*  根据card.js secondCategoryInfo 3) 商品二级分类 id,name,status,dsp,oneCateId,enable_time_limit,begin_time,end_time,begin_time2,end_time2
          商品二级分类Id,分类名称,分类状态:1有效 2无效 3 删除, 分类显示顺序, 二级分类所属一级分类Id,开启时间段限制 1 开启 2 未开启,时间段1开始时间格式hh24:mi,时间段1结束时间,时间段2开始时间,时间段2结束时间 
          里的 enable_time_limit,begin_time,end_time,begin_time2,end_time2，判断当前商品是否在时间段内
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
      if (productInfo.outSomethingCount == 0) return this.$message.warning('当前商品已售罄')
      productInfo.requireInfo = common_order.getRequireInfo(
        productInfo.twoCateId
      );
      this.currentProductInfo = productInfo;
      this.showOrHideDrawer(true);
    },

    showOrHideDrawer(value) {
      this.drawer.showDrawer = value;
    },

    // ====================优惠2相关===========================

    // 添加优惠2商品至已选列表
    getYh2ProInfo(proInfo) {
      // 判断已选列表中是否存在当前所选的商品
      const hasPro = this.selectedProList.find(item => item.id == proInfo.id);
      if (hasPro) {
        this.selectedProList = this.selectedProList.map(item => ({
          ...item,
          pc: item.id == proInfo.id ? item.pc * 1 + proInfo.pc * 1 : item.pc
        }));
      } else {
        this.selectedProList.push(proInfo);
      }
      this.showOrHideDrawer(false);
    },

    // 更改已选商品数量
    changeCount(type, info) {
      if (info.prdType == 4) return this.$message.warning("小费无法更改数量");
      let count = info.pc;
      switch (type) {
        case "add":
          count = Math.min(count + 1, 1000);
          break;
        case "sub":
          count = Math.max(count - 1, 1);
          break;
        case "input":
          count = Math.min(count, 1000);
          count = Math.max(count, 1);
          break;
      }
      // 是否为估清商品及数量限制
      const outOfSomethingPrdList = this.$store.state.cardPageInfo
        .resResultDataObj.prdOutOfSomething;
      const isOutOfSomethingPrd = outOfSomethingPrdList.find(
        item => item.id == info.id
      );
      if (isOutOfSomethingPrd && isOutOfSomethingPrd.cnt < count) {
        this.$message.warning(
          "点单数量已超过当前可点估清数量" + isOutOfSomethingPrd.cnt
        );
      } else {
        info.pc = count;
      }
    },

    // 删除优惠2中已选商品
    deletePrdHandle(id) {
      const index = this.selectedProList.findIndex(item => item.id == id);
      if (index > -1) this.selectedProList.splice(index, 1);
    },

    // 显示或隐藏提交优惠2抽屉
    showOrHideSubmitDrawer(status) {
      if (!this.drawer.showSubmitDrawer && this.selectedProList.length == 0)
        return this.$message.warning("请选择需要优惠的商品");
      this.status = status == 1 ? 1 : !this.personInfo.sales.sales_name ? 1 : 2;
      this.drawer.showSubmitDrawer = !this.drawer.showSubmitDrawer;
    },

    choosePersonInfoHandle() {
      this.showOrHideSubmitDrawer(1);
    },

    setPersonInfo(objInfo) {
      this.personInfo = objInfo;
    },

    keyHandle(e){
      console.log('productlistyh keyHandle')
      // alt 或 windows键(防止利用alt切屏)
      if (e.keyCode == 18 || e.keyCode == 91) return e.preventDefault()
      switch (e.type){
        
        case 'keydown':

        if(downKeyCode.findIndex(item => item == 0) < 0) return

        if (ctrlAndShiftCode.includes(e.keyCode)) {
          downKeyCode[0] = e.keyCode
        } else if (downKeyCode[0] == 0 && downKeyCode[1] == 0) {
          downKeyCode[1] = e.keyCode
        } else if (downKeyCode[0] == e.keyCode && downKeyCode[1] == 0 ){
          // 重复按同一个件
        } else if (downKeyCode[0] != 0 && downKeyCode[1] == 0) {
          downKeyCode[1] = e.keyCode
        }

        this.$nextTick(() => {
          if(downKeyCode[0] == 17 && downKeyCode[1] == 81) {
            //  ctrl + q  // 返回收银首页
            e.preventDefault()
            this.$router.replace({name: 'moneyCard'})
          } else if (downKeyCode[0] == 17 && downKeyCode[1] == 70) {
            // ctrl + f  // 搜索框获取焦点
            e.preventDefault()
            this.$refs.searchInputRef.focus()
          } else if (downKeyCode[0] == 0 && downKeyCode[1] == 13) {
            // enter
            e.preventDefault()
            if(this.drawer.showDrawer){
              // 确认优惠2数量
              this.$refs.mealDrawerRef.$refs.singleProductRef &&
              this.$refs.mealDrawerRef.$refs.singleProductRef.onSubmit &&
              this.$refs.mealDrawerRef.$refs.singleProductRef.onSubmit()
            } else if(!this.drawer.showSubmitDrawer) {
              // 优惠2商品 下一步
              this.showOrHideSubmitDrawer()
            } else if (this.$refs.drawerYH2Submit.formData.showFullPage) {
              // 选择卡台
              this.$refs.drawerYH2Submit.$refs.fullPageTableRef.submitHandle()
            } else if (this.drawer.showSubmitDrawer) {
              if(this.$refs.drawerYH2Submit.type == 1){
                // 下一步弹框展开中
                this.$refs.drawerYH2Submit.onSubmit()
              } else {
                // 授权
                this.$refs.drawerYH2Submit.$refs.authorization.onSubmit()
              }
            }
            
          } else if (downKeyCode[0] == 0 && downKeyCode[1] == 38) {
            // up
            e.preventDefault()
            if (this.drawer.showSubmitDrawer && this.$refs.drawerYH2Submit.type != 1 && this.$refs.drawerYH2Submit.$refs.authorization.tabIndex == 2) {
              // 授权向上移动input框焦点
              this.$refs.drawerYH2Submit.$refs.authorization.checkedIndex = 1
              this.$refs.drawerYH2Submit.$refs.authorization.$refs.userNameRef.focus()
            }
          } else if (downKeyCode[0] == 0 && downKeyCode[1] == 40) {
            // down
            e.preventDefault()
            if (this.drawer.showSubmitDrawer && this.$refs.drawerYH2Submit.type != 1 && this.$refs.drawerYH2Submit.$refs.authorization.tabIndex == 2) {
              // 授权向下移动input焦点
              this.$refs.drawerYH2Submit.$refs.authorization.checkedIndex = 2
              this.$refs.drawerYH2Submit.$refs.authorization.$refs.passwordRef.focus()
            }

          } else if (downKeyCode[0] == 0 && downKeyCode[1] == 37) {
            // left
            e.preventDefault()
            if (this.drawer.showSubmitDrawer && this.$refs.drawerYH2Submit.type != 1) {
              // 授权切换为刷卡
              this.$refs.drawerYH2Submit.$refs.authorization.tabIndex = 1
            }

          } else if (downKeyCode[0] == 0 && downKeyCode[1] == 39) {
            // right
            e.preventDefault()
            if (this.drawer.showSubmitDrawer && this.$refs.drawerYH2Submit.type != 1) {
              // 授权切换为密码输入
              this.$refs.drawerYH2Submit.$refs.authorization.tabIndex = 2
              this.$nextTick(() => {
                this.$refs.drawerYH2Submit.$refs.authorization.$refs.userNameRef.focus()
              })
            }

          }
        })
          break;

        case 'keyup':
          const index = downKeyCode.findIndex(item => item == e.keyCode)

          if (index > -1) downKeyCode[1] = 0

          if(ctrlAndShiftCode.includes(e.keyCode)) downKeyCode = [0, 0]
          
          break
      }
    }
  },  
  created () {
  },
  mounted() {
    console.log('productlistYH mounted')
    if (this.$store.state.userInfo.authStatus == 4) {
      window.addEventListener('keydown', this.keyHandle);
      window.addEventListener('keyup', this.keyHandle);
    }
    this.getCenterType();
    this.$refs.productListRef.addEventListener("scroll", this.scrollHandle);
  },
  props: ["allProductsList", "currentCategoryProductList"],
  components: {
    mealDrawer,
    drawerYH2Submit
  },
  watch: {
    currentCategoryProductList(newVal) {
      this.search.keyWord = "";
      this.productsListTotal = newVal;
      this.getPageData();
    }
  },

  beforeDestroy () {
    console.log('productlistYH destroy')
    window.removeEventListener('keydown', this.keyHandle);
    window.removeEventListener('keyup', this.keyHandle);
    downKeyCode = [0, 0]
    this.$refs.productListRef.removeEventListener("scroll", this.scrollHandle);
  }
};
</script>

<style scoped lang="less">
@import "../../style/order/orderMeal/productListYH.less";
</style>