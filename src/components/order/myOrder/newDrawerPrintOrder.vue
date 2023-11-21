<template>
  <!-- 
    我的点单页面，收银系统未支付订单
    赠送、自用、退单、选择套餐需要更改的套餐组、退单套餐查看套餐明细 
  -->
  <div class="my-order-print-drawer">
    <el-drawer :title="title" :visible.sync="show" direction="rtl" size="600px" :before-close="onCancelDrawer">
      <div class="content">
        <div class="form">
          <el-form label-position="right" @submit.native.prevent style="margin-left: 10px;">
            <!-- 商品名称 -->
            <el-form-item label="是否包含鸡尾酒类商品:">
              <el-radio v-model="radio" label="2">不包含</el-radio>
              <el-radio v-model="radio" label="1">包含</el-radio>
            </el-form-item>
          </el-form>
        </div>
        <!-- 提交按钮 -->
        <div class="form-btn" layout="row" layout-align="center center">
          <el-button type="info" @click.stop="onCancelDrawer">取消</el-button>
          <el-button type="primary" @click.stop="onSubmit">打印</el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_order from "@/api/order";

export default {
  data() {
    return {
      show: false,
      radio: '2'
    };
  },
  methods: {
    // 提交
    async onSubmit() {
      try {

        let res;
        if (this.pageType == 'myOrder') {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
            total_type: this.isNotPay ? 2 : 1, //  int64    1 总消费单 2 未结账消费单
            include_hl: this.radio * 1 /// int    1 含花篮小费 2 不含花篮小费
          };
          res = await api_order.reqPrintOrder(params);
        } else {
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
            turnover_cnt: this.turnover_cnt,
            pay_id: this.payId == -1 ? 0 : this.payId * 1, //消费单id
            range_type: this.payId == -1 ? 1 : 3, //  int64    范围标识 1 总单(pay_id需要传0), 2 未结账消费单(pay_id需要传0), 3 指定结账pay_id的消费单(pay_id<>0)
            include_hl: this.radio * 1 /// int    1 含花篮小费 2 不含花篮小费
          };
          if (this.isNotPay) {
            params.range_type = 2
          }
          res = await api_order.reqAnewPrintOrder(params);
        }

        if (res.code == 1) {
          this.$message.success("打印成功")
          this.onCancelDrawer()
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("打印消费单失败", error);
      }
    },

    onCancelDrawer() {
      this.$emit("showOrHidePrintDrawer");
    }
  },
  created() { },
  mounted() { },
  props: {
    showDrawer: {
      default: false
    },
    isNotPay: {
      default: false
    },
    turnover_cnt: {
      default: 0
    },
    payId: {
      default: 0
    },
    pageType: {
      default: 'payOrder' // payOrder: 收银系统, myOrder: 点单系统
    }
  },
  computed: {
    title() {
      return this.isNotPay ? '打印未结消费单' : '打印消费单'
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      if (newVal) this.radio = '2'
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/newElementDrawer.less";
// @import "../../../style/common/elementFormBtn.less";

/* 修改选中和未选中状态的背景颜色 */
/deep/ .el-radio__inner {
  background-color: #F9F9F9;
  width: 20px;
  height: 20px;
  /* 未选中状态的背景颜色 */
}

/deep/ .el-radio__input.is-checked .el-radio__inner {
  /* 选中状态的背景颜色 */
  width: 20px;
  height: 20px;
  background-color: #3373E8;
}

/* 修改文本字体大小和颜色 */
/deep/ .el-radio__label {

  font-size: 20px;
  /* 文本字体大小 */

  color: #08080A;
  /* 文本字体颜色 */
}

/* 修改选中状态的文本颜色 */
/deep/ .el-radio__input.is-checked .el-radio__label {
  color: #3373E8;
  /* 选中状态的文本颜色 */
}

.form-btn {
  position: absolute;
  bottom: 0;
  right: 0;
  z-index: 1;
  width: 100%;
  height: 64px;

  background: #FAFAFC;

  button {
    width: 112px;
    height: 52px;
    border-radius: 8px;
    border: none;
    font-size: 20px;
    font-family: PingFangSC, PingFang SC;
    font-weight: 600;
    color: #FFFFFF;

    &.el-button.el-button--info {
      width: 112px;
      background: #374368;
      box-shadow: inset 0px 1px 1px 0px rgba(255, 255, 255, 0.2);
      border-radius: 8px;
    }

    &.el-button.el-button--primary {

      background: #3373E8;
      box-shadow: none;
    }
  }
}
</style>