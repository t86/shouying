<template>
  <div>
    <!-- 会员充值 -->
    <el-drawer
      title="充值"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="1000px"
      custom-class="vip-recharge-drawer-small"
    >
      <div class="session p-5">
        <div class="search">
          <el-input
            size="small"
            v-model="keyword"
            placeholder="输入完整手机号或后4位，方可搜索"
            style="width:284px"
            @input="searchHandle"
          ></el-input>
          <button class="btn primary" @click="searchHandle">搜索</button>
          <span v-if="step==1" class="red m-l-6">可刷卡获取会员卡号</span>
        </div>
        <div class="content m-t-4">
          <searchList
            v-if="step == 1"
            :tableData="tableData"
            @changeStep="changeStep"
            @updateCurrentInfo="updateCurrentInfo"
          />
          <searchDetail
            ref="vipDetailRef"
            v-if="step == 2"
            :currentInfo="currentInfo"
            :vipIdOfSwiper="vipIdOfSwiper"
            @updateFormInfo="updateFormInfo"
          />
        </div>
      </div>
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer()">取消</el-button>
        <el-button type="primary" v-if="step==2" @click="onSubmit" :disabled="charging" >确定</el-button>
      </div>
    </el-drawer>

    <!-- 滞留金选择弹窗 -->
    <lateDepositDialog
      v-model="showLateDepositDialog"
      :rechargeInfo="currentRechargeInfo"
      :lateDepositList="lateDepositList"
      :currentCardNo="getCurrentCardNo()"
      @confirm="handleLateDepositConfirm"
    />

    <!-- 支付方式选择弹窗 -->
    <paymentMethodDialog
      ref="paymentMethodDialogRef"
      :value="showPaymentMethodDialog"
      @input="showPaymentMethodDialog = $event"
      :rechargeInfo="paymentDialogRechargeInfo"
      @scanCustomerPayment="handleScanCustomerPayment"
      @scan-customer-payment="handleScanCustomerPayment"
      @paymentSuccess="handlePaymentSuccess"
    />

    <!-- 客人付款码扫描弹窗 -->
    <customerPaymentScanDialog
      v-model="showCustomerPaymentScanDialog"
      :paymentAmount="currentPaymentAmount"
      :rechargeInfo="currentRechargeInfo"
      :selectedLateDeposits="currentSelectedLateDeposits"
      :payType="selectedPayType"
      @success="handlePaymentSuccess"
    />
  </div>
</template>
 
<script>
import md5 from "js-md5";
import api_vip from "@/api/vip";
import searchList from "./searchList.vue";
import searchDetail from "./searchDetail.vue";
import lateDepositDialog from "./lateDepositDialog.vue";
import paymentMethodDialog from "@/components/order/vipRecharge/paymentMethodDialog.vue";
import customerPaymentScanDialog from "./customerPaymentScanDialog.vue";
export default {
  data() {
    return {
      show: false,
      keyword: "",
      step: 0,
      tableData: [],
      currentInfo: {}, // 当前手动选择充值的会员卡相关信息
      vipIdOfSwiper: "",
      stepTwoInfo: {},
      charging: false, //充值处理中
      showLateDepositDialog: false, // 显示滞留金选择弹窗
      currentRechargeInfo: {}, // 当前充值信息
      lateDepositList: [], // 滞留金列表
      showPaymentMethodDialog: false, // 显示支付方式选择弹窗
      paymentDialogRechargeInfo: {}, // 支付对话框所需的充值信息
      selectedPayType: 5, // 选中的支付类型 5:支付宝 6:微信
      showCustomerPaymentScanDialog: false, // 显示客人付款码扫描弹窗
      currentPaymentAmount: "0.00", // 当前支付金额
      currentSelectedLateDeposits: [], // 当前选中的滞留金
    };
  },
  methods: {
    async searchHandle(e) {
      if (typeof e === "object" && this.keyword.length != 4 && this.keyword.length != 11)
        return this.$message.warning("输入手机号后四位或完整手机号，方可搜索");
      if (this.keyword.length != 4 && this.keyword.length != 11) return this.tableData = [];
      const params = {
        phone: this.keyword //    string   手机号后4位或 11 位
      };
      try {
        const res = await api_vip.reqGetMakeMoneyListOfPhoneNum(params);
        if (res.code == 1) {
          this.tableData = res.data.records || [];
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("模糊查询待充值会员列表失败", error);
      }
    },
    updateFormInfo(formInfo) {
      this.stepTwoInfo = { ...formInfo };
    },
    // 提交
    async onSubmit() {
      this.charging = true
      const isCustom = this.stepTwoInfo.makeAmtInfo.d == '自定义'
      const makeAmt = isCustom ? (this.stepTwoInfo.makeAmt * 1).toFixed(2) : (this.stepTwoInfo.makeAmtInfo.d / 100).toFixed(2)
      const freeAmt = isCustom ? (this.stepTwoInfo.freeAmt * 1).toFixed(2) : (this.stepTwoInfo.makeAmtInfo.f / 100).toFixed(2)
      
      // 🔍 调试信息：打印充值流程开始
      console.log("🎯 [充值流程] 开始充值流程 (onSubmit)");
      console.log("📋 [充值流程] 充值参数:");
      console.log("  - 是否自定义 (isCustom):", isCustom, typeof isCustom);
      console.log("  - 有价金额 (makeAmt):", makeAmt, typeof makeAmt);
      console.log("  - 赠送金额 (freeAmt):", freeAmt, typeof freeAmt);
      console.log("  - 当前会员信息:", this.currentInfo);
      console.log("  - 第二步信息:", this.stepTwoInfo);
      console.log("  - 用户信息:", this.$store.state.userInfo);
      console.log("  - 充值方式 (typeVal):", this.stepTwoInfo.typeVal);
      console.log("  - 推荐人 (personVal):", this.stepTwoInfo.personVal);
      
      if (!this.stepTwoInfo.typeVal)  {
        this.charging = false
        return this.$message.warning("请选择充值方式");
      }
      
      // 如果选择的是线上付款，检查是否有滞留金
      if (this.stepTwoInfo.typeVal == 9) {
        await this.handleOnlinePaymentRecharge(makeAmt, freeAmt, isCustom);
        return;
      }
      
      // 普通充值流程
      await this.processNormalRecharge(makeAmt, freeAmt, isCustom);
    },

    // 处理线上付款充值
    async handleOnlinePaymentRecharge(makeAmt, freeAmt, isCustom) {
      try {
        // 检查滞留金
        const lateDepositList = await this.checkLateDeposit();
        
        console.log("🔍 检查滞留金结果:", lateDepositList);
        console.log("🔍 滞留金数量:", lateDepositList ? lateDepositList.length : 0);
        
        if (lateDepositList && lateDepositList.length > 0) {
          // 有滞留金，显示滞留金选择弹窗
          console.log("✅ 有滞留金，打开滞留金选择弹窗");
          this.openLateDepositDialog({
            makeAmt,
            freeAmt,
            isCustom,
            lateDepositList
          });
        } else {
          // 没有滞留金，直接进入扫码流程
          console.log("❌ 无滞留金，直接进入扫码流程");
          this.startCustomerPaymentScan(makeAmt, freeAmt, isCustom);
        }
      } catch (error) {
        console.error("检查滞留金失败:", error);
        this.$message.error("检查滞留金失败，请重试");
      } finally {
        this.charging = false;
      }
    },

    // 处理普通充值
    async processNormalRecharge(makeAmt, freeAmt, isCustom) {
      const params = {
        id: (this.currentInfo.id || this.vipIdOfSwiper) * 1 , //    int64    会员卡Id
        val_amt: makeAmt ? makeAmt : "0", //    string   有价金额(最多支持两位小数)
        free_amt: freeAmt ? freeAmt : "0", //   string  赠送金额(最多支持两位小数)
        pt_amt: this.stepTwoInfo.sendPoint ? this.stepTwoInfo.sendPoint * 1 : 0, //   string  赠送积分
        m: isCustom ? 2 : 1,//  int   充值模式 1 规则模式, 2 自定义模式
        oper_emp_id: this.$store.state.userInfo.emp_id * 1, // int64    操作员工
        deposit_cnl: this.stepTwoInfo.typeVal * 1, // int     充值渠道Id
        sales_emp_id: this.stepTwoInfo.personVal * 1, // int64    推荐人(员工)
        remark: this.stepTwoInfo.remark //     string    充值备注
      };
      
      // 🔍 调试信息：打印充值参数
      console.log("🔍 [普通充值] 准备调用充值接口");
      console.log("📋 [普通充值] 接口参数详情:");
      console.log("  - 会员卡ID (id):", params.id, typeof params.id);
      console.log("  - 有价金额 (val_amt):", params.val_amt, typeof params.val_amt);
      console.log("  - 赠送金额 (free_amt):", params.free_amt, typeof params.free_amt);
      console.log("  - 赠送积分 (pt_amt):", params.pt_amt, typeof params.pt_amt);
      console.log("  - 充值模式 (m):", params.m, typeof params.m, params.m === 1 ? "规则模式" : "自定义模式");
      console.log("  - 操作员工 (oper_emp_id):", params.oper_emp_id, typeof params.oper_emp_id);
      console.log("  - 充值渠道 (deposit_cnl):", params.deposit_cnl, typeof params.deposit_cnl);
      console.log("  - 推荐人 (sales_emp_id):", params.sales_emp_id, typeof params.sales_emp_id);
      console.log("  - 备注 (remark):", params.remark, typeof params.remark);
      console.log("📦 [普通充值] 完整参数对象:", JSON.stringify(params, null, 2));
      
      try {
        console.log("🚀 [普通充值] 开始调用 reqMakeMoneyToCard 接口...");
        const res = await api_vip.reqMakeMoneyToCard(params);
        
        // 🔍 调试信息：打印接口响应
        console.log("📥 [普通充值] 接口响应:");
        console.log("  - 响应码 (code):", res.code, typeof res.code);
        console.log("  - 响应消息 (msg):", res.msg);
        console.log("  - 响应数据 (data):", res.data);
        console.log("📦 [普通充值] 完整响应对象:", JSON.stringify(res, null, 2));
        
          if (res.code == 1) {
            console.log("✅ [普通充值] 充值成功");
            this.$message.success("充值成功");
            this.onCancelDrawer();
            this.$emit('getTableData');
            
            // 充值成功后的跳转逻辑
            this.handlePostRechargeRedirect();
          } else {
          console.log("❌ [普通充值] 充值失败:", res.msg);
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.error("💥 [普通充值] 接口调用异常:", error);
        console.log("充值失败", error);
      } finally {
        this.charging = false;
      }
    },

    // 检查滞留金
    async checkLateDeposit() {
      try {
        console.log("📞 开始调用滞留金API...");
        // 调用新API检查当前会员是否有可用的充值滞留金
        // 根据接口文档，该接口不需要传入参数
        const res = await api_vip.reqGetDepositLateListForDeposit({});
        
        console.log("📦 API返回结果:", res);
        console.log("📦 res.code:", res.code);
        console.log("📦 res.data:", res.data);
        console.log("📦 res.data.records:", res.data ? res.data.records : null);
        
        if (res.code === 1 && res.data && res.data.records) {
          console.log("✅ API返回成功，records长度:", res.data.records.length);
          // 转换数据格式：接口返回的字段名(a, c, t, n, p)转换为组件使用的字段名
          const lateDepositList = res.data.records.map(item => ({
            id: item.id,           // 滞留金ID
            amount: item.a,        // 金额(单位分)
            card_no: item.c,       // 卡号
            create_time: item.t,   // 滞留时间
            name: item.n,          // 姓名
            phone: item.p,         // 手机号
            // 保留原始字段以兼容现有代码
            a: item.a,
            c: item.c,
            t: item.t,
            n: item.n,
            p: item.p
          }));
          console.log("🔄 转换后的数据:", lateDepositList);
          return lateDepositList;
        } else {
          console.warn("⚠️ 获取滞留金列表失败:", res.msg);
          return [];
        }
      } catch (error) {
        console.error("❌ 检查滞留金失败:", error);
        return [];
      }
    },

    // 显示滞留金选择弹窗
    openLateDepositDialog(rechargeInfo) {
      this.currentRechargeInfo = rechargeInfo;
      this.lateDepositList = rechargeInfo.lateDepositList || [];
      this.showLateDepositDialog = true;
    },

    // 获取当前会员卡号
    getCurrentCardNo() {
      if (this.currentInfo) {
        // 兼容两种字段名格式：card_no（完整）和 c（缩写）
        return this.currentInfo.card_no || this.currentInfo.c || "";
      }
      // 如果是刷卡进入，需要从其他地方获取卡号
      return "";
    },

    // 处理滞留金选择确认
    handleLateDepositConfirm(result) {
      const { selectedDeposits, remainingAmount, rechargeInfo } = result;
      
      if (remainingAmount > 0) {
        // 还有剩余金额需要用扫码支付
        this.processPartialPayment(selectedDeposits, remainingAmount, rechargeInfo);
      } else {
        // 滞留金完全覆盖充值金额
        this.processFullLateDepositPayment(selectedDeposits, rechargeInfo);
      }
    },

    // 处理部分支付（滞留金 + 扫码）
    async processPartialPayment(selectedDeposits, remainingAmount, rechargeInfo) {
      console.log("部分支付", { selectedDeposits, remainingAmount, rechargeInfo });
      
      // 计算已使用的滞留金总额
      const usedAmount = parseFloat(rechargeInfo.makeAmt) - remainingAmount;
      this.$message.info(`使用滞留金 ¥${usedAmount.toFixed(2)}，剩余 ¥${remainingAmount.toFixed(2)} 需要扫码支付`);
      
      // 注意：部分支付场景下，会先通过扫码完成剩余金额的支付
      // 然后在支付成功后，会使用滞留金ID作为deposit_cnl进行充值
      // 跳转到扫码支付，并携带选中的滞留金信息
      this.startCustomerPaymentScan(remainingAmount.toString(), rechargeInfo.freeAmt, rechargeInfo.isCustom, selectedDeposits);
    },

    // 处理完全滞留金支付
    async processFullLateDepositPayment(selectedDeposits, rechargeInfo) {
      console.log("完全滞留金支付", { selectedDeposits, rechargeInfo });
      
      try {
        // 注意：如果选择了多个滞留金，只使用第一个滞留金的ID
        // 因为接口的deposit_cnl字段只接受单个滞留金ID
        if (selectedDeposits.length > 1) {
          console.warn("选择了多个滞留金，但只会使用第一个滞留金ID进行充值");
        }
        
        // 调用充值API，使用滞留金支付
        // 根据接口文档，如果是使用滞留金结账，deposit_cnl字段对应的是滞留金的id
        const params = {
          id: (this.currentInfo.id || this.vipIdOfSwiper) * 1,
          val_amt: rechargeInfo.makeAmt,
          free_amt: rechargeInfo.freeAmt,
          pt_amt: this.stepTwoInfo.sendPoint ? this.stepTwoInfo.sendPoint * 1 : 0,
          m: rechargeInfo.isCustom ? 2 : 1,
          oper_emp_id: this.$store.state.userInfo.emp_id * 1,
          deposit_cnl: selectedDeposits[0].id, // 使用第一个滞留金的ID作为充值渠道
          sales_emp_id: this.stepTwoInfo.personVal * 1,
          remark: this.stepTwoInfo.remark || ""
        };
        
        // 🔍 调试信息：打印滞留金充值参数
        console.log("🔍 [滞留金充值] 准备调用充值接口");
        console.log("📋 [滞留金充值] 接口参数详情:");
        console.log("  - 会员卡ID (id):", params.id, typeof params.id);
        console.log("  - 有价金额 (val_amt):", params.val_amt, typeof params.val_amt);
        console.log("  - 赠送金额 (free_amt):", params.free_amt, typeof params.free_amt);
        console.log("  - 赠送积分 (pt_amt):", params.pt_amt, typeof params.pt_amt);
        console.log("  - 充值模式 (m):", params.m, typeof params.m, params.m === 1 ? "规则模式" : "自定义模式");
        console.log("  - 操作员工 (oper_emp_id):", params.oper_emp_id, typeof params.oper_emp_id);
        console.log("  - 充值渠道/滞留金ID (deposit_cnl):", params.deposit_cnl, typeof params.deposit_cnl);
        console.log("  - 推荐人 (sales_emp_id):", params.sales_emp_id, typeof params.sales_emp_id);
        console.log("  - 备注 (remark):", params.remark, typeof params.remark);
        console.log("📦 [滞留金充值] 完整参数对象:", JSON.stringify(params, null, 2));
        console.log("🏷️ [滞留金充值] 选中的滞留金信息:", selectedDeposits.map(d => ({
          id: d.id,
          amount: d.amount || d.a,
          card_no: d.card_no || d.c
        })));
        
        console.log("🚀 [滞留金充值] 开始调用 reqMakeMoneyToCard 接口...");
        const res = await api_vip.reqMakeMoneyToCard(params);
        
        // 🔍 调试信息：打印接口响应
        console.log("📥 [滞留金充值] 接口响应:");
        console.log("  - 响应码 (code):", res.code, typeof res.code);
        console.log("  - 响应消息 (msg):", res.msg);
        console.log("  - 响应数据 (data):", res.data);
        console.log("📦 [滞留金充值] 完整响应对象:", JSON.stringify(res, null, 2));
        
        if (res.code == 1) {
          console.log("✅ [滞留金充值] 充值成功");
          this.$message.success("充值成功");
          this.onCancelDrawer();
          this.$emit('getTableData');
          
          // 充值成功后的跳转逻辑
          this.handlePostRechargeRedirect();
        } else {
          console.log("❌ [滞留金充值] 充值失败:", res.msg);
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.error("💥 [滞留金充值] 接口调用异常:", error);
        console.error("滞留金充值失败:", error);
        this.$message.error("充值失败，请重试");
      }
    },

    // 开始客人付款码扫描
    startCustomerPaymentScan(makeAmt, freeAmt, isCustom, selectedLateDeposits = []) {
      // 准备充值信息
      const rechargeInfo = {
        memberId: (this.currentInfo.id || this.vipIdOfSwiper) * 1,
        makeAmt: makeAmt,
        freeAmt: freeAmt,
        isCustom: isCustom,
        sendPoint: this.stepTwoInfo.sendPoint || 0,
        salesEmpId: this.stepTwoInfo.personVal * 1,
        remark: this.stepTwoInfo.remark || ""
      };
      
      this.currentRechargeInfo = rechargeInfo;
      this.currentPaymentAmount = makeAmt;
      this.currentSelectedLateDeposits = selectedLateDeposits;
      
      // 准备支付对话框所需的数据格式
      // 注意：searchList 返回的字段是缩写（c, n, p），searchDetail 返回的字段是完整名称
      this.paymentDialogRechargeInfo = {
        member: {
          id: (this.currentInfo.id || this.vipIdOfSwiper) * 1,
          card_no: this.currentInfo.card_no || this.currentInfo.c || "",
          name: this.currentInfo.name || this.currentInfo.n || "",
          bind_phone: this.currentInfo.bind_phone || this.currentInfo.p || ""
        },
        depositAmount: makeAmt,
        freeAmount: freeAmt,
        mode: isCustom ? 2 : 1,
        freePoints: this.stepTwoInfo.sendPoint || 0,
        salesEmpId: this.stepTwoInfo.personVal * 1,
        remark: this.stepTwoInfo.remark || ""
      };
      
      // 打开支付方式选择对话框
      this.showPaymentMethodDialog = true;
    },
    
    // 处理扫客人付款码
    handleScanCustomerPayment(payType) {
      console.log("===========================================");
      console.log("🎯 [会员充值] 接收到扫客人付款事件，支付类型:", payType);
      console.log("  - 当前充值信息:", this.currentRechargeInfo);
      console.log("  - 当前支付金额:", this.currentPaymentAmount);
      console.log("  - 选中的滞留金:", this.currentSelectedLateDeposits);
      console.log("  - this.$refs:", this.$refs);
      console.log("  - showCustomerPaymentScanDialog 修改前:", this.showCustomerPaymentScanDialog);
      
      this.selectedPayType = payType;
      // 打开扫码对话框
      this.showCustomerPaymentScanDialog = true;
      
      console.log("  - showCustomerPaymentScanDialog 修改后:", this.showCustomerPaymentScanDialog);
      
      // 强制更新视图
      this.$nextTick(() => {
        console.log("  - $nextTick 中 showCustomerPaymentScanDialog:", this.showCustomerPaymentScanDialog);
        console.log("  - DOM中的对话框:", document.querySelectorAll('.customer-payment-scan-dialog'));
      });
      console.log("===========================================");
    },

    // 处理支付成功
    handlePaymentSuccess(result) {
      console.log("支付成功", result);
      this.$message.success(`充值成功！金额：¥${result.amount}`);
      this.onCancelDrawer();
      this.$emit('getTableData');
      
      // 充值成功后的跳转逻辑
      this.handlePostRechargeRedirect();
    },

    changeStep(step = 1) {
      this.step = step;
    },

    // 充值成功后的智能跳转逻辑
    handlePostRechargeRedirect() {
      console.log("🎯 [跳转逻辑] 开始处理充值成功后的跳转");
      console.log("  - 当前路由:", this.$route.name);
      console.log("  - 用户权限状态:", this.$store.state.userInfo.authStatus);
      
      // 1. 如果是在会员管理页面，不跳转，留在当前页面
      if (this.$route.name === 'vipManager') {
        console.log("✅ [跳转逻辑] 会员管理页面充值，留在当前页面");
        return;
      }
      
      // 2. 如果是在收银系统中
      if (this.$store.state.userInfo.authStatus == 4) {
        console.log("🏪 [跳转逻辑] 收银系统中的充值");
        
        // 2.1 如果是在payOrder结账页面，需要检查是否还有未结订单
        if (this.$route.name === 'payOrder') {
          console.log("💰 [跳转逻辑] 在结账页面充值，检查卡台订单状态");
          this.checkOrderStatusAndRedirect();
        } else {
          // 2.2 其他收银页面，直接跳转到收银首页
          console.log("🏠 [跳转逻辑] 跳转到收银首页");
          this.$router.replace({ name: "moneyCard" });
        }
      }
    },

    // 检查订单状态并决定跳转
    checkOrderStatusAndRedirect() {
      const currentCardInfo = this.$store.state.orderInfo.currentCardInfo;
      console.log("🔍 [订单检查] 当前卡台信息:", currentCardInfo);
      
      if (!currentCardInfo || !currentCardInfo.bizStatus) {
        console.log("⚠️ [订单检查] 无卡台信息，跳转到收银首页");
        this.$router.replace({ name: "moneyCard" });
        return;
      }
      
      const bizStatus = currentCardInfo.bizStatus;
      console.log("📊 [订单检查] 卡台业务状态:", bizStatus);
      
      // bizStatus: 1-空台, 2-锁定, 3-预订, 4-开台, 5-点单未结账, 6-部分结账, 7-已结账
      if (bizStatus == 1 || bizStatus == 7) {
        // 空台或已结账，没有未结订单，跳转到收银首页
        console.log("✅ [订单检查] 无未结订单，跳转到收银首页");
        this.$router.replace({ name: "moneyCard" });
      } else {
        // 有未结订单，留在当前结账页面
        console.log("📋 [订单检查] 有未结订单，留在结账页面");
        // 不跳转，留在payOrder页面
      }
    },

    updateCurrentInfo(currentInfo) {
      this.currentInfo = { ...currentInfo };
    },
    onCancelDrawer() {
      this.changeStep(0);
      this.$emit("showOrHideDrawer");
    },

    // 读卡
    readCard() {
      let cardNo = "";
      try {
        setTimeout(() => {
          cardNo = atool.getCardNo();
          if (!cardNo) {
            if (this.show && this.step == 1) this.readCard();
          } else {
            this.getCardPwd(cardNo);
          }
        }, 1000);
      } catch (error) {
        console.log("cardNo信息获取失败：", error);
      }
    },

    async getCardPwd(cardNo) {
      const params = {
        card_no: cardNo //  string  卡号,这里是指实体卡卡号
      };
      try {
        const res = await api_vip.reqGetVipCardPwdMsg(params);
        if (res.code == 1) {
          this.getCardData(cardNo, res.data.p);
        } else {
          this.readCard();
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取卡密失败", error);
      }
    },
    
    // 通过查询返回的卡密码,读取卡内容数据
    getCardData(cardNo = '', password = '') {
      let cardInfoText = ''
      try {
        cardInfoText = atool.getCardData(password);  // 参数为密码
        if (cardInfoText.length == 0){
          this.readCard();
          return this.$message.warning('卡验证失败,请确认卡未离开读卡位置或是有效卡')
        }
        this.getVipId(cardNo, cardInfoText)
      } catch (error) {
        console.log('读取卡内容数据失败：', error)
        this.$message.warning('读取卡内容数据失败：' + error)
      }
    },

    // 获取vipId
    async getVipId(cardNo, cardInfoText) {
      const params = {
        card_no: cardNo, //    string   卡号,这里是指实体卡卡号
        dt: md5(cardInfoText)
          .toString()
          .toUpperCase() //     string    卡验证数据
      };

      try {
        const res = await api_vip.reqGetVipCardId(params);
        if (res.code == 1) {
          this.vipIdOfSwiper = res.data.id;
          this.changeStep(2);
        } else {
          this.readCard();
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("刷卡获取vipId失败", error);
      }
    },

    restHandle() {
      this.keyword = "";
      this.tableData = [];
      if(this.currentVipId) {
        // 通过新建会员后模态框中去充值点击进入(此处借用刷卡方式进入到充值详情)
        this.vipIdOfSwiper = this.currentVipId
        this.changeStep(2)
      } else {
        // 通过普通充值按钮点击进入
        this.changeStep(1);
        setTimeout(() => {
          this.$message.info("输入完整手机号或后四位后，方可自动搜索");
        }, 200);
      }
    }
  },
  mounted() {
    console.log("🎯 [会员充值] 组件已挂载");
    console.log("  - paymentMethodDialogRef:", this.$refs.paymentMethodDialogRef);
    
    // 监听所有事件（调试用）
    this.$on('scanCustomerPayment', (payType) => {
      console.log("🎯 [会员充值] $on 捕获到 scanCustomerPayment 事件:", payType);
    });
  },
  props: {
    showDrawer: {
      default: false // 是否显示drawer
    },
    currentVipId: {
      default: ''
    }
  },
  components: {
    searchList,
    searchDetail,
    lateDepositDialog,
    paymentMethodDialog,
    customerPaymentScanDialog
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.restHandle();
        }
      },
      immediate: true
    },
    keyword() {
      this.changeStep(1);
    },
    step: {
      handler(newVal) {
        if (newVal == 1) {
          this.currentInfo = {};
          this.vipIdOfSwiper = "";
          this.readCard();
        } else if (newVal == 2) {
          this.$nextTick(() => {
            this.$refs.vipDetailRef &&
              this.$refs.vipDetailRef.init &&
              this.$refs.vipDetailRef.init();
          });
        }
      },
      immediate: true
    }
  }
};
</script>

<style scoped lang="less">
@import "../../../../style/common/elementDrawerVip.less";
@import "../../../../style/common/elementDrawerHeaderAndSession.less";
@import "../../../../style/vip/vipBtn.less";
@import "../../../../style/common/elementFormBtnVip.less";
@import "../../../../style/common/scrollBarVip.less";
@import "../../../../style/vip/vipBtn.less";
</style>
<style lang="less" scoped>
.red {
  font-size: 14px;
  color: #e0304f;
}
</style>

<style lang="less">
// 充值弹窗响应式样式 - 半屏效果（固定600px，不使用响应式避免跳动）
/deep/ .vip-recharge-drawer-small {
  &.el-drawer.rtl {
    width: 800px !important;
    max-width: 95% !important; // 小屏幕时不超出屏幕
    transition: none !important; // 🔥 禁用过渡动画，避免跳动
  }
  
  // 禁用 Drawer 内容的过渡动画
  .el-drawer__body {
    transition: none !important;
  }
}
</style>