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
                    <div class="td one-txt-cut">{{ item.b }}</div>
                    <div class="td one-txt-cut">{{ item.vb }}</div>
                    <div class="td one-txt-cut">{{ item.fb }}</div>
                    <div class="td one-txt-cut">
                      {{ (item.va * 1 + item.fa * 1).toFixed(2) }}
                    </div>
                    <div class="td one-txt-cut">{{ item.va }}</div>
                    <div class="td one-txt-cut">{{ item.fa }}</div>
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
import common_money from "@/utils/common/money";
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
      hasChoosedListArr: [], // 选择好支付方式的列表（购物车）
    };
  },
  methods: {
    init() {
      this.interValHandle();
      this.phoneNumVal = "";
      this.validateVal = "";
      this.tableData = [];
      this.hasChoosedListArr = []; //
      this.getChoosePayList();
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
        amt: item.useAmt,
      };
      const res = await api_money.reqUpdateVipCardIntoBillChannel(param);
      if (res.code == 1) {
        this.$message.success("加入成功");
        this.getChoosePayList();
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
        console.log("验证手机验证码失败", error);
      }
    },

    async validateValidateInfo() {
      const params = {
        pay_code: this.validateVal, //    string   付款码
      };
      if (params.pay_code.length != 6) {
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
      }
    },

    async cardPayInfo(){
      const cardIds = this.tableData.map((item) => item.id * 1);
      const params = {
        seat_id: this.$store.state.orderInfo.currentCardInfo.seatId * 1,
        mb_card_ids: cardIds,
      };
      const res = await api_money.reqGetVipCardAmountInfo(params);
      this.tableData = this.tableData.map((item) => {
        const i = res.data.records.find((a) => a.id == item.id);
        return { ...item, ...i };
      });
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
  computed: {
    btnText() {
      return this.count == 60 ? "发送验证码" : this.count + "s后发送";
    },
    // 已收金额
    chooseAmt() {
      let chooseAmt = 0;
      this.hasChoosedListArr.forEach((el) => {
        chooseAmt += el.chooseAmt * 1;
      });
      return chooseAmt.toFixed(2);
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
