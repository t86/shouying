<template>
  <!-- 服务员添加滞留金（让客人扫码） -->
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="notPayHandle"
      direction="rtl"
      append-to-body
      size="600px"
    >
      <div class="session p-5 fs14">
        <div v-show="status == 1">
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>渠道：</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <div
                class="choose"
                :class="{ active: payType == item.id }"
                v-for="item in payTypeList"
                :key="item.id"
                @click="payType = item.id"
              >
                <img
                  :src="item.icon"
                  style="height: 25px; width: 25px; vertical-align: middle"
                  alt=""
                />
                <span style="vertical-align: middle">{{ item.name }}</span
                ><span
                  v-if="[5, 6].includes(item.id)"
                  style="margin-left: 4px; vertical-align: middle; color: red"
                  >(推荐)</span
                >
              </div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>金额：</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <el-input
                style="width: 260px"
                v-model="amt"
                size="small"
                placeholder="请输入金额"
              ></el-input
              >&nbsp;
              <span>元</span>
            </div>
          </div>

          <div class="m-t-6">
            <keyBoard needPoint="true" @changeNum="changeNum" />
          </div>
        </div>

        <div v-show="status == 3 && qrResult == null">
          <div class="coll" layout="row" layout-align="start center">
            <div class="value" layout-align="start center">
              <el-input
                style="width: 260px"
                v-model="scanCode"
                size="small"
                placeholder="请输入支付码"
              ></el-input>
            </div>
          </div>
          <div class="m-t-6">
            <keyBoard @changeNum="changeCode" />
          </div>
        </div>

        <div v-if="status == 2 || status == 3">
          <div class="content" v-if="[1, 2].includes(payType)">
            <p class="label">
              <span>待支付金额:</span>
              <span class="amt" style="font-size: 28px">¥</span>
              <span class="amt">{{ (amt * 1).toFixed(2) }}</span>
            </p>
            <div class="qr" layout="column" layout-align="center center">
              <img
                v-if="!textValue"
                class="loading"
                :src="require('@/assets/order-img/loading.png')"
              />
              <vue-qr
                v-else
                ref="qrCode"
                :text="textValue"
                :size="240"
                :margin="8"
              />
            </div>
            <div class="tips">
              请客人使用{{ payType == 1 ? "支付宝" : "微信" }}扫描二维码进行付款
            </div>
          </div>
          <div
            class="wait_content"
            v-if="[5, 6].includes(payType) && this.qrResult != null"
          >
            <div v-if="qr_pay_state == 0">
              <img
                class="loading"
                :src="require('@/assets/order-img/loading.png')"
              />
              <div class="wait_tip">等待支付结果…</div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button
          type="info"
          v-if="status == 1 || (status == 3 && qrResult == null)"
          @click="onCancelDrawer"
          >取消</el-button
        >
        <el-button
          type="primary"
          v-if="status == 1 || (status == 3 && qrResult == null)"
          @click="onSubmit"
          >确定</el-button
        >

        <div>
          <el-button
            type="info"
            v-if="status == 2 && ![5, 6].includes(payType)"
            @click="notPayHandle"
            >暂不支付</el-button
          >
          <el-button
            type="primary"
            v-if="status == 2 && ![5, 6].includes(payType)"
            @click="goPrevStepHandle"
            >上一步</el-button
          >
        </div>
        <div v-if="[5, 6].includes(payType)">
          <el-button
            type="info"
            v-if="status == 2 && qr_pay_state == 0"
            @click="notPayHandle"
            >关闭</el-button
          >
          <el-button
            type="info"
            v-if="status == 2 && qr_pay_state == 2"
            @click="onCancelDrawer"
            >关闭</el-button
          >
          <el-button
            type="info"
            v-if="status == 2 && qr_pay_state == 2"
            @click="goPrevStepHandle"
            >重新扫描</el-button
          >
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_order from "@/api/order";
import VueQr from "vue-qr";
import weixin_kerensaowo from "@/assets/pay-img/weixin_kerensaowo.png";
import weixin_saokeren from "@/assets/pay-img/weixin_saokeren.png";
import weixinxiaochengxu from "@/assets/pay-img/weixinxiaochengxu.png";
import zhifubao_kerensaowo from "@/assets/pay-img/zhifubao_kerensaowo.png";
import zhifubaozhifu_saokeren from "@/assets/pay-img/zhifubaozhifu_saokeren.png";

const payTypeList =
  window.atool &&
  ("startScan" in window.atool || window.atool.getTermType() == "android")
    ? [
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
      ]
    : [
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

      ];
export default {
  data() {
    return {
      timer: null, // 定时器
      status: 1, // 1 选择支付方式  2 二维码  3 扫码支付输入支付码
      payTypeList,
      payType: "",
      amt: "",
      scanCode: "",
      textValue: "",
      textId: 0, //  二维码订单Id, 用于查询支付订单状态

      // 扫码支付
      qrResult: null, // 扫码结果
      qr_pay_state: 0, // 0:未支付 1:已支付 2:支付失败
    };
  },
  methods: {
    // 开始扫码
    startScan() {
      if (window.atool && "startScan" in window.atool) {
        window.atool.startScan("scan_callback");
      } else {
        this.status = 3;
      }
    },
    changeCode(value) {
      switch (value) {
        case 10: // 清空
          this.scanCode = "";
          break;
        case 12: // 回退
          this.scanCode = this.scanCode
            .toString()
            .slice(0, this.scanCode.toString().length - 1);
          break;
        default:
          this.scanCode = this.scanCode.toString() + value;
          break;
      }
    },
    // 获取二维码
    async getQRcodeUrl() {
      this.textId = "";
      this.textValue = "";
      // 5:扫客人-支付宝 6:扫客人-微信   扫码结果为空 调用客户端扫码
      if ([5, 6].includes(this.payType) && this.qrResult == null) {
        try {
          if (
            window.atool.getTermType() == "android" &&
            !("startScan" in window.atool)
          ) {
            this.$message.warning(
              "当前版本还不支持, 请联系系统运维人员升级版本"
            );
            return;
          }
          this.startScan();
        } catch (e) {
          console.log(e);
          this.$message.warning("启动扫码失败，请重试");
        }
        return;
      }
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64   卡台Id
        pay_type: this.payType * 1, //   int    买单方式: 1 支付宝扫我 2 微信扫我 5 扫我支付宝 6 扫我微信
        pay_amt: this.amt.toString(), //    string  滞留金金额
        auth_code: this.qrResult, //    string  付款码
      };
      try {
        const res = await api_order.reqGetMerchantPayQRcode(params);
        if (res.code == 1) {
          this.textValue = res.data.pay_url || "";
          this.textId = res.data.pay_dtl_id || 0;
          this.qr_pay_state = res.data.r || 0;
          if (this.qr_pay_state == 1) {
            clearInterval(this.timer);
            this.$message.success("支付成功");
            this.$emit("subSecondLogoutHandle");
            this.onCancelDrawer();
            return;
          } else if (this.qr_pay_state == 2) {
            clearInterval(this.timer);
            this.$message.warning(res.msg);
            this.onCancelDrawer();
            return;
          }

          if (this.timer) clearInterval(this.timer);
          this.timer = setInterval(() => {
            this.getPayStatus();
          }, 1000);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    // 获取支付状态
    async getPayStatus() {
      const params = {
        id: this.textId * 1, //  int64  订单Id
      };
      try {
        const res = await api_order.reqGetMerchantPayQRcodeStatus(params);
        if (res.code == 1) {
          if (res.data.status == 5) {
            clearInterval(this.timer);
            this.$message.success("支付成功");
            this.$emit("subSecondLogoutHandle");
            this.onCancelDrawer();
          }
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("数据请求失败", error);
      }
    },

    // 返回上一步
    goPrevStepHandle() {
      this.status = 1;
      if (this.timer) clearInterval(this.timer);
    },

    changeNum(value) {
      switch (value) {
        case 10: // 小数点
          if (this.amt.toString().indexOf(".") > -1) return;
          this.amt = this.amt.toString() + ".";
          break;
        case 12: // 回退
          this.amt = this.amt
            .toString()
            .slice(0, this.amt.toString().length - 1);
          break;
        default:
          this.amt = this.amt.toString() + value;
          break;
      }
    },

    // 暂不支付
    async notPayHandle() {
      const res = await this.showConfirmHandle(
        "确认",
        "点击关闭后，无法收到客人支付是否成功的结果通知！是否确认暂不支付？"
      );
      if (res == "confirm") {
        this.onCancelDrawer();
        this.$emit("subSecondLogoutHandle");
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

    onSubmit() {
      if (this.status == 1) {
        if (!this.payType) return this.$message.warning("请选择渠道");
        if (!this.amt) return this.$message.warning("请输入金额");
        this.status = 2;
        this.getQRcodeUrl();
      } else if (this.status == 3) {
        scan_callback({ code: this.scanCode ? 0 : 1, data: this.scanCode });
      }
    },
    onCancelDrawer() {
      this.show = false;
    },

    resetHandle() {
      this.status = 1;
      this.amt = "";
      this.payType = "";
    },
  },
  created() {},
  mounted() {
    const that = this;
    function scan_callback(value) {
      try {
        if (value && value.code === 0) {
          that.qrResult = value.data;
          that.qr_pay_state = 0;
          that.getQRcodeUrl();
        } else {
          that.qrResult = null;
          that.qr_pay_state = 0;
          that.status = 1;
          that.$message.warning("扫码取消");
        }
      } catch (error) {
        console.log("扫码失败：", error);
        that.$message.warning("扫码失败：" + error);
      }
    }

    window.scan_callback = scan_callback;
  },
  props: {
    value: {
      default: false,
    },
  },
  computed: {
    title() {
      return this.status == 1 ? "滞留金" : "客人支付滞留金";
    },
    show: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit("input", val);
      },
    },
  },
  components: {
    VueQr,
    keyBoard: () => import("@/components/common/keyBoard"),
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.resetHandle();
        } else {
          if (this.timer) clearInterval(this.timer);
        }
      },
      immediate: true,
    },
  },
  beforeDestroy() {
    if (this.timer) clearInterval(this.timer);
  },
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>
<style scoped lang="less">
.session {
  color: rgba(255, 255, 255, 0.8);
}

.coll {
  margin-top: 20px;
  align-items: baseline;
  .label {
    width: 80px;
    min-width: 80px;
    text-align: right;
  }

  .value {
    margin: 0 auto;
    flex-wrap: wrap;
    .choose {
      cursor: pointer;
      width: 168px;
      padding: 6px 6px 6px 16px;
      margin-right: 20px;
      margin-bottom: 20px;
      border: 1px solid #999;
      color: #999;
      border-radius: 6px;

      &.active {
        border-color: #4b89ff;
        color: #4b89ff;
      }
    }
  }
}

.content {
  padding: 10px;
  text-align: center;
  box-sizing: border-box;

  .label {
    margin: 4.5vh 0 5.5vh;
    font-size: 16px;
    line-height: 16px;

    .amt {
      color: #1edaad;
      font-size: 30px;
    }
  }

  .qr {
    margin: 0 auto;
    width: 240px;
    height: 240px;
    background-color: rgba(255, 255, 255, 0.2);

    img.loading {
      width: 70px;
      animation: rotateAnimation 0.7s linear infinite;
    }

    @keyframes rotateAnimation {
      from {
        transform: rotate(0deg);
      }
      to {
        transform: rotate(360deg);
      }
    }
  }

  .tips {
    font-size: 15px;
    color: #ff2f4b;
    margin-top: 4.5vh;
    margin-bottom: 5vh;
  }
}

.wait_content {
  padding: 10px;
  text-align: center;
  box-sizing: border-box;
  background: #202c4a;
  display: flex;
  justify-content: center;
  flex-direction: column;
  align-items: center;
  height: 376px;
  img.loading {
    width: 70px;
    animation: rotateAnimation 0.7s linear infinite;
  }
  .wait_tip {
    color: #fff;
    font-size: 16px;
    margin-top: 72px;
  }
  .fail {
    i {
      font-size: 120px;
      color: red;
    }
    .tip {
      font-size: 16px;
      margin-top: 70px;
    }
  }
}
</style>
