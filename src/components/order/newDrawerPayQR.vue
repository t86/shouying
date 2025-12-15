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
          <el-button 
            v-else 
            type="info" 
            @click="notPayHandle"
            style="pointer-events: auto; z-index: 999;"
          >
            暂不支付
          </el-button>
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
      // 创建本地数据快照，避免父组件修改影响支付流程
      localOrderInfo: null,
    };
  },
  methods: {
    init() {
      console.log("二维码弹窗 init 方法被调用");
      console.log("orderInfoDetail.r:", this.orderInfoDetail.r);
      console.log("orderInfoDetail:", this.orderInfoDetail);
      console.log("payType:", this.payType, "类型:", typeof this.payType);
      
      // 创建数据快照，防止父组件修改影响支付流程
      this.localOrderInfo = {
        pay_url: this.orderInfoDetail.pay_url,
        ol_pay_id: this.orderInfoDetail.ol_pay_id,
        pay_amt: this.orderInfoDetail.pay_amt,
        r: this.orderInfoDetail.r
      };
      console.log("创建本地数据快照:", this.localOrderInfo);
      
      // 判断是否为扫客人码场景（payType 5 或 6）
      const payTypeNum = this.payType * 1;
      const isScanCustomerPayment = [5, 6].includes(payTypeNum);
      console.log("是否为扫客人码场景:", isScanCustomerPayment, "payTypeNum:", payTypeNum);
      
      if (this.localOrderInfo.r !== 2) {
        // 扫客人码场景（payType 5 或 6）不需要 pay_url，只需要 ol_pay_id 来轮询支付状态
        // 扫客人码场景下，r 应该是 0（支付中），需要显示"等待支付结果"页面并开始轮询
        if (isScanCustomerPayment) {
          console.log("扫客人码场景，开始轮询支付状态");
          // 确保 r 为 0（支付中），以便显示"等待支付结果"页面
          if (this.localOrderInfo.r !== 0 && this.localOrderInfo.r !== 1) {
            this.localOrderInfo.r = 0;
            this.orderInfoDetail.r = 0;
          }
          this.startPaymentStatusPolling();
        } else {
          console.log("客人扫我场景，开始设置二维码信息");
          this.setQRCodeInfo();
        }
      } else {
        console.log("订单状态为失败（r=2），不设置二维码");
      }
      this.reloadMyOrderTableData();
    },

    // 生成二维码并设置询问状态（仅用于"客人扫我"场景，payType 1/2/3）
    setQRCodeInfo() {
      console.log("setQRCodeInfo 被调用");
      console.log("localOrderInfo:", this.localOrderInfo);
      console.log("pay_url:", this.localOrderInfo && this.localOrderInfo.pay_url);
      console.log("ol_pay_id:", this.localOrderInfo && this.localOrderInfo.ol_pay_id);
      console.log("payType:", this.payType, "类型:", typeof this.payType);
      
      // 校验必要参数
      if (!this.localOrderInfo) {
        console.error("localOrderInfo 为空，无法设置二维码");
        this.onCancelDrawer();
        return;
      }
      
      // 再次确认不是扫客人码场景（防止误入）
      const payTypeNum = this.payType * 1;
      if ([5, 6].includes(payTypeNum)) {
        console.warn("警告：扫客人码场景不应该走到 setQRCodeInfo，应该直接调用 startPaymentStatusPolling");
        // 扫客人码场景：直接启动轮询，不检查 pay_url
        if (!this.localOrderInfo.ol_pay_id) {
          console.error("ol_pay_id 为空，无法查询支付状态");
          this.$message.error("订单ID获取失败");
          this.onCancelDrawer();
          return;
        }
        // 确保 r 为 0（支付中）
        if (this.localOrderInfo.r !== 0 && this.localOrderInfo.r !== 1) {
          this.localOrderInfo.r = 0;
          this.orderInfoDetail.r = 0;
        }
        this.startPaymentStatusPolling();
        return;
      }
      
      // "客人扫我"场景：必须有 pay_url
      if (!this.localOrderInfo.pay_url) {
        console.error("pay_url 为空，无法生成二维码");
        this.$message.error("支付链接获取失败");
        this.onCancelDrawer();
        return;
      }
      
      this.textValue = this.localOrderInfo.pay_url;
      console.log("设置 textValue:", this.textValue);
      
      if (!this.localOrderInfo.ol_pay_id) {
        console.error("ol_pay_id 为空，无法查询支付状态");
        this.$message.error("订单ID获取失败");
        this.onCancelDrawer();
        return;
      }
      
      // 启动支付状态轮询
      this.startPaymentStatusPolling();
    },
    
    // 启动支付状态轮询（统一方法，供二维码场景和扫客人码场景使用）
    startPaymentStatusPolling() {
      if (!this.localOrderInfo || !this.localOrderInfo.ol_pay_id) {
        console.error("无法启动支付状态轮询：缺少 ol_pay_id");
        return;
      }
      
      console.log("启动支付状态轮询, ol_pay_id:", this.localOrderInfo.ol_pay_id);
      
      if (this.timer) clearInterval(this.timer);
      this.startTimer = 15*60; // 15分钟超时
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
      }, 1000); // 每秒查询一次
    },

    // 询问订单支付状态
    async getOrderPayStatus() {
      // 使用本地快照数据，避免父组件修改影响
      if (!this.localOrderInfo || !this.localOrderInfo.ol_pay_id) {
        console.error("本地订单信息或ol_pay_id不存在，停止查询支付状态");
        console.log("localOrderInfo:", this.localOrderInfo);
        
        // 清除定时器并关闭弹窗
        if (this.timer) {
          clearInterval(this.timer);
          this.timer = null;
        }
        this.onCancelDrawer();
        return;
      }

      const params = {
        ol_pay_id: this.localOrderInfo.ol_pay_id * 1, // int64   锁定订单Id
      };

      // 再次验证参数有效性
      if (!params.ol_pay_id || params.ol_pay_id <= 0 || isNaN(params.ol_pay_id)) {
        console.error("ol_pay_id参数无效:", params.ol_pay_id);
        if (this.timer) {
          clearInterval(this.timer);
          this.timer = null;
        }
        this.onCancelDrawer();
        return;
      }

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
        ol_pay_id: this.localOrderInfo.ol_pay_id * 1, // int64   锁定订单Id
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
      console.log("=== notPayHandle 被调用 ===");
      try {
        const res = await this.showConfirmHandle(
          "确认",
          "点击暂不支付后，如果客人已经成功付款，则该金额将进入到滞留金列表，是否确认暂不支付？"
        );
        console.log("确认对话框返回结果:", res);
        
        if (res == "confirm") {
          console.log("用户确认暂不支付，开始取消订单");
          // const result = await this.cancelPayOrder();
          // console.log("取消订单结果:", result);
          
          this.reloadMyOrderTableData();
          this.onCancelDrawer();
          
          // if (result == "success") {
            this.$emit("subSecondLogoutHandle");
          // }
        } else {
          console.log("用户取消了暂不支付操作");
        }
      } catch (error) {
        console.error("notPayHandle 执行出错:", error);
      }
    },

    // 操作确认框
    async showConfirmHandle(title = "", content = "") {
      console.log("=== showConfirmHandle 被调用 ===");
      console.log("title:", title);
      console.log("content:", content);
      
      try {
        console.log("准备显示确认对话框...");
        
        const result = await this.$confirm(content, title, {
          distinguishCancelAndClose: true,
          confirmButtonText: "确定",
          cancelButtonText: "取消",
          type: 'warning',
          center: true,
          customClass: 'pay-confirm-dialog',
          zIndex: 10000
        });
        
        console.log("用户点击了确定, result:", result);
        return "confirm";
      } catch (error) {
        console.log("用户点击了取消或关闭:", error);
        return "cancel";
      }
    },
    onCancelDrawer() {
      console.log("=== onCancelDrawer 被调用 ===");
      console.log("准备发射 showOrHideQRDrawerHandle 事件");
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
        // 清空本地数据快照
        this.localOrderInfo = null;
        console.log("已清空本地数据快照");
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

<style>
/* 确保确认对话框显示在最顶层 */
.pay-confirm-dialog {
  z-index: 10000 !important;
}

.pay-confirm-dialog .el-message-box {
  z-index: 10000 !important;
}

/* 只为确认对话框的遮罩层设置层级，不影响其他组件 */
.pay-confirm-dialog + .v-modal {
  z-index: 9999 !important;
}

/* 确保 Element UI 的确认对话框能正确显示 */
.el-message-box-wrapper {
  z-index: 10000 !important;
}

.el-message-box {
  z-index: 10000 !important;
}

/* 全局设置 Element UI 确认对话框的层级 */
body .el-message-box__wrapper {
  z-index: 10000 !important;
}

body .el-message-box {
  z-index: 10000 !important;
}
</style>
