<template>
  <div class="terminal-rules">
    <h4 class="m-b-2">超时时间配置</h4>
    <div class="m-l-4 fs14">
      <div>
        <span>线上下单后</span>
        <el-input style="width:150px" v-model="timeLine" type="text" @input="inputHandle" />
        <span>分钟未结账发出提醒</span>
      </div>
      <div>
        <span>线下下单后</span>
        <el-input style="width:150px" v-model="time" type="text" @input="inputHandle" />
        <span>分钟未结账发出提醒</span>
        <p class="red-color">输入0则默认为不提醒</p>
      </div>
    </div>

    <h4 class="m-b-2">限制预定系统显示金额</h4>
    <div class="m-l-4 fs14">
      <div>
        <span>限制预定系统显示金额</span>
        <el-switch v-model="notShowAmt"
                   active-text="是"
                   inactive-text="否"
        ></el-switch>
        <p class="red-color">开关开启后预定系统卡台列表和报表中不显示金额</p>
      </div>
    </div>

    <h4 class="m-b-2">扫码点单配置</h4>
    <div class="m-l-4 fs14">
      <span>客人扫码点单未达低消不允许下单:</span>
      <el-switch v-model="scanOrderMustDx"
                 active-text="是"
                 inactive-text="否"
      ></el-switch>
      <p class="red-color">开关开启后，客人扫码点单时，如果点单金额未达到当前卡台的低消，则不允许下单</p>
    </div>
    <div class="m-l-4 fs14">
      <span>扫码点单超时未支付自动退单:</span>
      <el-switch v-model="timeoutAutoBack"
                 active-text="是"
                 inactive-text="否"
      ></el-switch>
      <p class="red-color">开关开启后，客人扫码点单如超时未支付，则系统自动取消该订单</p>
      <div style="margin-bottom: 20px" v-if="timeoutAutoBack">
        <span>超时</span>
        <el-input style="width:150px" v-model="timeoutAutoBackTime" type="text" @input="inputHandle" />
        <span>分钟未支付自动退单</span>
      </div>
    </div>

    <h4 class="m-b-2">营业日时间配置</h4>
    <div class="m-l-4 fs14">
      <div>
        <span>是否自动结束营业日：</span>
        <el-radio v-model="radio" label="1">是</el-radio>
        <el-radio v-model="radio" label="2">否</el-radio>
      </div>
      <div>
        <span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;选择结束时间：</span>
        <el-select
            style="width:120px"
            :disabled="radio==2"
            v-model="chooseTime.hour"
            placeholder="请选择小时"
        >
          <el-option
              v-for="item in chooseTime.hourOption"
              :key="item.value"
              :label="item.label"
              :value="item.value"
          ></el-option>
        </el-select>&nbsp;时
        <el-select
            style="width:120px"
            :disabled="radio==2"
            v-model="chooseTime.minute"
            placeholder="请选择分钟"
        >
          <el-option
              v-for="item in chooseTime.minuteOption"
              :key="item.value"
              :label="item.label"
              :value="item.value"
          ></el-option>
        </el-select>&nbsp;分
      </div>
    </div>

    <h4 class="m-b-2 m-t-3">咨客清台配置</h4>
    <div class="fs14">
      <div>
        <span class="m-l-4">关闭咨客台清台功能：</span>
        <el-switch v-model="canClearCard"
                   active-text="是"
                   inactive-text="否"
        ></el-switch>
      </div>
    </div>

    <h4 class="m-b-2 m-t-3">下单出品配置</h4>
    <div class="fs14">
      <div>
        <span class="m-l-4">下单自动出品：</span>
        <el-switch v-model="orderAutoMake"
                   active-text="是"
                   inactive-text="否"
        ></el-switch>
      </div>
    </div>
    <h4 class="m-b-2 m-t-3">账户密码管理</h4>
    <div class="fs14">
      <div>
        <span class="m-l-4">禁止自助修改密码：</span>
        <el-switch v-model="disableChgPass"
                   active-text="是"
                   inactive-text="否"
        ></el-switch>
      </div>
    </div>

    <div style="position: fixed;
            bottom: 16px;
            left: 450px;"
    >
      <el-button class="m-l-10 m-t-10" type="primary" @click.native="submitHandle">保存</el-button>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      time: 0,
      timeLine: 0,
      radio: "1", // 是否开启自动结束营业日 1：是  2：否
      canClearCard: true, // 咨客是否可清台  true禁止  false不禁止
      orderAutoMake: true, // 下单自动出品 true自动 false不自动
      disableChgPass: false, // 禁止自助修改密码 true禁止 false不禁止
      notShowAmt: false,  // 是否不显示金额
      scanOrderMustDx: false,
      timeoutAutoBack: false,
      timeoutAutoBackTime: 0,
      chooseTime: {
        hour: "",
        hourOption: [],
        minute: "",
        minuteOption: []
      }
    };
  },
  methods: {
    inputHandle() {
      if (isNaN(this.time * 1) || isNaN(this.timeLine * 1)) {
        this.$message.warning("请输入数字");
        return true;
      }
    },

    getOption() {
      const hourArr = [];
      const minuteArr = [];
      for (let i = 0; i < 60; i++) {
        if (i < 24) {
          hourArr.push({
            value: i.toString().padStart(2, 0),
            label: i.toString().padStart(2, 0)
          });
        }

        minuteArr.push({
          value: i.toString().padStart(2, 0),
          label: i.toString().padStart(2, 0)
        });
      }
      this.chooseTime.hourOption = hourArr;
      this.chooseTime.minuteOption = minuteArr;
    },

    async getTime() {
      try {
        const res = await this.$api.BMS.terminalRules.reqGetTime();
        if (res.code == 1) {
          this.time = res.data.local_settle_timeout_mins;
          this.timeLine = res.data.online_settle_timeout_mins;
          this.radio = res.data.auto_close_on_off.toString();
          this.chooseTime.hour = (res.data.auto_close_hour * 1)
              .toString()
              .padStart(2, 0);
          this.chooseTime.minute = (res.data.auto_close_minute * 1)
              .toString()
              .padStart(2, 0);
          this.notShowAmt = res.data.limit_book_csm_amt == 1
          this.scanOrderMustDx = res.data.scan_order_must_dx == 1
          this.canClearCard = res.data.book_no_clean_seat == 1
          this.orderAutoMake = res.data.order_auto_mk == 1
          this.disableChgPass = res.data.disable_chg_pass == 1
          this.timeoutAutoBack = res.data.cust_scan_order_timeout !== 0
          this.timeoutAutoBackTime = res.data.cust_scan_order_timeout
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("获取终端规则失败", error);
      }
    },

    async submitHandle() {
      if (this.inputHandle()) return;
      const params = {
        online_settle_timeout_mins: this.timeLine * 1, // int  收银台待付超时提醒时间(单位分钟,默认15分钟,=0代表不提醒) 在线扫码点单下单
        local_settle_timeout_mins: this.time * 1, // int  收银台待付超时提醒时间(单位分钟,默认15分钟,=0代表不提醒)
        auto_close_on_off: this.radio * 1, // int     1 开 2 关
        auto_close_hour: this.chooseTime.hour * 1, // int     自动结束时 >=0 <=23 如果开关是关闭的话返还10
        auto_close_minute: this.chooseTime.minute * 1, // int    自动结束分钟 >=0 <=59 如果开关是关闭的话返还0
        limit_book_csm_amt: this.notShowAmt ? 1 : 2,  // int 限制预定系统显示消费金额 1 限制 2 不限制
        book_no_clean_seat: this.canClearCard ? 1 : 2, // int   是否禁止预订系统清台 1 禁止 2 不禁止
        order_auto_mk: this.orderAutoMake ? 1 : 2, // int   是否下单自动开启 1 开启 2 关闭
        disable_chg_pass: this.disableChgPass ? 1 : 2, // int   是否禁止自助修改密码 1 开启 2 关闭
        scan_order_must_dx: this.scanOrderMustDx ? 1 : 2,
        cust_scan_order_timeout: this.timeoutAutoBack ? this.timeoutAutoBackTime * 1 : 0

      };

      try {
        const res = await this.$api.BMS.terminalRules.reqSubmitTime(params);
        res.code == 1
            ? this.$message.success("保存成功")
            : this.$message.warning(res.msg);
      } catch (error) {
        console.log("保存终端规则失败", error);
      }
    }
  },
  mounted() {
    this.getOption();
    this.getTime();
  },
  watch: {
    radio(newVal) {
      if (newVal == 2) {
        this.chooseTime.hour = "10";
        this.chooseTime.minute = "00";
      }
    }
  }
};
</script>

<style scoped lang="less">
.terminal-rules {
  padding: 20px;
  padding-left: 30px;
  span {
    line-height: 40px;
  }
  p {
    font-size: 14px;
    line-height: 30px;
    margin-bottom: 20px;
  }
}

/deep/.el-switch.is-checked .el-switch__core{
  background-color: #2170ff;
  border: 1px solid #2170ff;
}
</style>