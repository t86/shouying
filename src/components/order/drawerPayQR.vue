<template>
  <!-- 付款二维码 -->
  <div class="pay-QR" v-if="show">
    <div class="contain">
      <div class="header">买单</div>
      <div class="content">
        <p class="label">
          <span>线下订单待支付金额:</span>
          <span class="amt" style="font-size: 28px">¥</span>
          <span class="amt">{{ orderInfoDetail.pay_amt }}</span>
        </p>
        <div class="qr" layout="column" layout-align="center center">
          <vue-qr ref="qrCode" :text="textValue" :size="240" :margin="8" />
        </div>
        <div class="tips">
          请客人使用{{ payType == 1 ? "支付宝" : "微信" }}扫描二维码进行付款
        </div>
      </div>
      <div class="footer" layout="row" layout-align="center center">
        <el-button type="info" @click="notPayHandle">暂不支付</el-button>
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
    };
  },
  methods: {
    init() {
      this.setQRCodeInfo();
      this.reloadMyOrderTableData();
    },

    // 生成二维码并设置询问状态
    setQRCodeInfo() {
      this.textValue = this.orderInfoDetail.pay_url;
      if (this.timer) clearInterval(this.timer);
      this.timer = setInterval(() => {
        this.getOrderPayStatus();
      }, 1000);
    },

    // 询问订单支付状态
    async getOrderPayStatus() {
      const params = {
        ol_pay_lock_id: this.orderInfoDetail.ol_pay_lock_id * 1, // int64   锁定订单Id
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
        ol_pay_lock_id: this.orderInfoDetail.ol_pay_lock_id * 1, // int64   锁定订单Id
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
        const result = await this.cancelPayOrder();
        this.reloadMyOrderTableData();
        this.onCancelDrawer();
        if (result == "success") {
          this.$emit("subSecondLogoutHandle");
        }
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
  components: {
    VueQr,
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) {
        this.init();
      } else {
        this.textValue = "";
        if (this.timer) clearInterval(this.timer);
      }
    },
  },

  beforeDestroy() {
    if (this.timer) clearInterval(this.timer);
  },
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/order/orderMeal/drawerPayQr.less";
</style>
