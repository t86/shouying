<template>
  <!-- 退单 -->
  <div>
    <el-drawer
      :title="title"
      :visible.sync="show"
      :before-close="closeDrawerHandle"
      direction="rtl"
      :size="size"
    >
      <!-- 选择退单的订单 -->
      <chooseBackOrder
        :show="show"        
        :originOrderList="originOrderList"
        @getBackOrderList="getBackOrderList"
        @updateBackReason="updateBackReason"
      />

      <!-- 提交按钮 -->
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click.stop="closeDrawerHandle">取消</el-button>
        <el-button type="primary" @click.stop="onSubmit" >确认</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_money from "@/api/money";

// 选择退单商品
import chooseBackOrder from "@/components/money/drawerOrderBack/drawerChooseBackOrder";

export default {
  data() {
    return {
      status: 1, // 1:选择要退单的商品  2：更改支付渠道（更改支付金额）  3：添加支付渠道  4：改金额
      show: false,
      backOrderList: [], // 退单列表
      backReason: '', // 退单理由
      originOrderList: [], // 修改退单之前的订单列表信息
    };
  },
  methods: {
    getBackOrderList(orderList) {
      this.backOrderList = orderList;
    },

    updateBackReason(reason) {
      this.backReason = reason
    },

    // 退单（完成退单操作）
    async orderBack() {
      const backAmt = this.backOrderList.map(item =>
        ["5", "3", "8"].indexOf(item.productInfo.prdType) > -1
          ? item.allAmt
          : item.pp == 0
          ? item.pa
          : item.pp * item.changeCount
      );

      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64     卡台Id
        pay_id: this.orderId * 1,  //     int64     支付订单Id
        remark: this.backReason, //     string    退单备注
        wk_order_ids: this.backOrderList.map(item => item.id * 1), // []int64     待退单订单Id列表
        prd_back_cnts: this.backOrderList.map(item => item.changeCount * 1), // []int      对应上面退单列表的退单商品数量
        prd_back_amts: backAmt.map(item => item.toString()), // []string    对应上面退单列表的退单商品金额
      };

      try {
        const res = await api_money.reqPayedBackOrder(params);
        if (res.code === 1) {
          this.$message.success("退单成功");
          this.$emit("showOrHideDrawer");
          this.$emit("updateBackOrderData");
          this.resetAllData();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("退单失败", error);
      }
    },

    closeDrawerHandle(isClose) {
      this.$emit("showOrHideDrawer");
    },

    // 显示或隐藏authDrawer
    showOrHideAuthDrawer() {
      this.showAuthDrawer = !this.showAuthDrawer;
    },

    onSubmit() {
      let flag = false;

      if (this.backOrderList.length === 0)
            return this.$message.warning("退单商品数量不能为0");

      this.backOrderList.forEach(el => {
        // 特饮和赔偿需要手动输入金额
        if (
          ["5", "3", "8"].indexOf(el.productInfo.prdType) > -1 &&
          !el.allAmt
        )
          flag = true;
      });

      if (flag)
        return this.$message.warning("特饮和小费必须要输入退单金额");

      if (!this.backReason) return this.$message.warning('请选择退单理由');

      this.$confirm('如果继续操作，本订单已支付渠道将进入滞留金列表，本订单中未退单的商品需重新支付。请确认是否继续操作？', '提示', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(() => {
          this.orderBack();
        }).catch(() => {
        });
    },

    // 初始化数据
    resetAllData() {
      this.backOrderList = []; // 退单列表
      this.originOrderList = []; // 修改退单之前的订单列表信息
    }
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    payedOrderList: {
      default: () => ({}) // 已支付订单信息
    },
    orderId: {
      default: "" // 当前要退单所属的单号id
    }
  },
  components: {
    chooseBackOrder
  },
  computed: {
    title() {
      return '退单';
    },
    size() {
      return "88%"
    }
  },
  watch: {
    showDrawer(newVal) {
      this.show = newVal;
      
      this.originOrderList = JSON.parse(JSON.stringify(this.payedOrderList));
      this.backOrderList = JSON.parse(
        JSON.stringify(this.payedOrderList)
      ).filter(item => item.changeCount > 0 && !item.back);
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../style/common/elementDrawer.less";
@import "../../../style/common/elementFormBtn.less";
@import "../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../style/common/elementConfirm.less";
</style>