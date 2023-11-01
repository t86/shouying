<template>
  <el-form
    label-position="right"
    @submit.native.prevent
    style="margin-top: 30px"
  >
    <!-- 数量 -->
    <el-form-item :class="{ 'm-b-2': orderMealStatus == 2 }">
      <input
        ref="inputCount"
        v-if="$store.state.userInfo.authStatus == 4"
        class="count"
        :class="{ focus: focus == 1 }"
        @click.stop="focusHandle(1)"
        placeholder="请输入商品数量"
        v-model="count"
      />
      <div
        v-else
        class="count"
        :class="{ focus: focus == 1, text: !count }"
        @click.stop="focusHandle(1)"
      >
        {{ count == "" ? "请输入商品数量" : count }}
      </div>
    </el-form-item>

    <!-- 金额 -->
    <div
      v-if="
        !isGQ &&
        (productInfo.prdType == 3 ||
          productInfo.prdType == 4 ||
          productInfo.prdType == 5 ||
          productInfo.prdType == 8)
      "
    >
      <el-form-item :class="{ 'm-b-2': orderMealStatus == 2 }">
        <input
          v-if="$store.state.userInfo.authStatus == 4"
          class="count"
          :class="{ focus: focus == 2 }"
          @click.stop="focusHandle(2)"
          placeholder="输入数量总金额"
          v-model="amt"
        />
        <div
          v-else
          class="count"
          :class="{ focus: focus == 2, text: !amt }"
          @click.stop="focusHandle(2)"
        >
          {{ amt == "" ? "输入数量总金额" : amt }}
        </div>
      </el-form-item>
    </div>

    <!-- 优惠理由 -->
    <el-form-item
      :class="{ 'm-b-2': orderMealStatus == 2 }"
      v-if="!isGQ && orderMealStatus == 2"
    >
      <p>请选择优惠理由：</p>
      <ul class="reason-list" layout="row" layout-align="start center">
        <li
          :class="{ active: formData.selectedInfo.name == item.name }"
          v-for="item in reasonList"
          :key="item.id"
          @click="formData.selectedInfo = item"
        >
          {{ item.name }}
        </li>
      </ul>
    </el-form-item>

    <!-- 定制要求 -->
    <div
      v-if="
        !isGQ &&
        !(
          productInfo.prdType == 2 ||
          productInfo.prdType == 3 ||
          productInfo.prdType == 4 ||
          productInfo.prdType == 5 ||
          productInfo.prdType == 8
        )
      "
    >
      <el-form-item
        v-if="productInfo.requireInfo.length > 0"
        :class="{ 'm-b-2': orderMealStatus == 2 }"
      >
        <div
          class="require-change one-txt-cut"
          :class="{ text: requireText != '定制要求' }"
          @click="showOrHideRequireDrawer"
        >
          {{ requireText }}
        </div>
      </el-form-item>
    </div>

    <!-- 键盘 -->
    <el-form-item>
      <keyBoard @changeNum="changeNum" />
    </el-form-item>

    <!-- 提交按钮 -->
    <div class="form-btn" layout="row" layout-align="center center">
      <el-button type="info" @click.stop="onCancelDrawer">取消</el-button>
      <el-button type="primary" @click.stop="onSubmit">确认</el-button>
    </div>

    <!-- 提交优惠2 -->
    <drawerYH2Submit
      ref="drawerYH2Submit"
      :showDrawer="showYH2Drawer"
      :selectedProList="[{ ...productInfo, pc: count }]"
      @showOrHideDrawer="showOrHideYH2Drawer"
      @showOrHideAnotherDrawer="onCancelDrawer"
    />

    <!-- 定制化口味等要求 -->
    <drawerChooseRequireInfo
      :showDrawer="requireDrawerInfo.showDrawer"
      :productInfo="productInfo"
      :requestInfoArr="requestInfoArr"
      @updateRequireInfoArr="updateRequireInfoArr"
      @showOrHideDrawer="showOrHideRequireDrawer"
    />

    <!-- 补交 -->
    <drawerBj
      v-model="showBJDrawer"
      :productInfo="productInfo"
      :count="count"
      :amt="amt"
      :requestInfoArr="requestInfoArr"
      @onCancelDrawer="onCancelDrawer"
    />

    <div class="modal" v-if="showModal">
      <div class="modal-content">
        <p class="m-b-2">请选择当前商品的下单途径</p>

        <div v-if="productInfo.canOrderMeal">
          <el-radio class="m-t-3 m-l-3" v-model="modalRadio" label="1"
            >点单下单</el-radio
          >
        </div>
        <div v-if="productInfo.canSeal">
          <el-radio class="m-t-3 m-l-3" v-model="modalRadio" label="2"
            >优惠下单</el-radio
          >
        </div>
        <div v-if="productInfo.canHL">
          <el-radio class="m-t-3 m-l-3" v-model="modalRadio" label="3"
            >特饮/小费下单</el-radio
          >
        </div>
        <div v-if="productInfo.canSealYH2">
          <el-radio class="m-t-3 m-l-3" v-model="modalRadio" label="5"
            >优惠2下单</el-radio
          >
        </div>

        <div class="btn m-t-6" style="text-align: center">
          <el-button
            type="info"
            size="mini"
            class="m-r-4"
            style="background: #374368; border-color: #374368"
            @click.stop="onCancelDrawer"
            >取消</el-button
          >
          <el-button type="primary" size="mini" @click.stop="modalSubmitHandle"
            >确认</el-button
          >
        </div>
      </div>
    </div>
  </el-form>
</template>

<script>
import api_order from "@/api/order";
import common_order from "@/utils/common/order";

import keyBoard from "@/components/common/keyBoard";
import drawerChooseRequireInfo from "@/components/order/drawerMeal/drawerChooseRequireInfo";
import drawerYH2Submit from "@/components/order/drawerMeal/drawerYH2Submit.vue";
// 补交
import drawerBj from "@/components/order/drawerMeal/drawerBj/index.vue";
export default {
  data() {
    return {
      modalRadio: "", // 1：服务员点单  2：优惠  3：花篮
      showModal: false,
      isGQ: false, // 是否是估清模态框
      focus: 1,
      count: "", // 数量
      amt: "", // 金额
      authType: "2", // 赠送类型
      authTypeList: [], // 当前商品对应的二级分类authType集合
      requestInfoArr: [], // 选择好的要求列表
      formData: {
        // 赠送理由
        selectedInfo: {},
      },

      requireDrawerInfo: {
        showDrawer: false,
      },

      showYH2Drawer: false,

      // 补交
      showBJDrawer: false,
    };
  },
  methods: {
    init() {
      this.getAuthTypeList();
      // 小费类型4商品数量默认为1 赔偿商品数量只能为 1  切不可修改
      if (this.productInfo.prdType == 4) {
        this.count = this.$route.name != "moneyCard"&&this.$route.name != "orderCard"  ? "" : 0;
      }
      this.isGQ = this.$route.name == "moneyCard" ||  this.$route.name == 'orderCard';
    },

    onCancelDrawer() {
      this.count = this.$route.name != "moneyCard"&&this.$route.name != "orderCard" ? "" : 0;
      this.requestInfoArr = [];
      this.$emit("closeDrawerHandle");
    },

    focusHandle(value = 1) {
      // if (value == 1 && this.productInfo.prdType == 4)
      //   return this.$message.warning("小费类型商品数量不可修改");
      this.focus = value;
    },

    getAuthTypeList() {
      const { twoCateId } = this.productInfo;
      this.authTypeList = common_order.getAuthTypeList(twoCateId);
    },

    blueHandle() {
      this.focus = 0;
    },

    changeNum(value) {
      if (!this.focus) return;
      switch (value) {
        case 10: // 清空
          this.focus == 1 ? (this.count = "") : (this.amt = "");
          break;
        case 12: // 回退
          this.focus == 1
            ? (this.count = this.count
                .toString()
                .slice(0, this.count.toString().length - 1))
            : (this.amt =
                this.amt.toString().slice(0, this.amt.toString().length - 1) *
                1);
          break;
        default:
          this.focus == 1
            ? (this.count = (this.count.toString() + value) * 1)
            : (this.amt = (this.amt.toString() + value) * 1);
          break;
      }
    },

    updateRequireInfoArr(requestList) {
      this.requestInfoArr = requestList;
    },

    resetSingleForm() {
      this.focus = 1;
      this.amt = "";
      this.count = this.$route.name != "moneyCard"&&this.$route.name != "orderCard" ? "" : 0;
      this.requestInfoArr = [];

      this.authType = "2"; // 赠送类型
      this.formData = {
        // 赠送理由
        selectedInfo: {},
      };

      if (
        this.productInfo.prdType == 3 ||
        this.productInfo.prdType == 4 ||
        this.productInfo.prdType == 13 ||
        this.productInfo.prdType == 14 ||
        this.productInfo.prdType == 5 ||
        this.productInfo.prdType == 8
      )
        // 3 存货花篮特饮 4 小费 5 赔偿 8 普通花篮/特饮(不关联erp)
        return this.init();
    },

    async onSubmit() {
      if (
        this.count.toString().indexOf(".") > -1 &&
        this.count.toString().indexOf(".") < this.count.toString().length - 1
      )
        return this.$message.warning("商品数量必须为整数");
      if (this.$route.name != "moneyCard"&&this.$route.name != "orderCard" && !this.count)
        return this.$message.warning("请输入商品数量！");
      if (isNaN(this.count * 1)) return this.$message.warning("请输入数字！");

      // 判断是否为估清
      if (this.$route.name == "moneyCard" || this.$route.name == 'orderCard') {
        const params = {
          prd_id: this.productInfo.id * 1, //     int64    商品Id
          cnt: this.count * 1, //   int  数量
        };
        try {
          const res = await api_order.reqAddGQOrder(params);
          if (res.code == 1) {
            this.$message.success("添加估清商品成功");
            this.$emit("getGQPrdList");
            this.onCancelDrawer();
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("添加估清商品失败", error);
        }
        return false;
      }

      // 判断点单数量是否超过了估清数量
      if (
        this.productInfo.outSomethingCount != "many" &&
        this.count * 1 > this.productInfo.outSomethingCount
      )
        return this.$message.warning(
          `商品数量超过了可点最大数量${this.productInfo.outSomethingCount}`
        );

      // 判断点单数量是否超过估清数量
      const outOfSomethingPrdList =
        this.$store.state.cardPageInfo.resResultDataObj.prdOutOfSomething;
      const isOutOfSomethingPrd = outOfSomethingPrdList.find(
        (item) => item.id == this.productInfo.id
      );
      if (
        isOutOfSomethingPrd &&
        isOutOfSomethingPrd.cnt < this.count * 1 &&
        isOutOfSomethingPrd.status == 1
      ) {
        // 当前商品是估清商品,且点单数量超过了估清数量
        return this.$message.warning(
          "点单数量已超过当前可点估清数量" + isOutOfSomethingPrd.cnt
        );
      }

      // 判断是否为补交台
      if (
        this.$store.state.orderInfo.currentCardInfo.bizType == 3 &&
        this.productInfo.prdType != 2
      ) {
        return (this.showBJDrawer = true);
      }

      // 优惠2
      if (this.$route.query.give && this.productInfo.prdType != 2) {
        // 判断是否为优惠2点单
        // 非套餐
        const resultProductInfo = {
          ...this.productInfo,
          pc: this.count * 1,
          amt: this.amt * 1,
          require: this.requestInfoArr.join(";"),
        };

        this.$emit("getYh2ProInfo", resultProductInfo);
        return;
      }

      // 收银下单
      if (this.$store.state.userInfo.authStatus == 4) {
        return this.orderMealToShoppingCart();
      }

      // 服务员可点商品加入购物车
      if (this.orderMealStatus == 1) {
        return this.orderMealToShoppingCart();
      }

      // 营销/花篮加入购物车
      if (this.orderMealStatus == 2 || this.orderMealStatus == 3) {
        return this.sealToShoppingCart();
      }

      // 优惠2加入购物车
      if (this.orderMealStatus == 5) {
        return this.showOrHideYH2Drawer();
      }
      this.$message.warning('商品状态异常，不能加入购物车, ', this.orderMealStatus)
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

    // 营销/花篮赠送
    async sealToShoppingCart() {
      if (!this.formData.selectedInfo.name && this.orderMealStatus == 2)
        return this.$message.warning("请选择优惠理由");
      else if (
        this.orderMealStatus == 3 &&
        this.amt === "" &&
        this.productInfo.prdType != 13 &&
        this.productInfo.prdType != 14
      )
        return this.$message.warning("请输入金额");

      try {
        const params = {
          auth_emp_code: "", // string  授权员工工号, 如果不传, 代表本账号授权
          auth_emp_passwd: "", // string  授权员工密码
          auth_reason: this.formData.selectedInfo.name, // string   授权理由
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    卡台Id
          prd_id: this.productInfo.id * 1, // int64   商品Id
          prd_cnt: this.count * 1, //  int    商品数量 小费类商品只能=1
          prd_amt: this.amt.toString(), //  string  商品金额 普通商品不要传数据(系统会自动计算), 花篮/小费 需传金额
          requirement: this.requestInfoArr.join(";"), // string  要求
          pass_type: 1, // 1:账号密码， 2：刷卡
          ...(this.orderMealStatus != 2 && { relate_csm_id: 0 }), // int64  关联流水Id(用于补交),没有填0
        };
        const res =
          this.orderMealStatus == 2
            ? await api_order.reqAddYhToShopping(params)
            : await api_order.reqAddAmtToShopping(params);
        if (res.code == 1) {
          this.$message.success("加入购物车成功");
          this.$store.dispatch("getShoppingCount", this);
          this.onCancelDrawer();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("营销账号赠送失败", error);
      }
    },

    // 获取当前商品的可点状态  1：服务员可下单  2：营销可下单  3：花篮可下单  5:优惠2下单
    getOrderMealStatus() {
      const status = [];
      if (this.productInfo.canOrderMeal) {
        status.push(1);
      }
      // prd_type=1的普通单品 才可以优惠
      if (this.productInfo.canSeal && this.productInfo.prdType == 1) {
        status.push(2);
      }
      if (this.productInfo.canHL) {
        status.push(3);
      }
      if (this.productInfo.canSealYH2) {
        status.push(5);
      }
      // 这是认为只配置了特饮,设置花篮
      if(status.length == 0) {
        status.push(3);
      }
      return status;
    },

    modalSubmitHandle() {
      if (!this.modalRadio) return this.$message.warning("请选择");
      this.$emit("updateOrderMealStatus", this.modalRadio * 1);
      this.showModal = false;
      this.$nextTick(() => {
        this.focusHandle(1);
        this.$refs.inputCount && this.$refs.inputCount.focus();
      });
    },

    showOrHideRequireDrawer() {
      this.requireDrawerInfo.showDrawer = !this.requireDrawerInfo.showDrawer;
    },

    showOrHideYH2Drawer() {
      this.showYH2Drawer = !this.showYH2Drawer;
    },
  },

  mounted() {
    this.init();
  },

  computed: {
    requireText() {
      return this.requestInfoArr.length > 0
        ? this.requestInfoArr.join(";")
        : "定制要求";
    },

    reasonList() {
      // 优惠1、退单2理由
      return this.$store.state.cardPageInfo.resResultDataObj.reasonList.filter(
        (item) => item.status == 1 && item.type_id == 1
      );
    },
  },

  components: {
    keyBoard,
    drawerChooseRequireInfo,
    drawerYH2Submit,
    drawerBj, // 补交
  },
  props: {
    show: {
      default: false,
    },
    // productInfo.prdType 1存货(关联erp) 7普通(不关联erp) 2套餐 3 时价特饮(关联erp) 4 小费 5 赔偿 6 联营,13 定价特饮 14 定价小费
    productInfo: {
      default: () => {},
    },
    orderMealStatus: {
      default: 1,
    },
  },
  watch: {
    show: {
      handler(newVal) {
        this.$nextTick(() => {
          if (newVal) {
            if (this.$store.state.userInfo.authStatus != 4 && !this.isGQ) {
              setTimeout(() => {
                const resultOrderMealStatusArr = this.getOrderMealStatus();
                this.showModal = resultOrderMealStatusArr.length > 1;
                if (!this.showModal)
                  this.$emit(
                    "updateOrderMealStatus",
                    resultOrderMealStatusArr[0] * 1
                  );
              }, 300);
            }
          } else {
            this.showModal = false;
          }
          if (newVal && this.$refs.inputCount) this.$refs.inputCount.focus();
        });
      },
      immediate: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../../style/order/orderMeal/drawerMeal/singleProduct.less";
@import "../../../style/common/elementFormBtn.less";
</style>

<style scoped lang="less">
.require-change {
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 8px;
  padding: 0 10px;
  cursor: pointer;
  color: rgba(255, 255, 255, 0.3);
  &.text {
    color: rgba(255, 255, 255, 0.8);
  }
}
</style>
