<template>
  <div>
    <!-- 选择支付渠道方式 -->
    <div class="choose-pay-type" v-show="show">
      <div class="contain">
        <div class="top" layout="row" layout-align="space-between center">
          <div>选择支付方式</div>
          <i class="el-icon-close cursor" style="color: #1A1A21;" @click="handleClose"></i>
        </div>

        <div class="center" layout="row" layout-align="start center">
          <div class="choose" :class="{ active: payType == item.id }" v-for="item in payTypeList" :key="item.id"
            @click="payType = item.id">
            <img :src="item.icon" style="height: 30px; width: 30px; vertical-align: middle" alt="" />
            <span style="margin-left: 8px;">{{ item.name }}</span><span v-if="[5, 6].includes(item.id)"
              class="tuijian">推荐</span>
          </div>
        </div>

        <div class="bottom" layout="row" layout-align="center center">
          <div class="button info cursor" @click="handleClose">
            取消
          </div>
          <div class="button primary cursor" @click="handleConfirm">
            确定
          </div>
        </div>
      </div>
    </div>

    <!-- 扫码输入支付码 -->
    <div class="scan_input" v-if="scanStart">
      <div class="contain">
        <div class="top center" layout="row" layout-align="space-between center">
          <input style="width: 260px" v-model="scanCode" class="value focus" size="small" placeholder="请输入支付码" />
        </div>
        <div class="m-t-6">
          <keyBoard @changeNum="changeCode" />
        </div>
        <div class="bottom" layout="row" layout-align="center center">
          <div class="button info cursor" @click="onCancelScan">取消</div>
          <div class="button primary cursor" @click="onSubmitScan">确定</div>
        </div>
      </div>
    </div>

    <!-- 扫客人付款码弹窗 -->
    <customerPaymentScanDialog
      v-model="showCustomerPaymentScan"
      :payType="payType"
      :orderIds="orderIds"
      @success="handleCustomerPaymentSuccess"
    />
  </div>
</template>

<script>
import api_order from "@/api/order";
import keyBoard from "@/components/common/keyBoard";
import customerPaymentScanDialog from "./customerPaymentScanDialog.vue";
import weixin_kerensaowo from "@/assets/pay-img/weixin_kerensaowo.png";
import weixin_saokeren from "@/assets/pay-img/weixin_saokeren.png";
import weixinxiaochengxu from "@/assets/pay-img/weixinxiaochengxu.png";
import zhifubao_kerensaowo from "@/assets/pay-img/zhifubao_kerensaowo.png";
import zhifubaozhifu_saokeren from "@/assets/pay-img/zhifubaozhifu_saokeren.png";

// 收银系统支付方式列表（包含扫客人选项）
const payTypeListForCashier = [
  {
    id: 6,
    icon: weixin_saokeren,
    name: "扫客人-微信",
  },
  {
    id: 5,
    icon: zhifubaozhifu_saokeren,
    name: "扫客人-支付宝",
  },
  {
    id: 2,
    icon: weixin_kerensaowo,
    name: "客人扫我-微信",
  },
  {
    id: 1,
    icon: zhifubao_kerensaowo,
    name: "客人扫我-支付宝",
  },
  {
    id: 3,
    icon: weixinxiaochengxu,
    name: "微信小程序自助",
  },
];

// 普通系统支付方式列表
const payTypeListForNormal = [
  {
    id: 2,
    icon: weixin_kerensaowo,
    name: "客人扫我-微信",
  },
  {
    id: 1,
    icon: zhifubao_kerensaowo,
    name: "客人扫我-支付宝",
  },
  {
    id: 3,
    icon: weixinxiaochengxu,
    name: "微信小程序自助",
  },
];

// 根据系统类型选择支付方式列表
export default {
  name: "ChoosePayTypeDialog",
  components: {
    keyBoard,
    customerPaymentScanDialog,
  },
  props: {
    value: {
      type: Boolean,
      default: false,
    },
    orderIds: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      show: false,
      payType: "",
      qrResult: null,
      scanStart: false,
      scanCode: "",
      showCustomerPaymentScan: false, // 显示扫客人付款码弹窗
    };
  },
  computed: {
    // 动态计算支付方式列表：收银系统(money)显示"扫客人"选项，点单系统(order)只显示"客人扫我"
    payTypeList() {
      const isCashierSystem = sessionStorage.getItem('client') === 'money';
      return isCashierSystem ? payTypeListForCashier : payTypeListForNormal;
    },
  },
  watch: {
    value(newVal) {
      console.log("choosePayTypeDialog value changed:", newVal);
      this.show = newVal;
      if (newVal) {
        this.payType = "";
        this.qrResult = null;
        this.scanStart = false;
        this.scanCode = "";
        console.log("接收到的订单ID列表:", this.orderIds);
      }
    },
    show(newVal) {
      console.log("choosePayTypeDialog show changed:", newVal);
      this.$emit("input", newVal);
    },
  },
  methods: {
    handleClose() {
      this.show = false;
      this.payType = "";
    },

    async handleConfirm() {
      if (!this.payType) {
        return this.$message.warning("请选择支付方式");
      }

      await this.getPayQRCode(1);
    },

    // 获取买单二维码
    async getPayQRCode(force = 2) {
      // 5:扫客人-支付宝 6:扫客人-微信
      if ([5, 6].includes(this.payType)) {
        // 打开扫客人付款码弹窗
        this.show = false;
        this.showCustomerPaymentScan = true;
        return;
      }

      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
        pay_type: this.payType * 1,
        auth_code: this.qrResult ? this.qrResult.toString() : "",
        order_ids: this.orderIds && this.orderIds.length > 0 ? this.orderIds : [], // 传递订单ID列表
      };

      try {
        const res = await api_order.reqGetPayQRcode(params);
        if (res.code == 1) {
          res.data = res.data || {};
          const orderInfo = { ...res.data, r: res.data.r || 0 };
          
          // 关闭当前弹窗
          this.show = false;
          this.scanStart = false;
          
          // 通知父组件打开支付二维码弹窗
          this.$emit("success", {
            payType: this.payType,
            orderInfo: orderInfo,
          });
        } else if (res.code == 2) {
          this.getPayQRCode(1);
        } else if (res.code == 3) {
          this.getPayQRCode(3);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("生成买单二维码失败", error);
        this.$message.error("生成买单二维码失败");
      }
    },

    // 启动扫码
    startScan() {
      return new Promise((resolve, reject) => {
        const that = this;
        function scan_callback(value) {
          try {
            console.log("scan_callback:", JSON.stringify(value));
            if (value && value.code === 0) {
              that.qrResult = value.data;
              resolve(value.data);
              that.getPayQRCode(1);
            } else {
              that.$message.warning("扫码取消");
              reject("扫码取消");
            }
          } catch (error) {
            console.log("扫码失败：", error);
            that.$message.warning("扫码失败：" + error);
            reject(error);
          }
        }

        window.scan_callback = scan_callback;

        if (window.atool && "startScan" in window.atool) {
          window.atool.startScan("scan_callback");
        } else {
          reject("不支持扫码");
        }
      });
    },

    // 键盘输入扫码
    changeCode(value) {
      switch (value) {
        case 11: // 删除
          this.scanCode = this.scanCode.toString().slice(0, -1);
          break;
        case 12: // 清空
          this.scanCode = "";
          break;
        default:
          this.scanCode = this.scanCode.toString() + value;
          break;
      }
    },

    // 取消扫码
    onCancelScan() {
      this.scanStart = false;
      this.scanCode = "";
      this.show = true; // 返回选择支付方式界面
    },

    // 确认扫码
    onSubmitScan() {
      if (!this.scanCode) {
        return this.$message.warning("请输入支付码");
      }
      this.qrResult = this.scanCode;
      this.scanStart = false;
      this.getPayQRCode(1);
    },

    // 处理扫客人付款成功
    handleCustomerPaymentSuccess(result) {
      console.log("扫客人付款成功", result);
      
      // 通知父组件打开支付二维码弹窗或处理支付结果
      this.$emit("success", result);
    },
  },
};
</script>

<style scoped lang="less">
@import "../../style/order/choosePayType.less";
</style>
