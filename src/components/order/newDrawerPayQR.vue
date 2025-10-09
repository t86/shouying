<template>
  <div>
    <!-- 付款二维码 -->
    <div class="pay-QR" v-if="show" v-show="show">
      <div class="contain">
        <div class="header">买单</div>
        <div class="content" v-if="[1, 2, 3].includes(payType * 1)">
          <p class="label">
            <span class="label-title">线下订单待支付金额:</span>
            <span class="amt">¥{{ (orderInfoDetail.pay_amt / 100).toFixed(2) }}</span>
          </p>
          <div class="qr" layout="column" layout-align="center center">
            <vue-qr ref="qrCode" :text="textValue" :size="240" :margin="8" />
          </div>
          <div class="tips">
            请客人使用{{ payType == 1 ? "支付宝" : "微信" }}扫描二维码进行付款
          </div>
        </div>
        <div class="wait_content" v-if="[5, 6].includes(payType * 1)">
          <div v-if="this.orderInfoDetail.r == 0">
            <img
              class="loading"
              :src="require('@/assets/order-img/loading.png')"
            />
            <div class="wait_tip">等待支付结果…</div>
          </div>
          <div class="fail" v-if="this.orderInfoDetail.r == 2">
            <i class="el-icon-warning" />
            <div class="tip">支付失败</div>
          </div>
        </div>
        <div class="footer" layout="row" layout-align="center center">
          <div v-if="this.orderInfoDetail.r == 2">
            <el-button type="info" @click="onCancelDrawer">关闭</el-button>
            <el-button type="info" @click="reloadQrRequest">重新扫码</el-button>
          </div>
          <el-button v-else type="info" @click="notPayHandle">暂不支付</el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import eventVue from "@/utils/eventVue";

import api_order from "@/api/order";
import VueQr from "vue-qr";

export default {
  data() {
    return {
      show: false,
      textValue: "",
      timer: "",
      startTimer: 15*60,
    };
  },
  methods: {
    init() {
      console.log("二维码弹窗 init 方法被调用");
      console.log("orderInfoDetail.r:", this.orderInfoDetail.r);
      console.log("orderInfoDetail:", this.orderInfoDetail);
      
      if (this.orderInfoDetail.r !== 2) {
        console.log("开始设置二维码信息");
        this.setQRCodeInfo();
      } else {
        console.log("订单状态为失败，不设置二维码");
      }
      this.reloadMyOrderTableData();
    },

    // 生成二维码并设置询问状态
    setQRCodeInfo() {
      console.log("setQRCodeInfo 被调用");
      console.log("pay_url:", this.orderInfoDetail.pay_url);
      
      this.textValue = this.orderInfoDetail.pay_url;
      console.log("设置 textValue:", this.textValue);
      
      if (this.timer) clearInterval(this.timer);
      this.startTimer = 15*60;
      this.timer = setInterval(() => {
        if(this.startTimer <= 0) {
          clearInterval(this.timer);
          this.onCancelDrawer();
          this.reloadMyOrderTableData();
          this.$emit("subSecondLogoutHandle");
          return;
        }
        this.startTimer--;
        this.getOrderPayStatus();
      }, 1000);
    },

    // 询问订单支付状态
    async getOrderPayStatus() {
      const params = {
        ol_pay_id: this.orderInfoDetail.ol_pay_id * 1, // int64   锁定订单Id
      };

      try {
        const res = await api_order.reqGetOrderOnlinePayStatus(params);
        if (res.code == 1) {
          if (res.data.status == 5) {
            this.$message.success("支付成功");
            this.onCancelDrawer();
            this.reloadMyOrderTableData();
            this.$emit("subSecondLogoutHandle");
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("询问订单支付状态失败", error);
      }
    },

    reloadMyOrderTableData() {
      if (this.$route.name == "myOrder") {
        eventVue.$emit("reloadMyOrderTableData");
      }
    },

    // 解除支付订单锁定
    async cancelPayOrder() {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64   卡台Id
        ol_pay_id: this.orderInfoDetail.ol_pay_id * 1, // int64   锁定订单Id
      };

      try {
        const res = await api_order.reqCancelPayOrder(params);
        if (res.code == 1) {
          if (this.timer) clearInterval(this.timer);
          return "success";
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("暂不支付失败", error);
      }
    },

    // 暂不支付
    async notPayHandle() {
      const res = await this.showConfirmHandle(
        "确认",
        "点击暂不支付后，如果客人已经成功付款，则该金额将进入到滞留金列表，是否确认暂不支付？"
      );
      if (res == "confirm") {
        // const result = await this.cancelPayOrder();
        this.reloadMyOrderTableData();
        this.onCancelDrawer();
        // if (result == "success") {
          this.$emit("subSecondLogoutHandle");
        // }
      }
    },

    // 操作确认框
    async showConfirmHandle(title = "", content = "") {
      return this.$confirm(content, title, {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消",
      })
        .then((res) => {
          return res;
        })
        .catch((e) => "");
    },
    onCancelDrawer() {
      this.$emit("showOrHideQRDrawerHandle");
    },
    reloadQrRequest() {
      this.$emit("showOrHideQRDrawerHandle");
      this.$emit("reloadQrRequest", 1);
    },
  },
  props: {
    showDrawer: {
      default: false,
    },
    orderInfoDetail: {
      default: {},
    },
    payType: {
      default: 1,
    },
  },
  created() {
    console.log("=== newDrawerPayQR 组件创建 ===");
    console.log("初始 showDrawer:", this.showDrawer);
    console.log("初始 payType:", this.payType);
    console.log("初始 orderInfoDetail:", this.orderInfoDetail);
  },
  mounted() {
    console.log("=== newDrawerPayQR 组件挂载 ===");
    console.log("挂载时 showDrawer:", this.showDrawer);
    console.log("挂载时 payType:", this.payType);
    console.log("挂载时 orderInfoDetail:", this.orderInfoDetail);
  },
  components: {
    VueQr,
  },
  watch: {
    showDrawer(newVal) {
      console.log("=== 二维码弹窗 showDrawer 变化 ===");
      console.log("showDrawer 变化:", newVal);
      console.log("当前 payType:", this.payType, "类型:", typeof this.payType);
      console.log("当前 orderInfoDetail:", JSON.stringify(this.orderInfoDetail));
      
      this.show = newVal;
      console.log("设置 show 为:", this.show);
      
      this.$nextTick(() => {
        console.log("nextTick 中 show 状态:", this.show);
        console.log("DOM 元素是否存在:", document.querySelector('.pay-QR'));
      });
      
      if (newVal) {
        console.log("开始初始化二维码弹窗");
        this.init();
      } else {
        console.log("关闭二维码弹窗");
        this.textValue = "";
        if (this.timer) clearInterval(this.timer);
      }
    },
    payType: {
      handler(newVal) {
        console.log("=== payType 变化 ===", newVal, "类型:", typeof newVal);
      },
      immediate: true,
    },
    orderInfoDetail: {
      handler(newVal) {
        console.log("=== orderInfoDetail 变化 ===", JSON.stringify(newVal));
      },
      immediate: true,
      deep: true,
    },
  },

  beforeDestroy() {
    if (this.timer) clearInterval(this.timer);
  },
};
</script>

<style scoped lang="less">
@import "../../style/common/newElementDrawer.less";
@import "../../style/order/orderMeal/newDrawerPayQr.less";
</style>
