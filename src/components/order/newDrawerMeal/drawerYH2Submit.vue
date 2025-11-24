<template>
  <!-- 优惠2 -->
  <div>
    <el-drawer
      @click.native="blueHandle"
      append-to-body
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      :size="size"
    >
      <!-- 选择卡台及订位人 -->
      <div v-if="type==1">
        <div class="form">
          <el-form label-position="right" label-width="150px" :model="formData" @submit.native.prevent>
            <el-form-item label="订位人" class="required required3">
              <input-select
                style="width:50%"
                :value="formData.sales.sales_name"
                placeholder="请输入姓名或工号"
                :optionsList="formData.sales.sales_info_option"
                @selectInputHandle="inputSealName"
                @selectOptionItem="changeSealName"
                @selectBlurHandle="selectBlurHandle"
              ></input-select>
            </el-form-item>
            <el-form-item label="关联卡台" class="required required4">
              <span
                :style="{'margin-right':formData.choosedCardInfo.name?'10px':'0'}"
                style="color:rgba(255,255,255,.8)"
              >{{formData.choosedCardInfo.name}}</span>
              <el-button type="primary" @click.native="showOrHideChooseCardHandle">选择卡台</el-button>
            </el-form-item>
            <!-- 优惠理由 -->
            <el-form-item label="优惠理由">
              <ul class="reason-list" layout="row" layout-align="start center">
                <li :class="{'active': formData.reason == item.name}" v-for="item in reasonList" :key="item.id" @click="formData.reason = formData.reason == item.name ? '' : item.name">{{item.name}}</li>
              </ul>
            </el-form-item>
          </el-form>
          <fullPageTable
            titleText="选择卡台"
            ref="fullPageTableRef"
            @showOrHideFullPageHandle="showOrHideChooseCardHandle"
            @setChoosedCardInfo="setChoosedCardInfo"
            v-if="formData.showFullPage"
          />
        </div>
        <!-- 提交按钮 -->
        <div v-if="type==1" class="form-btn" layout="row" layout-align="center center">
          <el-button type="info" @click.stop="closeDrawerHandle">取消</el-button>
          <el-button type="primary" @click.stop="onSubmit">确认</el-button>
        </div>
      </div>

      <!-- 授权 -->
      <div v-else class="auth" layout="row" layout-align="center start">
        <div class="auth-left p-l-3 white">
          <div class="table">
            <div class="thead">
              <div class="tr" layout="row" layout-align="start start">
                <div class="th">序号</div>
                <div class="th">商品名称</div>
                <div class="th">数量</div>
              </div>
            </div>
            <div class="tbody">
              <div
                class="tr"
                v-for="(item,index) in selectedProList"
                :key="index"
                layout="row"
                layout-align="start start"
              >
                <div class="td">{{index+1}}</div>
                <div class="td">{{item.name || item.productInfo.name}}</div>
                <div class="td">{{item.pc}}</div>
              </div>
            </div>
          </div>
        </div>
        <div class="auth-right">
          <authorization
            ref="authorization"
            :type="1"
            :productInfo="selectedProList"
            :formData="formData"
            :showSelfBtn="showSelfBtn"
            @closeDrawerHandle="closeDrawerHandle"
            @showOrHideAnotherDrawer="$emit('showOrHideAnotherDrawer')"
            @batchYH2Success="$emit('batchYH2Success')"
          />
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_order from "@/api/order";
import eventVue from '@/utils/eventVue';
import authorization from "@/components/order/newShoppingCart/authorization";
import inputSelect from "@/components/book/inputSelect";
import fullPageTable from "@/components/book/machine/fullPageTable"; // 转台

export default {
  data() {
    return {
      show: false,
      type: 1, // 1:选择订位人相关信息  2：授权
      formData: {
        // 订位人信息
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
    selectBlurHandle() {
      this.formData.selectOption = [];
    },

    // 订位人相关

    // 获取模糊查询订位人的相关信息
    inputSealName(query) {
      this.formData.sales.sales_name = query;
      this.formData.sales.sales_phone = "";
      this.formData.sales.sales_emp_id = "";
      const sealInfoArr = this.$store.state.cardPageInfo.resResultDataObj
        .orderPersonInfo;
      const results = query
        ? sealInfoArr.filter(
            el =>
              el.code.toString().includes(query) ||
              el.name.toString().includes(query) ||
              el.namePy.toString().includes(query.toLowerCase())
          )
        : sealInfoArr;
      this.formData.sales.sales_info_option = results;
    },
    // 选择订位人的信息
    changeSealName(info) {
      this.formData.sales.sales_name = info.name;
      this.formData.sales.sales_phone = info.phoneNum;
      this.formData.sales.sales_emp_id = info.id;
      this.formData.sales.sales_info_option = [];
    },

    setChoosedCardInfo(info) {
      this.formData.choosedCardInfo = { ...info };
    },

    // 显示或隐藏选择卡台组件
    showOrHideChooseCardHandle() {
      this.formData.showFullPage = !this.formData.showFullPage;
    },

    onSubmit() {
      if (!this.formData.sales.sales_name)
        return this.$message.warning("请选择订位人");
      if (!this.formData.choosedCardInfo.id)
        return this.$message.warning("请选择卡台");

      if(this.$route.name == 'orderMealList') {
        // 点单（将优惠2商品添加到购物车）
        this.sealYH2ToShoppingCart()
      } else if(this.$route.name == 'shoppingCart' || this.$route.name == 'myOrder' || this.$route.name == 'payOrder') {
        // 购物车批量优惠
        this.changeType(2);
      }
    },

    // 菜单点单优惠2加入购物车
    async sealYH2ToShoppingCart(){
      const params = {
        auth_emp_code: '', // string   授权员工工号, 如果不传, 代表本账号授权
        auth_emp_passwd: '', // string   授权员工密码
        auth_reason: '', // string   授权理由
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64     卡台Id
        prd_id: this.selectedProList[0].id * 1, //     int64    商品Id
        prd_cnt: this.selectedProList[0].pc * 1, //    int      商品数量 小费类商品只能=1
        requirement: '', // string   要求
        pass_type: 1, //  int     1 验证 员工号/密码  2 验证卡号/卡数据 为兼容之前的账号密码认证, 当=2的时候验证卡号和卡密, 共用emp_code,password
        yh2_sales_emp_id: this.formData.sales.sales_emp_id * 1, // int64    优惠2订位人Id
        yh2_seat_id: this.formData.choosedCardInfo.id * 1, // int64    优惠2卡台Id
      }

      try {
        const res = await api_order.reqAddYh2ToShoppingCart(params)
        if (res.code == 1) {
          this.$message.success("加入购物车成功");
          this.$store.dispatch("getShoppingCount", this);
          this.closeDrawerHandle();
          this.$emit('showOrHideAnotherDrawer')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log('优惠2商品加入购物车失败', error)
      }
    },

    // 授权相关
    changeType(type = 1) {
      this.type = type;
    },
    closeDrawerHandle() {
      this.$emit("showOrHideDrawer");
    },

    blueHandle() {
      const singleDom = this.$children[0].$children[0];
      if (singleDom) this.$children[0].$children[0].focus = false;
    },

    
    // 刷卡授权
    swipingOrderHandle(empCardInfo){
      if(this.show && this.type == 2) {
        const childrenVNode = this.$children[0].$children || []
        childrenVNode.forEach(el => {
          if(el.$el.className == 'auth') {
            if(el.tabIndex == 1) {
              // 刷卡
              el.onSubmit('another', empCardInfo, 2)
            } else {
              this.$message.warning('当前为输入账号授权，不可刷卡')
            }
          }
        })
      } else {
        this.$message.warning('刷卡无效，请在登录或授权时进行刷卡！')
      }
    },
  },
  props: {
    status: {
      default: 1
    },
    personInfo: {
      default: () => {}
    },
    showDrawer: {
      default: false // 是否显示drawer
    },
    showSelfBtn: {
      default: false,
    },
    selectedProList: {
      default: () => []
    }
  },
  components: {
    authorization,
    inputSelect,
    fullPageTable
  },
  computed: {
    size() {
      return this.type == 1 ? "50%" : "88%";
    },
    title() {
      let title = "";
      switch (this.type * 1) {
        case 1:
          title = "优惠2";
          break;
        case 2:
          title = "授权";
          break;
      }
      return title;
    },
    
    reasonList(){ // 优惠理由
      return this.$store.state.cardPageInfo.resResultDataObj.reasonList.filter(item => item.status == 1 && item.type_id == 1)
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        eventVue.$off('payYH2OrderHandle')
        eventVue.$on('payYH2OrderHandle', empCardInfo => {
          this.swipingOrderHandle(empCardInfo)
        })
        this.formData = {
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
        this.type = this.status;
      } else {
        window.stopLoopReadCard()
      }
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/scrollBar.less";
@import "../../../style/order/orderMeal/drawerMeal/drawerMeal.less";
@import "../../../style/common/elementFormBtn.less";
</style>

<style lang="less" scoped>
  // 理由
  .reason-list{
    margin-top: 4px;
    flex-wrap: wrap;
    li{
      margin-right: 10px;
      margin-bottom: 6px;
      width: 160px;
      height: 30px;
      line-height: 30px;
      text-align: center;
      border-radius: 15px;
      border: 1px solid rgba(255, 255, 2255, .5);
      color: rgba(255, 255, 2255, .5);
      cursor: pointer;
      &.active{
        border-color: #09f ;
        color: #09f ;
      }
    }
  }
</style>