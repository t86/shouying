<template>
  <!-- 
    我的点单页面，收银系统未支付订单
    赠送、自用、退单、选择套餐需要更改的套餐组、退单套餐查看套餐明细 
  -->
  <div class="my-order-drawer">
    <el-drawer
      :title="title"
      :visible.sync="show"
      direction="rtl"
      size="500px"
      :before-close="onCancelDrawer"
    >
      <div class="content">
        <div class="form">
              <el-form label-position="right" label-width="200px" @submit.native.prevent>
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
        if(this.pageType == 'myOrder'){
          const params = {
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
          total_type: this.isNotPay ? 2 : 1, //  int64    1 总消费单 2 未结账消费单
          include_hl: this.radio * 1 /// int    1 含花篮小费 2 不含花篮小费
          };
          res = await api_order.reqPrintOrder(params);
        }else{
          const params = {
            seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64  卡台Id
            turnover_cnt:this.turnover_cnt, 
            pay_id: this.payId == -1 ?0:this.payId * 1, //消费单id
            range_type: this.payId == -1?1:3, //  int64    范围标识 1 总单(pay_id需要传0), 2 未结账消费单(pay_id需要传0), 3 指定结账pay_id的消费单(pay_id<>0)
            include_hl: this.radio * 1 /// int    1 含花篮小费 2 不含花篮小费
          };
          if(this.isNotPay){
            params.range_type = 2
          }
          res = await api_order.reqAnewPrintOrder(params);
        }
      
        if(res.code == 1) {
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
  created() {},
  mounted() {},
  props: {
    showDrawer: {
      default: false
    },
    isNotPay:{
      default: false
    },
    turnover_cnt:{
      default: 0
    },
    payId:{
      default: 0
    },
    pageType:{
      default: 'payOrder' // payOrder: 收银系统, myOrder: 点单系统
    }
  },
  computed: {
    title(){
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
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementFormBtn.less";
</style>