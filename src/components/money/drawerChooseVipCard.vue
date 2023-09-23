<template>
  <div>
    <!-- 手机号选择会员卡 -->
    <el-drawer
      :title="type == 1 ? '服务码选择会员卡' : '手机号选择会员卡'"
      :visible.sync="show"
      :append-to-body="true"
      :before-close="onCancelDrawer"
      direction="rtl"
      size="720px"
    >
      <div class="session choose-vip-card">
        <div class="form">
          <template v-if="type == 1">
            <div class="row" layout="row" layout-align="start center">
              <div class="label">
                <span class="red">*</span>
                <span>付款码序列号:</span>
              </div>
              <div class="value" layout="row" layout-align="start center">
                <input
                  type="text"
                  v-model="validateVal"
                  placeholder="请输入付款码序列号"
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
                  class="btn"
                  :class="{ disabled: count < 60 }"
                  @click="sendPhoneMessage"
                >
                  {{ btnText }}
                </div>
              </div>
            </div>
            <div class="row" layout="row" layout-align="start center">
              <div class="label">
                <span class="red">*</span>
                <span>验证码:</span>
              </div>
              <div class="value" layout="row" layout-align="start center">
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

        <p class="tips red">提示：勾选会员卡后，才可以填写金额</p>

        <div class="table">
          <div class="thead">
            <div class="tr" layout="row" layout-align="space-between center">
              <div class="th">序号</div>
              <div class="th">会员卡号</div>
              <div class="th">会员名称</div>
              <div class="th">会员卡金额</div>
              <div class="th">卡可用余额</div>
              <div class="th">本次使用金额</div>
              <div class="th">本次使用储值金额</div>
              <div class="th">本次使用赠送金额</div>
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
                <el-checkbox
                  v-model="item.checked"
                  :disabled="item.disabled"
                  @change="changeCheckBox(item)"
                  >{{ index + 1 }}</el-checkbox
                >
              </div>
              <div class="td one-txt-cut">{{ item.c }}</div>
              <div class="td one-txt-cut">{{ item.n }}</div>
              <div class="td one-txt-cut">{{ item.b }}</div>
              <div class="td one-txt-cut">{{ item.b }}</div>
              <div class="td one-txt-cut">
                <input
                  type="text"
                  :disabled="!item.checked"
                  v-model="item.chooseAmt"
                  placeholder="请输入使用金额"
                  @input="changeInput(item, item.b)"
                />
              </div>
              <div class="td one-txt-cut">{{ item.b }}</div>
              <div class="td one-txt-cut">{{ item.b }}</div>
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
      <div class="form-btn" layout="row" layout-align="center center">
        <el-button type="info" @click="onCancelDrawer">关闭</el-button>
        <el-button type="primary" @click="onSubmit">确定</el-button>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import api_money from "@/api/money";
import api_vip from "@/api/vip";
export default {
  data() {
    return {
      timer: null,
      show: false,
      count: 60,
      phoneNumVal: "",
      validateVal: "",
      authCodeStr: "",
      tableData: [],
    };
  },
  methods: {
    init() {
      this.interValHandle();

      this.phoneNumVal = "";
      this.validateVal = "";
      this.tableData = [];
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
        this.count = 60;
      }
    },
    // 发送验证码
    async sendPhoneMessage() {
      if (this.count != 60) return;
      const params = {
        t: 200, //  int   200  验证获取客人会员卡结账
        m: this.phoneNumVal, //  string   手机号
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
        console.log("验证手机验证码失败", error);
      }
    },

    async validateValidateInfo() {
      const params = {
        pay_code: this.validateVal, //    string   付款码
      };
      if (params.pay_code.length != 6) {
        this.$message.warning("请输入正确的六位付款码序列号");
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
      if (this.timer) clearInterval(this.timer);
      this.timer = setInterval(() => {
        this.count--;
        if (this.count == 0) {
          clearInterval(this.timer);
          this.count = 60;
        }
      }, 1000);
    },

    async getTableData() {
      const result =
        this.type == 1
          ? await this.validateValidateInfo()
          : await this.validatePhoneInfo();
      if (result) {
        const params = {
          sms_auth_code: result, // string   手机验证码验证授权串
          phone_num: this.phoneNumVal, //  string   手机号
        };

        try {
          const res = await api_money.reqGetVipCardFormPhoneNum(params);
          if (res.code == 1) {
            this.tableData = (res.data.records || []).map((item) => ({
              ...item,
              checked: (res.data.records || []).length == 1,
              chooseAmt: "",
              disabled: false,
            }));
            if (this.tableData.length == 1) {
              this.changeCheckBox(this.tableData[0]);
            }
          } else {
            this.$message.warning(res.msg);
          }
        } catch (error) {
          console.log("通过手机号查询会员卡失败", error);
        }
      }
    },

    changeCheckBox(itemInfo) {
      const choosedAmt = this.choosedAmt;
      if (itemInfo.checked) {
        if (
          choosedAmt * 1 - itemInfo.chooseAmt * 1 + itemInfo.b * 1 <
          this.maxPayMoney * 1
        ) {
          itemInfo.chooseAmt = itemInfo.b * 1;
          this.tableData = this.tableData.map((item) => ({
            ...item,
            disabled: false,
          }));
        } else {
          itemInfo.chooseAmt = (
            (this.maxPayMoney - choosedAmt).toFixed(2) * 1
          ).toString();
          this.tableData = this.tableData.map((item) => ({
            ...item,
            disabled: !item.checked,
          }));
        }
      } else {
        itemInfo.chooseAmt = "";
        this.tableData = this.tableData.map((item) => ({
          ...item,
          disabled: false,
        }));
        this.$forceUpdate();
      }
    },

    changeInput(itemInfo, max) {
      const choosedAmt = this.tableData
        .filter((item) => item.checked && item.id != itemInfo.id)
        .reduce((a, b) => a + b.chooseAmt * 1, 0);
      if (isNaN(itemInfo.chooseAmt)) {
        this.$message.warning("请输入数字");
        itemInfo.chooseAmt =
          itemInfo.length > 1
            ? item.chooseAmt.slice(0, item.chooseAmt.length - 1)
            : "";
      } else if (choosedAmt * 1 + max * 1 > this.maxPayMoney * 1) {
        if (itemInfo.chooseAmt * 1 > this.maxPayMoney - choosedAmt) {
          itemInfo.chooseAmt = (
            (this.maxPayMoney - choosedAmt).toFixed(2) * 1
          ).toString();
        }
      } else if (itemInfo.chooseAmt * 1 > max * 1) {
        this.$message.warning("当前会员卡最大可用金额为" + max);
        itemInfo.chooseAmt =
          itemInfo.chooseAmt.length > 1
            ? itemInfo.chooseAmt.slice(0, itemInfo.chooseAmt.length - 1)
            : "";
      }

      if (this.choosedAmt * 1 < this.maxPayMoney * 1) {
        this.tableData = this.tableData.map((item) => ({
          ...item,
          disabled: false,
        }));
      }
    },
    // 提交
    async onSubmit() {
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1, //    int64    待操作卡台Id
        auth_type: 2, //  int       授权类型 1 卡授权 2 手机验证码授权
        auth_code: this.authCodeStr, //  string    授权串
        mb_card_ids: this.tableData
          .filter((item) => item.checked)
          .map((item) => item.id * 1), // []int64    会员卡Id列表
        amts: this.tableData
          .filter((item) => item.checked)
          .map((item) => item.chooseAmt.toString()), //       []string   使用金额
        ...(this.payId && { pay_id: this.payId * 1 }),
      };
      try {
        const api = this.payId
          ? "reqAddVipCardFormPhoneNumInPayAfter"
          : "reqAddVipCardFormPhoneNumInPayBefore";
        const res = await api_money[api](params);
        if (res.code == 1) {
          this.$message.success("添加成功");
          this.$emit("nextHandle");
          this.onCancelDrawer();
        } else {
          this.$message.warning(res.msg);
        }
      } catch (error) {
        console.log("会员卡选择组合支付失败", error);
      }
    },
    onCancelDrawer() {
      this.$emit("showOrHideDrawer");
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
    type: {
      default: 1, // 1:二维码序列号查找  2:手机号查找
    },
    payId: {
      default: "",
    },
  },
  computed: {
    btnText() {
      return this.count == 60 ? "发送验证码" : this.count + "s后发送";
    },

    choosedAmt() {
      const result =
        this.tableData
          .filter((item) => item.checked)
          .reduce((a, b) => a + b.chooseAmt * 1, 0)
          .toFixed(2) * 1;
      return result;
    },
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
      .value {
        padding-left: 10px;
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
      }
    }
  }

  .tips {
    line-height: 60px;
  }

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
      width: 20%;
    }
    .th:nth-child(2),
    .td:nth-child(2) {
      width: 30%;
    }
    .th:nth-child(3),
    .td:nth-child(3) {
      width: 30%;
    }
    .th:nth-child(4),
    .td:nth-child(4) {
      width: 30%;
    }
    .th:nth-child(5),
    .td:nth-child(5) {
      width: 30%;
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
  }
}

/deep/.el-checkbox__label {
  color: rgba(255, 255, 255, 8);
}
</style>
