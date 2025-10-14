<template>
  <div>
    <!-- 会员充值 -->
    <el-drawer
      title="充值"
      :visible.sync="show"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="1000"
    >
      <div class="session p-5">
        <div class="search">
          <el-input
            size="small"
            v-model="keyword"
            placeholder="输入手机号后四位后，方可搜索"
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

    <!-- 客人付款码扫描弹窗 -->
    <customerPaymentScanDialog
      v-model="showCustomerPaymentScanDialog"
      :paymentAmount="currentPaymentAmount"
      :rechargeInfo="currentRechargeInfo"
      :selectedLateDeposits="currentSelectedLateDeposits"
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
      showCustomerPaymentScanDialog: false, // 显示客人付款码扫描弹窗
      currentPaymentAmount: "0.00", // 当前支付金额
      currentSelectedLateDeposits: [], // 当前选中的滞留金
    };
  },
  methods: {
    async searchHandle(e) {
      if (typeof e === "object" && this.keyword.length != 4)
        return this.$message.warning("输入手机号后四位，方可搜索");
      if (this.keyword.length != 4) return this.tableData = [];
      const params = {
        phone: this.keyword //    string   手机号后4位
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
        
        if (lateDepositList && lateDepositList.length > 0) {
          // 有滞留金，显示滞留金选择弹窗
          this.openLateDepositDialog({
            makeAmt,
            freeAmt,
            isCustom,
            lateDepositList
          });
        } else {
          // 没有滞留金，直接进入扫码流程
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
      
      try {
        const res = await api_vip.reqMakeMoneyToCard(params);
        if (res.code == 1) {
          this.$message.success("充值成功");
          this.onCancelDrawer();
          this.$emit('getTableData')
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("充值失败", error);
      } finally {
        this.charging = false;
      }
    },

    // 检查滞留金
    async checkLateDeposit() {
      try {
        // 调用新API检查当前会员是否有可用的充值滞留金
        // 根据接口文档，该接口不需要传入参数
        const res = await api_vip.reqGetDepositLateListForDeposit({});
        
        if (res.code === 1 && res.data && res.data.records) {
          // 转换数据格式：接口返回的字段名(a, c, t)转换为组件使用的字段名
          const lateDepositList = res.data.records.map(item => ({
            id: item.id,           // 滞留金ID
            amount: item.a,        // 金额(单位分)
            card_no: item.c,       // 卡号
            create_time: item.t    // 滞留时间
          }));
          return lateDepositList;
        } else {
          console.warn("获取滞留金列表失败:", res.msg);
          return [];
        }
      } catch (error) {
        console.error("检查滞留金失败:", error);
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
      if (this.currentInfo && this.currentInfo.card_no) {
        return this.currentInfo.card_no;
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
        
        const res = await api_vip.reqMakeMoneyToCard(params);
        if (res.code == 1) {
          this.$message.success("充值成功");
          this.onCancelDrawer();
          this.$emit('getTableData');
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
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
      this.showCustomerPaymentScanDialog = true;
    },

    // 处理支付成功
    handlePaymentSuccess(result) {
      console.log("支付成功", result);
      this.$message.success(`充值成功！金额：¥${result.amount}`);
      this.onCancelDrawer();
      this.$emit('getTableData');
    },

    changeStep(step = 1) {
      this.step = step;
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
          this.$message.info("输入手机后四位后，方可自动搜索");
        }, 200);
      }
    }
  },
  mounted() {},
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