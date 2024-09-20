<template>
  <!-- 点单商品/套餐列表 -->
  <div class="product-list" ref="productListRef">
    <div class="search" layout="row" layout-align="start center">
      <input @blur="keyboardLeave('searchInputRef')" @click="keyboardShow('searchInputRef')" type="text" ref="searchInputRef"
        :style="{ 'width': isRect ? '220px' : '190px', color: '#1A1A21' }" @input="getPageData(1)"
        v-model="search.keyWord" placeholder="请输入商品首字母缩写" />
      <i v-if="search.keyWord" class="el-icon-circle-close" @click="search.keyWord = ''" />
      <img class="icon" :src="imgSrc.search" alt />
      <div class="opentime" layout="row" layout-align="center center">
        <span >开台时间：</span>
        <span>{{ openTime }}</span>
      </div>
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




    <div class="card-name-top" ref="cardNameTop" :style="{ right: isRect ? (isMediumWidth ? '300px' : '420px') : '300px'}">
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

    <div class="card-name-top2" ref="cardNameTop2">
      <div class="card-name-title" ref="cardNameTitle" v-if="displayCustName !== '' " @click="bindGuest">
        <span style="font-size: 16px; margin-right: 3px; cursor: pointer; color:  rgba(59, 130, 246, 0.8)">{{ displayCustName }}</span>
      </div>
      <div  class="bind-guest" v-else @click="bindGuest">
        <img :src="require('@/assets/card-imgs/bangdingfuwuyuan.png')" style="width: 16px;height: 16px" alt />
        绑定客人
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
      <div layout="row" layout-align="end center" class="bind-emp" v-if="showEmp && empId*1 == 0 && isValidCard" @click="showChangeFwy = true">
        <img :src="require('@/assets/card-imgs/bangdingfuwuyuan.png')" style="width: 16px;height: 16px" alt />
        绑定当台服务员
      </div> 
      <div v-else layout="row" layout-align="start center" class="author" :class="{ rect: !isRect }" @click="showDiandanEmpChange">
<!--        {{ authTips }}: {{authInfo.name}}-->
        <div class = 'text-ellipsis' >
                  {{authInfo.name}}
        </div>
        <img style="margin-left: 10px;" class="item-img" alt="修改卡台服务员" v-if="hasChgKTWaiterAuth && isValidCard"  :src="require('@/assets/img/btn_edit.png')" />
      </div>
    </div>


    <!-- <el-dialog :visible.sync="dialogVisible" width="100%" :fullscreen="true" :before-close="beforeClose">
      <div style="width: 100%; display: flex; align-items: center; justify-content: center;">
        <img :src="bigImageUrl" style="width: 60%">
      </div>

    </el-dialog> -->

    
    <el-dialog title="修改卡台服务员" :visible.sync="dialogFormVisible">
      <el-form :model="ruleForm" :rules="rules" ref="ruleForm" label-position="right" @submit.native.prevent label-width="150px">
        <el-form-item label="原服务员:">
<!--          {{this.$store.state.userInfo.name}}-->
          {{authInfo.name}}
        </el-form-item>
        <el-form-item label="绑定服务员:" required prop="waiter">
          <el-select
              v-model="ruleForm.waiter"
              ref="waiter"
              @focus="handleFocus('waiter')"
              filterable
              remote
              reserve-keyword
              placeholder="输入工号或者姓名搜索"
              :remote-method="remoteMethod"
              :loading="loading">
            <el-option
                v-for="item in ruleForm.waiters"
                :key="item.id"
                :label="item.name"
                :value="item.id">
            </el-option>
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="hideChgDianDan">取 消</el-button>
        <el-button type="primary" @click="chgDiandan">确 定</el-button>
      </div>
    </el-dialog>

    <!-- 单品点单 -->
    <mealDrawer ref="mealDrawerRef" :showDrawer="drawer.showDrawer" :productInfo="currentProductInfo"
      @showOrHideDrawer="showOrHideDrawer" />
    <ImagePreview :dialogVisible="dialogVisible" :imgSrc="bigImageUrl" @handleCloseClick="handleCloseClick" />
    <el-dialog append-to-body title="提示" :visible="showChangeFwy"@close="closeChangeFwy">
      <h3>绑定当台服务员？</h3>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="closeChangeFwy">关闭</el-button>
        <el-button type="primary" @click="submitChangeFwy">确定</el-button>
      </div>
    </el-dialog>
    <el-dialog append-to-body title="绑定客人" :visible="showBindGuest" @close="closeChangeFwy">
      <el-form ref="formguest"  label-width="110px">
        <el-form-item label="客人手机号">
<!--          <el-input v-model="formguest.guest"></el-input>-->
          <el-select
              style="width: 90%"
              v-model="formguest.phone"
              ref="guest"
              @focus="handleFocus('guest')"
              @blur="handleBlur"
              filterable
              remote
              reserve-keyword
              placeholder="输入客人手机号后四位搜索"
              :remote-method="searchGuestPhone"
              :loading="loading">
            <el-option
                v-for="item in formguest.guests"
                :key="item.p"
                :label=" formguest.editing ? item.n + '  ' + item.p: item.n "
                :value="item.p">
            </el-option>
          </el-select>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="primary" @click="cancelBindGuest">关闭</el-button>
        <el-button type="primary" @click="submitBindGuest">{{ this.formguest.new_guest ? "注册并绑定" : "确定" }}</el-button>
      </div>
    </el-dialog>

  </div>
</template>

<script>
import common_book from "@/utils/common/book";
import api_order from "@/api/order";
import search from "@/assets/order-img/search-icon.png";
import mealDrawer from "@/components/order/newDrawerMeal";
import ImagePreview from "@/components/ImagePreview"
import common_order from "@/utils/common/order";
import { cloneDeep, iteratee } from "lodash-es";
import Observer, { BIND_EMP } from "@/observer";

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
      formguest:{
        editing: false,
        phone:"",
        guests:[],
        guestinfo: "",
        name: "",
        new_guest: false,
      },
      displayCustName: "",
      showChangeFwy: false, // 是否显示绑定服务员弹窗
      showBindGuest: false,
      isRect: true, // 是否为横屏
      ruleForm: {
        waiter: '',
        waiters:[],
      },
      rules: {
        waiter: [
          {required: true, message: '请输入卡台服务员', trigger: 'change'}
        ],
      },
      loading: false,
      dialogFormVisible: false,
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
      isMediumWidth: window.innerWidth < 1200,
      pic_show: false,
      openTime: "",
      empId: 0,
      showEmp: false,
      showGuest: false,
      currentInputValue: ''
    };
  },
  methods: {
    filterMethod(value) {
      // 这个方法允许保留用户输入的内容
      return true; // 返回 true 以保留输入内容
    },
    async submitBindGuest(){
      if (!this.formguest.phone) {
        this.$message.warning('请输入客人手机号');
        return;
      }
      this.showBindGuest = false
      try {
        const res = await api_order.set_csm_cust({
          cust_phone: this.formguest.phone,
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
        })
        if (res.code === 1) {
          this.$message.success('绑定成功');
          this.formguest.name = this.formguest.guests.find(ite => ite.p == this.formguest.phone) ? this.formguest.guests.find(ite => ite.p == this.formguest.phone).n : ""
          this.formguest.phone = this.formguest.guests.find(ite => ite.p == this.formguest.phone) ? this.formguest.guests.find(ite => ite.p == this.formguest.phone).p : this.formguest.phone
          this.displayCustName = this.formguest.name || this.maskedPhone || ""
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('绑定服务员失败', error)
        this.formguest.phone = ""
        this.formguest.name = ""
        this.displayCustName = ""
      }
      this.keyboardLeave('guest');
    },
    cancelBindGuest(){
      this.showBindGuest = false
      const businessData = this.$store.state.cardPageInfo.resResultDataObj.businessData || []
      let currentBusiness = businessData.find(ite => ite.seatId * 1 == this.$store.state.orderInfo.currentCardInfo.seatId * 1)
      console.log('-'.repeat(30), currentBusiness)
      this.formguest.phone = currentBusiness.csm_cust_phone
      this.formguest.name = currentBusiness.csm_cust_name || this.maskedPhone
      this.displayCustName = this.formguest.name || this.maskedPhone || ""
      this.keyboardLeave('guest');
    },
    handleBlur(){
      this.formguest.editing = false
    // 移除输入事件监听
    const inputEl = this.$refs.guest.$el.querySelector('input');
    inputEl.removeEventListener('input', this.handleInput);

    // 使用当前输入值更新 formguest.phone
    if (this.currentInputValue) {
      this.formguest.phone = this.currentInputValue;
    }

    // 重置 currentInputValue
    this.currentInputValue = '';
      // 保存当前输入的内容
      console.log(this.formguest)
    },
    handleInput(event){
      console.log('handleinput', event.target.value)
      const inputEl = event.target;
      let value = inputEl.value.replace(/\D/g, ''); // 只允许数字
      
      if (value.length > 11) {
        value = value.slice(0, 11); // 限制最大长度为11位
      }
      
      this.currentInputValue = value;
      inputEl.value = value; // 更新输入框的值


    },
    handleFocus(refString){
      if(refString === 'guest') {
        console.log('handleFocus....')
        this.$nextTick(() => {
          const inputEl = this.$refs.guest.$el.querySelector('input');
          inputEl.addEventListener('input', this.handleInput);
        });
        if (this.formguest.guests.findIndex(item => item.p === this.formguest.phone) < 0) {
          this.formguest.guests = []
        }
      }
      if (
        window.atool
        && window.atool.getTermType() == "android" &&
        ("showSoftInput" in window.atool)
      ) {
        setTimeout(() => {
          this.keyboardShow(refString)
        }, 100)
        const dropdown = document.querySelector('.el-select-dropdown');
        if (dropdown) {
          dropdown.style.transform = 'translateX(150px)';
        }
      }
    },
    keyboardShow(refString){
      if (
        window.atool
        && window.atool.getTermType() == "android" &&
            ("showSoftInput" in window.atool)
          ) {
            atool.showSoftInput();
            atool.executeJs(`this.$refs.${refString}.focus()`)
          }
    },
    keyboardLeave(refString) {
      setTimeout(() => {
        if (
          window.atool
          && window.atool.getTermType() == "android" &&
          ("hideSoftInput" in window.atool)
        ) {
          atool.executeJs(`this.$refs.${refString}.blur()`);
          atool.hideSoftInput();
          atool.restart();

        }
      }, 10)
    },
    showDiandanEmpChange() {
      console.log('showDiandanEmpChange')
      if (this.isValidCard && this.hasChgKTWaiterAuth()) {
        this.dialogFormVisible = true;
        this.remoteMethod();
        this.ruleForm.waiter = this.empId + ""
        setTimeout(() => {
          this.keyboardShow('waiter')
        }, 100)
      }
    },
    bindGuest(){
      console.log('bindGuest', this.empId)
      this.showBindGuest = true;
      this.formguest.guests = [{
        p: this.formguest.phone,
        n: this.formguest.name
      }]
    },
    hideChgDianDan() {
      this.dialogFormVisible = false;
      this.keyboardLeave('waiter');
    },
    showEmpDialog() {
      console.log('showEmpDialog', this.showEmp, this.empId)
      if (this.showEmp && !this.empId) {
        this.showChangeFwy = true;
      }
    },
    closeChangeFwy() {
      this.showChangeFwy = false;
    },
    async submitChangeFwy() {
      this.showChangeFwy = false;
      try {
        const res = await api_order.reqSetCsmWaiter({
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
        })
        if (res.code === 1) {
          this.empId = this.$store.state.userInfo.emp_id;
          this.getAuthInfo();
          this.$message.success('绑定成功');
          console.log(res.data, '绑定成功')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('绑定服务员失败', error)
      }
    },
    async chgDiandan() {
      this.$refs['ruleForm'].validate((valid) => {
        console.log(valid)
        if (valid) {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
            waiter_emp_id: this.ruleForm.waiter * 1
          };
          const res =  api_order.chg_csm_waiter_inord(params);
          res.then( r => {
            if (r.code === 1) {
              this.empId = this.ruleForm.waiter * 1
              this.getAuthInfo();
              Observer.send(BIND_EMP, this.empId);
              this.$message.success('修改卡台服务员成功');
              this.dialogFormVisible = false
              this.keyboardLeave('waiter');
            } else {
              this.$message.warning(r.msg);
            }
          })
        } else {
          console.log('error submit!!');
          return false;
        }
      });
    },
    remoteMethod(query) {
      this.loading = true;
      this.ruleForm.waiters = []
      const sealInfoArr = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo;
      const results = query ? sealInfoArr.filter(
              (el) =>
                  el.code.toString().includes(query) ||
                  el.name.toString().includes(query) ||
                  el.namePy.toString().includes(query.toLowerCase())
          )
          : sealInfoArr;
      console.log('waiters:', results)
      this.ruleForm.waiters = results;
      this.loading = false;
    },
    async searchGuestPhone(query){
      this.formguest.guests = []
      if(query.length > 11) {
        query = query.slice(0, 11)
      }
      if (query && (query.length === 4 || query.length === 11)) {
        try {
          const params = {
            cust_phone: query
          };
          const res = await api_order.get_cust_items_for_csm(params);
          if (res.code === 1) {
            this.formguest.editing = true
            if (res.data.records && res.data.records.length > 0) {
              this.formguest.guests = res.data.records
              this.formguest.new_guest = false
            } else if (query.length === 11){
              // this.formguest.guests = [{p: query, n:  query.slice(0, 3) + '****' + query.slice(7)}]
              this.formguest.new_guest = true
            }
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("get_cust_items_for_csm", error);
        }
      }
    },
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
        // 是否有修改卡台
    hasChgKTWaiterAuth () {
      return (
        this.$store.state.userInfo.sys_modules &&
        this.$store.state.userInfo.sys_modules.includes(9)
      );
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
        name: '',
      };
      const businessData = this.$store.state.cardPageInfo.resResultDataObj.businessData || []
      this.empId = this.empId || businessData.find(ite => ite.seatId * 1 == this.$store.state.orderInfo.currentCardInfo.seatId * 1).waiter_emp_id
      this.authInfo.name = this.$store.state.cardPageInfo.resResultDataObj.orderPersonInfo.filter(
          (item) => item.id == this.empId
      ).map((item) => item.name).join("");
      this.authInfo = { ...this.authInfo };
    },
    async getShoppingCartData() {
      try {
        const params = {
          id: this.$store.state.orderInfo.currentCardInfo.seatId * 1 // int64  卡台Id
        };
        const res = await api_order.reqGetShoppingList(params);
        if (res.code === 1) {
          this.shoppingCartList = res.data;
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
      console.log('width, height', width, height)
      this.isRect = width >= height
    },

    getPageData(page = 1) {
    
      this.page = page;
      if(this.mustOrderProducts && this.mustOrderProducts.length > 0) {
        this.productsListTotal = this.mustOrderProducts
        this.productsList = this.productsListTotal || []
        this.productsList = this.productsList.map(it => {
          const prdInfo = this.$store.state.cardPageInfo.resResultDataObj.goodsAroundInfo.find(
          item => it.id * 1 == item.id * 1 );
          if(prdInfo) {
            it = {...prdInfo, isMustPrd:true, canOrderMeal: true }
          }
          return it
        });
      } else {
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
      }


      if(this.redeem == 0) {
        this.productsList = this.productsList.filter((item, index) => {
          // 非抖音，美团，推广套餐
          return ![12,22,32].includes(item.prdType*1)
        })
      } else {
        this.productsList = this.productsList.filter((item, index) => {
          // 抖音，美团，推广套餐
          return [this.redeem].includes(item.prdType*1)
        })
      }
      console.log('redeem', this.redeem, this.productsList, this.currentCategoryProductList)


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

    
    // 服务员/收银加入购物车
    async orderMealToShoppingCart() {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //  int64  卡台Id
        prd_id: this.productInfo.id * 1, //  int64  商品Id
        prd_cnt: this.count * 1, //  int   商品数量
        prd_price: this.productInfo.price, //  string  商品单价,用于做二次验证
        prd_amt: this.productInfo.prdType == 5 ? this.amt.toString() : "", //    string  商品金额 普通商品不要传数据, 赔偿类商品 需传赔偿金额
        requirement: this.requestInfoArr.join(";"), // string  要求
      };
      if (this.productInfo.prdType == 2) {
        // 选择套餐
        this.$emit("changeType", 2);
        this.$emit("setSingleInfo", params);
      } else if (
        this.productInfo.prdType == 3 ||
        this.productInfo.prdType == 4 ||
        this.productInfo.prdType == 13 ||
        this.productInfo.prdType == 14 ||
        this.productInfo.prdType == 8
      ) {
        // 添加存货花篮特饮3/普通花篮特饮8、小费4  13:定价花篮  14：定价小费
        if (
          !this.amt &&
          this.productInfo.prdType != 13 &&
          this.productInfo.prdType != 14
        )
          return this.$message.warning("请输入金额");

        const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //  int64  卡台Id
          prd_id: this.productInfo.id * 1, // int64   商品Id
          prd_cnt: this.count * 1, //  int    商品数量 小费类商品只能=1
          prd_amt:
            this.productInfo.prdType == 13 || this.productInfo.prdType == 14
              ? ""
              : this.amt.toString(), //  string  商品金额 普通商品,定价花篮(13),定价小费(14)不要传金额(空)(系统会自动计算), 时价花篮(3)/时价小费(4) 需传金额
          requirement: this.requestInfoArr.join(";"), // string   要求
          relate_csm_id: 0, // int64  关联流水Id(用于补交),没有填0
        };

        try {
          const res = await api_order.reqAddAmtToShopping(params);
          if (res.code == 1) {
            this.$message.success("加入购物车成功");
            this.$store.dispatch("getShoppingCount", this);
            this.onCancelDrawer();
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("加入购物车授权失败", error);
        }
      } else {
        // 正常商品添加购物车
        try {
          const res = await api_order.reqAddProductToShopping(params);
          if (res.code === 1) {
            this.$message.success("加入购物车成功");
            this.$store.dispatch("getShoppingCount", this);
            this.onCancelDrawer();
          } else this.$message.warning(res.msg);
        } catch (error) {
          console.log("加入购物车失败", error);
        }
      }
    },

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

      if(this.redeem != 0) {
        console.log('product', productInfo)
        this.currentProductInfo = {...productInfo, type:2, requireInfo:[]};
        this.showOrHideDrawer(true);
      } else {
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
      }

    },

    showOrHideDrawer(value) {
      this.drawer.showDrawer = value;
      if (!value) {
        if(this.redeem == 0) {
          this.getShoppingCartData();
        } else {
          this.$emit("onRedeem");
        }
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
        let h = cardInfo.openTime.substring(8, 10); // 时
        let s = cardInfo.openTime.substring(10, 12); // 分
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
    checkOverflow() {
      const el = this.$el.querySelector('.author');
      console.log('checkoverflow', el.scrollWidth, el.clientWidth)
      
      let fontSize = 16
      while (164 < el.innerText.length * fontSize) {
        fontSize = fontSize * 0.9
        el.style.fontSize = fontSize + 'px';
      }
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
    console.log('mounted================')
    firstLoad = true;
    this.getShoppingCartData()
    this.getCenterType();
    this.getAuthInfo();
    this.isMoneyClient = sessionStorage.getItem("client") == "money"
    this.cardInfo = this.$store.state.orderInfo.currentCardInfo;
    const businessData = this.$store.state.cardPageInfo.resResultDataObj.businessData || []
    let currentBusiness = businessData.find(ite => ite.seatId * 1 == this.$store.state.orderInfo.currentCardInfo.seatId * 1)
    console.log('-'.repeat(30), currentBusiness)
    this.empId = currentBusiness.waiter_emp_id
    this.formguest.phone = currentBusiness.csm_cust_phone
    this.formguest.name = currentBusiness.csm_cust_name || this.maskedPhone
    this.displayCustName = this.formguest.name || this.maskedPhone || ""
    this.showEmp = [1,2].includes(businessData.find(ite => ite.seatId == this.cardInfo.id).seat_biz_type * 1)
    if (this.showEmp && this.empId * 1 == 0) {
      this.authInfo.name = '';
    }
    this.getOpenTime(); //开台时间
    this.adjustFontSize(); // 在组件加载后调整一次字体大小
    window.addEventListener('resize', this.adjustFontSize); // 在窗口大小改变时再次调整字体大小
    // this.$refs.productListRef.addEventListener("scroll", this.scrollHandle);
    this.checkOverflow();

    let seat_id =  this.$store.state.orderInfo.currentCardInfo.seatId

  },
  props: {
    allProductsList: {
      default: []
    },
    currentCategoryProductList: {
      default: []
    },
    redeem: {
      default: 0 // 12:抖音 ,22：美团,32：推广 
    },
    step :{
      default: 0 //step 3 线下核销， 1 扫码核销 ， 2输入券码核销
    },
    mustOrderProducts: {
      default: []
    }
  },
  computed: {
    maskedPhone() {
      if (this.formguest.phone && this.formguest.phone.length === 11) {
      // 只对11位中国手机号掩码
        return (
          this.formguest.phone.slice(0, 3) +
          '****' +
          this.formguest.phone.slice(7)
          );
      }
      return this.formguest.phone; // 如果手机号不符合条件，直接返回
    },
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
      return this.showEmp ? (this.empId * 1 != 0 ? '服务员' : '绑定当台服务员'): this.$route.path.startsWith("/orderMeal") ? "点单人" : "收银员";
    },
    isValidCard() {
      return this.$store.state.orderInfo.currentCardInfo.bizType == 1;
    }
  },
  components: {
    mealDrawer,
    ImagePreview
  },
  watch: {
    "formguest.phone"(newVal){
      console.log("formguest.phone changed")
      this.formguest.editing = false
      this.formguest = {...this.formguest}
    },
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