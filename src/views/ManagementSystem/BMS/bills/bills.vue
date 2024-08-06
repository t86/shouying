<template>
  <div class="bills">
    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">下单消费单（点单机）打印份数：</div>
      <div class="value">
        <el-input-number v-model="orderCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">结账结算单（收银台）打印份数：</div>
      <div class="value">
        <el-input-number v-model="orderPayedCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">清台结算单打印份数：</div>
      <div class="value">
        <el-input-number v-model="clearCardCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">退单小票（出品库）打印份数：</div>
      <div class="value">
        <el-input-number v-model="backOrderCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">退单小票（收银台）打印份数：</div>
      <div class="value">
        <el-input-number v-model="backOrderMoneyCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">修改优惠人小票打印份数：</div>
      <div class="value">
        <el-input-number
          v-model="changeYhRenCount"
          :min="0"
          :max="9"
        />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">修改优惠2人小票打印份数：</div>
      <div class="value">
        <el-input-number
          v-model="changeYhRen2Count"
          :min="0"
          :max="9"
        />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">线上结算单小票打印份数：</div>
      <div class="value">
        <el-input-number v-model="onlineOrderCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">线上结算单小票打印机：</div>
      <div class="value">
        <el-select
          clearable
          v-model="onlineOrderPrint"
        >
          <el-option
            v-for="item in onlineOrderPrintList"
            :key="item.id"
            :label="item.n"
            :value="item.id"
          ></el-option>
        </el-select>
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">线上清台小票打印机：</div>
      <div class="value">
        <el-select
          clearable
          v-model="onlineClearCardPrint"
        >
          <el-option
            v-for="item in onlineClearCardPrintList"
            :key="item.id"
            :label="item.n"
            :value="item.id"
          ></el-option>
        </el-select>
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">会员扣款小票打印份数：</div>
      <div class="value">
        <el-input-number v-model="membersubtractCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">会员充值小票打印份数：</div>
      <div class="value">
        <el-input-number v-model="memberDepositCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">会员消费小票打印份数：</div>
      <div class="value">
        <el-input-number v-model="memberConsumeCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">会员充值积分小票打印份数：</div>
      <div class="value">
        <el-input-number v-model="memberRechargePointCount" :min="0" :max="9" />
      </div>
    </div>

    <div class="coll m-b-3" layout="row" layout-align="start center">
      <div class="label">会员扣除积分小票打印份数：</div>
      <div class="value">
        <el-input-number v-model="memberPointCount" :min="0" :max="9" />
      </div>
    </div>
    <drawerPreview v-model="showPreviewDrawer" />

    <el-button class="button" type="primary" @click.stop="submitHandle"
      >保存</el-button
    >
    <span
      class="primary-link cursor fs14 m-l-10"
      @click="showPreviewDrawer = true"
      >查看小票预览</span
    >
  </div>
</template>
<script>
export default {
  data() {
    return {
      orderCount: 1, // 下单消费单打印份数
      orderPayedCount: 1, // 结账结算单打印份数
      clearCardCount: 1, // 清台结算打印份数
      backOrderCount: 1, // 退单小票(出品库)打印份数
      backOrderMoneyCount: 1, // 退单小票(收银)打印份数
      changeYhRenCount: 0, // 修改优惠人小票打印份数
      changeYhRen2Count: 0, // 修改优惠2人小票打印份数
      showPreviewDrawer: false,
      onlineOrderCount: 1, // 线上结算单小票打印分书
      onlineOrderPrint: "", // 线上结算单小票打印机
      onlineOrderPrintList: [], // 线上结算单小票打印机option
      onlineClearCardPrint: "", // 线上清台小票打印机
      onlineClearCardPrintList: [], // 线上清台小票打印机option
      memberDepositCount: 0, // 会员充值小票份数
      memberConsumeCount: 0, // 会员消费小票份数
      memberRechargePointCount: 0, //会员充值积分小票份数
      membersubtractCount: 0, // 会员扣款小票份数
      memberPointCount: 0, // 会员扣除积分小票份数
    };
  },
  methods: {
    // 请求页面数据
    async getPageData() {
      try {
        const res = await this.$api.BMS.bill.requestBillGet();
        if (res.code == 1) {
          this.orderCount = res.data.ord_csm_ddj_cnt;
          this.orderPayedCount = res.data.sel_sel_syt_cnt;
          this.backOrderCount = res.data.back_mklib_cnt;
          this.backOrderMoneyCount = res.data.back_syt_cnt;
          this.changeYhRenCount = res.data.chg_yh_emp_cnt;
          this.changeYhRen2Count = res.data.chg_yh2_emp_cnt;
          this.clearCardCount = res.data.clean_stl_cnt;
          this.onlineOrderCount = res.data.ol_out_pay_cnt;
          this.onlineOrderPrint = res.data.ol_out_pay_prt_id || "";
          this.onlineClearCardPrint = res.data.ol_clean_prt_id || "";
          this.memberDepositCount = res.data.mb_deposit_cnt;
          this.memberConsumeCount = res.data.mb_csm_cnt;
          this.memberRechargePointCount = res.data.mb_dept_pt_cnt;
          this.membersubtractCount = res.data.mb_sub_cnt;
          this.memberPointCount = res.data.mb_sub_pt_cnt;
          this.onlineOrderPrintList = (res.data.printers || []).filter(
            (item) => item.s == 1
          );
          this.onlineClearCardPrintList = (res.data.printers || []).filter(
            (item) => item.s == 1
          );
          console.log(this.onlineOrderPrintList);
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("小票配置获取失败", error);
      }
    },

    // 提交
    async submitHandle() {
      const params = {
        ord_csm_ddj_cnt: this.orderCount * 1, // int    下单消费单,点单机,打印份数, 0表示不自动打印
        sel_sel_syt_cnt: this.orderPayedCount * 1, // int    结账结算单,收银台,打印份数, 0表示不自动打印
        back_mklib_cnt: this.backOrderCount * 1, // int    退单,出品库,打印份数(如果是已出品的), 0 表示不自动打印
        back_syt_cnt: this.backOrderMoneyCount * 1, // int    退单,收银台,打印份数(如果是已出品的), 0 表示不自动打印
        clean_stl_cnt: this.clearCardCount * 1, // int 清台,咨客台(会配置到收银打印机),收银台,打印结算单份数
        chg_yh_emp_cnt: this.changeYhRenCount * 1, // int 修改优惠人小票打印份数
        chg_yh2_emp_cnt: this.changeYhRen2Count * 1, // int 修改优惠2人小票打印份数
        ol_out_pay_cnt: this.onlineOrderCount * 1, // int        //OlOutPayCnt 线上付款,小票打印份数 0表示不打印, 0的时候out_out_pay_prt_id也必须为0
        ol_out_pay_prt_id: this.onlineOrderPrint * 1, // int64      //OlOutPayPrtId 线上付款,出票打印机Id, =0 代表没有配置
        ol_clean_prt_id: this.onlineClearCardPrint * 1, // int64      //OlCleanPrtId 线上清台,出票打印机Id, =0 代表没有配置
        mb_deposit_cnt: this.memberDepositCount * 1, // int 会员充值小票份数
        mb_csm_cnt: this.memberConsumeCount * 1, // int       会员扣款小票份数
        // TODO
        mb_xxx_cnt: this.memberRechargePointCount *1, // int 会员充值积分小票份数
        mb_sub_cnt: this.membersubtractCount * 1, // int64     会员扣款小票份数
        mb_sub_pt_cnt: this.memberPointCount * 1, // int64 会员积分打印份数
        mb_dept_pt_cnt: this.memberRechargePointCount * 1,// int64 会员卡充值积分打印份数
      };
      try {
        const res = await this.$api.BMS.bill.requestBillSave(params);
        res.code == 1
          ? this.$message.success("保存成功")
          : this.$message.warning(res.msg);
      } catch (error) {
        console.log("保存小票配置失败", error);
      }
    },
  },
  mounted() {
    this.getPageData();
  },
  components: {
    drawerPreview: () => import("./drawerPreview.vue"),
  },
};
</script>
<style scoped lang="less">
.bills {
  padding: 20px 30px;
  max-height: calc(100vh - 100px);
  overflow: auto;
  box-sizing: border-box;
}

/deep/.el-input-number__decrease {
  height: 32px;
  transform: translateY(2px);
  .el-icon-minus {
    transform: translateY(-2px);
  }
}

/deep/.el-input-number__increase {
  height: 32px;
  transform: translateY(2px);
  .el-icon-plus {
    transform: translateY(-2px);
  }
}
</style>
