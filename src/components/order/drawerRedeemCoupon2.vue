<template>
  <div>
    <el-drawer
        title="扫码核销"
        :visible.sync="show"
        :before-close="onCancelDrawer"
        direction="rtl"
        append-to-body
        size="80%"
    >
    
      <div class="voucher-selection" style="margin: 20px" v-if="step === 0">
        <div class='info'>
          <div class="info-item">
            <div class="info-title">券码：</div>
            <el-input type="text" v-model="authCode" style="width: 300px; height: 30px"></el-input>
          </div>
        </div>
      </div>

      <div class="voucher-selection" v-if="step === 1">
        <div class='info'>
          <div class="info-item">
            <div class="info-title">券名称：</div>
            <div class="info-value">{{ csmInfo.title }}</div>
          </div>
          <div class="info-item ">
            <div class="info-title ">券类型：</div>
            <div class="info-value">{{ csmInfo.coupon_type }}</div>
          </div>
          <div class="info-item">
            <div class="info-title">原价：</div>
            <div class="info-value">￥{{ (csmInfo.coupon_amt / 1000).toFixed(2) || '' }}</div>
          </div>
          <div class="info-item">
            <div class="info-title">购买价：</div>
            <div class="info-value">￥{{ (csmInfo.coupon_pay_amt / 1000).toFixed(2) || '' }}</div>
          </div>
        </div>

        <table class="voucher-table" v-if="step === 1">
          <thead>
          <tr>
            <th></th>
            <th>套餐名称</th>
            <th>套餐价格</th>
            <th>不可用原因</th>
          </tr>
          </thead>
          <tbody>
          <tr
              v-for="(item, index) in prds"
              :key="index"
              :class="{ disabled: item.r }"
          >
            <td>
              <el-checkbox v-model="item.checked" :disabled="item.r.length > 0" @change="selectOption($event,index)">
              </el-checkbox>
            </td>
            <td>{{ item.n }}</td>
            <td>￥{{ (item.p / 100).toFixed(2) }}</td>
            <td>{{ item.r }}</td>
          </tr>
          </tbody>
        </table>


      </div>

      <div class="order-meal-list" v-if="Object.keys(productInfo).length > 0 && this.step === 2" >
        <groupProduct2
            ref="groupProduct2"
            :productInfo="productInfo"
            :singleInfo="singleInfo"
            :key="componentKey"
            :csm-info="csmInfo"
            @submitting="submitLoading"
            @closeDrawerHandle="onRedeemSuccess"
        />
      </div>

      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">取消</el-button>
        <!--        <el-button type="info" @click="doRedeem" :loading="subIsloading">核销卡券</el-button>-->
        <el-button type="info" v-if="step === 1 || step === 0" @click="proceedNext">下一步</el-button>
        <el-button type="info" v-if="step === 2" @click="doRedeem">核销卡券</el-button>
      </div>
    </el-drawer>
  </div>


</template>

<script>
import api_order from "@/api/order";

import mealNav from "@/components/order/orderMealNav.vue";
import productList from "@/components/order/productList.vue";
import navPrdList from '@/mixin/navPrdList'
import groupProduct2 from "@/components/order/newDrawerMeal/groupProduct2";
import keyBoard from "@/components/common/newKeyBoard.vue";

export default {
  data() {
    return {
      selectedPrdId: -1,
      prds: [],
      csmInfo: {
        order_id: 0,
        kq_order_id: "",
        title: "",
        coupon_amt: 0,
        coupon_pay_amt: 0,
        verify_token: "",
        pt_sku_id: 0,
        receipt_code: "",
        prd_type: 12,
        wkday_id: 0,
        csm_id: 0,
        coupon_type:''
      },

      componentKey: 0,
      step: 1,
      tabIndex: 22,
      tableData: [],
      checkAll: false,
      checkedList: [],
      allProductsList: [],
      currentCategoryProductList: [],
      custKqId: "",
      prdId: "",
      authCode: "",
      productInfo: {},
      singleInfo: {},
      scanCode: 0, // 0 等待扫码 1：扫码中 2：扫码成功 3：扫码失败
      subIsloading: false,
      clientType: 'order',

    };
  },
  methods: {
    getCode(){
      window.scan_callback({code: 0, data: this.authCode})
    },
    selectOption(value, index) {
      console.log(value, index)

      if (value) {
        let selected = this.prds[index];
        this.selectedPrdId = selected.id
        this.prds.forEach(item => {
          item.checked = item.id === selected.id;
        })
      } else {
        this.selectedPrdId = -1
        this.prds.forEach(item => {
          item.checked = false
        })
      }
      this.prds = [...this.prds]
    },
    proceedNext() {
      if(this.step === 0) {
        this.step = 1
        this.getCode();
        return
      }
      if (this.selectedPrdId > 0) {
        this.step = 2
        this.csmInfo.prd_id = this.selectedPrdId
        this.productInfo = this.$store.state.orderInfo.allProductsList.find(item => item.id === this.selectedPrdId.toString())
        console.log("query product=============:", this.productInfo)
        this.componentKey += 1
        this.singleInfo.prd_cnt = 1
      } else {
        this.$message.warning("请选择一个商品");
      }
    },
    submitLoading(value) {
      console.log('from child:', value)
      this.subIsloading = value
    },
    changeNumHandle(value) {
      switch (value) {
        case 11: // 清空
          this.authCode = "";
          break;
        case 10: // 回退(
          this.authCode =
              this.authCode
                  .toString()
                  .slice(0, this.authCode.toString().length - 1) * 1;
          break;
        default:
          this.authCode = this.authCode + value * 1;
          break;
      }
      this.$forceUpdate();
    },
    // 开始扫码
    startScan() {
      console.log('start scan....')
      if (window.atool && "startScan" in window.atool) {
        window.atool.startScan("scan_callback");
      }
    },

    onRedeemSuccess() {
      this.step = window.atool && ("startScan" in window.atool || window.atool.getTermType() == "android") ? 1 : 0

    },
    onCancelDrawer() {
      this.step = window.atool && ("startScan" in window.atool || window.atool.getTermType() == "android") ? 1 : 0
      this.show = false;
      this.authCode = ''

    },
    checkCode() {
      window.scan_callback({code: this.tabIndex, data: this.authCode})
    },

    doRedeem() {
      let gp = this.$refs.groupProduct2
      if (gp) {
        this.$refs.groupProduct2.onSubmit()
      }
    },
    updateProductsList({key, value}) {
      this[key] = value;
    },

    changeFirstCategory(firstCategoryId = "") {
    },
  },
  created() {
  },
  mounted() {
    this.step = window.atool && ("startScan" in window.atool || window.atool.getTermType() == "android") ? 1 : 0
    this.clientType = this.$store.state.client
    this.getMenuInfo(false);
    const that = this;

    async function scan_callback(value) {
      //todo hardcode
      // value.data = '336122540'
      let seat_id = that.$store.state.orderInfo.currentCardInfo.seatId * 1
      let params = {
        seat_id: seat_id,
        kq_auth_code: value.data
      }
      try {
        let res = await api_order.csm_coupon_preparev2(params)
        // const res = {
        //   "code": 1,
        //   "msg": "",
        //   "data": {
        //     "order_id": 389,
        //     "kq_order_id": "",
        //     "title": "【中心卡座无附加费】早场啤酒薅羊毛套餐",
        //     "coupon_amt": 1990,
        //     "coupon_pay_amt": 1990,
        //     "verify_token": "",
        //     "pt_sku_id": 1099976424,
        //     "receipt_code": "6909584274",
        //     "prd_type": 12,
        //     "wkday_id": 242082100418841,
        //     "csm_id": 242131306419786,
        //     "prds": [
        //       {
        //         "id": 240751037365436,
        //         "n": "美团套餐",
        //         "p": 2000,
        //         "r": ""
        //       },
        //       {
        //         "id": 240791006365816,
        //         "n": "美团开业套餐",
        //         "p": 900,
        //         "r": "套餐定价低于卡券支付金额"
        //       }
        //     ]
        //   }
        // }
        if (res.code === 1) {
          that.csmInfo.order_id = res.data.order_id
          that.csmInfo.kq_order_id = res.data.kq_order_id
          that.csmInfo.title = res.data.title
          that.csmInfo.coupon_amt = res.data.coupon_amt
          that.csmInfo.coupon_pay_amt = res.data.coupon_pay_amt
          that.csmInfo.verify_token = res.data.verify_token
          that.csmInfo.pt_sku_id = res.data.pt_sku_id
          that.csmInfo.receipt_code = res.data.receipt_code
          that.csmInfo.prd_type = res.data.prd_type
          that.csmInfo.wkday_id = res.data.wkday_id
          that.csmInfo.csm_id = res.data.csm_id
          that.csmInfo.use_cnt_per_csm = res.data.use_cnt_per_csm
          that.csmInfo.use_exclusive_mode = res.data.use_exclusive_mode
          let coupon_type = ''
          if(res.data.prd_type === 12) {
            coupon_type = '抖音券'
          } else if (res.data.prd_type === 22) {
            coupon_type = '美团券'
          } else if (res.data.prd_type === 32) {
            coupon_type = '推广券'
          }
          that.csmInfo.coupon_type = coupon_type
          that.prds = res.data.prds
          this.step = 1
        } else {
          console.log("券码识别失败：", res);
          that.$message.warning("券码识别失败：" + res.msg);
          this.step = window.atool && ("startScan" in window.atool || window.atool.getTermType() == "android") ? 1 : 0
        }
      } catch (error) {
        this.step = window.atool && ("startScan" in window.atool || window.atool.getTermType() == "android") ? 1 : 0
        console.log("券码识别失败：", error);
        that.$message.warning("券码识别失败：" + error);
      }
    }

    window.scan_callback = scan_callback;
  },
  props: {
    value: {
      default: false
    }
  },
  mixins: [navPrdList],
  computed: {
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      }
    },
    isIndeterminate() {
      return !this.checkAll && this.tableData.some(item => item.checked)
    },
  },
  watch: {
    value: {
      handler(newVal) {
        this.selectedPrdId = -1
        console.log('watch....val.', newVal)
        if (newVal) {
          this.startScan()

          //for test
          // window.scan_callback({code: 0, data: ''})
        }
      },
      immediate: true
    },
  },
  components: {
    mealNav,
    productList,
    groupProduct2,
    keyBoard
  }
};
</script>

<style scoped lang='less'>
@import "../../style/common/newElementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/newElementFormBtn.less";
@import "../../style/common/scrollBar.less";
@import "../../style/order/orderMeal/newDrawerShowOrderList.less";
</style>
<style scoped lang='less'>
.voucher-selection {
  width: 80%;
  margin: 0 auto;

  .info {
    .info-item {
      display: flex;
      padding: 10px;

      .info-title {
        line-height: 32px;
        width: 25%;
        height: 30px;
        font-size: 30px;
        font-weight: 600;
        //color: white;
      }

      .info-value {
        height: 40px;
        width: 70%;
        font-size: 30px;
        font-weight: 600;
        color: #6a9eff;
        line-height: 40px;
      }
    }
  }

  .voucher-header {
    margin-bottom: 20px;
  }

  .voucher-header p {
    margin: 0;
  }

  .voucher-table {
    margin-top: 30px;
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
    font-size: 30px;
  }

  .voucher-table th, .voucher-table td {
    border: 1px solid #ddd;
    padding: 8px;
    text-align: left;
  }

  .voucher-footer {
    text-align: right;
  }

  .voucher-footer button {
    margin-left: 10px;
  }

  .disabled {
    background-color: #f5f5f5;
    color: #b0b0b0;
  }

  //button {
  //  padding: 0 4px;
  //  min-width: 112px;
  //  height: 52px;
  //  border-radius: 8px;
  //  border: none;
  //  font-size: 20px;
  //  font-family: PingFangSC, PingFang SC;
  //  font-weight: 600;
  //  color: #FFFFFF;
  //  padding: 0;
  //
  //  &.el-button.el-button--info {
  //    width: 112px;
  //    background: #374368;
  //    box-shadow: inset 0px 1px 1px 0px rgba(255, 255, 255, 0.2);
  //  }
  //
  //  &.el-button.el-button--primary {
  //    background: #3373E8;
  //    box-shadow: none;
  //  }
  //}
}

.session {
  color: rgba(255, 255, 255, 0.8);
}

.redeem-container {
  .nav {
    padding: 20px 20px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.2);
    gap: 10px;

    div {
      width: 100px;
      height: 100px;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      cursor: pointer;
      background-color: #cccccc;
      border: 1px solid rgba(0, 0, 255, 0.1);

      &:active {
        background-color: rgba(255, 255, 255, 0.3) !important;
        border: 1px solid rgba(0, 0, 255, 0.1);
      }
    }
  }

  .on-focus {
    background-color: rgba(0, 0, 255, 0.1) !important;
    border: 1px solid rgba(0, 0, 255, 0.5) !important;
  }
}

.redeem-sel {
  padding: 20px 20px;
  gap: 20px;

  div {
    width: 100px;
    height: 100px;
    display: flex;
    padding: 10px;
    gap: 5px;
    align-items: center;
    justify-content: center;
    text-align: center;
    cursor: pointer;
    background-color: #cccccc;
    border: 1px solid #cccccc;

    &:active {
      background-color: rgba(255, 255, 255, 0.3) !important;
      border: 1px solid rgba(0, 0, 255, 0.5);
    }
  }
}

/deep/ input {
  height: 36px;
  padding: 0 40px 0 12px;
  box-sizing: border-box;
  background: #FFFFFF;
  color: black;
  border-radius: 22px;
  border: 1px solid #C4CBD7;
}

/deep/ .el-checkbox__inner {
  width: 20px;
  height: 20px;

  border: 1px solid #1A1A21;
}

/deep/ .el-checkbox__inner::after {
  width: 5px;
  height: 9px;
  left: 6px;
  top: 3px;
}

/deep/ .el-checkbox__label {
  font-size: 24px;
  font-family: PingFangSC, PingFang SC;
  font-weight: 400;
  color: #08080A;
}

/deep/ .el-checkbox__input.is-checked .el-checkbox__inner {
  border: none;
}
</style>
