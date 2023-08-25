<template>
<!-- 服务员添加滞留金（让客人扫码） -->
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="notPayHandle"
      direction="rtl"
      append-to-body
      size="500px"
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
                :class="{'active': payType == item.id}"
                v-for="item in payTypeList"
                :key="item.id"
                @click="payType = item.id"
              >{{item.name}}</div>
            </div>
          </div>
          <div class="coll" layout="row" layout-align="start center">
            <div class="label">
              <span class="red-color">*</span>
              <span>金额：</span>
            </div>
            <div class="value" layout="row" layout-align="start center">
              <el-input style="width: 260px" v-model="amt" size="small" placeholder="请输入金额"></el-input>&nbsp;
              <span>元</span>
            </div>
          </div>

          <div class="m-t-6">
            <keyBoard needPoint="true" @changeNum="changeNum" />
          </div>
        </div>

        <div v-if="status == 2">
          <div class="content">
            <p class="label">
              <span>待支付金额:</span>
              <span class="amt" style="font-size:28px">¥</span>
              <span class="amt">{{(amt * 1).toFixed(2)}}</span>
            </p>
            <div class="qr" layout="column" layout-align="center center">
              <img v-if="!textValue" class="loading" :src="require('@/assets/order-img/loading.png')" />
              <vue-qr v-else ref="qrCode" :text="textValue" :size="240" :margin="8" />
            </div>
            <div class="tips">请客人使用{{payType == 1 ? '支付宝' : '微信'}}扫描二维码进行付款</div>
          </div>
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" v-if="status == 1" @click="onCancelDrawer">取消</el-button>
        <el-button type="primary" v-if="status == 1" @click="onSubmit">确定</el-button>

        <el-button type="info" v-if="status == 2" @click="notPayHandle">暂不支付</el-button>
        <el-button type="primary" v-if="status == 2" @click="goPrevStepHandle">上一步</el-button>
      </div>
    </el-drawer>
  </div>
</template>
 
<script>
import api_order from "@/api/order";
import VueQr from "vue-qr";
const payTypeList = [
  {
    id: 1,
    name: "支付宝扫码"
  },
  {
    id: 2,
    name: "微信扫码"
  }
];
export default {
  data() {
    return {
      timer: null, // 定时器
      status: 1, // 1 选择支付方式  2 二维码
      payTypeList,
      payType: "",
      amt: "",
      textValue: '',
      textId: 0,  //  二维码订单Id, 用于查询支付订单状态
    };
  },
  methods: {
    // 获取二维码
    async getQRcodeUrl(){
      this.textId = ''
      this.textValue = ''
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64   卡台Id
        pay_type: this.payType * 1, //   int    买单方式: 1 支付宝扫码 2 微信扫码
        pay_amt: this.amt.toString(), //    string  滞留金金额
      }
      try {
        const res = await api_order.reqGetMerchantPayQRcode(params)
        if(res.code == 1) {
          this.textValue = res.data.pay_url || ''
          this.textId = res.data.pay_dtl_id || 0

          if(this.timer) clearInterval(this.timer)
          this.timer = setInterval(() => {
            this.getPayStatus()
          }, 1000)

        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    // 获取支付状态
    async getPayStatus(){
      const params = {
        id: this.textId * 1, //  int64  订单Id
      }
      try {
        const res = await api_order.reqGetMerchantPayQRcodeStatus(params)
        if(res.code == 1) {
          if(res.data.status == 5) {
            clearInterval(this.timer)
            this.$message.success('支付成功')
            this.onCancelDrawer()
          }
        } else {
          this.$message.warning(res.msg)
        }
      } catch (error) {
        console.log('数据请求失败', error);
      }
    },

    // 返回上一步
    goPrevStepHandle(){
      this.status = 1
      if(this.timer) clearInterval(this.timer)
    },

    changeNum(value) {
      switch (value) {
        case 10: // 小数点
          if (this.amt.toString().indexOf(".") > -1) return;
          this.amt = this.amt.toString() + ".";
          break;
        case 12: // 回退
          this.amt =
            this.amt.toString().slice(0, this.amt.toString().length - 1) * 1;
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
      }
    },

    
    // 操作确认框
    async showConfirmHandle(title = "", content = "") {
      return this.$confirm(content, title, {
        distinguishCancelAndClose: true,
        confirmButtonText: "确定",
        cancelButtonText: "取消"
      })
        .then(res => {
          return res;
        })
        .catch(e => "");
    },

    onSubmit() {
      if (!this.payType) return this.$message.warning("请选择渠道");
      if (!this.amt) return this.$message.warning("请输入金额");
      this.status = 2;
      this.getQRcodeUrl()
    },
    onCancelDrawer() {
      this.show = false;
    },

    resetHandle() {
      this.status = 1
      this.amt = "";
      this.payType = "";
    }
  },
  created() {},
  mounted() {},
  props: {
    value: {
      default: false
    }
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
      }
    }
  },
  components: {
    VueQr,
    keyBoard: () => import("@/components/common/keyBoard")
  },
  watch: {
    value: {
      handler(newVal) {
        if (newVal) {
          this.resetHandle();
        } else {
          if(this.timer) clearInterval(this.timer)
        }
      },
      immediate: true
    }
  },
  beforeDestroy () {
    if(this.timer) clearInterval(this.timer)
  }
};
</script>

<style scoped lang='less'>
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>
<style scoped lang='less'>
.session {
  color: rgba(255, 255, 255, 0.8);
}

.coll {
  margin-top: 20px;
  .label {
    width: 80px;
    text-align: right;
  }

  .value {
    margin-left: 10px;
    .choose {
      cursor: pointer;
      padding: 6px 16px;
      margin-right: 20px;
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
    color: #d62855;
    margin-top: 4.5vh;
    margin-bottom: 5vh;
  }
}
</style>