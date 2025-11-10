<template>
  <div>
    <!-- 手机号选择会员卡 -->
    <el-drawer
      :title="type == 1 ? '服务码选择会员卡' : '手机号选择会员卡'"
      :visible.sync="show"
      :append-to-body="true"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="88%"
    >
      <div class="choose-vip-card">
        <div class="container">
          <div class="left">
            <div class="session">
              <div class="form">
                <template v-if="type == 1">
                  <div class="row" layout="row" layout-align="start center">
                    <div class="label">
                      <span class="red">*</span>
                      <span>服务码序列号:</span>
                    </div>
                    <div class="value" layout="row" layout-align="start center">
                      <input
                        type="text"
                        v-model="validateVal"
                        placeholder="请输入服务码序列号"
                      />
                      <div class="btn" @click="getTableData">搜索</div>
                    </div>
                  </div>
                </template>
                <template v-else>
                  <div class="row" layout="row" layout-align="start center">
                    <div class="label">
                      <span class="red">*</span>
                      <span>手机号:</span>
                    </div>
                    <div class="value" layout="row" layout-align="start center">
                      <input
                        type="text"
                        v-model="phoneNumVal"
                        placeholder="请输入手机号"
                      />
                      <div
                        v-if="needValidateCode"
                        class="btn"
                        :class="{ disabled: count != 0 }"
                        @click="sendPhoneMessage"
                      >
                        {{ btnText }}
                      </div>
                      <div v-else class="btn" @click="getTableData">搜索</div>
                    </div>
                  </div>
                  
                  <!-- 历史手机号列表 -->
                  <div class="row" layout="row" layout-align="start center" v-if="historyPhoneNums.length > 0">
                    <div class="label">
                      <span>当台常用手机号:</span>
                    </div>
                    <div class="value" layout="row" layout-align="start center">
                      <div class="phone-list">
                        <div 
                          v-for="(phone, index) in historyPhoneNums" 
                          :key="index"
                          :class="['phone-item', { selected: selectedPhone === phone }]"
                          @click="selectPhoneNum(phone)"
                        >
                          {{ phone }}
                        </div>
                        <p class="phone-tips">点击手机号，上方的输入框直接填充该手机号，并自动搜索会员卡</p>
                      </div>
                    </div>
                  </div>
                  
                  <div class="row" layout="row" layout-align="start center">
                    <div class="label">
                      <span class="red" v-if="needValidateCode">*</span>
                      <span>{{needValidateCode ? '验证码:' : ''}}</span>
                    </div>
                    <div class="value" layout="row" layout-align="start center" v-if="needValidateCode">
                      <input
                        type="text"
                        v-model="validateVal"
                        placeholder="请输入验证码"
                      />
                      <div class="btn" @click="getTableData">搜索</div>
                    </div>
                  </div>
                </template>
              </div>

              <p class="tips red m-b-2">提示：卡可用金额：本次订单可使用当前会员卡的支付的金额；
                由于某些商品不允许使用会员卡储值金额、赠送金额或不能用会员卡支付，
                所以可能导致卡余额大于订单金额但卡可用余额小于订单金额</p>
              <div class="table">
                <div class="thead">
                  <div
                    class="tr"
                    layout="row"
                    layout-align="space-between center"
                  >
                    <div class="th">序号</div>
                    <div class="th">会员卡号</div>
                    <div class="th">会员姓名</div>
                    <div class="th">会员卡金额</div>
                    <div class="th">会员卡储值余额</div>
                    <div class="th">会员卡赠送余额</div>
                    <div class="th">卡可用余额</div>
                    <div class="th">卡可用储值余额</div>
                    <div class="th">卡可用赠送余额</div>
                    <div class="th">本次使用金额</div>
                    <div class="th">操作</div>
                  </div>
                </div>
                <div class="tbody">
                  <div
                    class="tr"
                    layout="row"
                    layout-align="space-between center"
                    v-for="(item, index) in tableData"
                    :key="index"
                  >
                    <div class="td one-txt-cut">
                      {{ index + 1 }}
                    </div>
                    <div class="td one-txt-cut">{{ item.c }}</div>
                    <div class="td one-txt-cut">{{ item.n }}</div>
                    <div class="td one-txt-cut">{{ (((item.vb || 0)* 1  + (item.fb || 0)* 1 ) / 100).toFixed(2)  }}</div>
                    <div class="td one-txt-cut">{{  ((item.vb || 0)/100).toFixed(2)  }}</div>
                    <div class="td one-txt-cut">{{  ((item.fb || 0)/100).toFixed(2)  }}</div>
                    <div class="td one-txt-cut">
                      {{ (((item.uv || 0)* 1  + (item.uf || 0)* 1 ) / 100).toFixed(2) }}
                    </div>
                    <div class="td one-txt-cut">{{ ((item.uv || 0)/100).toFixed(2) }}</div>
                    <div class="td one-txt-cut">{{ ((item.uf || 0)/100).toFixed(2) }}</div>
                    <div class="td one-txt-cut">
                      <div>
                        <input
                          style="width: 80px"
                          type="text"
                          @input="changeInput(item)"
                          v-model="item.useAmt"
                          placeholder="使用金额"
                        />
                      </div>
                    </div>
                    <div class="td one-txt-cut">
                      <el-button
                        type="primary"
                        @click="intoChannel(item)"
                        size="small"
                        style="
                          width: 50px;
                          padding-top: 0px !important;
                          height: 20px;
                          line-height: 20px;
                        "
                        >添加</el-button
                      >
                    </div>
                  </div>
                  <p
                    v-if="tableData.length == 0"
                    class="m-t-10 fs14"
                    style="text-align: center"
                  >
                    暂无数据
                  </p>
                </div>
              </div>
            </div>
          </div>
          <div class="middle">
            <div class="arrow"></div>
          </div>
          <div class="right flex flex-col">
            <div class="right-top">
              <p>
                <span>本次应收:</span>
                <span class="amt all-amt">￥{{ allAmt }}</span>
              </p>
              <p>
                <span>已收:</span>
                <span class="amt">￥{{ chooseAmt }}</span>
              </p>
            </div>
            <div class="right-bottom">
              <ul>
                <li
                  v-for="(item, i) in hasChoosedListArr"
                  :key="i"
                  layout="row"
                  layout-align="space-between center"
                >
                  <div class="pay-detail">
                    <!-- 会员卡 -->
                    <p>{{ "卡号：" + item.n + " " + item.c }}:</p>

                    <!-- 会员卡落单/会员卡 -->
                    <div v-if="item.pid == 5 || item.pid == 500">
                      <p
                        class="amt"
                        layout="row"
                        layout-align="start center"
                        style="font-size: 13px"
                      >
                        <span style="width: 76px">金额:</span>￥{{
                          (item.pa * 1).toFixed(2)
                        }}
                      </p>
                      <p
                        class="amt text-wrap"
                        layout-align="start center"
                        style="font-size: 13px"
                      >
                        <span>{{`(储: ￥${(item.pv*1).toFixed(2)}; `}}</span>
                        <span>{{`赠: ￥${(item.pf*1).toFixed(2)})`}}</span>
                      </p>
                      <p
                        class="amt"
                        layout="row"
                        layout-align="start center"
                        style="font-size: 13px"
                      >
                      <span style="width: 76px">赠送积分:</span>{{
                          !isNaN(item.p ) ? `￥${item.p}` : item.p
                        }}
                      </p>
                    </div>
                    <p v-else class="amt">￥{{ item.chooseAmt }}</p>
                  </div>
                  <div class="close">
                    <i
                      class="el-icon-error"
                      @click.stop="delPayList(item.id)"
                    ></i>
                  </div>
                </li>
              </ul>
            </div>
          </div>
        </div>
        <div class="form-btn" layout="row" layout-align="center center">
          <el-button type="info" @click="onCancelDrawer">关闭</el-button>
          <el-button type="primary" @click="onSubmit">返回</el-button>
        </div>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_money from "@/api/money";
import api_vip from "@/api/vip";
import api_order from "@/api/order";
import common_money from "@/utils/common/money";
export default {
  data() {
    return {
      timer: null,
      show: false,
      count: 0,
      phoneNumVal: "",
      validateVal: "",
      authCodeStr: "",
      tableData: [],
      hasChoosedListArr: [], // 选择好支付方式的列表（购物车）
      historyPhoneNums: [], // 历史手机号列表
      selectedPhone: "", // 当前选中的历史手机号
    };
  },
  methods: {
    init() {
      this.interValHandle();
      this.phoneNumVal = "";
      this.validateVal = "";
      this.tableData = [];
      this.hasChoosedListArr = []; //
      this.historyPhoneNums = []; // 重置历史手机号
      this.selectedPhone = ""; // 重置选中状态
      this.getChoosePayList();
      this.loadHistoryPhoneNums(); // 加载历史手机号
    },
    
    // 加载历史手机号
    async loadHistoryPhoneNums() {
      try {
        const seatId = this.$store.state.orderInfo.currentCardInfo.seatId;
        if (!seatId) {
          console.log("未找到卡台ID，无法加载历史手机号");
          return;
        }
        
        const res = await api_order.get_csm_phone_nums({
          id: seatId * 1 // CsmId 流水Id
        });
        
        console.log("res:", res);
        if (res.code === 1 && res.data && res.data.records) {
          this.historyPhoneNums = res.data.records;
          console.log("加载历史手机号成功:", this.historyPhoneNums);
        } else {
          this.historyPhoneNums = [];
          console.log("未找到历史手机号或接口返回失败");
        }
      } catch (error) {
        console.error("加载历史手机号失败:", error);
        this.historyPhoneNums = [];
      }
    },
    
    // 选择历史手机号
    async selectPhoneNum(phone) {
      this.selectedPhone = phone; // 设置选中状态
      this.phoneNumVal = phone;
      if(this.phoneNumVal) {
        // 直接搜索，跳过验证码流程
        await this.getTableDataDirectly();
      }
    },
    
    // 直接搜索（不需要验证码）
    async getTableDataDirectly() {
      if(!this.phoneNumVal) return;
      const params = {
        sms_auth_code: 'NO_NEED_VALIDATE', // 历史手机号不需要验证码
        phone_num: this.phoneNumVal
      };

      try {
        const res = await api_money.reqGetVipCardFormPhoneNum(params);
        if (res.code == 1) {
          this.tableData = (res.data.records || []).map((item) => ({
            ...item,
            chooseAmt: "",
          }));
          this.cardPayInfo();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("通过手机号查询会员卡失败", error);
      }
    },
    interValHandle() {
      const storageSecondCount = this.$sessionStorage.getItem(
        "secondCountFormChooseVip"
      ); // 获取发送短信时的时间戳
      const now = +new Date();
      const oneMinute =
        +new Date("2023/05/25 12:01:00") - +new Date("2023/05/25 12:00:00");
      if (now - storageSecondCount < oneMinute) {
        // 倒计时为结束接着倒计时
        this.count =
          ((oneMinute - (now - storageSecondCount)) / (oneMinute / 60)).toFixed(
            0
          ) * 1;
        this.loopSecond();
      } else {
        this.count = 0;
      }
    },
    // 发送验证码
    async sendPhoneMessage() {
      if (this.count != 0) return;
      if(!this.needValidateCode) return; // 如果不需要验证码则直接返回
      
      this.count = 60
      const params = {
        t: 200, //  int   200  验证获取客人会员卡结账
        m: this.phoneNumVal //  string   手机号
      };
      if (params.m.length != 11)
        return this.$message.warning("请输入正确的11位手机号");
      try {
        const res = await api_vip.reqSendPhoneMsg(params);
        if (res.code == 1) {
          this.$message.success("验证码发送成功");
          this.count--;
          this.loopSecond();
          this.$sessionStorage.setItem(
            "secondCountFormChooseVip",
            (+new Date()).toString()
          );
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("发送验证码失败", error);
      }
    },

    async intoChannel(item) {
      if (item.useAmt * 1 <= 0) {
        this.$message.warning("请输入有效的金额");
        return;
      }
      const param = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
        auth_type: 2,
        auth_code: this.authCodeStr,
        mb_card_id: item.id,
        amt: item.useAmt * 100,
        phone_num: this.phoneNumVal
      };

      const res = await api_money.reqUpdateVipCardIntoBillChannel(param);
      if (res.code == 1 || res.code == 2) {
        this.$message.success("加入成功");
        // 先更新已收金额，再自动填充卡使用金额
        await this.getChoosePayList();
        this.cardPayInfo();
      } else {
        this.$message.warning(res.msg);
      }
    },
    async validatePhoneInfo() {
      const params = {
        m: this.phoneNumVal, //   string    手机号
        c: this.validateVal, //    string   验证码
      };

      if (params.c.length != 5) {
        this.$message.warning("请输入正确的五位验证码");
        return false;
      }
      try {
        const res = await api_vip.reqValidatePhoneMsg(params);
        if (res.code == 1) {
          this.authCodeStr = res.data.c;
          return res.data.c;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("验证手机验��码失败", error);
      }
    },

    async validateValidateInfo() {
      const params = {
        srv_code: this.validateVal, //    string   付款码
      };
      if (params.srv_code.length != 6) {
        this.$message.warning("请输入正确的六位服务码序列号");
        return false;
      }
      try {
        const res = await api_money.reqGetVipCardFormValidate(params);
        if (res.code == 1) {
          this.phoneNumVal = res.data.p;
          this.authCodeStr = res.data.c;
          return res.data.c;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("验证手机验证码失败", error);
      }
    },

    // 倒计时
    loopSecond() {
      if (this.timer) {
        clearInterval(this.timer);
        this.timer = null;
      }
      this.timer = setInterval(() => {
        this.count--;
        if (this.count == 0) {
          clearInterval(this.timer);
        }
      }, 1000);
    },

    async getTableData() {
      let result = true;
      if(this.type !== 1) { // 手��号方式
        if(this.needValidateCode) {
          // 需要验证码时才验证
          result = await this.validatePhoneInfo();
          if(!result) return;
        }
      } else {
        // 服务码方式
        result = await this.validateValidateInfo();
        if(!result) return;
      }

      const params = {
        sms_auth_code: this.needValidateCode ? result : 'NO_NEED_VALIDATE', // 不需要验证码时传特殊值
        phone_num: this.phoneNumVal
      };

      try {
        const res = await api_money.reqGetVipCardFormPhoneNum(params);
        if (res.code == 1) {

          this.tableData = (res.data.records || []).map((item) => ({
            ...item,
            // checked: (res.data.records || []).length == 1,
            chooseAmt: "",
            // disabled: false,
          }));

          this.cardPayInfo();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("通过手机号查询会员卡失败", error);
      }
    },

    async cardPayInfo(){
      const cardIds = this.tableData.map((item) => item.id * 1);
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
        all_mb_card_ids: cardIds,
      };
      const res = await api_money.reqGetVipCardAmountInfo(params);
      this.tableData = this.tableData.map((item) => {
        const i = res.data.records.find((a) => a.id == item.id);
        return { ...item, ...i };
      });
      // 获取卡信息后，自动填充使用金额
      this.autoFillCardAmounts();
    },
    
    // 自动填充会员卡使用金额
    autoFillCardAmounts() {
      if (!this.tableData || this.tableData.length === 0) {
        return;
      }
      
      // 获取待支付金额（单位：元）
      // 待支付金额 = 本次应收金额 - 已收金额
      const allAmt = parseFloat(this.allAmt) || 0;
      const chooseAmt = parseFloat(this.chooseAmt) || 0;
      const needPayAmount = allAmt - chooseAmt;
      
      if (needPayAmount <= 0) {
        // 如果已收金额已经大于等于应收金额，清空所有卡的使用金额
        this.tableData.forEach(item => {
          item.useAmt = "";
        });
        return;
      }
      
      // 先清空所有卡的使用金额
      this.tableData.forEach(item => {
        item.useAmt = "";
      });
      
      let remainingAmount = needPayAmount; // 剩余需要支付的金额（单位：元）
      
      // 遍历所有会员卡，自动分配使用金额
      for (let i = 0; i < this.tableData.length; i++) {
        const card = this.tableData[i];
        
        // 计算当前卡的可用余额（单位：元）
        // 使用 uv 和 uf 字段，与表格显示的"卡可用余额"保持一致
        // uv: 可用储值余额（单位：分），uf: 可用赠送余额（单位：分）
        const valAmt = (card.uv || 0) * 1; // 可用储值余额（分）
        const freeAmt = (card.uf || 0) * 1; // 可用赠送余额（分）
        const maxAvailable = valAmt + freeAmt; // 总可用余额（分）
        const availableAmount = maxAvailable / 100; // 转换为元
        
        if (availableAmount <= 0) {
          // 如果当前卡没有可用余额，跳过
          continue;
        }
        
        if (remainingAmount <= 0) {
          // 如果已经满足支付金额，停止分配
          break;
        }
        
        // 计算当前卡应该使用的金额
        let useAmount = 0;
        if (availableAmount >= remainingAmount) {
          // 当前卡余额足够支付剩余金额
          useAmount = remainingAmount;
          remainingAmount = 0;
        } else {
          // 当前卡余额不足，使用全部可用余额
          useAmount = availableAmount;
          remainingAmount -= availableAmount;
        }
        
        // 将使用金额填入输入框（保留两位小数）
        this.$set(card, 'useAmt', useAmount.toFixed(2));
      }
    },

    changeInput(item) {
      const choosedAmt = item.useAmt;
      const max = item.fa * 1 + item.va * 1;
      if (isNaN(item.useAmt)) {
        this.$message.warning("请输入数字");
        item.useAmt =
          item.useAmt.length > 1
            ? item.useAmt.slice(0, item.useAmt.length - 1)
            : "";
      } else if (choosedAmt * 1 > max) {
        this.$message.warning("当前会员卡最大可用金额为" + max);
        item.useAmt =
          item.useAmt.length > 1
            ? item.useAmt.slice(0, item.useAmt.length - 1)
            : "";
      }
    },
    // 提交
    async onSubmit() {
      this.$emit("nextHandle");
      this.onCancelDrawer();
    },
    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
      this.getChoosePayList();
    },

    // 获取已选择好的支付渠道（购物车）
    async getChoosePayList() {
      try {
        const res = await api_money.reqGetCardPayList({
          id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64   卡台Id
        });
        if (res.code === 1) {
          const hasChoosedListArr = res.data || [];
          hasChoosedListArr.forEach((el) => {
            el.chooseAmt = el.pa && (el.pa * 1).toFixed(2);
            el.choosedPayInfo = common_money.getPayInfo(el.pid);
          });
          this.hasChoosedListArr = hasChoosedListArr;
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("支付渠道获取失败", error);
      }
    },
    // 删除已选择好的支付渠道
    async delPayList(id) {
      try {
        const res = await api_money.reqDelPayListFromShopping({
          seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, // int64   卡台Id
          id: id * 1, //         int64      //Id 支付Id
        });
        if (res.code === 1) {
          this.$message.success("删除成功");
          this.getChoosePayList();
          this.cardPayInfo();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("删除已选择好的支付渠道失败", error);
      }
    },
  },
  mounted() {},
  props: {
    showDrawer: {
      default: false, // 是否显示drawer
    },
    maxPayMoney: {
      default: "0",
    },
    allAmt: {
      default: "0",
    },
    type: {
      default: 1, // 1:二维码序列号查找  2:手机号查找
    },
    payId: {
      default: "",
    },
  },
  beforeDestroy() {
    if(this.timer){
      clearInterval(this.timer);
    }
  },
  computed: {
    btnText() {
      return this.count == 0 ? "发送验证码" : this.count + "s后发送";
    },
    // 已收金额
    chooseAmt() {
      let chooseAmt = 0;
      this.hasChoosedListArr.forEach((el) => {
        chooseAmt += el.chooseAmt * 1;
      });
      return chooseAmt.toFixed(2);
    },
    needValidateCode() {
      const vipSettleRule = this.$store.state.cardPageInfo.resResultDataObj.vipSettleRule || []
      return !vipSettleRule.find(rule => rule.rule_id*1 === 10 && rule.status*1 === 1)
    }
  },
  watch: {
    showDrawer: {
      handler(newVal) {
        this.show = newVal;
        if (newVal) {
          this.init();
        }
      },
      immediate: true,
    },
  },
};
</script>

<style scoped lang="less">
@import "../../style/common/elementDrawer.less";
@import "../../style/common/elementDrawerHeaderAndSession.less";
@import "../../style/common/elementFormBtn.less";
@import "../../style/common/scrollBar.less";
</style>
<style lang="less" scoped>
.choose-vip-card {
  padding: 20px;
  color: rgba(255, 255, 255, 8);
  font-size: 14px;

  .red {
    color: #ff2f64;
  }

  .form {
    .row {
      padding: 10px 20px;
      
      // 标签列：固定最小宽度
      .label {
        flex-shrink: 0;
        min-width: 120px;
        white-space: nowrap;
      }
      
      // 值列：占据剩余空间
      .value {
        padding-left: 10px;
        flex: 1;
        
        input {
          padding: 0 10px;
          box-sizing: border-box;
          width: 200px;
          height: 30px;
          border-radius: 8px;
          box-sizing: border-box;
          border: 1px solid rgba(255, 255, 255, 0.15);
        }

        .btn {
          margin-left: 10px;
          background-color: #4b89ff;
          border-radius: 4px;
          width: 90px;
          height: 30px;
          line-height: 30px;
          text-align: center;
          cursor: pointer;

          &.disabled {
            background-color: #aaa;
            color: #eee;
            cursor: no-drop;
          }
        }
        
        // 历史手机号列表样式
        .phone-list {
          display: flex;
          flex-wrap: wrap;
          align-items: center;
          gap: 8px;
          width: 100%;
          
          .phone-item {
            padding: 6px 15px;
            background-color: rgba(255, 255, 255, 0.08);
            border-radius: 6px;
            font-size: 14px;
            color: #fff;
            cursor: pointer;
            transition: all 0.2s;
            border: 1px solid rgba(255, 255, 255, 0.15);
            
            &:hover {
              background-color: rgba(255, 255, 255, 0.12);
              border-color: rgba(255, 255, 255, 0.25);
              transform: translateY(-1px);
              box-shadow: 0 2px 8px rgba(255, 255, 255, 0.1);
            }
            
            &:active {
              transform: translateY(0);
            }
            
            // 选中状态 - 蓝色高亮
            &.selected {
              background-color: #409eff;
              border-color: #409eff;
              color: #fff;
              box-shadow: 0 2px 8px rgba(64, 158, 255, 0.4);
              
              &:hover {
                background-color: #66b1ff;
                border-color: #66b1ff;
              }
            }
          }
          
          .phone-tips {
            width: 100%;
            margin: 8px 0 0 0;
            font-size: 12px;
            color: #e6a23c;
            line-height: 18px;
          }
        }
      }
    }
  }

  .tips {
    line-height: 20px;
  }

  .container {
    display: flex;
    .left {
      flex: 70;
      height: 100%;
      .table {
        .thead .tr {
          background-color: rgba(255, 255, 255, 0.04);
        }
        .tr {
          height: 40px;
          &:nth-child(2n) {
            background-color: rgba(255, 255, 255, 0.04);
          }
        }

        .th:nth-child(1),
        .td:nth-child(1) {
          width: 40px;
        }
        .th:nth-child(2),
        .td:nth-child(2) {
          width: 6%;
        }
        .th:nth-child(3),
        .td:nth-child(3) {
          width: 10%;
        }
        .th:nth-child(4),
        .td:nth-child(4) {
          width: 10%;
        }
        .th:nth-child(5),
        .td:nth-child(5) {
          width: 10%;
        }
        .th:nth-child(6),
        .td:nth-child(6) {
          width: 10%;
        }
        .th:nth-child(7),
        .td:nth-child(7) {
          width: 9%;
        }
      }
      .th:nth-child(8),
      .td:nth-child(8) {
        width: 9%;
      }
      .th:nth-child(9),
      .td:nth-child(9) {
        width: 9%;
      }
      .th:nth-child(10),
      .td:nth-child(10) {
        width: 12%;
        input {
          width: 100%;
          padding: 0 10px;
          box-sizing: border-box;
          height: 26px;
          border-radius: 6px;
          &:focus {
            border-color: #4b89ff;
          }
        }
      }
      .th:nth-child(11),
      .td:nth-child(11) {
        width: 6%;
      }
    }

    .middle {
      position: relative;
      width: 40px;
      height: calc(100vh - 150px);
      border-left: 1px solid rgba(255, 255, 255, 0.2);
      .arrow {
        width: 0;
        height: 0;
        border-top: 14px solid transparent;
        border-bottom: 14px solid transparent;
        border-left: 14px solid white;
        position: absolute;
        top: 50%;
        left: 22px;
        transform: translateY(-50%);
      }
    }
    .middle::before {
      content: "";
      width: 20px;
      height: 15px;
      background: white;
      position: absolute;
      left: 2px;
      top: 50%;
      transform: translateY(-50%);
    }

    .right {
      flex: 27;
      border-left: 1px solid rgba(255, 255, 255, 0.2);

      &-top {
        p {
          padding: 10px 20px;
          font-size: 14px;
          line-height: 14px;

          .amt {
            display: block;
            padding-top: 10px;
            font-size: 26px;
            font-weight: 500;
            line-height: 26px;
          }
          .text-wrap {
            display: flex;
          }

          @media (max-width: 222px) {
          .text {
            flex-direction: column;
          }
        }
          .all-amt {
            color: #1edaad;
          }
        }
      }
      // 结账种类列表
      &-bottom {
        margin-top: 20px;

        ul {
          padding: 0 10px;
          box-sizing: border-box;
          height: calc(100vh - 294px);
          overflow-y: auto;

          li {
            margin-bottom: 6px;
            padding: 10px 10px 10px 14px;
            background: rgba(255, 255, 255, 0.04);
            border-radius: 4px;
            border: 1px solid rgba(255, 255, 255, 0.08);

            .pay-detail {
              p {
                font-size: 14px;
                font-weight: 400;
                color: #ffffff;
                line-height: 14px;

                &.amt {
                  font-weight: 500;
                  margin-top: 10px;
                  color: #ffffff;
                  font-size: 18px;
                }
              }
            }

            .close {
              i.el-icon-error {
                cursor: pointer;
                font-size: 20px;
                color: #ff2f64;
              }
            }
          }
        }
      }
    }
  }
}

/deep/.el-checkbox__label {
  color: rgba(255, 255, 255, 8);
}
</style>
